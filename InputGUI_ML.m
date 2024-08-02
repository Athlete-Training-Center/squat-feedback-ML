function [min_ml_f, max_ml_f, sideFoot, err] = InputGUI_ML
    % Initialize output variables
    min_ml_f = '';
    max_ml_f = '';

    [sideFoot, err] = InputGUI_MMF;

    if ~isempty(err)
        min_ml_f = '';
        max_ml_f = '';
        err = 'figure close';
        return;
    end
        

    sentence = {'Input Medial Force (N) : ', 'Input Lateral Force (N) : '};
   
    % Create a figure for the GUI
    fig = figure('Position', [300, 300, 400, length(sentence) * 100], 'MenuBar', 'none', 'Name', 'Medial Lateral Project', 'NumberTitle', 'off', 'Resize', 'off', 'CloseRequestFcn', @closeCallback);

    % Create the first input label and text box
    uicontrol('Style', 'text', 'Position', [50, 140, 200, 30], 'String', sentence{1}, 'HorizontalAlignment', 'left', 'FontSize', 10);
    l_max_force_Box = uicontrol('Style', 'edit', 'Position', [250, 140, 100, 30], 'FontSize', 10);

    % Create the second input label and text box
    uicontrol('Style', 'text', 'Position', [50, 80, 200, 30], 'String', sentence{2}, 'HorizontalAlignment', 'left', 'FontSize', 10);
    r_max_force_Box = uicontrol('Style', 'edit', 'Position', [250, 80, 100, 30], 'FontSize', 10);

    % Create a submit button
    uicontrol('Style', 'pushbutton', 'Position', [150, 20, 100, 40], 'String', 'Submit', 'FontSize', 10, 'Callback', @submitCallback);

    % Store initial data in the figure's UserData property
    data.l_max_f = '';
    data.r_max_f = '';
    set(fig, 'UserData', data);

    % Wait for the user to close the figure
    uiwait(fig);

    % Check if the figure still exists before retrieving data
    if isvalid(fig)
        data = get(fig, 'UserData');
        min_ml_f = data.l_max_f;
        max_ml_f = data.r_max_f;
        delete(fig);
    else
        disp('Figure was closed before data could be retrieved.');
    end

    % Callback function for the submit button
    function submitCallback(~, ~)
        min_ml_f = str2double(get(l_max_force_Box, 'String'));
        max_ml_f = str2double(get(r_max_force_Box, 'String'));
        
        % Store the inputs in the figure's UserData property
        data.l_max_f = min_ml_f;
        data.r_max_f = max_ml_f;
        set(fig, 'UserData', data);

        % Resume the GUI
        uiresume(fig);
    end

    % Callback function for closing the figure
    function closeCallback(~, ~)
        % Resume the GUI
        uiresume(fig);
        % Delete the figure
        delete(fig);
        err = 'figure closed';
    end

    function [sideFoot, err] = InputGUI_MMF
        % we must initialize output variables
        sideFoot = '';
        err = '';

        fig = figure('Position', [300, 300, 400, 200], 'MenuBar','none', 'Name', ...
            'Measure Maximal Force', 'NumberTitle','off', 'Resize','off', ...
            'CloseRequestFcn',@closeCallback);
        
        % Create input label and text bot
        uicontrol('Style','text', 'Position', [50, 120, 200, 30], 'String', ...
            'choose left or right foot (left/right)', 'HorizontalAlignment', 'left', 'FontSize',10);
        sideFoot_box = uicontrol('Style', 'edit', 'Position', [250, 120, 100, 30], 'FontSize',10);
        
        % Create a submit button
        uicontrol('Style', 'pushbutton', 'Position', [150, 20, 100, 40], 'String', ...
           'Submit', 'FontSize',10, 'Callback', @submitCallback);
        
        % Store initial data in the figure's UserData property
        data.sideFoot = '';
        set(fig, 'UserData', data);
        
        % Wait for the user to close the figure
        uiwait(fig);
        
        if isvalid(fig)
            data = get(fig, 'UserData');
            sideFoot = data.sideFoot;
            delete(fig);
        else
            disp('Figure was closed before data could be retrieved')
        end

        % Callback function for the submit button
        function submitCallback(~, ~)
            sideFoot = get(sideFoot_box, 'String');

            % store the inputs in the figure's UserData property
            data.sideFoot = sideFoot;
            set(fig, 'UserData', data);

            % Resume the GUI
            uiresume(fig);
        end

        % Callback function for closing the figure
        function closeCallback(~, ~)
            % Resume the GUI
            uiresume(fig);

            % Delete the figure
            delete(fig);

            err = 'figure close';
        end
    end
end
