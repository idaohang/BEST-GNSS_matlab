function analysis_measure_BDS
% ���������߱���α�ࡢα���ʲ������ȣ����ξ�������
% �����̶��Ĳο����꣬��ֹʱ��α��α�������Ϊ��ֵ���˶�ʱ��α��α��������������˶���ɵ�
% ���н�����鿴analysis����

%% ��������
output = evalin('base', 'output');

%% �ο�����
p0 = [45.73580, 126.62881, 159];
rp = lla2ecef(p0); %ecef
Cen = dcmecef2ned(p0(1), p0(2));

%% ����ռ�
n = output.n; %���ݵ���
svN_BDS = size(output.sv_BDS_A,1); %���Ǹ���
analysis.ta = output.ta; %ʱ������
analysis.BDS_dr  = zeros(n,svN_BDS); %α�������m
analysis.BDS_dv  = zeros(n,svN_BDS); %α���ʲ�����m/s
analysis.BDS_azi = zeros(n,svN_BDS); %��λ�ǣ�deg
analysis.BDS_ele = zeros(n,svN_BDS); %�߶Ƚǣ�deg
analysis.DOP_BDS = NaN(n,7); %����������������

%% ����
for k=1:n
    %----����
    sv_BDS = output.sv_BDS_A(:,1:8,k);
    rs = sv_BDS(:,1:3);
    rsp = ones(svN_BDS,1)*rp - rs;
    rho = sum(rsp.*rsp, 2).^0.5; 
    rspu = rsp ./ (rho*[1,1,1]); 
    vs = sv_BDS(:,5:7); 
    vsp = 0 - vs; 
    rhodot = sum(vsp.*rspu, 2);
    analysis.BDS_dr(k,:) = (sv_BDS(:,4) - rho)';
    analysis.BDS_dv(k,:) = (sv_BDS(:,8) - rhodot)';
    rn = (Cen*rspu')';
    analysis.BDS_ele(k,:) = asind(rn(:,3))';
    analysis.BDS_azi(k,:) = atan2d(-rn(:,2),-rn(:,1))'; 
    rn_BDS = rn(~isnan(rn(:,1)),:);
    if size(rn_BDS,1)>=4
        G = [rn_BDS, -ones(size(rn_BDS,1),1)];
        D = inv(G'*G);
        analysis.DOP_BDS(k,1:4) = sqrt(diag(D));
        analysis.DOP_BDS(k,5) = norm(analysis.DOP_BDS(k,1:2));
        analysis.DOP_BDS(k,6) = norm(analysis.DOP_BDS(k,1:3));
        analysis.DOP_BDS(k,7) = norm(analysis.DOP_BDS(k,1:4));
    end
end

%% ���
assignin('base', 'analysis', analysis);

end