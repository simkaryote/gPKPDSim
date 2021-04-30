classdef Summary < UIUtilities.Widget
    % Summary - A widget for displaying summary information from an nx2
    % cell array
    % ---------------------------------------------------------------------
    % Create a widget for visualizing the summary information
    %
    % Syntax:
    %           w = uix.widget.Summary('Property','Value',...)
    %
    % Properties:
    %
    %   AllItems - cell array (nx2) containing item titles (col 1) and
    %   values as strings (col 2)
    %
    % Inherited Properties:
    %
    %   BeingDeleted - Is the object in the process of being deleted
    %   [on|off]
    %
    %   DeleteFcn - Callback to execute when the object is deleted
    %
    %   Enable - allow interaction with this widget [on|off]
    %
    %   IsConstructed - indicate whether construction is complete
    %   [true|false]. Set this true at the end of your constructor method.
    %
    %   Parent - Handle of the parent container or figure [handle]
    %
    %   Position - Position [left bottom width height]
    %
    %   Tag - Tag [string]
    %
    %   Type - The object type (class) [string]
    %
    %   Units - Position units
    %   [inches|centimeters|normalized|points|pixels|characters]
    %
    %   UIContextMenu - Context menu for the object
    %
    %   Visible - Is the control visible on-screen [on|off]
    %
    % Methods:
    %
    %
    %   Callback methods:
    %       none
    %
    % Examples:
    %
    %     AllItems = {'Name','My Name';'Description','My Description'};
    %     fig = figure;
    %     w = uix.widget.Summary('Parent',fig,'AllItems',AllItems);
    %

    % Copyright 2017 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 420 $
    %   $Date: 2017-12-07 14:47:44 -0500 (Thu, 07 Dec 2017) $
    % ---------------------------------------------------------------------

    %% Properties
    properties
        AllItems = cell(0,2)
    end


    %% Constructor / Destructor
    methods

        function obj = Summary( varargin )

            % Create the parent widget
            obj = obj@UIUtilities.Widget();

            % Create the base graphics
            obj.create();

            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});

            % Assign the construction flag
            obj.IsConstructed = true;

            % Redraw the widget
            obj.redraw();

        end %constructor

    end %methods - constructor/destructor


    %% Create graphics
    methods ( Access = 'protected' )
        function create(obj)

            % List
            obj.h.Listbox = uicontrol( ...
                'Parent', obj.UIContainer, ...
                'Style', 'listbox', ...
                'FontSize', 9, ...
                'Enable','inactive',...
                'Units','pixels',...
                'Position',[0 0 1 1],...
                'FontName','FixedWidth',...
                'Value',[],...
                'Max',2);

        end %function create(obj)
    end %methods - create graphics


    %% Redraw graphics
    methods ( Access = 'protected' )
        function redraw(obj)

            % Ensure the construction is complete
            if ~isempty(obj.h)

                % Get widget dimensions
                [width,height] = obj.getpixelsize;
                pad = 0; %padding size

                % Position Selected listbox
                listX = 1+pad;
                listY = 1+pad;
                listW = max(width - pad - listX,0);
                listH = max(height - pad - listY,0);
                set(obj.h.Listbox, 'Position', [listX listY listW listH])

                % Update the listboxsrc text
                FormattedListboxStr = cell(size(obj.AllItems,1)*2,1);
                ct = 1;
                for rowIdx = 1:size(obj.AllItems,1)
                    if ischar(obj.AllItems{rowIdx,2})
                        FormattedListboxStr{ct} = sprintf('<HTML><b><FONT color="black">%s: </Font></b>%s</html>',...
                            obj.AllItems{rowIdx,1},obj.AllItems{rowIdx,2});
                        if ~isempty(obj.AllItems(rowIdx,2))
                            ct = ct+1;
                        end
                    elseif iscell(obj.AllItems{rowIdx,2})
                        FormattedListboxStr{ct} = sprintf('<HTML><b><FONT color="black">%s: </Font></b></html>',...
                            obj.AllItems{rowIdx,1});
                        if ~isempty(obj.AllItems{rowIdx,2})
                            ct = ct+2;
                        else
                            ct = ct+1;
                        end
                        TheseItems = obj.AllItems{rowIdx,2};
                        for itemIdx = 1:numel(TheseItems)
                            FormattedListboxStr{ct} = TheseItems{itemIdx};
                            ct = ct+1;
                        end
                    elseif isnumeric(obj.AllItems{rowIdx,2})
                        FormattedListboxStr{ct} = sprintf('<HTML><b><FONT color="black">%s: </Font></b>%s</html>',...
                            obj.AllItems{rowIdx,1},num2str(obj.AllItems{rowIdx,2}));
                        if ~isempty(obj.AllItems(rowIdx,2))
                            ct = ct+1;
                        end
                    else
                        warning('Internal Error: Cannot update Summary widget due to unsupported type: %s',class(obj.AllItems{rowIdx,2}));
                    end
                    
                    % Increment only if non-empty
                    
                        ct = ct+1;
                    
                end

                set(obj.h.Listbox, 'String', FormattedListboxStr, 'Value', []);

                % Update enables
                set(obj.h.Listbox, 'Enable', 'inactive')

            end

        end %function redraw(obj)
    end %methods - redraw graphics


    %% Get/Set methods
    methods

        % AllItems
        function set.AllItems(obj,value)
            if ~isequal(obj.AllItems, value)
                validateattributes(value,{'cell'},{'size',[NaN 2]})
                obj.AllItems = value;

                % Redraw the component
                obj.redraw();
            end
        end

    end % Get/Set methods


end %classdef