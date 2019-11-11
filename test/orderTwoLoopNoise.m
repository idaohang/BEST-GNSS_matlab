% ������׻��������
% 2Hz���������������Ϊ0.07
% 25Hz���������������Ϊ0.22

[K1, K2] = orderTwoLoopCoef(25, 0.707, 1);

n = 10000; %�ܵ���
dt = 0.001; %ʱ����
X = randn(n,1); %����
Y = zeros(n,1); %���

x1 = 0; %�������������
x2 = 0; %�ܻ������
for k=1:n
    e = X(k) - x2;
    x1 = x1 + K2*e*dt;
    x2 = x2 + (K1*e+x1)*dt;
    Y(k) = x2;
end

figure
plot((1:n)*dt, X)
hold on
plot((1:n)*dt, Y)

disp(std(Y)) %���������׼��