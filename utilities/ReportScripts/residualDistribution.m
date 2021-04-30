function residualDistribution(taskResult)
%RESIDUALDISTRIBUTION Creates a normplot of the residuals.
%
%    RESIDUALDISTRIBUTION(TASKRESULT) creates a normal
%    probability plot of residuals.
%
%    TASKRESULT is a structure containing a field for each output argument
%    from the task. The field SimdataI is the SimData Object obtained by
%    simulating the model using individual parameters. SimdataP is obtained
%    by using the population parameters for simulation.
%
%    See also NORMPLOT.

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

if strcmp(taskResult.TaskInfo.AlgorithmName, 'NLINFIT')
    resI = vertcat(taskResult.Results.R);
    resP = [];
    resTypes = {'Individual Residuals'};
    
elseif isfield(taskResult.Results,'stats') && isfield(taskResult.Results.stats, 'cwres') % If sbionlmefit has computed weighted residuals i.e. after R2011a.
    % Decide which residuals to plot
    resTypes = {'CWRES', 'IWRES'};
    resP = taskResult.Results.stats.cwres;
    resI = taskResult.Results.stats.iwres;
    
    if strcmp(taskResult.TaskInfo.AlgorithmName, 'NLMEFIT') && strcmpi(taskResult.TaskInfo.ApproximationType, 'FO') % We want to plot PWRES if FO is used.
        resTypes = {'PWRES', 'IWRES'};
        resP = taskResult.Results.stats.pwres;
    end
    
    % Error if Weighted residuals are empty.
    if isempty(resP) || isempty(resI)
        error('SimBiology:residuals:NoWeightedResiduals','Residual Distribution Plot could not be generated because weighted residuals could not be computed');
    end
else %Before R2011a
    id  = 'SimBiolology:residuals:Before_2011a';
    msg = 'Residual plots are displaying raw residuals. To compute and display weighted residuals rerun the task.';
    sbiogate('messagehandler', [], msg, id, 'Residual Distribution', 'Plot', 'Plot', false, true);
    resI = [];
    resP = [];
    observed = taskResult.TaskInfo.PKModelMap.Observed;
    predDataI = selectbyname(taskResult.SimdataI,observed);
    if isfield(taskResult,'SimdataP')
        predDataP = selectbyname(taskResult.SimdataP,observed);
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
    resTypes = {'Population Residuals', 'Individual Residuals'};
    
end

% Convert units if required.
observed = taskResult.TaskInfo.PKModelMap.Observed;
predDataI = selectbyname(taskResult.SimdataI,observed);
if ~isempty(predDataI(1).RunInfo.ConfigSet) && predDataI(1).RunInfo.ConfigSet.CompileOptions.UnitConversion
    xLabel        = cell(numResponse, 1);
    predDataInfo  = predDataI(1).DataInfo;
    obsDataInfo   = obsData(1).DataInfo;
    for i = 1:numResponse
        predDataUnits = predDataInfo{i}.Units;
        obsDataUnits  = obsDataInfo{i}.Units;
        if ~isempty(predDataUnits) && ~isempty(obsDataUnits) && ((strcmpi(taskResult.TaskInfo.AlgorithmName, 'NLINFIT') || ~isfield(taskResult.Results.stats, 'cwres')))
            xLabel{i} = ['Residuals (' obsDataUnits ')'];
            resI(:,i)   = sbiounitcalculator(predDataUnits, obsDataUnits, resI(:,i));
            if isfield(taskResult,'SimdataP')
                resP(:, i)   = sbiounitcalculator(predDataUnits, obsDataUnits, resP(:, i)); %#ok<AGROW>
            end
        else
            xLabel{i} = 'Residuals';
        end
    end
else
    xLabel = repmat({'Residuals'}, numResponse, 1);
end

xlimits = cell(numResponse,1);
ax      = cell(numResponse,1);
if ~strcmpi(taskResult.TaskInfo.AlgorithmName, 'NLINFIT')
    for i = 1:numResponse
        a(1) = axes;
        normplot(resP(:));
        
        a(2) = axes;
        createhistplot(resP(:));
        
        a(3) = axes;
        normplot(resI(:));
        
        a(4) = axes;
        createhistplot(resI(:));
        
        xlimits{i} = [ceil(max(abs(resP))), ceil(max((resI)))];
        ax{i} = a;
    end
    sbiogate('privateLayoutResidualDistributionPlot', ax, observed, resTypes, xlimits);
else
    % Plot each response in its own subplot.
    for resno = 1:numResponse
        % Create Plot.
        a = subplot(numResponse, 1, resno);
        normplot(resI(:,resno));
        
        % Add annotation.
        title(['Individual Residuals (Response' num2str(resno) ': '  observed{resno} ')'], 'Interpreter', 'none');
        xlabel(xLabel{resno});
        grid(a, 'off');
        set(a, 'YTickLabel', '');
        set(a, 'YTick', []);
        ylabel(a,'');
        set(a, 'ButtonDownFcn', @openNlinfitInNewWindow);
    end
end

function createhistplot(pwres)
[x, n] = hist(pwres);
d = n(2)- n(1);
x = x/sum(x*d);
bar(n,x);
ylim([0 max(x)*1.05]);
hold on;
x2 = -4:0.1:4;
f2 = normpdf(x2,0,1);
plot(x2,f2,'r');


function openNlinfitInNewWindow(src, ~)
f1  = figure;
a = copyobj(src, f1);
set(a, 'position', get(0,'DefaultaxesPosition'))
set(a, 'ButtonDownFcn', '');
