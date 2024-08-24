total_grf_array = load("squat-feedback-ML\2024_08_14\force_sample.mat", "total_grf_array");
total_grf_array = struct2cell(total_grf_array); total_grf_array = total_grf_array{1};
selectedFoot = 'left';
AE = cell(1,2);
for i=1:2
    grf_array = cell2mat(total_grf_array{1,i});
    
    fig = figure('Units','pixels','Position',[300, 100, 1200, 800]); % maximum 2000 pixels

    hold on;
    if i == 1
        title("0~1 minutes")
    else
        title("1~2 minutes")
    end
    legend;

    numCols = length(grf_array);
    t = 1:numCols;

    plot(t, grf_array, 'black', 'DisplayName', 'Original Data');
    
    data = readtable("squat-feedback-ML\2024_08_14\left_medial_lateral.xlsx");
    if strcmp(selectedFoot, 'left')
        l_target_force = data.lateral/2;
        r_target_force = data.medial/2;
    else
        l_target_force = data.medial/2;
        r_target_force = data.lateral/2;        
    end

    [max_grf, max_t] = findpeaks(grf_array, "MinPeakDistance",10, "MinPeakProminence", 30);
    TF = islocalmin(grf_array, "MinProminence",100); min_t = t(TF); min_grf = grf_array(TF);

    plot(min_t, min_grf, 'ro', 'DisplayName', 'peak points');
    plot(max_t, max_grf, 'ro', 'DisplayName', 'peak points');

    ml = struct('med',[], 'lat',[]);
    lr_target_force = containers.Map({'med', 'lat'}, {l_target_force, r_target_force});
    if selectedFoot == "left"
        flip_v = flip(values(lr_target_force));
        lr_target_force = containers.Map(keys(lr_target_force), flip_v);
    end
    direct = keys(lr_target_force);

    AE{1,i} = struct('med',[], 'lat',[]);
    AE{1,i}.(direct{1}) = mean(abs(min_grf - l_target_force));
    AE{1,i}.(direct{2}) = mean(abs(max_grf - r_target_force));
    
end

