function [StatusOk,Message] = run(obj)
% run - runs the analysis
% -------------------------------------------------------------------------
% Abstract: This runs the analysis based on the settings and data table.
%
% Syntax:
%           [StatusOk,Message] = run(obj)
%
% Inputs:
%           obj - PKPD.Analysis object
%
% Outputs:
%           StatusOk - Flag to indicate status
%
%           Message - Status description, populated if StatusOk is false
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

StatusOk = true;
Message = '';

% Run selected task
switch obj.Task
    case 'Simulation'        
        [StatusOk,Message] = runSimulation(obj);        
        
    case 'Fitting'
        [StatusOk,Message] = runFitting(obj);        
        
    case 'Population'
        [StatusOk,Message] = runPopulation(obj);
        
end

