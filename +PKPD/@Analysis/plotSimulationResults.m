function plotSimulationResults(this, type)
    arguments
        this
        type (1,1) string
    end

    try
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

        if ~isempty(this.PlotDatasetTable)
            dataPlotNumbers = cellfun(@(x)str2double(x), this.PlotDatasetTable(:,1));
        else
            dataPlotNumbers = [];
        end

        % Type specific
        switch type
            case "simulation"
                simRunToExportTF = [this.SimProfileNotes.Export];
                simDataToPlot = this.SimData(simRunToExportTF);
                nSimDataToPlot = numel(simDataToPlot);
                simProfileNotesToPlot = this.SimProfileNotes(simRunToExportTF);
                plotDataFcn = @(idx, name) plotSimData(simDataToPlot, simProfileNotesToPlot, idx, name);
            case "population"
                simRunToExportTF = [this.PopProfileNotes.Export];
                simDataToPlot = this.PopSummaryData(simRunToExportTF,:);
                nSimDataToPlot = size(simDataToPlot,1);
                simProfileNotesToPlot = this.PopProfileNotes(simRunToExportTF);
                plotDataFcn = @(idx, name) plotPopData(simDataToPlot, simProfileNotesToPlot, idx, name);
            case "datafitting"
                simDataToPlot = this.FitTaskResults.SimdataI;
                nSimDataToPlot = size(simDataToPlot, 1);
                dataFitProfileNotesToPlot = [];
                plotDataFcn = @(idx, name) plotDataFitting(simDataToPlot, dataFitProfileNotesToPlot, idx, name);
            otherwise
                error('Invalid plot type specified. Please use "simulation" or "population".');
        end

        for i = 1:rows*cols
            ax = nexttile;
            statesToPlotIdx = find(i == plotNumbers);
            for j = 1:numel(statesToPlotIdx)
                name = plotContents{statesToPlotIdx(j),2};
                for k = 1:nSimDataToPlot
                    plotDataFcn(k, name);

                    % A bit of defensive code. SimulationPlotSettings may not
                    % be the correct size if the YScale has not been set
                    % before. The old version made an array of 6
                    % SimulationPlotSettings and presumed to not need more.
                    if numel(this.SimulationPlotSettings) < statesToPlotIdx(j)
                        yScale = 'linear';
                    else
                        yScale = this.SimulationPlotSettings(statesToPlotIdx(j)).YScale;
                    end

                    % TODO: defensive code to avoid an empty YScale. This
                    % happens when plots are made but not used.
                    if isempty(yScale)
                        yScale = 'linear';
                    end

                    set(ax, 'YScale', yScale);
                end
            end

            % Plot data.
            dataToPlotIdx = find(i == dataPlotNumbers);
            for j = 1:numel(dataToPlotIdx)
                dataName = this.PlotDatasetTable{dataToPlotIdx(j),2};
                % we only have one dataset at the moment
                independentVarName = this.DatasetTable.Time;
                plot(this.DataToFit.(independentVarName), this.DataToFit.(dataName), 'x');
            end

            if isscalar(statesToPlotIdx)
                ylabel(name, 'Interpreter', 'none');
            end
            xlabel('Time', 'Interpreter', 'none');
        end
    catch e
        disp(getReport(e, 'extended'));
    end
end

function plotSimData(simData, simProfileNotes, idx, name)
    sd = simData(idx).selectbyname(name);
    plot(sd.Time, sd.Data, 'Color', simProfileNotes(idx).Color);
    hold on;
end

function plotPopData(simData, simProfileNotes, idx, name)
    whichOne = name == string({simData(idx,:).Name});
    theOne = simData(idx, whichOne);

    Prctile5 = theOne.P5;
    Prctile50 = theOne.P50;
    Prctile95 = theOne.P95;
    Time =  theOne.Time;
    ThisTime = [Time; Time(end:-1:1)];
    ThisData = [Prctile5; Prctile95(end:-1:1)];

    patch(...
        ThisTime,...
        ThisData,...
        simProfileNotes(idx).Color,...
        'EdgeColor','none',...
        'FaceAlpha', .1);

    hold on;

    plot(Time, Prctile50, 'Color', simProfileNotes(idx).Color);
end

function plotDataFitting(simData, profileNotes, idx, name)
    sd = simData(idx).selectbyname(name);
    plot(sd.Time, sd.Data);
    hold on;
end