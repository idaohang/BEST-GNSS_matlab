% GPS L1CA�����߶�λ

% �����������ӣ�F:\GNSS data\20190726\B210_20190726_205109_ch1.dat

clear %�����
clc %����Ļ
fclose('all'); %���ļ�

%% �����ļ�
%----�Ի���ѡ���ļ�
default_path = fileread('.\temp\path_data.txt'); %�����ļ�����Ĭ��·��
[file, path] = uigetfile([default_path,'\*.dat'], 'ѡ��GNSS�����ļ�'); %�ļ�ѡ��Ի���
if file==0
    disp('Invalid file!');
    return
end
if strcmp(file(1:4),'B210')==0
    error('File error!');
end
data_file = [path, file];
data_file_A = data_file;
%----ָ���ļ���
% data_file_A = 'F:\GNSS data\20190726\B210_20190726_205109_ch1.dat';

%% ����ʱ��
msToProcess = 60*1*1000; %������ʱ��
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

%--���ջ�ʱ�� (GPSʱ��)
tf = sscanf(data_file_A((end-22):(end-8)), '%4d%02d%02d_%02d%02d%02d')'; %�����ļ���ʼ����ʱ�䣨����ʱ�����飩
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
logFile_GPS_A = '.\temp\log_GPS_A.txt'; %��־�ļ�
logID_GPS_A = fopen(logFile_GPS_A, 'w');

%--����һ�Σ���ʱ��
acqResults_GPS = GPS_L1CA_acq(data_file_A, sample_offset, 12000, 1);
svList_GPS = find(~isnan(acqResults_GPS(:,1)));
acqResults_GPS(isnan(acqResults_GPS(:,1)),:) = [];
svN_GPS = length(svList_GPS);

%--�����б�
% svList_GPS = [10;13;15;20;21;24];
% svN_GPS = length(svList_GPS);

%--����ͨ��
channels_GPS_A = cell(svN_GPS,1); %����cell
for k=1:svN_GPS %��������ͨ������
    channels_GPS_A{k} = GPS_L1CA_channel(sampleFreq, buffSize, svList_GPS(k), logID_GPS_A);
end

%--��ʼ��ͨ��
for k=1:svN_GPS
    channels_GPS_A{k}.init(acqResults_GPS(k,1:2), 0);
end
% channels_GPS_A{1}.init([2947, 3250], 0);
% channels_GPS_A{2}.init([2704,-2750], 0);
% channels_GPS_A{3}.init([2341,-1250], 0);
% channels_GPS_A{4}.init([2772, 2250], 0);
% channels_GPS_A{5}.init([2621, -750], 0);
% channels_GPS_A{6}.init([1384, 2000], 0);

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

%% ���ջ�����洢�ռ�
m = msToProcess/dtpos + 100;
output.n        = 1; %��ǰ�洢��
output.ta       = NaN(m,1); %���ջ�ʱ�䣬s
output.state    = NaN(m,1); %���ջ�״̬
output.pos      = NaN(m,8); %��λ��[λ�á��ٶȡ��Ӳ��Ƶ��]
output.sv_GPS_A = NaN(svN_GPS,10,m); %GPS������Ϣ��[λ�á�α�ࡢ�ٶȡ�α���ʡ������������ز�����������]
output.df       = NaN(m,1); %���Ƴ�����Ƶ��

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
    
    %% ��λ
    dtp = (ta(1)-tp(1)) + (ta(2)-tp(2))/1e3 + (ta(3)-tp(3))/1e6;
    if dtp>=0
        % ����GPS������Ϣ
        sv_GPS_A = NaN(svN_GPS,10);
        for k=1:svN_GPS
            if channels_GPS_A{k}.state==2
                dn = mod(buffHead-channels_GPS_A{k}.trackDataTail+1, buffSize) - 1; %trackDataTailǡ�ó�ǰbuffHeadһ��ʱ��dn=-1
                dtc = dn / sampleFreq0; %��ǰ����ʱ������ٵ��ʱ���
                dt = dtc - dtp; %��λ�㵽���ٵ��ʱ���
                codePhase = channels_GPS_A{k}.remCodePhase + channels_GPS_A{k}.codeNco*dt; %��λ������λ
                ts0 = [floor(channels_GPS_A{k}.ts0/1e3), mod(channels_GPS_A{k}.ts0,1e3), 0] + [0, floor(codePhase/1023), mod(codePhase/1023,1)*1e3]; %��λ����뷢��ʱ��
                [sv_GPS_A(k,1:8),~] = GPS_L1CA_ephemeris_rho(channels_GPS_A{k}.ephemeris, tp, ts0); %����������������λ���ٶȺ�α��
                sv_GPS_A(k,8) = -(channels_GPS_A{k}.carrFreq/1575.42e6 + deltaFreq) * 299792458; %�ز�Ƶ��ת��Ϊ�ٶ�
                sv_GPS_A(k,8) = sv_GPS_A(k,8) + channels_GPS_A{k}.ephemeris(9)*299792458; %��������Ƶ������ӿ���α����ƫС
                sv_GPS_A(k,9)  = channels_GPS_A{k}.varCode.D;
                sv_GPS_A(k,10) = channels_GPS_A{k}.varPhase.D;
            end
        end
        
        % ��λ
        sv = sv_GPS_A;
        sv(isnan(sv(:,1)),:) = []; %ɾ����Ч����
        pos = pos_solve_weight(sv(:,1:8), sv(:,9));
        % ʱ������
%         if receiverState==1 && ~isnan(pos(7))
%             deltaFreq = deltaFreq + 10*pos(8)*dtpos/1000; %��Ƶ���ۼ�
%             ta = ta - sec2smu(10*pos(7)*dtpos/1000); %ʱ�����������Բ��ý�λ�����´θ���ʱ��λ��
%         end
        % �洢���
        n = output.n;
        output.ta(n) = tp(1) + tp(2)/1e3 + tp(3)/1e6;
        output.state(n) = receiverState;
        output.pos(n,:) = pos;
        output.sv_GPS_A(:,:,n) = sv_GPS_A;
        output.df(n) = deltaFreq;
        output.n = n + 1;
        % �����ջ�״̬
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
        % �����´ζ�λʱ��
        tp = time_carry(tp + [0,dtpos,0]);
    end
    
end

%% �ر��ļ����رս�����
fclose(fileID_A);
fclose(logID_GPS_A);
close(f);

%% ɾ���հ�����
trackResults_GPS_A = clean_trackResults(trackResults_GPS_A);
output = clean_receiverOutput(output);

%% ��ӡͨ����־
clc
disp('<--------GPS A-------->')
print_log(logFile_GPS_A, svList_GPS);

%% �������
clearvars -except sampleFreq msToProcess tf ...
                  svList_GPS channels_GPS_A trackResults_GPS_A ...
                  output

%% ��ʱ����
toc

%% �Ի���
answer = questdlg('Plot track result?', ...
	              'Finish', ...
	              'Yes','No','No');
switch answer
    case 'Yes'
        plot_track_GPS_A
    case 'No'
end
clearvars answer