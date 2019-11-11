function [ephemeris, sf3] = BDS_CNAV1_ephemeris_parse(data)
% B-CNAV1��������
% sf3Ϊ��֡3�����ڲ�ͬ��ҳ�����ͽṹ��һ��
% �������أ�http://www.csno-tarc.cn/support/downloads
% ���ϵ�������B1I�Ϸ��ģ�B1C�Ϸ������������Բ��ϣ��Ӳ�����ܶ���

% �⽻֯
frame = double(data>0); %��1ת����01
subFrameRaw23 = frame(73:1800); %�⽻֯ǰ2��3��֡��������
table = reshape(subFrameRaw23',36,48); %�ųɱ��
subFrame2_table = table([1,2,4,5,7,8,10,11,13,14,16,17,19,20,22,23,25,26,28,29,31,32,34,35,36],:); %�ӱ������ȡ��֡2����
subFrame2 = reshape(subFrame2_table',1,1200); % �ų�һ�У��⽻֯�����֡2
subFrame3_table = table([3,6,9,12,15,18,21,24,27,30,33],:); %�ӱ������ȡ��֡3����
subFrame3 = reshape(subFrame3_table',1,528); %�ų�һ�У��⽻֯�����֡3

% CRCУ��
det = crc.detector([1 1 0 0 0 0 1 1 0 0 1 0 0 1 1 0 0 1 1 1 1 1 0 1 1]); %У����
[~, error2] = detect(det, subFrame2(1:600)'); %��֡2����������������
[~, error3] = detect(det, subFrame3(1:264)'); %��֡3
if error2~=0 || error3~=0 %У��ʧ��
    ephemeris = [];
    sf3 = [];
    return
end

bdPi = 3.1415926535898; 

% ת���ɶ�����01�ַ���
subFrame2 = dec2bin(subFrame2>0)'; %������
subFrame3 = dec2bin(subFrame3>0)'; %������

% �������漰���Ƕȣ���λȫת�ɻ��ȣ�
WN = bin2dec(subFrame2(1:13)); %2006��1��1��0ʱΪ��ʼ
HOW = bin2dec(subFrame2(14:21));
IODC = bin2dec(subFrame2(22:31));
IODE = bin2dec(subFrame2(32:39));
toe = bin2dec(subFrame2(40:50)) * 300; %�����ο�ʱ��
SatType = bin2dec(subFrame2(51:52)); %1:GEO 2:IGSO 3:MEO
dA = twosComp2dec(subFrame2(53:78)) * 2^(-9);
A_dot = twosComp2dec(subFrame2(79:103)) * 2^(-21);
dn0 = twosComp2dec(subFrame2(104:120)) * 2^(-44) * bdPi;
dn0_dot = twosComp2dec(subFrame2(121:143)) * 2^(-57) * bdPi;
M0 = twosComp2dec(subFrame2(144:176)) * 2^(-32) *bdPi;
e = twosComp2dec(subFrame2(177:209)) * 2^(-34);
omega = twosComp2dec(subFrame2(210:242)) * 2^(-32) * bdPi;
Omega0 = twosComp2dec(subFrame2(243:275)) * 2^(-32) * bdPi;
i0 = twosComp2dec(subFrame2(276:308)) * 2^(-32) * bdPi;
Omega_dot = twosComp2dec(subFrame2(309:327)) * 2^(-44) * bdPi;
i0_dot = twosComp2dec(subFrame2(328:342)) * 2^(-44) * bdPi;
Cis = twosComp2dec(subFrame2(343:358)) * 2^(-30);
Cic = twosComp2dec(subFrame2(359:374)) * 2^(-30);
Crs = twosComp2dec(subFrame2(375:398)) * 2^(-8);
Crc = twosComp2dec(subFrame2(399:422)) * 2^(-8);
Cus = twosComp2dec(subFrame2(423:443)) * 2^(-30);
Cuc = twosComp2dec(subFrame2(444:464)) * 2^(-30);
toc = bin2dec(subFrame2(465:475)) * 300; %�Ӳ�����ο�ʱ��
a0 = twosComp2dec(subFrame2(476:500)) * 2^(-34);
a1 = twosComp2dec(subFrame2(501:522)) * 2^(-50);
a2 = twosComp2dec(subFrame2(523:533)) * 2^(-66);
T_GDB2ap = twosComp2dec(subFrame2(534:545)) * 2^(-34);
ISC_B1Cd = twosComp2dec(subFrame2(546:557)) * 2^(-34);
T_GDB1Cp = twosComp2dec(subFrame2(558:569)) * 2^(-34);

ephemeris = zeros(30,1);
ephemeris(1) = WN;
ephemeris(2) = HOW;
ephemeris(3) = IODC;
ephemeris(4) = IODE;
ephemeris(5) = toe;
ephemeris(6) = SatType;
ephemeris(7) = dA;
ephemeris(8) = A_dot;
ephemeris(9) = dn0;
ephemeris(10) = dn0_dot;
ephemeris(11) = M0;
ephemeris(12) = e;
ephemeris(13) = omega;
ephemeris(14) = Omega0;
ephemeris(15) = i0;
ephemeris(16) = Omega_dot;
ephemeris(17) = i0_dot;
ephemeris(18) = Cis;
ephemeris(19) = Cic;
ephemeris(20) = Crs;
ephemeris(21) = Crc;
ephemeris(22) = Cus;
ephemeris(23) = Cuc;
ephemeris(24) = toc;
ephemeris(25) = a0;
ephemeris(26) = a1;
ephemeris(27) = a2;
ephemeris(28) = T_GDB2ap;
ephemeris(29) = ISC_B1Cd;
ephemeris(30) = T_GDB1Cp;

pageID = bin2dec(subFrame3(1:6)); %ҳ������
sf3.pageID = pageID;
sf3.HS = bin2dec(subFrame3(7:8)); %����״̬��0:���� 1::������/����
sf3.DIF = bin2dec(subFrame3(9)); %��������Ա�ʾ��0����
sf3.SIF = bin2dec(subFrame3(10)); %�ź�����Ա�ʾ��0����
sf3.AIF = bin2dec(subFrame3(11)); %ϵͳ�����ʶ��0����
sf3.SISMAI = bin2dec(subFrame3(12:15)); %�ռ��źż�⾫��ָ��
switch pageID
    case 1
        sf3.BDGIM = zeros(9,1); %����ȫ�������ӳ���������
        sf3.BDGIM(1) = bin2dec(subFrame3(43:52)) * 2^(-3);
        sf3.BDGIM(2) = twosComp2dec(subFrame3(53:60)) * 2^(-3);
        sf3.BDGIM(3) = bin2dec(subFrame3(61:68)) * 2^(-3);
        sf3.BDGIM(4) = bin2dec(subFrame3(69:76)) * 2^(-3);
        sf3.BDGIM(5) = bin2dec(subFrame3(77:84)) * -2^(-3);
        sf3.BDGIM(6) = twosComp2dec(subFrame3(85:92)) * 2^(-3);
        sf3.BDGIM(7) = twosComp2dec(subFrame3(93:100)) * 2^(-3);
        sf3.BDGIM(8) = twosComp2dec(subFrame3(101:108)) * 2^(-3);
        sf3.BDGIM(9) = twosComp2dec(subFrame3(109:116)) * 2^(-3);
    case 2
        
    case 3
        sf3.BGTO = zeros(6,1); %BDT-GNSSʱ��ͬ������
        sf3.BGTO(1) = bin2dec(subFrame3(159:161)); %GNSSϵͳ��ʶ
        sf3.BGTO(2) = bin2dec(subFrame3(162:174)); %�ο�ʱ������
        sf3.BGTO(3) = bin2dec(subFrame3(175:190))* 2^4; %�ο�ʱ�̶�Ӧ������ʱ��
        sf3.BGTO(4) = twosComp2dec(subFrame3(191:206)) * 2^(-35); %A0
        sf3.BGTO(5) = twosComp2dec(subFrame3(207:219)) * 2^(-51); %A1
        sf3.BGTO(6) = twosComp2dec(subFrame3(220:226)) * 2^(-68); %A2
    case 4
        
end

end