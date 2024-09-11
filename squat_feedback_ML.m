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
    bar_realtime.XData = 0;
    % Add text for countdown timer
    timerText = text(xlim(1)+20, 90, 'Start: 3', 'FontSize', 14, 'FontWeight', 'bold');
    
    w = waitforbuttonpress;
    if ~isempty(w)
        for sec = 3:-1:0
            set(timerText, 'String', ['Start: ', num2str(sec)]);
            pause(1);
        end
    end
    delete(timerText);
    try
        tStart = tic;
        beep_count = 0;
        i = 1;
        while true
            % wait until target value is reached
            event = QCM('event');
            % Fetch data from QTM
            [frameinfo,force] = QCM; %?
            
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

% save("squat-feedback-ML/force.mat", "total_grf_array")

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate Absolute Error
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
AE = GetAE(total_grf_array, l_target_force, r_target_force, selectedFoot);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

function total_peak_grf = GetPeakPoint(total_grf_array)
    total_peak_grf = cell(1,2);
    for i=1:2
        total_peak_grf{1, i} = struct('min', [], 'max', []);
        fig = figure('Units','pixels','Position',[300, 100, 1200, 800]); % maximum 2000 pixels
    
        hold on;
        if i == 1
            title("0~1 minutes")
        else
            title("1~2 minutes")
        end
        legend;
    
        grf_array = cell2mat(total_grf_array{1,i});
    
        numCols = length(grf_array);
        t = 1:numCols;
    
        % find peak points (local minima, maxima)
        [max_grf, max_t] = findpeaks(grf_array, "MinPeakDistance",10, "MinPeakProminence", 30);
        TF = islocalmin(grf_array, "MinProminence",100); min_t = t(TF); min_grf = grf_array(TF);
        total_peak_grf{1, i}.min = min_grf;
        total_peak_grf{1, i}.max = max_grf;
        
        plot(t, grf_array, 'black', 'DisplayName', 'Original Data');
        plot(min_t, min_grf, 'ro', 'DisplayName', 'peak points');
        plot(max_t, max_grf, 'ro', 'DisplayName', 'peak points');
    end
end

function changed = changeSide(origin, selectedFoot)
    if selectedFoot == "left"
        flip_v = flip(values(origin));
        changed = containers.Map(keys(origin), flip_v);
    end
end
function AE = GetAE(total_grf_array, l_target_force, r_target_force, selectedFoot)
    % to evaluate accuracy, we calculated a number of error measures
    % Absolute error is the value of the difference between the p   eak and target force for each trial.

    lr_target_force = containers.Map({'med', 'lat'}, {l_target_force, r_target_force});
    lr_target_force = changeSide(lr_target_force, selectedFoot);
    
    direct = keys(lr_target_force);

    total_peak_grf = GetPeakPoint(total_grf_array);
    AE = cell(1,2);
    
    for rep =1:2
        peak_grf = total_peak_grf{1, rep};
        AE{1, rep} = struct('med',[], 'lat',[]);

        min_target = min(l_target_force, r_target_force);
        max_target = max(l_target_force, r_target_force);
        
        AE{1,rep}.(direct{1}) = mean(abs(peak_grf.min - min_target));
        AE{1,rep}.(direct{2}) = mean(abs(peak_grf.max - max_target));
    end
end