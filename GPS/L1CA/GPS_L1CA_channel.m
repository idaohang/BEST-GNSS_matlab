classdef GPS_L1CA_channel < GPS_L1CA_track

    % ֻ�����Ա�����޸�����ֵ
    properties (GetAccess = public, SetAccess = private)
        state           %ͨ��״̬�����֣�
    end %end properties
    
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
        end
        
        %% ���Ľ���
        function parse(obj, ta)
            
        end
        
    end %end methods
    
end %end classdef