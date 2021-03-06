function sv_3Dview_DOP
% 给定GPS卫星和北斗卫星高度角和方位角，画三维图，求几何精度因子
% X-Y视图是俯视
% 直接打开3D视图旋转，右键选择视角，双击恢复
% 四星方位均匀分布同高度角无法定位，GDOP无穷大，因为沿对称轴每个点都可能是定位点

n = 2000;

%----GPS
% GPS_azi = [-20,40,120,240]; %方位角，deg
% GPS_ele = [45,19,69,39]; %高度角，deg
% svList_GPS = [6;12;17;19];

GPS_azi = evalin('base', ['analysis.GPS_azi(',num2str(n),',:)']);
GPS_ele = evalin('base', ['analysis.GPS_ele(',num2str(n),',:)']);
svList_GPS = evalin('base', 'svList_GPS');

svN_GPS = length(svList_GPS);
sv_GPS = [GPS_azi',GPS_ele'];

%---BDS
% BDS_azi = [10,80,170,280];
% BDS_ele = [85,20,47,20];
% svList_BDS = [21;22;34;38];

BDS_azi = evalin('base', ['analysis.BDS_azi(',num2str(n),',:)']);
BDS_ele = evalin('base', ['analysis.BDS_ele(',num2str(n),',:)']);
svList_BDS = evalin('base', 'svList_BDS');

svN_BDS = length(svList_BDS);
sv_BDS = [BDS_azi',BDS_ele'];

% 画图
plot_sv_3d(sv_GPS, svList_GPS, sv_BDS, svList_BDS)

% GPS几何精度因子
G = zeros(svN_GPS,4);
G(:,end) = -1;
for k=1:svN_GPS
    G(k,1) = -cosd(sv_GPS(k,2))*cosd(sv_GPS(k,1));
    G(k,2) = -cosd(sv_GPS(k,2))*sind(sv_GPS(k,1));
    G(k,3) =  sind(sv_GPS(k,2));
end
G(isnan(G(:,1)),:) = []; %删除空行
if size(G,1)>=4
    D = inv(G'*G);
    sigma_GPS = sqrt(diag(D))
%     HDOP_GPS = norm(sigma_GPS(1:2))
%     PDOP_GPS = norm(sigma_GPS(1:3))
%     GDOP_GPS = norm(sigma_GPS)
    disp('-------------------------------')
end

% 北斗几何精度因子
G = zeros(svN_BDS,4);
G(:,end) = -1;
for k=1:svN_BDS
    G(k,1) = -cosd(sv_BDS(k,2))*cosd(sv_BDS(k,1));
    G(k,2) = -cosd(sv_BDS(k,2))*sind(sv_BDS(k,1));
    G(k,3) =  sind(sv_BDS(k,2));
end
G(isnan(G(:,1)),:) = []; %删除空行
if size(G,1)>=4
    D = inv(G'*G);
    sigma_BDS = sqrt(diag(D))
%     HDOP_BDS = norm(sigma_BDS(1:2))
%     PDOP_BDS = norm(sigma_BDS(1:3))
%     GDOP_BDS = norm(sigma_BDS)
    disp('-------------------------------')
end

% GPS+北斗几何精度因子
sv_GPS_BDS = [sv_GPS; sv_BDS];
svN_GPS_BDS = size(sv_GPS_BDS,1);
G = zeros(svN_GPS_BDS,4);
G(:,end) = -1;
for k=1:svN_GPS_BDS
    G(k,1) = -cosd(sv_GPS_BDS(k,2))*cosd(sv_GPS_BDS(k,1));
    G(k,2) = -cosd(sv_GPS_BDS(k,2))*sind(sv_GPS_BDS(k,1));
    G(k,3) =  sind(sv_GPS_BDS(k,2));
end
G(isnan(G(:,1)),:) = []; %删除空行
if size(G,1)>=4
    D = inv(G'*G);
    sigma_GPS_BDS = sqrt(diag(D))
%     HDOP_GPS_BDS = norm(sigma_GPS_BDS(1:2))
%     PDOP_GPS_BDS = norm(sigma_GPS_BDS(1:3))
%     GDOP_GPS_BDS = norm(sigma_GPS_BDS)
end

end

%% 画图函数
function plot_sv_3d(sv_GPS, svList_GPS, sv_BDS, svList_BDS)
    svN_GPS = length(svList_GPS);
    svN_BDS = length(svList_BDS);
    
    figure
    X = [-1,1;-1,1];
    Y = [1,1;-1,-1];
    Z = [0,0;0,0];
    surf(X,Y,Z, 'EdgeColor',[0.9290 0.6940 0.1250], 'FaceColor',[0.9290 0.6940 0.1250], 'FaceAlpha',0.4) %画地平面
    axis equal
    set(gca, 'Zlim',[-0.2,1.2])
    hold on
    text(0,1,0,'N')
    text(1,0,0,'E')
    plot3([-1,1],[0,0],[0,0], 'Color',[0.9290 0.6940 0.1250]) %画地平面分割线
    plot3([0,0],[-1,1],[0,0], 'Color',[0.9290 0.6940 0.1250])
    plot3(0,0,0, 'Color',[0.9290 0.6940 0.1250], 'LineStyle','none', 'Marker','.', 'MarkerSize',25) %画原点

    for k=1:svN_GPS
        if isnan(sv_GPS(k,1))
            continue
        end
        p = [cosd(sv_GPS(k,2))*cosd(90-sv_GPS(k,1)), ...
             cosd(sv_GPS(k,2))*sind(90-sv_GPS(k,1)), ...
             sind(sv_GPS(k,2))];
        plot3(p(1),p(2),p(3), 'Color',[76,114,176]/255, 'LineStyle','none', 'Marker','.', 'MarkerSize',25)
        plot3([0,p(1)],[0,p(2)],[0,p(3)], 'Color',[76,114,176]/255, 'LineWidth',0.5)
        text(p(1),p(2),p(3),['  G',num2str(svList_GPS(k))]) %卫星编号
    end

    for k=1:svN_BDS
        if isnan(sv_BDS(k,1))
            continue
        end
        p = [cosd(sv_BDS(k,2))*cosd(90-sv_BDS(k,1)), ...
             cosd(sv_BDS(k,2))*sind(90-sv_BDS(k,1)), ...
             sind(sv_BDS(k,2))];
        plot3(p(1),p(2),p(3), 'Color',[196,78,82]/255, 'LineStyle','none', 'Marker','.', 'MarkerSize',25)
        plot3([0,p(1)],[0,p(2)],[0,p(3)], 'Color',[196,78,82]/255, 'LineWidth',0.5)
        text(p(1),p(2),p(3),['  B',num2str(svList_BDS(k))]) %卫星编号
    end
    
    rotate3d on %直接打开3D视图旋转，右键选择视角，双击恢复
end