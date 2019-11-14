% ͬʱ����GPS�ͱ����ź�
clear %�����
clc %����Ļ
fclose('all'); %���ļ�

%% �����ļ�
data_file = 'E:\GNSS data\B210_20190726_205109_ch1.dat';

%% ����ʱ��
msToProcess = 60*1*1000; %������ʱ��
sample_offset = 0*4e6; %����ǰ���ٸ�������
sampleFreq = 4e6; %���ջ�����Ƶ��

%% ��ǰ�ļ���
curr_full_path = mfilename('fullpath'); %��ǰ��������·���������ļ���
[curr_path, ~] = fileparts(curr_full_path); %��ȡ��ǰ��������·��

%% ��ʱ��ʼ
tic

%% ��ʼ�����ջ�
%--���ݻ���
buffBlkNum = 40;                     %�������ݻ����������Ҫ��֤����ʱ�洢ǡ�ô�ͷ��ʼ��
buffBlkSize = 4000;                  %һ����Ĳ���������1ms��
buffSize = buffBlkSize * buffBlkNum; %�������ݻ����С
buff = zeros(2,buffSize);            %�������ݻ��棬��һ��I���ڶ���Q
buffBlkPoint = 0;                    %���ݸ����ڼ���棬��0��ʼ
buffHead = 0;                        %�������ݵ���ţ�buffBlkSize�ı���

%--���ջ�ʱ�� (GPSʱ��)
tf = sscanf(data_file((end-22):(end-8)), '%4d%02d%02d_%02d%02d%02d')'; %�����ļ���ʼ����ʱ�䣨����ʱ�����飩
[tw, ts] = GPS_time(tf); %tw��GPS������ts��GPS��������
ta = [ts,0,0] + sample2dt(sample_offset, sampleFreq); %��ʼ�����ջ�ʱ�䣨������������[s,ms,us]
ta = time_carry(round(ta,2)); %ȡ��

%--���ջ�״̬
receiverState = 0; %���ջ�״̬��0��ʾδ��ʼ����ʱ�仹���ԣ�1��ʾʱ���Ѿ�У��
deltaFreq = 0; %ʱ�Ӳ���Ϊ�ٷֱȣ������1e-9������1500e6Hz�Ĳ����1.5Hz
dtpos = 10; %��λʱ������ms
tp = [ta(1),0,0]; %tpΪ�´ζ�λʱ��
tp(2) = (floor(ta(2)/dtpos)+1) * dtpos; %�ӵ��¸���Ŀ��ʱ��
tp = time_carry(tp); %��λ

%% ����GPS����ͨ��
%--������־�ļ�
logFile_GPS_A = [curr_path,'\log_GPS_A.txt']; %��־�ļ�
logID_GPS_A = fopen(logFile_GPS_A, 'w');

%--�����б�
svList_GPS = [10;13;15;20;21;24];
svN_GPS = length(svList_GPS);

%--����ͨ��
channels_GPS_A = cell(svN_GPS,1); %����cell
for k=1:svN_GPS %��������ͨ������
    channels_GPS_A{k} = GPS_L1CA_channel(sampleFreq, buffSize, svList_GPS(k), logID_GPS_A);
end

%--��ʼ��ͨ��
channels_GPS_A{1}.init([2947, 3250], 0);
channels_GPS_A{2}.init([2704,-2750], 0);
channels_GPS_A{3}.init([2341,-1250], 0);
channels_GPS_A{4}.init([2772, 2250], 0);
channels_GPS_A{5}.init([2621, -750], 0);
channels_GPS_A{6}.init([1384, 2000], 0);

%--ͨ������洢�ռ�
m = msToProcess + 10;
trackResults_GPS_A = struct('PRN',0, 'n',1, ...
'dataIndex',    zeros(m,1), ...
...'remCodePhase', zeros(m,1), ... %���Բ��棬ע�͵���ǰ���...
'codeFreq',     zeros(m,1), ...
...'remCarrPhase', zeros(m,1), ... %���Բ���
'carrFreq',     zeros(m,1), ...
'I_Q',          zeros(m,6), ...
'disc',         zeros(m,3), ...
'std',          zeros(m,2));
trackResults_GPS_A = repmat(trackResults_GPS_A, svN_GPS,1);
for k=1:svN_GPS
    trackResults_GPS_A(k).PRN = svList_GPS(k);
end

%% ������������ͨ��
%--������־�ļ�
logFile_BDS_A = [curr_path,'\log_BDS_A.txt']; %��־�ļ�
logID_BDS_A = fopen(logFile_BDS_A, 'w');

