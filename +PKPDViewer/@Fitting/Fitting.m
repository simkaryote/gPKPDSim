classdef Fitting < UIUtilities.ViewerBase
    % Fitting - Class definition for Fitting viewer
    % ---------------------------------------------------------------------
    % Abstract: Display a viewer/editor for a PKPD.Fitting object
    %
    % Syntax:
    %           vObj = PKPDViewer.Fitting
    %           vObj = PKPDViewer.Fitting('Property','Value',...)
    %
    % PKPDViewer.Fitting Properties:
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
    % PKPDViewer.Fitting methods:
    %
    %     callCallback - call a user-specified callback function
    %
    %   Callback methods:
    %       none
    %
    %
    % Examples:
    %  vObj = PKPDViewer.Fitting()
    
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
        Data = PKPD.Analysis
    end

    %% Private Properties
    properties (SetAccess=private)
        IsPC = ispc
    end
    
    %% Dependent Properties
    properties(SetAccess = 'private',Dependent=true);
        Height %dependent on FilePath
    end
    
    
    %% Constructor and Destructor
    % A constructor method is a special function that creates an instance
    % of the class. Typically, constructor methods accept input arguments
    % to assign the data stored in properties and always return an
    % initialized object.
    methods
        function vObj = Fitting(varargin)
            % Fitting % Constructor for PKPDViewer.Fitting
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new PKPDViewer.Fitting
            %
            % Syntax:
            %           vObj = PKPDViewer.Fitting()
            %           vObj = PKPDViewer.Fitting('p1',v1,...)
            %
            % Inputs:
            %           Optional property-value pairs for default settings
            %
            % Outputs:
            %           vObj - PKPDViewer.Fitting object
            %
            % Examples:
            %           vObj = PKPDViewer.Fitting();
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
    
    
    %% Callbacks
    methods
        
        function onDoseSpeciesTableEdited(vObj,h,~)
            % On select target species
            
            % Which control was changed
            ControlName = get(h,'Tag');
            NewValue = [];
            
            % Set response map
            vObj.Data.DoseMap = get(h,'Data');
            
            % Refresh the entire viewer
            vObj.refresh();
            
            % Call the callback, providing relevant eventdata
            e = struct('Data',vObj.Data,'Control',ControlName,'Value',NewValue);
            vObj.callCallback(vObj.DataChangedCallback,vObj,e);
            
        end %function
        
        function onConcSpeciesTableEdited(vObj,h,~)
            % On select target species
            
            % Which control was changed
            ControlName = get(h,'Tag');
            NewValue = [];
            
            % Set response map
            vObj.Data.ResponseMap = get(h,'Data');
            
            % Refresh the entire viewer
            vObj.refresh();
            
            % Call the callback, providing relevant eventdata
            e = struct('Data',vObj.Data,'Control',ControlName,'Value',NewValue);
            vObj.callCallback(vObj.DataChangedCallback,vObj,e);
            
        end %function
        
        function onSelectPooledFitting(vObj,h,~)
            % On select pooled fitting
            
            % Which control was changed
            ControlName = get(h,'Tag');
            NewValue = [];
            
            % Set pooled fitting
            vObj.Data.UsePooledFitting = logical(get(h,'Value'));
            
            % Refresh the entire viewer
            vObj.refresh();
            
            % Call the callback, providing relevant eventdata
            e = struct('Data',vObj.Data,'Control',ControlName,'Value',NewValue);
            vObj.callCallback(vObj.DataChangedCallback,vObj,e);
            
        end %function
        
        function onSelectErrorModel(vObj,h,~)
            % On select error model
            
            % Which control was changed
            ControlName = get(h,'Tag');
            NewValue = [];
            
            vObj.Data.FitErrorModel = vObj.Data.FitErrorModelOptions{get(h,'Value')};
            
            % Refresh the entire viewer
            vObj.refresh();
            
            % Call the callback, providing relevant eventdata
            e = struct('Data',vObj.Data,'Control',ControlName,'Value',NewValue);
            vObj.callCallback(vObj.DataChangedCallback,vObj,e);
            
        end %function
        
        function onRestoreDefaults(vObj,h,~)
            % On restoring defaults
            
            % Which control was changed
            ControlName = get(h,'Tag');
            NewValue = [];
            
            OrderedVariants = vObj.Data.SelectedVariants;
            OrderedVariants(vObj.Data.SelectedVariantsOrder) = vObj.Data.SelectedVariants;
            IsSelected = get(OrderedVariants,'Active');
            if iscell(IsSelected)
                IsSelected = cell2mat(IsSelected);
            end
            OrderedVariants = OrderedVariants(IsSelected);
            
            % Update selected parameters props based on selected model
            % and variants
            for index = 1:numel(vObj.Data.SelectedParams)
                restoreValueFromVariant(vObj.Data.SelectedParams(index),vObj.Data.ModelObj,OrderedVariants);
            end
            
            % Apply parameters to fitting variant (for consistency)
            updateFitVariant(vObj.Data);
            
            % Refresh the entire viewer
            vObj.refresh();
            
            % Call the callback, providing relevant eventdata
            e = struct('Data',vObj.Data,'Control',ControlName,'Value',NewValue);
            vObj.callCallback(vObj.DataChangedCallback,vObj,e);
            
        end %function
        
        function onSaveAsVariant(vObj,h,~)
            % On saving as variant
            
            % Which control was changed
            ControlName = get(h,'Tag');
            NewValue = [];

            FlagFit = [vObj.Data.SelectedParams.FlagFit];
            FittedValue = {vObj.Data.SelectedParams.FittedVal};
            IsEmptyFittedValue = cellfun(@isempty,FittedValue(FlagFit));
            
            if all(~FlagFit) || any(IsEmptyFittedValue)
                hDlg = errordlg('Cannot save variant. At least one parameter must be selected for fitting, and fitting must be run for all selected parameters.','Save Variant','modal');
                uiwait(hDlg);
                return;
            end
            
            Options.Resize = 'on';
            Options.WindowStyle = 'modal';
            Answer = inputdlg('Save variant as?','Save Variant',[1 50],{''},Options);
            
            if ~isempty(Answer)
                SelectedVariants = vObj.Data.SelectedVariants;
                SelectedVariantNames = get(SelectedVariants,'Name');
                
                if isempty(strtrim(Answer{1})) || any(strcmpi(Answer{1},SelectedVariantNames))
                    Message = 'Please provide a valid, unique variant name.';
                    Title = 'Invalid name';
                    hDlg = errordlg(Message,Title,'modal');
                    uiwait(hDlg);
                else
                    SavedVariantName = strtrim(Answer{1});
                    
                    % Apply to fit variant
                    updateFitVariant(vObj.Data)
                    
                    % Save and add to selected variant names
                    saveVariant(vObj.Data,SavedVariantName,'fit');                                       
                end
            end
            
            % Refresh the entire viewer
            vObj.refresh();
            
            % Call the callback, providing relevant eventdata
            e = struct('Data',vObj.Data,'Control',ControlName,'Value',NewValue);
            vObj.callCallback(vObj.DataChangedCallback,vObj,e);
            
        end %function
        
        function onParamsTableEdited(vObj,h,e)
            % On editing table
            
            % Which control was changed
            ControlName = get(h,'Tag');
            TableData = get(h,'Data');
            
            FlagRefresh = false;
            
            if ~isempty(e) && (isfield(e,'Indices') || isprop(e,'Indices')) && numel(e.Indices) > 1
                % Validate value
                Row = e.Indices(1);
                Col = e.Indices(2);
                
                try
                    switch Col
                        case 2
                            % Fit
                            if ~isequal(TableData{Row,Col},vObj.Data.SelectedParams(Row).FlagFit)
                                FlagRefresh = true;
                                vObj.Data.SelectedParams(Row).FlagFit = TableData{Row,Col};
                            end
                            
                        case 3
                            % Initial
                            if ~isequal(TableData{Row,Col},vObj.Data.SelectedParams(Row).Value)
                                FlagRefresh = true;
                                vObj.Data.SelectedParams(Row).Value = TableData{Row,Col};
                            end                            
                            
                        case 7
                            % Min
                            if ~isequal(TableData{Row,Col},vObj.Data.SelectedParams(Row).Min)
                                FlagRefresh = true;
                                vObj.Data.SelectedParams(Row).Min = TableData{Row,Col};
                            end                            
                            
                        case 8
                            % Max
                            if ~isequal(TableData{Row,Col},vObj.Data.SelectedParams(Row).Max)
                                FlagRefresh = true;
                                vObj.Data.SelectedParams(Row).Max = TableData{Row,Col};
                            end
                    end
                catch err
                    Message = sprintf('Unable to change %s table: \n%s','parameters',err.message);
                    Title = 'Parameters Table';
                    FlagRefresh = true;
                    hDlg = errordlg(Message,Title,'modal');
                    uiwait(hDlg);
                end
            end
            
            if FlagRefresh
                % Refresh the entire viewer
                vObj.refresh();
                
                NewValue = TableData{Row,Col};
                
                % Call the callback, providing relevant eventdata
                e = struct('Data',vObj.Data,'Control',ControlName,'Value',NewValue);
                vObj.callCallback(vObj.DataChangedCallback,vObj,e);
            end
            
        end %function
        
    end % callback
    
    
    %% Get methods
    methods
        function value = get.Height(vObj)
            if vObj.IsConstructed && ~isempty(vObj.h)
                value = sum(vObj.h.MainLayout.Heights) + ...
                    vObj.h.MainLayout.Padding * 2 + ...
                    vObj.h.MainLayout.Spacing * (numel(vObj.h.MainLayout.Heights)-1) + ...
                    20; % Arbitrary buffer
            else
                value = 0;
            end
        end
    end
    
    
    %% Set methods
    methods
        
        function set.Data(vObj,value)
            validateattributes(value,{'PKPD.Analysis'},{});
            % Did the Data object change? If so, store it and refresh view.
            if ~isequal(value,vObj.Data)
                vObj.Data = value;
                if vObj.IsConstructed
                    refresh(vObj);
                end
            end
        end
        
    end %methods
    
end %classdef