% ��α���������غ���

n = 8; %һ�����ز���ȡ������
N = 20460*n;

B1Ccode = BDS_B1C_data_generate(19); %α�����
B1Ccode = reshape([B1Ccode;-B1Ccode],10230*2,1)'; %�����ز�
code = B1Ccode(floor((0:N-1)/n) + 1)'; %������������
codes = [code; code]'; %������
codes = circshift(codes,4*n); %��������Ƭ

m = 8*n + 1; %�ܼ������
R = zeros(m,1); %����

% �������
for k=1:m
    R(k) = codes(k:k+N-1) * code;
end

% ��ͼ
figure
plot(((1:m)-(m+1)/2)/2/n, R/20460/n, 'Marker','.', 'MarkerSize',10)
grid on
xlabel('��Ƭ')
ylabel('��һ�������ֵ')