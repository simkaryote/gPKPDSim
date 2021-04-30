classdef Simulation < UIUtilities.ViewerBase
    % Simulation - Class definition for Simulation viewer
    % ---------------------------------------------------------------------
    % Abstract: Display a viewer/editor for a PKPD.Simulation object
    %
    % Syntax:
    %           vObj = PKPDViewer.Simulation
    %           vObj = PKPDViewer.Simulation('Property','Value',...)
    %
    % PKPDViewer.Simulation Properties:
    %
    %     Data - The data that will be displayed by the viewer
    %
    %     Type - Type of viewer to display - either simulation or
    %     population (similar)
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
    % PKPDViewer.Simulation methods:
    %
    %     callCallback - call a user-specified callback function
    %
    %   Callback methods:
    %       none
    %
    %
    % Examples:
    %  vObj = PKPDViewer.Simulation()
    
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
        Type = 'simulation'
    end
    
    
    %% Dependent Properties
    properties(SetAccess = 'private',Dependent=true);
        Height %dependent on FilePath
    end
    
    %% Constant Properties
    properties(Constant = true);
        ValidTypes = {...
            'simulation',...
            'population',...
            }
        MaxSimulationParamRowWidths = [100 55 5 35 -2 35 60 0 0] % [100 -1 5 -1 -2 -1 -1 0 0]
        MaxPopulationParamRowWidths = [100 55 5 35 -2 35 60 35 35] % [100 -1 5 -1 -2 -1 -1 -1 -1]        
        ParamRowHeight = 30 % 25 is best for popupdialog
    end
    
    %% Constructor and Destructor
    % A constructor method is a special function that creates an instance
    % of the class. Typically, constructor methods accept input arguments
    % to assign the data stored in properties and always return an
    % initialized object.
    methods
        function vObj = Simulation(Type,varargin)
            % Simulation % Constructor for PKPDViewer.Simulation
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new PKPDViewer.Simulation
            %
            % Syntax:
            %           vObj = PKPDViewer.Simulation()
            %           vObj = PKPDViewer.Simulation('p1',v1,...)
            %
            % Inputs:
            %           Optional property-value pairs for default settings
            %
            % Outputs:
            %           vObj - PKPDViewer.Simulation object
            %
            % Examples:
            %           vObj = PKPDViewer.Simulation();
            %
            
            % Call superclass constructor
            vObj = vObj@UIUtilities.ViewerBase(varargin{:});
            
            
            %----- Create Graphics and Assign Inputs -----%
            vObj.Type = Type;
            
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
    
    
    %% Public methods
    
    methods
        function minimizeParameterView(vObj)
            
            if isempty(vObj.h.ParamHBox)
                return;
            end
            
            % Only show the first two widths per row
            Widths = vObj.MaxSimulationParamRowWidths;
            Widths(1:2) = -1;
            Widths(3:end) = 0;
            
            hParamControls = [...
                vObj.h.ParamNameText
                vObj.h.ParamValueEdit
                vObj.h.ParamUnitsText
                vObj.h.ParamMinEdit
                vObj.h.ParamSlider
                vObj.h.ParamMaxEdit
                vObj.h.ParamScalePopup
                vObj.h.ParamPercCVEdit
                vObj.h.ParamPercCVText
                ];
            if strcmpi(vObj.Type,'Simulation')
                set(vObj.h.ParamHBox,'Widths',Widths)      
                set(hParamControls(Widths == 0,:),'Visible','off');
            else
                Widths(end-1) = -1;
                Widths(end) = 35;
                set(vObj.h.ParamHBox,'Widths',Widths)
                set(hParamControls(Widths == 0,:),'Visible','off');
            end
            
