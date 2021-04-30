function update(vObj)
% update - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           update(vObj)
%
% Inputs:
%           vObj - The PKPDViewer.Simulation vObject
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


%% Number of Runs (Population only)

set(vObj.h.NumberOfRunsEdit,'String',num2str(vObj.Data.NumPopulationRuns));
if strcmpi(vObj.Type,'Simulation')
    set(vObj.h.NumberOfRunsLabel,'Visible','off');
    set(vObj.h.NumberOfRunsEdit,'Visible','off');
    vObj.h.MainLayout.Heights(2) = 0;
else
    set(vObj.h.NumberOfRunsLabel,'Visible','on');
    set(vObj.h.NumberOfRunsEdit,'Visible','on');
    vObj.h.MainLayout.Heights(2) = 25;
end


%% Parameters

% Only proceed if controls have been created
if ~isempty(vObj.Data.SelectedParams) && ~isempty(vObj.h.ParamNameText) && ...
        numel(vObj.Data.SelectedParams) == numel(vObj.h.ParamNameText)
    for index = 1:numel(vObj.Data.SelectedParams)
        set(vObj.h.ParamNameText(index),'String',vObj.Data.SelectedParams(index).Name);
        set(vObj.h.ParamValueEdit(index),'String',num2str(vObj.Data.SelectedParams(index).Value))
        set(vObj.h.ParamUnitsText(index),'String',vObj.Data.SelectedParams(index).Units)
        set(vObj.h.ParamMinEdit(index),'String',num2str(vObj.Data.SelectedParams(index).Min))
        if strcmpi(vObj.Data.SelectedParams(index).Scale,'linear')
            set(vObj.h.ParamSlider(index),...
                'Value',vObj.Data.SelectedParams(index).Value,...
                'Min',vObj.Data.SelectedParams(index).Min,...
                'Max',vObj.Data.SelectedParams(index).Max);
        else
            set(vObj.h.ParamSlider(index),...
                'Value',log10(vObj.Data.SelectedParams(index).Value),...
                'Min',log10(vObj.Data.SelectedParams(index).Min),...
                'Max',log10(vObj.Data.SelectedParams(index).Max));
        end
        set(vObj.h.ParamMaxEdit(index),'String',num2str(vObj.Data.SelectedParams(index).Max))
        MatchInd = find(strcmpi(vObj.Data.SelectedParams(index).Scale,{'linear','log'}));
        if isempty(MatchInd)
            MatchInd = 1;
        end
        set(vObj.h.ParamScalePopup(index),'Value',MatchInd);
        set(vObj.h.ParamPercCVEdit(index),'String',num2str(vObj.Data.SelectedParams(index).PercCV))
        
        if vObj.Data.SelectedParams(index).Min == vObj.Data.SelectedParams(index).Max
            set(vObj.h.ParamSlider(index),'Enable','off');
        else
            set(vObj.h.ParamSlider(index),'Enable','on');
        end
    end
end
