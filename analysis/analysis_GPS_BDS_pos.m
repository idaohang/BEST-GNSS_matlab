function analysis_GPS_BDS_pos
% ����������GPS+����α�ࡢα���ʲ������ȣ����ξ�������
% �����̶��Ĳο����꣬��ֹʱ��α��α�������Ϊ��ֵ���˶�ʱ��α��α��������������˶���ɵ�
% ���н�����鿴analysis����
% ���鷢�֣�ĳЩʱ���������ξ������Ӳ��ã���λ���������ܴ�

%% ��������
output = evalin('base', 'output');

%% �ο�����
p0 = [45.73580, 126.62881, 159];
rp = lla2ecef(p0); %ecef
Cen = dcmecef2ned(p0(1), p0(2));

%% ����ռ�
n = output.n; %���ݵ���
svN_GPS = size(output.sv_GPS_A,1); %���Ǹ���
svN_BDS = size(output.sv_BDS_A,1);
analysis.ta = output.ta; %ʱ������
analysis.GPS_dr  = zeros(n,svN_GPS); %α�������m
analysis.GPS_dv  = zeros(n,svN_GPS); %α���ʲ�����m/s
analysis.GPS_azi = zeros(n,svN_GPS); %��λ�ǣ�deg
analysis.GPS_ele = zeros(n,svN_GPS); %�߶Ƚǣ�deg
analysis.BDS_dr  = zeros(n,svN_BDS);
analysis.BDS_dv  = zeros(n,svN_BDS);
analysis.BDS_azi = zeros(n,svN_BDS);
analysis.BDS_ele = zeros(n,svN_BDS);
analysis.DOP_GPS     = NaN(n,7); %GPS������������
analysis.DOP_BDS     = NaN(n,7); %����������������
analysis.DOP_GPS_BDS = NaN(n,7); %GPS+����������������

%% ����
for k=1:n
    %----GPS
    sv_GPS = output.sv_GPS_A(:,1:8,k);
    rs = sv_GPS(:,1:3);            %����λ��
    rsp = ones(svN_GPS,1)*rp - rs; %����ָ����ջ�ʸ��
    rho = sum(rsp.*rsp, 2).^0.5;   %����α��
    rspu = rsp ./ (rho*[1,1,1]);   %���ߵ�λʸ��
    vs = sv_GPS(:,5:7);            %�����ٶ�
    vsp = 0 - vs;                  %���ջ�������ǵ��ٶ�
    rhodot = sum(vsp.*rspu, 2);    %����α����
    analysis.GPS_dr(k,:) = (sv_GPS(:,4) - rho)';    %α�����������ֵ������ֵ
    analysis.GPS_dv(k,:) = (sv_GPS(:,8) - rhodot)'; %α���ʲ������
    rn = (Cen*rspu')'; %����ϵ�����ߵ�λʸ��
    analysis.GPS_ele(k,:) = asind(rn(:,3))'; %���Ǹ߶Ƚ�
    analysis.GPS_azi(k,:) = atan2d(-rn(:,2),-rn(:,1))'; %���Ƿ�λ��
    rn_GPS = rn(~isnan(rn(:,1)),:); %��ȡ�ǿ�����
    if size(rn_GPS,1)>=4
        G = [rn_GPS, -ones(size(rn_GPS,1),1)];
        D = inv(G'*G);
        analysis.DOP_GPS(k,1:4) = sqrt(diag(D));
        analysis.DOP_GPS(k,5) = norm(analysis.DOP_GPS(k,1:2)); %HDOP
        analysis.DOP_GPS(k,6) = norm(analysis.DOP_GPS(k,1:3)); %PDOP
        analysis.DOP_GPS(k,7) = norm(analysis.DOP_GPS(k,1:4)); %GDOP
    end
    
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
    
    %----GPS+����DOP
    rn_GPS_BDS = [rn_GPS; rn_BDS];
    if size(rn_GPS_BDS,1)>=4
        G = [rn_GPS_BDS, -ones(size(rn_GPS_BDS,1),1)];
        D = inv(G'*G);
        analysis.DOP_GPS_BDS(k,1:4) = sqrt(diag(D));
        analysis.DOP_GPS_BDS(k,5) = norm(analysis.DOP_GPS_BDS(k,1:2));
        analysis.DOP_GPS_BDS(k,6) = norm(analysis.DOP_GPS_BDS(k,1:3));
        analysis.DOP_GPS_BDS(k,7) = norm(analysis.DOP_GPS_BDS(k,1:4));
    end
end

%% ���
assignin('base', 'analysis', analysis);

end