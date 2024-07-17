%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   ACL_biofeedback
%
%   Code showing real time vGRF and AP COP data
% 코드 설명, 코드 목적, 기능, 작성자, 업데이트 날짜
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% reset setting
% QCM('disconnect');
% clear

% Connect to QTM
ip = '127.0.0.1';

% Connects to QTM and keeps the connection alive.
QCM('connect', ip, 'frameinfo', 'force');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure setting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create a figure window
figureHandle = figure(1);
hold on
% set the figure size
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
% remove ticks from axes
set(gca,'XTICK',[],'YTick',[])

% setting figure size to realworld size
xlim=[0 1200]; % 600 mm x 2
ylim=[-200 200]; % 400 mm
% set limits for axes
set(gca, 'xlim',xlim, 'ylim',ylim)

% center coordinate for figure size
centerpoint = [(xlim(1)+xlim(2))/2 (ylim(1)+ylim(2))/2];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% foot size setting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if you want to input foot size, must use this option
% foot_size = '270';
foot_size = inputdlg("input the foot size (mm): ");
foot_size = str2double(foot_size);
if foot_size <= 0 || foot_size >= 350
    disp('bad size! try again');
end

% Start the graph from the bottom to the top 70mm
start_valuey = 70;
% Required for 20% calculation of foot size from the center of foot size
foot_center = ylim(2) - start_valuey - foot_size/2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%initialize the COP circle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% bar blank between two bar
margin = 300; 
% initial location of each bar
loc1_org = [centerpoint(1)-margin 0]; % x1 y
loc2_org = [centerpoint(1)+margin 0]; % x2 y
% width of each bar
width = 100;
% height of bars
height = start_valuey + foot_size - 200;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% drawing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make handles for each bar to update vGRF and AP COP data
plot_bar1 = plot([loc1_org(1)-width/2, loc1_org(1)-width/2], [ylim(1) + 70, foot_center], 'LineWidth', 90,'Color','red');
plot_bar2 = plot([loc2_org(1)+width/2, loc2_org(1)+width/2], [ylim(1) + 70, foot_center], 'LineWidth', 90,'Color','blue');

% draw left bar frame
plot([loc1_org(1)-width/2 loc1_org(1)+width/2],[height height],'k', 'linewidth',1) % top
plot([loc1_org(1)-width/2 loc1_org(1)-width/2],[ylim(1) height],'k', 'linewidth',1); % left
plot([loc1_org(1)+width/2 loc1_org(1)+width/2],[ylim(1) height],'k', 'linewidth',1); % right

% draw right bar frame
plot([loc2_org(1)-width/2 loc2_org(1)+width/2],[height height],'k', 'linewidth',1); % top
plot([loc2_org(1)-width/2 loc2_org(1)-width/2],[ylim(1) height],'k', 'linewidth',1); % left
plot([loc2_org(1)+width/2 loc2_org(1)+width/2],[ylim(1) height],'k', 'linewidth',1); % right

% draw auxiliary lines
start_lineh = plot([xlim(1) xlim(2)], [ylim(1)+start_valuey ylim(1)+start_valuey],'black','linestyle','--', 'LineWidth',1); % 70mm
p20_line_value = foot_size * 0.2;
p20_upper_lineh = plot([loc1_org(1)-width/2 loc2_org(1)+width/2], [foot_center+p20_line_value foot_center+p20_line_value], ...
                        'black','LineWidth', 10);
p20_under_lineh = plot([loc1_org(1)-width/2 loc2_org(1)+width/2], [foot_center-p20_line_value foot_center-p20_line_value], ...
                        'black','LineWidth', 10);
text(loc1_org(1)-width/2-50, foot_center+p20_line_value, num2str(foot_center + p20_line_value),'fontsize', 20);
text(loc1_org(1)-width/2-50, foot_center-p20_line_value, num2str(foot_center - p20_line_value),'fontsize', 20);
cop1_value = text(loc1_org(1)-width/2-50, centerpoint(2), num2str(0), 'FontSize', 30);
cop2_value = text(loc2_org(1)+width/2+50, centerpoint(2), num2str(0), 'FontSize', 30);

