function updateAxesLayout(app)
% updateAxesLayout - Updates all parts of the app display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the app display
%
% Syntax:
%           updateAxesLayout(app)
%
% Inputs:
%           app - The PKPDViewer.AnalysisApp object
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%

% Copyright 2017 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: agajjala $
%   $Revision: 399 $  $Date: 2017-07-10 17:14:00 -0400 (Mon, 10 Jul 2017) $
% ---------------------------------------------------------------------

hFigure = ancestor(app.h.PlotGrid,'Figure');

if strcmpi(app.Analysis.Task,'Simulation')
    % Simulation
    [app.h.MainAxesContainer(app.SimulationPlotIdx).Parent] = deal(app.h.PlotGrid);
    [app.h.MainAxesContainer(app.FittingPlotIdx).Parent] = deal(app.NoParent_);
    [app.h.MainAxesContainer(app.PopulationPlotIdx).Parent] = deal(app.NoParent_);
    [app.h.ContextMenu(app.SimulationPlotIdx).Parent] =  deal(hFigure);
    switch app.Analysis.SelectedPlotLayout
        case '1x1'
            app.h.PlotGrid.Heights = -1;
            app.h.PlotGrid.Widths = [-1 0 0 0 0 0];
            set(app.h.MainAxes(1),'Visible','on');
            set(app.h.MainAxes(2:6),'Visible','off');
        case '2x1'
            app.h.PlotGrid.Heights = [-1 -1];
            app.h.PlotGrid.Widths = [-1 0 0];
            set(app.h.MainAxes(1:2),'Visible','on');
            set(app.h.MainAxes(3:6),'Visible','off');
        case '2x2'
            app.h.PlotGrid.Heights = [-1 -1];
            app.h.PlotGrid.Widths = [-1 -1 0];
            set(app.h.MainAxes(1:4),'Visible','on');
            set(app.h.MainAxes(5:6),'Visible','off');
        case '3x2'
            app.h.PlotGrid.Heights = [-1 -1 -1];
            app.h.PlotGrid.Widths = [-1 -1];
            set(app.h.MainAxes(1:6),'Visible','on');            
    end
    
elseif strcmpi(app.Analysis.Task,'Fitting')
    % Fitting
    app.h.MainAxesContainer(7).Parent = app.h.PlotGrid;
    [app.h.MainAxesContainer([app.SimulationPlotIdx,app.PopulationPlotIdx]).Parent] = deal(app.NoParent_);
    app.h.ContextMenu(7).Parent = hFigure;
    app.h.PlotGrid.Heights = -1;
    app.h.PlotGrid.Widths = -1;
else
    % Population
    [app.h.MainAxesContainer(app.SimulationPlotIdx).Parent] = deal(app.NoParent_);
    [app.h.MainAxesContainer(app.FittingPlotIdx).Parent] = deal(app.NoParent_);
    [app.h.MainAxesContainer(app.PopulationPlotIdx).Parent] = deal(app.h.PlotGrid);
    [app.h.ContextMenu(app.PopulationPlotIdx).Parent] =  deal(hFigure);
    switch app.Analysis.SelectedPlotLayout
        case '1x1'
            app.h.PlotGrid.Heights = -1;
            app.h.PlotGrid.Widths = [-1 0 0 0 0 0];
            set(app.h.MainAxes(13),'Visible','on');
            set(app.h.MainAxes(14:end),'Visible','off');
        case '2x1'
            app.h.PlotGrid.Heights = [-1 -1];
            app.h.PlotGrid.Widths = [-1 0 0];
            set(app.h.MainAxes(13:14),'Visible','on');
            set(app.h.MainAxes(15:end),'Visible','off');
        case '2x2'
            app.h.PlotGrid.Heights = [-1 -1];
            app.h.PlotGrid.Widths = [-1 -1 0];
            set(app.h.MainAxes(13:16),'Visible','on');
            set(app.h.MainAxes(17:end),'Visible','off');
        case '3x2'
            app.h.PlotGrid.Heights = [-1 -1 -1];
            app.h.PlotGrid.Widths = [-1 -1];
            set(app.h.MainAxes(13:end),'Visible','on');            
    end
end