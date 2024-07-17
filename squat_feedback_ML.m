%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   squat_feedback_ML
%
%   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% reset setting
clear

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% bodyweight setting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[body_weight_kg, option] = MultiInputGUI("ML");

gravity = 9.80665; % gravity acceleration (m/s^2)
bodyweight_N = body_weight_kg * gravity;

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

% setting figure size to real force plate size
%           600mm      600mm
%        ---------------------
%      x↑         ¦           ¦
%       o → y     ¦           ¦ 400mm
%       ¦         ¦           ¦ 
%        ---------------------
% original coordinate : left end(x = 0) and center
xlim=[0 1200];
ylim = [0 round(bodyweight_N,0)]; % TODO : 데이터 최대값이 대충 얼마인지 파악해서 최대값 지정해야 함
% set limits for axes
set(gca, 'xlim',xlim, 'ylim',ylim)

% center coordinate for figure size
centerpoint = [(xlim(1) + xlim(2)) / 2, (ylim(1) + ylim(2)) / 2];

% bar blank between vertical center line and each bar
margin = 300; 
% initial location of each bar (bottom and center point of bar)
loc1_org = [centerpoint(1)-margin ylim(1)]; % x1 y
loc2_org = [centerpoint(1)+margin ylim(1)]; % x2 y

% width of each bar
width = 100;
% each bar height
height = ylim(2) - ylim(1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% draw outlines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% draw outline force plate
plot([0 0],get(gca,'ylim'),'k', 'linewidth',3)
plot([xlim(2) xlim(2)],get(gca,'ylim'),'k', 'linewidth',3)
plot([centerpoint(1) centerpoint(1)],get(gca,'ylim'),'k', 'linewidth',3)
plot(get(gca,'xlim'),[ylim(2) ylim(2)],'k', 'linewidth',3)
plot(get(gca,'xlim'),[ylim(1) ylim(1)],'k', 'linewidth',3)
title('Left                                                            Right','fontsize',30)

% make handles for each bar to update vGRF and AP COP data
plot_bar1 = plot([loc1_org(1) - width/2, loc1_org(1) - width/2], [ylim(1), ylim(1)], 'LineWidth', 90,'Color','red');
plot_bar2 = plot([loc2_org(1) + width/2, loc2_org(1) + width/2], [ylim(1), ylim(1)], 'LineWidth', 90,'Color','blue');

% draw left bar frame
plot([loc1_org(1)-width/2 loc1_org(1)+width/2],[height height],'k', 'linewidth',1) % top
plot([loc1_org(1)-width/2 loc1_org(1)-width/2],[ylim(1) height],'k', 'linewidth',1); % left
plot([loc1_org(1)+width/2 loc1_org(1)+width/2],[ylim(1) height],'k', 'linewidth',1); % right

% draw right bar frame
plot([loc2_org(1)-width/2 loc2_org(1)+width/2],[height height],'k', 'linewidth',1); % top
plot([loc2_org(1)-width/2 loc2_org(1)-width/2],[ylim(1) height],'k', 'linewidth',1); % left
plot([loc2_org(1)+width/2 loc2_org(1)+width/2],[ylim(1) height],'k', 'linewidth',1); % right

target_line = [];
target_text = [];

count_text = text(xlim(2)-100, ylim(2)-100, 'Count: 0', 'FontSize', 20, 'HorizontalAlignment', 'center', 'Color', 'black');

% Real time loop with 10 repetitions
for rep = 1:10
    %use event function to avoid crash
    try
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % draw target line
        %% Perform a target force 10 times at a random rate based on weight
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % 20% ~ 60% for body weight
        random_value = round(randi([2, 6]),0);
        target_value = bodyweight_N * random_value .* 0.1;

        if ishandle(target_line)
            delete(target_line);
        end
        if ishandle(target_text)
            delete(target_text);
        end

        % draw new target line and text
        target_line = plot([loc1_org(1) - width/2, loc2_org(1) + width/2], [target_value target_value], 'LineWidth', 10, 'Color', 'black');
        target_text = text(loc1_org(1) - width/2 - 100, target_value, sprintf("%d %% for \nbody weight", random_value * 10), 'FontSize', 20, 'HorizontalAlignment', 'center', 'Color', 'black');

        % wait until target value is reached
        while true
            event = QCM('event');
            % Fetch data from QTM
            [frameinfo,force] = QCM;
    
            fig = get(groot, 'CurrentFigure');
            % error occurs when getting realtime grf data. Sometimes there is no data.
            if isempty(fig)
                break
            end
            if isempty(force{2,1}) || isempty(force{2,2})
                continue
            end

            % get GRF X from plate 1, 2
            GRF1 = abs(force{2,2}(1,1))*20;
            GRF2 = abs(force{2,1}(1,1))*20;

            set(plot_bar1,'xdata',[loc1_org(1), loc1_org(1)],'ydata',[ylim(1), GRF1])
            set(plot_bar2,'xdata',[loc2_org(1), loc2_org(1)],'ydata',[ylim(1), GRF2])

            % update the figure
            drawnow;

            % check if target value is reached
            if GRF1 >= target_value || GRF2 >= target_value
                break
            end
        end 

        % Update the count text
        set(count_text, 'String', sprintf('Count: %d', rep));

        pause(3);

    catch exception
        disp(exception.message);
        break
    end
end

