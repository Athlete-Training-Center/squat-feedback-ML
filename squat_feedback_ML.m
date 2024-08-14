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

% GRF data array for variability graph
total_grf_array = cell(1,2);

% Real time loop with 2 minutes, sound goes off 120 times.
% For each sound, force is applied alternately in the direction of the media material.
for rep = 1:2 % 2 minutes
    uiwait(figureHandle);
    %% TODO: 시작 전 멈춰있고, 사용자가 버튼 or 키(q or enter)를 누르면 시작하도록 하기
    try
        tStart = tic;
        beep_count = 0;
        i = 1;
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
            bar_realtime.XData = -ml_grf;
    
            total_grf_array{1,rep}{i} = -ml_grf;
            i = i + 1;

            % update the figure
            drawnow;

            % Play beep sound at the specified intervals
            elapsed_time = toc(tStart);
            if elapsed_time >= beep_count * beep_interval
                sound(beep_sound, fs);
                beep_count = beep_count + 1;
            end

            if elapsed_time >= 60
                break;
            end
        end

    catch exception
        disp(exception.message);
        break
    end
end

delete(figureHandle);

% to evaluate accuracy, save the peak GRF for each trial.
peak_grf = cell(1,2);

for rep =1:2
    grf_array = cell2mat(total_grf_array{1, rep});
    peak_grf{1, rep} = struct('med', [], 'lat', []);
    
    % Question : 논문에 의하면 peak value와 target force(50% Max) 를 비교하여 error를 구하는데, peak가 가장 큰 값인지, target과 가장 가까운 값인지?
    [~, l_idx] = min(abs(grf_array - l_target_force));
    [~, r_idx] = min(abs(grf_array - r_target_force));
    
    switch selectedFoot
        case 'left'
            % [peak GRF, Absolute Error]
            peak_grf{1, rep}.lat = {grf_array(l_idx), min(abs(grf_array - l_target_force))};
            peak_grf{1, rep}.med = {grf_array(r_idx), min(abs(grf_array - r_target_force))};
        case 'right'
            peak_grf{1, rep}.med = {grf_array(l_idx), min(abs(grf_array - l_target_force))};
            peak_grf{1, rep}.lat = {grf_array(r_idx), min(abs(grf_array - r_target_force))};
    end
end

% save("squat-feedback-ML/force.mat", "total_grf_array")

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
    % Absolute error is the value of the difference between the p   eak and target force for each trial.
    direct = keys(lr_target_force);
    for rep = 1:2
        for i = 1:2
            fprintf('Absolute Error for %s: %2f %% at %i trials', direct{i}, peak_grf{1, rep}.(direct{i}){2}, rep);
            disp(" ")
        end
        disp(" ")
        disp(" ")
    end
end

function [fs, beep_sound, beep_interval] = SettingBeep(~, ~)
    fs = 8000;
    % Time vector for 0.3 second sound
    t_sound = 0:1/fs:0.3;
    % 1000 Hz
    beep_sound = sin(2*pi*1000*t_sound);
    
    % 240 times for 2 minutes
    total_duration = 120;
    % num of iterations
    num_beeps = 120;
    % pause duration between iterations
    beep_interval = total_duration / num_beeps;
end

function playBeep(~, ~)
    sound(beep_sound, fs);
end

numCols = length(grf_array);

% find inflection point
grad = gradient(grf_array);
grad_diff = gradient(grad);
threshold = 10;
peak_points = find(abs(grad_diff) > threshold);
%{
windowSize = 3;
movingAVGfilteredData = movmean(grf_diff_array, windowSize);

slopeMAF = diff(movingAVGfilteredData);
slope_changeMAF = diff(slopeMAF);
threshold = 20;
peak_pointsMAF = find(abs(slope_changeMAF) > threshold);

plot((1:numCols), movingAVGfilteredData, 'b-', 'DisplayName', 'Moving AVG filter Data')
plot(peak_pointsMAF + 2, movingAVGfilteredData(peak_pointsMAF + 2), 'bo', 'DisplayName', 'peak point MVG');
%}

legend;
plot((1:numCols), grf_array, 'b-', 'DisplayName', 'Original Data');
hold on;
plot(peak_points, grf_array(peak_points), 'ro', 'DisplayName', 'peak point');