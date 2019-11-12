classdef GPS_L1CA_track < handle

    % ֻ�����Ա�����޸�����ֵ
    properties (GetAccess = public, SetAccess = private)
        sampleFreq      %��Ʋ���Ƶ��
        deltaFreq       %Ƶ�����
        buffSize        %������������С
        logID           %��־�ļ�ID
        PRN             %���Ǳ��
        code            %C/A��
        timeIntMs       %����ʱ�䣬ms (1,2,4,5,10,20)
        timeIntS        %����ʱ�䣬s
        codeInt         %����ʱ������Ƭ����
        pointInt        %һ�������ж��ٸ����ֵ㣬һ������20ms
        trackDataTail   %���ٿ�ʼ�������ݻ����е�λ��
        blkSize         %�������ݶβ��������
        trackDataHead   %���ٽ����������ݻ����е�λ��
        dataIndex       %���ٿ�ʼ�����ļ��е�λ��
        carrNco         %�ز�������Ƶ��
        codeNco         %�뷢����Ƶ��
        carrFreq        %�ز�Ƶ�ʲ���
        codeFreq        %��Ƶ�ʲ���
        remCarrPhase    %���ٿ�ʼ����ز���λ
        remCodePhase    %���ٿ�ʼ�������λ
        FLL             %��Ƶ��
        PLL             %���໷
        DLL             %�ӳ�������
        I               %I·���ֽ��
        Q               %Q·���ֽ��
        PLLFlag         %PLLģʽ��־��0��ʾ��Ƶ����1��ʾ���໷
        DLLFlag         %DLLģʽ��־��0��ʾ��DLL��1��ʾXXX
        ts0             %��ǰα�����ڵĿ�ʼʱ�䣬ms
        varCode         %�����������ͳ��
        varPhase        %�ز�����������ͳ��
    end %end properties
    
    methods
        %% ����
        function obj = GPS_L1CA_track(sampleFreq, buffSize, PRN, logID)
            obj.sampleFreq = sampleFreq;
            obj.buffSize = buffSize;
            obj.PRN = PRN;
            obj.logID = logID;
        end
        
        %% ��ʼ��
        function init(obj, acqResult, n)
            % acqResultΪ����������һ����Ϊ����λ���ڶ�����Ϊ�ز�Ƶ��
            % nΪ�Ѿ����˶��ٸ�������
            obj.deltaFreq = 0;
            codeCA = GPS_L1CA_code(obj.PRN)';
            obj.code = [codeCA(end);codeCA;codeCA(1)]; %������
            obj.timeIntMs = 1;
            obj.timeIntS = 0.001;
            obj.codeInt = 1023;
            obj.pointInt = 20;
            obj.trackDataTail = obj.sampleFreq*0.001 - acqResult(1) + 2;
            obj.blkSize = obj.sampleFreq*0.001;
            obj.trackDataHead = obj.trackDataTail + obj.blkSize - 1;
            obj.dataIndex = obj.trackDataTail + n;
            obj.carrNco = acqResult(2);
            obj.codeNco = 1.023e6 + obj.carrNco/1540;
            obj.carrFreq = obj.carrNco;
            obj.codeFreq = obj.codeNco;
            obj.remCarrPhase = 0;
            obj.remCodePhase = 0;
            obj.FLL.K = 40*0.001;
            obj.FLL.Int = obj.carrNco;
            obj.FLL.cnt = 0;
            [K1, K2] = orderTwoLoopCoefDisc(25, 0.707, obj.timeIntS);
            obj.PLL.K1 = K1;
            obj.PLL.K2 = K2;
            obj.PLL.Int = 0;
            [K1, K2] = orderTwoLoopCoefDisc(2, 0.707, obj.timeIntS);
            obj.DLL.K1 = K1;
            obj.DLL.K2 = K2;
            obj.DLL.Int = obj.codeNco;
            obj.I = 1;
            obj.Q = 1;
            obj.PLLFlag = 0;
            obj.DLLFlag = 0;
            obj.ts0 = NaN;
            obj.varCode = var_rec(200);
            obj.varPhase = var_rec(200);
        end
        
        %% ����
        function [I_Q, disc] = track(obj, rawSignal)
            %----��������Ƶ��
            sampleFreq0 = obj.sampleFreq * (1+obj.deltaFreq);
            %----���¸��ٿ�ʼ�����ļ��е�λ�ã��´θ��٣�
            obj.dataIndex = obj.dataIndex + obj.blkSize;
            %----ʱ������
            t = (0:obj.blkSize-1) / sampleFreq0;
            te = obj.blkSize / sampleFreq0;
            %----���ɱ����ز�
            theta = (obj.remCarrPhase + obj.carrNco*t) * 2; %��2��Ϊ��������piΪ��λ�����Ǻ���
            carr_cos = cospi(theta); %�����ز�
            carr_sin = sinpi(theta);
            theta_next = obj.remCarrPhase + obj.carrNco*te;
            obj.remCarrPhase = mod(theta_next, 1); %ʣ���ز���λ����
            %----���ɱ�����
            tcode = obj.remCodePhase + obj.codeNco*t + 2; %��2��֤���ͺ���ʱ����1
            earlyCode  = obj.code(floor(tcode+0.5)); %��ǰ��
            promptCode = obj.code(floor(tcode));     %��ʱ��
            lateCode   = obj.code(floor(tcode-0.5)); %�ͺ���
            obj.remCodePhase = obj.remCodePhase + obj.codeNco*te - obj.codeInt; %ʣ���ز���λ����
            %----ԭʼ���ݳ��ز�
            iBasebandSignal = rawSignal(1,:).*carr_cos + rawSignal(2,:).*carr_sin; %�˸��ز�
            qBasebandSignal = rawSignal(2,:).*carr_cos - rawSignal(1,:).*carr_sin;
            %----��·����
            I_E = iBasebandSignal * earlyCode;
            Q_E = qBasebandSignal * earlyCode;
            I_P = iBasebandSignal * promptCode;
            Q_P = qBasebandSignal * promptCode;
            I_L = iBasebandSignal * lateCode;
            Q_L = qBasebandSignal * lateCode;
            %----�������
            S_E = sqrt(I_E^2+Q_E^2);
            S_L = sqrt(I_L^2+Q_L^2);
            codeError = 0.5 * (S_E-S_L)/(S_E+S_L); %��λ����Ƭ��0.5--0.5��0.4--0.6��0.3--0.7��0.25--0.75
            %----�ز�������
            carrError = atan(Q_P/I_P) / (2*pi); %��λ����
            %----��Ƶ��
            yc = obj.I*I_P + obj.Q*Q_P; %I0*I1+Q0*Q1
            ys = obj.I*Q_P - obj.Q*I_P; %I0*Q1-Q0*I1
            freqError = atan(ys/yc)/obj.timeIntS / (2*pi); %��λ��Hz
            obj.I = I_P;
            obj.Q = Q_P;
            %----FLL/PLL
            if obj.PLLFlag==0 %-FLL
                obj.FLL.Int = obj.FLL.Int + obj.FLL.K*freqError; %��Ƶ��������
                obj.carrNco = obj.FLL.Int;
                obj.carrFreq = obj.FLL.Int;
                obj.FLL.cnt = obj.FLL.cnt + 1;
                if obj.FLL.cnt==200 %��Ƶ200ms��ת�����໷����
                    obj.FLL.cnt = 0;
                    obj.PLL.Int = obj.FLL.Int; %��ʼ�����໷������
                    obj.PLLFlag = 1;
                    fprintf(obj.logID, '%2d: Start PLL tracking at %.8fs\r\n', ...
                    obj.PRN, obj.dataIndex/obj.sampleFreq);
                end
            else %-PLL
                obj.PLL.Int = obj.PLL.Int + obj.PLL.K2*carrError; %���໷������
                obj.carrNco = obj.PLL.Int + obj.PLL.K1*carrError;
                obj.carrFreq = obj.PLL.Int;
            end
            %----DLL
            obj.DLL.Int = obj.DLL.Int + obj.DLL.K2*codeError; %�ӳ�������������
            obj.codeNco = obj.DLL.Int + obj.DLL.K1*codeError;
            obj.codeFreq = obj.DLL.Int;
            %----����α������ʱ��
            obj.ts0 = obj.ts0 + obj.timeIntMs;
            %----������һ���ݿ�λ��
            obj.trackDataTail = obj.trackDataHead + 1;
            if obj.trackDataTail>obj.buffSize
                obj.trackDataTail = 1;
            end
            obj.blkSize = ceil((obj.codeInt-obj.remCodePhase)/obj.codeNco*sampleFreq0);
            obj.trackDataHead = obj.trackDataTail + obj.blkSize - 1;
            if obj.trackDataHead>obj.buffSize
                obj.trackDataHead = obj.trackDataHead - obj.buffSize;
            end
            %----���
            I_Q = [I_P, I_E, I_L, Q_P, Q_E, Q_L];
            disc = [codeError, carrError, freqError];
            %----ͳ�Ƽ������������
            obj.varCode.update(codeError);
            obj.varPhase.update(carrError);
        end
        
        %% ����α�����ڿ�ʼʱ��
        function set_ts0(obj, ts0)
            obj.ts0 = ts0;
        end
        
        %% ����Ƶ�����
        function set_deltaFreq(obj, deltaFreq)
            obj.deltaFreq = deltaFreq;
        end
        
        %% ���û���ʱ��
        function set_timeInt(obj, ti)
            codeCA = GPS_L1CA_code(obj.PRN)';
            obj.code = [codeCA(end);repmat(codeCA,ti,1);codeCA(1)]; %������
            obj.timeIntMs = ti;
            obj.timeIntS = ti/1000;
            obj.codeInt = ti*1023;
            obj.pointInt = 20/ti;
            sampleFreq0 = obj.sampleFreq * (1+obj.deltaFreq);
            obj.blkSize = ceil((obj.codeInt-obj.remCodePhase)/obj.codeNco*sampleFreq0);
            obj.trackDataHead = obj.trackDataTail + obj.blkSize - 1;
            if obj.trackDataHead>obj.buffSize
                obj.trackDataHead = obj.trackDataHead - obj.buffSize;
            end
            if ti==10
                [K1, K2] = orderTwoLoopCoefDisc(20, 0.707, obj.timeIntS);
                obj.PLL.K1 = K1;
                obj.PLL.K2 = K2;
                [K1, K2] = orderTwoLoopCoefDisc(1.8, 0.707, obj.timeIntS);
                obj.DLL.K1 = K1;
                obj.DLL.K2 = K2;
            elseif ti==1
                [K1, K2] = orderTwoLoopCoefDisc(25, 0.707, obj.timeIntS);
                obj.PLL.K1 = K1;
                obj.PLL.K2 = K2;
                [K1, K2] = orderTwoLoopCoefDisc(2, 0.707, obj.timeIntS);
                obj.DLL.K1 = K1;
                obj.DLL.K2 = K2;
            end
        end
        
    end %end methods
    
end %end classdef