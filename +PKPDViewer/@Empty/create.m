function create(vObj)
% create - Creates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function creates all parts of the viewer display
%
% Syntax:
%           create(vObj)
%
% Inputs:
%           vObj - The PKPDViewer.Empty vObject
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

%% Create the layout

% Vertical layout, making upper/lower panes
vObj.h.VLayout = uix.VBox(...
    'Parent',vObj.hPanel,...
    'Spacing',6);

% Empty item up top
uix.Empty('Parent',vObj.h.VLayout);

% Text displayed in center
vObj.h.MessageText = uicontrol(...
    'Parent',vObj.h.VLayout,...
    'Style','text',...
    'HorizontalAlignment','center',...
    'FontSize',12,...
    'String','Select an item on the left pane.');

% Empty item on bottom
uix.Empty('Parent',vObj.h.VLayout);

% Adjust layout sizes
vObj.h.VLayout.Heights = [-1 20 -1];