%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   squat_feedback_ML
%   
%   ~ ~
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% reset setting
clear

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Medial lateral Maximal Force
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FootDict = containers.Map({'right', 'left'}, {1, 2});
%[l_ml_f, r_ml_f, err] = InputGUI_ML;
[l_ml_f, r_ml_f, selectedFoot, err] = MeasureMaxForce;

% if close the figure, we finish this trial
if ~isempty(err)
    disp("🚫 figure closed!, so be finished this trial")
    return;
end

% Connect to QTM
ip = '127.0.0.1';
% Connects to QTM and keeps the connection alive.
QCM('connect', ip, 'frameinfo', 'force');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure setting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create a figure window
figureHandle = figure('Position', [300, 300, 1200, 600], 'Name', 'ML Force Feedback', 'NumberTitle','off', 'Color', [0.8, 0.8, 0.8]);
hold on

% remove ticks from axes
set(gca,'YTick',[])

xlim = [l_ml_f * 1.5, r_ml_f * 1.5];
ylim = [0, 100];

% set limits for axes
set(gca, 'xlim', xlim, 'ylim', ylim)

% Create bars for left and right force
l_target_force = l_ml_f * 0.5;
r_target_force = r_ml_f * 0.5;
bar_left = bar(l_target_force, 100, 'FaceColor', 'yellow', 'BarWidth', 10);
bar_right = bar(r_target_force, 100, 'FaceColor', 'yellow', 'BarWidth', 10);
bar_realtime = bar(0, 100, 'FaceColor', 'blue', 'BarWidth', 10);

title('ML slider');
xlabel('Medial/Lateral Force (N)');

[fs, beep_sound, beep_interval] = SettingBeep;

% start timer
tStart = tic;
beep_count = 0;

% GRF data list for variability graph
total_grf_list = cell(1,2);

% to evaluate accuracy, save the peak GRF for each trial.
peak_grf = cell(1,2);

% Real time loop with 2 minutes, sound goes off 120 times.
% For each sound, force is applied alternately in the direction of the media material.
for rep = 1:2 % 2 minutes
    peak_grf{1, rep} = struct('med', [], 'lat', []);
    try
        tStart = tic;
        while true
            % wait until target value is reached
            event = QCM('event');
            % Fetch data from QTM
            [frameinfo,force] = QCM;
    
            if ~ishandle(figureHandle)
                QCM('disconnect');
                break;
            end
    
            % get GRF Y from plate 1, 2 unit : kgf
            ml_grf = force{2, FootDict(selectedFoot)}(1, 2);
    
            % Update the bars
            % plate y axis is output in the direction opposite to the axis.
            bar_realtime.XData = ml_grf;
    
            total_grf_list{1,rep} = [total_grf_list{1,rep}, ml_grf];
    
            % Play beep sound at the specified intervals
            elapsed_time = toc(tStart);
            if elapsed_time >= beep_count * beep_interval
                sound(beep_sound, fs);
                beep_count = beep_count + 1;
            end
    
            % update the figure
            drawnow;

            if toc(tStart) >= 60
                % Question : 논문에 의하면 peak value와 target force(50% Max) 를 비교하여 error를 구하는데, peak가 가장 큰 값인지, target과 가장 가까운 값인지?
                [~, l_idx] = min(abs(total_grf_list{1,rep} - l_target_force));
                [~, r_idx] = min(abs(total_grf_list{1,rep} - r_target_force));
                
                switch selectedFoot
                    case 'left'
                        % [peak GRF, Absolute Error]
                        peak_grf{1, rep}.lat = {total_grf_list{1,rep}(l_idx), min(abs(total_grf_list{1,rep} - l_target_force))};
                        peak_grf{1, rep}.med = {total_grf_list{1,rep}(r_idx), min(abs(total_grf_list{1,rep} - r_target_force))};
                    case 'right'
                        peak_grf{1, rep}.med = {total_grf_list{1,rep}(l_idx), min(abs(total_grf_list{1,rep} - l_target_force))};
                        peak_grf{1, rep}.lat = {total_grf_list{1,rep}(r_idx), min(abs(total_grf_list{1,rep} - r_target_force))};
                end
                break;
            end
        end

    catch exception
        disp(exception.message);
        break
    end
end

delete(figureHandle);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate Absolute Error
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lr_target_force = containers.Map({'med', 'lat'}, {l_target_force, r_target_force});
if selectedFoot == "left"
    flip_v = flip(values(lr_target_force));
    lr_target_force = containers.Map(keys(lr_target_force), flip_v);
end

GetAE(peak_grf, lr_target_force);

function GetAE(peak_grf, lr_target_force)
    % to evaluate accuracy, we calculated a number of error measures
    % Absolute error is the value of the difference between the peak and target force for each trial.
    direct = keys(lr_target_force);
    for rep = 1:2
        for i = 1:2
            fprintf('Absolute Error for %s: %2f %% %s for %i trials', direct{i}, peak_grf{1, rep}.(direct{i}){2}, rep);
        end
        disp(" ")
        disp(" ")
    end
end

function [fs, beep_sound, beep_interval] = SettingBeep(~, ~)
    fs = 8000;
    % Time vector for 0.5 second sound
    t_sound = 0:1/fs:0.5;
    % 1000 Hz
    beep_sound = sin(2*pi*1000*t_sound);
    
    % 120 times for 2 minutes
    total_duration = 120;
    % num of iterations
    num_beeps = 120;
    % pause duration between iterations
    beep_interval = total_duration / num_beeps;
end

function playBeep(~, ~)
    sound(beep_sound, fs);
end