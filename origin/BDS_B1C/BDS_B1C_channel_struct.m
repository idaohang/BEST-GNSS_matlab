function ch = BDS_B1C_channel_struct()
% ����ͨ���ṹ�����г�

ch.PRN              = []; %���Ǳ��
ch.state            = []; %ͨ��״̬�����֣�
ch.codeData         = []; %���ݷ���α��
ch.codePilot        = []; %��Ƶ����α��
ch.timeIntMs        = []; %����ʱ�䣬ms

ch.trackDataTail    = []; %���ٿ�ʼ�������ݻ����е�λ��
ch.blkSize          = []; %�������ݶβ��������
ch.trackDataHead    = []; %���ٽ����������ݻ����е�λ��
ch.dataIndex        = []; %���ٿ�ʼ�����ļ��е�λ��
ch.codeTarget       = []; %��ǰ����Ŀ������λ

ch.carrNco          = []; %�ز�������Ƶ��
ch.codeNco          = []; %�뷢����Ƶ��
ch.carrFreq         = []; %�ز�Ƶ�ʲ���
ch.codeFreq         = []; %��Ƶ�ʲ���
ch.remCarrPhase     = []; %���ٿ�ʼ����ز���λ
ch.remCodePhase     = []; %���ٿ�ʼ�������λ
ch.PLL              = []; %���໷���ṹ�壩
ch.DLL              = []; %�ӳ����������ṹ�壩

end