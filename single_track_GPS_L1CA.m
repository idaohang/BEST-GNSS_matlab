% GPS L1CA����
% һ�����Ǹ���20sʱ�仨��8.5s

% �����������ӣ�F:\GNSS data\20190726\B210_20190726_205109_ch1.dat��15������

clear %�����
clc %����Ļ
fclose('all'); %���ļ�

%% �����ļ�
% data_file_A = 'F:\GNSS data\20190726\B210_20190726_205109_ch1.dat';
data_file_A = 'F:\GNSS data\20190826\B210_20190826_104744_ch1.dat';

%% ����ʱ��
msToProcess = 300*1*1000; %������ʱ��
sample_offset = 0*4e6; %����ǰ���ٸ�������
sampleFreq = 4e6; %���ջ�����Ƶ��

%% ��ʱ��ʼ
tic

%% ��ʼ�����ջ�
%--���ݻ���
buffBlkNum = 40;                     %�������ݻ����������Ҫ��֤����ʱ�洢ǡ�ô�ͷ��ʼ��
buffBlkSize = 4000;                  %һ����Ĳ���������1ms��
buffSize = buffBlkSize * buffBlkNum; %�������ݻ����С
buff_A = zeros(2,buffSize);          %�������ݻ��棬��һ��I���ڶ���Q
buffBlkPoint = 0;                    %���ݸ����ڼ���棬��0��ʼ
buffHead = 0;                        %�������ݵ���ţ�buffBlkSize�ı���

%% ����GPS����ͨ��
%--������־�ļ�
logFile_GPS_A = '.\temp\log_GPS_A.txt'; %��־�ļ�
logID_GPS_A = fopen(logFile_GPS_A, 'w');

%--�����б�
svList_GPS = 6;
% svList_GPS = 15;
% svList_GPS = [10;13;15;20;21;24];
svN_GPS = length(svList_GPS);

%--����ͨ��
channels_GPS_A = cell(svN_GPS,1); %����cell
for k=1:svN_GPS %��������ͨ������
    channels_GPS_A{k} = GPS_L1CA_channel(sampleFreq, buffSize, svList_GPS(k), logID_GPS_A);
end

%--��ʼ��ͨ��
% channels_GPS_A{1}.init([2947, 3250], 0);
% channels_GPS_A{2}.init([2704,-2750], 0);
% channels_GPS_A{3}.init([2341,-1250], 0);
% channels_GPS_A{4}.init([2772, 2250], 0);
% channels_GPS_A{5}.init([2621, -750], 0);
% channels_GPS_A{6}.init([1384, 2000], 0);

% channels_GPS_A{1}.init([2947, 3250], 0);
% channels_GPS_A{1}.init([2704,-2750], 0);
% channels_GPS_A{1}.init([2341,-1250], 0);
% channels_GPS_A{1}.init([2772, 2250], 0);
% channels_GPS_A{1}.init([2621, -750], 0);
% channels_GPS_A{1}.init([1384, 2000], 0);

channels_GPS_A{1}.init([ 301, 1750], 0);

%--ͨ������洢�ռ�
m = msToProcess + 10;
trackResults_GPS = struct('PRN',0, 'n',1, ...
'dataIndex',    zeros(m,1), ...
...'remCodePhase', zeros(m,1), ... %���Բ��棬ע�͵���ǰ���...
'codeFreq',     zeros(m,1), ...
...'remCarrPhase', zeros(m,1), ... %���Բ���
'carrFreq',     zeros(m,1), ...
'I_Q',          zeros(m,6), ...
'disc',         zeros(m,3), ...
'std',          zeros(m,2));
trackResults_GPS_A = repmat(trackResults_GPS, svN_GPS,1);
clearvars trackResults_GPS
for k=1:svN_GPS
    trackResults_GPS_A(k).PRN = svList_GPS(k);
end

%% ���ļ�������������
fileID_A = fopen(data_file_A, 'r');
fseek(fileID_A, round(sample_offset*4), 'bof'); %��ȡ�����ܳ����ļ�ָ���Ʋ���ȥ
if int64(ftell(fileID_A))~=int64(sample_offset*4)
    error('Sample offset error!');
end
f = waitbar(0, ['0s/',num2str(msToProcess/1000),'s']);

%% �źŴ���
for t=1:msToProcess
    %% ���½�����
    if mod(t,1000)==0 %1s����
        waitbar(t/msToProcess, f, [num2str(t/1000),'s/',num2str(msToProcess/1000),'s']);
    end
    
    %% ������
    buff_A(:,buffBlkPoint*buffBlkSize+(1:buffBlkSize)) = double(fread(fileID_A, [2,buffBlkSize], 'int16')); %ȡ���ݣ������������������
    buffBlkPoint = buffBlkPoint + 1;
    buffHead = buffBlkPoint * buffBlkSize;
    if buffBlkPoint==buffBlkNum
        buffBlkPoint = 0; %�����ͷ��ʼ
    end
    
    %% GPS����
    for k=1:svN_GPS
        if channels_GPS_A{k}.state~=0
            while 1
                % �ж��Ƿ��������ĸ�������
                if mod(buffHead-channels_GPS_A{k}.trackDataHead,buffSize)>(buffSize/2)
                    break
                end
                % ����ٽ����ͨ��������
                n = trackResults_GPS_A(k).n;
                trackResults_GPS_A(k).dataIndex(n,:)    = channels_GPS_A{k}.dataIndex;
                % trackResults_GPS_A(k).remCodePhase(n,:) = channels_GPS_A{k}.remCodePhase;
                trackResults_GPS_A(k).codeFreq(n,:)     = channels_GPS_A{k}.codeFreq;
                % trackResults_GPS_A(k).remCarrPhase(n,:) = channels_GPS_A{k}.remCarrPhase;
                trackResults_GPS_A(k).carrFreq(n,:)     = channels_GPS_A{k}.carrFreq;
                % ��������
                trackDataHead = channels_GPS_A{k}.trackDataHead;
                trackDataTail = channels_GPS_A{k}.trackDataTail;
                if trackDataHead>trackDataTail
                    [I_Q, disc] = channels_GPS_A{k}.track(buff_A(:,trackDataTail:trackDataHead));
                else
                    [I_Q, disc] = channels_GPS_A{k}.track([buff_A(:,trackDataTail:end),buff_A(:,1:trackDataHead)]);
                end
                channels_GPS_A{k}.parse; %����ע�͵���ֻ���ٲ�����
                % ����ٽ�������ٽ����
                trackResults_GPS_A(k).I_Q(n,:)          = I_Q;
                trackResults_GPS_A(k).disc(n,:)         = disc;
                trackResults_GPS_A(k).std(n,:)          = sqrt([channels_GPS_A{k}.varCode.D,channels_GPS_A{k}.varPhase.D]);
                trackResults_GPS_A(k).n                 = n + 1;
            end
        end
    end
    
end

%% �ر��ļ����رս�����
fclose(fileID_A);
fclose(logID_GPS_A);
close(f);

%% ɾ���հ�����
trackResults_GPS_A = clean_trackResults(trackResults_GPS_A);

%% ��ӡͨ����־
clc
disp('<--------GPS A-------->')
print_log(logFile_GPS_A, svList_GPS);

%% ��ͼ
plot_track_GPS_A

%% �������
clearvars -except sampleFreq msToProcess tf ...
                  svList_GPS channels_GPS_A trackResults_GPS_A ...

%% ��ʱ����
toc