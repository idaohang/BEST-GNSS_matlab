classdef GPS_L1CA_channel < GPS_L1CA_track

    % ֻ�����Ա�����޸�����ֵ
    properties (GetAccess = public, SetAccess = private)
        state           %ͨ��״̬�����֣�
        msgStage        %���Ľ����׶Σ��ַ���
        msgCnt          %���Ľ���������
        I0              %�ϴ�I·����ֵ�����ڱ���ͬ����
        bitSyncTable    %����ͬ��ͳ�Ʊ�
        bitBuff         %���ػ���
        frameBuff       %֡����
        frameBuffPoint  %֡����ָ��
        ephemeris       %����
        ion             %�����У������
    end %end properties
    
    properties (Constant = true)
        frameHead = [1,-1,-1,-1,1,-1,1,1] %֡ͷ
    end
    
    methods
        %% ����
        function obj = GPS_L1CA_channel(sampleFreq, buffSize, PRN, logID)
            obj = obj@GPS_L1CA_track(sampleFreq, buffSize, PRN, logID);
            obj.state = 0;
        end
        
        %% ��ʼ��
        function init(obj, acqResult, n)
            init@GPS_L1CA_track(obj, acqResult, n) %���ø���ͬ������
            obj.state = 1;
            obj.msgStage = 'I';
            obj.msgCnt = 0;
            obj.I0 = 0;
            obj.bitSyncTable = zeros(1,20); %һ�����س���20ms
            obj.bitBuff = zeros(1,20); %�����20��
            obj.frameBuff = zeros(1,1502); %һ֡����1500����
            obj.frameBuffPoint = 0;
            obj.ephemeris = NaN(26,1);
            obj.ion = NaN(8,1);
        end
        
        %% ���Ľ���
        % �Ӳ��񵽽������ͬ��Ҫ500ms
        % ����ͬ������Ҫ2s����ʼѰ��֡ͷҪ��һ��ʱ�䣬�ȴ����ر߽絽��
        % ����ͬ����ʼѰ��֡ͷ������һ��������֡����У��֡ͷ����Ѱ��֡ͷ��������������6s�����12s
        % ��֤֡ͷ��Ϳ���ȷ���뷢��ʱ��
        % ��������30sһ��
        % ����ͬ����������ӻ���ʱ��
        function parse(obj)
            obj.msgCnt = obj.msgCnt + 1; %������1
            switch obj.msgStage %I,B,W,H,C,E
                case 'I' %<<====����
                    if obj.msgCnt==500 %����500ms
                        obj.msgCnt = 0; %����������
                        obj.msgStage = 'B'; %�������ͬ���׶�
                        fprintf(obj.logID, '%2d: Start bit synchronization at %.8fs\r\n', ...
                        obj.PRN, obj.dataIndex/obj.sampleFreq);
                    end
                case 'B' %<<====����ͬ��
                    if obj.I0*obj.I<0 %���ֵ�ƽ��ת
                        index = mod(obj.msgCnt-1,20) + 1;
                        obj.bitSyncTable(index) = obj.bitSyncTable(index) + 1; %ͳ�Ʊ��еĶ�Ӧλ��1
                    end
                    obj.I0 = obj.I;
                    if obj.msgCnt==2000 %2s�����ͳ�Ʊ���ʱ��100������
                        obj.I0 = 0;
                        if max(obj.bitSyncTable)>10 && (sum(obj.bitSyncTable)-max(obj.bitSyncTable))<=2
                        % ����ͬ���ɹ���ȷ����ƽ��תλ�ã���ƽ��ת�󶼷�����һ�����ϣ�
                            [~,obj.msgCnt] = max(obj.bitSyncTable); %������ֵ��Ϊͬ�������ֵ������
                            obj.bitSyncTable = zeros(1,20); %����ͬ��ͳ�Ʊ�����
                            obj.msgCnt = -obj.msgCnt + 1; %�������Ϊ1���¸�I·����ֵ��Ϊ���ؿ�ʼ��
                            if obj.msgCnt==0
%                                 obj.set_timeInt(10); %���ӻ���ʱ��
                                obj.msgStage = 'H'; %����Ѱ��֡ͷ�׶�
                                fprintf(obj.logID, '%2d: Start find head at %.8fs\r\n', ...
                                obj.PRN, obj.dataIndex/obj.sampleFreq);
                            else
                                obj.msgStage = 'W'; %�ȴ�����ͷ
                            end
                        else
                        % ����ͬ��ʧ�ܣ��ر�ͨ��
                            obj.state = 0;
                            fprintf(obj.logID, '%2d: ***Bit synchronization failed at %.8fs\r\n', ...
                            obj.PRN, obj.dataIndex/obj.sampleFreq);
                        end
                    end
                case 'W' %<<====�ȴ�����ͷ
                    if obj.msgCnt==0
