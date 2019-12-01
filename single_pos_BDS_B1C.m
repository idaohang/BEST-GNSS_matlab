% ����B1C�����߶�λ
% ���ʱ�Ӳ������������Ӳɢ����Ƶ�ֵ
% ���ֻ����Ƶ����Ƶ��Ϊ0���Ӳ��ڶ�ʱ��Ӧ�ò�Ʈ��Ҫ��Ʈ�ˣ�˵����Ƶ����Ĳ���
% �Ӳ��Ƶ��ȫ�ޣ��Ӳ����Ƶ���0
% ��Ƶ����ز������ղ�����Ӱ����Ҫ��Դ���±�ƵʱƵ�ʵ�ƫ�ƣ������Ǹ��ٽ׶β���Ƶ�ʲ�׼����ı����ز�Ƶ�����
% ����3e-9����Ƶ�1575.42e6Hz�ز��±�ƵƵ��ƫ��Լ4.73Hz
% ��������3kHz�ı����ز�������Ƶ���������ı����ز��������ԼΪ1e-5Hz�����Ժ��Բ���
% ��λʱ������Ӱ�춨λ��������

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

%--���ջ�ʱ�� (BDSʱ��)
tf = sscanf(data_file_A((end-22):(end-8)), '%4d%02d%02d_%02d%02d%02d')'; %�����ļ���ʼ����ʱ�䣨����ʱ�����飩
[tw, ts] = BDS_time(tf); %tw��BDT������ts��BDT��������
ta = [ts,0,0] + sample2dt(sample_offset, sampleFreq); %��ʼ�����ջ�ʱ�䣨������������[s,ms,us]
ta = time_carry(round(ta,2)); %ȡ��

%--���ջ�״̬
receiverState = 0; %���ջ�״̬��0��ʾδ��ʼ����ʱ�仹���ԣ�1��ʾʱ���Ѿ�У��
deltaFreq = 0; %ʱ�Ӳ���Ϊ�ٷֱȣ������1e-9������1500e6Hz�Ĳ����1.5Hz
dtpos = 10; %��λʱ������ms
tp = [ta(1),0,0]; %tpΪ�´ζ�λʱ��
tp(2) = (floor(ta(2)/dtpos)+1) * dtpos; %�ӵ��¸���Ŀ��ʱ��
tp = time_carry(tp); %��λ

%% ������������ͨ��
%--������־�ļ�
logFile_BDS_A = '.\temp\log_BDS_A.txt'; %��־�ļ�
logID_BDS_A = fopen(logFile_BDS_A, 'w');

%--����һ�Σ���ʱ��
acqResults_BDS = BDS_B1C_acq(data_file_A, sample_offset, 1);
svList_BDS = acqResults_BDS(~isnan(acqResults_BDS(:,2)),1);
acqResults_BDS(isnan(acqResults_BDS(:,2)),:) = [];
acqResults_BDS(:,1) = [];
svN_BDS = length(svList_BDS);

%--�����б�
% svList_BDS = [19;20;22;36;37;38];
% svN_BDS = length(svList_BDS);

%--����ͨ��
channels_BDS_A = cell(svN_BDS,1); %����cell
for k=1:svN_BDS %��������ͨ������
    channels_BDS_A{k} = BDS_B1C_channel(sampleFreq, buffSize, svList_BDS(k), logID_BDS_A);
end

%--��ʼ��ͨ��
for k=1:svN_BDS
    channels_BDS_A{k}.init(acqResults_BDS(k,1:2), 0);
end
% channels_BDS_A{1}.init([14319, -200], 0);
% channels_BDS_A{2}.init([19294,-2450], 0);
% channels_BDS_A{3}.init([29616, 2300], 0);
% channels_BDS_A{4}.init([13406, 3300], 0);
% channels_BDS_A{5}.init([15648,-2100], 0);
% channels_BDS_A{6}.init([27633,-1900], 0);

%--ͨ������洢�ռ�
m = msToProcess + 10;
trackResults_BDS = struct('PRN',0, 'n',1, ...
'dataIndex',    zeros(m,1), ...
...'remCodePhase', zeros(m,1), ... %���Բ��棬ע�͵���ǰ���...
'codeFreq',     zeros(m,1), ...
...'remCarrPhase', zeros(m,1), ... %���Բ���
'carrFreq',     zeros(m,1), ...
'I_Q',          zeros(m,8), ...
'disc',         zeros(m,2), ...
'std',          zeros(m,2));
trackResults_BDS_A = repmat(trackResults_BDS, svN_BDS,1);
clearvars trackResults_BDS
for k=1:svN_BDS
    trackResults_BDS_A(k).PRN = svList_BDS(k);
end

%% ���ջ�����洢�ռ�
m = msToProcess/dtpos + 100;
output.n        = 1; %��ǰ�洢��
output.ta       = NaN(m,1); %���ջ�ʱ�䣬s
output.state    = NaN(m,1); %���ջ�״̬
output.pos      = NaN(m,8); %��λ��[λ�á��ٶȡ��Ӳ��Ƶ��]
output.sv_BDS_A = NaN(svN_BDS,10,m); %����������Ϣ��[λ�á�α�ࡢ�ٶȡ�α���ʡ������������ز�����������]
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
    
    %% ��λ
    dtp = (ta(1)-tp(1)) + (ta(2)-tp(2))/1e3 + (ta(3)-tp(3))/1e6;
    if dtp>=0
        % ��������������Ϣ
        sv_BDS_A = NaN(svN_BDS,10);
        for k=1:svN_BDS
            if channels_BDS_A{k}.state==2
                dn = mod(buffHead-channels_BDS_A{k}.trackDataTail+1, buffSize) - 1;
                dtc = dn / sampleFreq0;
                dt = dtc - dtp;
                codePhase = channels_BDS_A{k}.remCodePhase + channels_BDS_A{k}.codeNco*dt;
                ts0 = [floor(channels_BDS_A{k}.ts0/1e3), mod(channels_BDS_A{k}.ts0,1e3), 0] + [0, floor(codePhase/2046), mod(codePhase/2046,1)*1e3]; %�����������ز�ʱ��Ƶ��2.046e6Hz
                [sv_BDS_A(k,1:8),~] = BDS_CNAV1_ephemeris_rho(channels_BDS_A{k}.ephemeris, tp, ts0);
                sv_BDS_A(k,8) = -(channels_BDS_A{k}.carrFreq/1575.42e6 + deltaFreq) * 299792458;
                sv_BDS_A(k,8) = sv_BDS_A(k,8) + channels_BDS_A{k}.ephemeris(26)*299792458;
                sv_BDS_A(k,9)  = channels_BDS_A{k}.varCode.D;
                sv_BDS_A(k,10) = channels_BDS_A{k}.varPhase.D;
            end
        end
        % ��λ
        sv = sv_BDS_A;
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
        output.sv_BDS_A(:,:,n) = sv_BDS_A;
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
fclose(logID_BDS_A);
close(f);

%% ɾ���հ�����
trackResults_BDS_A = clean_trackResults(trackResults_BDS_A);
output = clean_receiverOutput(output);

%% ��ӡͨ����־
clc
disp('<--------BDS A-------->')
print_log(logFile_BDS_A, svList_BDS);

%% �������
clearvars -except sampleFreq msToProcess tf ...
                  svList_BDS channels_BDS_A trackResults_BDS_A ...
                  output

%% ��ʱ����
toc

%% �Ի���
answer = questdlg('Plot track result?', ...
	              'Finish', ...
	              'Yes','No','No');
switch answer
    case 'Yes'
        plot_track_BDS_A
    case 'No'
end
clearvars answer