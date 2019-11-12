% ��֤ʵ�ʴ�����������µ������
% �������񡢸��٣�ȷ������λ��׼ȷ���ز�Ƶ��
% ��������������õĲ�������������ͬ���ʱ���µ�����ؽ����ʱ��Խ�������������Խƽ��

% �ļ�·��
file_path = 'E:\GNSS data\B210_20190726_205109_ch1.dat';

PRN = 15;
acqCodePhase = 2341; %��������λ���
carrFreq = -1227+0; %���ٵõ����ز�Ƶ�ʣ��Ӹ�����Ƶ�������ʱ����ؽ��

fs = 4e6; %����Ƶ�ʣ�Hz
fc = 1.023e6; %��Ƶ�ʣ�Hz
Nc = 40000; %һ�������ڵĲ�������
N = 40000; %������õĲ���������4000��Ӧ1ms��40000��Ӧ10ms

% ȡ��ǰ��100ms�ĵ�
fclose('all');
fileID = fopen(file_path, 'r');
baseband = double(fread(fileID, [2,100*4e3], 'int16'));
baseband = baseband(1,:) + baseband(2,:)*1i; %������
fclose(fileID);

% �������ڿ�ʼ������ȡһ���������ڵ�����
index = Nc - acqCodePhase + 2; %����õ��������ڿ�ʼ�������
data = baseband(index:index+N-1);

carrier = exp(-2*pi * carrFreq * (0:N-1)/fs * 1i); %���ظ��ز�����Ƶ��

x = data .* carrier; %�����źų��ز�

CAcode = GPS_L1_CA_generate(PRN);

phase = -2:0.01:2; %������λ����
n = length(phase);
R = zeros(n,1); %����

for k=1:n
    code = CAcode(mod(floor((0:N-1)*fc/fs+phase(k)),1023) + 1); %�����������λƫ��
    R(k) = x * code'; %��������أ�����������λ��
end

figure
Rm = abs(R); %R��ģ��
plot(phase+0.04, Rm/max(Rm))
grid on
% ����max(Rm)������һ��������Ƿ�������ʹ���ֵ�����и�������1/-1ʹ����Ϊ��
% phase����ֵʹ��ֵ�����룬��ͼ������Ϊ����õ�����λֵ����ֱ�ӵõ��ķ�ֵ����ƫһ�㣬ƫ��Խ���ʾ����ȷ������λ���Խ��