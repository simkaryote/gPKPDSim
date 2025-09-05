classdef controller < handle
    properties(Constant)
        Version = "2.1"
        PreferencesName = "PKPDViewer_AnalysisApp";
        Debug = false;
    end

    properties
        app
        projectPath (1,1) string
        projectName (1,1) string
        session PKPD.Analysis = PKPD.Analysis.empty        
        RevisionDate = datetime("now");
        SessionDirtyState (1,1) logical = false
    end

    methods
        function this = controller(app)
            arguments
                app = []
            end

            % UIHTML HTMLEventReceivedFcn only supported since 23b
            if isMATLABReleaseOlderThan('R2023b')
                error('gPKPDSim V2.0 not supported in releases older than R2023b');
            end

            this.app = app;

            % The models used for the built-in case studies use custom
            % units and we need to make sure those are loaded.
            units;

            % See if there is an old version of gPKPDSim installed in the
            % Apps folder. 
            % appInfo = matlab.apputil.getInstalledAppInfo;
            % idx = appInfo.id == "gPKPDSimAPP";
            % if any(idx)
            %    matlab.apputil.uninstall(appInfo(idx).id);
            % end
            % 
            % installedAddOns = matlab.addons.installedAddons;
            % gPKPDSimAddOn = installedAddOns(installedAddOns.Name == "gPKPDSim", :);
            % if ~isempty(gPKPDSimAddOn)
            %     matlab.addons.uninstall("gPKPDSim");
            % end

            % Setup preferences.
            this.setupPreferences();                        

            % Configure the window with custom settings.
            if ~isempty(this.app)
                position = getpref(this.PreferencesName, 'Position');
                this.app.gPKPDSimUIFigure.Position = position;
                this.app.HTML.Position = [1 1 position(3) position(4)];
                this.app.gPKPDSimUIFigure.CloseRequestFcn = @(s,e)this.closeApp;
                this.app.gPKPDSimUIFigure.Name = "gPKPDSim " + this.Version;

                % turn off some warnings for now
                warning('off', 'SimBiology:SimData:datasetColumnNotNumeric');
                warning('off', 'SimBiology:sbiofit:IgnoringCategoryVariableName');
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

                % Any calls from the UI for update methods
                if eventName.startsWith("update")
                    this.SessionDirtyState = true;
                end
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
        function notifyUI(this, eventName, inputMessage)
            arguments
                this
                eventName (1,1) string
                inputMessage = ""
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
                        this.session.updateFitVariant();
                        message = this.getDataFittingResults();

                    case "RecentFiles"
                        message = getpref(this.PreferencesName, eventName);

                    case "updateParameters"
                        message = this.getParameters();                        

                    case "updateSelectedVariants"
                        message = this.getSelectedVariants();

                    case "updateDataset"
                        message = this.getDataset();

                    case "updateDataFittingResponseMap"
                        message = this.getDataFittingResponseMap();

                    case "updateDataFittingDoseMap"
                        message = this.getDataFittingDoseMap();

                    case "Error"
                        message = inputMessage;
                        
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
                "UsePooledFitting",...
                "NumPopulationRuns",...
                ];

            for i = 1:numel(selectedFields)
                sessionForUI.(selectedFields(i)) = this.session.(selectedFields(i));
            end

            sessionForUI.ProjectName = this.projectName;

            % Selected Variants.
            sessionForUI.Variants = this.getSelectedVariants();

            % Selected Doses
            if ~isempty(this.session.SelectedDoses)
                dosesFields = ["Active", "Name", "Type", "TargetName", "StartTime", "TimeUnits", "Amount", "AmountUnits", "Interval", "Rate", "RepeatCount"];
                s = arrayfun(@(x)struct(x), this.session.SelectedDoses);
                fieldsToRemove = setdiff(fields(s), dosesFields);
                sessionForUI.Doses = rmfield(s, fieldsToRemove);
            else
                sessionForUI.Doses = [];
            end

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
            % normalize names to have [] if needed. 
            for jj = 1:numel(sessionForUI.PlotSpeciesTable.StateName)
                if ~isvarname(sessionForUI.PlotSpeciesTable.StateName(jj)) && ~sessionForUI.PlotSpeciesTable.StateName(jj).startsWith("[")
                    sessionForUI.PlotSpeciesTable.StateName(jj) = "[" + sessionForUI.PlotSpeciesTable.StateName(jj) + "]";
                end
            end


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
            usedPlotsIdx = unique(vertcat(usedPlotsIdx, plotIndexUsedByDataset));
            usedPlotsIdx = usedPlotsIdx(~isnan(usedPlotsIdx));

            % SimulationPlotSettings
            sessionForUI.SimulationPlotSettings = struct2table(this.session.SimulationPlotSettings(usedPlotsIdx));
            sessionForUI.SimulationPlotSettings.PlotIndex = usedPlotsIdx;

            % SimProfileNotes + simulation data
            sessionForUI.SimulationPlotOverlay = this.session.FlagSimOverlay;
            sessionForUI.SimulationProfileNotes = this.getSimulationResults();

            % PopulationProfileNotes + simulation data
            sessionForUI.PopulationPlotOverlay = this.session.FlagPopOverlay;
            sessionForUI.PopulationProfileNotes = this.getPopulationSimulationResults();

            % FittingProfileNotes + simulation data with estimated params
            sessionForUI.DataFittingProfileNotes = this.getDataFittingResults();

            % Dataset information
            sessionForUI.DataSet = this.getDataset();

            % Fitting method options
            sessionForUI.FitFunctionOptions = this.getFitFunctionOptions();

            % DataFitting Task
            sessionForUI.DataFittingTask.ResponseMap = this.getDataFittingResponseMap();
            sessionForUI.DataFittingTask.DoseMap = this.getDataFittingDoseMap();

            sessionForUI.DataFittingTask.DatasetHeaders = this.session.DatasetTable.Headers;
            sessionForUI.DataFittingTask.TargetSpecies = string({this.session.SelectedSpecies.partiallyQualifiedName});
            sessionForUI.DataFittingTask.PooledFitting = this.session.UsePooledFitting;
            sessionForUI.DataFittingTask.ErrorType = this.session.FitErrorModel;
            sessionForUI.DataFittingTask.FitFunctionName = this.session.FitFunctionName;

            sessionForUI.SimulationColormap = PKPD.controller.rgb2hex(this.session.ColorMap1);

            % Preferences will be sent with the Model session for simplicity sake.
            % Recent Files List
            sessionForUI.Preferences.RecentFiles = getpref(this.PreferencesName, "RecentFiles");
            % if ispref(this.PreferencesName, 'FontName')
            %     sessionForUI.Preferences.FontName = getpref(this.PreferencesName, 'FontName');
            % else
            %     sessionForUI.Preferences.FontName = '';
            % end
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

            % Use the filenames for the _final.mat in each case. 
            switch caseStudyNumber
                case 1
                    filename = 'casestudy1_TwoCompPK_final.mat';
                case 2
                    filename = 'casestudy2_TMDD_final.mat';
                case 3
                    filename = 'casestudy3_IDR_TwoCompPK_final.mat';
                case 4
                    filename = 'casestudy4_minPBPK_final.mat';                    
                otherwise
                    warning('Unknown case study number %d', caseStudyNumber);
            end

            fullPathName = csPath + "/" + filename;
            
            if ~exist(fullPathName, "file")
                error('No CaseStudy%d', caseStudyNumber);
            end

            this.loadProject(fullPathName);
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

            if ischar(fileName) && ischar(pathName)
                if ~strcmp(pathName, savedPath)
                    setpref(this.PreferencesName, 'LastPath', pathName);
                end
                fullFileName = fullfile(pathName, fileName);
            else
                % User likely called cancel.
                fullFileName = '';
            end
        end
    
        function set.SessionDirtyState(this, state)
            if this.SessionDirtyState ~= state
                this.SessionDirtyState = state;
                this.setFigureName();
            end
        end

        function setFigureName(this)
            if ~isempty(this.app)
                if this.SessionDirtyState
                    this.app.gPKPDSimUIFigure.Name = this.app.gPKPDSimUIFigure.Name + " *";
                else
                    currentName = string(this.app.gPKPDSimUIFigure.Name);
                    this.app.gPKPDSimUIFigure.Name = currentName.strip("right", "*").strip;
                end
            end
        end

        function closeApp(this)
            % This will be called when the app's uifigure is being closed.
            % Now is the time to store the position in our preferences.
            assert(~isempty(this.app));
            currentWindowPosition = this.app.gPKPDSimUIFigure.Position;
            setpref(this.PreferencesName, 'Position', currentWindowPosition);            
            
            % If all worked ok then delete the app. This will delete
            % everything.
            delete(this.app);
        end
        
        function setupPreferences(this)
            % If we don't have Preferences setup yet then use some defaults
            % to initialize them.
            defaultValues = dictionary;
            defaultValues("LastPath") = {pwd};
            defaultValues("DataPath") = {pwd};
            defaultValues("Position") = {[50 100 1500 1000]};
            defaultValues("RecentFiles") = {{}};

            if ~ispref(this.PreferencesName)
                expectedFields = defaultValues.keys;
                for i = 1:numel(expectedFields)
                    field_i = expectedFields(i);
                    value = defaultValues(field_i);
                    setpref(this.PreferencesName, field_i, value{1});
                end
            else
                % Make sure we have all the fields
                expectedFields = defaultValues.keys.sort;
                preferenceFields = string(fields(getpref('PKPDViewer_AnalysisApp'))).sort;
                match = expectedFields.matches(preferenceFields);

                if ~all(match)
                    % some fields are missing
                    idx = find(match == 0);
                    for i = 1:numel(idx)
                        field_i = expectedFields(idx(i));
                        value = defaultValues(field_i);
                        setpref(this.PreferencesName, field_i, value{1});
                    end
                end
            end
        end
            
    end

    % Server-side actions
    methods(Access=public)
        % Run a task. Determines which task based on the current task
        % selected in the frontend.
        function runTask(this, ~)

            try
                [status, message] = this.session.run;
            catch e
                disp(e)
            end

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
                notifyUI(this, 'Error', message);
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

            [~, name, ext] = fileparts(projectPath);
            if ext == ".mat"
                sessionContainer = load(projectPath);
            else
                error("Select a MAT file");
            end
            this.projectName = name;

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

            this.SessionDirtyState = false;

            % Save the recentFiles change in the preferences.
            if ~isempty(this.app)
                this.saveUserPreference("RecentFiles", projectPath);
            end
        end

        function saveProject(this, fullFilePathName)

            if exist(fullFilePathName, "file")
                [status, attribs] = fileattrib(fullFilePathName);
                if ~status
                    error('Could not get file attributes for %s', fullFilePathName);
                elseif ~attribs.UserWrite
                    error('File %s is read-only', fullFilePathName);
                end          
            end

            Analysis = this.session;
            save(fullFilePathName, "Analysis");
            this.SessionDirtyState = false;
        end
    end

    % These methods update the M(odel).
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
                    this.session.(field)(showPlot.Run).Show = showPlot.Show;
                case 'PopulationSimulationProfileNotes'
                    field = "PopProfileNotes";
                    this.session.(field)(showPlot.Run).Show = showPlot.Show;
                case 'DataFittingProfileNotes'
                    % TODO: This is not yet supported
                otherwise
                    error("Unknown task type: %s", showPlot.Task);
            end
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
                    if isstruct(plotContent.content)
                        stateName = plotContent.content.StateName;
                        %warning("Internal issue: plotContent.content should not be a struct.");
                    else
                        stateName = plotContent.content;
                    end

                    idx = speciesNames == stateName;
                    if ~any(idx)
                        % Deal with brakets
                        stateName = string(stateName);
                        if stateName.startsWith("[") && stateName.endsWith("]")
                            stateName = stateName.extractBetween("[", "]");
                        end
                        idx = speciesNames == stateName;
                    end
                    
                    assert(sum(idx) == 1, "Looking for a state that is not present.");
                    
                    if addTF
                        % do we have a sourceID if so its a move
                        this.session.PlotSpeciesTable{idx,1} = num2str(plotContent.plotIndex);
                    else
                        this.session.PlotSpeciesTable{idx,1} = '';
                    end
                case 'dataset'
                    if addTF && isempty(this.session.PlotDatasetTable)
                        this.session.PlotDatasetTable{1,1} = num2str(plotContent.plotIndex);
                        this.session.PlotDatasetTable{1,2} = plotContent.content;
                        this.session.PlotDatasetTable{1,3} = plotContent.content;
                    else
                        dataName = string(this.session.PlotDatasetTable(:,2));
                        idx = dataName == plotContent.content;
                        if addTF
                            this.session.PlotDatasetTable{idx,1} = num2str(plotContent.plotIndex);
                        else
                            this.session.PlotDatasetTable{idx,1} = '';
                        end
                    end

                otherwise
                    disp('Unhandled plotContent.type %s', plotContent.type);
            end
            % TODO: keep this for debugging.
            % this.session.PlotSpeciesTable
            % this.session.PlotDatasetTable
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
                case 'PopulationSimulationProfileNotes'
                    assert(plotExport.Run <= numel(this.session.PopProfileNotes));
                    this.session.PopProfileNotes(plotExport.Run).Export = plotExport.Export;
                case 'DataFittingProfileNotes'
                    % This option is not enabled yet bc previous version
                    % did not support ProfileNotes (i.e., multiple runs)
                    % for data fitting. Export in this case always exports
                    % the fitted parameter values for the only fit results
                    % available in session.
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
            this.session.saveVariant(char(newName), this.session.Task);
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
            OrderedVariants = this.session.SelectedVariants(this.session.SelectedVariantsOrder);            
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
            this.session.SelectedVariantNames = {this.session.SelectedVariants.Name};
        end

        function updateVariantOrder(this, variantOrder)

            % TODO: Keep these comments for debugging.
            % fprintf('Requesting order:\t')
            % fprintf('%s ', variantOrder.rows.Name);
            % fprintf('\n');
            % 
            % % selectedVariants and selectedVariantNames should not be
            % % changing
            % fprintf('SelectedVariantNames\t');
            % fprintf('%s ', string(this.session.SelectedVariantNames));
            % fprintf('\n');
            % 
            % fprintf('SelectedVariants\t');
            % fprintf('%s ', string({this.session.SelectedVariants.Name}));
            % fprintf('\n');
            % fprintf('\n');

            % Enhancement. Rather than hold on to the Variants, their
            % Names, and the order in different properties of session we
            % should just have the variants themselves and order them the
            % way we want. The old app kept the variant order fixed and
            % users specified a vector with the order they wanted;
            % SelectedVariants and SelectedVariantNames were never
            % reordered while SelectedVariantsOrder is used as an index
            % into those vectors. We'd like to keep both apps working so
            % lets keep this strategy.
            newOrder = string({variantOrder.rows.Name});
            origianlOrder = string(this.session.SelectedVariantNames);
            
            % Find the order that puts the original order into the new
            % order.
            idx = zeros(numel(newOrder), 1);
            for i=1:numel(newOrder)
                idx(i) = find(newOrder(i) == origianlOrder);
            end

            % fprintf('Calculated order:\t')
            % fprintf('%d ', idx);
            % fprintf('\n');

            this.session.SelectedVariantsOrder = idx;

            % fprintf('%s ', this.session.SelectedVariants(this.session.SelectedVariantsOrder).Name);
            % fprintf('\n');

            % Now we update the M(odel) state to reflect the new state of
            % applied variants. In addition to the active variants we
            % update the SelectedParams and the SimVariant. This is done
            % with the updateRestoreParameters. That function is used to
            % restore the parameter table to model defaults + applied
            % variants.
            this.updateRestoreParameters();

            % fprintf('%s ', this.session.SelectedVariants(this.session.SelectedVariantsOrder).Name);
            % fprintf('\n');
            % fprintf('\n');
            % fprintf('\n');
        end
        
        function updateDataFittingResponseMap(this, responseMap)
            this.session.ResponseMap{2} = responseMap.ResponseMap.ModelComponentName;
        end

        function updateDataFittingDoseMap(this, doseMap)
            this.session.DoseMap{2} = doseMap.DoseMap.DoseTarget;
        end
    
        function updateDatasetTable(this, dataSetTable)
            % Update all fields in the update dataSetTable struct.
            props = fields(dataSetTable);
            for i = 1:numel(props)
                propName = props{i};
                switch propName
                    case 'Time'                        
                        this.session.DatasetTable.(propName) = dataSetTable.(propName);
                    case 'Group'
                        this.session.DatasetTable.(propName) = dataSetTable.(propName);
                        % TODO: This may be overkill (instead update only the
                        % field were the groups are split. We could also
                        % just move the splitting of data into the UI.                        
                        notifyUI(this, 'updateDataset');
                    case 'Dose'
                        this.session.DatasetTable.Dosing = dataSetTable.(propName);
                        if isempty(this.session.DoseMap)
                            this.session.DoseMap = cell(1,2);
                        end
                        this.session.DoseMap{1} = dataSetTable.(propName);

                    case 'Response'
                        this.session.DatasetTable.Concentration = dataSetTable.(propName);
                        if isempty(this.session.ResponseMap)
                            this.session.ResponseMap = cell(1,2);
                        end
                        this.session.ResponseMap{1} = dataSetTable.(propName);
                    otherwise
                        error('Unknown option');
                end
            end
        end    
    
        function updateParameterFlagFit(this, fit)
            paramTF = string({this.session.SelectedParams.Name}).matches(fit.parameter);
            this.session.SelectedParams(paramTF).FlagFit = fit.flagFit;            
        end

        function updateFitFunctionName(this, fitFunctionName)
            this.session.FitFunctionName = fitFunctionName.fitFunctionName;
        end
    end

    % Menu item callbacks.
    methods(Access=private)    
        function menuOpenSession(this, projectPath)                        
            if isempty(projectPath)
                lastPath = getpref(this.PreferencesName, 'LastPath');
                [fileName, location] = uigetfile({'*.mat'}, "Open", lastPath);
                if ischar(fileName) && ischar(location)
                    if ~strcmp(lastPath, location)
                        setpref(this.PreferencesName, 'LastPath', location);
                    end
                    selectedDirOrFile = [location, fileName];
                else
                    % User likely cancelled the open dialog.
                    return
                end
            else
                % This came from the UI with a recent file name.
                selectedDirOrFile = projectPath.sessionData;
                if ~isfile(selectedDirOrFile)
                    warning('Must provide a filename');
                    return
                end
            end
            
            this.loadProject(selectedDirOrFile);
        end

        function menuOpenCaseStudy(this, caseStudyNumber)
            this.loadCaseStudy(caseStudyNumber);
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

        function menuExportSimToMATLABFigure(this, ~)
            this.session.plotSimulationResults();
        end

        function menuExportPopulationSimToMATLABFigure(this, ~)
            this.session.plotPopulationSimulationResults();
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
            % TODO, need to make sure this is on the path after
            % installation.
            web('gPKPDSimUserGuide.html');
        end

        function menuImportDataset(this, ~)
            % This function is used by the new UI to load new datasets. If
            % a dataset was saved with a Session (aka project) then all
            % dataset related information is saved with the project and
            % this code is not used.
            Spec = {'*.xlsx;*.xls;*.csv'};
            Title = 'Open Dataset';
            DataPath = getpref(this.PreferencesName, 'DataPath');
            [FileName, PathName] = uigetfile(Spec,Title,DataPath);
            FilePath = fullfile(PathName,FileName);

            % Make a new PKPD.Dataset
            this.session.DatasetTable = PKPD.Dataset;

            % TODO: Don't store paths on the session object.
            this.session.DatasetTable.FilePath = FilePath;

            rawData = readtable(FilePath);

            if ~isempty(rawData)
                this.session.DatasetTable.Headers = rawData.Properties.VariableNames;
            else
                % This should be an error.
                error('Error loading %s', FilePath);
            end

            % Remove excluded data
            if ismember(this.session.DatasetTable.Headers, 'Include')
              if isstring(rawData.Include)
                  idx = rawData.Include == "C";
                  rawData = rawData(~idx, :);
              end
            end

            this.session.DataToFit = rawData;

            % Store the name of the dataset as the filename. 
            [~, Name] = fileparts(FileName);
            this.session.DatasetTable.Name = Name;            

            % Reuse as much as possible of old code to avoid datatype
            % issues loading sessions (aka PKPD.Analysis objects).
            % this.session.importData(this.session.DatasetTable, false); %NCA is false

            setpref(this.PreferencesName, 'DataPath', PathName);
            this.notifyUI('updateDataset');
        end
        
        function menuSave(this, ~)
            this.saveProject(this.projectPath);            
        end

        function menuSaveAs(this, ~)
            fullFileName = this.getFilePathAndSavePreference({'*.mat'});
            
            if ~isempty(fullFileName)
                this.saveProject(fullFileName);
            end
        end

        function menuQuit(this, ~)
            s = "OK";
            if this.projectName.startsWith('casestudy') && this.projectName.endsWith('_final')
                delete(this.app)
            elseif this.SessionDirtyState                
                s = uiconfirm(this.app.gPKPDSimUIFigure, 'There are unsaved changes. Close gPKPDSim?', "quit");
            end

            if strcmp(s, "OK")
                delete(this.app);
            end
        end
    end

    % These methods are used to marshall data from the Model (backend) to
    % the UI (frontend).
    methods (Access=private)
        function simulationResults = getSimulationResults(this)
            if ~isempty(this.session.SimProfileNotes)
                simProfileNotes = arrayfun(@(x)struct(x), this.session.SimProfileNotes);
                simulationResults = struct2table(simProfileNotes, "AsArray", true);
                simulationResults.Color = PKPD.controller.rgb2hex(simulationResults.Color);
                simulationResults.Run = (1:height(simulationResults))';

                try
                    simulationResults.ParametersTable = cell2table(simulationResults.ParametersTable, 'VariableNames', ["Name", "Value"]);
                catch
                    simulationResults.ParametersTable = cellfun(@(x)cell2table(x, 'VariableNames', ["Name", "Value"]), simulationResults.ParametersTable, UniformOutput=false);
                end
                
                dosingTable_VariableNames = ["DoseName", "Type", "Target", "StartTime", "TimeUnits", "Amount", "AmountUnits", "Interval", "Rate", "RepeatCount"];

                if size(simulationResults.DosingTable,2) ~= 1
                    for j = 1:height(simulationResults)
                        tmp(j) = {simulationResults.DosingTable(j,:)};
                    end
                    simulationResults.DosingTable = tmp';
                end

                for j = 1:height(simulationResults)
                    dosingTable_j = simulationResults.DosingTable{j};
                    if ~isempty(dosingTable_j)
                        simulationResults.DosingTable{j} = cell2table(dosingTable_j, VariableNames=dosingTable_VariableNames);
                    else
                        simulationResults.DosingTable{j} = {};
                    end
                end                    

                simData = this.session.SimData;
                fixedDataNames = PKPD.controller.getFixedDataNames(simData);
                simData = struct(simData);

                for i = 1:numel(simData)
                    simData(i).DataNames = fixedDataNames;
                    simData(i).Data = simData(i).Data'; % this this orientation for proper data marshall to JS                    
                end

                fieldsToKeep = ["Data", "DataNames", "Time"];
                simData = rmfield(simData, setdiff(fields(simData), fieldsToKeep));
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
                
                dosingTable_VariableNames = ["DoseName", "Type", "Target", "StartTime", "TimeUnits", "Amount", "AmountUnits", "Interval", "Rate", "RepeatCount"];
                if size(populationSimulationResults.DosingTable,2) ~= 1
                    for j = 1:height(populationSimulationResults)
                        tmp(j) = {populationSimulationResults.DosingTable(j,:)};
                    end
                    populationSimulationResults.DosingTable = tmp';
                end

                for j = 1:height(populationSimulationResults)
                    dosingTable_j = populationSimulationResults.DosingTable{j};
                    if ~isempty(dosingTable_j)
                        populationSimulationResults.DosingTable{j} = cell2table(dosingTable_j, VariableNames=dosingTable_VariableNames);
                    else
                        populationSimulationResults.DosingTable{j} = {};
                    end
                end

                for i = 1:size(this.session.PopSummaryData, 1)
                    thisRun = this.session.PopSummaryData(i,:);
                    popSimData(i).DataNames = this.getFixedNamesFromStrings(string({thisRun.Name}));
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
        
        function fitFunctionOptions = getFitFunctionOptions(this)
            fitFunctionOptions = table(string(this.session.FitFunctionOptions), 'VariableNames', "FitFunctions");
        end

        function dataFittingResults = getDataFittingResults(this)
            if ~isempty(this.session.FitResults)
                dataFittingProfileNotes = arrayfun(@(x)struct(x), this.session.FitResults);
                fieldsToKeep = ["ParameterEstimates", "MSE", "SSE", "LogLikelihood", "AIC", "BIC", "DFE", "FitType"];
                dataFittingProfileNotes = rmfield(dataFittingProfileNotes, setdiff(fields(dataFittingProfileNotes), fieldsToKeep));
                dataFittingResults = struct2table(dataFittingProfileNotes, "AsArray", true);

                % We only support having one datafitting results.
                assert(height(dataFittingResults) == 1);

                dataFittingResults.Run = (1:height(dataFittingResults))';
                dataFittingResults.Show = true;

                % Since we only support one DataFittingResults, all the
                % simdatas in FitSimData are for the same results
                fitSimData = this.session.FitSimData;
                fixedDataNames = PKPD.controller.getFixedDataNames(fitSimData);
                fitSimData = struct(fitSimData);

                fieldsToKeep = ["Data", "DataNames", "Time"];
                fitSimData = rmfield(fitSimData, setdiff(fields(fitSimData), fieldsToKeep));
                for i = 1:numel(fitSimData)
                    fitSimData(i).Data = fitSimData(i).Data';
                    fitSimData(i).DataNames = fixedDataNames;
                    % TODO: need to clean this up. There probably should
                    % always be group colors if there is a dataset loaded
                    % with colors.
                    if isempty(this.session.GroupColors)
                        cm = this.session.ColorMap1;
                        groupColor = cm(i,:);
                    else
                        groupColor = this.session.GroupColors(i,:);
                    end

                    fitSimData(i).Color = PKPD.controller.rgb2hex(groupColor);
                    fitSimData(i).Group = i;
                end
                dataFittingResults.Data = fitSimData';
            else
                dataFittingResults = [];
            end
        end
        
        function parameters = getParameters(this)
            parameters = arrayfun(@(x)struct(x), this.session.SelectedParams);
            parameters = struct2table(parameters, 'AsArray', true);
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
        
        function dataSet = getDataset(this)
            dataSet.Meta = struct(this.session.DatasetTable);
            dataSet.Meta.GroupColors = PKPD.controller.rgb2hex(this.session.GroupColors);

            if isa(this.session.DataToFit, 'dataset')
                dataSet.Data = dataset2table(this.session.DataToFit);
            else
                dataSet.Data = this.session.DataToFit;
            end

            % Send the time-course split by group.
            dataSet = splitByGroup(this, dataSet);
        end

        function dataSet = splitByGroup(this, dataSet)
            groupLabel = dataSet.Meta.Group;
            if ~isempty(groupLabel)
                groups = unique(dataSet.Data.(groupLabel));
                for i = 1:numel(groups)
                    group_i_tf = dataSet.Data.(groupLabel) == i;
                    dataSet.GroupData{i} = dataSet.Data(group_i_tf,:);
                end
            end
        end

        function responseMap = getDataFittingResponseMap(this)
            responseMap = cell2table(this.session.ResponseMap, 'VariableNames', ["DataName", "ModelComponentName"]);
        end

        function doseMap = getDataFittingDoseMap(this)
            doseMap = cell2table(this.session.DoseMap, 'VariableNames', ["DataName", "DoseTarget"]);
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
    
        function fixedNames = getFixedDataNames(simData)

            assert(simData.IsHomogeneous, "Internal error. Heterogeneous simdata array found.");
            firstSimData = simData(1);

            for j = 1:numel(firstSimData.DataInfo)
                currentCompartmentName = firstSimData.DataInfo{j}.Compartment;
                currentStateName = firstSimData.DataInfo{j}.Name;

                if ~isvarname(currentCompartmentName)
                    currentCompartmentName = "[" + currentCompartmentName + "]";
                end

                if ~isvarname(currentStateName)
                    currentStateName = "[" + currentStateName + "]";
                end

                fixedNames(j) = currentCompartmentName + "." + currentStateName;
            end

            OneCpt_TF = isscalar(unique(fixedNames.extractBefore(".")));
            if OneCpt_TF
                fixedNames = fixedNames.extractAfter(".");
            end
        end

        function fixedNames = getFixedNamesFromStrings(names)
            for j = 1:numel(names)
                if ~isvarname(names(j)) && ~names(j).startsWith("[")
                    fixedNames(j) = "[" + names(j) + "]";
                else
                    fixedNames(j) = names(j);
                end
            end
        end
    end
end
