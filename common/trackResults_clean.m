function trackResults = trackResults_clean(trackResults)

fields = fieldnames(trackResults); %����

M = size(trackResults,1); %�ṹ������
N = size(fields,1); %����

for ki=1:M
    for kj=3:N %�ӵ�3������ʼ
        eval('n = trackResults(ki).n;')
        eval(['trackResults(ki).',fields{kj},'(n:end,:) = [];'])
    end
end

end