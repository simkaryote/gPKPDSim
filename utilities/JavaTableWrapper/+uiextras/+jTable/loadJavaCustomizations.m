function loadJavaCustomizations()
% loadJavaCustomizations - Load the custom java files
% -------------------------------------------------------------------------
% Abstract: Loads the custom Java .jar file required for the
% uiextras.jTable
%
% Syntax:
%           loadJavaCustomizations()
%
% Inputs:
%           none
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%

%   Copyright 2012-2015 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: agajjala $
%   $Revision: 30 $  $Date: 2015-11-12 18:05:09 -0500 (Thu, 12 Nov 2015) $
% ---------------------------------------------------------------------

% Define the jar file
JarFile = 'UIExtrasTable.jar';
JarPath = fullfile(fileparts(mfilename('fullpath')), JarFile);

% Check if the jar is loaded
JavaInMem = javaclasspath('-all');
PathIsLoaded = ~all(cellfun(@isempty,strfind(JavaInMem,JarFile)));

% Load the .jar file
if ~PathIsLoaded
    disp('Loading Java Customizations in UIExtrasTable.jar');
    javaaddpath(JarPath);
end
