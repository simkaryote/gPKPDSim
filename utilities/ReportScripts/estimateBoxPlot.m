function estimateBoxPlot(taskresult)
%ESTIMATEBOXPLOT Creates a Box Plot for the estimated parameters.
%
%    ESTIMATEBOXPLOT(TASKRESULT) creates a box plot for the random effects
%    if the algorithm is NLMEFIT or NLMEFITSA and estimated parameters if 
%    the algorithm is NLINFIT. 
%
%    TASKRESULT is a structure containing a field for each output argument
%    from the task. The field SimdataI is the SimData Object obtained by
%    simulating the model using individual parameters. SimdataP is obtained
%    by using the population parameters for simulation.

% Error Checking.
if ~isfield(taskresult, 'TaskInfo')
    error('SimBiology:INVALID_PLOT_TYPE','This plot is supported only for Parameter Fit tasks.');
end

% Get the parameter estimates and parameter names.
if strcmp(taskresult.TaskInfo.AlgorithmName,'NLINFIT')
    labelY    = 'Estimated Values (beta)';
    plotTitle = 'Individual Estimates Box Plot';
    
    % Get the names for estimated parameters.
    names = taskresult.TaskInfo.PKModelMap.Estimated;
    
    beta = zeros(length(taskresult.Results), length(names));
    for i = 1:length(taskresult.Results)
        beta(i,:) = taskresult.Results(i).ParameterEstimates.Estimate(:);
    end
else
    % Random effects n x P.
    beta = double(taskresult.Results.RandomEffects);
    labelY    = 'Random Effects (b)';
    plotTitle = 'Random Effects Box Plot';
    
    % Get the names for random effects.
    names = taskresult.TaskInfo.PKModelMap.Estimated(taskresult.TaskInfo.RandomEffects);
end

% Create the labels.
transform   = taskresult.TaskInfo.ParamTransform;
transformFn = {'', 'log', 'probit', 'logit'};
for i = 1:length(names)
    if transform(i) ~= 0
        names{i} = [transformFn{transform(i)+1} '(' names{i} ')'];
    end
end

% Create Plot.
boxplot(beta,names);

% Label Plot.
ylabel(labelY);
title(plotTitle);
