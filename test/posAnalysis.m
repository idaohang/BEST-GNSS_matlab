% ��֤�ǵ�α�������µ���С���˶�λ����

% ���Ƿ�λ�Ǻ͸߶Ƚ�
sv_info = [  0, 45;
            23, 28;
            58, 80;
           100, 49;
           146, 34;
           186, 78;
           213, 43;
           255, 15;
           310, 20];
svN = size(sv_info,1); % ���Ǹ���

% figure
% polarscatter(sv_info(:,1)/180*pi, sv_info(:,2), ...
%              100, 'MarkerEdgeColor','g', 'MarkerFaceColor','y')
% ax = gca;
% ax.RLim = [0 90];
% ax.RDir = 'reverse';
% ax.ThetaDir = 'clockwise';
% ax.RTick = [0 15 30 45 60 75 90];

G = zeros(svN,4);
G(:,end) = -1;
for k=1:svN
    G(k,1:3) = [-cosd(sv_info(k,2))*cosd(sv_info(k,1)), ...
                -cosd(sv_info(k,2))*sind(sv_info(k,1)), ...
                 sind(sv_info(k,2))]; %����ָ����ջ��ĵ�λʸ��������ϵ����������
end

Q = diag([1,3,1,5,1,2,1,2,1].^2);

disp('����Ȩ')
D = (G'*G)\G'*Q*G/(G'*G);
disp(sqrt(D(1,1)))
disp(sqrt(D(2,2)))
disp(sqrt(D(3,3)))
disp(sqrt(D(4,4)))

disp('��Ȩ')
E = inv(G'/Q*G);
disp(sqrt(E(1,1)))
disp(sqrt(E(2,2)))
disp(sqrt(E(3,3)))
disp(sqrt(E(4,4)))

H = G;
R = Q;
w = [2,4,6,8];
H(w,:) = [];
R(w,:) = [];
R(:,w) = [];

disp('ɾ����Ȩ')
F = inv(H'/R*H);
disp(sqrt(F(1,1)))
disp(sqrt(F(2,2)))
disp(sqrt(F(3,3)))
disp(sqrt(F(4,4)))