% ��ǰ��������������ָ֤���ļ�����B1C�źŸ�������
% �ڴ治�����л����
% ����һ�����Ǹ���20sʱ�仨��9s

clear
clc

%% �����ļ�
data_file = 'E:\GNSS data\B210_20190726_205109_ch1.dat';

%% ��ʱ��ʼ
tic

%% ������־�ļ�
curr_full_path = mfilename('fullpath'); %��ǰ��������·���������ļ���
[curr_path, ~] = fileparts(curr_full_path); %��ȡ��ǰ��������·��
fclose('all'); %�ر�֮ǰ�򿪵������ļ�
log_file = [curr_path,'\log.txt']; %��־�ļ�
logID = fopen(log_file, 'w'); %�ڵ�ǰ����·���´�����־�ļ���ʱ��˳�����־��

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

%% ��ȡ�ļ�ʱ��
tf = sscanf(data_file((end-22):(end-8)), '%4d%02d%02d_%02d%02d%02d')'; %�����ļ���ʼ����ʱ�䣨����ʱ�����飩
[tw, ts] = BDS_time(tf); %tw��BDT������ts��BDT��������
ta = [ts,0,0] + sample2dt(sample_offset, sampleFreq); %��ʼ�����ջ�ʱ�䣨������������[s,ms,us]
ta = time_carry(round(ta,2)); %ȡ��

%% �����б�
svList = 19;
% svList = [19;20;22;36;37;38];
svN = length(svList);

%% Ϊÿ�ſ��ܼ��������Ƿ������ͨ��
channels = cell(svN,1); %����cell
for k=1:svN %��������ͨ������
    channels{k} = BDS_B1C_channel(sampleFreq, buffSize, svList(k), logID);
end
% ���ݲ�������ʼ��ͨ��
% channels{1}.init([14319, -200], 0);
% channels{2}.init([19294,-2450], 0);
% channels{3}.init([29616, 2300], 0);
% channels{4}.init([13406, 3300], 0);
% channels{5}.init([15648,-2100], 0);
% channels{6}.init([27633,-1900], 0);

channels{1}.init([14319, -200], 0); %ͬ��
% channels{1}.init([19294,-2450], 0); %����
% channels{1}.init([29616, 2300], 0);
% channels{1}.init([13406, 3300], 0);
% channels{1}.init([15648,-2100], 0);
% channels{1}.init([27633,-1900], 0);

%% �������ٽ���洢�ռ�
trackResults = repmat(trackResult_struct(msToProcess), svN,1);
for k=1:svN
    trackResults(k).PRN = svList(k);
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
    ta = time_carry(ta + sample2dt(buffBlkSize, sampleFreq));
    
    %% ����
    for k=1:svN
        if channels{k}.state~=0
            while 1
                % �ж��Ƿ��������ĸ�������
                if mod(buffHead-channels{k}.trackDataHead,buffSize)>(buffSize/2)
                    break
                end
                % ����ٽ����ͨ��������
                n = trackResults(k).n;
                trackResults(k).dataIndex(n,:)    = channels{k}.dataIndex;
                trackResults(k).remCodePhase(n,:) = channels{k}.remCodePhase;
                trackResults(k).codeFreq(n,:)     = channels{k}.codeFreq;
                trackResults(k).remCarrPhase(n,:) = channels{k}.remCarrPhase;
                trackResults(k).carrFreq(n,:)     = channels{k}.carrFreq;
                % ��������
                trackDataHead = channels{k}.trackDataHead;
                trackDataTail = channels{k}.trackDataTail;
                if trackDataHead>trackDataTail
                    [I_Q, disc] = channels{k}.track(buff(:,trackDataTail:trackDataHead));
                else
                    [I_Q, disc] = channels{k}.track([buff(:,trackDataTail:end),buff(:,1:trackDataHead)]);
                end
                channels{k}.parse(ta); %����ע�͵���ֻ���ٲ�����
                % ����ٽ�������ٽ����
                trackResults(k).I_Q(n,:)          = I_Q;
                trackResults(k).disc(n,:)         = disc;
                trackResults(k).std(n,:)          = sqrt([channels{k}.varCode.D,channels{k}.varPhase.D]);
                trackResults(k).n                 = n + 1;
            end
        end
    end
    
end

%% �ر��ļ����رս�����
fclose(fileID);
fclose(logID);
close(f);

%% ɾ���հ�����
for k=1:svN
    trackResults(k) = trackResult_clean(trackResults(k));
end

%% ��ӡͨ����־
clc
listing = dir(log_file); %��־�ļ���Ϣ
if listing.bytes~=0 %�����־�ļ����ǿղŴ�ӡ
    print_log(log_file, svList);
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
    plot(ax1, trackResults(k).I_Q(1001:end,7),trackResults(k).I_Q(1001:end,8), 'LineStyle','none', 'Marker','.') %I/Qͼ
    plot(ax2, trackResults(k).dataIndex/sampleFreq, trackResults(k).I_Q(:,8)) %Q
    plot(ax2, trackResults(k).dataIndex/sampleFreq, trackResults(k).I_Q(:,7)) %I
    plot(ax4, trackResults(k).dataIndex/sampleFreq, trackResults(k).carrFreq, 'LineWidth',1.5) %�ز�Ƶ��
    
    % ����������
    set(ax2, 'XLim',[0,msToProcess/1000])
    set(ax3, 'XLim',[0,msToProcess/1000])
    set(ax4, 'XLim',[0,msToProcess/1000])
    set(ax5, 'XLim',[0,msToProcess/1000])
end

%% ��ʱ����
toc

%% ����
function trackResult = trackResult_struct(m)
% ���ٽ���ṹ��
    trackResult.PRN = 0;
    trackResult.n = 1; %ָ��ǰ�洢���к�
    
    trackResult.dataIndex     = zeros(m,1); %�����ڿ�ʼ��������ԭʼ�����ļ��е�λ��
    trackResult.remCodePhase  = zeros(m,1); %�����ڿ�ʼ�����������λ����Ƭ
    trackResult.codeFreq      = zeros(m,1); %��Ƶ��
    trackResult.remCarrPhase  = zeros(m,1); %�����ڿ�ʼ��������ز���λ����
    trackResult.carrFreq      = zeros(m,1); %�ز�Ƶ��
    trackResult.I_Q           = zeros(m,8); %[I_P,I_E,I_L,Q_P,Q_E,Q_L, I,Q]
    trackResult.disc          = zeros(m,2); %���������
    trackResult.std           = zeros(m,2); %�����������׼��
end

function trackResult = trackResult_clean(trackResult)
% ������ٽ���еĿհ׿ռ�
    n = trackResult.n;
    
    trackResult.dataIndex(n:end,:)    = [];
    trackResult.remCodePhase(n:end,:) = [];
    trackResult.codeFreq(n:end,:)     = [];
    trackResult.remCarrPhase(n:end,:) = [];
    trackResult.carrFreq(n:end,:)     = [];
    trackResult.I_Q(n:end,:)          = [];
    trackResult.disc(n:end,:)         = [];
    trackResult.std(n:end,:)          = [];
end