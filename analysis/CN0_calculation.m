% ��������ȼ��㷽��
% M��ֵСʱ��CN0i�����󣬵�M����ʱ��CN0i�����½�������
% ƽ������Խ��CN0m����ԽС����ƽ������Ϊ1000����ʱ��CN0m�ǳ��ӽ�����ֵ

A = 10;
sigma = 0.2;

n = 200*1000; %���ݵ���

I = randn(n,1)*sigma + A;
Q = randn(n,1)*sigma;

% figure %��ɢ��ֲ�
% plot(I,Q, 'LineStyle','none', 'Marker','.')
% grid on
% axis equal
% set(gca, 'Xlim', [-5*sigma-A, 5*sigma+A])
% set(gca, 'Ylim', [-5*sigma-A, 5*sigma+A])

M = 20; %���խ���������ݶε���
N = n/M; %���ݶθ���

NBP_WBP = zeros(N,1);

for k=1:N
    Id = I((k-1)*M+(1:M));
    Qd = Q((k-1)*M+(1:M));
    WBP = sum(Id.^2 + Qd.^2); %��ƽ�������
    NBP = sum(Id)^2 + sum(Qd)^2; %�������ƽ��
    NBP_WBP(k) = NBP / WBP;
end

figure
CN0i = sqrt(2*(NBP_WBP-1)./(M-NBP_WBP)); %��һ��NBP/WBP���������
plot(CN0i)
hold on

Z = movmean(NBP_WBP,25); %ʹ��NBP/WBP�ľ�ֵ��������ȣ����������ȼ��㹫ʽ������
CN0m = sqrt(2*(Z-1)./(M-Z)); %�������ֵӦ�õ���A/sigma
plot(CN0m)