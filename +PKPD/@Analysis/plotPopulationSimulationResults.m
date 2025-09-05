function plotPopulationSimulationResults(this)
    arguments
        this
    end

    fig = figure;

    layout = string(this.SelectedPlotLayout);
    layout = str2double(split(layout, "x"));
    rows = layout(1);
    cols = layout(2);

    tiledlayoutObj = tiledlayout(fig, rows, cols);

    % Process the PlotSpeciesTable to see what needs plotting
    plotContents = this.PlotSpeciesTable(:,1:2);
    
    notEmpty_TF = cellfun(@(x)~isempty(x), plotContents(:,1));
    plotContents = plotContents(notEmpty_TF, :);
    plotNumbers = cellfun(@(x)str2double(x), plotContents(:,1));

    % simRunToExportTF = [this.SimProfileNotes.Export];
    simRunToExportTF = [this.PopProfileNotes.Export];

    % simDataToPlot = this.SimData(simRunToExportTF);
    simDataToPlot = this.PopSummaryData(simRunToExportTF,:);

    %simProfileNotesToPlot = this.SimProfileNotes(simRunToExportTF);
    simProfileNotesToPlot = this.PopProfileNotes(simRunToExportTF);

    for i = 1:rows*cols        
        nexttile
        statesToPlotIdx = find(i == plotNumbers);
        for j = 1:numel(statesToPlotIdx)
            name = plotContents{statesToPlotIdx(j),2};
            for k = 1:size(simDataToPlot,1)
                %sd = simDataToPlot(k).selectbyname(name);
                whichOne = name == string({this.PopSummaryData(k,:).Name});
                theOne = simDataToPlot(k, whichOne);

                Prctile5 = theOne.P5;
                Prctile50 = theOne.P50;
                Prctile95 = theOne.P95;
                Time =  theOne.Time;
                ThisTime = [Time; Time(end:-1:1)];
                ThisData = [Prctile5; Prctile95(end:-1:1)];

                patch(...
                        ThisTime,...
                        ThisData,...
                        simProfileNotesToPlot(k).Color,...
                        'EdgeColor','none',...
                        'FaceAlpha', .1);
                hold on

                plot(Time, Prctile50, 'Color', simProfileNotesToPlot(k).Color);

                hold on
            end
        end
        if isscalar(statesToPlotIdx)
            ylabel(name);
        end
        xlabel('Time');
    end
end


% 
% 
% Prctile5 = obj.PopSummaryData(index,MatchIndex).P5;
% Prctile50 = obj.PopSummaryData(index,MatchIndex).P50;
% Prctile95 = obj.PopSummaryData(index,MatchIndex).P95;
% Time =  obj.PopSummaryData(index,MatchIndex).Time;
% 
% % Patch
% ThisTime = [Time; Time(end:-1:1)];
% ThisData = [Prctile5; Prctile95(end:-1:1)];
% 
% 
%                     if ~isempty(ThisData)
%                     hSpeciesSummaryPatch{index,axIndex} = [hSpeciesSummaryPatch{index,axIndex} patch(...
%                         ThisTime,...
%                         ThisData,...
%                         obj.PopProfileNotes(index).Color,...
%                         'Parent',hAxes(axIndex),...
%                         'Tag',obj.PlotSpeciesTable{sIndex,2},...
%                         'DisplayName',regexprep(obj.PlotSpeciesTable{sIndex,3},'_','\\_'),... % Initially
%                         'EdgeColor','none',...
%                         'FaceAlpha',PatchFaceAlpha,...
%                         'LineStyle',obj.SpeciesLineStyles{sIndex},...
%                         'LineWidth',PatchLineWidth)];
%                     % Turn off legend entry for last
%                     set(get(get(hSpeciesSummaryPatch{index,axIndex}(end),'Annotation'),'LegendInformation'),'IconDisplayStyle','off')
% 
%                     % Plot 50%
%                     hSpeciesSummaryLine{index,axIndex} = [hSpeciesSummaryLine{index,axIndex} line(Time,Prctile50,...
%                         'Parent',hAxes(axIndex),...
%                         'Tag',obj.PlotSpeciesTable{sIndex,2},...
%                         'DisplayName',regexprep(obj.PlotSpeciesTable{sIndex,3},'_','\\_'),... % Initially
%                         'LineStyle',obj.SpeciesLineStyles{sIndex},...
%                         'LineWidth',Prctile50LineWidth,... % Thicker than 5% and 95%
%                         'UserData',obj.PopProfileNotes(index),...
%                         'Color',obj.PopProfileNotes(index).Color)];
%                     % Plot 5%
%                     hSpeciesSummaryLine{index,axIndex} = [hSpeciesSummaryLine{index,axIndex} line(Time,Prctile5,...
%                         'Parent',hAxes(axIndex),...
%                         'Tag',obj.PlotSpeciesTable{sIndex,2},...
%                         'DisplayName',regexprep(obj.PlotSpeciesTable{sIndex,3},'_','\\_'),... % Initially
%                         'LineStyle',obj.SpeciesLineStyles{sIndex},...
%                         'LineWidth',Prctile5LineWidth,...
%                         'UserData',obj.PopProfileNotes(index),...
%                         'Color',obj.PopProfileNotes(index).Color)];
%                     % Plot 95%
%                     hSpeciesSummaryLine{index,axIndex} = [hSpeciesSummaryLine{index,axIndex} line(Time,Prctile95,...
%                         'Parent',hAxes(axIndex),...
%                         'Tag',obj.PlotSpeciesTable{sIndex,2},...
%                         'DisplayName',regexprep(obj.PlotSpeciesTable{sIndex,3},'_','\\_'),... % Initially
%                         'LineStyle',obj.SpeciesLineStyles{sIndex},...
%                         'LineWidth',Prctile95LineWidth,...
%                         'UserData',obj.PopProfileNotes(index),...
%                         'Color',obj.PopProfileNotes(index).Color)];
%                     % Turn off legend entry for last two (keep for 50%)
%                     set(get(get(hSpeciesSummaryLine{index,axIndex}(end-1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off')
%                     set(get(get(hSpeciesSummaryLine{index,axIndex}(end),'Annotation'),'LegendInformation'),'IconDisplayStyle','off')
% 
% 
% end