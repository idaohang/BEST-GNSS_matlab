classdef BDS_B1C_track < handle
% ʹ�þ���࣬����ֵ���ݣ�help->Comparison of Handle and Value Classes
% ����๹��ʱ����һ����������ã���������ʱ����Ҫ����ԭʼ����

    % ֻ�����Ա�����޸�����ֵ
    properties (GetAccess = public, SetAccess = private)
        sampleFreq      %����Ƶ��
        buffSize        %������������С
        logID           %��־�ļ�ID
        PRN             %���Ǳ��
        codeData        %�������루�����ز���
        codePilot       %��Ƶ���루�����ز���
        codeSub         %��Ƶ����
        timeIntMs       %����ʱ�䣬ms
        timeIntS        %����ʱ�䣬s
        trackDataTail   %���ٿ�ʼ�������ݻ����е�λ��
        blkSize         %�������ݶβ��������
        trackDataHead   %���ٽ����������ݻ����е�λ��
        dataIndex       %���ٿ�ʼ�����ļ��е�λ��
        codeTarget      %��ǰ����Ŀ������λ
        carrNco         %�ز�������Ƶ��
        codeNco         %�뷢����Ƶ��
        carrFreq        %�ز�Ƶ�ʲ���
        codeFreq        %��Ƶ�ʲ���
        remCarrPhase    %���ٿ�ʼ����ز���λ
        remCodePhase    %���ٿ�ʼ�������λ
        PLL             %���໷
        DLL             %�ӳ�������
        I               %��Ƶ�������ֽ��
        Q               %���ݷ������ֽ��
        PLLFlag         %PLLģʽ��־��0��ʾ180����λģ����1��ʾ�����໷
        subPhase        %������λ
        ts0             %��ǰα�����ڵĿ�ʼʱ�䣬ms
        varCode         %�����������ͳ��
        varPhase        %�ز�����������ͳ��
    end %end properties
    
    methods
        %% ����
        function obj = BDS_B1C_track(sampleFreq, buffSize, PRN, logID)
            obj.sampleFreq = sampleFreq; %�����������
            obj.buffSize = buffSize;
            obj.PRN = PRN;
            obj.logID = logID;
        end
        
        %% ��ʼ��
        function init(obj, acqResult, n)
            % acqResultΪ����������һ����Ϊ����λ���ڶ�����Ϊ�ز�Ƶ��
            % nΪ�Ѿ����˶��ٸ�������
            code = BDS_B1C_code_data(obj.PRN);
            code = reshape([code;-code],10230*2,1);
            obj.codeData = [code(end);code;code(1)]; %������
            code = BDS_B1C_code_pilot(obj.PRN);
            code = reshape([code;-code],10230*2,1);
            obj.codePilot = [code(end);code;code(1)]; %������
            obj.codeSub = BDS_B1C_code_sub(obj.PRN); %������
            obj.timeIntMs = 1;
            obj.timeIntS = 0.001;
            obj.trackDataTail = obj.sampleFreq*0.01 - acqResult(1) + 2;
            obj.blkSize = obj.sampleFreq*0.001;
            obj.trackDataHead = obj.trackDataTail + obj.blkSize - 1;
            obj.dataIndex = obj.trackDataTail + n;
            obj.codeTarget = 2046;
            obj.carrNco = acqResult(2);
            obj.codeNco = (1.023e6 + obj.carrNco/1540) * 2; %��Ϊ�����ز���Ҫ��2
            obj.carrFreq = obj.carrNco;
            obj.codeFreq = obj.codeNco;
            obj.remCarrPhase = 0;
            obj.remCodePhase = 0;
            [K1, K2] = orderTwoLoopCoef(25, 0.707, 1);
            obj.PLL.K1 = K1;
            obj.PLL.K2 = K2;
            obj.PLL.Int = obj.carrNco;
            [K1, K2] = orderTwoLoopCoef(2, 0.707, 1);
            obj.DLL.K1 = K1;
            obj.DLL.K2 = K2;
            obj.DLL.Int = obj.codeNco;
            obj.I = 0;
            obj.Q = 0;
            obj.PLLFlag = 0;
            obj.subPhase = 1;
            obj.ts0 = NaN;
            obj.varCode = var_rec(200);
            obj.varPhase = var_rec(200);
        end
        
        %% ����
        function [I_Q, disc] = track(obj, rawSignal)
            %----���¸��ٿ�ʼ�����ļ��е�λ�ã��´θ��٣�
            obj.dataIndex = obj.dataIndex + obj.blkSize;
            %----ʱ������
            t = (0:obj.blkSize-1) / obj.sampleFreq;
            te = obj.blkSize / obj.sampleFreq;
            %----���ɱ����ز�
            theta = (obj.remCarrPhase + obj.carrNco*t) * 2; %��2��Ϊ��������piΪ��λ�����Ǻ���
            carr_cos = cospi(theta); %�����ز�
            carr_sin = sinpi(theta);
            theta_next = obj.remCarrPhase + obj.carrNco*te;
            obj.remCarrPhase = mod(theta_next, 1); %ʣ���ز���λ����
            %----���ɱ�����
            tcode = obj.remCodePhase + obj.codeNco*t + 2; %��2��֤���ͺ���ʱ����1
