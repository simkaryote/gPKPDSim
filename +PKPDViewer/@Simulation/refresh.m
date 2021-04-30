function refresh(vObj)
% refresh - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           refresh(vObj)
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

%% Toggle enables

if ~isempty(vObj.Data.ModelObj)
    set([....
        vObj.h.TimeStartEdit,...
        vObj.h.TimeStepEdit,...
        vObj.h.TimeStopEdit,...
        vObj.h.RestoreDefaultsButton,...
        vObj.h.SaveAsVariantButton],'Enable','on');
    
else
    set([....
        vObj.h.TimeStartEdit,...
        vObj.h.TimeStepEdit,...
        vObj.h.TimeStopEdit,...
        vObj.h.RestoreDefaultsButton,...
        vObj.h.SaveAsVariantButton],'Enable','off');
end
        

%% Simulation time

set(vObj.h.TimeStartEdit,'String',num2str(vObj.Data.StartTime));
set(vObj.h.TimeStepEdit,'String',num2str(vObj.Data.TimeStep));
set(vObj.h.TimeStopEdit,'String',num2str(vObj.Data.StopTime));

% Get active config set
if ~isempty(vObj.Data.ModelObj)
    ConfigSet = vObj.Data.ConfigSet;
    ConfigSet = ConfigSet([ConfigSet.Active]);
    set(vObj.h.TimeUnitsLabel,'String',ConfigSet.TimeUnits);
else
    set(vObj.h.TimeUnitsLabel,'String','');
end


%% Invoke update

update(vObj);
