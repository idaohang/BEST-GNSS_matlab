function [sv, E] = BDS_CNAV1_ephemeris_sv_ecef(ephemeris, t)
% ��������ʱt(s)ʹ��CNAV1�������������������ǣ�������λ���ģ��ڱ�������ϵ�е�����
% sv = [x,y,z, vx,vy,vz]
% ���ƫ�����E�����������������У��
% ���ռ��źŽӿڿ����ļ�B1C 1.0��

miu = 3.986004418e14; %m^3/s^2
w = 7.292115e-5; %rad/s

toe       = ephemeris(5);
SatType   = ephemeris(6);
dA        = ephemeris(7);
A_dot     = ephemeris(8);
dn0       = ephemeris(9);
dn0_dot   = ephemeris(10);
M0        = ephemeris(11);
e         = ephemeris(12);
omega     = ephemeris(13);
Omega0    = ephemeris(14);
i0        = ephemeris(15);
Omega_dot = ephemeris(16);
i0_dot    = ephemeris(17);
Cis       = ephemeris(18);
Cic       = ephemeris(19);
Crs       = ephemeris(20);
Crc       = ephemeris(21);
Cus       = ephemeris(22);
Cuc       = ephemeris(23);

if SatType==1 || SatType==2
    Aref = 42162200;
elseif SatType==3
    Aref = 27906100;
end
dt = t - toe;
if dt>302400
    dt = dt-604800;
elseif dt<-302400
    dt = dt+604800;
end
A0 = Aref + dA; %�ο�ʱ�̵ĳ�����
A = A0 + A_dot*dt; %������
n0 = sqrt(miu/A0^3);
dn = dn0 + 0.5*dn0_dot*dt;
n = n0 + dn; %ƽ�����ٶ�
M = mod(M0+n*dt, 2*pi); %ƽ����ǣ�0~2*pi
E = kepler(M, e); %ƫ�����
% v = 2 * mod(atan(sqrt((1+e)/(1-e))*tan(E/2)), pi); %�����ǣ�0~2*pi
sin_v = sqrt(1-e^2)*sin(E) / (1-e*cos(E));
cos_v = (cos(E)-e) / (1-e*cos(E));
v = atan2(sin_v, cos_v);
Phi = v + omega;
du = Cus*sin(2*Phi) + Cuc*cos(2*Phi);
dr = Crs*sin(2*Phi) + Crc*cos(2*Phi);
di = Cis*sin(2*Phi) + Cic*cos(2*Phi);
u = Phi + du;
r = A*(1-e*cos(E)) + dr;
i = i0 + i0_dot*dt + di;
xp = r*cos(u);
yp = r*sin(u);
Omega = Omega0 + (Omega_dot-w)*dt - w*toe;
x = xp*cos(Omega) - yp*cos(i)*sin(Omega);
y = xp*sin(Omega) + yp*cos(i)*cos(Omega);
z = yp*sin(i);

% �μ�������/GPS˫ģ������ջ�ԭ����ʵ�ּ�����283ҳ
d_E = (n0+dn0+dn0_dot*dt)/(1-e*cos(E)); %�б仯
d_Phi = sqrt(1-e^2)*d_E/(1-e*cos(E));
d_r = A_dot*(1-e*cos(E)) + A*e*sin(E)*d_E + 2*(Crs*cos(2*Phi)-Crc*sin(2*Phi))*d_Phi; %�б仯
d_u = d_Phi + 2*(Cus*cos(2*Phi)-Cuc*sin(2*Phi))*d_Phi;
d_Omega = Omega_dot-w;
d_i = i0_dot + 2*(Cis*cos(2*Phi)-Cic*sin(2*Phi))*d_Phi;
d_xp = d_r*cos(u) - r*sin(u)*d_u;
d_yp = d_r*sin(u) + r*cos(u)*d_u;
vx = d_xp*cos(Omega) - d_yp*cos(i)*sin(Omega) + yp*sin(i)*sin(Omega)*d_i - y*d_Omega;
vy = d_xp*sin(Omega) + d_yp*cos(i)*cos(Omega) - yp*sin(i)*cos(Omega)*d_i + x*d_Omega;
vz = d_yp*sin(i) + yp*cos(i)*d_i;

sv = [x,y,z, vx,vy,vz];

end