% ѡ���ļ����б���B1C����

default_path = fileread('.\temp\path_data.txt'); %�����ļ�����Ĭ��·��
[file, path] = uigetfile([default_path,'\*.dat'], 'ѡ��GNSS�����ļ�'); %�ļ�ѡ��Ի���
if file==0
    disp('Invalid file!');
    return
end
data_file = [path, file];

acqResults = BDS_B1C_acq(data_file, 0*4e6, 1);