%--�����б�
svList_BDS = [19;20;22;36;37;38];
svN_BDS = length(svList_BDS);

%--����ͨ��
channels_BDS_A = cell(svN_BDS,1); %����cell
for k=1:svN_BDS %��������ͨ������
    channels_BDS_A{k} = BDS_B1C_channel(sampleFreq, buffSize, svList_BDS(k), logID_BDS_A);
end

%--��ʼ��ͨ��
channels_BDS_A{1}.init([14319, -200], 0);
channels_BDS_A{2}.init([19294,-2450], 0);
channels_BDS_A{3}.init([29616, 2300], 0);
channels_BDS_A{4}.init([13406, 3300], 0);
channels_BDS_A{5}.init([15648,-2100], 0);
channels_BDS_A{6}.init([27633,-1900], 0);

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
fileID = fopen(data_file, 'r');
fseek(fileID, round(sample_offset*4), 'bof'); %��ȡ�����ܳ����ļ�ָ���Ʋ���ȥ
if int64(ftell(fileID))~=int64(sample_offset*4)
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
    buff(:,buffBlkPoint*buffBlkSize+(1:buffBlkSize)) = double(fread(fileID, [2,buffBlkSize], 'int16')); %ȡ���ݣ������������������
    buffBlkPoint = buffBlkPoint + 1;
    buffHead = buffBlkPoint * buffBlkSize;
    if buffBlkPoint==buffBlkNum
        buffBlkPoint = 0; %�����ͷ��ʼ
    end
    
    %% ���½��ջ�ʱ��
    sampleFreq0 = sampleFreq * (1+deltaFreq); %��ʵ����Ƶ��
    ta = time_carry(ta + sample2dt(buffBlkSize, sampleFreq0));
    
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
                channels_GPS_A{k}.set_deltaFreq(deltaFreq); %����ͨ��Ƶ������֤����Ƶ����׼��
                trackDataHead = channels_GPS_A{k}.trackDataHead;
                trackDataTail = channels_GPS_A{k}.trackDataTail;
                if trackDataHead>trackDataTail
                    [I_Q, disc] = channels_GPS_A{k}.track(buff(:,trackDataTail:trackDataHead));
                else
                    [I_Q, disc] = channels_GPS_A{k}.track([buff(:,trackDataTail:end),buff(:,1:trackDataHead)]);
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
                channels_BDS_A{k}.set_deltaFreq(deltaFreq); %����ͨ��Ƶ������֤����Ƶ����׼��
                trackDataHead = channels_BDS_A{k}.trackDataHead;
                trackDataTail = channels_BDS_A{k}.trackDataTail;
                if trackDataHead>trackDataTail
                    [I_Q, disc] = channels_BDS_A{k}.track(buff(:,trackDataTail:trackDataHead));
                else
                    [I_Q, disc] = channels_BDS_A{k}.track([buff(:,trackDataTail:end),buff(:,1:trackDataHead)]);
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
    
    %% ��λ
    
end

%% �ر��ļ����رս�����
fclose(fileID);
fclose(logID_GPS_A);
fclose(logID_BDS_A);
close(f);

%% ɾ���հ�����
trackResults_GPS_A = trackResults_clean(trackResults_GPS_A);
trackResults_BDS_A = trackResults_clean(trackResults_BDS_A);

%% ��ӡͨ����־
clc
disp('<--------GPS A-------->')
print_log(logFile_GPS_A, svList_GPS);
disp('<--------BDS A-------->')
print_log(logFile_BDS_A, svList_BDS);

%% ��ͼ
plot_trackResults_GPS(trackResults_GPS_A, msToProcess, sampleFreq)
plot_trackResults_BDS(trackResults_BDS_A, msToProcess, sampleFreq)

%% ��ʱ����
toc

