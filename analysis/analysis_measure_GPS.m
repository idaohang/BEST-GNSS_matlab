function analysis_measure_GPS
% ����������GPSα�ࡢα���ʲ������ȣ����ξ�������
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
svN_GPS = size(output.sv_GPS_A,1); %���Ǹ���
analysis.ta = output.ta; %ʱ������
analysis.GPS_dr  = zeros(n,svN_GPS); %α�������m
analysis.GPS_dv  = zeros(n,svN_GPS); %α���ʲ�����m/s
analysis.GPS_azi = zeros(n,svN_GPS); %��λ�ǣ�deg
analysis.GPS_ele = zeros(n,svN_GPS); %�߶Ƚǣ�deg
analysis.DOP_GPS = NaN(n,7); %GPS������������

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
end

%% ���
assignin('base', 'analysis', analysis);

end