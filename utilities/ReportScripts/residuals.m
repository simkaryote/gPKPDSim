function residuals(taskResult, xaxis)
%RESIDUALS Plots residuals.
%
%    RESIDUALS(TASKRESULT, XAXIS) plots residuals versus
%    time, group or predicted value.
%
%    TASKRESULT is a structure containing a field for each output argument
%    from the task. The field SimdataI is the SimData Object obtained by
%    simulating the model using individual parameters. SimdataP is obtained
%    by using the population parameters for simulation.
%
%    XAXIS defines what is plotted on x-axis of the plot. Accepted values
%    are 'time', 'group' or 'predictions'.
%

% Error Checking.
if ~isfield(taskResult, 'TaskInfo')
    error('SimBiology:INVALID_PLOT_TYPE','This plot is supported only for Parameter Fit tasks.');
end

% Extract the observation data.
depVars = taskResult.TaskInfo.PKData.DependentVarLabel;
if ~iscell(depVars);
    depVars = {depVars};
end
obsData = selectbyname(taskResult.DataToFit, depVars);
numResponse = numel(depVars);

observed = taskResult.TaskInfo.PKModelMap.Observed;
predDataI = selectbyname(taskResult.SimdataI,observed);
if isfield(taskResult,'SimdataP')
    predDataP = selectbyname(taskResult.SimdataP,observed);
end

% Decide which residuals to plot
if strcmp(taskResult.TaskInfo.AlgorithmName, 'NLINFIT')
    resI     = vertcat(taskResult.Results.R);
    resTypes = {'Individual Residuals'};
    resP     = [];
elseif isfield(taskResult.Results.stats, 'cwres') % If sbionlmefit has computed weighted residuals i.e. after R2011a.
    % Decide which residuals to plot
    resTypes = {'CWRES', 'IWRES'};
    resP     = taskResult.Results.stats.cwres;
    resI     = taskResult.Results.stats.iwres;
    
    if strcmp(taskResult.TaskInfo.AlgorithmName, 'NLMEFIT') && strcmpi(taskResult.TaskInfo.ApproximationType, 'FO')
        resTypes = {'PWRES', 'IWRES'};
        resP = taskResult.Results.stats.pwres;
    end
    
    % Error if Weighted residuals are empty.
    if isempty(resP) || isempty(resI)
        error('SimBiology:residuals:NoWeightedResiduals','Residuals Plot could not be generated because weighted residuals could not be computed');
    end
else %Before R2011a
    resI = [];
    resP = [];
    resTypes = {'Individual Residuals'};
    if isfield(taskResult,'SimdataP')
        resTypes = {'Population Residuals', 'Individual Residuals'};
    end
    for i = 1:numel(predDataI)
        predI = predDataI(i).Data;
        if isfield(taskResult,'SimdataP')
            predP = predDataP(i).Data;
        end
        tempData = obsData(i).Data;
        
        % Remove all rows that have NaNs in all reposne columns.
        tempData = tempData(any(~isnan(tempData), 2), :);
        resI     =  [resI; tempData - predI]; %#ok<AGROW>
        if isfield(taskResult,'SimdataP')
            resP     =  [resP; tempData - predP]; %#ok<AGROW>
        end
    end
end

% Unit related information.
unitConversion  = false;
predDataUnits = cell(numResponse, 1);
obsDataUnits  = cell(numResponse, 1);
predTimeUnits   = '';
obsTimeUnits    = '';

if ~isempty(predDataI(1).RunInfo.ConfigSet) && predDataI(1).RunInfo.ConfigSet.CompileOptions.UnitConversion
    yLabel         = cell(numResponse, 1);
    predDataInfo   = predDataI(1).DataInfo;
    obsDataInfo    = obsData(1).DataInfo;
    unitConversion = true;
    for i = 1:numResponse
        predDataUnits{i} = predDataInfo{i}.Units;
        obsDataUnits {i} = obsDataInfo{i}.Units;
        predTimeUnits = predDataI(1).TimeUnits;
        obsTimeUnits  = obsData(1).TimeUnits;
        if ~isempty(predDataUnits{i}) && ~isempty(obsDataUnits{i}) && (strcmpi(taskResult.TaskInfo.AlgorithmName, 'NLINFIT') || ~isfield(taskResult.Results.stats, 'cwres'));
            resI(:,i)   = sbiounitcalculator(predDataUnits{i}, obsDataUnits{i}, resI(:,i));
            if isfield(taskResult,'SimdataP')
                resP(:, i)   = sbiounitcalculator(predDataUnits{i}, obsDataUnits{i}, resP(:, i)); %#ok<AGROW>
            end
            yLabel{i} = ['Residuals (' obsDataUnits{i} ')'];
        else
            yLabel{i} = 'Residuals';
        end
    end
else
    yLabel = repmat({'Residuals'}, numResponse, 1);
end

% Calculate the data to be plotted on x-axis.
xDataI = [];
xDataP = [];

