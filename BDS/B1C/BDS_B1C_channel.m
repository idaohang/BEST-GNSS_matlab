classdef BDS_B1C_channel < BDS_B1C_track
% �̳��ڸ����࣬���������Ľ���
% https://blog.csdn.net/qq_43575267/article/details/93778020
    
    % ֻ�����Ա�����޸�����ֵ
    properties (GetAccess = public, SetAccess = private)
        state           %ͨ��״̬�����֣�
        msgStage        %���Ľ����׶Σ��ַ���
        msgCnt          %���Ľ���������
        Q0              %�ϴε�Ƶ��������ֵ�����ڱ���ͬ����
        bitSyncTable    %����ͬ��ͳ�Ʊ�
        bitBuff         %���ػ���
        frameBuff       %֡����
        frameBuffPoint  %֡����ָ��
        ephemeris       %����
        BDT_GPS         %����ʱ��GPSʱͬ������
        BDT_Galileo     %����ʱ��Galileoʱͬ������
        BDT_GLONASS     %����ʱ��GLONASSʱͬ������
    end
    
    methods
        %% ����
        function obj = BDS_B1C_channel(sampleFreq, buffSize, PRN, logID)
            obj = obj@BDS_B1C_track(sampleFreq, buffSize, PRN, logID);
            obj.state = 0;
        end
        
        %% ��ʼ��
        function init(obj, acqResult, n)
            init@BDS_B1C_track(obj, acqResult, n) %���ø���ͬ������
            obj.state = 1;
            obj.msgStage = 'I';
            obj.msgCnt = 0;
            obj.Q0 = 0;
            obj.bitSyncTable = zeros(1,10); %һ�����س���10ms
            obj.bitBuff = zeros(1,10); %�����10��
            obj.frameBuff = zeros(1,1800); %һ֡����1800����
            obj.frameBuffPoint = 0;
            obj.ephemeris = NaN(30,1);
            obj.BDT_GPS = NaN(5,1);
            obj.BDT_Galileo = NaN(5,1);
            obj.BDT_GLONASS = NaN(5,1);
        end
        
        %% ���Ľ���
        % �Ӳ��񵽽������ͬ��Ҫ200ms
        % ����ͬ������Ҫ1s����ʼ֡ͬ��Ҫ��һ��ʱ�䣬�ȴ����ر߽絽��
        % ֡ͬ������Ҫ500ms���ȵ���һ֡��ʼ�Ž�����������
        % ��������18sһ��
        function parse(obj, ta) %������ջ�ʱ�䣬��֡ͬ��ʱ����ȷ��α�����ڿ�ʼʱ��
            obj.msgCnt = obj.msgCnt + 1; %������1
            switch obj.msgStage %I,B,W,F,H,E
                case 'I' %<<====����
                    if obj.msgCnt==200 %����200ms
                        obj.msgCnt = 0; %����������
                        obj.msgStage = 'B'; %�������ͬ���׶�
                        fprintf(obj.logID, '%2d: Start bit synchronization at %.8fs\r\n', ...
                        obj.PRN, obj.dataIndex/obj.sampleFreq);
                    end
                case 'B' %<<====����ͬ��
                    if obj.Q0*obj.Q<0 %���ֵ�ƽ��ת
                        index = mod(obj.msgCnt-1,10) + 1;
                        obj.bitSyncTable(index) = obj.bitSyncTable(index) + 1; %ͳ�Ʊ��еĶ�Ӧλ��1
                    end
                    obj.Q0 = obj.Q;
                    if obj.msgCnt==1000 %1s�����ͳ�Ʊ���ʱ��100������
                        if max(obj.bitSyncTable)>10 && (sum(obj.bitSyncTable)-max(obj.bitSyncTable))<=2
                        % ����ͬ���ɹ���ȷ����ƽ��תλ�ã���ƽ��ת�󶼷�����һ�����ϣ�
                            [~,obj.msgCnt] = max(obj.bitSyncTable); %������ֵ��Ϊͬ�������ֵ������
                            obj.bitSyncTable = zeros(1,10); %����ͬ��ͳ�Ʊ�����
                            obj.msgCnt = -obj.msgCnt + 1; %�������Ϊ1���¸�Q·����ֵ��Ϊ���ؿ�ʼ��
                            if obj.msgCnt==0
                                obj.msgStage = 'F'; %����֡ͬ���׶�
                                fprintf(obj.logID, '%2d: Start frame synchronization at %.8fs\r\n', ...
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
                        obj.msgStage = 'F'; %����֡ͬ���׶�
                        fprintf(obj.logID, '%2d: Start frame synchronization at %.8fs\r\n', ...
                        obj.PRN, obj.dataIndex/obj.sampleFreq);
                    end
                case 'F' %<<====֡ͬ��
                    obj.bitBuff(obj.msgCnt) = obj.Q; %�����ػ����д�������Ƶ����
                    if obj.msgCnt==10 %������һ������
                        obj.msgCnt = 0; %����������
                        obj.frameBuffPoint = obj.frameBuffPoint + 1; %֡����ָ���1
                        obj.frameBuff(obj.frameBuffPoint) = (double(sum(obj.bitBuff)>0) - 0.5) * 2; %�洢����ֵ����1
                        % �ɼ�һ��ʱ�䵼Ƶ���룬ȷ���������������е�λ��
                        if obj.frameBuffPoint==50 %����50������
                            R = zeros(1,1800); %50���������������в�ͬλ�õ���ؽ��
                            code = [obj.codeSub, obj.codeSub(1:49)];
                            x = obj.frameBuff(1:50)'; %������
                            for k=1:1800
                                R(k) = code(k:k+49) * x;
                            end
                            [Rmax, index] = max(abs(R)); %Ѱ����ؽ�������ֵ
                            if Rmax==50 %������ֵ��ȷ
                                ta = ta(1)*1000 + ta(2); %��ǰ���ջ�ʱ�䣬ms
                                td = (index+50) *10; %֡��ms
                                t0 = round((ta-td)/18000); %ָ���������18s
                                obj.set_ts0(t0*18000+td); %����α�����ڿ�ʼʱ��
                                obj.start_pure_PLL(index+50, R(index)<0); %���������໷
                                obj.frameBuffPoint = mod(index+49,1800); %֡����ָ���ƶ�
                                if obj.frameBuffPoint==0
                                    obj.msgStage = 'E'; %������������׶�
                                    fprintf(obj.logID, '%2d: Start parse ephemeris at %.8fs\r\n', ...
                                    obj.PRN, obj.dataIndex/obj.sampleFreq);
                                else
                                    obj.msgStage = 'H'; %�ȴ�֡ͷ
                                end
                            else %������ֵ����
                                obj.frameBuffPoint = 0; %֡����ָ���λ
                                obj.msgStage = 'B'; %���ر���ͬ���׶�
                                fprintf(obj.logID, '%2d: ***Frame synchronization failed at %.8fs\r\n', ...
                                obj.PRN, obj.dataIndex/obj.sampleFreq);
                            end
                        end
                    end
                case 'H' %<<====�ȴ�֡ͷ
                    if obj.msgCnt==10 %������һ������
                        obj.msgCnt = 0; %����������
                        obj.frameBuffPoint = obj.frameBuffPoint + 1; %֡����ָ���1
                        if obj.frameBuffPoint==1800
                            obj.frameBuffPoint = 0; %֡����ָ���λ
                            obj.msgStage = 'E'; %������������׶�
                            fprintf(obj.logID, '%2d: Start parse ephemeris at %.8fs\r\n', ...
                            obj.PRN, obj.dataIndex/obj.sampleFreq);
                        end
                    end
                case 'E' %<<====��������
                    obj.bitBuff(obj.msgCnt) = obj.I; %�����ػ����д�������������
                    if obj.msgCnt==10 %������һ������
                        obj.msgCnt = 0; %����������
                        obj.frameBuffPoint = obj.frameBuffPoint + 1; %֡����ָ���1
                        obj.frameBuff(obj.frameBuffPoint) = (double(sum(obj.bitBuff)>0) - 0.5) * 2; %�洢����ֵ����1
                        if obj.frameBuffPoint==1800 %����1800�����أ�һ֡��
                            obj.frameBuffPoint = 0;
                            [ephemeris0, sf3] = BDS_CNAV1_ephemeris_parse(obj.frameBuff);
                            if ~isempty(ephemeris0) %���������ɹ�
                                fprintf(obj.logID, '%2d: Ephemeris is parsed at %.8fs\r\n', ...
                                obj.PRN, obj.dataIndex/obj.sampleFreq);
                                obj.ephemeris = ephemeris0;
                                obj.state = 2;
                                if sf3.pageID==3
                                    switch sf3.BGTO(1) %����BDT-GNSSʱ��ͬ������
                                        case 1
                                            obj.BDT_GPS = sf3.BGTO(2:6);
                                        case 2
                                            obj.BDT_Galileo = sf3.BGTO(2:6);
                                        case 3
                                            obj.BDT_GLONASS = sf3.BGTO(2:6);
                                    end
                                end
                            else %������������
                                fprintf(obj.logID, '%2d: ***Ephemeris error at %.8fs\r\n', ...
                                obj.PRN, obj.dataIndex/obj.sampleFreq);
                            end
                        end
                    end
                otherwise
            end
        end
        
    end %end methods
    
end %end classdef