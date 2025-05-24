function [StatusOK,Message] = export(obj,FilePath,Type)
% export - runs the analysis to Excel
% -------------------------------------------------------------------------
% Abstract: This exports the analysis
%
% Syntax:
%           export(aObj)
%
% Inputs:
%           aObj - PKPD.Analysis object
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%

% Copyright 2017 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: agajjala $
%   $Revision: 420 $  $Date: 2017-12-07 14:47:44 -0500 (Thu, 07 Dec 2017) $
% ---------------------------------------------------------------------

StatusOK = true;
Message = '';

if exist(FilePath,'file')
    delete(FilePath)
end

switch Type
    
    case 'Simulation'
        ExportRuns = [obj.SimProfileNotes.Export];
        
        if ~isempty(obj.SimData) && any(ExportRuns)
            ExportRunIdx = find(ExportRuns);
            
            for runIndex = ExportRunIdx
                SheetName = sprintf('Run %d',runIndex);
                
                Header = obj.SimData(runIndex).DataNames(:)';
                
                % Get matches from selected species
                MatchIndex = ismember(Header,get(obj.SelectedSpecies,'Name'));
                
                % Prune header and ThisData based on MatchIndex
                Header = Header(MatchIndex);
                ThisData = obj.SimData(runIndex).Data;
                ThisData = ThisData(:,MatchIndex);
                
                % Append time
                Header = ['Time',Header]; %#ok<AGROW>
                ThisData = [obj.SimData(runIndex).Time,ThisData]; %#ok<AGROW>
               
                % Write to Excel
                if ispc
                    [StatusOK,Message] = xlswrite(FilePath,[Header;num2cell(ThisData)],SheetName);
                else
                    [StatusOK,Message] = xlwrite(FilePath,[Header;num2cell(ThisData)],SheetName);
                end
            end
            
        else
            StatusOK = false;
            Message = 'Simulation data is empty or no runs have been selected for export.';
        end
        
    case 'Fitting'
        
        FitVal = {obj.SelectedParams.FittedVal}';
        CombinedFitValAndStdErr = cell(numel(FitVal),1);
        for index = 1:numel(FitVal)
                for fIndex = 1:size(FitVal{index},1)
                    CombinedFitValAndStdErr{index,fIndex} = sprintf('%f + %f',FitVal{index}(fIndex,1),FitVal{index}(fIndex,2));
                end
        end
        
        ParamsData = [...
            {obj.SelectedParams.Name}',...
            {obj.SelectedParams.FlagFit}',...
            {obj.SelectedParams.Value}',...
            CombinedFitValAndStdErr,...
            {obj.SelectedParams.Units}',...
            {obj.SelectedParams.Min}',...
            {obj.SelectedParams.Max}',...
            ];
        
        if ~isempty(obj.FitResults)
            Header = [...
                {'Name','Fit?','Initial'},...
                cellfun(@(x)sprintf('Fit - Group %s',char(x)),{obj.FitResults.GroupName},'UniformOutput',false),...
                {'Units','Min','Max'}];
        else
            Header = [...
                {'Name','Fit?','Initial'},...
                'Fit',...
                {'Units','Min','Max'}];
        end

        % Write to Excel
        if ispc
            [StatusOK,Message] = xlswrite(FilePath,[Header;ParamsData]);
        else
            [StatusOK,Message] = xlwrite(FilePath,[Header;ParamsData]);
        end
        
    case 'FittingSummary'
        if ~isempty(obj)
            
            % Save task results to temporary file
            TmpFilePath = fullfile(tempdir,'TmpTaskResults.mat');
            TaskResult = obj.FitTaskResults;             %#ok<NASGU>
            save(TmpFilePath,'TaskResult');
            
            % Invoke publish command
            options = struct('format','pdf','outputDir',FilePath,'showCode',false);
            publish('genReport.m',options);

            % Rename the published file
            if exist(FilePath,'file')
                FileDir = fileparts(FilePath);
                movefile(fullfile(FilePath,'genReport.pdf'),FileDir);
                rmdir(FilePath);
                movefile(fullfile(FileDir,'genReport.pdf'),FilePath);
            end
            
            % Delete temporary file
            if exist(TmpFilePath,'file')
                delete(TmpFilePath)
            end
            
        end
        
    case 'Population'
        
        ExportRuns = [obj.PopProfileNotes.Export];
        
        if ~isempty(obj.PopSummaryData) && any(ExportRuns)
            ExportRunIdx = find(ExportRuns);
            
            for runIndex = ExportRunIdx
                SheetName = sprintf('Run %d',runIndex);
                
                Header = {obj.PopSummaryData(1,:).Name};
                Header = Header(:)';
                 
                NumSpeciesInTable = numel(Header);                
                ThisData = [];

                for index = 1:NumSpeciesInTable                    
                    ThisData = [...
                        ThisData,...
                        obj.PopSummaryData(runIndex,index).P50,... % 50%
                        obj.PopSummaryData(runIndex,index).P5,... % 5%
                        obj.PopSummaryData(runIndex,index).P95,... % 95%
                        ]; %#ok<AGROW>
                end
                
                % Create header
                FullHeader = cell(1,3*NumSpeciesInTable);
                FullHeader(1:3:end) = Header;
                PercHeader = repmat({'50%','5%','95%'},1,NumSpeciesInTable);
                FullHeader = ['Time',FullHeader]; %#ok<AGROW>
                FullPercHeader = [{''},PercHeader];
                
                % Append time
                ThisData = [obj.PopSummaryData(runIndex,1).Time,ThisData]; %#ok<AGROW>
                
                % Write to Excel
                if ispc
                    [StatusOK,Message] = xlswrite(FilePath,[FullHeader;FullPercHeader;num2cell(ThisData)],SheetName);
                else
                    [StatusOK,Message] = xlwrite(FilePath,[FullHeader;FullPercHeader;num2cell(ThisData)],SheetName);
                end
            end
            
        else
            StatusOK = false;
            Message = 'Population data is empty or no runs have been selected for export.';
        end
        
    case 'NCA'
        
        if ~isempty(obj.NCAParameters) && istable(obj.NCAParameters)
            
            Header = obj.NCAParameters.Properties.VariableNames;
            TableData = table2cell(obj.NCAParameters);
            IsNumeric = cellfun(@isnumeric,TableData);
            TableData(~IsNumeric) = cellfun(@char,TableData(~IsNumeric),'UniformOutput',false);
            
            if ispc
                [StatusOK,Message] = xlswrite(FilePath,[Header;TableData]);
            else
                [StatusOK,Message] = xlwrite(FilePath,[Header;TableData]);
            end
        else
            StatusOK = false;
            Message = 'NCA parameters must be a non-empty table. Exporting has failed.';
        end
end
