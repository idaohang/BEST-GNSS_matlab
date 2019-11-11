function [ch, I_Q, disc] = BDS_B1C_track(ch, sampleFreq, buffSize, rawSignal)

%% ��ȡͨ����Ϣ
codeData       = ch.codeData;
codePolit      = ch.codePilot;
timeIntMs      = ch.timeIntMs;
blkSize        = ch.blkSize;
carrNco        = ch.carrNco;
codeNco        = ch.codeNco;
remCarrPhase   = ch.remCarrPhase;
remCodePhase   = ch.remCodePhase;
PLL            = ch.PLL;
DLL            = ch.DLL;

ch.dataIndex = ch.dataIndex + blkSize;

timeInt = timeIntMs * 0.001; %����ʱ�䣬s

%% ��������
% ʱ������
t = (0:blkSize-1) / sampleFreq;
te = blkSize / sampleFreq;

% ���ɱ����ز�
theta = (remCarrPhase + carrNco*t) * 2; %��2��Ϊ��������piΪ��λ�����Ǻ���
carr_cos = cospi(theta); %�����ز�
carr_sin = sinpi(theta);
theta_next = remCarrPhase + carrNco*te;
remCarrPhase = mod(theta_next, 1); %ʣ���ز���λ����

% ���ɱ�����
tcode = remCodePhase + codeNco*t + 2; %��2��֤���ͺ���ʱ����1
% earlyCodeI  = codeData(floor(tcode+0.3));  %��ǰ�루���ݷ�����
promptCodeI = codeData(floor(tcode));      %��ʱ��
% lateCodeI   = codeData(floor(tcode-0.3));  %�ͺ���
earlyCodeQ  = codePolit(floor(tcode+0.3)); %��ǰ�루��Ƶ������
promptCodeQ = codePolit(floor(tcode));     %��ʱ��
lateCodeQ   = codePolit(floor(tcode-0.3)); %�ͺ���
remCodePhase = mod(remCodePhase + codeNco*te, 20460); %ʣ���ز���λ����

% ԭʼ���ݳ��ز�
iBasebandSignal = rawSignal(1,:).*carr_cos + rawSignal(2,:).*carr_sin; %�˸��ز�
qBasebandSignal = rawSignal(2,:).*carr_cos - rawSignal(1,:).*carr_sin;

% ��·���֣�ʹ�����ݷ������٣�
% I_E = iBasebandSignal * earlyCodeI;
% Q_E = qBasebandSignal * earlyCodeI;
% I_P = iBasebandSignal * promptCodeI;
% Q_P = qBasebandSignal * promptCodeI;
% I_L = iBasebandSignal * lateCodeI;
% Q_L = qBasebandSignal * lateCodeI;
% I = I_P;
% Q = Q_P;
% ��·���֣�ʹ�õ�Ƶ�������٣�
% I_E = iBasebandSignal * earlyCodeQ;
% Q_E = qBasebandSignal * earlyCodeQ;
% I_P = iBasebandSignal * promptCodeQ;
% Q_P = qBasebandSignal * promptCodeQ;
% I_L = iBasebandSignal * lateCodeQ;
% Q_L = qBasebandSignal * lateCodeQ;
% I = I_P;
% Q = Q_P;
% ��·���֣�˫ͨ�����٣�
I_E = iBasebandSignal * earlyCodeQ;
Q_E = qBasebandSignal * earlyCodeQ;
I_P = -qBasebandSignal * promptCodeI; %���ݷ�������ֵ��1:sqrt(29/11)��1:624
Q_P =  iBasebandSignal * promptCodeQ; %��Ƶ����
I_L = iBasebandSignal * lateCodeQ;
Q_L = qBasebandSignal * lateCodeQ;
I = iBasebandSignal * promptCodeQ;
Q = qBasebandSignal * promptCodeQ;

% �������
S_E = sqrt(I_E^2+Q_E^2);
S_L = sqrt(I_L^2+Q_L^2);
codeError = (11/30) * (S_E-S_L)/(S_E+S_L); %��λ����Ƭ

% �ز�������
carrError = atan(Q/I) / (2*pi); %��λ����

%% �����㷨
%----PLL
PLL.Int = PLL.Int + PLL.K2*carrError*timeInt; %���໷������
carrNco = PLL.Int + PLL.K1*carrError;
carrFreq = PLL.Int;
%----DLL
DLL.Int = DLL.Int + DLL.K2*codeError*timeInt; %�ӳ�������������
codeNco = DLL.Int + DLL.K1*codeError;
codeFreq = DLL.Int;

%% ������һ���ݿ�λ��
trackDataTail = ch.trackDataHead + 1;
if trackDataTail>buffSize
    trackDataTail = 1;
end
if ch.codeTarget==20460
    ch.codeTarget = 2046;
else
    ch.codeTarget = ch.codeTarget + 2046; %����Ŀ������λ��������
end
blkSize = ceil((ch.codeTarget-remCodePhase)/codeNco*sampleFreq);
trackDataHead = trackDataTail + blkSize - 1;
if trackDataHead>buffSize
    trackDataHead = trackDataHead - buffSize;
end
ch.trackDataTail = trackDataTail;
ch.blkSize       = blkSize;
ch.trackDataHead = trackDataHead;

%% ����ͨ����Ϣ
ch.carrNco        = carrNco;
ch.codeNco        = codeNco;
ch.carrFreq       = carrFreq;
ch.codeFreq       = codeFreq;
ch.remCarrPhase   = remCarrPhase;
ch.remCodePhase   = remCodePhase;
ch.PLL            = PLL;
ch.DLL            = DLL;

%% ���
I_Q = [I_P, I_E, I_L, Q_P, Q_E, Q_L];
disc = [codeError, carrError];

end