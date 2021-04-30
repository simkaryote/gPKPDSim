classdef Dataset < handle & UIUtilities.ConstructorAcceptsPVPairs
    % Dataset - Defines a complete Dataset
    % ---------------------------------------------------------------------
    % Abstract: This object defines a complete Dataset setup
    %
    % Syntax:
    %           obj = PKPD.Dataset
    %           obj = PKPD.Dataset('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % PKPD.Dataset Properties:
    %
    %    Name - Name of dataset
    %
    %    Filepath - File path of dataset
    %
    %    Time - Time name
    %
    %    Group - Group name
    %
    %    YAxis - Y-axis name
    %
    %    Dosing - Dosing name
    %
    %    Sparse - Sparse dataset flag (For NCA)
    %
    %    Subgroup - Subgroup name (For NCA)
    %
    %    IVDose - IVDose name (For NCA)
    %
    %    SCDose - SCDose name (For NCA)
    %
    %    Concentration - Concentration name (For NCA)
    %
    %    AUCTimePoints - List of AUC time points (For NCA)
    %
    %    CmaxTimePoints - Cmax time points (For NCA)
    %
    %    AutomaticHalfLifeEstimation - Flag to perform automatic half-life estimation (For NCA)
    %
    %    HalfLifeEstimationTimePoints - Half-life estimation time points (For NCA)
    %
    %    Headers - Dataset headers
    %
    %
    % PKPD.Dataset Methods:
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
        % For Fitting
        Name = ''
        FilePath = ''
        Time = ''
        Group = ''
        YAxis = {}
        Dosing = {}
        
        % For NCA
        Sparse = true
        Subgroup = ''
        IVDose = ''
        SCDose = ''
        Concentration = ''
        AUCTimePoints = []
        CmaxTimePoints = []
        AutomaticHalfLifeEstimation = true
        HalfLifeEstimationTimePoints = []        
        
        % Headers
        Headers = {}
    end
    
    
    %% Constructor
    methods
        function obj = Dataset(varargin)
            % Dataset - Constructor for PKPD.Dataset
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new PKPD.Dataset object.
            %
            % Syntax:
            %           obj = PKPD.Dataset('Parameter1',Value1,...)
            %
            % Inputs:
            %           Dataset-value pairs
            %
            % Outputs:
            %           obj - PKPD.Dataset object
            %
            % Example:
            %    aObj = PKPD.Dataset();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
        end %function obj = Dataset(varargin)
        
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
            
            ModelParam = sbioselect(ModelObj,'Name',obj.Name,'Type','Dataset');
            
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
                        
                        % Only extract Dataset type
                        Content = Content(strcmpi(Content(:,1),'Dataset'),:);
                        
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
        
        function set.FilePath(obj,Value)
            validateattributes(Value,{'char'},{})
            obj.FilePath = Value;
        end
        
        function set.Time(obj,Value)
            validateattributes(Value,{'char'},{})
            obj.Time = Value;
        end
        
        function set.Group(obj,Value)
            validateattributes(Value,{'char'},{})
            obj.Group = Value;
        end
        
        function set.YAxis(obj,Value)
            if ischar(Value)
                Value = {Value};
            end
            validateattributes(Value,{'cell'},{})
            obj.YAxis = Value;
        end
        
        function set.Dosing(obj,Value)
            if ischar(Value)
                Value = {Value};
            end
            validateattributes(Value,{'cell'},{})
            obj.Dosing = Value;
        end
        
        function set.Subgroup(obj,Value)
            validateattributes(Value,{'char'},{})
            obj.Subgroup = Value;
        end
        
        function set.IVDose(obj,Value)
            validateattributes(Value,{'char'},{})
            obj.IVDose = Value;
        end
        
        function set.SCDose(obj,Value)
            validateattributes(Value,{'char'},{})
            obj.SCDose = Value;
        end
        
        function set.Concentration(obj,Value)
            validateattributes(Value,{'char'},{})
            obj.Concentration = Value;
        end
        
        function set.Sparse(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'})
            obj.Sparse = Value;
        end
       
        function set.AUCTimePoints(obj,Value)
            validateattributes(Value,{'numeric'},{})
            obj.AUCTimePoints = Value;
        end
        
        function set.CmaxTimePoints(obj,Value)
            validateattributes(Value,{'numeric'},{})
            obj.CmaxTimePoints = Value;
        end
        
        function set.AutomaticHalfLifeEstimation(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'})
            obj.AutomaticHalfLifeEstimation = Value;
        end
        
        function set.HalfLifeEstimationTimePoints(obj,Value)
            validateattributes(Value,{'numeric'},{})
            obj.HalfLifeEstimationTimePoints = Value;
        end
        
        function set.Headers(obj,Value)
            validateattributes(Value,{'cell'},{})
            obj.Headers = Value;
        end
        
    end %methods
end %classdef
