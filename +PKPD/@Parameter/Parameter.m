classdef Parameter < handle & UIUtilities.ConstructorAcceptsPVPairs
    % Parameter - Defines a complete Parameter
    % ---------------------------------------------------------------------
    % Abstract: This object defines a complete Parameter setup
    %
    % Syntax:
    %           obj = PKPD.Parameter
    %           obj = PKPD.Parameter('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % PKPD.Parameter Properties:
    %
    %    Name - Name of parameter
    %
    %    Min - Minimum value
    %
    %    Max - Max value
    %
    %    Scale - Linear or log scale
    %
    %    Value - Value of parameter
    %
    %    FlagFit - Flag to fit parameter
    %
    %    FittedVal - Value from fitting
    %
    %    PercCV - Coefficient of variation
    %
    % PKPD.Parameter Methods:
    %
    
    % Copyright 2017 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 421 $  $Date: 2017-12-07 15:07:04 -0500 (Thu, 07 Dec 2017) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties
        Name = '' % Should be derived from Parameter object
        Units = '' % Should be derived from Parameter object
        Min = 0
        Max = 1000
        Scale = 'linear'
        Value = 0
        FlagFit = true
        FittedVal        
        PercCV = 10
    end
    
    
    %% Private Properties
    properties (SetAccess = 'private')
        DefaultValue
    end
    
    
    %% Constructor
    methods
        function obj = Parameter(varargin)
            % Parameter - Constructor for PKPD.Parameter
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new PKPD.Parameter object.
            %
            % Syntax:
            %           obj = PKPD.Parameter('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - PKPD.Parameter object
            %
            % Example:
            %    aObj = PKPD.Parameter();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
        end %function obj = Parameter(varargin)
        
    end %methods
    
    
    %% Methods
    methods
        
        function saveDefaultValue(obj)
            % Save default parameters
            
            if isempty(obj.DefaultValue)
                obj.DefaultValue = obj.Value;
            end
        end
        
        
        function restoreDefaultValue(obj)
            % Restore default parameters
            
            if ~isempty(obj.DefaultValue)
                obj.Value = obj.DefaultValue;
            end
        end
        
        
        function restoreValueFromVariant(obj,ModelObj,Variants)
            % Restore value from variant
            
            ModelParam = sbioselect(ModelObj,'Name',obj.Name,'Type','parameter');
            
            if ~isempty(ModelParam)
                % Store default value from model
                obj.Units = ModelParam.ValueUnits;
                if ~isempty(obj.DefaultValue)
                    obj.Value = obj.DefaultValue;
                else
                    obj.Value = ModelParam.Value;
                end
                
                if ~isempty(Variants)
                    Content = get(Variants,'content');
                    if ~isempty(Content)
                        % Flatten content
                        if size(Content,2) == 1
                            Content = vertcat(Content{:});
                        end
                        if size(Content,2) == 1
                            Content = vertcat(Content{:});
                        end
                        
                        % Only extract parameter type
                        Content = Content(strcmpi(Content(:,1),'parameter'),:);
                        
                        % Get the last occurence of the name match
                        MatchIndex = find(strcmpi(Content(:,2),obj.Name),1,'last');
                        if ~isempty(MatchIndex)
                            % Update value if there is a match
                            obj.Value = Content{MatchIndex,4};
                        end
                    end
                end
                
                % Update min and max to fit the value (new)
                if obj.Value < obj.Min
                    warning('Updating minimum bound for %s',obj.Name);
                    obj.Min = min(obj.Min,obj.Value);
                end
                if obj.Value > obj.Max
                    warning('Updating maximum bound for %s',obj.Name);
                    obj.Max = max(obj.Max,obj.Value);
                end
            end
        end %function
        
    end %methods
    
    
    %% Set Methods
    methods
        function set.Name(obj,Value)
            validateattributes(Value,{'char'},{})
            obj.Name = Value;
        end
        
        function set.Value(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','nonnan'})
            obj.Value = Value;
        end
        
        function set.Min(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','nonnan'})
            obj.Min = Value;
        end
        
        function set.Max(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','nonnan'})
            obj.Max = Value;
        end
        
        function set.Scale(obj,Value)
            Value = validatestring(Value,{'linear','log'});
            obj.Scale = Value;
        end
        
        function set.FlagFit(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'})
            obj.FlagFit = Value;
        end
        
        function set.PercCV(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','nonnan','>=',0,'<=',100})
            obj.PercCV = Value;
        end
        
    end %methods
end %classdef
