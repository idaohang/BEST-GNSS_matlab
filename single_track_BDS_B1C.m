% ����B1C�źŸ���
% һ�����Ǹ���20sʱ�仨��9s

% �����������ӣ�F:\GNSS data\20190726\B210_20190726_205109_ch1.dat��19������

clear %�����
clc %����Ļ
fclose('all'); %���ļ�

%% �����ļ�
data_file_A = 'F:\GNSS data\20190726\B210_20190726_205109_ch1.dat';

%% ����ʱ��
msToProcess = 20*1*1000; %������ʱ��
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

%% ������������ͨ��
%--������־�ļ�
logFile_BDS_A = '.\temp\log_BDS_A.txt'; %��־�ļ�
logID_BDS_A = fopen(logFile_BDS_A, 'w');

%--�����б�
svList_BDS = 19;
% svList_BDS = [19;20;22;36;37;38];
svN_BDS = length(svList_BDS);

%--����ͨ��
channels_BDS_A = cell(svN_BDS,1); %����cell
for k=1:svN_BDS %��������ͨ������
    channels_BDS_A{k} = BDS_B1C_channel(sampleFreq, buffSize, svList_BDS(k), logID_BDS_A);
end

%--��ʼ��ͨ��
% channels_BDS_A{1}.init([14319, -200], 0);
% channels_BDS_A{2}.init([19294,-2450], 0);
% channels_BDS_A{3}.init([29616, 2300], 0);
% channels_BDS_A{4}.init([13406, 3300], 0);
% channels_BDS_A{5}.init([15648,-2100], 0);
% channels_BDS_A{6}.init([27633,-1900], 0);

channels_BDS_A{1}.init([14319, -200], 0);
% channels_BDS_A{1}.init([19294,-2450], 0);
% channels_BDS_A{1}.init([29616, 2300], 0);
% channels_BDS_A{1}.init([13406, 3300], 0);
% channels_BDS_A{1}.init([15648,-2100], 0);
% channels_BDS_A{1}.init([27633,-1900], 0);

%--ͨ������洢�ռ�
m = msToProcess + 10;
trackResults_BDS_A = struct('PRN',0, 'n',1, ...
'dataIndex',    zeros(m,1), ...
...'remCodePhase', zeros(m,1), ... %���Բ��棬ע�͵���ǰ���...
'codeFreq',     zeros(m,1), ...
...'remCarrPhase', zeros(m,1), ... %���Բ���
'carrFreq',     zeros(m,1), ...
'I_Q',          zeros(m,8), ...
'disc',         zeros(m,2), ...
'std',          zeros(m,2));
trackResults_BDS_A = repmat(trackResults_BDS_A, svN_BDS,1);
for k=1:svN_BDS
    trackResults_BDS_A(k).PRN = svList_BDS(k);
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
    
    %% BDS����
    for k=1:svN_BDS
        if channels_BDS_A{k}.state~=0
            while 1
                % �ж��Ƿ��������ĸ�������
                if mod(buffHead-channels_BDS_A{k}.trackDataHead,buffSize)>(buffSize/2)
                    break
                end
                % ����ٽ����ͨ��������
                n = trackResults_BDS_A(k).n;
                trackResults_BDS_A(k).dataIndex(n,:)    = channels_BDS_A{k}.dataIndex;
                % trackResults_BDS_A(k).remCodePhase(n,:) = channels_BDS_A{k}.remCodePhase;
                trackResults_BDS_A(k).codeFreq(n,:)     = channels_BDS_A{k}.codeFreq;
                % trackResults_BDS_A(k).remCarrPhase(n,:) = channels_BDS_A{k}.remCarrPhase;
                trackResults_BDS_A(k).carrFreq(n,:)     = channels_BDS_A{k}.carrFreq;
                % ��������
                trackDataHead = channels_BDS_A{k}.trackDataHead;
                trackDataTail = channels_BDS_A{k}.trackDataTail;
                if trackDataHead>trackDataTail
                    [I_Q, disc] = channels_BDS_A{k}.track(buff_A(:,trackDataTail:trackDataHead));
                else
                    [I_Q, disc] = channels_BDS_A{k}.track([buff_A(:,trackDataTail:end),buff_A(:,1:trackDataHead)]);
                end
                channels_BDS_A{k}.parse; %����ע�͵���ֻ���ٲ�����
                % ����ٽ�������ٽ����
                trackResults_BDS_A(k).I_Q(n,:)          = I_Q;
                trackResults_BDS_A(k).disc(n,:)         = disc;
                trackResults_BDS_A(k).std(n,:)          = sqrt([channels_BDS_A{k}.varCode.D,channels_BDS_A{k}.varPhase.D]);
                trackResults_BDS_A(k).n                 = n + 1;
            end
        end
    end
    
end

%% �ر��ļ����رս�����
fclose(fileID_A);
fclose(logID_BDS_A);
close(f);

%% ɾ���հ�����
trackResults_BDS_A = clean_trackResults(trackResults_BDS_A);

%% ��ӡͨ����־
clc
disp('<--------BDS A-------->')
print_log(logFile_BDS_A, svList_BDS);

%% ��ͼ
plot_track_BDS_A

%% �������
clearvars -except sampleFreq msToProcess tf ...
                  svList_BDS channels_BDS_A trackResults_BDS_A ...

%% ��ʱ����
toc