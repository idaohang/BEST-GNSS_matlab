% һ�����Ǹ���20s��ʱԼ9s

clear
clc

%%
tic

%% �ļ���
file_path = 'E:\GNSS data\B210_20190726_205109_ch1.dat';

%% ����ʱ��
msToProcess = 20*1*1000; %������ʱ��
sample_offset = 0*4e6; %����ǰ���ٸ�������
sampleFreq = 4e6; %���ջ�����Ƶ��

%% ���ݻ���
buffBlkNum = 40;                     %�������ݻ����������Ҫ��֤����ʱ�洢ǡ�ô�ͷ��ʼ��
buffBlkSize = 4000;                  %һ����Ĳ���������1ms��
buffSize = buffBlkSize * buffBlkNum; %�������ݻ����С
buff = zeros(2,buffSize);            %�������ݻ��棬��һ��I���ڶ���Q
buffBlkPoint = 0;                    %���ݸ����ڼ���棬��0��ʼ
buffHead = 0;                        %�������ݵ���ţ�buffBlkSize�ı���

%% �����б�
svList = 19;
% svList = [19;20;22;36;37;38];
svN = length(svList);

%% Ϊÿ�ſ��ܼ��������Ƿ������ͨ��
channels = repmat(BDS_B1C_channel_struct(), svN,1); %ֻ�����˳���������Ϣ��Ϊ��
for k=1:svN
    channels(k).PRN = svList(k); %ÿ��ͨ�������Ǻ�
    channels(k).state = 0; %״̬δ����
end
% ���ݲ�������ʼ��ͨ��
channels(1) = BDS_B1C_channel_init(channels(1), [14319-0, -200], 0, sampleFreq); %����������2��������ʱ����������������غ����ĸ��壻4M�β���Ƶ���£��벶��������Ϊ0.125��Ƭ
% channels(2) = BDS_B1C_channel_init(channels(2), [19294,-2450], 0, sampleFreq);
% channels(3) = BDS_B1C_channel_init(channels(3), [29616, 2300], 0, sampleFreq);
% channels(4) = BDS_B1C_channel_init(channels(4), [13406, 3300], 0, sampleFreq);
% channels(5) = BDS_B1C_channel_init(channels(5), [15648,-2100], 0, sampleFreq);
% channels(6) = BDS_B1C_channel_init(channels(6), [27633,-1900], 0, sampleFreq);

%% �������ٽ���洢�ռ�
trackResults = repmat(trackResult_struct(msToProcess), svN,1);
for k=1:svN
    trackResults(k).PRN = svList(k);
end

%% ���ļ�������������
fclose('all');
fileID = fopen(file_path, 'r');
fseek(fileID, round(sample_offset*4), 'bof'); %��ȡ�����ܳ����ļ�ָ���Ʋ���ȥ
if int64(ftell(fileID))~=int64(sample_offset*4)
    error('Sample offset error!');
end
f = waitbar(0, ['0s/',num2str(msToProcess/1000),'s']);

%% �źŴ���
for t=1:msToProcess
    if mod(t,1000)==0 %1s����
        waitbar(t/msToProcess, f, [num2str(t/1000),'s/',num2str(msToProcess/1000),'s']);
    end
    
    buff(:,buffBlkPoint*buffBlkSize+(1:buffBlkSize)) = double(fread(fileID, [2,buffBlkSize], 'int16')); %ȡ���ݣ������������������
    buffBlkPoint = buffBlkPoint + 1;
    buffHead = buffBlkPoint * buffBlkSize;
    if buffBlkPoint==buffBlkNum
        buffBlkPoint = 0; %�����ͷ��ʼ
    end
    
    for k=1:svN
        if channels(k).state~=0
            while 1
                % �ж��Ƿ��������ĸ�������
                if mod(buffHead-channels(k).trackDataHead,buffSize)>(buffSize/2)
                    break
                end
                % ����ٽ����ͨ��������
                n = trackResults(k).n;
                trackResults(k).dataIndex(n,:)    = channels(k).dataIndex;
                trackResults(k).remCodePhase(n,:) = channels(k).remCodePhase;
                trackResults(k).codeFreq(n,:)     = channels(k).codeFreq;
                trackResults(k).remCarrPhase(n,:) = channels(k).remCarrPhase;
                trackResults(k).carrFreq(n,:)     = channels(k).carrFreq;
                % ��������
                trackDataHead = channels(k).trackDataHead;
                trackDataTail = channels(k).trackDataTail;
                if trackDataHead>trackDataTail
                    [channels(k), I_Q, disc] = ...
                        BDS_B1C_track(channels(k), sampleFreq, buffSize, buff(:,trackDataTail:trackDataHead));
                else
                    [channels(k), I_Q, disc] = ...
                        BDS_B1C_track(channels(k), sampleFreq, buffSize, [buff(:,trackDataTail:end),buff(:,1:trackDataHead)]);
                end
                % ����ٽ�������ٽ����
                trackResults(k).I_Q(n,:)          = I_Q;
                trackResults(k).disc(n,:)         = disc;
                trackResults(k).n                 = n + 1;
            end
        end
    end
end

%% �ر��ļ����رս�����
fclose(fileID);
close(f);

%% ɾ���հ�����
for k=1:svN
    trackResults(k) = trackResult_clean(trackResults(k));
end

%% ��ͼ
for k=1:svN
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
    title(['PRN = ',num2str(svList(k))])
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
    plot(ax2, trackResults(k).dataIndex/sampleFreq, trackResults(k).I_Q(:,4)) %I_Qͼ
    plot(ax2, trackResults(k).dataIndex/sampleFreq, trackResults(k).I_Q(:,1)) %I_Pͼ
    plot(ax4, trackResults(k).dataIndex/sampleFreq, trackResults(k).carrFreq, 'LineWidth',1.5) %�ز�Ƶ��
    
    % ����������
    set(ax2, 'XLim',[0,msToProcess/1000])
    set(ax3, 'XLim',[0,msToProcess/1000])
    set(ax4, 'XLim',[0,msToProcess/1000])
    set(ax5, 'XLim',[0,msToProcess/1000])
end

%%
toc