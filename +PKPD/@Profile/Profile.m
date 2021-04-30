classdef Profile < handle & UIUtilities.ConstructorAcceptsPVPairs
    % Profile - Defines a complete Profile
    % ---------------------------------------------------------------------
    % Abstract: This object defines a complete Profile setup
    %
    % Syntax:
    %           obj = PKPD.Profile
    %           obj = PKPD.Profile('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % PKPD.Profile Properties:
    %
    %    Name - Name of profile item
    %
    %    Description - Description of item
    %
    %    Show - Flag to toggle visibility on/off
    %
    %    Export - Flag to select for export
    %
    %    NCA - Unused
    %
    %    Species - Unused
    %
    %    Color - Color of item
    %
    %    NumPopulationRuns - Number of simulations (population task only)
    %
    %
    % PKPD.Profile Methods:
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
        Name = ''
        Description = ''
        Show = true
        Export = true
        NCA = 'None'
        Species = ''      
        Color = [1 0 0]
        NumPopulationRuns = nan
    end
    
    
    %% Private Properties
    properties (SetAccess = 'private')        
        VariantNames = {}
        DoseNames = {}
        DosingTable = {}
        ParametersTable = {}        
    end
    
    
    %% Constructor
    methods
        function obj = Profile(varargin)
            % Profile - Constructor for PKPD.Profile
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new PKPD.Profile object.
            %
            % Syntax:
            %           obj = PKPD.Profile('Parameter1',Value1,...)
            %
            % Inputs:
            %           Profile-value pairs
            %
            % Outputs:
            %           obj - PKPD.Profile object
            %
            % Example:
            %    aObj = PKPD.Profile();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
        end %function obj = Profile(varargin)
        
    end %methods
    
    
    %% Methods
    methods
        
        function populate(obj,Variants,Doses,SelectedParams,varargin)
            
            if nargin > 4
                obj.NumPopulationRuns = varargin{1};
            else
                obj.NumPopulationRuns = NaN;
            end
            
            % Variants
            if isempty(Variants)
                obj.VariantNames = {};
            else
                ThisName = get(Variants,'Name');
                if ischar(ThisName)
                    ThisName = {ThisName};
                end
                obj.VariantNames = ThisName;
            end
            
            % Doses
            if isempty(Doses)
                obj.DoseNames = {};
            else
                ThisName = get(Doses,'Name');
                if ischar(ThisName)
                    ThisName = {ThisName};
                end
                obj.DoseNames = ThisName;
            end
            
            % Dosing Table
            if numel(Doses) == 1
                obj.DosingTable = [...
                    {get(Doses,'Name')},...
                    {get(Doses,'Type')},...
                    {get(Doses,'TargetName')},...
                    {get(Doses,'StartTime')},...
                    {get(Doses,'TimeUnits')},...
                    {get(Doses,'Amount')},...
                    {get(Doses,'AmountUnits')},...
                    {get(Doses,'Interval')},...
                    {get(Doses,'Rate')},...
                    {get(Doses,'RepeatCount')},...
                    ];
            else
                obj.DosingTable = [...
                    get(Doses,'Name'),...
                    get(Doses,'Type'),...
                    get(Doses,'TargetName'),...
                    get(Doses,'StartTime'),...
                    get(Doses,'TimeUnits'),...
                    get(Doses,'Amount'),...
                    get(Doses,'AmountUnits'),...
                    get(Doses,'Interval'),...
                    get(Doses,'Rate'),...
                    get(Doses,'RepeatCount'),...
                    ];
            end
            
            % Parameters
            TableData = [{SelectedParams.Name}' {SelectedParams.Value}'];
            obj.ParametersTable = TableData;
            
        end %function
            
        function Summary = getSummary(obj)
            
            % NumPopulationRuns is NaN for Simulation
            if ~isnan(obj.NumPopulationRuns)
                
                Summary = { % Exclude ID
                    obj.Description,...
                    obj.NumPopulationRuns,...
                    obj.Show,...
                    obj.Export,...                
                    ...obj.NCA,...
                    ...obj.Species                
                    };
                
            else
                
                 Summary = { % Exclude ID
                    obj.Description,...                    
                    obj.Show,...
                    obj.Export,...                
                    ...obj.NCA,...
                    ...obj.Species                
                    };
            end
            
            
        end %function
        
        function Content = getDetailedContent(obj)
            
            % Description
            Content = cell(0,2);
            
            % Variants
            if ~isempty(obj.VariantNames)
                ThisContent = {...
                    'Variants (Ordered)',obj.VariantNames;
                    };
            else
                ThisContent = {...
                    'Variants (Ordered)','NONE';
                    };
            end
            Content = [Content;ThisContent];
            
            % Dosing
            DoseLabels = {
                    'Type',...
                    'Target Name',...
                    'Start Time',...
                    'Time Units',...
                    'Amount',...
                    'Amount Units',...
                    'Interval',...
                    'Rate',...
                    'Repeat Count'...
                    };
            if ~isempty(obj.DosingTable)
                FormattedDoseTable = obj.DosingTable(:,2:end);
                % Convert numeric to string
                IsNumeric = cellfun(@isnumeric,FormattedDoseTable);
                FormattedDoseTable(IsNumeric) = cellfun(@(x)num2str(x),FormattedDoseTable(IsNumeric),'UniformOutput',false);

                % Iterate through dose table
                for index = 1:size(obj.DosingTable,1)
                    DoseContent = cellfun(@(x,y)sprintf('%s: %s',x,y),...
                        DoseLabels,FormattedDoseTable(index,:),...
                        'UniformOutput',false);

                    ThisContent = {...
                        sprintf('Dose: %s',obj.DosingTable{index,1}),DoseContent;
                        };

                    % Append
                    Content = [Content;ThisContent]; %#ok<AGROW>
                end
            else
                ThisContent = {...
                    'Dose','NONE';
                    }; 
                Content = [Content;ThisContent];
            end
                
            % Parameter
            if ~isempty(obj.ParametersTable)
                ParamContent = cellfun(@(x,y)sprintf('%s: %f',x,y),...
                    obj.ParametersTable(:,1),obj.ParametersTable(:,2),...
                    'UniformOutput',false);
                ThisContent = {...
                    'Parameters',ParamContent;
                    };
            else
                ThisContent = {...
                    'Parameters','NONE';
                    };
            end
            Content = [Content;ThisContent];
            
            % NaN for Simulation
            if ~isnan(obj.NumPopulationRuns)
                ThisContent = {...
                    'No. of Simulations',obj.NumPopulationRuns;
                    };          
                Content = [Content;ThisContent];
            end
            
        end %function
    end
    
    
    %% Set Methods
    methods
        
        function set.Name(obj,Value)
            validateattributes(Value,{'char'},{})
            obj.Name = Value;
        end
        
        function set.Description(obj,Value)
            validateattributes(Value,{'char'},{})
            obj.Description = Value;
        end
        
        function set.Show(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'})
            obj.Show = Value;
        end
        
        function set.Export(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'})
            obj.Export = Value;
        end
        
        function set.NCA(obj,Value)            
            Value = validatestring(Value,PKPD.Analysis.NCADosingTypes);
            obj.NCA = Value;
        end
        
        function set.Species(obj,Value)
            validateattributes(Value,{'char'},{})
            obj.Species = Value;
        end
        
    end %methods
end %classdef
