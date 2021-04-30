function [StatusOk,Message] = runSimulation(obj)
% runSimulation - runs the simulation task
% -------------------------------------------------------------------------
% Abstract: This runs the simulation task.
%
% Syntax:
%           [StatusOk,Message] = runSimulation(obj)
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

% Populate sim run colors if needed
if isempty(obj.SimRunColors)
    updateSimRunColors(obj);
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
    
    try
        Title = 'Running Simulation';
        hWbar = UIUtilities.CustomWaitbar(0,Title,'',false);
    
        UIUtilities.CustomWaitbar(0.5,hWbar,'Simulating...');
        % Debug
        if obj.FlagDebug
            disp('------ DEBUG: Displaying parameters used for simulation');
            obj.SimVariant
            disp('------');
        end
        % Simulate
        ThisRun = sbiosimulate(obj.ModelObj,obj.ConfigSet,obj.SimVariant,obj.SelectedDoses(IsDoseSelected));
        if obj.FlagSimOverlay && ~isempty(obj.SimData)
            obj.SimData(end+1) = ThisRun;
        else
            obj.SimData = ThisRun;
        end
        
        % Add to SimProfileNotes
        ActiveDoses = getActiveSelectedDoses(obj);
        ActiveOrderedVariants = getActiveOrderedVariants(obj);
        SelectedParams = obj.SelectedParams;
        
        % New profile with populated info
        pObj = PKPD.Profile;
        populate(pObj,ActiveOrderedVariants,ActiveDoses,SelectedParams);
        
        % Add to SimProfileNotes
        if obj.FlagSimOverlay && ~isempty(obj.SimProfileNotes)
            obj.SimProfileNotes(end+1) = pObj;            
        else
            obj.SimProfileNotes = pObj;
        end
        NumRuns = numel(obj.SimProfileNotes);
        obj.SimProfileNotes(end).Color = obj.SimRunColors(NumRuns,:);
        
        UIUtilities.CustomWaitbar(1,hWbar,'Done');
        if ~isempty(hWbar) && ishandle(hWbar)
            delete(hWbar);
        end
    catch ME
        StatusOk = false;
        Message = ME.message;
        if ~isempty(hWbar) && ishandle(hWbar)
            delete(hWbar);
        end
    end
else
    obj.SimData = [];
end