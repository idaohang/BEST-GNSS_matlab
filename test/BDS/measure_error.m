function measure_error
% ��֤��ֹʱα�ࡢα���ʲ������
% �����л��̶��ο����껹��ʵ�ʽ�������

%% ��������
svList = evalin('base', 'svList'); %���Ǳ���б�
sv_info = evalin('base', 'output_sv(:,1:8,:)'); %������Ϣ��[x,y,z, rho, vx,vy,vz, rhodot]
% p0 = evalin('base', 'output_pos(:,1:3)'); %��λ��Ϣ

%% �ο�����
p0 = [45.73105, 126.62487, 207];
rp = lla2ecef(p0); %ecef
Cen = dcmecef2ned(p0(1), p0(2));

%% ���ݷ�Χ
range = 1:size(sv_info,3); %���е�
% range = 1:6000; %�ӵڼ����㵽�ڼ�����

%% �������ݽ�ȡ
sv_info = sv_info(:,:,range);

%% ����洢�ռ�
n = size(sv_info,3); %���ݵ���
svN = length(svList); %���Ǹ���

output_dr = zeros(n,svN); %α����ÿһ��Ϊһ������
output_dv = zeros(n,svN); %α�������
output_ele = zeros(n,svN); %�߶Ƚ�
output_azi = zeros(n,svN); %��λ��

%% ����
for k=1:n
%     rp = lla2ecef(p0(k,1:3)); %ecef
%     Cen = dcmecef2ned(p0(k,1), p0(k,2));
    
    rs = sv_info(:,1:3,k);
    rsp = ones(svN,1)*rp - rs; %����ָ����ջ�ʸ��
    rho = sum(rsp.*rsp, 2).^0.5;
    rspu = rsp ./ (rho*[1,1,1]);
    vs = sv_info(:,5:7,k);
    vsp = 0 - vs;
    rhodot = sum(vsp.*rspu, 2);
    output_dr(k,:) = (sv_info(:,4,k) - rho)'; %����ֵ������ֵ
    output_dv(k,:) = (sv_info(:,8,k) - rhodot)';
    rn = (Cen*rspu')'; %����ϵ�µ�λʸ��
    output_ele(k,:) = asind(rn(:,3))';
    output_azi(k,:) = atan2d(-rn(:,2),-rn(:,1))';
end

%% ���
assignin('base', 'output_dr', output_dr);
assignin('base', 'output_dv', output_dv);
assignin('base', 'output_ele', output_ele);
assignin('base', 'output_azi', output_azi);

%% ��ͼ
figure
plot(output_dr)
figure
plot(output_dv)

end