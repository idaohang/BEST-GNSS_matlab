% ��ǰ��������������ָ֤���ļ�GPS L1CA�źŶ�λ����
% ��λʱ������Ӱ�춨λ��������

clear
clc

%% �����ļ�
data_file = 'E:\GNSS data\B210_20190726_205109_ch2.dat';

%% ��ʱ��ʼ
tic

%% ������־�ļ�
curr_full_path = mfilename('fullpath'); %��ǰ��������·���������ļ���
[curr_path, ~] = fileparts(curr_full_path); %��ȡ��ǰ��������·��
fclose('all'); %�ر�֮ǰ�򿪵������ļ�
log_file = [curr_path,'\log.txt']; %��־�ļ�
logID = fopen(log_file, 'w'); %�ڵ�ǰ����·���´�����־�ļ���ʱ��˳�����־��

%% ����ʱ��
msToProcess = 200*1*1000; %������ʱ��
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
[tw, ts] = GPS_time(tf); %tw��GPS������ts��GPS��������
ta = [ts,0,0] + sample2dt(sample_offset, sampleFreq); %��ʼ�����ջ�ʱ�䣨������������[s,ms,us]
ta = time_carry(round(ta,2)); %ȡ��

%% �����б�
svList = [10;13;15;20;21;24];
% svList = [13;15;20;21;24];
svN = length(svList);

%% Ϊÿ�ſ��ܼ��������Ƿ������ͨ��
channels = cell(svN,1); %����cell
for k=1:svN %��������ͨ������
    channels{k} = GPS_L1CA_channel(sampleFreq, buffSize, svList(k), logID);
end
% ���ݲ�������ʼ��ͨ��
channels{1}.init([2947, 3250], 0);
channels{2}.init([2704,-2750], 0);
channels{3}.init([2341,-1250], 0);
channels{4}.init([2772, 2250], 0);
channels{5}.init([2621, -750], 0);
channels{6}.init([1384, 2000], 0);

% channels{1}.init([2704,-2750], 0);
% channels{2}.init([2341,-1250], 0);
% channels{3}.init([2772, 2250], 0);
% channels{4}.init([2621, -750], 0);
% channels{5}.init([1384, 2000], 0);

%% �������ٽ���洢�ռ�
trackResults = repmat(trackResult_struct(msToProcess), svN,1);
for k=1:svN
    trackResults(k).PRN = svList(k);
end

%% ���ջ�״̬
receiverState = 0; %���ջ�״̬��0��ʾδ��ʼ����ʱ�仹���ԣ�1��ʾʱ���Ѿ�У��
deltaFreq = 0; %ʱ�Ӳ���Ϊ�ٷֱȣ������1e-9������1500e6Hz�Ĳ����1.5Hz
dtpos = 10; %��λʱ������ms
tp = [ta(1),0,0]; %tpΪ�´ζ�λʱ��
tp(2) = (floor(ta(2)/dtpos)+1) * dtpos; %�ӵ��¸���Ŀ��ʱ��
tp = time_carry(tp); %��λ