%                         obj.set_timeInt(10); %���ӻ���ʱ��
                        obj.msgStage = 'H'; %����Ѱ��֡ͷ�׶�
                        fprintf(obj.logID, '%2d: Start find head at %.8fs\r\n', ...
                        obj.PRN, obj.dataIndex/obj.sampleFreq);
                    end
                otherwise %<<====�Ѿ���ɱ���ͬ��
                    obj.bitBuff(obj.msgCnt) = obj.I; %�����ػ����д���
                    if obj.msgCnt==obj.pointInt %������һ������
                        obj.msgCnt = 0; %����������
                        obj.frameBuffPoint = obj.frameBuffPoint + 1; %֡����ָ���1
                        obj.frameBuff(obj.frameBuffPoint) = (double(sum(obj.bitBuff(1:obj.pointInt))>0) - 0.5) * 2; %�洢����ֵ����1
                        switch obj.msgStage
                            case 'H' %<<====Ѱ��֡ͷ
                                if obj.frameBuffPoint>=10 %������10�����أ�ǰ��������У��
                                    if abs(sum(obj.frameBuff(obj.frameBuffPoint+(-7:0)).*obj.frameHead))==8 %��⵽����֡ͷ
                                        obj.frameBuff(1:10) = obj.frameBuff(obj.frameBuffPoint+(-9:0)); %��֡ͷ��ǰ
                                        obj.frameBuffPoint = 10;
                                        obj.msgStage = 'C'; %����У��֡ͷ�׶�
                                    end
                                    if obj.frameBuffPoint==1502
                                        obj.frameBuffPoint = 0;
                                    end
                                end
                            case 'C' %<<====У��֡ͷ
                                if obj.frameBuffPoint==310 %�洢��һ����֡��2+300+8
                                    if GPS_L1CA_check(obj.frameBuff(1:32))==1 && ...
                                       GPS_L1CA_check(obj.frameBuff(31:62))==1 && ...
                                       abs(sum(obj.frameBuff(303:310).*obj.frameHead))==8 %У��ͨ��
                                        % ��ȡ����ʱ��
                                        % frameBuff(32)Ϊ��һ�ֵ����һλ��У��ʱ���Ƶ�ƽ��ת��Ϊ1��ʾ��ת��Ϊ0��ʾ����ת���μ�ICD-GPS���ҳ
                                        bits = -obj.frameBuff(32) * obj.frameBuff(33:49); %��ƽ��ת��31~47����
                                        bits = dec2bin(bits>0)'; %��1����ת��Ϊ01�ַ���
                                        TOW = bin2dec(bits); %01�ַ���ת��Ϊʮ������
                                        obj.set_ts0((TOW*6+0.16)*1000); %����α�����ڿ�ʼʱ�䣬ms��0.16=8/50
                                        % TOWΪ��һ��֡��ʼʱ�䣬�μ�������/GPS˫ģ������ջ�ԭ����ʵ�ּ�����96ҳ
                                        obj.msgStage = 'E'; %������������׶�
                                        fprintf(obj.logID, '%2d: Start parse ephemeris at %.8fs\r\n', ...
                                        obj.PRN, obj.dataIndex/obj.sampleFreq);
                                    else %У��δͨ��
                                        for k=11:310 %���������������û��֡ͷ
                                            if abs(sum(obj.frameBuff(k+(-7:0)).*obj.frameHead))==8 %��⵽����֡ͷ
                                                obj.frameBuff(1:320-k) = obj.frameBuff(k-9:310); %��֡ͷ�ͺ���ı�����ǰ��320-k = 310-(k-9)+1
                                                obj.frameBuffPoint = 320-k; %��ʾ֡�������ж��ٸ���
                                                break
                                            end
                                        end
                                        if obj.frameBuffPoint==310 %û��⵽����֡ͷ
                                            obj.frameBuff(1:9) = obj.frameBuff(302:310); %��δ���ı�����ǰ
                                            obj.frameBuffPoint = 9;
                                            obj.msgStage = 'H'; %�ٴ�Ѱ��֡ͷ
                                        end
                                    end
                                end
                            case 'E' %<<====��������
                                if obj.frameBuffPoint==1502 %������5֡
                                    [ephemeris0, ion0] = GPS_L1CA_ephemeris_parse(obj.frameBuff); %��������
                                    if ~isempty(ephemeris0) %���������ɹ�
                                        if ephemeris0(2)==ephemeris0(3) %��������
                                            fprintf(obj.logID, '%2d: Ephemeris is parsed at %.8fs\r\n', ...
                                            obj.PRN, obj.dataIndex/obj.sampleFreq);
                                            obj.ephemeris = ephemeris0;
                                            obj.state = 2;
                                            if ~isempty(ion0) %�����У������
                                                obj.ion = ion0;
                                            end
                                        else %�����ı�
                                            fprintf(obj.logID, '%2d: ***Ephemeris changes at %.8fs, IODC=%d, IODE=%d\r\n', ...
                                            obj.PRN, obj.dataIndex/obj.sampleFreq, ephemeris0(2), ephemeris0(3));
                                        end
                                    else  %������������
                                        fprintf(obj.logID, '%2d: ***Ephemeris error at %.8fs\r\n', ...
                                        obj.PRN, obj.dataIndex/obj.sampleFreq);
                                    end
                                    obj.frameBuff(1:2) = obj.frameBuff(1501:1502); %���������������ǰ
                                    obj.frameBuffPoint = 2;
                                end
                        end
                    end
            end
        end
        
    end %end methods
    
end %end classdef