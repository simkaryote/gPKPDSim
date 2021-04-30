function hDlg = AboutDialog(Title,Version,Date,Logo,CustomText)
% AboutDialog - Generate an About dialog
% -------------------------------------------------------------------------
% Abstract: This function generates an About dialog with the given
%           parameters
%
% Syntax:
%           AboutDialog(Title,Version,Date,Logo,CustomText)
%
% Inputs:
%           Title - The title of the application (string)
%           Version - The revision number of the application (string)
%           Date - The revision date of the application (string or datenum)
%           Logo - File path to an image file with the logo (string)
%           CustomText - Custom text to add to the dialog (string)
%
% Outputs:
%           hDlg - Handle to the About dialog figure
%
% Examples:
%           Title = 'Data Analysis Application';
%           Version = '1.0.100';
%           Date = datestr(date,'mmmm dd, yyyy');
%           Logo = 'MW_CSG_Logo.png';
%           CustomText = 'This is my application.';
%           AboutDialog(Title,Version,Date,Logo,CustomText)
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

% Check inputs
if nargin<5
    CustomText = '';
    if nargin<4
        Logo = '';
        if nargin<3
            Date = '';
            if nargin<2
                Version = '';
                if nargin<1
                    Title = 'About Dialog - Place Title Here';
                end
            end
        end
    end
end

% Define contact info
MWContact = {
    'MathWorks Consulting'
    '3 Apple Hill Drive'
    'Natick, MA 01760-2098'    
    '+1 (508) 647-7000'};
GenentechContact = {
    'Genentech Inc.'
    '1 DNA Way'
    'South San Francisco, CA 94080'
    'hosseini.iraj@gene.com'};

% Format Date
if ~isempty(Date)
    Date = datestr(Date,'mmmm dd, yyyy');
end

%% Create the dialog

% Offset
hoff = 120;

% Read Logo
lh = 0;
lw = 0;
if exist(Logo,'file')
    try
        CData = imread(Logo,'BackgroundColor',[1 1 1]);
        lh = size(CData,1);
        lw = size(CData,2);
    end
end

% Figure
fw = max(450,lw);
hDlg = figure(...
    'BackingStore','off',...
    'ColorMap',[],...
    'Color','white',...
    'DockControls','off',...
    'HandleVisibility','callback',...
    'IntegerHandle','off',...
    'InvertHardCopy','off',...
    'MenuBar','none',...
    'NumberTitle','off',...
    'Units','pixels',...
    'Position',[100 100 fw 2.5*hoff+lh],...
    'Resize','off',...
    'Visible','off',...
    'WindowStyle','modal');

% Move to center screen
movegui(hDlg,'center');

% Title
uicontrol(...
    'Parent',hDlg,...
    'BackgroundColor','white',...
    'FontSize',18,...
    'FontWeight','bold',...
    'Units','pixels',...
    'Position',[0 130+lh+hoff fw 35],...
    'String',Title,...
    'Style','text');

% Version
uicontrol(...
    'Parent',hDlg,...
    'BackgroundColor','white',...
    'FontSize',12,...
    'HorizontalAlignment','left',...
    'Units','pixels',...
    'Position',[6 97+lh+hoff 210 23],...
    'String',['Version ' Version],...
    'Style','text');

% Date
uicontrol(...
    'Parent',hDlg,...
    'BackgroundColor','white',...
    'FontSize',12,...
    'HorizontalAlignment','left',...
    'Units','pixels',...
    'Position',[6 74+lh+hoff 210 23],...
    'String',Date,...
    'Style','text');

% Custom Text
uicontrol(...
    'Parent',hDlg,...
    'BackgroundColor','white',...
    'FontSize',10,...
    'HorizontalAlignment','left',...
    'Units','pixels',...
    'Position',[6 6+lh+hoff 210 65],...
    'String',CustomText,...
    'Style','text');

% MathWorks Contact Info
uicontrol(...
    'Parent',hDlg,...
    'BackgroundColor','white',...
    'FontSize',12,...
    'HorizontalAlignment','left',...
    'Units','pixels',...
    'Position',[fw/2+5 6+lh+hoff fw/2-10 114],...
    'String',MWContact,...
    'Style','text');

% Genentech Contact Info
uicontrol(...
    'Parent',hDlg,...
    'BackgroundColor','white',...
    'FontSize',12,...
    'HorizontalAlignment','left',...
    'Units','pixels',...
    'Position',[fw/2+5 6+lh fw/2-10 114],...
    'String',GenentechContact,...
    'Style','text');

% Logo
if lh>0
    hAxes = axes(...
        'Parent',hDlg,...
        'Units','pixels',...
        'Position',[1 1 lw lh]);
    image(CData,'Parent',hAxes);
    axis(hAxes,'off')
    axis(hAxes,'image')
end

% Make visible
set(hDlg,'Visible','on')

