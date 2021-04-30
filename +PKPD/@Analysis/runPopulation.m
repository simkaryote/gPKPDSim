function [StatusOk,Message] = runPopulation(obj)
% runPopulation - runs the population task
% -------------------------------------------------------------------------
% Abstract: This runs the population task.
%
% Syntax:
%           [StatusOk,Message] = runPopulation(obj)
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
Message = {};

% Populate pop run colors if needed
if isempty(obj.PopRunColors)
    updatePopRunColors(obj);
end

if ~isempty(obj.ModelObj)
    % createSimFunction can be used for multiple sequential simulations and
    % may therefore preferred over sbiosimulate, however createSimFunction
    % ignores active variants
    %     SimFunction = createSimFunction(aObj.ModelObj,ParamNames,aObj.SpeciesToPlot,Dosed);
    
    %     obj.SimTime = obj.StartTime:obj.TimeStep:obj.StopTime;
    %     aObj.SimData = SimFunction(ParamValues,StopTime,DosingInfo,aObj.SimTime);
    
    IsDoseSelected = get(obj.SelectedDoses,'Active');
    if iscell(IsDoseSelected)
        IsDoseSelected = cell2mat(IsDoseSelected);
    end
    
    ErrorCount = 0;
    
    Title = 'Running Population';
    hWbar = UIUtilities.CustomWaitbar(0,Title,'',false);
    
    UIUtilities.CustomWaitbar(1/(obj.NumPopulationRuns+2),hWbar,'Accelerating model...');
    % Accelerate model
    sbioaccelerate(obj.ModelObj,[],obj.SelectedDoses(IsDoseSelected));
    
    % Create parameter set for population variant
    ParamVec = zeros(numel(obj.SelectedParams),obj.NumPopulationRuns);
    RandNum = randn(numel(obj.SelectedParams),obj.NumPopulationRuns);
    
    % scale MeanVec for the parameters with "log" scales
    LogScaleVec = zeros(1, length(obj.SelectedParams));
    for i = 1 : length(LogScaleVec)
        if strcmp(obj.SelectedParams(i).Scale, 'log')
            LogScaleVec(i) = 1;
        end
    end
    MeanVec = [obj.SelectedParams.Value];
    MeanVec(LogScaleVec == 1) = log(MeanVec(LogScaleVec == 1));
    
    CVVec   = [obj.SelectedParams.PercCV]/100;
    
    % Clear NewPopSimData
    NewPopSimData = [];
    
    for rIndex = 1:obj.NumPopulationRuns
        UIUtilities.CustomWaitbar((rIndex+1)/(obj.NumPopulationRuns+2),hWbar,sprintf('Running %d of %d...',rIndex,obj.NumPopulationRuns));
        
        % Rescale NewVal for the parameters with "log" scales
        NewVal = MeanVec .* ( 1 + CVVec.*RandNum(:,rIndex)');
        NewVal(LogScaleVec == 1) = exp(NewVal(LogScaleVec == 1));
        % This is to remove negative parameter values
        NewVal = max(NewVal, 0);
        
        ParamVec(:,rIndex) = NewVal(:);
        
        % Create population variant
        PopVariant = sbiovariant('POPULATION_IN_APP');
        
        % Loop through selected variants in order specified
        OrderedVariants = obj.SelectedVariants;
        OrderedVariants(obj.SelectedVariantsOrder) = obj.SelectedVariants;
        IsSelected = get(OrderedVariants,'Active');
        if iscell(IsSelected)
            IsSelected = cell2mat(IsSelected);
        end
        OrderedVariants = OrderedVariants(IsSelected);
        
        % Get variant content
        VariantContent = {};
        for index = 1:numel(OrderedVariants)
            VariantContent = [VariantContent; OrderedVariants(index).Content]; %#ok<AGROW>
        end
        VariantContent = vertcat(VariantContent{:});
        
        % Then update with overrides
        ParamContent = cell(numel(obj.SelectedParams),4);
        ParamContent(:,1) = {'parameter'};
        ParamContent(:,2) = {obj.SelectedParams.Name};
        ParamContent(:,3) = {'Value'};
        ParamContent(:,4) = num2cell(ParamVec(:,rIndex));
        
        % Add content
        Content = [VariantContent;ParamContent];
        if ~isempty(Content)
            [~,MatchIndex] = unique(Content(:,2),'last');
            Content = Content(MatchIndex,:);
            
            % Add to pop variant
            addcontent(PopVariant,num2cell(Content,2));
        end
        
        try
            % Run sbiosimulate
            ThisRun = sbiosimulate(obj.ModelObj,obj.ConfigSet,PopVariant,obj.SelectedDoses(IsDoseSelected));
            if ~isempty(NewPopSimData)
                NewPopSimData(end+1) = ThisRun; %#ok<AGROW>
            else
                NewPopSimData = ThisRun;
            end
        catch ME
            StatusOk = false;
            Message = [Message, ME.message]; %#ok<AGROW>
            ErrorCount = ErrorCount + 1;
            
            % Store empty sim data
            if ~isempty(NewPopSimData)
                NewPopSimData(end+1) = SimData; %#ok<AGROW>
            else
                NewPopSimData = SimData;
            end
        end
    end % for each simulation in this population run
    
    if ~StatusOk
        % Concatenate error messages
        Message = unique(Message);
        Message = sprintf('Population analysis failed for %d runs.\n\n%s',ErrorCount,cellstr2dlmstr(Message,'\n'));
    else
        % Add to PopProfileNotes
        ActiveDoses = getActiveSelectedDoses(obj);
        ActiveOrderedVariants = getActiveOrderedVariants(obj);
        SelectedParams = obj.SelectedParams;
        NumPopulationRuns = obj.NumPopulationRuns;
        
        % New profile with populated info
        pObj = PKPD.Profile;
        populate(pObj,ActiveOrderedVariants,ActiveDoses,SelectedParams,NumPopulationRuns);
        
        % Add to PopProfileNotes
        if obj.FlagPopOverlay && ~isempty(obj.PopProfileNotes)
            obj.PopProfileNotes(end+1) = pObj;
        else
            obj.PopProfileNotes = pObj;
        end
        NumRuns = numel(obj.PopProfileNotes);
        obj.PopProfileNotes(end).Color = obj.PopRunColors(NumRuns,:);
    end
    
    % Extract data after running in order to make plotting
    % quicker
    UIUtilities.CustomWaitbar((obj.NumPopulationRuns+1)/(obj.NumPopulationRuns+2),hWbar,'Extracting species data...');
    if ~isempty(NewPopSimData)
        NewPopSpeciesData = NewPopSimData.selectbyname(obj.PlotSpeciesTable(:,2));
        
        NumSpeciesInTable = numel(obj.PlotSpeciesTable(:,1));
        NewPopSpeciesFlatData = horzcat(NewPopSpeciesData.Data);
        
        NewPopSpeciesSummary = PKPD.PopulationSummary.empty(0,0);
        for sIndex = 1:NumSpeciesInTable        
            
            ThisSim = NewPopSpeciesFlatData(:,sIndex:NumSpeciesInTable:end);            
            NewPopSpeciesSummary(1,sIndex) = PKPD.PopulationSummary(...
                'Name',obj.PlotSpeciesTable{sIndex,2},...
                'Time',NewPopSpeciesData(1).Time,...
                'P50',prctile(ThisSim,50,2),...
                'P5',prctile(ThisSim,5,2),...
                'P95',prctile(ThisSim,95,2));
        end
        
        if obj.FlagPopOverlay && ~isempty(obj.PopSummaryData)
            obj.PopSummaryData(end+1,:) = NewPopSpeciesSummary;
        else
            obj.PopSummaryData = NewPopSpeciesSummary;
        end
        
    else        
        obj.PopSummaryData = PKPD.PopulationSummary.empty(0,0);
    end
    
    UIUtilities.CustomWaitbar(1,hWbar,'Done');
    if ~isempty(hWbar) && ishandle(hWbar)
        delete(hWbar);
    end    
    
end