%             % Adjust heights
%             vObj.h.ParametersLayout.Heights = 30*ones(size(vObj.h.ParametersLayout.Heights));
%             vObj.h.ParametersLayout.Heights(1) = 30;
            
        end
        
        function maximizeParameterView(vObj)  
            
            if isempty(vObj.h.ParamHBox)
                return;
            end
            
            hParamControls = [...
                vObj.h.ParamNameText
                vObj.h.ParamValueEdit
                vObj.h.ParamUnitsText
                vObj.h.ParamMinEdit
                vObj.h.ParamSlider
                vObj.h.ParamMaxEdit
                vObj.h.ParamScalePopup
                vObj.h.ParamPercCVEdit
                vObj.h.ParamPercCVText
                ];            
            % Restore widths and visibility
            if strcmpi(vObj.Type,'Simulation')
                set(vObj.h.ParamHBox,'Widths',vObj.MaxSimulationParamRowWidths)
                set(hParamControls(1:(end-2)),'Visible','on'); 
                set(hParamControls((end-1):end),'Visible','off'); 
            else
                set(vObj.h.ParamHBox,'Widths',vObj.MaxPopulationParamRowWidths)                
                set(hParamControls,'Visible','on'); 
            end
            
%             vObj.h.ParametersLayout.Heights = vObj.ParamRowHeight*ones(size(vObj.h.ParametersLayout.Heights));
        end
    end
    
    
    %% Callbacks
    methods
        
        function onEdit(vObj,h,~)
            % On editing a setting
            
            % Which control was changed
            ControlName = get(h,'Tag');
            
            % What is the new value?
            NewValue = str2double(get(h,'String'));
                    
            % Try to set the value
            try
                vObj.Data.(ControlName) = NewValue;
            catch err
                Message = sprintf('Unable to change setting value: \n%s',err.message);
                Title = 'Invalid value';
                hDlg = errordlg(Message,Title,'modal');
                uiwait(hDlg);
            end
            
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
            
            % Update selected parameters props based on selected model
            % and variants
            OrderedVariants = vObj.Data.SelectedVariants;
            OrderedVariants(vObj.Data.SelectedVariantsOrder) = vObj.Data.SelectedVariants;
            IsSelected = get(OrderedVariants,'Active');
            if iscell(IsSelected)
                IsSelected = cell2mat(IsSelected);
            end
            OrderedVariants = OrderedVariants(IsSelected);
            
            for index = 1:numel(vObj.Data.SelectedParams)
                restoreValueFromVariant(vObj.Data.SelectedParams(index),vObj.Data.ModelObj,OrderedVariants);
            end
            
            % Apply parameters to simulation variant
            updateSimVariant(vObj.Data);
            
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
                    
                    % Save and add to selected variant names
                    saveVariant(vObj.Data,SavedVariantName);                    
                end
            end
                
            % Refresh the entire viewer
            vObj.refresh();
            
            % Call the callback, providing relevant eventdata
            e = struct('Data',vObj.Data,'Control',ControlName,'Value',NewValue);
            vObj.callCallback(vObj.DataChangedCallback,vObj,e);
            
        end %function
        
        function onEditParam(vObj,h,~,FieldName)
            % On editing parameter value
            
            % Which control was changed
            ControlName = get(h,'Tag');
            
            % Find the match
            Match = strcmp({vObj.Data.SelectedParams.Name},ControlName);
            ThisParam = vObj.Data.SelectedParams(Match);
            
            % What is the new value?
            NewValue = str2double(get(h,'String'));
               
            % Try to set the value
            try
                ThisParam.(FieldName) = NewValue;
