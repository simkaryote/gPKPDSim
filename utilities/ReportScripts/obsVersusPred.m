function obsVersusPred(taskresult)
%OBSVERSUSPRED Plots observed values versus predicted values.
%
%    OBSVERSUSPRED(TASKRESULT) plots experimetal data versus the
%    predicted data obtained from the fit.
%
%    TASKRESULT is a structure containing a field for each output argument
%    from the task. The field SimdataI is the SimData Object obtained by
%    simulating the model using individual parameters. SimdataP is obtained
%    by using the population parameters for simulation.
%

% Error Checking.
if ~isfield(taskresult, 'TaskInfo')
    error('SimBiology:INVALID_PLOT_TYPE','This plot is supported only for Parameter Fit tasks.');
end

% Extract the observation data.
depVars      = taskresult.TaskInfo.PKData.DependentVarLabel;
if ~iscell(depVars);
    depVars = {depVars};
end
obsData      = selectbyname(taskresult.DataToFit, depVars);
numResponse  =  numel(depVars);

% Extract the prediction data. 
observed = taskresult.TaskInfo.PKModelMap.Observed;
if strcmp(taskresult.TaskInfo.AlgorithmName,'NLINFIT')
    predDataI  = selectbyname(taskresult.SimdataI, observed);
else
    predDataI  = selectbyname(taskresult.SimdataI, observed);
    predDataP  = selectbyname(taskresult.SimdataP, observed);
end

% Unit related information.
unitConversion  = false;
labelX        = cell(numResponse, 1);
labelY        = cell(numResponse, 1);
predDataUnits = cell(numResponse, 1);
obsDataUnits  = cell(numResponse, 1);
predDataInfo  = predDataI(1).DataInfo;
obsDataInfo   = obsData(1).DataInfo;

obsTimeUnits  = obsData(1).TimeUnits;
predTimeUnits  = predDataI(1).TimeUnits;
if ~isempty(predDataI(1).RunInfo.ConfigSet) && predDataI(1).RunInfo.ConfigSet.CompileOptions.UnitConversion
    unitConversion  = true;
    for i = 1:numResponse  
        predDataUnits{i} = predDataInfo{i}.Units;
        obsDataUnits{i}  = obsDataInfo{i}.Units;
        labelX{i}    = ['Predictions (' obsDataUnits{i} ')'];
        labelY{i}    = ['Observations (' obsDataUnits{i} ')'];
    end
else
    for i = 1:numResponse
        labelX{i} = 'Predictions';
        labelY{i} = 'Observations';
    end
end
    

% Create the predicted and observed data.
predI = [];
predP = [];
obs   = [];
for i = 1:numel(predDataI)
    
    obsTime = obsData(i).Time;
    % Remove all rows that have NaNs in all reposne columns.
    Idx = any(~isnan(obsData(i).Data), 2);
    obsTime = obsTime(Idx);
    obs      = [obs; obsData(i).Data(Idx, :)];  %#ok<AGROW>
    
    % resample simDataI and simDataP at the observation time points.
    if unitConversion
        obsTime = sbiounitcalculator(obsTimeUnits, predTimeUnits, obsTime);
    end
    
    % Resampling is required only if predDataI has more time points than
    % obsTime
    if  numel(predDataI(i).Time) ~= numel(obsTime) || ~all(predDataI(i).Time == obsTime)
        predDataI(i) = predDataI(i).resample(obsTime);
        if exist('predDataP','var') && ~isempty(predDataP)
            predDataP(i) = predDataP(i).resample(obsTime);
        end
    end
    predI = [predI; predDataI(i).Data]; %#ok<AGROW>
    if exist('predDataP','var') && ~isempty(predDataP)
        predP = [predP; predDataP(i).Data]; %#ok<AGROW>
    end
    
end

% If unit conversion is on, convert data to observation data units
if unitConversion
    for i = 1:numResponse
        if ~isempty(predDataUnits{i}) && ~isempty(obsDataUnits{i})
            predI(:,i) = sbiounitcalculator(predDataUnits{i}, obsDataUnits{i}, predI(:, i)); %#ok<AGROW>
            if ~isempty(predP)
                predP(:, i) = sbiounitcalculator(predDataUnits{i}, obsDataUnits{i}, predP(:, i)); %#ok<AGROW>
            end
        end
    end
end

subplotRows = ceil(sqrt(numResponse));
subplotCols = ceil(numResponse/subplotRows);

% get names of DV data columns.
if ~iscell(taskresult.TaskInfo.PKData.DependentVarLabel)
    obsNames = {taskresult.TaskInfo.PKData.DependentVarLabel};
else
    obsNames = taskresult.TaskInfo.PKData.DependentVarLabel;
end
% Plot each response in its own subplot.
for resno = 1:numResponse
    
    % Plot the data.
    subplot(subplotRows, subplotCols, resno);
    if ~isempty(predP)
        plot(predI(:,resno), obs(:,resno), 'd', 'MarkerEdgeColor','r');
        hold on;
        plot(predP(:,resno), obs(:,resno), 'o', 'MarkerEdgeColor','b');
        legend({'Individual', 'Population'}, 'Location', 'NorthWest');
        hold off;
    else
        plot(predI(:,resno), obs(:,resno), 'd', 'MarkerEdgeColor','r');
        legend('Individual', 'Location', 'NorthWest');
    end
    
    % y = x line
    [xl yl] = adjustAxesLimitsForObsVPred(gca);
    minimum = min([xl yl]);
    maximum = max([xl yl]);
    line('XData', [minimum maximum],'YData',[minimum maximum], 'Color','b');
    lines = get(gca,'children');
    lines = [lines(end); lines(2:end-1); lines(1)];
    set(gca,'children', lines);
    
    % Label the plot.
    title(['Observation versus Prediction (Response' num2str(resno) ': ' obsNames{resno} ')'], 'Interpreter', 'none');
    xlabel(labelX{resno});
    ylabel(labelY{resno});
end

function [xl, yl] = adjustAxesLimitsForObsVPred(axesHandle)

lims = get(axesHandle, {'xlim', 'ylim'});
dx   = diff(lims{1});
dy   = diff(lims{2});

xtick = get(axesHandle, 'xtick');
ytick = get(axesHandle, 'ytick');

slack = .05;

xl = lims{1}+[-1 1]*dx*slack;
yl = lims{2}+[-1 1]*dy*slack;
set(gca, 'xlim', xl);
set(gca, 'ylim', yl);

set(axesHandle, 'xtick', xtick);
set(axesHandle, 'ytick', ytick);
