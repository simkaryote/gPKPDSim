classdef PlotSettings < matlab.mixin.SetGet & UIUtilities.ConstructorAcceptsPVPairs
    % PlotSettings - Defines a complete PlotSettings
    % ---------------------------------------------------------------------
    % Abstract: This object defines a complete PlotSettings setup
    %
    % Syntax:
    %           obj = PKPD.PlotSettings
    %           obj = PKPD.PlotSettings('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % PKPD.PlotSettings Properties:
    %
    %    LegendVisibility - Turn on/off legend visibility
    %
    %    LegendLocation - Legend location
    %
    %    LegendFontSize - Font size for legend
    %
    %    LegendFontWeight - Font weight for legend
    %
    %    LineWidth - Width of line
    %
    %    DataSymbolSize - Size of data symbol
    %
    %    Title - Title for axes
    %
    %    XLabel - X-label for axes
    %
    %    YLabel - Y-label for axes
    %
    %    TitleFontSize - Font size of title
    %
    %    TitleFontWeight - Font weight of title
    %
    %    XLabelFontSize - Font size of x-label
    %
    %    XLabelFontWeight - Font weight of x-label
    %
    %    YLabelFontSize - Font size of y-label
    %
    %    YLabelFontWeight - Font size of y-label
    %
    %    XTickLabelFontSize - Font size of x-tick labels
    %
    %    XTickLabelFontWeight - Font weight of x-tick labels
    %
    %    YTickLabelFontSize - Font size of y-tick labels
    %
    %    YTickLabelFontWeight - Font weight of y-tick labels
    %
    %    YScale - Scale of y-axes
    %
    %    XGrid - Turn on/off x-grid
    %
    %    YGrid - Turn on/off y-grid
    %
    %    XMinorGrid - Turn on/off x minor grid
    %
    %    YMinorGrid - Turn on/off y minor grid
    %
    %    XLimMode - x limits mode from MATLAB
    %
    %    YLimMode - y limits mode from MATLAB
    %
    %    CustomXLim - Custom x limits if XLimMode is manual
    %
    %    CustomYLim - Custom y limits if XLimMode is manual    %
    %
    %
    % PKPD.PlotSettings Methods:
    %
    
    % Copyright 2017 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 421 $  $Date: 2017-12-07 15:07:04 -0500 (Thu, 07 Dec 2017) $
    % ---------------------------------------------------------------------
   
    %% Private Properties
    properties(SetAccess=private,Transient=true)        
        hAxes        
    end
    
    %% Public Properties
    properties
        LegendVisibility = 'on'
        LegendLocation = 'northeast'
        LegendFontSize = 10
        LegendFontWeight = 'normal'    
        
        LineWidth = 0.5         
        DataSymbolSize = 6
    end

    %% Dependent Properties
    properties (Dependent=true)
        Title = ''
        XLabel = ''
        YLabel = ''
        
        TitleFontSize = 10
        TitleFontWeight = 'normal'
        
        XLabelFontSize = 10
        XLabelFontWeight = 'normal'
        
        YLabelFontSize = 10
        YLabelFontWeight = 'normal'
        
        XTickLabelFontSize = 10
        XTickLabelFontWeight = 'normal'
        
        YTickLabelFontSize = 10
        YTickLabelFontWeight = 'normal'
        
        YScale = 'linear'
        XGrid = 'off'      
        YGrid = 'off' 
        XMinorGrid = 'off' 
        YMinorGrid = 'off' 
                
        XLimMode = 'auto'
        YLimMode = 'auto'   
        CustomXLim = ''
        CustomYLim = ''
    end
    
    
     %% Dependent Properties
    properties (Dependent=true,SetAccess=private)
        HighlightLineWidth = 2
    end
    
    
    %% Constant Properties
    properties(Constant=true)
        FontWeightOptions = {
            'normal'
            'bold'
            }
        
        LegendOptions = {
            'on'
            'off'
            }
        
        LegendLocationOptions = {
            'north'
            'south'
            'east'
            'west'
            'northeast'
            'northwest'
            'southeast'
            'southwest'
            'northoutside'
            'southoutside'
            'eastoutside'
            'westoutside'
            'northeastoutside' 
            'northwestoutside'
            'southeastoutside'
            'southwestoutside'
            ...'best' % Requires special handling for export
            ...'bestoutside' % Requires special handling for export
            }
        
        GridOptions = {
            'on'
            'off'
            }
        
        YScaleOptions = {
            'linear'
            'log'
        }
    
        XYLimModeOptions = {
            'auto'
            'manual'
            }
        
        SettablePropertiesGroup1 = {
            'Title','char';
            'XLabel','char';
            'YLabel','char';            
        }
    
        SettablePropertiesGroup2 = {
            'TitleFontSize','numeric';
            'TitleFontWeight',PKPD.PlotSettings.FontWeightOptions(:)';
            'XLabelFontSize','numeric';
            'XLabelFontWeight',PKPD.PlotSettings.FontWeightOptions(:)';
            'YLabelFontSize','numeric';
            'YLabelFontWeight',PKPD.PlotSettings.FontWeightOptions(:)';
            'XTickLabelFontSize','numeric';
            'XTickLabelFontWeight',PKPD.PlotSettings.FontWeightOptions(:)';        
            'YTickLabelFontSize','numeric';
            'YTickLabelFontWeight',PKPD.PlotSettings.FontWeightOptions(:)';
            }
    
        SettablePropertiesGroup3 = {
            'YScale',PKPD.PlotSettings.YScaleOptions(:)';
            'XGrid',PKPD.PlotSettings.GridOptions(:)';
            'YGrid',PKPD.PlotSettings.GridOptions(:)';
            'XMinorGrid',PKPD.PlotSettings.GridOptions(:)';
            'YMinorGrid',PKPD.PlotSettings.GridOptions(:)';
            'XLimMode',PKPD.PlotSettings.XYLimModeOptions(:)';
            'YLimMode',PKPD.PlotSettings.XYLimModeOptions(:)';
            'CustomXLim','char'; % To support vector
            'CustomYLim','char'; % To support vector
            }
        
        SettablePropertiesGroup4 = {
            'LineWidth','numeric';
            'DataSymbolSize','numeric';
            'LegendVisibility',PKPD.PlotSettings.LegendOptions(:)';
            'LegendLocation',PKPD.PlotSettings.LegendLocationOptions(:)';
            'LegendFontSize','numeric';
            'LegendFontWeight',PKPD.PlotSettings.FontWeightOptions(:)';            
            }
    
        SettableProperties = vertcat(...
            PKPD.PlotSettings.SettablePropertiesGroup1,...
            PKPD.PlotSettings.SettablePropertiesGroup2,...
            PKPD.PlotSettings.SettablePropertiesGroup3,...
            PKPD.PlotSettings.SettablePropertiesGroup4...
            )
    end
   
    
    %% Constructor
    methods
        function obj = PlotSettings(hAxes,varargin)
            % PlotSettings - Constructor for PKPD.PlotSettings
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new PKPD.PlotSettings object.
            %
            % Syntax:
            %           obj = PKPD.PlotSettings('Parameter1',Value1,...)
            %
            % Inputs:
            %           PlotSettings-value pairs
            %
            % Outputs:
            %           obj - PKPD.PlotSettings object
            %
            % Example:
            %    aObj = PKPD.PlotSettings();
            
            % Populate public properties from P-V input pairs
            obj.hAxes = hAxes;
            obj.assignPVPairs(varargin{:});
            
        end %function obj = PlotSettings(varargin)
        
    end %methods
    
    
    %% Methods
    methods
        
        function Summary = getSummary(obj,varargin)    
            if nargin > 1 && ischar(varargin{1}) && ...
                    any(strcmpi(varargin{1},{'SettablePropertiesGroup1','SettablePropertiesGroup2','SettablePropertiesGroup3','SettablePropertiesGroup4'}))
                PropStr = varargin{1};
            else
                PropStr = 'SettableProperties';
            end
            
            for oIndex = 1:numel(obj)
                for index = 1:size(obj(oIndex).(PropStr),1)
                    Summary(oIndex).(obj(oIndex).(PropStr){index,1}) = obj(oIndex).(obj(oIndex).(PropStr){index,1}); %#ok<AGROW>
                end
            end
        end %function      
        
        
        function setLegend(obj,Value)
            if ishandle(Value) && isa(Value,'matlab.graphics.illustration.Legend')
                obj.hLegend = Value;
            end
        end %function
        
        
        function setLine(obj,Value)
            if ishandle(Value)
                obj.hLine = Value;
            end
        end %function
            
    end %methods
    
    
    %% Get/Set Methods
    methods
        
        function Value = get.Title(obj)      
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'Title');
                Value = get(hThis,'String');
            else
                Value = '';
            end
        end %function            
        function set.Title(obj,Value)
            validateattributes(Value,{'char'},{})
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'title');
                set(hThis,'String',Value);            
            end
        end %function
        
        
        function Value = get.XLabel(obj)
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'xlabel');
                Value = get(hThis,'String');
            else
                Value = '';
            end
        end %function
        function set.XLabel(obj,Value)
            validateattributes(Value,{'char'},{})
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'xlabel');
                set(hThis,'String',Value);   
            end
        end %function
        
        
        function Value = get.YLabel(obj)
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'ylabel');
                Value = get(hThis,'String');
            else
                Value = '';
            end
        end %function
        function set.YLabel(obj,Value)
            validateattributes(Value,{'char'},{})
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'ylabel');
                set(hThis,'String',Value);   
            end
        end %function
        
        
        function Value = get.XLabelFontSize(obj)
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'xlabel');
                Value = get(hThis,'FontSize');
            else
                Value = 11;
            end            
        end %function
        function set.XLabelFontSize(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','nonnegative','nonnan'})
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'xlabel');
                set(hThis,'FontSize',Value); 
            end
        end %function
        
        
        function Value = get.YLabelFontSize(obj)
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'ylabel');
                Value = get(hThis,'FontSize');
            else
                Value = 11;
            end
        end %function
        function set.YLabelFontSize(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','nonnegative','nonnan'})
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'ylabel');
                set(hThis,'FontSize',Value); 
            end
        end %function
        
        
        function Value = get.TitleFontSize(obj)
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'title');
                Value = get(hThis,'FontSize');
            else
                Value = 11;
            end
        end %function
        function set.TitleFontSize(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','nonnegative','nonnan'})
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'title');
                set(hThis,'FontSize',Value);     
            end
        end %function
        
        
        function Value = get.XTickLabelFontSize(obj)            
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'XRuler');
                Value = get(hThis,'FontSize');
            else
                Value = 10;
            end
        end %function
        function set.XTickLabelFontSize(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','nonnegative','nonnan'})
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'XRuler');
                hLabel = get(obj.hAxes,'xlabel');
                LabelFontSize = get(hLabel,'FontSize');
                set(hThis,'FontSize',Value);
                set(hLabel,'FontSize',LabelFontSize);
            end
        end %function
        
        
        function Value = get.YTickLabelFontSize(obj)
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'YRuler');
                Value = get(hThis,'FontSize');
            else
                Value = 10;
            end
        end %function
        function set.YTickLabelFontSize(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','nonnegative','nonnan'})
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hLabel = get(obj.hAxes,'ylabel');
                LabelFontSize = get(hLabel,'FontSize');
                hThis = get(obj.hAxes,'YRuler');
                set(hThis,'FontSize',Value);
                set(hLabel,'FontSize',LabelFontSize);
            end
        end %function
        
        
        function Value = get.XLabelFontWeight(obj)
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'xlabel');
                Value = get(hThis,'FontWeight');
            else
                Value = 'normal';
            end
        end %function
        function set.XLabelFontWeight(obj,Value)
            Value = validatestring(Value,obj.FontWeightOptions);
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'xlabel');
                set(hThis,'FontWeight',Value);
            end
        end %function
        
        
        function Value = get.YLabelFontWeight(obj)
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'ylabel');
                Value = get(hThis,'FontWeight');
            else
                Value = 'normal';
            end
        end %function
        function set.YLabelFontWeight(obj,Value)
            Value = validatestring(Value,obj.FontWeightOptions);
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'ylabel');
                set(hThis,'FontWeight',Value);
            end
        end %function
        
        
        function Value = get.TitleFontWeight(obj)
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'Title');
                Value = get(hThis,'FontWeight');
            else
                Value = 'normal';
            end
        end %function
        function set.TitleFontWeight(obj,Value)
            Value = validatestring(Value,obj.FontWeightOptions);
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'title');
                set(hThis,'FontWeight',Value);
            end
        end %function
        
        
        function Value = get.XTickLabelFontWeight(obj)
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'XRuler');
                Value = get(hThis,'FontWeight');
            else
                Value = 'normal';
            end
        end %function
        function set.XTickLabelFontWeight(obj,Value)
            Value = validatestring(Value,obj.FontWeightOptions);
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hLabel = get(obj.hAxes,'xlabel');
                LabelFontWeight = get(hLabel,'FontWeight');
                hThis = get(obj.hAxes,'XRuler');
                set(hThis,'FontWeight',Value);
                set(hLabel,'FontWeight',LabelFontWeight);
            end
        end %function
        
        
        function Value = get.YTickLabelFontWeight(obj)
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hThis = get(obj.hAxes,'YRuler');
                Value = get(hThis,'FontWeight');
            else
                Value = 'normal';
            end
        end %function
        function set.YTickLabelFontWeight(obj,Value)
            Value = validatestring(Value,obj.FontWeightOptions);
            if ~isempty(ancestor(obj.hAxes,'figure'))
                hLabel = get(obj.hAxes,'ylabel');
                LabelFontWeight = get(hLabel,'FontWeight');
                hThis = get(obj.hAxes,'YRuler');
                set(hThis,'FontWeight',Value);
                set(hLabel,'FontWeight',LabelFontWeight);
            end
        end %function

        
        function Value = get.XGrid(obj)
            if ~isempty(ancestor(obj.hAxes,'figure'))
                Value = get(obj.hAxes,'XGrid');         
            else
                Value = 'on';
            end
        end %function
        function set.XGrid(obj,Value)
            Value = validatestring(Value,obj.GridOptions);
            if ~isempty(ancestor(obj.hAxes,'figure'))
                set(obj.hAxes,'XGrid',Value);            
            end
        end %function
        
        
        function Value = get.YGrid(obj)
            if ~isempty(ancestor(obj.hAxes,'figure'))
                Value = get(obj.hAxes,'YGrid');  
            else
                Value = 'on';
            end
        end %function
        function set.YGrid(obj,Value)
            Value = validatestring(Value,obj.GridOptions);
            if ~isempty(ancestor(obj.hAxes,'figure'))
                set(obj.hAxes,'YGrid',Value);            
            end
        end %function
        
        
        function Value = get.XMinorGrid(obj)
            if ~isempty(ancestor(obj.hAxes,'figure'))
                Value = get(obj.hAxes,'XMinorGrid');         
            else
                Value = 'on';
            end
        end %function
        function set.XMinorGrid(obj,Value)
            Value = validatestring(Value,obj.GridOptions);
            if ~isempty(ancestor(obj.hAxes,'figure'))
                set(obj.hAxes,'XMinorGrid',Value);            
            end
        end %function
        
        
        function Value = get.YMinorGrid(obj)
            if ~isempty(ancestor(obj.hAxes,'figure'))
                Value = get(obj.hAxes,'YMinorGrid');
            else
                Value = 'on';
            end
        end %function
        function set.YMinorGrid(obj,Value)
            Value = validatestring(Value,obj.GridOptions);
            if ~isempty(ancestor(obj.hAxes,'figure'))
                set(obj.hAxes,'YMinorGrid',Value);            
            end
        end %function
        
        
        function Value = get.YScale(obj)
            if ~isempty(ancestor(obj.hAxes,'figure'))
                Value = get(obj.hAxes,'YScale');            
            else
                Value = 'linear';
            end 
        end %function
        function set.YScale(obj,Value)
            Value = validatestring(Value,obj.YScaleOptions);
            if ~isempty(ancestor(obj.hAxes,'figure'))
                set(obj.hAxes,'YScale',Value);
            end
        end %function
        
        
        function Value = get.XLimMode(obj)
            if ~isempty(ancestor(obj.hAxes,'figure'))
                Value = get(obj.hAxes,'XLimMode');            
            else
                Value = 'auto';
            end
        end %function
        function set.XLimMode(obj,Value)
            Value = validatestring(Value,obj.XYLimModeOptions);  
            if ~isempty(ancestor(obj.hAxes,'figure'))
                set(obj.hAxes,'XLimMode',Value);    
            end
        end %function
        
        
        function Value = get.YLimMode(obj)
            if ~isempty(ancestor(obj.hAxes,'figure'))
                Value = get(obj.hAxes,'YLimMode');   
            else
                Value = 'auto';
            end
        end %function
        function set.YLimMode(obj,Value)
            Value = validatestring(Value,obj.XYLimModeOptions);  
            if ~isempty(ancestor(obj.hAxes,'figure'))
                set(obj.hAxes,'YLimMode',Value);            
            end
        end %function
        
        
        function Value = get.CustomXLim(obj)
            if ~isempty(ancestor(obj.hAxes,'figure'))
                Value = num2str(get(obj.hAxes,'XLim')); % As string (for use in table)      
            else
                Value = [0 1];
            end
        end %function
        function set.CustomXLim(obj,Value)
            if ischar(Value)
                Value = str2num(Value); %#ok<ST2NM>  % As string (for use in table)
            end
            validateattributes(Value,{'numeric'},{'size',[1 2],'increasing','nonnan'});
            if ~isempty(ancestor(obj.hAxes,'figure'))
                CurrXLimMode = get(obj.hAxes,'XLimMode');
                if strcmpi(CurrXLimMode,'manual')
                    set(obj.hAxes,'XLim',Value);
                end
            end
        end %function
        
        
        function Value = get.CustomYLim(obj)
            if ~isempty(ancestor(obj.hAxes,'figure'))
                Value = num2str(get(obj.hAxes,'YLim')); % As string (for use in table)
            else
                Value = [0 1];
            end
        end %function
        function set.CustomYLim(obj,Value)
            if ischar(Value)
                Value = str2num(Value); %#ok<ST2NM>  % As string (for use in table)
            end
            validateattributes(Value,{'numeric'},{'size',[1 2],'increasing','nonnan'});
            if ~isempty(ancestor(obj.hAxes,'figure'))
                CurrYLimMode = get(obj.hAxes,'YLimMode');
                if strcmpi(CurrYLimMode,'manual')
                    set(obj.hAxes,'YLim',Value);
                end
            end
        end %function
        
        
        function set.LegendVisibility(obj,Value)
            Value = validatestring(Value,obj.LegendOptions);
            obj.LegendVisibility = Value;
        end %function
        
        
        function set.LegendLocation(obj,Value)
            Value = validatestring(Value,obj.LegendLocationOptions);
            obj.LegendLocation = Value;
        end %function
        
        
        function set.LegendFontSize(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','nonnegative','nonnan'})
            obj.LegendFontSize = Value;
        end %function
        
        
        function set.LegendFontWeight(obj,Value)
            Value = validatestring(Value,obj.FontWeightOptions);
            obj.LegendFontWeight = Value;
        end %function
        
       
        function set.LineWidth(obj,Value)            
            validateattributes(Value,{'numeric'},{'scalar','nonnegative','nonnan'})
            obj.LineWidth = Value;
        end %function
        
        
        function Value = get.HighlightLineWidth(obj)
            Value = min(obj.LineWidth*2,10);
        end %function
        
        
        function set.DataSymbolSize(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','nonnegative','nonnan'})
            obj.DataSymbolSize = Value;
        end %function
        
    end %methods
end %classdef
