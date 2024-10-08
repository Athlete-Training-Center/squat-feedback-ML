function [min_ml_f, max_ml_f, selectedFoot, err] = MeasureMaxForce
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   measure_max_force
    %
    %   * measure maximal force 3 times and 
    %     return the value for average of maximal forces
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    FootDict = containers.Map({'right', 'left'}, {1, 2});
    [selectedFoot, err] = InputGUI_MMF;

    if ~isempty(err)
        max_ml_f = '';
        min_ml_f = '';
        err = 'figure close';
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
    figureHandle = figure(1);
    hold on
    % set the figure size
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
    % remove ticks from axes
    set(gca,'YTick',[])
    
    xlim=[-600, 600];
    ylim=[0, 500];
    
    % set limits for axes
    set(gca, 'xlim', xlim, 'ylim',ylim)
    
    % center coordinate for figure size
    centerpoint = [(xlim(1) + xlim(2)) / 2, (ylim(1) + ylim(2)) / 2];

    % each bar width
    width = 200;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % draw outlines
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    title(sprintf('%s Foot\n<ㅡㅡㅡㅡㅡ    ㅡㅡㅡㅡㅡ>', selectedFoot), 'FontSize', 30);
    
    % center line
    plot([centerpoint(1), centerpoint(1)], get(gca, 'ylim'), 'LineWidth', 3,'Color','black');

    % make handles for each bar to update Medial Lateral Force
    ml_bar = barh(centerpoint(2), 0, 'FaceColor','green', 'BarWidth', width);
    
    %{
    % normalized unit about figure size
    circleRadius = 0.1;
    circleRadiusX = 0.1 * (500/1200);
    circle = annotation('ellipse', [0.2, 0.7, circleRadiusX, circleRadius]);
    pos_x = 130;
    pos_y = 420;
    count = text(xlim(1)+pos_x, pos_y, num2str(0), "FontSize", 40);
    %}
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % GRF data list for measuring maximal medial/lateral force
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % max iteration is 100,000 for preallocation, because of speed
    grf_array = zeros(1, 100000);
    i = 1;

    while ishandle(figureHandle)
        try
            event = QCM('event');
            [~, force] = QCM;
            try
                a = force{2,1}(1,7);
            catch exception
                continue
            end
            
            % get GRF Y from plate 1, 2 unit : kgf
            ml_grf = force{2, FootDict(selectedFoot)}(1, 2);
            
            ml_bar.YData = -ml_grf;

            grf_array(i) = -ml_grf;
            i = i+1;

            drawnow;
        
        catch exception
            disp(exception.message);
            break;
        end       
    end

    delete(figureHandle);

    disp(mink(grf_array, 3))
    disp(maxk(grf_array, 3))

    min_ml_f = mean(mink(grf_array, 3));
    max_ml_f = mean(maxk(grf_array, 3));

    ml = {'medial', 'lateral'};

    % the lateral medial direction is opposite when it is the left foot and right foot.
    if selectedFoot == "left"; ml = flip(ml); end
    
    fprintf("%s %s force: \n", selectedFoot, ml{1})
    disp(abs(min_ml_f));

    fprintf("%s %s force: \n", selectedFoot, ml{2})
    disp(abs(max_ml_f));
    
    date = datetime("now");
    ml{3} = 'date';
    dataTable = table(abs(min_ml_f), abs(max_ml_f), date, 'VariableNames', ml);
    
    dir_name = datestr(now, 'yyyy_mm_dd');
    mkdir(sprintf('squat-feedback-ML/%s',dir_name));
    file_name = sprintf('squat-feedback-ML/%s/%s_medial_lateral.xlsx',dir_name, selectedFoot);
    writetable(dataTable, file_name);
end