% draw outline force plate
plot([0 0],get(gca,'ylim'),'k', 'linewidth',3)
plot([xlim(2) xlim(2)],get(gca,'ylim'),'k', 'linewidth',3)
plot([centerpoint(1) centerpoint(1)],get(gca,'ylim'),'k', 'linewidth',3)
plot(get(gca,'xlim'),[ylim(2) ylim(2)],'k', 'linewidth',3)
plot(get(gca,'xlim'),[ylim(1) ylim(1)],'k', 'linewidth',3)
title('Left                                                            Right','fontsize',30)

event = QCM('event');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COP data list for variability graph
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cop_list1 = [];
cop_list2 = [];

% Real time loop
while ishandle(figureHandle)
    %use event function to avoid crash
    try
        event = QCM('event');
        % ### Fetch data from QTM
        [frameinfo,force] = QCM;
        
        fig = get(groot, 'CurrentFigure');
        % error occurs when getting realtime grf data. Sometimes there is no data.
        if isempty(fig)
            break
        end    
        if isempty(force{2,1}) || isempty(force{2,2})
            continue
        end
        
        GRF1 = abs(force{2,2}(1,3));%get GRF Z from plate 1
        GRF2 = abs(force{2,1}(1,3));%get GRF Z from plate 2

        COP1Z = (force{2,2}(1,7));
        COP2Z = (force{2,1}(1,7));
        
        % Update each bar and COP line        
        set(plot_bar1,'xdata',[loc1_org(1) loc1_org(1)],'ydata',[ylim(1)+start_valuey COP1Z])
        set(plot_bar2,'xdata',[loc2_org(1) loc2_org(1)],'ydata',[ylim(1)+start_valuey COP2Z])
        set(cop1_value,'string', round(COP1Z, 1), 'Position', [loc1_org(1)-width/2-100, COP1Z]);
        set(cop2_value,'string', round(COP2Z, 1), 'Position', [loc2_org(1)+width/2+100, COP2Z]);
        
        % append cop to cop_list
        cop_list1 = [cop_list1, COP1Z];
        cop_list2 = [cop_list2, COP2Z];
           
        % update the figure
        drawnow;
    catch exception
        display(event)
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% noise filtering
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i=1:2
    if i == 1
        cop_list = cop_list1;
    else
        cop_list = cop_list2;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % remove unnecessary data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    new_cop_list = [];
    start_collect = false;
    for j = 1:length(cop_list)
        if cop_list(j) > -5 || cop_list(j) < 5
            start_collect = true;
        end
    
        if start_collect
            new_cop_list = [new_cop_list, cop_list(j)];
        end
    end    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % draw the graph
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    new_cop_list = new_cop_list.*-1;
    n = length(new_cop_list);
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % calculate RMSE(Root Mean Sqaure Error)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    upper_target_value = foot_center+p20_line_value;
    upper_rmse = sqrt(sum((new_cop_list - upper_target_value).^2) / n);
    disp(['Upper Mean Percent Difference: ', num2str(upper_rmse), '%']);

    lower_target_value = (foot_center-p20_line_value);
    lower_rmse = sqrt(sum((new_cop_list - lower_target_value).^2) / n);
    disp(['Lower Mean Percent Difference: ', num2str(lower_rmse), '%']);
    
    [numRows, numCols] = size(new_cop_list);

    subplot(2,1,i);
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
    
    hold on;
    plot([1 numCols], [upper_target_value upper_target_value], ...
                            'black','LineWidth', 1, 'LineStyle','--');
    plot([1 numCols], [lower_target_value lower_target_value], ...
                            'black','LineWidth', 1, 'LineStyle','--');
    
    title(sprintf('Percent Difference from Target Value %.i plate', i), 'FontSize', 20);
    xlabel('Time ', 'FontSize', 15);
    ylabel('Difference ', 'FontSize', 15);
    grid on;
    
    plot((1: numCols), new_cop_list, 'black');
    
    text_position_x = round(numCols / 2);
    upper_text_position_y = upper_target_value+5;
    lower_text_position_y = lower_target_value-5;
    
    % 상단 평균 퍼센트 차이 텍스트 추가
    text(text_position_x, upper_text_position_y, ['RMSE: ', num2str(upper_rmse), '%'], ...
        'FontSize', 15, 'HorizontalAlignment', 'center', 'Color', 'red');
    
    % 하단 평균 퍼센트 차이 텍스트 추가
    text(text_position_x, lower_text_position_y, ['RMSE: ', num2str(lower_rmse), '%'], ...
        'FontSize', 15, 'HorizontalAlignment', 'center', 'Color', 'blue');
end

QCM('disconnect');
clear mex
