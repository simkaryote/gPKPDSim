function [hSpeciesLine,hDatasetLine,hLegend,hLegendChildren] = plotSimulation(obj,hAxes,SelectedProfileRow,Settings)
    % plotSimulation - plots the simulation
    % -------------------------------------------------------------------------
    % Abstract: This plots the simulation analysis based on the settings.
    %
    % Syntax:
    %           [hSpeciesLine,hDatasetLine,hLegend,hLegendChildren] = plotSimulation(obj,hAxes,SelectedProfileRow,Settings)
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
    %           hSpeciesLine - Species line handles
    %
    %           hDatasetLine - Dataset line handles
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


    %% Define colors and markers

    if ~isempty(obj.DataToFit)
        GroupLabelFixed = matlab.lang.makeValidName(obj.DatasetTable.Group);
        UniqueGroups = unique(obj.DataToFit.(GroupLabelFixed),'stable');
    else
        UniqueGroups = [];
    end

    % Define symbols
    ValidLineMarkers = CustomLineMarkers(size(obj.PlotDatasetTable,1));

    NumAxes = numel(hAxes);
    NumSimData = numel(obj.SimProfileNotes);


    %% Plot species

    hSpeciesLine = cell(NumSimData,NumAxes);
    hSpeciesLineFORLEGEND = cell(NumSimData,NumAxes);

    if ~isempty(obj.ModelObj) && ~isempty(obj.SimData)

        Show = [obj.SimProfileNotes.Show];

        for dIndex = 1:NumSimData
            % Skip if needed
            if ~Show(dIndex)
                continue;
            end

            Data = obj.SimData(dIndex).getdata;
            SpeciesData = Data.SpeciesData;

            for sIndex = 1:size(obj.PlotSpeciesTable,1)

                % Get axes index
                axIndex = str2double(obj.PlotSpeciesTable{sIndex,1});

                if ~isempty(axIndex) && ~isnan(axIndex)

                    % Make active axes (for patch objects)
                    if ~isempty(ancestor(hAxes(axIndex),'Figure'))
                        axes(hAxes(axIndex)); %#ok<LAXES>
                    end

                    % Get species name index
                    SelectedIdx = strcmpi(SpeciesData.Name,obj.PlotSpeciesTable{sIndex,2});

                    if ~isempty(SelectedProfileRow) && dIndex == SelectedProfileRow
                        % Set default and highlight linewidths
                        LineWidth = Settings(axIndex).HighlightLineWidth;
                    else
                        LineWidth = Settings(axIndex).LineWidth;
                    end

                    hSpeciesLine{dIndex,axIndex} = [hSpeciesLine{dIndex,axIndex} plot(Data.Time,SpeciesData.Data(:,SelectedIdx),...
                        'Parent',hAxes(axIndex),...
                        'LineWidth',LineWidth,...
                        'LineStyle',obj.SpeciesLineStyles{sIndex},...
                        'Tag',obj.PlotSpeciesTable{sIndex,2},...
                        'DisplayName',regexprep(obj.PlotSpeciesTable{sIndex,3},'_','\\_'),... % Initially
                        'UserData',obj.SimProfileNotes(dIndex),...
                        'Color',obj.SimProfileNotes(dIndex).Color)];
                    hSpeciesLineFORLEGEND{dIndex,axIndex} = [hSpeciesLineFORLEGEND{dIndex,axIndex} line(nan,nan,...
                        'Parent',hAxes(axIndex),...
                        'LineWidth',LineWidth,...
                        'LineStyle',obj.SpeciesLineStyles{sIndex},...
                        'Tag','ForUILegendOnly',...
                        'DisplayName',regexprep(obj.PlotSpeciesTable{sIndex,3},'_','\\_'),... % Initially
                        'Color',[0 0 0])];
                end
            end
        end
    end


    %% Plot dataset

    hDatasetLine = cell(1,NumAxes);
    if ~isempty(obj.ModelObj) && ~isempty(obj.DataToFit)
        % Fix names
        TimeLabelFixed = matlab.lang.makeValidName(obj.DatasetTable.Time);
        GroupLabelFixed = matlab.lang.makeValidName(obj.DatasetTable.Group);

        Time = obj.DataToFit.(TimeLabelFixed);
        Group = obj.DataToFit.(GroupLabelFixed);

        for sIndex = 1:size(obj.PlotDatasetTable,1)

            % Get axes index
            axIndex = str2double(obj.PlotDatasetTable{sIndex,1});

            if ~isempty(axIndex) && ~isnan(axIndex)

                % Get data
                ThisLabelFixed = matlab.lang.makeValidName(obj.PlotDatasetTable{sIndex,2});
                ThisData = obj.DataToFit.(ThisLabelFixed);

                % Plot in group
                for gIndex = 1:numel(UniqueGroups)
                    % Only if selected
                    if obj.SelectedGroups(gIndex)
                        hDatasetLine{axIndex} = [hDatasetLine{axIndex} line(Time(Group == UniqueGroups(gIndex)),ThisData(Group == UniqueGroups(gIndex)),...
                            'Parent',hAxes(axIndex),...
                            'Marker',ValidLineMarkers{sIndex},...
                            'LineStyle','none',...
                            'MarkerSize',Settings(axIndex).DataSymbolSize,...
                            'DisplayName',regexprep(sprintf('%s %s',obj.PlotDatasetTable{sIndex,3},obj.PlotGroupNames{gIndex}),'_','\\_'),...
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
    for axIndex = 1:NumAxes

        % Get any non-empty hSpeciesLine for this axes across all runs
        ThisRunIdx = find(~cellfun(@isempty,hSpeciesLine(:,axIndex)),1);

        if ~isempty(ThisRunIdx)
            % Use hSpeciesLineFORLEGEND instead of hSpeciesLine
            LegendItems = [hSpeciesLineFORLEGEND{ThisRunIdx,axIndex} hDatasetLine{axIndex}];
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

            % Color, FontSize, FontWeight
            for cIndex = 1:numel(hLegendChildren{axIndex})
                if isprop(hLegendChildren{axIndex}(cIndex),'FontSize')
                    hLegendChildren{axIndex}(cIndex).FontSize = Settings(axIndex).LegendFontSize;
                end
                if isprop(hLegendChildren{axIndex}(cIndex),'FontWeight')
                    hLegendChildren{axIndex}(cIndex).FontWeight = Settings(axIndex).LegendFontWeight;
                end
            end

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
end