%                 if strcmpi(ThisParam.Scale,'linear') || strcmpi(FieldName,'Value')
%                     ThisParam.(FieldName) = NewValue;
%                 elseif strcmpi(ThisParam.Scale,'log')
%                     ThisParam.(FieldName) = 10^NewValue;
%                 else
%                     ThisParam.(FieldName) = NewValue;
%                 end
                
                % Update based on min/max
                ThisParam.Value = max([ThisParam.Value,ThisParam.Min]);
                ThisParam.Value = min([ThisParam.Value,ThisParam.Max]);
            
                % Apply parameters to simulation variant
                updateSimVariant(vObj.Data);
                
            catch err
                Message = sprintf('Unable to change parameter %s: \n%s',FieldName,err.message);
                Title = FieldName;
                hDlg = errordlg(Message,Title,'modal');
                uiwait(hDlg);
            end
            
            % Refresh the entire viewer
            vObj.refresh();
            
            % Do not call the main viewer in case the user quickly presses
            % Run - this will trigger multiple updates to the profile notes
            % table            
            
        end %function
        
        function onEditParamCV(vObj,h,~)
            % On editing param CV
            
            % Which control was changed
            ControlName = get(h,'Tag');
            
            % Find the match
            Match = strcmp({vObj.Data.SelectedParams.Name},ControlName);
            ThisParam = vObj.Data.SelectedParams(Match);
            
            % What is the new value?
            NewValue = str2double(get(h,'String'));
               
            % Try to set the value
            try
                ThisParam.PercCV = NewValue;
                
                % Update based on min/max
                ThisParam.Value = max([ThisParam.Value,ThisParam.Min]);
                ThisParam.Value = min([ThisParam.Value,ThisParam.Max]);
            
                % Apply parameters to simulation variant
                updateSimVariant(vObj.Data);
                
            catch err
                Message = sprintf('Unable to change parameter %s coefficient of variation: \n%s',ControlName,err.message);
                Title = ControlName;
                hDlg = errordlg(Message,Title,'modal');
                uiwait(hDlg);
            end
            
            % Refresh the entire viewer
            vObj.refresh();
            
            % Call the callback, providing relevant eventdata
            e = struct('Data',vObj.Data,'Control',ControlName,'Value',NewValue);
            vObj.callCallback(vObj.DataChangedCallback,vObj,e);
        end
        
        function onEditParamSlider(vObj,h,~)
            % On editing parameter slider
            
            % Which control was changed
            ControlName = get(h,'Tag');
            Match = strcmpi({vObj.Data.SelectedParams.Name},ControlName);
            ThisParam = vObj.Data.SelectedParams(Match);
            
            % What is the new value?
            NewValue = get(h,'Value');
                    
            % Try to set the value
            try
                if strcmpi(ThisParam.Scale,'linear')
                    ThisParam.Value = NewValue;                    
                else
                    ThisParam.Value = 10^NewValue;
                end
                
                % Update based on min/max
                ThisParam.Value = max([ThisParam.Value,ThisParam.Min]);
                ThisParam.Value = min([ThisParam.Value,ThisParam.Max]);
                
                % Apply parameters to simulation variant
                updateSimVariant(vObj.Data);
                
            catch err
                Message = sprintf('Unable to change parameter slider: \n%s',err.message);
                Title = 'Parameter Slider';
                hDlg = errordlg(Message,Title,'modal');
                uiwait(hDlg);
            end
            
            % Update the entire viewer
            vObj.update();
            
%             % Call the callback, providing relevant eventdata
%             e = struct('Data',vObj.Data,'Control',ControlName,'Value',NewValue);
%             vObj.callCallback(vObj.DataChangedCallback,vObj,e);
            
        end %function
        
        function onEditParamScale(vObj,h,~)
            % On editing parameter scale
            
            % Which control was changed
            ControlName = get(h,'Tag');
            Match = strcmpi({vObj.Data.SelectedParams.Name},ControlName);
            
            % What is the new value?
            Options = get(h,'String');
            NewValue = get(h,'Value');
                    
            % Try to set the value
            try
                vObj.Data.SelectedParams(Match).Scale = Options{NewValue};
            catch err
                Message = sprintf('Unable to change parameter scale: \n%s',err.message);
                Title = 'Parameter Scale';
                hDlg = errordlg(Message,Title,'modal');
                uiwait(hDlg);
            end
            
            % Refresh the entire viewer
            vObj.refresh();
            
            % Call the callback, providing relevant eventdata
            e = struct('Data',vObj.Data,'Control',ControlName,'Value',NewValue);
            vObj.callCallback(vObj.DataChangedCallback,vObj,e);
            
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
        
        function set.Type(vObj,value)
            value = validatestring(value,vObj.ValidTypes);
            vObj.Type = value;
        end
        
    end %methods
    
end %classdef