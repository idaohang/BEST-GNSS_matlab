function output = clean_receiverOutput(output)
% �Զ�ʶ��ṹ���еĳ���������������

fields = fieldnames(output); %����
N = size(fields,1); %����

%---ɾ����β���������
index = find(isnan(output.state)); %��״̬����
for k=2:N
    if strcmp(fields{k}(1:2),'sv') %����ǰ׺��sv
        eval(['output.',fields{k},'(:,:,index) = [];'])
    else
        eval(['output.',fields{k},'(index,:) = [];'])
    end
end

%---ɾ�����ջ�δ��ʼ��������
index = find(output.state == 0); %0״̬����
for k=2:N
    if strcmp(fields{k}(1:2),'sv')
        eval(['output.',fields{k},'(:,:,index) = [];'])
    else
        eval(['output.',fields{k},'(index,:) = [];'])
    end
end

output.n = length(output.ta); %���ݸ���

end