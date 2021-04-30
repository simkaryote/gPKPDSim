function [hSpeciesSummaryLine,hSpeciesSummaryPatch,hDatasetLine,hLegend,hLegendChildren] = plotPopulation(obj,hAxes,SelectedProfileRow,Settings)
% plotPopulation - plots the population
% -------------------------------------------------------------------------
% Abstract: This plots the population analysis based on the settings.
%
% Syntax:
%           [hSpeciesSummaryLine,hSpeciesSummaryPatch,hDatasetLine,hLegend,hLegendChildren] = plotPopulation(obj,hAxes,SelectedProfileRow,Settings)
%
% Inputs:
%           obj - PKPD.Analysis object
%
%           hAxes - Axes handle
%
%           SelectedProfileRow - Selected population run index
%
%           Settings - Settings for plotting
%
% Outputs:
%
%           hSpeciesSummaryLine - Species line handles for 50%, 5% and 95%
%
%           hSpeciesSummaryPatch - Species patch handles for 50%, 5% and
%           95%
%
%           hDatasetLine - Line handles
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


%% Turn on hold

for index = 1:numel(hAxes)
    XLimMode{index} = get(hAxes(index),'XLimMode'); %#ok<AGROW>
    YLimMode{index} = get(hAxes(index),'YLimMode'); %#ok<AGROW>
    cla(hAxes(index));
    legend(hAxes(index),'off')
    set(hAxes(index),'XLimMode',XLimMode{index},'YLimMode',YLimMode{index})
    hold(hAxes(index),'on')    
end


%% Define markers

% Get unique groups
if ~isempty(obj.DataToFit)
    GroupLabelFixed = matlab.lang.makeValidName(obj.DatasetTable.Group);
    UniqueGroups = unique(obj.DataToFit.(GroupLabelFixed),'stable');
else
    UniqueGroups = [];
end

% Define symbols
ValidLineMarkers = CustomLineMarkers(size(obj.PlotDatasetTable,1));

NumAxes = numel(hAxes);


%% Plot species

NumProfiles = numel(obj.PopProfileNotes);

hSpeciesSummaryLine = cell(NumProfiles,NumAxes);
hSpeciesSummaryPatch = cell(NumProfiles,NumAxes);
hSpeciesSummaryLineFORLEGEND = cell(NumProfiles,NumAxes);

if ~isempty(obj.ModelObj) && ~isempty(obj.PopSummaryData) && ~isempty(obj.PlotSpeciesTable)

    NumRuns = size(obj.PopSummaryData,1);
    
    Show = [obj.PopProfileNotes.Show];
    
    for sIndex = 1:size(obj.PlotSpeciesTable,1)
        
        % Get axes index
        axIndex = str2double(obj.PlotSpeciesTable{sIndex,1});        
        if ~isempty(axIndex) && ~isnan(axIndex)
            
            % Make active axes (for patch objects)
            if ~isempty(ancestor(hAxes(axIndex),'Figure'))
                axes(hAxes(axIndex)); %#ok<LAXES>
            end
           
            % Concatenate all data to plot in gray
%             AllPopTime = [];
%             AllPopData = [];
            if ~isempty(obj.PopSummaryData)
                DataNames = {obj.PopSummaryData(1,:).Name};
            else
                DataNames = {};
            end
            
            % Get species name index
            MatchIndex = find(strcmpi(DataNames,obj.PlotSpeciesTable{sIndex,2}));
            
            % Iterate through each population run to plot 5-50-95%
            for index = 1:NumRuns
                
                % Skip if needed
                if ~Show(index)
                    continue;
                end

                if ~isempty(obj.PopSummaryData) && ~isempty(SelectedProfileRow) && (index == SelectedProfileRow)                
                    % Plot with normal lines
                    PatchLineWidth = 1;
                    PatchFaceAlpha = 0.5;
                    Prctile50LineWidth = Settings(axIndex).HighlightLineWidth;
                    Prctile5LineWidth = Settings(axIndex).LineWidth;
                    Prctile95LineWidth = Settings(axIndex).LineWidth;
                else
                    PatchLineWidth = 0.5;
                    PatchFaceAlpha = 0.05;
                    Prctile50LineWidth = min(Settings(axIndex).LineWidth*1.25,10);
                    Prctile5LineWidth = Settings(axIndex).LineWidth;
                    Prctile95LineWidth = Settings(axIndex).LineWidth;
                end
                
                % Compute
