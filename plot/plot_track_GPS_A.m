plot_fun(trackResults_GPS_A, msToProcess, sampleFreq);

%% ��ͼ����
function plot_fun(trackResults, msToProcess, sampleFreq)
    for k=1:size(trackResults,1)
        if trackResults(k).n==1 %����û���ٵ�ͨ��
            continue
        end

        % ����������
        screenSize = get(0,'ScreenSize'); %��ȡ��Ļ�ߴ�
        w = screenSize(3); %��Ļ��
        h = screenSize(4); %��Ļ��
        figure('Position', [floor(w*0.15), floor(h*0.15), floor(w*0.7), floor(h*0.7)]);
        
        ax1 = axes('Position', [0.08, 0.4, 0.38, 0.53]);
        hold(ax1,'on');
        axis(ax1, 'equal');
        title(['PRN = ',num2str(trackResults(k).PRN)])
        ax2 = axes('Position', [0.53, 0.7 , 0.42, 0.25]);
        hold(ax2,'on');
        ax3 = axes('Position', [0.53, 0.38, 0.42, 0.25]);
        hold(ax3,'on');
        grid(ax3,'on');
        ax4 = axes('Position', [0.53, 0.06, 0.42, 0.25]);
        hold(ax4,'on');
        grid(ax4,'on');
        ax5 = axes('Position', [0.05, 0.06, 0.42, 0.25]);
        hold(ax5,'on');
        grid(ax5,'on');

        % ��ͼ
        plot(ax1, trackResults(k).I_Q(1001:end,1),trackResults(k).I_Q(1001:end,4), 'LineStyle','none', 'Marker','.') %I/Qͼ
        plot(ax2, trackResults(k).dataIndex/sampleFreq, trackResults(k).I_Q(:,1))
        plot(ax4, trackResults(k).dataIndex/sampleFreq, trackResults(k).carrFreq, 'LineWidth',1.5) %�ز�Ƶ��
        plot(ax5, trackResults(k).dataIndex/sampleFreq, trackResults(k).disc(:,1))
        plot(ax5, trackResults(k).dataIndex/sampleFreq, trackResults(k).std(:,1))

        % ����������
        set(ax2, 'XLim',[0,msToProcess/1000])
        set(ax3, 'XLim',[0,msToProcess/1000])
        set(ax4, 'XLim',[0,msToProcess/1000])
        set(ax5, 'XLim',[0,msToProcess/1000])
    end
end