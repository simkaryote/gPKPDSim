function refresh(vObj)
% refresh - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           refresh(vObj)
%
% Inputs:
%           vObj - The PKPDViewer.Fitting vObject
%
% Outputs:
%           none
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


%% Concentration/Dose - Target Species Mapping

% Get species and create full name
Species = get(vObj.Data.ModelObj,'Species');
if ~isempty(Species)
    % Update Species
    SelectedSpeciesNames = get(vObj.Data.SelectedSpecies,'Name');
    MatchIndex = ismember(get(Species,'Name'),SelectedSpeciesNames);
    Species = Species(MatchIndex);
    
    Compartments = get(Species,'Parent');
    if numel(Compartments) == 1
        Compartments = {Compartments};
    end
    CompartmentNames = get(vertcat(Compartments{:}),'Name');
    if ischar(CompartmentNames)
        CompartmentNames = {CompartmentNames};
    end
    SpeciesNames = get(Species,'Name');
    if ischar(SpeciesNames)
        SpeciesNames = {SpeciesNames};
    end
    % Append empty    
    FullSpeciesNames = cellfun(@(x,y)sprintf('[%s].[%s]',x,y),CompartmentNames,SpeciesNames,'UniformOutput',false);    
    FullSpeciesNames = vertcat({' '},FullSpeciesNames);    
    if vObj.IsPC
        set(vObj.h.DoseMappingTable,'ColumnFormatData',{{},FullSpeciesNames});        
        set(vObj.h.ConcMappingTable,'ColumnFormatData',{{},FullSpeciesNames});
    else        
        set(vObj.h.DoseMappingTable,'ColumnFormat',{'char',FullSpeciesNames(:)'});        
        set(vObj.h.ConcMappingTable,'ColumnFormat',{'char',FullSpeciesNames(:)'});
    end
    
    if ~isempty(vObj.Data.DoseMap)
        % Pre-populate any empties in dose map
        MatchIndex = cellfun(@isempty,vObj.Data.DoseMap(:,2));
        vObj.Data.DoseMap(MatchIndex,2) = {FullSpeciesNames{1}};
    end
    
    if ~isempty(vObj.Data.ResponseMap)
        % Pre-populate any empties in response map
        MatchIndex = cellfun(@isempty,vObj.Data.ResponseMap(:,2));
        vObj.Data.ResponseMap(MatchIndex,2) = {FullSpeciesNames{1}};
    end
else
    if vObj.IsPC
        set([vObj.h.DoseMappingTable,vObj.h.ConcMappingTable],'ColumnFormatData',{{},{}});    
    else
        set([vObj.h.DoseMappingTable,vObj.h.ConcMappingTable],'ColumnFormat',{'char','char'});    
    end
end

% Set response map
set(vObj.h.DoseMappingTable,'Data',vObj.Data.DoseMap);
set(vObj.h.ConcMappingTable,'Data',vObj.Data.ResponseMap);


%% Pooled Fitting

set(vObj.h.PooledFittingCheckbox,'Value',vObj.Data.UsePooledFitting);


%% Error Model

MatchIndex = find(strcmpi(vObj.Data.FitErrorModel,vObj.Data.FitErrorModelOptions));
set(vObj.h.FitErrorModelPopup,'Value',MatchIndex);


%% Parameters

FitVal = {vObj.Data.SelectedParams.FittedVal}';
CombinedFitValAndStdErr = cell(numel(FitVal),1);
for index = 1:numel(FitVal)
    for fIndex = 1:size(FitVal{index})
        CombinedFitValAndStdErr{index,fIndex} = sprintf('%f + %f',FitVal{index}(fIndex,1),FitVal{index}(fIndex,2));        
    end    
end
    
% Set ParamsData based on UseFitBounds flag
ParamsData = [...
        {vObj.Data.SelectedParams.Name}',...
        {vObj.Data.SelectedParams.FlagFit}',...
        {vObj.Data.SelectedParams.Value}',...
        CombinedFitValAndStdErr,...
        {vObj.Data.SelectedParams.Units}',...
        ];    
if vObj.Data.UseFitBounds
    ParamsData = [...
        ParamsData,...
        {vObj.Data.SelectedParams.Min}',...
        {vObj.Data.SelectedParams.Max}',...
        ];
end

% Get number of animals
NumAnimals = size(CombinedFitValAndStdErr,2);
if ~isempty(vObj.Data.FitResults)
    ColumnName = [...
        {'Name','Fit?','Initial'},...
        cellfun(@(x)sprintf('Fit - Group %s',char(x)),{vObj.Data.FitResults.GroupName},'UniformOutput',false),...
        {'Units'}];
else
    ColumnName = [...
        {'Name','Fit?','Initial'},...
        'Fit - Group',...
        {'Units'}];
end
% Append Min and Max if bounds are used
if vObj.Data.UseFitBounds
    ColumnName = [...
        ColumnName,...
        {'Min','Max'};
        ];
end

% ColumnEditable
ColumnEditable = [false true true false(1,NumAnimals) false];
if vObj.Data.UseFitBounds
    ColumnEditable = [ColumnEditable true true];
end

% ColumnFormat
if vObj.IsPC
     ColumnFormat = [...
        {'char','boolean','float'},...
        repmat({'char'},1,NumAnimals),...
        {'char'}];
    if vObj.Data.UseFitBounds
        ColumnFormat = [...
            ColumnFormat,...
            {'float','float'}];
    end
    
else
    ColumnFormat = [...
        {'char','logical','numeric'},...
        repmat({'char'},1,NumAnimals),...
        {'char','numeric','numeric'}];
    if vObj.Data.UseFitBounds
        ColumnFormat = [...
            ColumnFormat,...
            {'numeric','numeric'}];
    end    
end

% Set the ParametersTable
set(vObj.h.ParametersTable,...
    'Data',ParamsData,...
    'ColumnName',ColumnName,...
    'ColumnFormat',ColumnFormat,...
    'ColumnEditable',ColumnEditable);


%% Toggle enables

if ~isempty(vObj.Data.ModelObj)
    set([....
        vObj.h.FitErrorModelPopup,...
        vObj.h.RestoreDefaultsButton],'Enable','on');
    set(vObj.h.SaveAsVariantButton,'Enable','on');
%     if vObj.Data.UsePooledFitting && NumAnimals == 1
%         set(vObj.h.SaveAsVariantButton,'Enable','on');
%     else
%         set(vObj.h.SaveAsVariantButton,'Enable','off');
%     end
    if vObj.IsPC
        set(vObj.h.ParametersTable,'Enabled','on');
        set(vObj.h.DoseMappingTable,'Enabled','on');
        set(vObj.h.ConcMappingTable,'Enabled','on');
    end
else
    set([....
        vObj.h.FitErrorModelPopup,...
        vObj.h.RestoreDefaultsButton,...
        vObj.h.SaveAsVariantButton],'Enable','off');
    if vObj.IsPC
        set(vObj.h.ParametersTable,'Enabled','off');
        set(vObj.h.DoseMappingTable,'Enabled','off');
        set(vObj.h.ConcMappingTable,'Enabled','off');
    end
end    