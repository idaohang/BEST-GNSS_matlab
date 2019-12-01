classdef navFilter_pv_geog < handle
% ����ϵPVģ�͵����˲���
% ��ͬ״̬���ĳ߶����ܴ���ʵ�ʼ���ʱ�Ƿ���ڲ���Ӱ�죿

    properties (GetAccess = public, SetAccess = private)
        pos       %λ�ã�[lat,lon,h]��[deg,deg,m]
        vel       %�ٶȣ�[ve,vn,vd]��m/s
        dtr       %�Ӳs
        dtv       %��Ƶ�s/s
        T         %�������ڣ�s
        Pk        %�˲���P��
        Qk        %�˲���Q��
%         Rx_rho    %α��������������
%         Rx_rhodot %α����������������
    end %end properties
    
    properties (Access = private) %��������ʹ�õı���
        Plla    %λ�ã�[lat,lon,h]��[rad,rad,m]����������
        Vned    %�ٶȣ�[ve,vn,vd]��m/s����������
    end
    
    methods
        %% ����
        function obj = navFilter_pv_geog(p0, v0, T, para)
            % p0����ʼλ�ã�[lat,lon,h]��deg
            % v0����ʼ�ٶȣ�[ve,vn,vd]��m/s
            % T���������ڣ�s
            % para���˲�������
            obj.pos = p0;
            obj.vel = v0;
            obj.dtr = 0;
            obj.dtv = 0;
            obj.T = T;
            obj.Pk = para.P;
            obj.Qk = para.Q;
%             obj.Rx_rho = filterPara.R_rho;
%             obj.Rx_rhodot = filterPara.R_rhodot;
            obj.Plla = [p0(1)/180*pi, p0(2)/180*pi, p0(3)];
            obj.Vned = v0;
        end
        
        %% ����
        function [rho, rhodot] = update(obj, sv, sv_m, sigma)
            % sv = [x,y,z, vx,vy,vz]������λ�á��ٶ�
            % sv_m = [rho_m, rhodot_m]������ֵ��α�ࡢα����
            % sigma = [sigma_rho, sigma_rhodot]������ֵ������׼��
            % rho, rhodot��ʹ���˲���λ�á��ٶȼ����α�ࡢα����
            
            lat = obj.Plla(1); %rad
            lon = obj.Plla(2); %rad
            h = obj.Plla(3);
            [~, Rm, Rn] = earthPara(lat, h); %���������ʰ뾶
