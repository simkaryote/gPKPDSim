function [hLine,hLegend,hLegendChildren] = plotFitting(obj,hAxes,Settings)
% plotFitting - plots the fitting
% -------------------------------------------------------------------------
% Abstract: This plots the fitting analysis based on the settings and data table.
%
% Syntax:
%           [hLine,hLegend,hLegendChildren] = plotFitting(obj,hAxes,Settings)
%
% Inputs:
%           obj - PKPD.Analysis object
%
%           hAxes - Axes handle
%
%           Settings - Settings for plotting
%
% Outputs:
%           hLine - Line handles
%
%           hLegend - Legend handles
%
%           hLegendChildren - Legend children handles
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
%   $Revision: 420 $  $Date: 2017-12-07 14:47:44 -0500 (Thu, 07 Dec 2017) $
% ---------------------------------------------------------------------

for index = 1:numel(hAxes)
    XLimMode{index} = get(hAxes(index),'XLimMode'); %#ok<AGROW>
    YLimMode{index} = get(hAxes(index),'YLimMode'); %#ok<AGROW>
	cla(hAxes(index));
    legend(hAxes(index),'off')
    set(hAxes(index),'XLimMode',XLimMode{index},'YLimMode',YLimMode{index})    
    hold(hAxes(index),'on')
end


NumAxes = numel(hAxes);
hLine = cell(1,NumAxes);
hLegend = cell(1,NumAxes);
hLegendChildren = cell(1,NumAxes);

if ~isempty(obj.ModelObj) && ~isempty(obj.FitSimData) && ~isempty(obj.DataToFit)
        
    LegendNames = {};
    
    % Define symbols
    ValidLineMarkers = CustomLineMarkers(size(obj.PlotDatasetTable,1));

    for index = 1:size(obj.ResponseMap)
        
        DependentVar = obj.ResponseMap{index,1};
        TargetSpecies = obj.ResponseMap{index,2};
        
        MarkerIndex = strcmpi(DependentVar,obj.PlotDatasetTable(:,2));
        ThisLineMarker = ValidLineMarkers{MarkerIndex};
        
        % Remove compartment name
        MatchIndex = regexp(TargetSpecies,'\.');
        if ~isempty(MatchIndex)
            MatchIndex = MatchIndex(end);
            if MatchIndex < length(TargetSpecies)
                TargetSpecies = TargetSpecies((MatchIndex+1):end);
            end
        end
        TargetSpecies = regexprep(TargetSpecies,'[','');
        TargetSpecies = regexprep(TargetSpecies,']','');
        
        % Plot data
        TimeLabelFixed = matlab.lang.makeValidName(obj.DatasetTable.Time);
        DependentVarLabelFixed = matlab.lang.makeValidName(DependentVar);
        GroupLabelFixed = matlab.lang.makeValidName(obj.DatasetTable.Group);
        
        Xdata = obj.DataToFit.(TimeLabelFixed);
        Ydata = obj.DataToFit.(DependentVarLabelFixed);

        % Get list of unique groups
        Group = obj.DataToFit.(GroupLabelFixed);
        UniqueGroups = unique(Group,'stable');
        
        % Plot in group
        for gIndex = 1:numel(UniqueGroups)            
            DisplayName = sprintf('OBS (%s) (Group %d)',DependentVar,UniqueGroups(gIndex));
            hLine{1} = [hLine{1} plot(hAxes(1),Xdata(Group == UniqueGroups(gIndex)),Ydata(Group == UniqueGroups(gIndex)),...
                'Marker',ThisLineMarker,...
                'MarkerSize',Settings(1).DataSymbolSize,...
                'LineStyle','none',...
                'Tag','observed',...
                'DisplayName',regexprep(DisplayName,'_','\\_'),...
                'Color',obj.GroupColors(gIndex,:))];
            LegendNames = [LegendNames,DisplayName]; %#ok<AGROW>            
        end
        
        for sIndex = 1:numel(obj.FitSimData)
            % Plot simulation results
            Xsim = obj.FitSimData(sIndex).Time;
            Ysim = obj.FitSimData(sIndex).Data(:,strcmpi(obj.FitSimData((sIndex)).DataNames,TargetSpecies));
            
            if ~isempty(Xsim) && ~isempty(Ysim)
                % Get color
                ThisColor = obj.GroupColors(sIndex,:);
                DisplayName = sprintf('PRED (%s) (Group %d)',TargetSpecies,UniqueGroups(sIndex));
                
                hLine{1} = [hLine{1} plot(hAxes(1),Xsim,Ysim,...
                    'LineStyle','-',...
                    'LineWidth',Settings(1).LineWidth,...
                    'Tag','predicted',...
                    'DisplayName',regexprep(DisplayName,'_','\\_'),...
                    'Color',ThisColor)];
                
                LegendNames = [LegendNames,DisplayName]; %#ok<AGROW>
            end
        end
    end

    if ~isempty(hLine{1})
        % Add legend        
        [hLegend{1},hLegendChildren{1}] = legend(hAxes(1),hLine{1});
        set(hLegend{1},...
            'EdgeColor','none',...
            'Visible',Settings(1).LegendVisibility,...
            'Location',Settings(1).LegendLocation,...
            'FontSize',Settings(1).LegendFontSize,...
            'FontWeight',Settings(1).LegendFontWeight); 
    else
        hLegend{1} = [];
        hLegendChildren{1} = [];  
    end
    
end


%% Turn off hold

for index = 1:numel(hAxes)
    hold(hAxes(index),'off')
    % Reset zoom state
    hFigure = ancestor(hAxes(index),'Figure');
    if ~isempty(hFigure) && strcmpi(XLimMode{index},'auto') && strcmpi(YLimMode{index},'auto')
        axes(hAxes(index)); %#ok<LAXES>
        zoom(hFigure,'out');
        zoom(hFigure,'reset');
    end
end