%                 Prctile5 = prctile(ThisSim,5,2);
%                 Prctile50 = prctile(ThisSim,50,2);
%                 Prctile95 = prctile(ThisSim,95,2);
%                 Time = ThisSpeciesData(1).Time;
                Prctile5 = obj.PopSummaryData(index,MatchIndex).P5;
                Prctile50 = obj.PopSummaryData(index,MatchIndex).P50;
                Prctile95 = obj.PopSummaryData(index,MatchIndex).P95;
                Time =  obj.PopSummaryData(index,MatchIndex).Time;
                
                % Patch
                ThisTime = [Time; Time(end:-1:1)];
                ThisData = [Prctile5; Prctile95(end:-1:1)];
                % Prune out <= 0 values so that log-Y shows up correctly
                InvalidIdx = (ThisData <= 0);
                ThisTime(InvalidIdx) = [];
                ThisData(InvalidIdx) = [];
                
                if ~isempty(ThisData)
                    hSpeciesSummaryPatch{index,axIndex} = [hSpeciesSummaryPatch{index,axIndex} patch(...
                        ThisTime,...
                        ThisData,...
                        obj.PopProfileNotes(index).Color,...
                        'Parent',hAxes(axIndex),...
                        'Tag',obj.PlotSpeciesTable{sIndex,2},...
                        'DisplayName',regexprep(obj.PlotSpeciesTable{sIndex,3},'_','\\_'),... % Initially
                        'EdgeColor','none',...
                        'FaceAlpha',PatchFaceAlpha,...
                        'LineStyle',obj.SpeciesLineStyles{sIndex},...
                        'LineWidth',PatchLineWidth)];
                    % Turn off legend entry for last
                    set(get(get(hSpeciesSummaryPatch{index,axIndex}(end),'Annotation'),'LegendInformation'),'IconDisplayStyle','off')
                    
                    % Plot 50%
                    hSpeciesSummaryLine{index,axIndex} = [hSpeciesSummaryLine{index,axIndex} line(Time,Prctile50,...
                        'Parent',hAxes(axIndex),...
                        'Tag',obj.PlotSpeciesTable{sIndex,2},...
                        'DisplayName',regexprep(obj.PlotSpeciesTable{sIndex,3},'_','\\_'),... % Initially
                        'LineStyle',obj.SpeciesLineStyles{sIndex},...
                        'LineWidth',Prctile50LineWidth,... % Thicker than 5% and 95%
                        'UserData',obj.PopProfileNotes(index),...
                        'Color',obj.PopProfileNotes(index).Color)];
                    % Plot 5%
                    hSpeciesSummaryLine{index,axIndex} = [hSpeciesSummaryLine{index,axIndex} line(Time,Prctile5,...
                        'Parent',hAxes(axIndex),...
                        'Tag',obj.PlotSpeciesTable{sIndex,2},...
                        'DisplayName',regexprep(obj.PlotSpeciesTable{sIndex,3},'_','\\_'),... % Initially
                        'LineStyle',obj.SpeciesLineStyles{sIndex},...
                        'LineWidth',Prctile5LineWidth,...
                        'UserData',obj.PopProfileNotes(index),...
                        'Color',obj.PopProfileNotes(index).Color)];
                    % Plot 95%
                    hSpeciesSummaryLine{index,axIndex} = [hSpeciesSummaryLine{index,axIndex} line(Time,Prctile95,...
                        'Parent',hAxes(axIndex),...
                        'Tag',obj.PlotSpeciesTable{sIndex,2},...
                        'DisplayName',regexprep(obj.PlotSpeciesTable{sIndex,3},'_','\\_'),... % Initially
                        'LineStyle',obj.SpeciesLineStyles{sIndex},...
                        'LineWidth',Prctile95LineWidth,...
                        'UserData',obj.PopProfileNotes(index),...
                        'Color',obj.PopProfileNotes(index).Color)];
                    % Turn off legend entry for last two (keep for 50%)
                    set(get(get(hSpeciesSummaryLine{index,axIndex}(end-1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off')
                    set(get(get(hSpeciesSummaryLine{index,axIndex}(end),'Annotation'),'LegendInformation'),'IconDisplayStyle','off')
                    
                    % Temporary line for
                    hSpeciesSummaryLineFORLEGEND{index,axIndex} = [hSpeciesSummaryLineFORLEGEND{index,axIndex} line(nan,nan,...
                        'Parent',hAxes(axIndex),...
                        'Tag','ForUILegendOnly',...
                        'DisplayName',regexprep(obj.PlotSpeciesTable{sIndex,3},'_','\\_'),... % Initially
                        'LineStyle',obj.SpeciesLineStyles{sIndex},...
                        'Color',[0 0 0])];
                end %if ~isempty(ThisData)
                
            end %for index - 1:NumRuns
        end %if ~isempty(axIndex) && ~isnan(axIndex)
    end %for sIndex = 1:size(obj.PlotSpeciesTable,1)    
end


%% Plot dataset

hDatasetLine = cell(1,NumAxes);
if ~isempty(obj.ModelObj) && ~isempty(obj.DataToFit) && ~isempty(obj.DatasetTable)
    % Fix names
    TimeLabelFixed = matlab.lang.makeValidName(obj.DatasetTable.Time);
    GroupLabelFixed = matlab.lang.makeValidName(obj.DatasetTable.Group);
    
    LastPopTime = obj.DataToFit.(TimeLabelFixed);
    Group = obj.DataToFit.(GroupLabelFixed);    
    
    for sIndex = 1:size(obj.PlotDatasetTable,1)
        
        % Get axes index
        axIndex = str2double(obj.PlotDatasetTable{sIndex,1});
        
        if ~isempty(axIndex) && ~isnan(axIndex)
            
            % Get data
            ThisLabelFixed = matlab.lang.makeValidName(obj.PlotDatasetTable{sIndex,2});
            ThisSpeciesData = obj.DataToFit.(ThisLabelFixed);
            
            % Plot in group
            for gIndex = 1:numel(UniqueGroups)
                % Only if selected
                if obj.SelectedGroups(gIndex)
                    hDatasetLine{axIndex} = [hDatasetLine{axIndex} line(LastPopTime(Group == UniqueGroups(gIndex)),ThisSpeciesData(Group == UniqueGroups(gIndex)),...
                        'Parent',hAxes(axIndex),...
                        'Marker',ValidLineMarkers{sIndex},...
                        'LineStyle','none',...
                        'MarkerSize',Settings(axIndex).DataSymbolSize,...
                        'DisplayName',regexprep(sprintf('%s %s',obj.PlotDatasetTable{sIndex,3},obj.PlotGroupNames{gIndex}),'_','\\_'),...
                        ...'DisplayName',regexprep(obj.PlotDatasetTable{sIndex,3},'_','\\_'),...
                        'Tag',obj.PlotDatasetTable{sIndex,2},...
                        'Color',obj.GroupColors(gIndex,:))];
                end
            end            
        end
    end
end


%% Legend

hLegend = cell(1,NumAxes);
hLegendChildren = cell(1,NumAxes);
for axIndex = 1:numel(hAxes)
    
    % Get any non-empty hSpeciesPatch for this axes across all runs
    ThisRunIdx = find(~cellfun(@isempty,hSpeciesSummaryLine(:,axIndex)),1);
    
    % Only take every 3 entries in species line
    if ~isempty(ThisRunIdx)
        % Use hSpeciesSummaryLineFORLEGEND instead of hSpeciesSummaryLine
        LegendItems = [hSpeciesSummaryLineFORLEGEND{ThisRunIdx,axIndex} hDatasetLine{axIndex}]; 
    else
        LegendItems = hDatasetLine{axIndex};
    end
    if ~isempty(LegendItems)
        % Add legend
        [hLegend{axIndex},hLegendChildren{axIndex}] = legend(hAxes(axIndex),LegendItems);
        set(hLegend{axIndex},...
            'EdgeColor','none',...
            'Visible',Settings(axIndex).LegendVisibility,...
            'Location',Settings(axIndex).LegendLocation,...
            'FontSize',Settings(axIndex).LegendFontSize,...
            'FontWeight',Settings(axIndex).LegendFontWeight);
    else
        hLegend{axIndex} = [];
        hLegendChildren{axIndex} = [];
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