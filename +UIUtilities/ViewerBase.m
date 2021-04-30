classdef ViewerBase < matlab.mixin.SetGet & UIUtilities.ConstructorAcceptsPVPairs
    % ViewerBase - Class definition for handle graphics cluster of controls
    % ---------------------------------------------------------------------
    % Abstract: ViewerBase defines the basic properties needed to define a
    % cluster of controls that behaves as a single handle graphics object
    %
    % Syntax:
    %           vObj = ViewerBase
    %           vObj = ViewerBase('Property','Value',...)
    %
    % ViewerBase Properties:
    %
    %     Data - The data that will be displayed by the viewer
    %
    %     DataChangedCallback - A settable callback that will fire when the
    %     viewer's Data is modified.
    %
    %     Enable - controls whether the HG controls in the viewer are
    %     enabled or disabled
    %
    %     Parent - handle graphics parent for the viewer, which should be
    %     a valid container including figure, uipanel, or uitab
    %
    %     Position - position of the viewer within the parent container
    %
    %     Units - units of the viewer within the parent container, used for
    %     determining the position
    %
    % ViewerBase Methods:
    %
    %     callCallback - call a user-specified callback function
    %
    %   Callback methods:
    %       none
    %
    % Examples:
    %  hFig = figure();
    %  vObj = ViewerBase('Parent',hFig,'Units','normalized','Position',[0 0 0.5 0.5])
    
    % Copyright 2017 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 420 $  $Date: 2017-12-07 14:47:44 -0500 (Thu, 07 Dec 2017) $
    % ---------------------------------------------------------------------

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Abstract Properties and Methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    % These items must be defined in any class that inherits from
    % ViewerBase.
    
    properties (Abstract, SetObservable, SetAccess=public, GetAccess=public)
       Data
    end
    methods (Abstract)
        refresh(vObj);
    end
    methods (Abstract, Access=protected)
        create(vObj);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Properties
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %% Public properties
    
    % These properties can be read or written to from outside the methods
    % of this object.
    properties (SetAccess=public, GetAccess=public, SetObservable)
        DataChangedCallback = []
        Enable = 'on' %enable state of the cluster
    end
    
    %% Dependent properties
    
    % These properties are dependent, meaning that their values are derived
    % from other properties and are calculated on request. This prevents
    % the values from being stale. Dependent property values are defined in
    % this file by a get function (e.g. get.PropertyName).
    properties (Dependent=true, SetAccess=public, GetAccess=public)
        Parent %handle graphics parent object of the cluster
        Position %position of the cluster
        Units %units for the position of the cluster
        Visible %visibility of the cluster
    end
    
    %% Protected properties
    
    % These properties are values that may be needed by the class methods,
    % but should be protected from being set outside
    properties (SetAccess=protected, GetAccess=protected)
        hPanel = [] %handle to the underlying panel of the cluster
        IsConstructed = false %True when the constructor is complete
    end
    
    % The internal handles structure for the viewer. These are hidden from
    % the user. It is useful to look at these values for development
    % purposes.
    properties (Hidden=true, SetAccess=protected, GetAccess=public)
        h %internal handles structure
    end

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Constructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % A constructor method is a special function that creates an instance
    % of the class. Typically, constructor methods accept input arguments
    % to assign the data stored in properties and always return an
    % initialized object.
    methods
        function [vObj,InputArgs] = ViewerBase(varargin)
            % ViewerBase - Constructor for ViewerBase
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new ViewerBase
            %
            % Syntax:
            %           vObj = ViewerBase()
            %           vObj = ViewerBase('p1',v1,...)
            %           [vObj,InputArgs] = ViewerBase('p1',v1,...)
            %
            % Inputs:
            %           Optional property-value pairs for default settings
            %
            % Outputs:
            %           vObj - ViewerBase object
            %           InputArgs - structure of unmatched input arguments
            %                       to pass to superclass
            %
            % Examples:
            %           hFig = figure;
            %           vObj = ViewerBase('Parent',hFig);
            %
            
            %----- Parse Inputs -----%
            p = inputParser();
            p.KeepUnmatched = false;
            
            % Define defaults and requirements for each parameter
            p.addParameter('DataChangedCallback',[]);
            p.addParameter('Parent',[]);
            p.addParameter('Position',[0 0 1 1]);
            p.addParameter('Units','normalized');
            p.addParameter('Visible','on');
            p.parse(varargin{:});
            
            % Retain any unused input arguments
            InputArgs = p.Unmatched;
            
            %----- Create Graphics and Assign Inputs -----%
            % Set up the panel to contain the cluster
            if isempty(p.Results.Parent)
                vObj.hPanel = uipanel(...
                    'BorderType','none',...
                    'Units',p.Results.Units,...
                    'Position',p.Results.Position,...
                    'Visible',p.Results.Visible,...
                    'DeleteFcn',@(h,e)delete(vObj),...
                    'UserData',vObj);
            else
                vObj.hPanel = uipanel(...
                    'Parent',p.Results.Parent,...
                    'BorderType','none',...
                    'Clipping','on',...
                    'Units',p.Results.Units,...
                    'Position',p.Results.Position,...
                    'Visible',p.Results.Visible,...
                    'DeleteFcn',@(h,e)delete(vObj),...
                    'UserData',vObj);
            end
            
            % Save the object handle in the panel userdata
            % (otherwise it might get cleaned up and deleted unintentionally)
            set(vObj.hPanel,'UserData',{vObj});
            
            % Assign the properties
            vObj.DataChangedCallback = p.Results.DataChangedCallback;
            
        end
    end %methods
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function delete(vObj)
            
            % Remove the panel and all children
            if ishandle(vObj.hPanel)
                delete(vObj.hPanel);
            end
            
        end
    end %methods
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Static Methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Static = true)
        
        function varargout = callCallback( callback, varargin )
            %callCallback  Try to call a callback function or method
            %
            %   ViewerBase.callCallback(@FCN,ARG1,ARG2,...) calls the function
            %   specified by the supplied function handle @FCN, passing it the supplied
            %   extra arguments.
            %
            %   ViewerBase.callCallback(FCNCELL,ARG1,ARG2,...) calls the function
            %   specified by the first item in cell array FCNCELL, passing the extra
            %   arguments ARG1, ARG2 etc before any additional arguments in the cell
            %   array.
            %
            %   ViewerBase.callCallback(FUNCNAME,ARG1,ARG2,...) calls the function
            %   specified by the string FUNCNAME, passing the supplied extra arguments.
            %
            %   [OUT1,OUT2,...] = ViewerBase.callCallback(...) also captures return
            %   arguments. Note that the function called must provide exactly the right
            %   number of output arguments.
            %
            %   Use this function to handle firing callbacks from widgets.
            %
            %   Examples:
            %   >> callback = {@horzcat, 5, 6};
            %   >> c = VolumeEditor.callCallback( callback, 1, 2, 3, 4 )
            %   c =
            %       1  2  3  4  5  6
            
            if isempty( callback ) % empty
                return
            elseif iscell( callback ) % cell array
                inargs = [callback(1), varargin, callback(2:end)];
                [varargout{1:nargout}] = feval( inargs{:} );
            elseif ischar( callback ) % expression
                eval( callback );
                return
            else % function handle or string
                inargs = [{callback}, varargin];
                [varargout{1:nargout}] = feval( inargs{:} );
            end
        end
        
    end %static methods
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Get Methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % MATLAB calls a property's get method whenever the property value is
    % queried, if a get method for that property exists.
    methods
        
        function value = get.Parent(vObj)
            % Get the property from the HG panel
            value = get(vObj.hPanel,'Parent');
        end
        
        function value = get.Position(vObj)
            % Get the property from the HG panel
            value = get(vObj.hPanel,'Position');
        end
        
        function value = get.Units(vObj)
            % Get the property from the HG panel
            value = get(vObj.hPanel,'Units');
        end
        
        function value = get.Visible(vObj)
            % Get the property from the HG panel
            value = get(vObj.hPanel,'Visible');
        end
        
    end %get methods
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Set Methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        % Set methods customize the behavior that occurs when a property
        % value is set.
        
        function set.Enable(vObj,value)
            % Set child HG controls
            value = validatestring(value,{'on','off'});
            vObj.Enable = value;
            hDescendants = findobj(vObj.hPanel); %#ok<MCSUP>
            for hDescendants = reshape(hDescendants,1,[])
                if isprop(hDescendants,'Enable')
                    set(hDescendants,'Enable',value)
                end
            end
        end
        
        function set.Parent(vObj,value)
            % Set the property in the HG panel
            set(vObj.hPanel,'Parent',value)
        end
        
        function set.Position(vObj,value)
            % Set the property in the HG panel
            set(vObj.hPanel,'Position',value)
        end
        
        function set.Units(vObj,value)
            % Set the property in the HG panel
            set(vObj.hPanel,'Units',value)
        end
        
        function set.Visible(vObj,value)
            % Set the property in the HG panel
            set(vObj.hPanel,'Visible',value)
        end
        
    end %set methods
    
end %classdef

