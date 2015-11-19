function Figure_properties(varargin, width, height)
% SDF Set the line width and fonts of a figure
% 
% sdf(fig)
% 
% where fig is the figure number. If the figure number is omitted, the 
% currently active figure is updated. Edit the file to set you own style 
% settings.
%
% sdf(fig, 'stylename')
% applies a pre-configured style from the File-->Export Setup menu of the
% figure's window. The stylename should be one of the 'Export Styles'
% section of the dialog.
%
% The function allows applying the same settings as through the 
% File-->Export Setup-->Apply menu of the figure, but much faster and 
% without the annoying clicking. 
%
% Example
%   figure(1);      t=0:0.1:10;   plot(t, sin(t));
%   sdf(1)
%   pause
%   sdf(1,'PowerPoint')

% Andrey Popov, Hamburg, 2009

%% Parse the input data
default = true;
if nargin == 0       % no input - take current fig and apply default style
    fig = gcf();
else                 % at least 1 input
    if ischar(varargin{1})  % style name
        default = false;
        style_name = varargin{1};
        fig = gcf();
    else
        fig = varargin{1};
        figure(fig);        % just in case it does not exist
        if nargin == 2
            default = false;
            style_name = varargin{2};
        end
    end
end

%% Apply a style
if default      % Apply a default style
    style = struct();
    style.Version = '1';
    style.Format = 'pdf'; %was eps
    style.Preview = 'none';
    style.Width = num2str(width); % was 3
    style.Height = num2str(height); % was 2.5
    style.Units = 'inches';
    style.Color = 'rgb';
    style.Background = 'w';          % '' = no change; 'w' = white background
    style.FixedFontSize = '11'; % was 11
    style.ScaledFontSize = 'auto';
    style.FontMode = 'fixed';
    style.FontSizeMin = '11'; 
%     style.FixedLineWidth = '1';
%     style.ScaledLineWidth = 'auto';
%    style.LineMode = 'fixed';
%     style.LineWidthMin = '1';
    style.FontName = 'times new roman'; % was arial
    style.FontWeight = 'bold'; % was light
    style.FontAngle = 'auto';
    style.FontEncoding = 'latin1';
    style.PSLevel = '1';
    style.Renderer = 'auto';
    style.Resolution = '300';
    style.LineStyleMap = 'none';
    style.ApplyStyle = '0';
    style.Bounds = 'tight';
    style.LockAxes = 'on';
    style.ShowUI = 'on';
    style.SeparateText = 'off';

    hgexport(fig,'temp_dummy',style,'applystyle', true);

else    % Apply an existing style, defined as in the Export dialog
    % The files are in folder   fullfile(prefdir(0),'ExportSetup');
    style = hgexport('readstyle',style_name);
    hgexport(fig,'temp_dummy',style,'applystyle', true);
end
% set(0,'defaulttextinterpreter','latex');
set(0,'defaultAxesFontName','arial')
set(0,'defaultAxesFontWeight','light')
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [3 2.5]);

