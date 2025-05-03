classdef controller < handle
    properties(Constant)
        Version = 2.0
        RevisionDate = datetime("now");
        PreferencesName = "PKPDViewer_AnalysisApp";
    end

    properties
        app
        projectPath (1,1) string
        projectName (1,1) string
        session PKPD.Analysis = PKPD.Analysis.empty
    end

    methods
        function this = controller(app)
            arguments
                app = []
            end
            this.app = app;
        end

        % This is the distribution center for messages coming from the UI.
        function eventDistribution(this, eventName, e)
            arguments
                this
                eventName (1,1) string
                e
            end
            % All messages from the UI must start with the "update" prefix.
            % These eventNames are update functions in the controller so we
            % dispatch them directly here.
            assert(eventName.startsWith("update") || eventName.startsWith("menu"));

            try
                fprintf("Handling event: %s\n", eventName);
                this.(eventName)(e);
            catch p
                fprintf('Error calling the %s method. %s\n', eventName, p.message);
            end

        end

        % Send events to the UI. No other function sends events to the UI
        % other than this one.
        function notifyUI(this, eventName)
            arguments
                this
                eventName (1,1) string
            end

            if ~isempty(this.app)
                switch eventName
                    case "LoadProject"
                        trimmedSession = this.trimSession();
                        fprintf("Sending event " + eventName + " to app\n");
                        message = trimmedSession;
                    case "NewSimulation"
                        simulationResults = this.getSimulationResults();
                        message = simulationResults;
                    case "NewPopulation"
                        populationSimulationResults = this.getPopulationSimulationResults();
                        message = populationSimulationResults;
                    case "NewFitting"
                        message = this.getDataFittingResults();
                    case "RecentFiles"
                        message = getpref(this.PreferencesName, eventName);

                    otherwise
                        fprintf("Unhandled event: %s\n", eventName);
                end
                sendEventToHTMLSource(this.app.HTML, eventName, message);
            else
                fprintf("No app to send event " + eventName + "\n");
            end
        end

        % Generate a session in the form that is shared with the UI. Not
        % all data is necessary for the UI and some formats are changed to
        % make things easier to consume in the JS code.
        function sessionForUI = trimSession(this)
            warnState = warning('query', 'MATLAB:structOnObject');
            warning('off', 'MATLAB:structOnObject');
            % Fields that we are going to send as is.
            selectedFields = [...
                "ModelName", ...
                "SelectedPlotLayout", ...
                "Task", ...
                "MaxNumRuns", ...
                "FitErrorModel", ...
                "MaxNumRuns",...
                "UsePooledFitting",...
                ];

            for i = 1:numel(selectedFields)
                sessionForUI.(selectedFields(i)) = this.session.(selectedFields(i));
            end

            sessionForUI.ProjectName = this.projectName;

            % Transformations on data to simplify the communication.

            % Selected Variants.
            % Sort the names using the VariantOrder and supply
            % the UI the variants in order.
            if ~isempty(this.session.SelectedVariants)
                variants = this.session.SelectedVariants;
                sessionForUI.Variants = table([variants.Active]', string({variants.Name})', string({variants.Tag})', 'VariableNames', ["Active", "Name", "Tag"]);
                sessionForUI.Variants = sessionForUI.Variants(this.session.SelectedVariantsOrder,:);
            else
                sessionForUI.Variants = table.empty;
            end

            % Selected Doses
            dosesFields = ["Active", "Name", "Type", "TargetName", "StartTime", "TimeUnits", "Amount", "AmountUnits", "Interval", "Rate"];
            s = arrayfun(@(x)struct(x), this.session.SelectedDoses);
            fieldsToRemove = setdiff(fields(s), dosesFields);
            sessionForUI.Doses = rmfield(s, fieldsToRemove);

            % Simulation Time Specification
            sessionForUI.TimeSettings = [this.session.StartTime, this.session.TimeStep, this.session.StopTime];

            % Selected parameters
            sessionForUI.Parameters = arrayfun(@(x)struct(x), this.session.SelectedParams);
            sessionForUI.Parameters = struct2table(sessionForUI.Parameters);

            % PlotSpeciesTable
            sessionForUI.PlotSpeciesTable = cell2table(this.session.PlotSpeciesTable, 'VariableNames', ["PlotIndex", "StateName", "DisplayName"]);
            dataUsedTF = cellfun(@(x)ischar(x), sessionForUI.PlotSpeciesTable.PlotIndex);
            sessionForUI.PlotSpeciesTable.PlotIndex(~dataUsedTF) = {'NaN'};
            sessionForUI.PlotSpeciesTable.PlotIndex = cellfun(@(x)str2double(x), sessionForUI.PlotSpeciesTable.PlotIndex);
            sessionForUI.PlotSpeciesTable.StateName = string(sessionForUI.PlotSpeciesTable.StateName);
            sessionForUI.PlotSpeciesTable.DisplayName = [];
            sessionForUI.PlotSpeciesTable.LineStyle = string(this.session.SpeciesLineStyles);
            % will need the plot settings for the plots used.
            usedPlotsIdx = sessionForUI.PlotSpeciesTable.PlotIndex(dataUsedTF);

            % PlotDatasetTable
            if ~isempty(this.session.PlotDatasetTable)
                sessionForUI.PlotDatasetTable = cell2table(this.session.PlotDatasetTable, 'VariableNames', ["PlotIndex", "StateName", "DisplayName"]);
                dataUsedTF = cellfun(@(x)ischar(x), sessionForUI.PlotDatasetTable.PlotIndex);
                sessionForUI.PlotDatasetTable.PlotIndex(~dataUsedTF) = {'NaN'};
                sessionForUI.PlotDatasetTable.PlotIndex = cellfun(@(x)str2double(x), sessionForUI.PlotDatasetTable.PlotIndex);
                sessionForUI.PlotDatasetTable.StateName = string(sessionForUI.PlotDatasetTable.StateName);
                sessionForUI.PlotDatasetTable.DisplayName = [];
                plotIndexUsedByDataset = sessionForUI.PlotDatasetTable.PlotIndex(dataUsedTF);
            else
                sessionForUI.PlotDatasetTable = cell2table(cell(0,3), 'VariableNames', ["PlotIndex", "StateName", "DisplayName"]);
                plotIndexUsedByDataset = [];
            end

            % Used Plot Index are the plots currently selected.
            usedPlotsIdx = unique([usedPlotsIdx, plotIndexUsedByDataset]);

            % SimulationPlotSettings
            sessionForUI.SimulationPlotSettings = struct2table(this.session.SimulationPlotSettings(usedPlotsIdx));
            sessionForUI.SimulationPlotSettings.PlotIndex = usedPlotsIdx;

            % % SimProfileNotes + simulation data
            sessionForUI.SimulationPlotOverlay = this.session.FlagSimOverlay;
            sessionForUI.SimulationProfileNotes = this.getSimulationResults();

            % PopulationProfileNotes + simulation data
            sessionForUI.PopulationPlotOverlay = this.session.FlagPopOverlay;
            sessionForUI.PopulationProfileNotes = this.getPopulationSimulationResults();

            % FittingProfileNotes + simulation data with estimated params
            sessionForUI.DataFittingProfileNotes = this.getDataFittingResults();

            % Dataset information
            sessionForUI.DataSet.Meta = struct(this.session.DatasetTable);
            sessionForUI.DataSet.Meta.GroupColors = rgb2hex(this.session.GroupColors);

            % Maybe we don't send the entire dataset but only the time
            % courses of interest? How do we determine the state of
            % interest?
            if isa(this.session.DataToFit, 'dataset')
                sessionForUI.DataSet.Data = dataset2table(this.session.DataToFit);
            else
                sessionForUI.DataSet.Data = this.session.DataToFit;
            end

            % Send the time-course split by group.
            groupLabel = sessionForUI.DataSet.Meta.Group;
            if ~isempty(groupLabel)
                groups = unique(sessionForUI.DataSet.Data.(sessionForUI.DataSet.Meta.Group));
                for i = 1:numel(groups)
                    group_i_tf = sessionForUI.DataSet.Data.(groupLabel) == i;
                    sessionForUI.DataSet.GroupData{i} = sessionForUI.DataSet.Data(group_i_tf,:);
                end
            end

            % DataFitting Task
            sessionForUI.DataFittingTask.ResponseMap = cell2table(this.session.ResponseMap, 'VariableNames', ["DataName", "ModelComponentName"]);
            sessionForUI.DataFittingTask.DoseMap = cell2table(this.session.DoseMap, 'VariableNames', ["DataName", "DoseTarget"]);
            sessionForUI.DataFittingTask.DatasetHeaders = this.session.DatasetTable.Headers;
            sessionForUI.DataFittingTask.TargetSpecies = string({this.session.SelectedSpecies.partiallyQualifiedName});
            sessionForUI.DataFittingTask.PooledFitting = this.session.UsePooledFitting;
            sessionForUI.DataFittingTask.ErrorType = this.session.FitErrorModel;

            % Recent Files List
            sessionForUI.RecentFiles = getpref(this.PreferencesName, "RecentFiles");

            warning(warnState);
        end

    end

    % Utilities
    methods
        function loadCaseStudy(this, caseStudyNumber)
            csPath = "/Users/pax/projects/gPKPDSim/Supp Info - 2nd Submission/";

            switch caseStudyNumber
                case 1
                    csPath = csPath + "1) Case Study 1";
                case 2
                    csPath = csPath + "2) Case Study 2";
                case 3
                    csPath = csPath + "3) Case Study 3";
                case 4
                    csPath = csPath + "4) Case Study 4";
                otherwise
                    error('No case study for index = %d', caseStudyNumber);
            end

            this.loadProject(csPath);
        end

        function jsonsession = trimmedToJSON(this)
            jsonsession = jsonencode(this.trimSession);
        end

        function saveAllCaseStudiesToJSON(this)
            for i=1:4
                this.loadCaseStudy(i);
                this.saveSessionToJSON(sprintf('debugConfig_%d.js', i));
            end
        end

        % This function is used for debugging. It writes out a session
        % appropriate for the UI in JSON and puts the resulting file in a
        % specific location where the UI can load it. This allows us to
        % load realistic sessions in the UI without having the Controller
        % or the Model around (so no MATLAB).
        function saveSessionToJSON(this, outputFileName)
            arguments
                this
                outputFileName (1,1) string
            end
            fileLocation = "/Users/pax/projects/gPKPDSimUI/test/casestudies/";
            f = fopen(fileLocation + outputFileName, "w");
            fprintf(f, "%s", "export const debugConfig = ");
            fprintf(f, "%s", this.trimmedToJSON());
            fclose(f);
        end

        function saveUserPreference(this, fieldName, newValue)
            switch fieldName
                case "RecentFiles"
                    recentFiles = getpref(this.PreferencesName, fieldName);

                    [inListTF, currentIndex] = ismember(newValue, recentFiles);

                    if ~inListTF
                        recentFiles = vertcat({char(newValue)}, recentFiles);
                    else
                        recentFiles(currentIndex) = [];
                        recentFiles = vertcat(newValue, recentFiles);
                    end

                    % Limit the number of recent files to 5
                    if numel(recentFiles) > 5
                        recentFiles = recentFiles(1:5);
                    end
                    setpref(this.PreferencesName, fieldName, recentFiles);
                    this.notifyUI(fieldName);
                case ["DataPath", "LastPath", "Position"]
                    setpref(this.PreferencesName, fieldName, newValue);
                otherwise
                    error("Preference name %s not found.", fieldName);
            end
        end
    end

    % Actions on the server side
    methods(Access=public)
        % Menu callback function.
        function runTask(this, ~)

            [status, message] = this.session.run;

            if status
                switch this.session.Task
                    case 'Simulation'
                        notifyUI(this, 'NewSimulation');
                    case 'Fitting'
                        notifyUI(this, 'NewFitting');
                    case 'Population'
                        notifyUI(this, 'NewPopulation');
                    otherwise
                        error('Unknown functionalty %s', this.session.Task);
                end
            else
                error("Failed to run %s with message: %s", this.session.Task, message);
            end
        end

        % Load a project. This function also updates the RecentFiles
        % preference and notifies the UI of the update those.
        function loadProject(this, projectPath)
            arguments
                this (1,1) PKPD.controller
                projectPath (1,1) string
            end

            if isfolder(projectPath)
                matFile = string(what(projectPath).mat);
                if numel(matFile) > 1
                    % Assume there is a template mat file. Open the other
                    % one.
                    selectOneTF = ~matFile.contains("_template");
                    assert(sum(selectOneTF) == 1);
                    matFile = matFile(selectOneTF);
                end
                sessionContainer = load(matFile);

                % See if there is an sbproj file.
                % TODO: Might want to investigate
                % how gPKPDSim is loading the mat file to see if there is a
                % more robust way to get the name of the sbproj.
                dirListing = dir(projectPath);
                fileNames = string({dirListing.name});
                sbprojFileNameTF = fileNames.contains(".sbproj");
                assert(sum(sbprojFileNameTF) == 1);
                this.projectName = fileNames(sbprojFileNameTF);
            else
                [~, ~, ext] = fileparts(projectPath);
                if ext == ".mat"
                    sessionContainer = load(projectPath);
                else
                    error("not a MAT file");
                end
            end

            f = string(fields(sessionContainer));
            assert(isscalar(f));

            newSession = sessionContainer.(f);

            assert(class(newSession) == "PKPD.Analysis");

            this.session = newSession;
            this.projectPath = projectPath;

            % We don't want the backend to use UI in the new version. The
            % old version (version 1) will continue to do what it did
            % before.
            this.session.useUI = false;
            this.session.FlagDebug = false;

            warning('off', 'MATLAB:structOnObject');
            warning('off', 'SimBiology:REACTIONRATE_INVALID');

            this.notifyUI("LoadProject");

            % Save the recentFiles change in the preferences.
            if ~isempty(this.app)
                this.saveUserPreference("RecentFiles", projectPath);
            end
        end
    end

    % These methods all start with the prefix "update" and are the
    % functions called from the UI to update the Model.
    methods(Access=private)
        function updateTimeSettings(this, timeSettings)
            this.session.StartTime = timeSettings(1);
            this.session.TimeStep = timeSettings(2);
            this.session.StopTime = timeSettings(3);
        end

        function updateFunctionality(this, functionality)
            switch functionality.functionality
                case 'simulation'
                    task = 'Simulation';
                case 'datafitting'
                    task = 'Fitting';
                case 'populationsimulation'
                    task = 'Population';
                otherwise
                    error('Unknown functionality %s', functionalty.functionality);
            end

            this.session.Task = task;
        end

        function updatePlotOverlay(this, overlay)
            switch overlay.type
                case 'simulationprofilenotes'
                    this.session.FlagSimOverlay = overlay.plotOverlay;
                case 'populationsimulationprofilenotes'
                    this.session.FlagPopOverlay = overlay.plotOverlay;
                otherwise
                    error('Unknown overlay type %s', overlay.type);
            end
        end

        function updateNumberOfSimulations(this, numSimulations)
            this.session.NumPopulationRuns = numSimulations;
        end

        function updateParameter(this, parameter)
            % Will likely need to know which variant to edit. maybe there
            % is only one.. There is a function called updateSimVariant in
            % the Analysis class but it does not appear to do what we
            % need. So do that here and then investigate.
            idx = cellfun(@(x) x{2} == string(parameter.parameter), this.session.SimVariant.Content);
            assert(sum(idx) == 1);
            quad = this.session.SimVariant.Content{idx};
            quad{4} = str2double(parameter.value);
            this.session.SimVariant.Content{idx} = quad;
        end

        function updatePlotScale(this, plotScale)
            this.session.SimulationPlotSettings(plotScale.plotIndex).YScale = plotScale.yScale;
        end

        function updateDoseChanged(this, dose)
            doseObject = sbioselect(this.session.SelectedDoses, 'Name', dose.rows.Name);
            doseFields = string(fields(dose.rows));
            doseFields(doseFields == "Type")=[];
            for i = 1:numel(doseFields)
                doseObject.(doseFields{i}) = dose.rows.(doseFields{i});
            end
        end

        function updateDoseActive(this, doseActive)
            doseObject = sbioselect(this.session.SelectedDoses, 'Name', doseActive.name);
            doseObject.Active = doseActive.active;
        end

        function updateDeleteRun(this, deleteRun)
            switch deleteRun.task
                case 'SimulationProfileNotes'
                    this.session.SimData(deleteRun.index + 1) = [];
                    this.session.SimProfileNotes(deleteRun.index + 1) = [];
                case 'PopulationSimulationProfileNotes'
                    this.session.PopProfileNotes(deleteRun.index + 1) = [];
                    this.session.PopSummaryData(deleteRun.index + 1,:) = [];
                otherwise
                    error('Unhandled task %s', deleteRun.task);
            end
        end

        function updateDeleteAllRuns(this, allRuns)
            % Consider adding a trash can so that we can recover
            % accidentally deleted runs.
            switch allRuns.task
                case 'SimulationProfileNotes'
                    this.session.SimData = [];
                    this.session.SimProfileNotes = PKPD.Profile.empty;
                case 'PopulationSimulationProfileNotes'
                    this.session.PopProfileNotes = PKPD.Profile.empty;
                    this.session.PopSummaryData = PKPD.PopulationSummary.empty;
                case 'DataFittingProfileNotes'
                    disp('needs to be done');
            end            
        end

        function updatePopulationParameterCV(this, parameter)
            idx = string({this.session.SelectedParams.Name}) == parameter.parameter;
            assert(sum(idx) == 1);
            this.session.SelectedParams(idx).PercCV = str2double(parameter.cv);
        end

        function updatePlotLayout(this, plotLayout)
            this.session.SelectedPlotLayout = plotLayout.layout;
        end

        function updatePlotShow(this, showPlot)
            switch showPlot.Task
                case 'simulationprofilenotes'
                    field = "SimProfileNotes";
                case 'populationsimulationprofilenotes'
                    field = "PopProfileNotes";
                otherwise
                    error("Unknown task type: %s", showPlot.Task);
            end
            this.session.(field)(showPlot.Run).Show = showPlot.Show;
        end

        function updatePlotColor(this, newColor)
            switch newColor.Task
                case 'simulationprofilenotes'
                    field = "SimProfileNotes";
                case 'populationsimulationprofilenotes'
                    field = "PopProfileNotes";
                otherwise
                    error("Unknown task type: %s", showPlot.Task);
            end
            this.session.(field)(newColor.Run).Color = hex2rgb(newColor.Color);
        end

        function updatePlotContent(this, plotContent)
            addTF = plotContent.action == "add";
            switch plotContent.type
                case 'species'
                    % TODO: old version only support a state displaying in
                    % one plot. Now we support it plotting in multiple
                    % places. I am going to preserve the session object as
                    % it was for backwards compat and fix for new version
                    % later.
                    speciesNames = string(this.session.PlotSpeciesTable(:,2));
                    idx = speciesNames == plotContent.content;
                    if addTF
                        % do we have a sourceID if so its a move
                        this.session.PlotSpeciesTable{idx,1} = num2str(plotContent.plotIndex);
                    else
                        this.session.PlotSpeciesTable{idx,1} = '';
                    end
                otherwise
                    disp('Unhandled plotContent.type %s', plotContent.type);
            end
            % TODO: keep this for debugging.
            this.session.PlotSpeciesTable
        end

        function updatePlotStyles(this, plotStyle)
            speciesNames = string(this.session.PlotSpeciesTable(:,2));
            idx = speciesNames == plotStyle.speciesName;
            assert(sum(idx) == 1);
            this.session.setSpeciesLineStyles(find(idx), plotStyle.lineStyle);
        end

        function updatePlotExport(this, plotExport)
            switch plotExport.Task
                case 'simulationprofilenotes'
                    assert(plotExport.Run <= numel(this.session.SimProfileNotes));
                    this.session.SimProfileNotes(plotExport.Run).Export = plotExport.Export;
                otherwise
                    error('unhandled case %s', plotExport.Task)
            end
        end

        function updateAllExport(this, exportToggle)
            switch exportToggle.task
                case 'SimulationProfileNotes'                    
                    array = this.session.SimProfileNotes;
                case 'DataFittingProfileNotes'                    
                    error('This has no analog in the old version');
                case 'PopulationSimulationProfileNotes'
                    array = this.session.PopProfileNotes;
            end
            arrayfun(@(x)setfield(x, 'Export', exportToggle.export), array);
        end

        function updateRunDescription(this, runDescription)
            switch runDescription.Task
                case 'simulationprofilenotes'
                    this.session.SimProfileNotes(runDescription.Run).Description = runDescription.Description;
                otherwise
                    error('unhandled case %s', runDescription.Task);
            end
        end
        
        function updateVariantActive(this, activeVariant)
            variantNames = string({this.session.SelectedVariants.Name});
            idx = variantNames == activeVariant.name;
            assert(sum(idx) == 1);
            this.session.SelectedVariants(idx).Active = activeVariant.active;            
        end
    
        function updatePooledFitting(this, pooledFitting)
            this.session.UsePooledFitting = pooledFitting.pooledFitting;
        end
        
        function updateErrorType(this, errorModel)
            this.session.FitErrorModel = errorModel.errorType;
        end
    end

    % Menu item callbacks.
    methods(Access=private)
        function menuOpenSession(this, projectPath)
            if isempty(projectPath)
                selectedDir = uigetdir;
            else
                selectedDir = projectPath.sessionData;
            end
            this.loadProject(selectedDir);
        end

        function menuRun(this, task)
            this.runTask(task);
        end

        function menuAbout(this, ~)
            Name = "gPKPDSim";
            Logo = [];
            SupportInfo = "foobar";

            % Reuse the old about dialog. Probably should update to
            % something more modern.
            UIUtilities.AboutDialog(Name, this.Version, this.RevisionDate, Logo, SupportInfo);
        end
    end

    % These methods are used to marshall data from the Model (backend) to
    % the UI (frontend).
    methods(Access=private)
        function simulationResults = getSimulationResults(this)
            if ~isempty(this.session.SimProfileNotes)
                simProfileNotes = arrayfun(@(x)struct(x), this.session.SimProfileNotes);
                simulationResults = struct2table(simProfileNotes, "AsArray", true);
                simulationResults.Color = rgb2hex(simulationResults.Color);
                simulationResults.Run = (1:height(simulationResults))';
                simulationResults.ParametersTable = cellfun(@(x)cell2table(x, 'VariableNames', ["Name", "Value"]), simulationResults.ParametersTable, UniformOutput=false);
                simulationResults.DosingTable = cell2table(simulationResults.DosingTable, 'VariableNames',["DoseName", "Type", "Target", "Interval", "TimeUnits", "Amount", "AmountUnits", "foo1", "foo2", "foo3"]);
                simulationResults.DosingTable = [];

                % Send only the data that is being selected now. More data will
                % be sent on demand.
                simData = this.session.SimData;
                simData = struct(simData);
                fieldsToKeep = ["Data", "DataNames", "Time"];
                simData = rmfield(simData, setdiff(fields(simData), fieldsToKeep));
                for i = 1:numel(simData)
                    simData(i).Data = simData(i).Data';
                end
                simulationResults.Data = simData';
            else
                simulationResults = [];
            end
        end

        function populationSimulationResults = getPopulationSimulationResults(this)
            if ~isempty(this.session.PopProfileNotes)
                populationProfileNotes = arrayfun(@(x)struct(x), this.session.PopProfileNotes);
                populationSimulationResults = struct2table(populationProfileNotes, AsArray=true);
                populationSimulationResults.Color = rgb2hex(populationSimulationResults.Color);

                populationSimulationResults.Run = (1:height(populationSimulationResults))';
                populationSimulationResults.ParametersTable = cellfun(@(x)cell2table(x, 'VariableNames', ["Name", "Value"]), populationSimulationResults.ParametersTable, UniformOutput=false);
                populationSimulationResults.DosingTable = cell2table(populationSimulationResults.DosingTable, 'VariableNames',["DoseName", "Type", "Target", "Interval", "TimeUnits", "Amount", "AmountUnits", "foo1", "foo2", "foo3"]);

                for i = 1:size(this.session.PopSummaryData, 1)
                    thisRun = this.session.PopSummaryData(i,:);
                    popSimData(i).DataNames = string({thisRun.Name});
                    popSimData(i).Time = thisRun(1).Time; % Should check all time vectors are the same.
                    popSimData(i).P5 = [thisRun.P5]';
                    popSimData(i).P50 = [thisRun.P50]';
                    popSimData(i).P95 = [thisRun.P95]';
                end
                populationSimulationResults.Data = popSimData';
            else
                populationSimulationResults = [];
            end
        end
    
        function dataFittingResults = getDataFittingResults(this)
            if ~isempty(this.session.FitResults)
                dataFittingProfileNotes = arrayfun(@(x)struct(x), this.session.FitResults);
                fieldsToKeep = ["MSE", "SSE", "LogLikelihood", "AIC", "BIC", "DFE", "FitType"];
                dataFittingProfileNotes = rmfield(dataFittingProfileNotes, setdiff(fields(dataFittingProfileNotes), fieldsToKeep));
                dataFittingResults = struct2table(dataFittingProfileNotes, "AsArray", true);
                
                % We only support having one datafitting results.
                assert(height(dataFittingResults) == 1);

                dataFittingResults.Run = (1:height(dataFittingResults))';
                dataFittingResults.Show = true;                
                
                % Since we only support one DataFittingResults, all the
                % simdatas in FitSimData are 
                fitSimData = this.session.FitSimData;
                fitSimData = struct(fitSimData);
                fieldsToKeep = ["Data", "DataNames", "Time"];
                fitSimData = rmfield(fitSimData, setdiff(fields(fitSimData), fieldsToKeep));
                for i = 1:numel(fitSimData)
                    fitSimData(i).Data = fitSimData(i).Data';
                    fitSimData(i).Color = rgb2hex(this.session.GroupColors(i,:));
                    fitSimData(i).Group = i;
                end
                dataFittingResults.Data = fitSimData';
            else
                dataFittingResults = [];
            end
        end
    end
end
