classdef (Abstract) ConstructorAcceptsPVPairs < handle
    % ConstructorAcceptsPVPairs - Allow PV pairs on construction for public
    % properties
    % ---------------------------------------------------------------------
    % Abstract: This is a superclass that accepts PV pairs on construction
    % to populate its public properties
    %
    % Syntax:
    %           obj = NewObject
    %           obj = NewObject('Property','Value',...)
    %
    % ConstructorAcceptsPVPairs Properties:
    %
    %     None
    %
    % ConstructorAcceptsPVPairs Methods:
    %
    %     Method - description
    %
    % Notes:
    %   To use this, the class must derive from this object, and you must
    %   call this somewhere in the constructor to assign properties:
    %
    %       % Populate public properties from P-V input pairs
    %       obj.assignPVPairs(varargin{:});
    %
    %         or
    %
    %       % Populate public properties from P-V input pairs
    %       UnmatchedPairs = obj.assignPVPairs(varargin{:});
    %
    
    % Copyright 2017 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 420 $  $Date: 2017-12-07 14:47:44 -0500 (Thu, 07 Dec 2017) $
    % ---------------------------------------------------------------------
    
    
    %% Constructor
    methods
        function obj = ConstructorAcceptsPVPairs(varargin)
            
            % Assign PV pairs on construction, if called
            obj.assignPVPairs(varargin{:});
            
        end
    end %methods
    
    
    %% Method to parse and assign PV Pairs
    methods (Access = protected)
        function varargout = assignPVPairs(obj,varargin)
            
            % Get a list of public properties
            metaObj = metaclass(obj);
            PropNames = {metaObj.PropertyList.Name}';
            isSettableProp = strcmp({metaObj.PropertyList.SetAccess}','public');
            PublicPropNames = PropNames(isSettableProp);
            
            % Create a parser for all public properties
            p = inputParser;
            if nargout
                p.KeepUnmatched = true;
            end
            for pIdx = 1:numel(PublicPropNames)
                p.addParameter(PublicPropNames{pIdx}, obj.(PublicPropNames{pIdx}));
            end
            
            % Parse the P-V pairs
            p.parse(varargin{:});
            
            % Set just the parameters the user passed in
            ParamNamesToSet = varargin(1:2:end);
            
            % Assign properties
            for ThisName = ParamNamesToSet
                obj.(ThisName{1}) = p.Results.(ThisName{1});
            end
            
            % Return unmatched pairs
            if nargout
                varargout{1} = p.Results.Unmatched;
            end
            
        end
    end %methods
    
end %classdef