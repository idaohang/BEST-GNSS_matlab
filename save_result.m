% ����������н����������ӵ���ݼ���

initialVars = who; %ԭ�����ռ��еı�����

default_path = fileread('.\temp\path_result.txt'); %Ĭ�Ͻ���ļ��洢·��
[file, path] = uiputfile([default_path,'\matlab.mat']); %ѡ���ļ�·���������ļ�����Ĭ���ļ���matlab.mat���ر�file,path����0

if file~=0
    save([path,file], initialVars{:})
end

clearvars initialVars default_path file path