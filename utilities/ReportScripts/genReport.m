function genReport

    TmpFilePath = fullfile(tempdir,'TmpTaskResults.mat');
    ThisData = load(TmpFilePath,'TaskResult');
    TaskResult = ThisData.TaskResult;

    % Plot the results.
    hFigure = figure;
    plottype_Fit_Summary(TaskResult);
    pause(0.5) % Add pause in order to capture and prevent black box
    snapnow
    close(hFigure);

    hFigure = figure;
    plottype_Fit(TaskResult, 'individual', 'trellis', '');
    snapnow
    close(hFigure);

    hFigure = figure;
    plottype_Observation_versus_Prediction(TaskResult);
    snapnow
    close(hFigure);

    hFigure = figure;
    plottype_Box_Plot(TaskResult);
    snapnow
    close(hFigure);

    hFigure = figure;
    plottype_Residuals(TaskResult, 'time');
    snapnow
    close(hFigure);

    hFigure = figure;
    plottype_Residual_Distribution(TaskResult);
    snapnow
    close(hFigure)


    % % Code from Kapil
    % figure('Tag', 'fittingToolPlot1');
    % fitsummary(TaskResult)
    % figure('Tag', 'fittingToolPlot2');
    % fitplot(TaskResult.SimdataI, TaskResult.DataToFit)
    % figure('Tag', 'fittingToolPlot3');
    % obsVersusPred(TaskResult)
    % %figure('Tag', 'fittingToolPlot4');
    % %estimateBoxPlot(TaskResult)
    % figure('Tag', 'fittingToolPlot5');
    % residuals(TaskResult, 'time')
    % figure('Tag', 'fittingToolPlot6');
    % residualDistribution(TaskResult)
end

    % ---------------------------------------------------------
function restore(modelobj, originalConfigset)

    % Restore active configset.
    setactiveconfigset(modelobj, originalConfigset);
end

    % ----------------------------------------------------------
function plottype_Fit_Summary(taskresult)
    %FITSUMMARY Show summary of fit results.
    %
    %    FITSUMMARY(TASKRESULT) creates a summary of fit results.
    %
    %    TASKRESULT is a structure containing a field for each out argument
    %    from the task.
    %

    % Error Checking.
    if ~isfield(taskresult, 'TaskInfo')
        error(message('SimBiology:plottypes:INVALID_PLOT_TYPE'));
    end
    infoPanel         = javaObjectEDT('com.mathworks.toolbox.simbio.desktop.analysis.populationfit.html.FitResultsSummaryHTMLPage');
    [comp, container] = javacomponent(infoPanel);

    % Set the resize function.
    set(gcf, 'ResizeFcn', {@resizeFunction, container})

    % Generate the html. Call private function to construct data.
    comp.setData(sbiogate('getPKInfoPlotTaskResults', taskresult));

    % Position infoPanel.
    drawnow;
    resizeFunction(gcf, [], container);
end

    %--------------------------------------------------------------------------
function resizeFunction(src, eventdata, container) %#ok<INUSL>

    figPos = get(src,'Position');
    set(container, 'position', [0, 0, figPos(3), figPos(4)]);
end

    % ----------------------------------------------------------
function plottype_Fit(taskresult, fitType, plotStyle, axesStyle)
    %FITPLOT Plots observed and predicted values versus time.
    %
    %    FITPLOT(TASKRESULT, FITTYPE, PLOTSTYLE, PROP) Plots the predicted
    %    results for individual or population fit and observation versus time.
    %
    %    FITTYPE defines if the plot created uses population fit or individual
    %    fit. If taskresult.TaskInfo.AlgorithmName is NLMEFIT or NLMEFITSA,
    %    FITTYPE can be 'individual' or 'population'. If it is NLINFIT,
    %    FITTYPE can only be 'individual'.
    %
    %    If PLOTSTYLE is 'one axes' then data from each run is plotted into one
    %    axes. If PLOTSTYLE is 'trellis' then data from each run is plotted
    %    into its own subplot.
    %
    %    AXESSTYLE is a structure that contains axes property value pairs.
    %
    %    See also GETDATA, SELECTBYNAME, SBIOPLOT, SBIOSUBPLOT.

    % Error checking.
    if ~isfield(taskresult, 'Results')
        error(message('SimBiology:plottypes:INVALID_PLOT_TYPE'));
    end

    results = taskresult.Results;
    if isa(results, 'NLMEResults') || isa(results, 'NLINResults')
        % Backwards compatible method.
        plot(results, taskresult, fitType, plotStyle, axesStyle);
    else
        plot(results, 'ParameterType', fitType, 'PlotStyle', plotStyle, 'AxesStyle', axesStyle);
    end
end

    % ----------------------------------------------------------
function plottype_Observation_versus_Prediction(taskresult)
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
    if ~isfield(taskresult, 'Results')
        error(message('SimBiology:plottypes:INVALID_PLOT_TYPE'));
    end

    results = taskresult.Results;
    if isa(results, 'NLMEResults') || isa(results, 'NLINResults')
        % Backwards compatible method.
        plotActualVersusPredicted(results, taskresult);
    else
        plotActualVersusPredicted(results);
    end
end

    % ----------------------------------------------------------
function plottype_Box_Plot(taskresult)
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
    if ~isfield(taskresult, 'Results')
        error(message('SimBiology:plottypes:INVALID_PLOT_TYPE'));
    end

    results = taskresult.Results;
    if isa(results, 'NLMEResults') || isa(results, 'NLINResults')
        % Backwards compatible method.
        boxplot(results, taskresult);
    else
        boxplot(results);
    end
end

    % ----------------------------------------------------------
function plottype_Residuals(taskresult, xaxis)
    %RESIDUALS Plots residuals.
    %
    %    RESIDUALS(taskresult, XAXIS) plots residuals versus
    %    time, group or predicted value.
    %
    %    taskresult is a structure containing a field for each output argument
    %    from the task. The field SimdataI is the SimData Object obtained by
    %    simulating the model using individual parameters. SimdataP is obtained
    %    by using the population parameters for simulation.
    %
    %    XAXIS defines what is plotted on x-axis of the plot. Accepted values
    %    are 'time', 'group' or 'predictions'.
    %

    % Error Checking.
    if ~isfield(taskresult, 'TaskInfo')
        error(message('SimBiology:plottypes:INVALID_PLOT_TYPE'));
    end

    results = taskresult.Results;
    if isa(results, 'NLMEResults') || isa(results, 'NLINResults')
        % Backwards compatible method.
        plotResiduals(results, taskresult, xaxis);
    else
        plotResiduals(results, xaxis);
    end
end

    % ----------------------------------------------------------
function plottype_Residual_Distribution(taskresult)
    %RESIDUALDISTRIBUTION Creates a normplot of the residuals.
    %
    %    RESIDUALDISTRIBUTION(taskresult) creates a normal
    %    probability plot of residuals.
    %
    %    taskresult is a structure containing a field for each output argument
    %    from the task. The field SimdataI is the SimData Object obtained by
    %    simulating the model using individual parameters. SimdataP is obtained
    %    by using the population parameters for simulation.
    %
    %    See also NORMPLOT.

    % Error Checking.
    if ~isfield(taskresult, 'TaskInfo')
        error(message('SimBiology:plottypes:INVALID_PLOT_TYPE'));
    end

    results = taskresult.Results;
    if isa(results, 'NLMEResults') || isa(results, 'NLINResults')
        % Backwards compatible method.
        plotResidualDistribution(results, taskresult);
    else
        plotResidualDistribution(results);
    end
end
