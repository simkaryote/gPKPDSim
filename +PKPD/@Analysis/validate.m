function [StatusOk,Message] = validate(obj)
% validate - validates the analysis
% -------------------------------------------------------------------------
% Abstract: This validates the analysis object set up in the configruation file.
%
% Syntax:
%           [StatusOk,Message] = validate(obj)
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

% Validate SelectedVariantNames and SelectedVariantsOrder
if numel(obj.SelectedVariantNames) ~= numel(obj.SelectedVariantsOrder)
    StatusOk = false;
    Message = 'Size of SelectedVariantNames must match size of SelectedVariantsOrder.';
end

if ~isempty(obj.SelectedVariantsOrder) && ~isequal(sort(obj.SelectedVariantsOrder),1:max(obj.SelectedVariantsOrder))
    StatusOk = false;
    Message = 'SelectedVariantsOrder must contain unique values and contain consecutive entries.';
end

% Check variant names
if ~isempty(obj.SelectedVariantNames)
    Var = getvariant(obj.ModelObj);
    VariantNames = get(Var,'Name');
    Match = ismember(obj.SelectedVariantNames,VariantNames);
    if any(~Match)
        StatusOk = false;
        Message = sprintf('Invalid name(s) specified in SelectedVariantNames. Name(s) must match model variant names. Please validate: %s',cellstr2dlmstr(obj.SelectedVariantNames(~Match),', '));
    end
end

% Check dose names
if ~isempty(obj.SelectedDoses)
    Dose = getdose(obj.ModelObj);
    DoseNames = get(Dose,'Name');
    if ischar(DoseNames)
        DoseNames = {DoseNames};
    end
    % Convert to cell
    SelectedDoseNames = get(obj.SelectedDoses,'Name');
    if ischar(SelectedDoseNames)
        SelectedDoseNames = {SelectedDoseNames};
    end
    Match = ismember(SelectedDoseNames,DoseNames);
    if any(~Match)
        StatusOk = false;
        Message = sprintf('Invalid dose(s) specified in SelectedDoses. Name(s) must match model dose names. Please validate: %s',cellstr2dlmstr(SelectedDoseNames(~Match),', '));
    end
end

% Validate parameters
if ~isempty(obj.SelectedParams)
    AllNames = get(obj.Parameters,'Name');
    % Put names in cell
    Names = {obj.SelectedParams.Name};
    Match = ~ismember(Names,AllNames);
    if any(Match)
        StatusOk = false;
        Message = sprintf('Incorrect parameter names specified for %s',cellstr2dlmstr(Names(Match),', '));
    end
end
    
