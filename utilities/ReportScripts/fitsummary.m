function fitsummary(taskresult)
%FITSUMMARY Show summary of fit results.
%
%    FITSUMMARY(TASKRESULT) creates a summary of fit results. 
%
%    TASKRESULT is a structure containing a field for each out argument
%    from the task. 
%

% Error Checking.
if ~isfield(taskresult, 'TaskInfo')
    error('SimBiology:INVALID_PLOT_TYPE','This plot is supported only for Parameter Fit tasks.');
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

%--------------------------------------------------------------------------
function resizeFunction(src, eventdata, container) %#ok<INUSL>

figPos = get(src,'Position');
set(container, 'position', [0, 0, figPos(3), figPos(4)]);