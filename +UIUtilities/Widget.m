classdef (Abstract) Widget < handle & matlab.mixin.SetGet & UIUtilities.ConstructorAcceptsPVPairs
    % Widget  A base class for building graphical widgets
    % ---------------------------------------------------------------------
    % This is an abstract base class and cannot be instantiated. It
    % provides the basic properties needed for a panel that will contain a
    % group of graphics objects to build a complex widget.
    %
    % Properties:
    %
    %   BeingDeleted - Is the object in the process of being deleted
    %   [on|off]
    %
    %   DeleteFcn - Callback to execute when the object is deleted
    %
    %   Enable - allow interaction with this widget [on|off]
    %
    %   Parent - Handle of the parent container or figure [handle]
    %
    %   Position - Position [left bottom width height]
    %
    %   Tag - Tag [char]
    %
    %   Type - The object type (class) [char]
    %
    %   Units - Position units
    %   [inches|centimeters|normalized|points|pixels|characters]
    %
    %   UIContextMenu - Context menu for the object
    %
    %   Visible - Is the control visible on-screen [on|off]
    %
    %
    % Properties you must set in subclass constructor:
    %
    %   IsConstructed - indicate whether construction is complete
    %   [true|false]. Set this true at the end of your subclass constructor
    %   method.
    %
    %
    % Methods you may overload in subclasses:
    %
    %   onResized, onVisibleChanged, onEnableChanged,
    %   onContainerBeingDestroyed
    %
    % Methods you must define in subclasses:
    %
    %   redraw
    %
    
    % Copyright 2017 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 420 $
    %   $Date: 2017-12-07 14:47:44 -0500 (Thu, 07 Dec 2017) $
    % ---------------------------------------------------------------------
      
    %RAJ - TO DO
    %  Figure out what to do with title. (If we use the main panel, we'd
    %  need to do other sizing based on inner position, but then units are
    %  an issue.)
    
    %% Properties
    properties (Dependent=true)
        DeleteFcn = []
        Parent
        Units
        Position
        Tag
        UIContextMenu = []
        Visible
    end
    
    properties
        Enable = 'on'
        Padding = 4
        Spacing = 4
    end
    
    properties (Dependent=true, SetAccess=protected)
        BeingDeleted
        Type
    end
    
    
    %% Protected properties
    properties (SetAccess=protected, Hidden)
        h = struct() %For widgets to store internal handles
        IsConstructed = false
        UIContainer = matlab.ui.container.Panel.empty(0,1);
        Listeners = event.listener.empty(0,1);
    end
    
    
    
    %% Abstract methods
    methods(Abstract=true, Access='protected')
        redraw(obj)
    end % abstract methods
    
    
    %% Constructor and Destructor
    methods
        
        function obj = Widget( varargin )
            
            % Create the container panel
            obj.UIContainer = matlab.ui.container.Panel(...
                'BorderType','none',...
                'FontSize', 10, ...
                'UserData',obj);
            
            % Assign PV pairs to properties
            obj.assignPVPairs(varargin{:});
            
            % Create listeners to resizing of container
            obj.Listeners = [
                event.listener( obj.UIContainer, 'SizeChanged', @obj.onResized )
                event.listener( obj.UIContainer, 'ObjectBeingDestroyed', @obj.onContainerBeingDestroyed )
                ];
            
        end
        
        
        function delete( obj )
            %delete  destroy this control
            %
            % If the user destroys the object, we *must* also remove any
            % graphics
            if ~isempty(obj.UIContainer) && isvalid(obj.UIContainer) &&...
                    ~strcmpi( get( obj.UIContainer, 'BeingDeleted' ), 'on' )
                delete( obj.UIContainer );
            end
        end % delete
        
    end
    
    
    
    %% Public methods
    methods
        
        function hgobj = double( obj )
            %double: Convert to an HG double handle.
            %
            %  D = double(W) converts a widget W to an HG handle D.
            hgobj = obj.UIContainer;
        end % double
        
        function pos = getpixelposition( obj, recursive )
            %getpixelposition: get the absolute pixel position
            %
            %   POS = GETPIXELPOSITION(C) gets the absolute position of the container C
            %   within its parent container. The returned position is in pixels.
            %
            %   POS = GETPIXELPOSITION(C,RECURSE) when RECURSE is set true
            %   will recursively scan the parents of the widget so as to
            %   return the position relative to the figure window.
            if nargin > 1
                % NB: If recursive is false the position part is relative
                % to immediate parent.
                pos = getpixelposition( obj.UIContainer, recursive );
            else
                pos = getpixelposition( obj.UIContainer );
            end
        end % getpixelposition
        
        function [w,h] = getpixelsize( obj )
            %getpixelsize: get the widget size [width,height] in pixels
            %
            %   POS = GETPIXELSIZE(C) or [W,H] = GETPIXELSIZE(C) returns
            %   the size [width,height] of this widget in pixels,
            %   regardless of the widget units.
            pos = getpixelposition( obj.UIContainer, false );
            if nargout==1
                w = pos(3:4);
            else
                w = pos(3);
                h = pos(4);
            end
        end % getpixelsize
        
    end % Public methods
    
    
    
    %% Protected methods for subclasses to overload
    methods ( Access = 'protected' )
        
        function onResized( obj, source, eventData ) %#ok<INUSD>
            %onResized: Callback that fires when the widget is resized.
            obj.redraw();
        end % onResized
        
        function onVisibleChanged( obj, source, eventData ) %#ok<INUSD>
            %onVisibleChanged: Callback that fires when the widget is shown/hidden
        end % onVisibleChanged
        
        function onEnableChanged( obj, source, eventData ) %#ok<INUSD>
            %onEnableChanged: Callback that fires when the widget is enabled/disabled
        end % onEnableChanged
        
        function onContainerBeingDestroyed( obj, source, eventData ) %#ok<INUSD>
            %onContainerBeingDestroyed  Callback that fires when the container dies
            delete( obj );
        end % onContainerBeingDestroyed
        
    end % Protected methods
    
    
    
    %% Get/Set methods
    methods
        
        % BeingDeleted
        function value = get.BeingDeleted( obj )
            value = get( obj.UIContainer, 'BeingDeleted' );
        end
        
        % DeleteFcn
        function value = get.DeleteFcn(obj)
            value = get( obj.UIContainer, 'DeleteFcn' );
        end
        function set.DeleteFcn(obj,value)
            set( obj.UIContainer, 'DeleteFcn', value );
        end
        
        % Enable
        function set.Enable(obj,value)
            value = validatestring(value,{'on','off'});
            if ~strcmpi( obj.Enable, value )
                obj.Enable = value;
                evt = struct( 'Source', obj, 'Value', value );
                obj.onEnableChanged( obj, evt );
            end
            obj.redraw();
        end
        
        % Parent
        function value = get.Parent(obj)
            value = get( obj.UIContainer, 'Parent' );
        end
        function set.Parent(obj,value)
            set( obj.UIContainer, 'Parent', value )
        end
        
        % Position
        function value = get.Position(obj)
            value = get( obj.UIContainer, 'Position' );
        end
        function set.Position(obj,value)
            set( obj.UIContainer, 'Position', value );
            obj.redraw();
        end
        
        % Padding
        function set.Padding(obj,value)
            validateattributes(value, {'numeric'}, {'scalar','nonnegative','finite'});
            obj.Padding = value;
            obj.redraw();
        end
        
        % Padding
        function set.Spacing(obj,value)
            validateattributes(value, {'numeric'}, {'scalar','nonnegative','finite'});
            obj.Spacing = value;
            obj.redraw();
        end
        
        % Tag
        function value = get.Tag( obj )
            value = get( obj.UIContainer, 'Tag' );
        end
        function set.Tag( obj, value )
            if ~strcmpi( obj.Tag, value )
                set( obj.UIContainer, 'Tag', value );
            end
        end
        
        % Title
