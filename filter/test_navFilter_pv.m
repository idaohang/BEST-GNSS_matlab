% ����PVģ�͵����˲���
% �е���ϵ�º�ecefϵ�����֣����ַ����ȶ�ʱ���һ��

clear
clc

%% ������������
%====����ʱ��
T = 200;        %��ʱ�䣬s
dt = 0.01;      %ʱ������s
n = T / dt;     %�ܷ������
t = (1:n)'*dt;  %ʱ�����У���������

%====���ջ�����
sigma_rho = 3;        %α�����������׼�m
sigma_rhodot = 0.1;   %α���ʲ���������׼�m/s
dtr = 1e-8;           %��ʼ�Ӳs
dtv = 3e-9;           %��ʼ��Ƶ�s/s
c = 299792458;        %���٣�m/s

%====���ջ�λ��
lat = 46;      %γ�ȣ�deg
lon = 126;     %���ȣ�deg
h = 200;       %�߶ȣ�m

%====����λ��
% ��һ��Ϊ��λ�ǣ��ڶ���Ϊ�߶Ƚǣ�deg
sv_info = [  0, 45;
            23, 28;
            58, 80;
           100, 49;
           146, 34;
           186, 78;
           213, 43;
           255, 15;
           310, 20];
rho = 20000000; %���ǵ����ջ��ľ��룬m

%====��������λ�á��ٶ�
svN = size(sv_info,1); %���Ǹ���
sv_real = zeros(svN,8); %�洢������������⣬[x,y,z, rho, vx,vy,vz, rhodot]
Cen = dcmecef2ned(lat, lon);
rp = lla2ecef([lat, lon, h]); %���ջ�λ��ʸ����ecef����������
for k=1:svN
    e = [-cosd(sv_info(k,2))*cosd(sv_info(k,1)), ...
         -cosd(sv_info(k,2))*sind(sv_info(k,1)), ...
          sind(sv_info(k,2))]; %����ָ����ջ��ĵ�λʸ��������ϵ����������
    rsp = e * rho; %����ָ����ջ���λ��ʸ��������ϵ��
    sv_real(k,1:3) = rp - (rsp*Cen);  %����λ��ʸ����ecef��
    sv_real(k,4) = rho;               %α��
    sv_real(k,5:7) = 0;               %�����ٶ�
    sv_real(k,8) = 0;                 %α����
end

%====����α�ࡢα��������
% �Աȷ���ʹ�ù���������
noise_rho    = randn(n,svN)*sigma_rho;
noise_rhodot = randn(n,svN)*sigma_rhodot;

%% ���Ե���ϵ�µ����˲���
%====�����������ռ�
output_geog.nav = zeros(n,6); %�˲����������
output_geog.dc  = zeros(n,2); %�Ӳ��Ƶ�����
output_geog.P   = zeros(n,8); %�˲���P��

%====��ʼ���˲���
a = 6371000; %����뾶
para.P = diag([ ...
               [1/a,secd(lat)/a,1]*5, ... %��ʼλ����[rad,rad,m]
               [1,1,1]*1, ...             %��ʼ�ٶ���m/s
               2e-8, ...                  %��ʼ�Ӳs
               3e-9 ...
               ])^2;                  %��ʼ��Ƶ�s/s
para.Q = diag([ ...
               [1/a,secd(lat)/a,1]*0.01 *(dt/1), ...
               [1,1,1]*0.01, ...
               0.03e-9 *(dt/1), ...
               0.03e-9 ...
               ])^2 * dt^2;
NF = navFilter_pv_geog([lat,lon,h], [0,0,0], dt, para);
sigma = [ones(svN,1)*sigma_rho, ones(svN,1)*sigma_rhodot];

%====����
for k=1:n
    % ������������
    dtr = dtr + dtv*dt; %��ǰ�Ӳs
    sv = sv_real;
    sv(:,4) = sv(:,4) + noise_rho(k,:)'    + dtr*c; %α�������
    sv(:,8) = sv(:,8) + noise_rhodot(k,:)' + dtv*c; %α���ʼ�����
    
    % ���µ����˲���
    NF.update(sv(:,[1:3,5:7]), sv(:,[4,8]), sigma);
    
    % �洢�������
    output_geog.nav(k,1:3) = NF.pos;
    output_geog.nav(k,4:6) = NF.vel;
    output_geog.dc(k,1) = NF.dtr - dtr;
    output_geog.dc(k,2) = NF.dtv;
    output_geog.P(k,:) = sqrt(diag(NF.Pk)');
end

%% ����ecefϵ�µ����˲���
%====�����������ռ�
output_ecef.nav = zeros(n,6); %�˲����������
output_ecef.dc  = zeros(n,2); %�Ӳ��Ƶ�����
output_ecef.P   = zeros(n,8); %�˲���P��

%====��ʼ���˲���
para.P = diag([ ...
               [1,1,1]*5, ... %��ʼλ����[m
               [1,1,1]*1, ... %��ʼ�ٶ���m/s
               2e-8, ...      %��ʼ�Ӳs
               3e-9 ...       %��ʼ��Ƶ�s/s
               ])^2;
para.Q = diag([ ...
               [1,1,1]*0.01 *(dt/1), ...
               [1,1,1]*0.01, ...
               0.03e-9 *(dt/1), ...
               0.03e-9 ...
               ])^2 * dt^2;
NF = navFilter_pv_ecef([lat,lon,h], [0,0,0], dt, para);
sigma = [ones(svN,1)*sigma_rho, ones(svN,1)*sigma_rhodot];

%====����
for k=1:n
    % ������������
    dtr = dtr + dtv*dt; %��ǰ�Ӳs
    sv = sv_real;
    sv(:,4) = sv(:,4) + noise_rho(k,:)'    + dtr*c; %α�������
    sv(:,8) = sv(:,8) + noise_rhodot(k,:)' + dtv*c; %α���ʼ�����
    
    % ���µ����˲���
    NF.update(sv(:,[1:3,5:7]), sv(:,[4,8]), sigma);
    
    % �洢�������
    output_ecef.nav(k,1:3) = NF.pos;
    output_ecef.nav(k,4:6) = NF.vel;
    output_ecef.dc(k,1) = NF.dtr - dtr;
    output_ecef.dc(k,2) = NF.dtv;
    output_ecef.P(k,:) = sqrt(diag(NF.Pk)');
end