function acqResults = BDS_B1C_acq(file_path, sample_offset)
% ����B1C�źŲ���ֻ���������������ǣ�20ms���ݳ��ȣ�������ڱ���acqResults��
% B1C�ź�ֻ�ڱ�������MEO��IGSO�ϲ���
% sample_offset������ǰ���ٸ������㴦��ʼ����

%%
N = 40000; %��Ч���ȣ�10ms
Ns = 2*N; %����������20ms
fs = 4e6; %����Ƶ�ʣ�Hz
fc = 1.023e6; %��Ƶ�ʣ�Hz

carrFreq = -5e3:(fs/N/2):5e3; %Ƶ��������Χ��Ƶ�ʲ���50ms
M = length(carrFreq); %Ƶ����������

acqThreshold = 1.4; %������ֵ������ȵڶ�������ٱ�

%%
% ȡ20ms����
fileID = fopen(file_path, 'r');
    fseek(fileID, round(sample_offset*4), 'bof');
    if int32(ftell(fileID))~=int32(sample_offset*4)
        error('Sample offset error!');
    end
    baseband = double(fread(fileID, [2,Ns], 'int16'));
    baseband = baseband(1,:) + baseband(2,:)*1i; %������
fclose(fileID);

result = zeros(M,N); %����������������ز�Ƶ�ʣ���������λ
corrValue = zeros(M,1); %ÿ������Ƶ��������ֵ
corrIndex = zeros(M,1); %���ֵ��Ӧ������λ����

% �����б�
svList = [19:30,32:38]; %��ǰ���õı����������ǣ���ֹ��2019��10��29��19�ţ�38ΪIGSO������ΪMEO

% �沶��������һ������λ���ڶ����ز�Ƶ��
acqResults = NaN(length(svList),2);

%% �����㷨
for PRN=svList
%     B1Ccode = BDS_B1C_code_data(PRN);
    B1Ccode = BDS_B1C_code_pilot(PRN); %����Ƶ�������ܸ��ã���������һ������ط����
    B1Ccode = reshape([B1Ccode;-B1Ccode],10230*2,1)'; %�����ز��������������
    codes = B1Ccode(floor((0:N-1)*fc*2/fs) + 1); %�����������ز�����Ƶ�ʳ�2
    code = [zeros(1,N), codes]; %����
    CODE = fft(code); %��FFT
    
    %----����
    for k=1:M
        carrier = exp(-2*pi * carrFreq(k) * (0:Ns-1)/fs * 1i); %���ظ��ز�����Ƶ��
        x = baseband .* carrier;
        X = fft(x);
        Y = conj(X).*CODE;
        y = abs(ifft(Y));
        result(k,:) = y(1:N); %ֻȡǰN��
        [corrValue(k), corrIndex(k)] = max(result(k,:)); %Ѱ��һ����ص����ֵ��������
    end
    
    %----Ѱ����ط�
    [peakSize, index] = max(corrValue); %�����С�Ͷ�Ӧ��Ƶ������
    corrValue(mod(index+(-5:5)-1,M)+1) = 0; %�ų��������ط���Χ�ĵ�
    secondPeakSize = max(corrValue); %�ڶ����
    
    %----�����ź�
    if (peakSize/secondPeakSize)>acqThreshold
        % ��ͼ
        figure
        subplot(2,1,1) %����λ����
        plot(result(index,:)) %result����
        grid on
        title(['PRN = ',num2str(PRN)])
        subplot(2,1,2) %Ƶ�ʷ���
        plot(carrFreq, result(:,corrIndex(index))') %result����
        grid on
        drawnow
        %�洢������
        ki = find(svList==PRN,1);
        acqResults(ki,1) = corrIndex(index); %����λ
        acqResults(ki,2) = carrFreq(index); %�ز�Ƶ��
    end
end

acqResults = [svList', acqResults]; %��һ��������Ǳ��

end