%             earlyCodeI  = obj.codeData(floor(tcode+0.3));  %��ǰ�루���ݷ�����
            promptCodeI = obj.codeData(floor(tcode));      %��ʱ��
%             lateCodeI   = obj.codeData(floor(tcode-0.3));  %�ͺ���
            earlyCodeQ  = obj.codePilot(floor(tcode+0.3)); %��ǰ�루��Ƶ������
            promptCodeQ = obj.codePilot(floor(tcode));     %��ʱ��
            lateCodeQ   = obj.codePilot(floor(tcode-0.3)); %�ͺ���
            obj.remCodePhase = mod(obj.remCodePhase + obj.codeNco*te, 20460); %ʣ���ز���λ����
            %----ԭʼ���ݳ��ز�
            iBasebandSignal = rawSignal(1,:).*carr_cos + rawSignal(2,:).*carr_sin; %�˸��ز�
            qBasebandSignal = rawSignal(2,:).*carr_cos - rawSignal(1,:).*carr_sin;
            %----��·���֣�ʹ�õ�Ƶ�������٣����ݷ���ֻ�����������ģ�
            I_E = iBasebandSignal * earlyCodeQ;
            Q_E = qBasebandSignal * earlyCodeQ;
            I_P = iBasebandSignal * promptCodeQ;
            Q_P = qBasebandSignal * promptCodeQ;
            I_L = iBasebandSignal * lateCodeQ;
            Q_L = qBasebandSignal * lateCodeQ;
            obj.I = -qBasebandSignal * promptCodeI; %���ݷ�������ֵ��1:sqrt(29/11)��1:624
            obj.Q = I_P;                            %��Ƶ����
            %----�������
            S_E = sqrt(I_E^2+Q_E^2);
            S_L = sqrt(I_L^2+Q_L^2);
            codeError = (11/30) * (S_E-S_L)/(S_E+S_L); %��λ����Ƭ
            %----�ز�������
            if obj.PLLFlag==0
                carrError = atan(Q_P/I_P) / (2*pi); %��λ����
            else
                s = obj.codeSub(obj.subPhase); %�������
                carrError = atan2(Q_P*s,I_P*s) / (2*pi); %��λ����
            end
            %----PLL
            obj.PLL.Int = obj.PLL.Int + obj.PLL.K2*carrError*obj.timeIntS; %���໷������
            obj.carrNco = obj.PLL.Int + obj.PLL.K1*carrError;
            obj.carrFreq = obj.PLL.Int;
            %----DLL
            obj.DLL.Int = obj.DLL.Int + obj.DLL.K2*codeError*obj.timeIntS; %�ӳ�������������
            obj.codeNco = obj.DLL.Int + obj.DLL.K1*codeError;
            obj.codeFreq = obj.DLL.Int;
            %----����Ŀ������λ����Ƶ������λ��α������ʱ��
            if obj.codeTarget==20460
                obj.codeTarget = 2046;
                obj.subPhase = mod(obj.subPhase,1800) + 1; %��Ƶ������λ��1��ֻ��ͨ�����Ľ���ȷ���˵�Ƶ������λ�������壩
                obj.ts0 = obj.ts0 + 10; %һ��α������10ms
            else
                obj.codeTarget = obj.codeTarget + 2046; %����Ŀ������λ
            end
            %----������һ���ݿ�λ��
            obj.trackDataTail = obj.trackDataHead + 1;
            if obj.trackDataTail>obj.buffSize
                obj.trackDataTail = 1;
            end
            obj.blkSize = ceil((obj.codeTarget-obj.remCodePhase)/obj.codeNco*obj.sampleFreq);
            obj.trackDataHead = obj.trackDataTail + obj.blkSize - 1;
            if obj.trackDataHead>obj.buffSize
                obj.trackDataHead = obj.trackDataHead - obj.buffSize;
            end
            %----���
            I_Q = [I_P, I_E, I_L, Q_P, Q_E, Q_L, obj.I, obj.Q];
            disc = [codeError/2, carrError]; %����λ������2�������������λ���
            %----ͳ�Ƽ������������
            obj.varCode.update(codeError/2);
            obj.varPhase.update(carrError);
        end
        
        %% ���������໷
        function start_pure_PLL(obj, subPhase, phaseFlag)
            if phaseFlag==1
                obj.remCarrPhase = mod(obj.remCarrPhase+0.5, 1); %�ز���λ��ת
            end
            obj.subPhase = subPhase;
            obj.PLLFlag = 1;
        end
        
        %% ����α�����ڿ�ʼʱ��
        function set_ts0(obj, ts0)
            obj.ts0 = ts0;
        end
        
        %% ���ò���Ƶ��
        function set_sampleFreq(obj, sampleFreq)
            obj.sampleFreq = sampleFreq;
        end
        
    end %end methods
    
end %end classdef