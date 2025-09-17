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

                % Assume a homogeneous simdata array (i.e., has the same data
                % names across all entries).
                Header = string(get(obj.SelectedSpecies, 'PartiallyQualifiedName'))';

                for runIndex = ExportRunIdx
                    SheetName = sprintf('Run %d',runIndex);

                    [time, data] = obj.SimData(runIndex).selectbyname(Header);

                    % make sure we got the data we expected
                    assert(size(data, 2) == numel(Header));

                    % Write to File (Excel, CSV)
                    try
                        tableForExport = array2table([time, data], 'VariableNames', ["Time", Header]);
                        writetable(tableForExport, FilePath, 'Sheet', SheetName);

                        % Meta Data Column Name
                        ColumnName = getColumnName(size(tableForExport,2) + 2);

                        if true
                            exportMetaData(obj, FilePath, SheetName, ColumnName, obj.SimProfileNotes(runIndex));
                        else
                            % Add the Description
                            nextRow = 1;
                            descriptionTable = table(string(obj.SimProfileNotes(runIndex).Description), 'VariableNames', {'Description'});
                            writetable(descriptionTable, FilePath, 'Sheet', SheetName, 'Range', ColumnName + nextRow);

                            % Parameter Table
                            nextRow = nextRow + height(descriptionTable) + 2;
                            paramHeader = ["Name", "Value"];
                            params = cell2table(obj.SimProfileNotes(runIndex).ParametersTable, 'VariableNames', paramHeader);
                            units = string({obj.SelectedParams.Units})';
                            assert(all(string(params.Name) == string({obj.SelectedParams.Name})'));
                            params.Units = units;
                            writetable(params, FilePath, 'Sheet', SheetName, 'Range', ColumnName + nextRow);

                            % Dosing Table
                            nextRow = nextRow + height(params) + 2;
                            dosingHeader = {'Dose Name', 'Dose Type', 'Target', 'StartTime', 'TimeUnits', 'Amount', 'AmountUnits', 'Interval', 'Rate', 'RepeatCount'};
                            dosing = cell2table(obj.SimProfileNotes(runIndex).DosingTable, 'VariableNames', dosingHeader);
                            writetable(dosing, FilePath, 'Sheet', SheetName, 'Range', ColumnName + nextRow);

                            % Variants applied
                            if ~isempty(obj.SimProfileNotes(runIndex).VariantNames)
                                nextRow = nextRow + height(dosing) + 2;
                                variant = cell2table(obj.SimProfileNotes(runIndex).VariantNames, 'VariableNames', {'Applied variants'});
                                writetable(variant, FilePath, 'Sheet', SheetName, 'Range', ColumnName + nextRow);
                            end
                        end

                    catch e
                        StatusOK = false;
                        Message = e.message;
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
            try
                tableForExport = array2table(ParamsData, 'VariableNames', Header);
                writetable(tableForExport, FilePath);
            catch e
                StatusOK = false;
                Message = e.message;
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
                    try
                        % Use a cell here because we have two header rows.
                        cellForExport = [FullHeader; FullPercHeader; num2cell(ThisData)];
                        writecell(cellForExport, FilePath, 'Sheet', SheetName);

                        if true
                            ColumnName = getColumnName(size(cellForExport, 2) + 2);
                            exportMetaData(obj, FilePath, SheetName, ColumnName, obj.PopProfileNotes(runIndex));
                        end
                    catch e
                        StatusOK = false;
                        Message = e.message;
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
end

function column_name = getColumnName(num)
    column_name = "";
    while num > 0
        remainder = rem(num - 1, 26);
        column_name = string(char(65 + remainder)) + column_name;
        num = floor((num - 1)/26);
    end
end

function exportMetaData(this, FilePath, SheetName, ColumnName, data)

    % Add the Description
    nextRow = 1;
    descriptionTable = table(string(data.Description), 'VariableNames', {'Description'});
    writetable(descriptionTable, FilePath, 'Sheet', SheetName, 'Range', ColumnName + nextRow);

    % Parameter Table
    nextRow = nextRow + height(descriptionTable) + 2;
    paramHeader = ["Name", "Value"];
    params = cell2table(data.ParametersTable, 'VariableNames', paramHeader);
    units = string({this.SelectedParams.Units})';
    assert(all(string(params.Name) == string({this.SelectedParams.Name})'));
    params.Units = units;
    writetable(params, FilePath, 'Sheet', SheetName, 'Range', ColumnName + nextRow);

    % Dosing Table
    nextRow = nextRow + height(params) + 2;
    dosingHeader = {'Dose Name', 'Dose Type', 'Target', 'StartTime', 'TimeUnits', 'Amount', 'AmountUnits', 'Interval', 'Rate', 'RepeatCount'};
    dosing = cell2table(data.DosingTable, 'VariableNames', dosingHeader);
    writetable(dosing, FilePath, 'Sheet', SheetName, 'Range', ColumnName + nextRow);

    % Variants applied
    if ~isempty(data.VariantNames)
        nextRow = nextRow + height(dosing) + 2;
        variant = cell2table(data.VariantNames, 'VariableNames', {'Applied variants'});
        writetable(variant, FilePath, 'Sheet', SheetName, 'Range', ColumnName + nextRow);
    end
end