classdef FileRegexpReplacer < handle
    % FileRegexpReplacer - Handles regular expression replacement in a
    % directory structure of files
    % ---------------------------------------------------------------------
    % Abstract: This object performs regular expression replacement of tobj.FileSearchStr
    % in a directory structure of files.
    %
    % Syntax:
    %           f = FileRegexpReplacer
    %
    % FileRegexpReplacer Properties:
    %
    %     Property - description
    %
    %     Property - description
    %
    % FileRegexpReplacer Methods:
    %
    %     regexprep - runs the replacement process
    %
    %     findFiles - prepares the list of files to find (called
    %     automatically by regexprep method)
    %
    
    % Copyright 2017 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 420 $  $Date: 2017-12-07 14:47:44 -0500 (Thu, 07 Dec 2017) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties
        RootDir = pwd
        Recurse = true
        FileSearchStr = '.m'
        Ignores = {'.','..','.svn','CVS'}
    end
    properties (SetAccess = protected)
        FilePaths = {}
    end
    
    
    %% Methods
    methods
        
        function obj = FileRegexpReplacer()
            obj.RootDir = pwd;
        end
        
        function regexprep(obj,varargin)
            
            % Check number of input arguments
            narginchk(3, inf)
            
            % Find the files
            obj.findFiles();
            
            % Loop on files
            for idx = 1:numel(obj.FilePaths)
                
                % Get the current file path
                ThisFile = obj.FilePaths{idx};
                
                % Get the text of the file:
                fid = fopen(ThisFile,'r');
                NextLine = '';
                FileText = '';
                while ~isequal(NextLine,-1)
                    FileText = [FileText, NextLine]; %#ok<AGROW>
                    NextLine = fgets(fid);
                end
                
                % Perform regexp on the text in the file
                FileText = regexprep(FileText,varargin{:});
                
                % Close the file
                fclose(fid);
                
                % Write the new file
                fid = fopen(ThisFile,'w');
                fprintf(fid,'%s',FileText);
                
                % Close the file
                fclose(fid);
                
            end %for idx = 1:numel(FilePaths)
            
        end %function regexprep(obj,varargin)
        
        function varargout = findFiles(obj,StartPath)
            if nargin<2
                StartPath = obj.RootDir;
            end
            files = {};
            d = dir( StartPath );
            for jj=1:numel(d)
                if ~ismember( d(jj).name, obj.Ignores )
                    fullname = fullfile( StartPath, d(jj).name );
                    if d(jj).isdir
                        if obj.Recurse
                            newfiles = obj.findFiles( fullname );
                            files = [files; newfiles(:)]; %#ok<AGROW>
                        end
                    else
                        [p,f,e] = fileparts(fullname); %#ok<ASGLU>
                        if isempty(obj.FileSearchStr) || strcmpi(obj.FileSearchStr,e)
                            files = [files; fullname]; %#ok<AGROW>
                        end
                    end
                end
            end
            obj.FilePaths = files;
            if nargout
                varargout{1} = files;
            end
        end
        
    end %methods
    
end %classdef