%% �������ջ�����洢�ռ�
nRow = msToProcess/dtpos;
no = 1; %ָ��ǰ�洢��
output_ta  = NaN(nRow,2); %��һ��Ϊʱ�䣨s�����ڶ���Ϊ���ջ�״̬
output_pos = NaN(nRow,8); %��λ��[λ�á��ٶȡ��Ӳ��Ƶ��]
output_sv  = NaN(svN,8,nRow); %������Ϣ��[λ�á�α�ࡢ�ٶȡ�α����]
output_df  = NaN(nRow,1); %�����õ���Ƶ��˲������Ƶ�

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
    sampleFreq0 = sampleFreq * (1+deltaFreq); %��ʵ�Ĳ���Ƶ��
    ta = time_carry(ta + sample2dt(buffBlkSize, sampleFreq0));
    
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
                channels{k}.set_deltaFreq(deltaFreq); %����ͨ��Ƶ������֤����Ƶ����׼��
                trackDataHead = channels{k}.trackDataHead;
                trackDataTail = channels{k}.trackDataTail;
                if trackDataHead>trackDataTail
                    [I_Q, disc] = channels{k}.track(buff(:,trackDataTail:trackDataHead));
                else
                    [I_Q, disc] = channels{k}.track([buff(:,trackDataTail:end),buff(:,1:trackDataHead)]);
                end
                channels{k}.parse; %����ע�͵���ֻ���ٲ�����
                % ����ٽ�������ٽ����
                trackResults(k).I_Q(n,:)          = I_Q;
                trackResults(k).disc(n,:)         = disc;
                trackResults(k).std(n,:)          = sqrt([channels{k}.varCode.D,channels{k}.varPhase.D]);
                trackResults(k).n                 = n + 1;
            end
        end
    end
    
    %% ��λ
    dtp = (ta(1)-tp(1)) + (ta(2)-tp(2))/1e3 + (ta(3)-tp(3))/1e6;
    if dtp>=0
        % 1.��������λ�á��ٶȣ�����α�ࡢα����
        sv = NaN(svN,8);
        R = zeros(svN,1); %�����������
        for k=1:svN
            if channels{k}.state==2
                dn = mod(buffHead-channels{k}.trackDataTail+1, buffSize) - 1; %trackDataTailǡ�ó�ǰbuffHeadһ��ʱ��dn=-1
                dtc = dn / sampleFreq0; %��ǰ����ʱ������ٵ��ʱ���
                dt = dtc - dtp; %��λ�㵽���ٵ��ʱ���
                codePhase = channels{k}.remCodePhase + dt*channels{k}.codeFreq; %��λ������λ
                ts0 = [floor(channels{k}.ts0/1e3), mod(channels{k}.ts0,1e3), 0] + [0, floor(codePhase/1023), mod(codePhase/1023,1)*1e3]; %��λ����뷢��ʱ��
                [sv(k,:),~] = GPS_L1CA_ephemeris_rho(channels{k}.ephemeris, tp, ts0); %����������������[λ�á�α�ࡢ�ٶ�]
                sv(k,8) = -(channels{k}.carrFreq/1575.42e6 + deltaFreq) * 299792458; %�ز�Ƶ��ת��Ϊ�ٶ�
                sv(k,8) = sv(k,8) + channels{k}.ephemeris(9)*299792458; %��������Ƶ������ӿ���α����ƫС
                R(k) = channels{k}.varCode.D;
            end
        end
        % 2.��λ
%         pos = pos_solve(sv(~isnan(sv(:,1)),:)); %��ȡ�ɼ����Ƕ�λ���������4�����Ƿ���8��NaN
        index = find(~isnan(sv(:,1)));
        pos = pos_solve_weight(sv(index,:), R(index)); %��Ȩ��λ
        % 3.ʱ�ӷ�������
        if receiverState==1 && ~isnan(pos(7))
            deltaFreq = deltaFreq + 10*pos(8)*dtpos/1000; %��Ƶ���ۼ�
            ta = ta - sec2smu(10*pos(7)*dtpos/1000); %ʱ�����������Բ��ý�λ�����´θ���ʱ��λ��
        end
        % 4.�洢���
        output_ta(no,1)   = tp(1) + tp(2)/1e3 + tp(3)/1e6; %ʱ�����s
        output_ta(no,2)   = receiverState; %���ջ�״̬
        output_pos(no,:)  = pos;
        output_sv(:,:,no) = sv;
        output_df(no)     = deltaFreq;
        % 5.����ʼ��
        if receiverState==0 && ~isnan(pos(7))
            if abs(pos(7))>0.1e-3 %�Ӳ����0.1ms���������ջ�ʱ��
                ta = ta - sec2smu(pos(7)); %ʱ������
                ta = time_carry(ta);
                tp(1) = ta(1); %�����´ζ�λʱ��
                tp(2) = (floor(ta(2)/dtpos)+1) * dtpos;
                tp = time_carry(tp);
            else %�Ӳ�С��0.1ms����ʼ������
                receiverState = 1;
            end
        end
        % 6.�����´ζ�λʱ��
        tp = time_carry(tp + [0,dtpos,0]);
        no = no + 1; %ָ����һ�洢λ��
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
output_ta(no:end,:)   = [];
output_pos(no:end,:)  = [];
output_sv(:,:,no:end) = [];
output_df(no:end,:)   = [];
% ɾ�����ջ�δ��ʼ��ʱ������
index = find(output_ta(:,2)==0);
output_ta(index,:)    = [];
output_pos(index,:)   = [];
output_sv(:,:,index)  = [];
output_df(index,:)    = [];

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
    plot(ax1, trackResults(k).I_Q(1001:end,1),trackResults(k).I_Q(1001:end,4), 'LineStyle','none', 'Marker','.') %I/Qͼ
    plot(ax2, trackResults(k).dataIndex/sampleFreq, trackResults(k).I_Q(:,1))
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
    trackResult.I_Q           = zeros(m,6); %[I_P,I_E,I_L,Q_P,Q_E,Q_L]
    trackResult.disc          = zeros(m,3); %���������
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