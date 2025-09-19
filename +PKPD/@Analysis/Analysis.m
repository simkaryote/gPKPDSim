classdef Analysis < handle & UIUtilities.ConstructorAcceptsPVPairs
    % Analysis - Defines a complete analysis
    % ---------------------------------------------------------------------
    % Abstract: This object defines a complete analysis setup
    %
    % Syntax:
    %           obj = PKPD.Analysis
    %           obj = PKPD.Analysis('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % PKPD.Analysis Properties:
    %
    %    SelectedPlotLayout - Plot layout (one of PlotLayoutOptions)
    %
    %    Task - Current task (Simulation, Fitting, or Population)
    %
    %    SelectedSpecies - Selected species of interest
    %
    %    SelectedParams - Selected parameters of interest
    % 
    %    SelectedDoses - Selected doses of interest
    %
    %    SelectedVariantNames - Selected variant names of interest
    %
    %    SelectedVariantsOrder - Selected variants of interest
    %
    %    SelectedVariants - Selected variants of interest
    %
    %    DatasetTable - Imported dataset
    %
    %    StartTime - Simulation start time
    %
    %    TimeStep - Simulation time step
    %
    %    StopTime - Simulation end time
    %
    %    SimVariant - SimBiology variant for simulation task
    %
    %    FitVariant - SimBiology variant for fitting task
    %
    %    FitFunctionName - Fitting function (One of FitFunctionOptions)
    %
    %    UseFitBounds - Flag to use bounds in fitting
    %
    %    FitErrorModel - Error model for fitting (One of
    %    FitErrorModelOptions)
    %
    %    DoseMap - Dose map for performing fitting
    %
    %    ResponseMap - Response map for performing fitting
    %
    %    UsePooledFitting - Flag to use pooled fitting
    %
    %    NumPopulationRuns - Number of simulations in a population analysis
    %
    %    SimData - Array of simDataObj capturing simulation run data from
    %    sbiosimulate
    %
    %    FitResults - Results from fitting (sbiofit - 1st output)
    %
    %    FitTaskResults - Summary of results from fitting
    %
    %    FitSimData - SimData from fitting (sbiofit - 2nd output)
    %
    %    PopSummaryData - PKPD.PopulationSummary from population task
    %
    %    SimProfileNotes - Profile notes for simulation task
    %
    %    PopProfileNotes - Profile notes for population task
    %
    %    PlotDatasetTable - Table for configuring plotting of dataset
    %
    %    PlotGroupNames - Group names for Group table
    %
    %    SelectedGroups - Selected groups of interest
    %
    %    PlotSpeciesTable - Table for configuring plotting of species
    %
    %    FlagSimOverlay - Flag to overlay multiple simulation runs
    %
    %    FlagPopOverlay - Flag to overlay multiple population runs
    %
    %    SimulationPlotSettings - Summary of plot settings for Simulation
    %
    %    FittingPlotSettings - Summary of plot settings for Fitting
    %
    %    PopulationPlotSettings - Summary of plot settings for Population
    %
    %    ColorMap1 - First colormap
    %
    %    ColorMap2 - Second colormap
    %
    %    LineStyleMap - Map for setting line styles
    %
    %    FlagComputeNCA - Flag to compute NCA
    %
    %    NCAParameters - Results of NCA analysis
    %
    %    FlagDebug - Flag to turn on/off debugging
    %
    %
    % PKPD.Analysis Methods:
    %
    %
    
    % Copyright 2017 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 420 $  $Date: 2017-12-07 14:47:44 -0500 (Thu, 07 Dec 2017) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties
        % Layout
        SelectedPlotLayout = '1x1' % Default plot layout
        
        % Task
        Task = 'Simulation'
        
        % General
        SelectedSpecies
        SelectedParams = PKPD.Parameter.empty(0,1)
        SelectedDoses
        SelectedVariantNames = {}       
        SelectedVariantsOrder
        SelectedVariants
        
        % Dataset
        DatasetTable = PKPD.Dataset;
        
        % Simulation
        StartTime = 0
        TimeStep = 0.1
        StopTime = 100
        SimVariant
        
        % Fitting
        FitVariant
        FitFunctionName = 'nlinfit'
        UseFitBounds = false
        FitErrorModel = 'constant'
        DoseMap = cell(0,2)
        ResponseMap = cell(0,2)
        UsePooledFitting = true
        
        % Population
        NumPopulationRuns = 1000 %Number of population runs
        
        % Simulation/Fitting/Population results
        SimData = []
        FitResults = []
        FitTaskResults 
        FitSimData = []
        
        PopSummaryData = PKPD.PopulationSummary.empty(0,0)
        
        % Profile Notes
        SimProfileNotes = PKPD.Profile.empty(0,1)
        PopProfileNotes = PKPD.Profile.empty(0,1)
        
        % Settings
        PlotDatasetTable = {}
        PlotGroupNames = {}
        SelectedGroups = false(1,0)
        PlotSpeciesTable = {}
        FlagSimOverlay = false
        FlagPopOverlay = false
        
        SimulationPlotSettings = struct
        FittingPlotSettings = struct
        PopulationPlotSettings = struct
        
        % Colormaps
        ColorMap1
        ColorMap2
        LineStyleMap = {...
            '-',...
            '--',...
            ':',...
            '-.',...
            }
        
        % NCA
        FlagComputeNCA = true
        NCAParameters = table
        
        % DEBUG
        FlagDebug = true
        
        % In version 2 we will prevent the backend code from showing any UI
        % elements such as dialog boxes etc.
        useUI = true;
    end
        
        
    %% Private Properties
    properties(SetAccess = 'private')
        ProjectPath % Path to project file
        ModelName % Name of project file
        ModelObj % Model obj    
        SpeciesLineStyles
        SimRunColors
        PopRunColors
        GroupColors

        % Model documentation in HTML (loaded from a file)
        ModelReport = ''
    end

    properties (SetAccess = 'public')
        DataToFit
    end
        
    %% Private Dependent Properties
    properties(SetAccess = 'private',Dependent=true)
        Species
        Doses
        Parameters
        Variants                
        ConfigSet
    end
    
    %% Constant properties - Public
    % These properties are constant values that may be needed by the class
    % methods.
    properties (Constant=true, GetAccess=public)   
        MaxNumRuns = 1000
        SimVariantName = 'SIMULATION_IN_APP'
        FitVariantName = 'FITTING_IN_APP'
        ValidTasks = {...
            'Simulation',...
            'Fitting',...
            'Population',...
            }
        FitFunctionOptions = {....
            'nlinfit' % (Statistics and Machine Learning Toolbox is required.)
            'fminunc' % (Optimization Toolbox is required.)
            'fmincon' % (Optimization Toolbox is required.)
            'fminsearch' % (Optimization Toolbox is required.)
            'lsqcurvefit' % (Optimization Toolbox is required.)
            'lsqnonlin' % (Optimization Toolbox is required.)
            'patternsearch' % (Global Optimization Toolbox is required.)
            'ga' % (Global Optimization Toolbox is required.)
            'particleswarm' % (Global Optimization Toolbox is required.)
            }
        FitErrorModelOptions = {...
            'constant',...
            'proportional',...
            'combined',...
            'exponential',...            
            }    
        NCADosingTypes = {...
            'None',...
            'IV',...
            'SC'};
        PlotLayoutOptions = {'1x1','2x1','2x2','3x2'}
    end
    
    %% Constructor
    methods
        function obj = Analysis(varargin)
            % Analysis - Constructor for PKPD.Analysis
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new PKPD.Analysis object.
            %
            % Syntax:
            %           obj = PKPD.Analysis('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - PKPD.Analysis object
            %
            % Example:
            %    aObj = PKPD.Analysis();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
        end %function obj = Analysis(varargin)
        
    end %methods
    
    
    %% Get Methods
    methods
        
        function Value = get.Species(obj)
            if ~isempty(obj.ModelObj)
                Value = obj.ModelObj.Species;
            else
                Value = [];
            end
        end
        
        function Value = get.Doses(obj)
            if ~isempty(obj.ModelObj)
                Value = getdose(obj.ModelObj);
            else
                Value = [];
            end
        end
        
        function Value = get.Parameters(obj)
            if ~isempty(obj.ModelObj)
                Value = obj.ModelObj.Parameters;
            else
                Value = [];
            end
        end
        
        function Value = get.Variants(obj)
            if ~isempty(obj.ModelObj)
                Value = getvariant(obj.ModelObj);
            else
                Value = [];
            end
        end
        
        function Value = get.ConfigSet(obj)
            if ~isempty(obj.ModelObj)
                Value = getconfigset(obj.ModelObj,'active');
            else
                Value = [];
            end
        end
        
    end %methods
    
    
    %% Methods
    methods
        
        function [StatusOk,Message] = importModel(obj,ProjectPath,ModelName)
            
            % Defaults
            StatusOk = true;
            Message = '';
            
            % Load project
            AllModels = struct2cell(sbioloadproject(ProjectPath));
            AllModels = [AllModels{:}]; 
            m1 = sbioselect(AllModels,'Name',ModelName,'type','sbiomodel') ; 

            if isempty(m1)
                StatusOk = false;
                Message = sprintf('Model %s not found in project',ModelName);
            else
                obj.ModelObj = m1;
                obj.ProjectPath = ProjectPath;
                obj.ModelName = ModelName;                      
            end
        end %function

        function importModelReport(obj, reportPath)
            arguments
                obj (1,1)
                reportPath (1,1) string 
            end

            fid = fopen(reportPath, "r");
            if fid == -1
                error('Failed to open the model report file: %s', reportPath);
            end
            cleanupObj = onCleanup(@()fclose(fid));
            textData = textscan(fid, "%s", 'Delimiter', '\n');
            obj.ModelReport = strjoin(textData{1}, newline);
        end        
        
        function importData(obj,DatasetTable,FlagComputeNCA)
            % Assign
            obj.DatasetTable = DatasetTable;
            obj.FlagComputeNCA = FlagComputeNCA;
            
            DependentVariable = DatasetTable.YAxis;
            
            Table = readtable(DatasetTable.FilePath);
            
            % Filter out any 'C' in Include option, if it exists
            MatchInclude = strcmp(Table.Properties.VariableNames,'Include');
            if any(MatchInclude)
                % Must be a cell array
                if iscell(Table.Include)
                    MatchC = strcmpi(Table.Include,'C');
                    Table = Table(~MatchC,:);
                end
            end
                        
            dataToFit = table2dataset(Table);
            
            % Convert all to numeric
            FieldNames = properties(dataToFit);
            for index = 1:numel(FieldNames)
                if iscell(dataToFit.(FieldNames{index}))
                    dataToFit.(FieldNames{index}) = categorical(dataToFit.(FieldNames{index})); %cellfun(@str2double,dataToFit.(FieldNames{index}));
                end
            end
            
            % Response map
            responseMap = cell(numel(DependentVariable),2);
            responseMap(:,1) = DependentVariable;
            obj.ResponseMap = responseMap;
            
            % Dose map
            doseMap = cell(numel(DatasetTable.Dosing),2);
            doseMap(:,1) = DatasetTable.Dosing;
            obj.DoseMap = doseMap;
            
            % Data to fit
            obj.DataToFit = dataToFit;
            
            % Only displayed selected Y-Axis fields for dataset table
            SelectedFields = DatasetTable.YAxis;
            
            obj.PlotDatasetTable = cell(numel(SelectedFields),3);
            obj.PlotDatasetTable(:,2) = SelectedFields;
            obj.PlotDatasetTable(:,3) = SelectedFields;
            
            % Update groupcolors 
            if numel(obj.DatasetTable.Group) > 0
                updateGroupColors(obj);
            end
            
            if ~isempty(obj.DataToFit) && ~isempty(DatasetTable.Group)
                UniqueGroups = unique(categorical(obj.DataToFit.(DatasetTable.Group)),'stable');
                obj.PlotGroupNames = cellfun(@(x)char(x),num2cell(UniqueGroups(:)),'UniformOutput',false);
                obj.SelectedGroups = true(1,numel(obj.PlotGroupNames));
            end
            
            % Compute NCA
            if obj.FlagComputeNCA
                options = sbioncaoptions;
                options.independentVariableColumnName = matlab.lang.makeValidName(DatasetTable.Time);
                options.groupColumnName = matlab.lang.makeValidName(DatasetTable.Group);
                
                options.SparseData = DatasetTable.Sparse;  
                % If serial (not sparse), use dose column name (subgroup or
                % second-level identifier)
                if DatasetTable.Sparse || strcmpi(DatasetTable.Subgroup,'Unspecified')
                    options.idColumnName = '';
                else
                    options.idColumnName = matlab.lang.makeValidName(DatasetTable.Subgroup);
                end
                
                % IV Dose column name, SC Dose column name, concentration
                % name
                if strcmpi(DatasetTable.IVDose,'Unspecified')
                    options.IVDoseColumnName = '';
                else
                    options.IVDoseColumnName = matlab.lang.makeValidName(DatasetTable.IVDose);
                end
                if strcmpi(DatasetTable.SCDose,'Unspecified')
                    options.EVDoseColumnName = '';
                else
                    options.EVDoseColumnName = matlab.lang.makeValidName(DatasetTable.SCDose);
                end
                if strcmpi(DatasetTable.Concentration,'Unspecified')
                    options.concentrationColumnName = '';
                else
                    options.concentrationColumnName = matlab.lang.makeValidName(DatasetTable.Concentration);
                end
                                
                % Partial areas
                options.PartialAreas = num2cell(DatasetTable.AUCTimePoints,2); % Either empty or one for ALL groups
                options.PartialAreas = options.PartialAreas(:)';
                
                % CMax
                options.C_max_ranges = num2cell(DatasetTable.CmaxTimePoints,2); % Either empty or one for ALL groups
                options.C_max_ranges = options.C_max_ranges(:)';
                
                % Half-life
                if ~DatasetTable.AutomaticHalfLifeEstimation && ~isempty(DatasetTable.HalfLifeEstimationTimePoints)
                    options.Lambda_Z_Time_Min_Max = DatasetTable.HalfLifeEstimationTimePoints;
                else
                    options.Lambda_Z_Time_Min_Max = [NaN NaN];
                end
                
                try
                    [obj.NCAParameters,ThisMessage] = sbionca(dataset2table(dataToFit), options);
                    if ~isempty(ThisMessage)
                        if iscell(ThisMessage)
                            ThisMessage = cellstr2dlmstr(ThisMessage,'\n');
                        end
                        hDlg = msgbox(sprintf('Unable to compute NCA parameters. Please validate dataset and import settings (particularly grouping variable).\n\n%s',ThisMessage),'NCA error','modal');
                        uiwait(hDlg);
                    end
                    
                catch ME
                    hDlg = errordlg(sprintf('Internal Error: Unable to compute NCA parameters. Please validate dataset and import settings (particularly grouping variable).\n\n%s',ME.message),'NCA error','modal');
                    uiwait(hDlg);
                end
            else
                obj.NCAParameters = table;
            end
                
            
        end %function
        
        
        function updateSelectedVariants(obj)
            if ~isempty(obj.ModelObj) && ...                    
                    ~isequal(numel(obj.SelectedVariants),numel(obj.SelectedVariantNames))
                Var = getvariant(obj.ModelObj);
                for index = 1:numel(Var)
                    VarCopy(index) = sbiovariant(Var(index).Name); %#ok<AGROW>
                    addcontent(VarCopy(index),Var(index).Content);
                end
                
                VariantNames = get(Var,'Name');
                [~,Loc] = ismember(obj.SelectedVariantNames,VariantNames);
                obj.SelectedVariants = VarCopy(Loc);
            elseif isempty(obj.ModelObj) || isempty(obj.SelectedVariantNames)
                obj.SelectedVariants = [];                
            end
        end %function

        
        function applyToFitVariant(obj)
            % Assign FitVal to Value
            for index = 1:numel(obj.SelectedParams)
                if obj.SelectedParams(index).Value < obj.SelectedParams(index).Min
                    warning('Updating minimum bound for %s',obj.SelectedParams(index).Name);
                    obj.SelectedParams(index).Min = obj.SelectedParams(index).Value;
                end
                if obj.SelectedParams(index).Value > obj.SelectedParams(index).Max
                    warning('Updating maximum bound for %s',obj.SelectedParams(index).Name);
                    obj.SelectedParams(index).Max = obj.SelectedParams(index).Value;
                end
            end
            % Update fit variant
            updateFitVariant(obj);
            
        end %function
       
        
        function updateSimVariant(obj)
            % Create a sbiovariant if it does not exist and apply
            if ~isempty(obj.SimVariant)
                % Clear the variant's content
                rmcontent(obj.SimVariant,get(obj.SimVariant,'content'));                
            else
                % Create variant
                obj.SimVariant = sbiovariant(obj.SimVariantName);                                
            end
            
            % Loop through selected variants in order specified
            OrderedVariants = obj.SelectedVariants;
            OrderedVariants(obj.SelectedVariantsOrder) = obj.SelectedVariants;
            IsSelected = get(OrderedVariants,'Active');
            if iscell(IsSelected)
                IsSelected = cell2mat(IsSelected);
            end
            OrderedVariants = OrderedVariants(IsSelected);
            
            VariantContent = {};
            for index = 1:numel(OrderedVariants)
                VariantContent = [VariantContent; OrderedVariants(index).Content]; %#ok<AGROW>
            end
            VariantContent = vertcat(VariantContent{:});
            
            % Then update with overrides
            ParamContent = {};
            for index = 1:numel(obj.SelectedParams)
                ParamContent = [ParamContent;
                    {'parameter',obj.SelectedParams(index).Name,'Value',obj.SelectedParams(index).Value}]; %#ok<AGROW>
            end   
            
            % Concatenate and remove duplicates
            Content = [VariantContent;ParamContent];
            if ~isempty(Content)
                [~,MatchIndex] = unique(Content(:,2),'last');
                Content = Content(MatchIndex,:);
                
                % Add to sim variant
                addcontent(obj.SimVariant,num2cell(Content,2));
            end
        end %function
        
        
        function updateFitVariant(obj)
            
            FlagFit = [obj.SelectedParams.FlagFit];
            FitIdx = find(FlagFit);
            if ~isempty(FitIdx)
                % Use the first to get the number of fit variants (> 1 if
                % unpooled)
                NumFitVariants = size(obj.SelectedParams(FitIdx(1)).FittedVal,1);
            else
                NumFitVariants = 1;
            end            
            
            % Create a sbiovariant if it does not exist and apply
            if ~isempty(obj.FitVariant)
                % Clear the variant's content
                for iVar = 1:numel(obj.FitVariant)
                    rmcontent(obj.FitVariant(iVar),get(obj.FitVariant(iVar),'content'));                
                end
                if numel(obj.FitVariant) < NumFitVariants
                    FitVarNames = repmat({obj.FitVariantName},1,NumFitVariants);
                    FitVarNames = matlab.lang.makeUniqueStrings(FitVarNames);                    
                    % Create empty variants for remainder up to
                    % NumFitVariants
                    for iVar = (numel(obj.FitVariant)+1):NumFitVariants    
                        obj.FitVariant(iVar) = sbiovariant(FitVarNames{iVar});
                    end
                elseif NumFitVariants < numel(obj.FitVariant)
                    obj.FitVariant = obj.FitVariant(1:NumFitVariants);                    
                end
            else
                % Create variant
                FitVarNames = repmat({obj.FitVariantName},1,NumFitVariants);
                FitVarNames = matlab.lang.makeUniqueStrings(FitVarNames);
                for iVar = 1:NumFitVariants
                    if iVar == 1
                        obj.FitVariant = sbiovariant(FitVarNames{iVar});
                    else
                        obj.FitVariant(iVar) = sbiovariant(FitVarNames{iVar});     
                    end
                end
            end
            
            % Loop through selected variants in order specified
            OrderedVariants = obj.SelectedVariants;
            OrderedVariants(obj.SelectedVariantsOrder) = obj.SelectedVariants;
            IsSelected = get(OrderedVariants,'Active');
            if iscell(IsSelected)
                IsSelected = cell2mat(IsSelected);
            end
            OrderedVariants = OrderedVariants(IsSelected);
            
            VariantContent = {};
            for index = 1:numel(OrderedVariants)
                VariantContent = [VariantContent; OrderedVariants(index).Content]; %#ok<AGROW>
            end
            VariantContent = vertcat(VariantContent{:});
            
            for iVar = 1:NumFitVariants
                % Then update with overrides
                ParamContent = {};
                for index = 1:numel(obj.SelectedParams)
                    if obj.SelectedParams(index).FlagFit && ~isempty(obj.SelectedParams(index).FittedVal) && ~isnan(obj.SelectedParams(index).FittedVal(iVar,1))
                        ParamContent = [ParamContent;
                            {'parameter',obj.SelectedParams(index).Name,'Value',obj.SelectedParams(index).FittedVal(iVar,1)}]; %#ok<AGROW>
                    else
                        ParamContent = [ParamContent;
                            {'parameter',obj.SelectedParams(index).Name,'Value',obj.SelectedParams(index).Value}]; %#ok<AGROW>
                    end
                end
                
                % Concatenate and remove duplicates
                Content = [VariantContent;ParamContent];
                if ~isempty(Content)
                    [~,MatchIndex] = unique(Content(:,2),'last');
                    Content = Content(MatchIndex,:);
                    
                    % Add to fit variant
                    addcontent(obj.FitVariant(iVar),num2cell(Content,2));
                end
            end
        end %function
        
        
        function ActiveDoses = getActiveSelectedDoses(obj)
            IsDoseSelected = get(obj.SelectedDoses,'Active');
            if iscell(IsDoseSelected)
                IsDoseSelected = cell2mat(IsDoseSelected);
            end
            ActiveDoses = obj.SelectedDoses(IsDoseSelected);
        end %function
        
        
        function OrderedVariants = getActiveOrderedVariants(obj)
            % Loop through selected variants in order specified
            OrderedVariants = obj.SelectedVariants;
            OrderedVariants(obj.SelectedVariantsOrder) = obj.SelectedVariants;
            IsSelected = get(OrderedVariants,'Active');
            if iscell(IsSelected)
                IsSelected = cell2mat(IsSelected);
            end
            OrderedVariants = OrderedVariants(IsSelected);
            
        end %function
        
        
        function saveVariant(obj,Name,varargin)
            if nargin > 2 && ischar(varargin{1})
                switch(varargin{1})
                    case 'Fitting'
                        ThisType = 'fit';
                    case {'Simulation', 'Population'}
                        ThisType = 'sim';
                    otherwise
                        error('Unknown Task type');
                end
            else
                ThisType = 'sim';
            end
            
            if strcmpi(ThisType,'fit')
                ThisVariant = obj.FitVariant;                
            else
                ThisVariant = obj.SimVariant;
            end
                
            Names = repmat({Name},1,numel(ThisVariant));
            Names = matlab.lang.makeUniqueStrings(Names);
            for index = 1:numel(ThisVariant)
                ThisVariantContent = get(ThisVariant(index),'content');
                
                SavedVariant = sbiovariant(Names{index});
                set(SavedVariant,'Tag','custom');
                addcontent(SavedVariant,ThisVariantContent);
                
                obj.SelectedVariantNames = [...
                    obj.SelectedVariantNames,Names{index}];
                obj.SelectedVariantsOrder = vertcat(obj.SelectedVariantsOrder(:),numel(obj.SelectedVariantNames));
                obj.SelectedVariants = vertcat(obj.SelectedVariants(:),SavedVariant);
            end
            
        end %function
        
        
        function removeVariant(obj,Index)
            obj.SelectedVariantNames(Index) = [];
            ThisOrder = obj.SelectedVariantsOrder(Index);
            
            obj.SelectedVariantsOrder(obj.SelectedVariantsOrder > ThisOrder) = ...
                obj.SelectedVariantsOrder(obj.SelectedVariantsOrder > ThisOrder) - 1;
            obj.SelectedVariantsOrder(Index) = [];
            
            obj.SelectedVariants(Index) = [];
        end
        
        
        function ParamInfo = getParamInfo(obj)
            
            if ~isempty(obj.SelectedParams)
                ParamInfo = ...
                    cell2struct([...
                    {obj.SelectedParams.Name}',...
                    {obj.SelectedParams.Value}',...
                    {obj.SelectedParams.Min}',...
                    {obj.SelectedParams.Max}',...
                    {obj.SelectedParams.Units}',...
                    {obj.SelectedParams.Scale}',...
                    {obj.SelectedParams.FlagFit}',...
                    {obj.SelectedParams.FittedVal}',...
                    {obj.SelectedParams.PercCV}',...
                    ],...
                    {'Name','Value','Min','Max','Units','Scale','FlagFit','FittedVal','PercCV'},2);
            else
                ParamInfo = {};
            end
            
        end %function
        
        
        function updateSpeciesLineStyles(obj)
            ThisMap = obj.LineStyleMap;
            if ~isempty(ThisMap) && size(obj.PlotSpeciesTable,1) ~= numel(obj.SpeciesLineStyles)
                obj.SpeciesLineStyles = GetLineStyleMap(ThisMap,size(obj.PlotSpeciesTable,1)); % Number of species
            end
            
        end %function
        
        
        function updateSimRunColors(obj)
            ThisColorMap = obj.ColorMap1;
            if ~isempty(ThisColorMap) && size(ThisColorMap,2) == 3
                obj.SimRunColors = GetColorMap(ThisColorMap,obj.MaxNumRuns); 
            else
                obj.SimRunColors = CustomColorMap1(obj.MaxNumRuns);
            end
        end %function
        
        
        function updatePopRunColors(obj)
            ThisColorMap = obj.ColorMap1;
            if ~isempty(ThisColorMap) && size(ThisColorMap,2) == 3
                obj.PopRunColors = GetColorMap(ThisColorMap,obj.MaxNumRuns); 
            else
                obj.PopRunColors = CustomColorMap1(obj.MaxNumRuns);
            end
        end %function
        
        
        function updateGroupColors(obj)
            ThisColorMap = obj.ColorMap2;
            if ~isempty(obj.DataToFit) && ~isempty(obj.DatasetTable.Group)
                GroupLabelFixed = matlab.lang.makeValidName(obj.DatasetTable.Group);
                UniqueGroups = unique(obj.DataToFit.(GroupLabelFixed),'stable');
            else
                UniqueGroups = {};
            end
            
            if ~isempty(ThisColorMap) && size(ThisColorMap,2) == 3
                obj.GroupColors = GetColorMap(ThisColorMap,numel(UniqueGroups));
            else
                obj.GroupColors = CustomColorMap2(numel(UniqueGroups)); % Number of unique groups
            end
            
        end %function
        
        
        function setSpeciesLineStyles(obj,Index,NewLineStyle)
            NewLineStyle = validatestring(NewLineStyle,obj.LineStyleMap);
            obj.SpeciesLineStyles{Index} = NewLineStyle;
        end %function
        
            
%         function setSimRunColors(obj,Index,NewColor)
%             validateattributes(NewColor,{'numeric'},{'size',[1 3]});
%             validateattributes(Index,{'numeric'},{'scalar','>=',1,'<=',size(obj.SimRunColors,1)});
%             obj.SimRunColors(Index,:) = NewColor;            
%         end %function
%         
%         
%         function setPopRunColors(obj,Index,NewColor)
%             validateattributes(NewColor,{'numeric'},{'size',[1 3]});
%             validateattributes(Index,{'numeric'},{'scalar','>=',1,'<=',size(obj.PopRunColors,1)});
%             obj.PopRunColors(Index,:) = NewColor;            
%         end %function
        
        
        function setGroupColors(obj,Index,NewColor)
            validateattributes(NewColor,{'numeric'},{'size',[1 3]});
            validateattributes(Index,{'numeric'},{'scalar','>=',1,'<=',size(obj.GroupColors,1)});
            obj.GroupColors(Index,:) = NewColor;            
        end %function
        
        
        function update(obj)
            if ~isempty(obj.ConfigSet)
                if ~isempty(obj.StopTime)
                    set(obj.ConfigSet,'StopTime',obj.StopTime);
                end
                if ~isempty(obj.StartTime) && ~isempty(obj.TimeStep) && ~isempty(obj.StopTime)
                    set(obj.ConfigSet.SolverOptions,'OutputTimes',obj.StartTime:obj.TimeStep:obj.StopTime);
                end
            end
        end %function        
        
    end %methods
    
    
    %% Set Methods
    methods
        
        function set.SelectedPlotLayout(obj,Value)
            % See no reason why we would constrain the layout (mxn) chosen
            % by a user. There could be some issues with the stored
            % plotIndex but that might not be something we care about. 
            % Value = validatestring(Value,obj.PlotLayoutOptions);
            obj.SelectedPlotLayout = Value;
        end
        
        function set.Task(obj,Value)
            % Validate the new Value is of the right type, then set it
            validateattributes(Value,{'char'},{'row'})
            ValidValue = obj.ValidTasks;
            if any(strcmp(Value,ValidValue))
                obj.Task = Value;
            else
                % The new Type was not on the list of supported types
                error('Invalid Task: ''%s''. Valid options are: {''%s''}',...
                    Value, cellstr2dlmstr(ValidValue,''', '''));
            end
        end
        
        function set.SelectedSpecies(obj,Value)
            if ~isempty(Value)
                validateattributes(Value,{'SimBiology.Species'},{});
            end
            obj.SelectedSpecies = Value; 
        end
        
        function set.SelectedParams(obj,Value)
            validateattributes(Value,{'PKPD.Parameter'},{});
            obj.SelectedParams = Value; 
        end
        
        function set.SelectedDoses(obj,Value)
            if ~isempty(Value)
                validateattributes(Value,{'SimBiology.Dose'},{});
            end
            obj.SelectedDoses = Value; 
        end
        
        function set.SelectedVariantNames(obj,Value)
            validateattributes(Value,{'cell'},{});
            obj.SelectedVariantNames = Value; 
        end
        
        function set.SelectedVariantsOrder(obj,Value)
            validateattributes(Value,{'numeric'},{});
            obj.SelectedVariantsOrder = Value; 
        end
        
        function set.SelectedVariants(obj,Value)
            if ~isempty(Value)
                validateattributes(Value,{'SimBiology.Variant'},{});
            end            
            obj.SelectedVariants = Value; 
        end
        
        function set.DatasetTable(obj,Value)
            validateattributes(Value,{'PKPD.Dataset'},{'scalar'});
            obj.DatasetTable = Value; 
        end
                
        function set.StartTime(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','nonnegative'})
            obj.StartTime = Value;
            update(obj);            
        end
        
        function set.TimeStep(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','nonnegative'})
            obj.TimeStep = Value;
            update(obj);
        end
        
        function set.StopTime(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','nonnegative'})
            obj.StopTime = Value;
            update(obj);
        end
        
        function set.SimVariant(obj,Value)
            if ~isempty(Value)
                validateattributes(Value,{'SimBiology.Variant'},{});
            end
            obj.SimVariant = Value;
        end
        
        function set.FitVariant(obj,Value)
            if ~isempty(Value)
                validateattributes(Value,{'SimBiology.Variant'},{});
            end
            obj.FitVariant = Value;
        end
        
        function set.FitFunctionName(obj,Value)
            % Validate the new Value is of the right type, then set it
            validateattributes(Value,{'char'},{'row'})
            ValidValue = obj.FitFunctionOptions;
            if any(strcmp(Value,ValidValue))
                switch Value
                    case {'fminunc','fmincon','fminsearch','lsqcurvefit','lsqnonlin'}
                        if isempty(ver('optim'))
                            warning('Optimization Toolbox may not be installed. Defaulting to nlinfit');
                            Value = 'nlinfit'; % Default
                        end
                    case {'patternserch','ga','particleswarm'}
                        if isempty(ver('globaloptim'))
                            warning('Optimization Toolbox may not be installed. Defaulting to nlinfit');
                            Value = 'nlinfit'; % Default
                        end
                end
                obj.FitFunctionName = Value;
            else
                % The new Type was not on the list of supported types
                error('Invalid FitFunctionName: ''%s''. Valid options are: {''%s''}',...
                    Value, cellstr2dlmstr(ValidValue,''', '''));
            end
        end
        
        function set.UseFitBounds(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'});
            obj.UseFitBounds = Value;
        end
        
        function set.FitErrorModel(obj,Value)
            % Validate the new Value is of the right type, then set it
            validateattributes(Value,{'char'},{'row'})
            ValidValue = obj.FitErrorModelOptions;
            if any(strcmp(Value,ValidValue))
                obj.FitErrorModel = Value;
            else
                % The new Type was not on the list of supported types
                error('Invalid FitErrorModel: ''%s''. Valid options are: {''%s''}',...
                    Value, cellstr2dlmstr(ValidValue,''', '''));
            end
        end
        
        function set.DoseMap(obj,Value)
            validateattributes(Value,{'cell'},{'size',[nan 2]})
            obj.DoseMap = Value;
        end
        
        function set.ResponseMap(obj,Value)
            validateattributes(Value,{'cell'},{'size',[nan 2]})
            obj.ResponseMap = Value;
        end
        
        function set.UsePooledFitting(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'});
            obj.UsePooledFitting = Value;
        end
        
        function set.NumPopulationRuns(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','positive'})
            obj.NumPopulationRuns = Value;
        end
        
        function set.SimData(obj,Value)
            if ~isempty(Value)
                validateattributes(Value,{'SimData'},{})
            end
            obj.SimData = Value;
        end
        
        function set.FitResults(obj,Value)            
            obj.FitResults = Value;
        end
        
        function set.FitTaskResults(obj,Value)            
            obj.FitTaskResults = Value;
        end
        
        function set.FitSimData(obj,Value)
            if ~isempty(Value)
                validateattributes(Value,{'SimData'},{})
            end
            obj.FitSimData = Value;
        end
        
        function set.PopSummaryData(obj,Value)
            validateattributes(Value,{'PKPD.PopulationSummary'},{})
            obj.PopSummaryData = Value;            
        end
        
        function set.SimProfileNotes(obj,Value)
            validateattributes(Value,{'PKPD.Profile'},{})
            obj.SimProfileNotes = Value;            
        end
               
        function set.PopProfileNotes(obj,Value)
            validateattributes(Value,{'PKPD.Profile'},{})
            obj.PopProfileNotes = Value;            
        end
        
        function set.PlotDatasetTable(obj,Value)
            validateattributes(Value,{'cell'},{})
            obj.PlotDatasetTable = Value;            
        end
        
        function set.PlotGroupNames(obj,Value)
            validateattributes(Value,{'cell'},{})
            obj.PlotGroupNames = Value;            
        end
        
        function set.SelectedGroups(obj,Value)
            validateattributes(Value,{'logical'},{})
            obj.SelectedGroups = Value;            
        end
        
        function set.PlotSpeciesTable(obj,Value)
            validateattributes(Value,{'cell'},{})
            obj.PlotSpeciesTable = Value;            
        end
        
        function set.FlagSimOverlay(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'});
            obj.FlagSimOverlay = Value;
        end
        
        function set.FlagPopOverlay(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'});
            obj.FlagPopOverlay = Value;
        end
        
        function set.SimulationPlotSettings(obj,Value)
            validateattributes(Value,{'struct'},{});
            obj.SimulationPlotSettings = Value;
        end
        
        function set.FittingPlotSettings(obj,Value)
            validateattributes(Value,{'struct'},{});
            obj.FittingPlotSettings = Value;
        end
        
        function set.PopulationPlotSettings(obj,Value)
            validateattributes(Value,{'struct'},{});
            obj.PopulationPlotSettings = Value;
        end
        
        function set.ColorMap1(obj,Value)
            validateattributes(Value,{'numeric'},{});
            obj.ColorMap1 = Value;
        end
        
        function set.ColorMap2(obj,Value)
            validateattributes(Value,{'numeric'},{});
            obj.ColorMap2 = Value;
        end
        
        function set.LineStyleMap(obj,Value)
            validateattributes(Value,{'cell'},{});
            obj.LineStyleMap = Value;
        end
        
        function set.FlagComputeNCA(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'})
            obj.FlagComputeNCA = Value;
        end
        
        function set.NCAParameters(obj,Value)
            validateattributes(Value,{'table'},{})
            obj.NCAParameters = Value;            
        end
        
        function set.FlagDebug(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'})
            obj.FlagDebug = Value;
        end
    end %methods
end %classdef
