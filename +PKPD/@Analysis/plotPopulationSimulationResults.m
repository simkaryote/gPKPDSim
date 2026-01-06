function plotPopulationSimulationResults(this)
    arguments
        this
    end

    fig = figure;

    layout = string(this.SelectedPlotLayout);
    layout = str2double(split(layout, "x"));
    rows = layout(1);
    cols = layout(2);

    tiledlayout(fig, rows, cols);

    % Process the PlotSpeciesTable to see what needs plotting
    plotContents = this.PlotSpeciesTable(:,1:2);
    
    notEmpty_TF = cellfun(@(x)~isempty(x), plotContents(:,1));
    plotContents = plotContents(notEmpty_TF, :);
    plotNumbers = cellfun(@(x)str2double(x), plotContents(:,1));

    simRunToExportTF = [this.PopProfileNotes.Export];

    simDataToPlot = this.PopSummaryData(simRunToExportTF,:);

    simProfileNotesToPlot = this.PopProfileNotes(simRunToExportTF);

    for i = 1:rows*cols        
        ax = nexttile;
        statesToPlotIdx = find(i == plotNumbers);
        for j = 1:numel(statesToPlotIdx)
            name = plotContents{statesToPlotIdx(j),2};
            for k = 1:size(simDataToPlot,1)
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
                if numel(this.SimulationPlotSettings) < statesToPlotIdx(j)
                    yScale = 'linear';
                else
                    yScale = this.SimulationPlotSettings(statesToPlotIdx(j)).YScale;
                end
                set(ax, 'YScale', yScale);
            end
        end
        if isscalar(statesToPlotIdx)
            ylabel(name, 'Interpreter', 'none');
        end
        xlabel('Time');
    end
end