%             Cen = dcmecef2ned(obj.pos(1), obj.pos(2)); %�������������
            Cen = [-sin(lat)*cos(lon), -sin(lat)*sin(lon),  cos(lat);
                            -sin(lon),           cos(lon),         0;
                   -cos(lat)*cos(lon), -cos(lat)*sin(lon), -sin(lat)];
            
            %==========����״̬����========================================%
            v = obj.Vned; %�ٶȲ���
            lat = lat + v(1)/(Rm+h)*obj.T;
            lon = lon + v(2)/(Rn+h)*sec(lat)*obj.T;
            h = h - v(3)*obj.T;
            
            %==========�˲���״̬����======================================%
            A = zeros(8);
            A(1,4) = 1/(Rm+h);
            A(2,5) = sec(lat)/(Rn+h);
            A(3,6) = -1;
            A(7,8) = 1;
            Phi = eye(8) + A*obj.T;
            
            %==========����ά��============================================%
            index1 = find(~isnan(sv_m(:,1)))';  %α����������
            index2 = find(~isnan(sv_m(:,2)))';  %α������������
            n1 = length(index1);                %α���������
            n2 = length(index2);                %α�����������
            n  = size(sv,1);                    %ͨ������
            
            %==========״̬����============================================%
            X = zeros(8,1);
            X(7) = obj.dtr;
            X(8) = obj.dtv;
            
            %==========ʱ�����============================================%
            X = Phi*X;
            obj.Pk = Phi*obj.Pk*Phi' + obj.Qk;
            
            %==========�������============================================%
            if n1>0
                % 1. ����α�ࣨ����ͨ�����㣬������û������
                rp = lla2ecef([lat/pi*180, lon/pi*180, h]); %���ջ�λ��ʸ����ecef����������
                rs = sv(:,1:3);                             %����λ��ʸ����ecef����������
                rsp = ones(n,1)*rp - rs;                    %����ָ����ջ���λ��ʸ��
                rho = sum(rsp.*rsp, 2).^0.5;                %�����α��
                rspu = rsp ./ (rho*[1,1,1]);                %����ָ����ջ��ĵ�λʸ����ecef��
                % 2. ����α���ʣ�����ͨ�����㣬������û������
                vp = v*Cen;                                 %���ջ��ٶ�ʸ����ecef����������
                vs = sv(:,4:6);                             %�����ٶ�ʸ����ecef����������
                vsp = ones(n,1)*vp - vs;                    %���ջ�������ǵ��ٶ�ʸ��
                rhodot = sum(vsp.*rspu, 2);                 %�����α����
                % 3. �����������������������������
                f = 1/298.257223563;
                F = [-(Rn+h)*sin(lat)*cos(lon), -(Rn+h)*cos(lat)*sin(lon), cos(lat)*cos(lon);
                     -(Rn+h)*sin(lat)*sin(lon),  (Rn+h)*cos(lat)*cos(lon), cos(lat)*sin(lon);
                       (Rn*(1-f)^2+h)*cos(lat),             0,                 sin(lat)    ];
                HA = rspu*F;
                HB = rspu*Cen'; %����Ϊ����ϵ������ָ����ջ��ĵ�λʸ��
                Ha = HA(index1,:); %ȡ��Ч����
                Hb = HB(index2,:);
                H = zeros(n1+n2, 8);
                H(1:n1,1:3) = Ha;
                H(1:n1,7) = -ones(n1,1)*299792458;
                H((n1+1):end,4:6) = Hb;
                H((n1+1):end,8) = -ones(n2,1)*299792458;
                Z = [   rho(index1) - sv_m(index1,1); ... %α����������⣩
                     rhodot(index2) - sv_m(index2,2)];    %α���ʲ�
                R = diag([sigma(index1,1)', ...
                          sigma(index2,2)'])^2;
                % 4. �˲�����
                P = obj.Pk;
                K = P*H' / (H*P*H'+R);
                X = X + K*(Z-H*X);
                P = (eye(length(X))-K*H)*P;
                obj.Pk = (P+P')/2;
            end
            
            %==========��������============================================%
            obj.Plla = [lat,lon,h] - X(1:3)';
            obj.Vned = v - X(4:6)';
            obj.dtr = X(7);
            obj.dtv = X(8);
            
            %==========�������============================================%
            obj.pos = [obj.Plla(1)/pi*180, obj.Plla(2)/pi*180, obj.Plla(3)]; %deg
            obj.vel = obj.Vned; %m/s
            
            %==========�����˲��������α�ࡢα����=========================%
            % ����α��
            rp = lla2ecef(obj.pos);
            rs = sv(:,1:3);
            rsp = ones(n,1)*rp - rs;
            rho = sum(rsp.*rsp, 2).^0.5;
            rspu = rsp ./ (rho*[1,1,1]);
            % ����α����
            vp = obj.Vned*Cen;
            vs = sv(:,4:6);
            vsp = ones(n,1)*vp - vs;
            rhodot = sum(vsp.*rspu, 2);
            % ���Ӳ��Ƶ������
            rho = rho + obj.dtr*299792458; %�ӿ�ʹ������α��䳤
            rhodot = rhodot + obj.dtv*299792458; %�ӿ�ʹ������α���ʱ��
            
        end
        
    end %end methods
    
end %end classdef