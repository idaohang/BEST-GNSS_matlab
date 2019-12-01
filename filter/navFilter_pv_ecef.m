classdef navFilter_pv_ecef < handle
% ecefϵPVģ�͵����˲���

    properties (GetAccess = public, SetAccess = private)
        pos       %λ�ã�[lat,lon,h]��[deg,deg,m]
        vel       %�ٶȣ�[ve,vn,vd]��m/s
        dtr       %�Ӳs
        dtv       %��Ƶ�s/s
        T         %�������ڣ�s
        Pk        %�˲���P��
        Qk        %�˲���Q��
    end %end properties
    
    properties (Access = private) %��������ʹ�õı���
        Pxyz      %λ�ã�[x,y,z]��m����������
        Vxyz      %�ٶȣ�[vx,vy,vz]��m/s����������
    end
    
    methods
        %% ����
        function obj = navFilter_pv_ecef(p0, v0, T, para)
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
            Cen = dcmecef2ned(p0(1), p0(2));
            obj.Pxyz = lla2ecef(p0);
            obj.Vxyz = v0*Cen;
        end
        
        %% ����
        function [rho, rhodot] = update(obj, sv, sv_m, sigma)
            % sv = [x,y,z, vx,vy,vz]������λ�á��ٶ�
            % sv_m = [rho_m, rhodot_m]������ֵ��α�ࡢα����
            % sigma = [sigma_rho, sigma_rhodot]������ֵ������׼��
            % rho, rhodot��ʹ���˲���λ�á��ٶȼ����α�ࡢα����
            
%             Cen = dcmecef2ned(obj.pos(1), obj.pos(2)); %�������������
            lat = obj.pos(1) /180*pi; %rad
            lon = obj.pos(2) /180*pi; %rad
            Cen = [-sin(lat)*cos(lon), -sin(lat)*sin(lon),  cos(lat);
                            -sin(lon),           cos(lon),         0;
                   -cos(lat)*cos(lon), -cos(lat)*sin(lon), -sin(lat)];
            
            %==========����״̬����========================================%
            v = obj.Vxyz; %�ٶȲ���
            p = obj.Pxyz + v*obj.T;
            
            %==========�˲���״̬����======================================%
            A = zeros(8);
            A(1,4) = 1;
            A(2,5) = 1;
            A(3,6) = 1;
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
                rp = p;                                     %���ջ�λ��ʸ����ecef����������
                rs = sv(:,1:3);                             %����λ��ʸ����ecef����������
                rsp = ones(n,1)*rp - rs;                    %����ָ����ջ���λ��ʸ��
                rho = sum(rsp.*rsp, 2).^0.5;                %�����α��
                rspu = rsp ./ (rho*[1,1,1]);                %����ָ����ջ��ĵ�λʸ����ecef��
                % 2. ����α���ʣ�����ͨ�����㣬������û������
                vp = v;                                     %���ջ��ٶ�ʸ����ecef����������
                vs = sv(:,4:6);                             %�����ٶ�ʸ����ecef����������
                vsp = ones(n,1)*vp - vs;                    %���ջ�������ǵ��ٶ�ʸ��
                rhodot = sum(vsp.*rspu, 2);                 %�����α����
                % 3. �����������������������������
                Ha = rspu(index1,:); %ȡ��Ч����
                Hb = rspu(index2,:);
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
            obj.Pxyz = p - X(1:3)';
            obj.Vxyz = v - X(4:6)';
            obj.dtr = X(7);
            obj.dtv = X(8);
            
            %==========�������============================================%
            obj.pos = ecef2lla(obj.Pxyz); %γ���ߣ�deg
            obj.vel = obj.Vxyz*Cen'; %����ϵ���ٶȣ�m/s
            
            %==========�����˲��������α�ࡢα����=========================%
            % ����α��
            rp = obj.Pxyz;
            rs = sv(:,1:3);
            rsp = ones(n,1)*rp - rs;
            rho = sum(rsp.*rsp, 2).^0.5;
            rspu = rsp ./ (rho*[1,1,1]);
            % ����α����
            vp = obj.Vxyz;
            vs = sv(:,4:6);
            vsp = ones(n,1)*vp - vs;
            rhodot = sum(vsp.*rspu, 2);
            % ���Ӳ��Ƶ������
            rho = rho + obj.dtr*299792458; %�ӿ�ʹ������α��䳤
            rhodot = rhodot + obj.dtv*299792458; %�ӿ�ʹ������α���ʱ��
            
        end
        
    end %end methods
    
end %end classdef