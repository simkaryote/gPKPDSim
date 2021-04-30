function varargout = CustomWaitbar(x,Name,Message,AllowCancel)
% CustomWaitbar - Custom waitbar with added functionality
% -------------------------------------------------------------------------
% Abstract: This function adds functionality to the waitbar including
% turning off the Tex interpreter, allowing a cancel button, and time
% estimation of the progress.
%
% Syntax:
%           hWbar = CustomWaitbar(x,Name,Message,AllowCancel)
%           StatusOk = CustomWaitbar(x,hWbar,Message)
%
% Inputs:
%           x - the waitbar fraction
%           Name - title bar name of the figure
%           hWbar - handle to existing waitbar to update
%           Message - message to display
%           AllowCancel - flag to add cancel button (optional)
%
% Outputs:
%           hWbar - handle to the waitbar
%           StatusOk - false if waitbar does not exist (was cancelled)
%
% Examples:
%           hWbar = CustomWaitbar(0,'title','message',true)
%           for idx = 1:5
%               StatusOk = CustomWaitbar(idx/5,hWbar,sprintf('Step %d',idx))
%               if ~StatusOk
%                   break; %user cancelled
%               end
%           end
%
% Notes: Your code can also detect when the cancel is hit by checking for
%        existance of the handle hWbar. For example:
%
%           if ~ishandle(hWbar)
%               break
%           end
%

% Copyright 2017 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: agajjala $
%   $Revision: 420 $  $Date: 2017-12-07 14:47:44 -0500 (Thu, 07 Dec 2017) $
% ---------------------------------------------------------------------

persistent TStart hTxt

% Which syntax was used?
if ischar(Name)
    % Syntax: hWbar = CustomWaitbar(x,Name,Message,AllowCancel)
    
    % Was a cancel button called for
    if nargin>3 && AllowCancel
        % Initialize the waitbar with cancel button
        hWbar = waitbar(x,Message,'Name',Name,...
            'CreateCancelBtn',@(src,e)CancelCallback(src,e));
    else
        % Initialize the waitbar
        hWbar = waitbar(x,Message,'Name',Name);
    end
    
    % Turn off Tex
    hTxt = findall(hWbar,'Type','text');
    set(hTxt,'Interpreter','none')
    
    % Increase button font
    hBut = findall(hWbar,'Type','uicontrol');
    set(hBut,'FontSize',10);
    
    % Create remaining time display
    hTxt = uicontrol('Parent',hWbar,...
        'Style','text',...
        'HorizontalAlignment','left',...
        'FontSize',8,...
        'BackgroundColor',get(hWbar,'Color'),...
        'Position',[10 1 250 20],...
        'String','Remaining time: Calculating...');
    
    % Make it a modal figure
    set(hWbar,'WindowStyle','modal')
    
    % Process output handle
    if nargout
        varargout{1} = hWbar;
    end
    
    % Keep track of time
    TStart = now;
    
else
    % Syntax: CustomWaitbar(x,hWbar,Message,AllowCancel)
    
    % Check for TStart
    if ~exist('TStart','var')
        TStart = now;
    end
    
    % Name argument is actually hWbar
    hWbar = Name;
    
    % Does the waitbar still exist, or was it cancelled?
    StatusOk = ishandle(hWbar);
    if StatusOk
        
        % Update the progress
        waitbar(x,hWbar,Message)
        
        % Calculate the remaining time
        TimeElapsed = now - TStart;
        TimeRemaining = (1-x)/x * TimeElapsed;
        
        % Update the time
        if ishandle(hTxt)
            if isfinite(TimeRemaining)
                TimeStr = sprintf('Remaining time: %s min, %s sec',...
                    datestr(TimeRemaining,'MM'), ...
                    datestr(TimeRemaining,'SS'));
            else
               TimeStr = 'Remaining time: Calculating...';
            end
            set(hTxt,'String',TimeStr)
        end
        
    end
    
    % Was an output requested?
    if nargout
        varargout{1} = StatusOk;
    end
    
end


%% Define cancel callback
function CancelCallback(src,~)

% Delete the waitbar
delete(ancestor(src,'figure'));

