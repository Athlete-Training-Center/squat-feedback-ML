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
    
    % if date input, save that in variables
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