%         function value = get.Title( obj )
%             value = get( obj.UIContainer, 'Title' );
%         end
%         function set.Title( obj, value )
%             if ~strcmpi( obj.Title, value )
%                 set( obj.UIContainer, 'Title', value );
%             end
%         end
        
        % Type
        function value = get.Type( obj )
            value = class( obj );
        end
        
        % UIContextMenu
        function value = get.UIContextMenu(obj)
            value = get( obj.UIContainer, 'UIContextMenu' );
        end
        function set.UIContextMenu(obj,value)
            if ~isequal( obj.UIContextMenu, value )
                set( obj.UIContainer, 'UIContextMenu', value );
            end
        end
        
        % Units
        function value = get.Units(obj)
            value = get( obj.UIContainer, 'Units' );
        end
        function set.Units(obj,value)
            if ~strcmpi( obj.Units, value )
                set( obj.UIContainer, 'Units', value );
            end
            obj.redraw();
        end
        
        % Visible
        function value = get.Visible(obj)
            value = get( obj.UIContainer, 'Visible' );
        end
        function set.Visible(obj,value)
            if ~strcmpi( obj.Visible, value )
                set( obj.UIContainer, 'Visible', value );
                evt = struct( 'Source', obj, 'Value', value );
                obj.onVisibleChanged( obj, evt );
            end
            obj.redraw();
        end
        
    end % Get/Set methods
    
    
end % classdef
