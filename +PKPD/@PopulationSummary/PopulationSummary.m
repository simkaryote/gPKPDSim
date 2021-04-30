classdef PopulationSummary < handle & UIUtilities.ConstructorAcceptsPVPairs
    % PopulationSummary - Defines a complete PopulationSummary
    % ---------------------------------------------------------------------
    % Abstract: This object defines a complete PopulationSummary setup
    %
    % Syntax:
    %           obj = PKPD.PopulationSummary
    %           obj = PKPD.PopulationSummary('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % PKPD.PopulationSummary Properties:
    %
    %    Name - Name of population summary
    %
    %    Time - Time vector
    %
    %    P50 - P50 statistic vector
    %
    %    P5 - P5 statistic vector
    %
    %    P95 - P95 statistic vector
    %
    %
    % PKPD.PopulationSummary Methods:
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
        Time = []        
        P50 = []
        P5 = []
        P95 = []   
    end
    
  
    %% Constructor
    methods
        function obj = PopulationSummary(varargin)
            % PopulationSummary - Constructor for PKPD.PopulationSummary
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new PKPD.PopulationSummary object.
            %
            % Syntax:
            %           obj = PKPD.PopulationSummary('Parameter1',Value1,...)
            %
            % Inputs:
            %           PopulationSummary-value pairs
            %
            % Outputs:
            %           obj - PKPD.PopulationSummary object
            %
            % Example:
            %    aObj = PKPD.PopulationSummary();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
        end %function obj = PopulationSummary(varargin)
        
    end %methods
   
    
    %% Set Methods
    methods
    
        function set.Name(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.Name = Value;
        end %function
        
        function set.Time(obj,Value)
            validateattributes(Value,{'numeric'},{});
            obj.Time = Value;
        end %function
        
        function set.P50(obj,Value)
            validateattributes(Value,{'numeric'},{});
            obj.P50 = Value;
        end %function
        
        function set.P5(obj,Value)
            validateattributes(Value,{'numeric'},{});
            obj.P5 = Value;
        end %function
        
        function set.P95(obj,Value)
            validateattributes(Value,{'numeric'},{});
            obj.P95 = Value;
        end %function
        
        
    end %methods
end %classdef