%% ��ͼ����
function plot_trackResults_GPS(trackResults, msToProcess, sampleFreq)
    for k=1:size(trackResults,1)
        if trackResults(k).n==1 %����û���ٵ�ͨ��
            continue
        end

        % ����������
        screenSize = get(0,'ScreenSize'); %��ȡ��Ļ�ߴ�
        if screenSize(3)==1920 %������Ļ�ߴ����û�ͼ��Χ
            figure('Position', [390, 280, 1140, 670]);
        elseif screenSize(3)==1368 %SURFACE
            figure('Position', [114, 100, 1140, 670]);
        elseif screenSize(3)==1440 %С��Ļ
            figure('Position', [150, 100, 1140, 670]);
        elseif screenSize(3)==1600 %T430
            figure('Position', [230, 100, 1140, 670]);
        else
            error('Screen size error!')
        end
        ax1 = axes('Position', [0.08, 0.4, 0.38, 0.53]);
        hold(ax1,'on');
        axis(ax1, 'equal');
        title(['PRN = ',num2str(trackResults(k).PRN)])
        ax2 = axes('Position', [0.53, 0.7 , 0.42, 0.25]);
        hold(ax2,'on');
        ax3 = axes('Position', [0.53, 0.38, 0.42, 0.25]);
        hold(ax3,'on');
        grid(ax3,'on');
        ax4 = axes('Position', [0.53, 0.06, 0.42, 0.25]);
        hold(ax4,'on');
        grid(ax4,'on');
        ax5 = axes('Position', [0.05, 0.06, 0.42, 0.25]);
        hold(ax5,'on');
        grid(ax5,'on');

        % ��ͼ
        plot(ax1, trackResults(k).I_Q(1001:end,1),trackResults(k).I_Q(1001:end,4), 'LineStyle','none', 'Marker','.') %I/Qͼ
        plot(ax2, trackResults(k).dataIndex/sampleFreq, trackResults(k).I_Q(:,1))
        plot(ax4, trackResults(k).dataIndex/sampleFreq, trackResults(k).carrFreq, 'LineWidth',1.5) %�ز�Ƶ��
        plot(ax5, trackResults(k).dataIndex/sampleFreq, trackResults(k).disc(:,1))
        plot(ax5, trackResults(k).dataIndex/sampleFreq, trackResults(k).std(:,1))

        % ����������
        set(ax2, 'XLim',[0,msToProcess/1000])
        set(ax3, 'XLim',[0,msToProcess/1000])
        set(ax4, 'XLim',[0,msToProcess/1000])
        set(ax5, 'XLim',[0,msToProcess/1000])
    end
end

function plot_trackResults_BDS(trackResults, msToProcess, sampleFreq)
    for k=1:size(trackResults,1)
        if trackResults(k).n==1 %����û���ٵ�ͨ��
            continue
        end

        % ����������
        screenSize = get(0,'ScreenSize'); %��ȡ��Ļ�ߴ�
        if screenSize(3)==1920 %������Ļ�ߴ����û�ͼ��Χ
            figure('Position', [390, 280, 1140, 670]);
        elseif screenSize(3)==1368 %SURFACE
            figure('Position', [114, 100, 1140, 670]);
        elseif screenSize(3)==1440 %С��Ļ
            figure('Position', [150, 100, 1140, 670]);
        elseif screenSize(3)==1600 %T430
            figure('Position', [230, 100, 1140, 670]);
        else
            error('Screen size error!')
        end
        ax1 = axes('Position', [0.08, 0.4, 0.38, 0.53]);
        hold(ax1,'on');
        axis(ax1, 'equal');
        title(['PRN = ',num2str(trackResults(k).PRN)])
        ax2 = axes('Position', [0.53, 0.7 , 0.42, 0.25]);
        hold(ax2,'on');
        ax3 = axes('Position', [0.53, 0.38, 0.42, 0.25]);
        hold(ax3,'on');
        grid(ax3,'on');
        ax4 = axes('Position', [0.53, 0.06, 0.42, 0.25]);
        hold(ax4,'on');
        grid(ax4,'on');
        ax5 = axes('Position', [0.05, 0.06, 0.42, 0.25]);
        hold(ax5,'on');
        grid(ax5,'on');

        % ��ͼ
        plot(ax1, trackResults(k).I_Q(1001:end,7),trackResults(k).I_Q(1001:end,8), 'LineStyle','none', 'Marker','.') %I/Qͼ
        plot(ax2, trackResults(k).dataIndex/sampleFreq, trackResults(k).I_Q(:,8)) %Q
        plot(ax2, trackResults(k).dataIndex/sampleFreq, trackResults(k).I_Q(:,7)) %I
        plot(ax4, trackResults(k).dataIndex/sampleFreq, trackResults(k).carrFreq, 'LineWidth',1.5) %�ز�Ƶ��
        plot(ax5, trackResults(k).dataIndex/sampleFreq, trackResults(k).disc(:,1))
        plot(ax5, trackResults(k).dataIndex/sampleFreq, trackResults(k).std(:,1))

        % ����������
        set(ax2, 'XLim',[0,msToProcess/1000])
        set(ax3, 'XLim',[0,msToProcess/1000])
        set(ax4, 'XLim',[0,msToProcess/1000])
        set(ax5, 'XLim',[0,msToProcess/1000])
    end
end