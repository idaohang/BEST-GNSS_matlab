function trackResult = trackResult_struct(m)
% ���ٽ���ṹ��

trackResult.PRN = 0;
trackResult.n = 1; %ָ��ǰ�洢���к�

trackResult.dataIndex     = zeros(m,1); %�����ڿ�ʼ��������ԭʼ�����ļ��е�λ��
trackResult.remCodePhase  = zeros(m,1); %�����ڿ�ʼ�����������λ����Ƭ
trackResult.codeFreq      = zeros(m,1); %��Ƶ��
trackResult.remCarrPhase  = zeros(m,1); %�����ڿ�ʼ��������ز���λ����
trackResult.carrFreq      = zeros(m,1); %�ز�Ƶ��
trackResult.I_Q           = zeros(m,6); %[I_P,I_E,I_L,Q_P,Q_E,Q_L]
trackResult.disc          = zeros(m,2); %������

end