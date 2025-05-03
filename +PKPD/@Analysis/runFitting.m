function [StatusOk,Message] = runFitting(obj)
    % runFitting - runs the fitting task
    % -------------------------------------------------------------------------
    % Abstract: This runs the fitting task.
    %
    % Syntax:
    %           [StatusOk,Message] = runFitting(obj)
    %
    % Inputs:
    %           obj - PKPD.Analysis object
    %
    % Outputs:
    %           StatusOk - Flag to indicate status
    %
    %           Message - Status description, populated if StatusOk is false
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

    StatusOk = true;
    Message = '';

    % Filter
    FilteredDoseMap = obj.DoseMap;
    FilteredResponseMap = obj.ResponseMap;

    % Keep the non-empty mappings
    if ~isempty(FilteredDoseMap)
        IsNonEmptyMapping = ~cellfun(@(x)isempty(strtrim(x)),FilteredDoseMap(:,2));
        FilteredDoseMap = FilteredDoseMap(IsNonEmptyMapping,:);
        FilteredDoseMap(:,1) = cellfun(@(x)matlab.lang.makeValidName(x),FilteredDoseMap(:,1),'UniformOutput',false);
    end
    if ~isempty(FilteredResponseMap)
        IsNonEmptyMapping = ~cellfun(@(x)isempty(strtrim(x)),FilteredResponseMap(:,2));
        FilteredResponseMap = FilteredResponseMap(IsNonEmptyMapping,:);
        FilteredResponseMap(:,1) = cellfun(@(x)matlab.lang.makeValidName(x),FilteredResponseMap(:,1),'UniformOutput',false);
    end

    if isempty(obj.ModelObj) || isempty(obj.DatasetTable) || ...
            isempty(FilteredResponseMap) || any(any(cellfun(@isempty,FilteredResponseMap))) || ... % any(any(...) modified by Iraj
            isempty(obj.SelectedParams) || ...
            (~isempty(obj.SelectedParams) && ~any([obj.SelectedParams.FlagFit]))

        StatusOk = false;
        Message = 'Model and dataset must be specified, at least one parameter must be selected for fitting, and response map must be specified.';
    else
        % Description of the dosing information.
        DoseTemplate = [];
        for index = 1:size(FilteredDoseMap,1)
            Dosearray = sbiodose(FilteredDoseMap{index,1});
            Dosearray.TargetName = FilteredDoseMap{index,2};
            Dosearray.LagParameterName = '';
            DoseTemplate = [DoseTemplate;Dosearray]; %#ok<AGROW>
        end

        % Classify Data Column Names.
        GroupLabel = obj.DatasetTable.Group;
        TimeLabel = obj.DatasetTable.Time;
        DependentVariableLabel = obj.DatasetTable.YAxis;
        DoseLabel = obj.DatasetTable.Dosing;
        RateLabel = '';

        % Fix names
        if isempty(GroupLabel)
            GroupLabelFixed = '';
        else
            GroupLabelFixed = matlab.lang.makeValidName(GroupLabel);
        end
        if isempty(TimeLabel)
            TimeLabelFixed = '';
        else
            TimeLabelFixed = matlab.lang.makeValidName(TimeLabel);
        end
        if isempty(DoseLabel)
            DoseLabelFixed = '';
        else
            DoseLabelFixed = matlab.lang.makeValidName(DoseLabel);
        end
        if isempty(RateLabel)
            RateLabelFixed = '';
        else
            RateLabelFixed = matlab.lang.makeValidName(RateLabel);
        end

        % Define the parameters.
        IsSelected = [obj.SelectedParams.FlagFit];
        EstimatedParams = {obj.SelectedParams(IsSelected).Name};
        EstimatedParamInitialValues =  {obj.SelectedParams(IsSelected).Value};

        % Define response information.
        % Example: {'PK.output_logPK = Conc'};
        ResponseMap = cellfun(@(x,y)sprintf('%s = %s',x,y),...
            FilteredResponseMap(:,2),...
            FilteredResponseMap(:,1),...
            'UniformOutput',false);

        % Define Estimate options.
        ErrorModel = obj.FitErrorModel;

        % Define a description of the data.
        GroupedDataObj = groupedData(obj.DataToFit);

        % Define objects being estimated and their initial estimates.
        if obj.UseFitBounds
            EstimatedParamBounds = cellfun(@(x,y) [x,y],{obj.SelectedParams(IsSelected).Min},{obj.SelectedParams(IsSelected).Max},'UniformOutput',false);
            EstimatedInfoObj = estimatedInfo(EstimatedParams,...
                'InitialValue',EstimatedParamInitialValues,...
                'Bounds',EstimatedParamBounds,...
                'CategoryVariableName',GroupLabelFixed);
        else
            EstimatedInfoObj = estimatedInfo(EstimatedParams,...
                'InitialValue',EstimatedParamInitialValues,...
                'CategoryVariableName',GroupLabelFixed);
        end

        % Assign Grouped Data Column Names.
        GroupedDataObj.Properties.GroupVariableName			= GroupLabelFixed;
        GroupedDataObj.Properties.IndependentVariableName 	= TimeLabelFixed;

        % Sort rows by group label and time label
        GroupedDataObj = sortrows(GroupedDataObj,{GroupLabelFixed, TimeLabelFixed},{'ascend','ascend'});

        % Extract dosing information.
        Dosing = createDoses(GroupedDataObj, DoseLabelFixed, RateLabelFixed, DoseTemplate);

        % Define Estimate options.
        Pooled = obj.UsePooledFitting;
        FittingOptions = {'ErrorModel', ErrorModel, 'Pooled', Pooled};

        % Define Algorithm options.
        Options = statset;
        Options.TolX = 1.0E-8;
        Options.TolFun = 1.0E-8;
        Options.MaxIter = 100;

        try
            if obj.useUI
                Title = 'Running Fitting';
                hWbar = UIUtilities.CustomWaitbar(0,Title,'',false);
                UIUtilities.CustomWaitbar(0.5,hWbar,'Fitting...');
            end

            % Loop through selected variants in order specified
            OrderedVariants = obj.SelectedVariants;
            OrderedVariants(obj.SelectedVariantsOrder) = obj.SelectedVariants;
            IsSelected = get(OrderedVariants,'Active');
            if iscell(IsSelected)
                IsSelected = cell2mat(IsSelected);
            end
            OrderedVariants = OrderedVariants(IsSelected);
            % Create current fit variant
            CurrFitVariant = sbiovariant('TEMP_FITTING_IN_APP');
            CurrFitVariant.Active = true;
            % Then update with overrides
            ParamContent = {};
            for index = 1:numel(obj.SelectedParams)
                ParamContent = [ParamContent;
                    {'parameter',obj.SelectedParams(index).Name,'Value',obj.SelectedParams(index).Value}];             %#ok<AGROW>
            end
            addcontent(CurrFitVariant,num2cell(ParamContent,2));
            % Concatenate
            OrderedVariants = [OrderedVariants(:)',CurrFitVariant];

            % Debug
            if obj.FlagDebug
                disp('------ DEBUG: Displaying variants used for fitting');
                OrderedVariants
                disp('------ DEBUG: Displaying parameters contained in TEMP_FITTING_IN_APP');
                CurrFitVariant
                disp('------');
            end

            % Estimate parameter values.
            [Results,SimDataI] = sbiofit(obj.ModelObj, GroupedDataObj, ResponseMap, EstimatedInfoObj, ...
                Dosing, obj.FitFunctionName, Options, OrderedVariants, FittingOptions{:});

            if obj.FlagDebug % added by Iraj
                disp('------ DEBUG: Displaying results for the fitted model');
                disp(sprintf('LogL = %3.3f  ', Results.LogLikelihood));
                disp(sprintf('AIC = %3.3f  ', Results.AIC));
                disp(sprintf('BIC = %3.3f  ', Results.BIC));

            end
            % Assign to object
            obj.FitResults = Results;
            obj.FitSimData = SimDataI;

            % Assign fitted value and standard error
            [obj.SelectedParams.FittedVal] = deal([]);

            if ~isempty(Results)
                for index = 1:numel(Results(1).ParameterEstimates.Name)
                    for rIndex = 1:numel(Results)
                        MatchIndex = strcmpi(Results(rIndex).ParameterEstimates.Name(index),{obj.SelectedParams.Name});
                        obj.SelectedParams(MatchIndex).FittedVal = ...
                            [obj.SelectedParams(MatchIndex).FittedVal;
                            Results(rIndex).ParameterEstimates.Estimate(index) Results(rIndex).ParameterEstimates.StandardError(index)];
                    end
                end
            end

            % Configure the names of the resulting simulation data.
            for i = 1:length(SimDataI)
                SimDataI(i).Name = 'SimData Individual';
            end

            % Convert dataToFit to a SimData object for plotting.
            UpdatedDataToFit = SimData.constructFromTable(obj.DataToFit, TimeLabelFixed, GroupLabelFixed);
            for i = 1:length(UpdatedDataToFit)
                UpdatedDataToFit(i).Name = 'Data To Fit';
            end

            % Store taskResult
            % Define information about the task.
            taskInfo.AlgorithmName              = obj.FitFunctionName;
            taskInfo.ErrorModel                 = obj.FitErrorModel;
            taskInfo.Pooled                     = obj.UsePooledFitting;
            taskInfo.ParamTransform             = 0;
            taskInfo.PKData.GroupLabel          = GroupLabelFixed;
            taskInfo.PKData.IndependentVarLabel = TimeLabelFixed;
            taskInfo.PKData.IndependentVarUnits = {''};
            taskInfo.PKData.DependentVarLabel   = DependentVariableLabel;
            taskInfo.PKData.DependentVarUnits   = {''};
            taskInfo.PKData.DoseLabel           = DoseLabelFixed;
            taskInfo.PKData.DoseUnits           = {''};
            taskInfo.PKData.RateLabel           = RateLabelFixed;
            taskInfo.PKData.RateUnits           = {''};
            taskInfo.PKData.CovariateLabels     = {''};
            taskInfo.PKData.GroupNames          = Results.groupNames;
            taskInfo.PKModelMap.Dosed           = FilteredDoseMap(:,2);
            taskInfo.PKModelMap.Observed        = FilteredResponseMap(:,2);
            taskInfo.PKModelMap.Estimated       = EstimatedParams;
            taskInfo.PKModelMap.EstimatedTypes  = {'parameter'};
            taskInfo.PKModelMap.DosingType      = {};
            taskInfo.CovariateModel             = [];
            taskInfo.PKModelMap.EstimatedNames  = EstimatedParams;

            % Add statistical information.
            stackedResults = vertcat(Results.ParameterEstimates);
            values = reshape(stackedResults.Estimate, length(taskInfo.PKModelMap.Estimated), length(Results))';
            if numel(taskInfo.PKData.GroupLabel) == 1
                taskInfo.Stats.Mean              = values;
                taskInfo.Stats.StandardDeviation = zeros(1, length(values));
            else
                taskInfo.Stats.Mean              = nanmean(values, 1);
                taskInfo.Stats.StandardDeviation = nanstd(values, 0, 1);
            end

            taskResult.TaskInfo = taskInfo;
            taskResult.SimdataI = SimDataI;
            taskResult.DataToFit = UpdatedDataToFit;
            taskResult.Results = Results;

            % Store task result
            obj.FitTaskResults = taskResult;

            % Waitbar
            if obj.useUI
                UIUtilities.CustomWaitbar(1,hWbar,'Done');
                if ~isempty(hWbar) && ishandle(hWbar)
                    delete(hWbar);
                end
            end
        catch ME
            StatusOk = false;
            Message = ME.message;
            if obj.useUI
                if ~isempty(hWbar) && ishandle(hWbar)
                    delete(hWbar);
                end
            end
        end

    end