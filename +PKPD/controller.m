classdef controller < handle
    properties(Constant)
        Version = 2.0
        PreferencesName = "PKPDViewer_AnalysisApp";
        Debug = false;
    end

    properties
        app
        projectPath (1,1) string
        projectName (1,1) string
        session PKPD.Analysis = PKPD.Analysis.empty        
        RevisionDate = datetime("now");
        FrontendSHA (1,1) string
        BackendSHA (1,1) string
    end

    methods
        function this = controller(app)
            arguments
                app = []
            end
            this.app = app;

            % This may not be needed
            [~, this.FrontendSHA] = system('git -C /Users/pax/projects/gPKPDSimUI rev-parse HEAD');
            [~, this.BackendSHA] = system('git -C /Users/pax/projects/gPKPDSim rev-parse HEAD');
            this.FrontendSHA = strip(this.FrontendSHA);
            this.BackendSHA = strip(this.BackendSHA);

            % hack for now to initialize preferences
            if ~ispref(this.PreferencesName)
                setpref(this.PreferencesName, 'RecentFiles', {});
            end
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
                if this.Debug
                    fprintf("Handling event: %s\n", eventName);
                end
                
                this.(eventName)(e);
            catch p
                fprintf('Error calling the %s method. %s\n', eventName, p.message);
            end

        end

        % Send events to the UI. No other function sends events to the UI
        % other than this one. This may not be a great solution for
        % controller -> viewer comm because of the switch statement (don't
        % want another string making the connections) but I do want to keep
        % communication going through one function so I plan to look at
        % this decision again and see if we can clean it up.
        function notifyUI(this, eventName)
            arguments
                this
                eventName (1,1) string
            end

            if ~isempty(this.app)
                switch eventName
                    case "LoadProject"
                        trimmedSession = this.trimSession();
                        message = trimmedSession;
                    case "NewSimulation"
                        message = this.getSimulationResults();
                    case "NewPopulation"
                        message = this.getPopulationSimulationResults();
                    case "NewFitting"
                        message = this.getDataFittingResults();

                    case "RecentFiles"
                        message = getpref(this.PreferencesName, eventName);

                    case "updateParameters"
                        message = this.getParameters();                        

                    case "updateSelectedVariants"
                        message = this.getSelectedVariants();

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
            % % Sort the names using the VariantOrder and supply
            % % the UI the variants in order.
            % if ~isempty(this.session.SelectedVariants)
            %     variants = this.session.SelectedVariants;
            %     sessionForUI.Variants = table([variants.Active]', string({variants.Name})', string({variants.Tag})', 'VariableNames', ["Active", "Name", "Tag"]);
            %     sessionForUI.Variants = sessionForUI.Variants(this.session.SelectedVariantsOrder,:);
            % else
            %     sessionForUI.Variants = table.empty;
            % end

            sessionForUI.Variants = this.getSelectedVariants();

            % Selected Doses
            dosesFields = ["Active", "Name", "Type", "TargetName", "StartTime", "TimeUnits", "Amount", "AmountUnits", "Interval", "Rate", "RepeatCount"];
            s = arrayfun(@(x)struct(x), this.session.SelectedDoses);
            fieldsToRemove = setdiff(fields(s), dosesFields);
            sessionForUI.Doses = rmfield(s, fieldsToRemove);

            % Simulation Time Specification
            sessionForUI.TimeSettings = [this.session.StartTime, this.session.TimeStep, this.session.StopTime];

            % Selected parameters
            sessionForUI.Parameters = this.getParameters();
            

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
            sessionForUI.DataSet.Meta.GroupColors = PKPD.controller.rgb2hex(this.session.GroupColors);

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

            % Preferences will be sent with the Model session for simplicity sake.
            % Recent Files List
            % sessionForUI.Preferences.RecentFiles = getpref(this.PreferencesName, "RecentFiles");
            if ispref(this.PreferencesName, 'FontName')
                sessionForUI.Preferences.FontName = getpref(this.PreferencesName, 'FontName');
            else
                sessionForUI.Preferences.FontName = '';
            end
            % Supply all the available fonts.
            % TODO: This should be done via a get
            % method and an explicit call from the UI. but I want to
            % prototype this quickly so use this mechanism.
            %sessionForUI.Preferences.FontNames = string(listfonts);

            warning(warnState);
        end

    end

    % Utilities
    methods
        function loadCaseStudy(this, caseStudyNumber)
            csPath = fileparts(mfilename('fullpath')) + "/../CaseStudies/CaseStudy" + caseStudyNumber;

            if ~exist(csPath, "dir")
                error('No CaseStudy%d', caseStudyNumber);
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
                    elseif numel(recentFiles) > 1
                        % If there is more than one recentFiles sort the
                        % newValue at the top.
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

        % Uses uiputfile to get a full path to a chosen filepath. It
        % initializes uiputfile using the LastPath used preference and
        % updates it if changed.
        function fullFileName = getFilePathAndSavePreference(this, fileExtensionFilter)
            % Start uiputfile from the LastPath
            savedPath = getpref(this.PreferencesName, 'LastPath');
            [fileName, pathName] = uiputfile(fileExtensionFilter, 'Save As ...', savedPath);

            if ~strcmp(pathName, savedPath)
                setpref(this.PreferencesName, 'LastPath', pathName);
            end
            fullFileName = fullfile(pathName, fileName);
        end
    end

    % Actions on the server side
    methods(Access=public)
        % Run a task. Determines which task based on the current task
        % selected in the frontend.
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
        % preference and notifies the UI of the update.
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
                case 'SimulationProfileNotes'
                    this.session.FlagSimOverlay = overlay.plotOverlay;
                case 'PopulationSimulationProfileNotes'
                    this.session.FlagPopOverlay = overlay.plotOverlay;
                case 'DataFittingProfileNotes'
                    warning('DataFittingProfiles are not supported yet');
                otherwise
                    error('Unknown overlay type %s', overlay.type);
            end
        end

        function updateNumberOfSimulations(this, numSimulations)
            this.session.NumPopulationRuns = numSimulations;
        end

        function updateParameter(this, parameter)
            idx = arrayfun(@(x)strcmp(x.Name, parameter.parameter), this.session.SelectedParams);
            assert(sum(idx) == 1);
            this.session.SelectedParams(idx).Value = str2double(parameter.value);
            this.session.updateSimVariant();
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
                case 'SimulationProfileNotes'
                    field = "SimProfileNotes";
                case 'PopulationSimulationProfileNotes'
                    field = "PopProfileNotes";
                otherwise
                    error("Unknown task type: %s", showPlot.Task);
            end
            this.session.(field)(showPlot.Run).Show = showPlot.Show;
        end

        function updatePlotColor(this, newColor)
            switch newColor.Task
                case 'SimulationProfileNotes'
                    field = "SimProfileNotes";
                case 'PopulationSimulationProfileNotes'
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
            % this.session.PlotSpeciesTable
        end

        function updatePlotStyles(this, plotStyle)
            speciesNames = string(this.session.PlotSpeciesTable(:,2));
            idx = speciesNames == plotStyle.speciesName;
            assert(sum(idx) == 1);
            this.session.setSpeciesLineStyles(find(idx), plotStyle.lineStyle);
        end

        function updatePlotExport(this, plotExport)
            switch plotExport.Task
                case 'SimulationProfileNotes'
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
                otherwise
                    error('Unknown task name %s', exportToggle.task);
            end
            arrayfun(@(x)setfield(x, 'Export', exportToggle.export), array);
        end

        function updateRunDescription(this, runDescription)
            switch runDescription.Task
                case 'SimulationProfileNotes'
                    this.session.SimProfileNotes(runDescription.Run).Description = runDescription.Description;
                case 'PopulationSimulationProfileNotes'
                    this.session.PopProfileNotes(runDescription.Run).Description = runDescription.Description;
                case 'DataFittingProfileNotes'
                    warning('DataFittingProfileNotes not finished yet.')
                otherwise
                    error('unhandled case %s', runDescription.Task);
            end
        end

        function updateVariantActive(this, activeVariant)
            variantNames = string({this.session.SelectedVariants.Name});
            idx = variantNames == activeVariant.name;
            assert(sum(idx) == 1);
            this.session.SelectedVariants(idx).Active = activeVariant.active;

            % Now we update the M(odel) state to reflect the new state of
            % applied variants. In addition to the active variants we
            % update the SelectedParams and the SimVariant. This is done
            % with the updateRestoreParameters. That function is used to
            % restore the parameter table to model defaults + applied
            % variants. 
            this.updateRestoreParameters();
        end

        function updateSavedVariants(this, ~)
            % Make up a new name for the new variant.
            existingNames = arrayfun(@(x)string(x.Name), this.session.SelectedVariants);
            if ~isempty(existingNames)
                numberUnnamedVariants = sum(existingNames.startsWith("Unnamed"));
                newName = "Unnamed" + (numberUnnamedVariants + 1);
            else
                newName = "Unnamed";
            end
            this.session.saveVariant(char(newName));
            this.notifyUI("updateSelectedVariants");
        end

        function updatePooledFitting(this, pooledFitting)
            this.session.UsePooledFitting = pooledFitting.pooledFitting;
        end

        function updateErrorType(this, errorModel)
            this.session.FitErrorModel = errorModel.errorType;
        end

        function updateRestoreParameters(this, ~)
            % this should probably not do the work but call the Model (MVC)
            % to do this work. But lets not change the M(odel) now.

            % SelectedParams is updated with the model value + applied variants
            OrderedVariants = this.session.SelectedVariants;
            OrderedVariants(this.session.SelectedVariantsOrder) = this.session.SelectedVariants;
            IsSelected = get(OrderedVariants,'Active');
            if iscell(IsSelected)
                IsSelected = cell2mat(IsSelected);
            end
            OrderedVariants = OrderedVariants(IsSelected);

            for index = 1:numel(this.session.SelectedParams)
                restoreValueFromVariant(this.session.SelectedParams(index), this.session.ModelObj, OrderedVariants);
            end

            % Apply parameters to simulation variant
            this.session.updateSimVariant();

            % Tell the UI we changed the parameters
            this.notifyUI("updateParameters");
        end
    
        function updateVariantNameOrTag(this, variant)
            idx = arrayfun(@(x)strcmp(x.(variant.property), variant.oldValue), this.session.SelectedVariants);
            assert(sum(idx) == 1);
            this.session.SelectedVariants(idx).(variant.property) = variant.newValue;
            this.session.SelectedVariants
        end

        function updateVariantOrder(this, variantOrder)
            % Enhancement. Rather than hold on to the Variants, their
            % Names, and the order in different properties of session we
            % should just have the variants themselves and order them the
            % way we want.
            newOrder = string({variantOrder.rows.Name});
            currentOrder = string(this.session.SelectedVariantNames);
            currentOrder = currentOrder(this.session.SelectedVariantsOrder);
            
            idx = zeros(numel(newOrder), 1);
            for i=1:numel(newOrder)
                idx(i) = find(newOrder(i) == currentOrder);
            end

            this.session.SelectedVariantsOrder = idx;            
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

        function menuExportSimToExcel(this, ~)
            Spec =  {'*.xlsx;*.xls','Excel'};
            fullFileName = this.getFilePathAndSavePreference(Spec);
            [StatusOK,Message] = export(this.session, fullFileName, 'Simulation');
            if ~StatusOK
                error('Unhandled error. Need to send this to the frontend. %s', Message);
            end
        end

        function menuExportDataFittingToExcel(this, ~)
            Spec =  {'*.xlsx;*.xls','Excel'};
            fullFileName = this.getFilePathAndSavePreference(Spec);
            [StatusOK,Message] = export(this.session, fullFileName, 'Fitting');
            if ~StatusOK
                error('Unhandled error. Need to send this to the frontend. %s', Message);
            end
        end

        function menuExportDataFittingToPDF(this, ~)
            warning('Data fitting summary export to PDF is currently disabled');
            return
            Spec = {'*.pdf','PDF';'*.xlsx;*.xls','Excel'};

            fullFileName = this.getFilePathAndSavePreference(Spec);
            % TODO: this is disabled for now.
            % [StatusOK,Message] = export(this.session, fullFileName, 'FittingSummary');
            if ~StatusOK
                error('Unhandled error. Need to send this to the frontend. %s', Message);
            end
        end

        function menuExportPopulationSimulationToExcel(this, ~)
            Spec =  {'*.xlsx;*.xls','Excel'};
            fullFileName = this.getFilePathAndSavePreference(Spec);
            [StatusOK,Message] = export(this.session, fullFileName, 'Population');
            if ~StatusOK
                error('Unhandled error. Need to send this to the frontend. %s', Message);
            end
        end

        function menuExportNCAToExcel(this, ~)
            warning('NCA export is currently disabled');
            return
            Spec =  {'*.xlsx;*.xls','Excel'};
            fullFileName = this.getFilePathAndSavePreference(Spec);
            [StatusOK,Message] = export(this.session, fullFileName, 'NCA');
            if ~StatusOK
                error('Unhandled error. Need to send this to the frontend. %s', Message);
            end
        end

        function menuAbout(this, ~)
            Name = "gPKPDSim";
            Logo = [];
            SupportInfo = "";

            % Reuse the old about dialog. Probably should update to
            % something more modern.
            UIUtilities.AboutDialog(Name, this.Version, this.RevisionDate, Logo, SupportInfo);
        end

        function menuDocumentation(this, ~)
            % TODO, need to make sure this is on the path
            web('gPKPDSimUserGuide.html');
        end
        
        function menuImportDataset(this, ~)
            % TODO, add filter and title and multi-select should be off
            [file, location] = uigetfile;
            
            disp('adf');
        end
    end

    % These methods are used to marshall data from the Model (backend) to
    % the UI (frontend).
    methods(Access=private)
        function simulationResults = getSimulationResults(this)
            if ~isempty(this.session.SimProfileNotes)
                simProfileNotes = arrayfun(@(x)struct(x), this.session.SimProfileNotes);
                simulationResults = struct2table(simProfileNotes, "AsArray", true);
                simulationResults.Color = PKPD.controller.rgb2hex(simulationResults.Color);
                simulationResults.Run = (1:height(simulationResults))';
                simulationResults.ParametersTable = cellfun(@(x)cell2table(x, 'VariableNames', ["Name", "Value"]), simulationResults.ParametersTable, UniformOutput=false);
                % TODO: there is a bug here.
                % simulationResults.DosingTable = cell2table(simulationResults.DosingTable, 'VariableNames',["DoseName", "Type", "Target", "Interval", "TimeUnits", "Amount", "AmountUnits", "foo1", "foo2", "foo3"]);
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
                populationSimulationResults.Color = PKPD.controller.rgb2hex(populationSimulationResults.Color);

                populationSimulationResults.Run = (1:height(populationSimulationResults))';
                populationSimulationResults.ParametersTable = cellfun(@(x)cell2table(x, 'VariableNames', ["Name", "Value"]), populationSimulationResults.ParametersTable, UniformOutput=false);
                % TODO: there is a bug here.
                %populationSimulationResults.DosingTable = cell2table(populationSimulationResults.DosingTable, 'VariableNames',["DoseName", "Type", "Target", "Interval", "TimeUnits", "Amount", "AmountUnits", "foo1", "foo2", "foo3"]);
                populationSimulationResults.DosingTable = [];

                % Test that this works.
                %popSimData = repmat(struct('DataNames', [], 'Time', [], 'P5', [], 'P50', [], 'P95', []), size(this.session.PopSummaryData, 1), 1);
                
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
                    fitSimData(i).Color = PKPD.controller.rgb2hex(this.session.GroupColors(i,:));
                    fitSimData(i).Group = i;
                end
                dataFittingResults.Data = fitSimData';
            else
                dataFittingResults = [];
            end
        end
        
        function parameters = getParameters(this)
            parameters = arrayfun(@(x)struct(x), this.session.SelectedParams);
            parameters = struct2table(parameters);
        end

        function variants = getSelectedVariants(this)
            % Sort the names using the VariantOrder and supply
            % the UI the variants in order.
            if ~isempty(this.session.SelectedVariants)
                variants = this.session.SelectedVariants;
                variants = table([variants.Active]', string({variants.Name})', string({variants.Tag})', 'VariableNames', ["Active", "Name", "Tag"]);
                variants = variants(this.session.SelectedVariantsOrder,:);
            else
                variants = table.empty;
            end
        end
    end

    methods(Static)
        % This function is here to make gPKPDSim work on older versions of
        % MATLAB that did not have this function. rgb2hex was introduced in
        % R2024a. If we are running in a release < 24a use this otherwise
        % use the official MATLAB version.
        function hex = rgb2hex(rgb, opts)
            %
            %   Copyright 2024 The MathWorks, Inc.

            arguments
                rgb {mustBeA(rgb,["double","single","uint8","uint16"]), mustBeNonnegative}
                opts.Shorthand (1,1) logical
            end

            if ~isMATLABReleaseOlderThan("R2024a")
                hex = rgb2hex(rgb);
                return
            end

            rgbType = class(rgb);
            sz = size(rgb);

            % Validate RGB shape and reshape MxNx3 to a vector of RGB triplets.
            if sz(end) ~= 3 && ~isequal(sz,[0 0])
                error(message('MATLAB:graphics:validatecolor:InvalidRGBMatrixShape'))
            end

            % Change to a vector of rgb triplets.
            rgb = reshape(rgb,[],3);

            if ~isempty(rgb) && ismember(rgbType, {'double' 'single'}) && (max(rgb,[],"all") > 1)
                error(message('MATLAB:graphics:validatecolor:OutOfRange'));
            end

            % Scale values to be on the [0,255] range.
            if ismember(rgbType, {'double', 'single'})
                rgb = round(rgb * 255);
            elseif isequal(rgbType, 'uint16')
                scale = 255 / 65535;
                rgb = rgb * scale;
            end

            % Determine whether to use shorthand 3-digit representation or standard 6-digit.
            % Convert to hexadecimal representation.
            if isfield(opts, 'Shorthand') && opts.Shorthand
                % Shorthand represents multiples of '#11', which is 17 in decimal.
                % Divide each rgb value by 17 and round to the closes multiple of 17.
                % dec2hex to convert each scaled rgb value to its corresponding 1-digit
                % hex value. reshape each triple of hex values to a 3-digit hex value.
                hex(:,2:4) = reshape(dec2hex(round(rgb/17)')', 3, [])';
            else
                % dec2hex to convert each rgb value to its corresponding 2-digit hex
                % value. reshape each triplet of hex values to a 6-digit hex value.
                hex(:,2:7) = reshape(dec2hex(rgb',2)', 6, [])';
            end
            hex(:,1) = '#';
            if ~isempty(hex)
                hex = string(cellstr(hex));
            else
                hex = strings(0); % Create an empty string to prevent the empty char from becoming "".
            end
            if numel(sz) > 2
                % For NDx3, change back to an ND matrix of hex codes.
                hex = reshape(hex, sz(1:end-1));
            end
        end
    end
end
