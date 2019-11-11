% ָ��PRN��������һ�����ǽ��в������������ֵ�Ƿ�仯

sample_offset = 0*4e6;
file_path = 'E:\GNSS data\B210_20190726_205109_ch1.dat';
PRN = 20;

N = 40000; %��Ч���ȣ�10ms
Ns = 2*N; %����������20ms
fs = 4e6; %����Ƶ�ʣ�Hz
fc = 1.023e6; %��Ƶ�ʣ�Hz

carrFreq = -5e3:(fs/N/2):5e3; %Ƶ��������Χ��Ƶ�ʲ���50ms
M = length(carrFreq); %Ƶ����������
result = zeros(M,N); %����������������ز�Ƶ�ʣ���������λ
corrValue = zeros(M,1); %ÿ������Ƶ��������ֵ
corrIndex = zeros(M,1); %���ֵ��Ӧ������λ����

% ��ͼ
YLim = [0,2e6];
figure
subplot(2,1,1)
h1 = plot(result(1,:));
set(gca, 'YLim', YLim)
grid on
title(['PRN = ',num2str(PRN)])
subplot(2,1,2)
h2 = plot(carrFreq, result(:,1)');
set(gca, 'YLim', YLim)
grid on

% α��
B1Ccode = BDS_B1C_pilot_generate(PRN); %����Ƶ�������ܸ��ã���������һ������ط����
B1Ccode = reshape([B1Ccode;-B1Ccode],10230*2,1)'; %�����ز��������������
codes = B1Ccode(floor((0:N-1)*fc*2/fs) + 1); %����
code = [zeros(1,N), codes]; %����
CODE = fft(code); %��FFT

% ���ļ�
fclose('all'); %�ر�֮ǰ�򿪵������ļ�
fileID = fopen(file_path, 'r');
fseek(fileID, round(sample_offset*4), 'bof');
if int32(ftell(fileID))~=int32(sample_offset*4)
    error('Sample offset error!');
end

for n=1:100
    baseband = double(fread(fileID, [2,Ns], 'int16')); %ȡ20ms����
    baseband = baseband(1,:) + baseband(2,:)*1i; %������
    for k=1:M
        carrier = exp(-2*pi * carrFreq(k) * (0:Ns-1)/fs * 1i); %���ظ��ز�����Ƶ��
        x = baseband .* carrier;
        X = fft(x);
        Y = conj(X).*CODE;
        y = abs(ifft(Y));
        result(k,:) = y(1:N); %ֻȡǰN��
        [corrValue(k), corrIndex(k)] = max(result(k,:)); %Ѱ��һ����ص����ֵ��������
    end
    % Ѱ����ط�
    [~, index] = max(corrValue); %�����С�Ͷ�Ӧ��Ƶ������
    % ��ͼ
    set(h1, 'Ydata', result(index,:));
    set(h2, 'Ydata', result(:,corrIndex(index))');
    drawnow
end

fclose(fileID);