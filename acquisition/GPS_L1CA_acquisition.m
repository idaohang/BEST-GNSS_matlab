% ѡ���ļ�����GPS L1CA����

default_path = fileread('.\temp\path_data.txt'); %�����ļ�����Ĭ��·��
[file, path] = uigetfile([default_path,'\*.dat'], 'ѡ��GNSS�����ļ�'); %�ļ�ѡ��Ի���
if file==0
    disp('Invalid file!');
    return
end
data_file = [path, file];

acqResults = GPS_L1CA_acq(data_file, 0*4e6, 12000, 1);