labelx = cell(numResponse, 1);
for i = 1:numel(predDataI)
    Idx = any(~isnan(obsData(i).Data), 2);
    obsTime   = obsData(i).Time(Idx);
    if unitConversion
        obsTime = sbiounitcalculator(obsTimeUnits, predTimeUnits, obsTime);
    end
    
    % Resampling is required only if predDataI has more time points than
    % obsTime
    if numel(predDataI(i).Time) ~= numel(obsTime) || ~all(predDataI(i).Time == obsTime)
        predDataI(i) = predDataI(i).resample(obsTime);
        if isfield(taskResult,'SimdataP')
            predDataP(i) = predDataP(i).resample(obsTime);
        end
    end
    
    switch xaxis
        case 'time'
            tempI = predDataI(i).Time;
            if isfield(taskResult,'SimdataP')
                tempP = predDataP(i).Time;
            end
            if unitConversion
                if ~isempty(predTimeUnits) && ~isempty(obsTimeUnits)
                    tempI  = sbiounitcalculator(predTimeUnits, obsTimeUnits, tempI);
                    if isfield(taskResult,'SimdataP')
                        tempP  = sbiounitcalculator(predTimeUnits, obsTimeUnits, tempP);
                    end
                    labelx = {['Time (' obsTimeUnits ')']};
                end
            else
                labelx = {'Time'};
            end
            labelx = repmat(labelx, numResponse,1);
        case 'group'
            tempI = zeros(numel(predDataI(i).Time), 1);
            tempI(:) = i;
            if isfield(taskResult,'SimdataP')
                tempP = zeros(numel(predDataP(i).Time), 1);
                tempP(:) = i;
            end
            labelx = {'Group'};
            labelx = repmat(labelx, numResponse,1);
        case 'predictions'
            tempI = predDataI(i).Data;
            if isfield(taskResult,'SimdataP')
                tempP = predDataP(i).Data;
            end
            for resno = 1:numResponse
                if unitConversion
                    if ~isempty(predDataUnits) && ~isempty(obsDataUnits)
                        tempI(:, resno) = sbiounitcalculator(predDataUnits{resno}, obsDataUnits{resno}, tempI(:, resno));
                        if isfield(taskResult,'SimdataP')
                            tempP(:, resno) = sbiounitcalculator(predDataUnits{resno}, obsDataUnits{resno}, tempP(:, resno));
                        end
                    end
                    labelx{resno} = ['Predictions ('  obsDataUnits{resno} ')'];
                else
                    labelx{resno} = 'Predictions';
                end
            end
    end
    xDataI = [xDataI; tempI]; %#ok<AGROW>
    if isfield(taskResult,'SimdataP')
        xDataP = [xDataP; tempP]; %#ok<AGROW>
    end
end

subplotRows = numResponse;
subplotCols = 1;


if size(xDataI,2) == 1
    xDataI = repmat(xDataI, 1, numResponse);
end
if ~isempty(xDataP) && size(xDataP,2) == 1
    xDataP = repmat(xDataP, 1, numResponse);
end

% get names of DV data columns.
if ~iscell(taskResult.TaskInfo.PKData.DependentVarLabel)
    obsNames = {taskResult.TaskInfo.PKData.DependentVarLabel};
else
    obsNames = taskResult.TaskInfo.PKData.DependentVarLabel;
end

% Plot each response in its own subplot.
for resno = 1:numResponse
    
    % Plot Data.
    subplot(subplotRows, subplotCols, resno);
    if isfield(taskResult,'SimdataP')
        if ~isempty(xDataP)
            plot(xDataP(:,resno), resP(:,resno),'o',  'MarkerEdgeColor', 'b');
        end
        hold on;
        plot(xDataI(:,resno), resI(:,resno),'d', 'MarkerEdgeColor', 'r');
        
        legend(resTypes, 'Interpreter', 'none');
        hold off;
    else
        plot(xDataI(:,resno),resI(:,resno),'d','markeredgecolor', 'r');
        legend({'Individual'}, 'Interpreter', 'none');
    end
    
    % Create the y = 0 line.
    [x, ~] = adjustAxesLimitsForRes(gca);
    line([x(1) x(2)],[0 0])
    lines = get(gca,'children');
    lines = [lines(end); lines(2:end-1); lines(1)];
    set(gca,'children', lines);
    
    % Label the plot.
    title([ ' Residuals versus ' upper(xaxis(1)) xaxis(2:end) ' (Response' num2str(resno) ': '  obsNames{resno} ')'], 'Interpreter', 'none');
    xlabel(labelx{resno});
    ylabel(yLabel{resno});
end

function [xl, yl] = adjustAxesLimitsForRes(axesHandle)

lims = get(axesHandle, {'xlim', 'ylim'});
dx   = diff(lims{1});
dy   = diff(lims{2});

xtick = get(axesHandle, 'xtick');
ytick = get(axesHandle, 'ytick');

slack = .05;

xl = lims{1}+[-1 1]*dx*slack;
yl = lims{2}+[-1 1]*dy*slack;
set(gca, 'xlim',xl);
set(gca, 'ylim',yl);

set(axesHandle, 'xtick', xtick);
set(axesHandle, 'ytick', ytick);
