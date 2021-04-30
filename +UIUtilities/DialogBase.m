classdef DialogBase < matlab.mixin.SetGet
    % DialogBase - Class definition for handle graphics cluster of controls
    % ---------------------------------------------------------------------
    % Abstract: DialogBase defines the basic properties needed to define a
    % dialog window.
    %
    % Syntax:
    %           dlg = PKPD.DialogBase('p1',v1,...)
    %           Output = dlg.waitForOutput();
    %
    % PKPD.DialogBase optional constructor inputs:
    %
    %   CallingFigure - handle to the figure that called this dialog, used
    %   for positioning the dialog window
    %
    %   DialogSize - width and height of dialog window. If unspecified,
    %   default to [600 300]
    %
    %   WindowStyle - indicate either 'normal' or 'modal' for the dialog
    %
    % PKPD.DialogBase Properties:
    %
    %   Resize - whether the dialog is resizable
    %
    %   Title - title bar text for the dialog
    %
    %   Visible - visibility of the dialog figure
    %
    % PKPD.DialogBase Methods:
    %
    %   create - create the dialog figure and graphics
    %
    %   refresh - refresh the dialog contents
    %
    %   waitForOutput - wait for the dialog to close and produce output,
    %       typically used after setting WindowStyle to 'modal'
    %
    % Examples:
    %  hFig = figure();
    %  vObj = PKPD.DialogBase('Parent',hFig,'Units','normalized','Position',[0 0 0.5 0.5])
    
    % Copyright 2017 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 420 $  $Date: 2017-12-07 14:47:44 -0500 (Thu, 07 Dec 2017) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties
        Output
    end
    properties (Dependent=true, SetAccess=public, GetAccess=public)
        Resize
        Title
        Visible
    end
    properties (SetAccess=protected, GetAccess=protected)
        h
    end
    properties (SetAccess = private, GetAccess = protected)
        Figure
    end
    properties (SetAccess = private, GetAccess = private)
        IsWaitingForOutput = false
    end
    
    
    %% Constructor and Destructor
    methods
        
        function dlg = DialogBase(varargin)
            % DialogBase - Constructor for DialogBase
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new DialogBase
            %
            % Syntax:
            %           dlg = DialogBase()
            %
            % Inputs:
            %           Optional property-value pairs for default settings
            %
            % Outputs:
            %           dlg - DialogBase object
            %
            % Examples:
            %           hFig = figure;
            %           dlg = DialogBase('Parent',hFig);
            %
            
            %----- Parse Inputs -----%
            p = inputParser();
            p.KeepUnmatched = false;
            
            % Define defaults and requirements for each parameter
            p.addParameter('CallingFigure',[]);  
            p.addParameter('DialogSize',[600 300],@(x)numel(x)==2);  
            p.addParameter('Title','Dialog');            
            p.addParameter('Resize','off');
            p.addParameter('Visible','on');
            p.addParameter('WindowStyle','normal');
            p.parse(varargin{:});
            
            % Prepare the dialog position
            DPos = [100 100 p.Results.DialogSize];
            
            % If a calling figure was specified, get the center of it
            if ~isempty(p.Results.CallingFigure)
                CPos = getpixelposition(p.Results.CallingFigure);
                CMid = CPos([1 2]) + CPos([3 4])/2;
                DPos([1 2]) = CMid - DPos([3 4])/2;
            end
            
            % Create the figure window
            dlg.Figure = figure(...
                'MenuBar','none',...
                'Toolbar','none',...
                'DockControls','off',...
                'NumberTitle','off',...
                'Name', p.Results.Title,...
                'IntegerHandle','off',...
                'HandleVisibility','callback',...
                'Color',get(0,'DefaultUIControlBackgroundColor'),...
                'Visible',p.Results.Visible,...
                'Units','pixels',...
                'Position',DPos,...
                'Resize',p.Results.Resize,...
                'WindowStyle',p.Results.WindowStyle,...
                'CloseRequestFcn',@(h,e)onClose(dlg));
            
            % Store this object in the figure
            setappdata(dlg.Figure,'Dialog',dlg);
            
            % Ensure it is centered or at least on screen
            if isempty(p.Results.CallingFigure)
                movegui(dlg.Figure,'center');
            else
                movegui(dlg.Figure,'onscreen');
            end
            
        end

        function delete(dlg)
            
            % Remove the figure
            if ~dlg.IsWaitingForOutput && ishandle(dlg.Figure)
                delete(dlg.Figure);
            end
            
        end
        
    end %methods
    
    
    %% Public Methods and Event Handlers
    methods
       
        function Output = waitForOutput(dlg)
            
            % Set the output flag
            dlg.IsWaitingForOutput = true;
            
            % Wait for the figure to close
            uiwait(dlg.Figure);
            
            % Produce output
            Output = dlg.Output;
            
            % Clear the output flag
            dlg.IsWaitingForOutput = false;
            
        end
        
        function onClose(dlg)
           
            % No output was generated, so delete the figure
            delete(dlg.Figure);
            drawnow
            
        end
        
        
    end %methods
    
    

    %% Get/Set Methods
    % MATLAB calls a property's get method whenever the property value is
    % queried, if a get method for that property exists.
    methods
        
        function value = get.Resize(dlg)
            value = get(dlg.Figure,'Resize');
        end
        function set.Resize(dlg,value)
            value = validatestring(value,{'on','off'});
            set(dlg.Figure,'Resize',value)
        end
        
        function value = get.Title(dlg)
            value = get(dlg.Figure,'Name');
        end
        function set.Title(dlg,value)
            validateattributes(value,{'char'},{});
            set(dlg.Figure,'Name',value)
        end
        
        function value = get.Visible(dlg)
            value = get(dlg.Figure,'Visible');
        end
        function set.Visible(dlg,value)
            value = validatestring(value,{'on','off'});
            set(dlg.Figure,'Visible',value)
        end
        
    end %get/set methods
    
    
end %classdef

