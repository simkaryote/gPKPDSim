classdef Empty < UIUtilities.ViewerBase
    % Empty - Class definition for Empty viewer
    % ---------------------------------------------------------------------
    % Abstract: Display a viewer/editor for a PKPD.Empty object
    %
    % Syntax:
    %           vObj = PKPDViewer.Empty
    %           vObj = PKPDViewer.Empty('Property','Value',...)
    %
    % PKPDViewer.Empty Properties:
    %
    %     Data - The data that will be displayed by the viewer
    %
    %     DataChangedCallback - A settable callback that will fire when the
    %     viewer's Data is modified.
    %
    %     Enable - controls whether the HG controls in the viewer are
    %     enabled or disabled
    %
    %     Title - An optional title for the viewer
    %
    %     Parent - handle graphics parent for the viewer, which should be
    %     a valid container including figure, uipanel, or uitab
    %
    %     Position - position of the viewer within the parent container
    %
    %     Units - units of the viewer within the parent container, used for
    %     determining the position
    %
    % PKPDViewer.Empty methods:
    %
    %     callCallback - call a user-specified callback function
    %
    %   Callback methods:
    %       none
    %
    %
    % Examples:
    %  vObj = PKPDViewer.Empty()
    
    % Copyright 2017 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 420 $
    %   $Date: 2017-12-07 14:47:44 -0500 (Thu, 07 Dec 2017) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties (SetAccess=public, GetAccess=public, SetObservable)
        Data = PKPD.Analysis.empty(0,1);
    end
    
    
    %% Constructor and Destructor
    % A constructor method is a special function that creates an instance
    % of the class. Typically, constructor methods accept input arguments
    % to assign the data stored in properties and always return an
    % initialized object.
    methods
        function vObj = Empty(varargin)
            % Empty % Constructor for PKPDViewer.Empty
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new PKPDViewer.Empty
            %
            % Syntax:
            %           vObj = PKPDViewer.Empty()
            %           vObj = PKPDViewer.Empty('p1',v1,...)
            %
            % Inputs:
            %           Optional property-value pairs for default settings
            %
            % Outputs:
            %           vObj - PKPDViewer.Empty object
            %
            % Examples:
            %           vObj = PKPDViewer.Empty();
            %
            
            % Call superclass constructor
            vObj = vObj@UIUtilities.ViewerBase(varargin{:});
            
            
            %----- Create Graphics and Assign Inputs -----%
            
            % Create the base graphics
            vObj.create();
            
            % Populate public properties from P-V input pairs
            vObj.assignPVPairs(varargin{:});
            
            % Mark the viewer construction complete, so view updates will
            % begin. The view updates don't occur before this is marked
            % true, for performance and visual reasons.
            vObj.IsConstructed = true;
            
            % Refresh the view
            vObj.refresh();
            
        end
    end %methods
    
    
    %% Methods in separate files with custom permissions
    
    methods (Access=protected)
        create(vObj);
    end
    
end %classdef