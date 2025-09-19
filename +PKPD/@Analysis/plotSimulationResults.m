function plotSimulationResults(this)
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

    simRunToExportTF = [this.SimProfileNotes.Export];
    simDataToPlot = this.SimData(simRunToExportTF);
    simProfileNotesToPlot = this.SimProfileNotes(simRunToExportTF);

    for i = 1:rows*cols        
        ax = nexttile;
        statesToPlotIdx = find(i == plotNumbers);
        for j = 1:numel(statesToPlotIdx)
            name = plotContents{statesToPlotIdx(j),2};
            for k = 1:numel(simDataToPlot)
                sd = simDataToPlot(k).selectbyname(name);
                yScale = this.SimulationPlotSettings(statesToPlotIdx(j)).YScale;
                plot(sd.Time, sd.Data, 'Color', simProfileNotesToPlot(k).Color);
                set(ax, 'YScale', yScale);
                hold on
            end
        end
        if isscalar(statesToPlotIdx)
            ylabel(name);
        end
        xlabel('Time');
    end
end

