% CDA Compressor - Copyright (C) 2026 Ahmed Mohamed Ahmed Hassan, Abdalmoez Ahmed Abdullah Hemid,
% Thabet Saber Thabet Abdelhamid and Deyaa ElHaq Nabil Elshebiny (Cairo University).
% Free for noncommercial use under the PolyForm Noncommercial License 1.0.0; see LICENSE.
% https://github.com/AhmedDMoHassan/CDA-Compressor
function CDA_launcher()
% CDA_LAUNCHER  Start window of the compressor design (CDA) and off-design tools.
% Main file of the packaged toolbox / MATLAB app and of the standalone program.
% Needs, in the same folder: Compressor_design_app.m, cda_core.m, cda_guide.html,
% cda_offdesign_guide.html, Compressor_offdesign_app.m, CDA_icon_512.png, cda_configurations.png.

b = char(8226);                                   % bullet
icon = local_file('CDA_icon_512.png');
cfgimg = local_file('cda_configurations.png');

f = uifigure('Name', 'CDA Compressor - design and off-design (mean-line)', 'Visible', 'off');
try, ss = get(groot, 'ScreenSize'); catch, ss = [1 1 1366 768]; end
w = min(1040, ss(3) - 60); h = min(680, ss(4) - 110);
f.Position = [max(1, floor((ss(3) - w)/2)), max(50, floor((ss(4) - h)/2)), w, h];
if ~isempty(icon), try, f.Icon = icon; catch, end, end
try, f.WindowState = 'maximized'; catch, f.Position = [1 41 ss(3) ss(4) - 70]; end   % full screen
f.Resize = 'off';                                 % fixed size: the layout always fits

g = uigridlayout(f, [4 1]); g.RowHeight = {78, 230, '1x', 32}; g.Padding = [14 10 14 8]; g.RowSpacing = 8;

% ---- header: icon + title
gh = uigridlayout(g, [2 2]); gh.ColumnWidth = {72, '1x'}; gh.RowHeight = {'1x', '1x'}; gh.Padding = [0 0 0 0]; gh.ColumnSpacing = 12;
if ~isempty(icon)
    im = uiimage(gh, 'ImageSource', icon); im.Layout.Row = [1 2]; im.Layout.Column = 1;
end
t = uilabel(gh, 'Text', 'CDA Compressor', 'FontSize', 22, 'FontWeight', 'bold', 'FontColor', [0.08 0.2 0.42]);
t.Layout.Row = 1; t.Layout.Column = 2;
t = uilabel(gh, 'Text', 'Mean-line preliminary design and off-design analysis of axial compressors', 'FontSize', 13, 'FontColor', [0.3 0.3 0.3]);
t.Layout.Row = 2; t.Layout.Column = 2;

% ---- the four configurations
if ~isempty(cfgimg)
    im = uiimage(g, 'ImageSource', cfgimg, 'ScaleMethod', 'fit', 'HorizontalAlignment', 'center'); im.Layout.Row = 2;
else
    l = uilabel(g, 'Text', 'Configurations: rotor-stator, rotor-stator without the last stator, rotor-rotor on one shaft, rotor-rotor on two shafts.');
    l.Layout.Row = 2;
end

% ---- the two apps
gp = uigridlayout(g, [1 2]); gp.Padding = [0 0 0 0]; gp.ColumnSpacing = 12; gp.Layout.Row = 3;

pd = uipanel(gp, 'Title', '1  Design app', 'FontWeight', 'bold', 'FontSize', 13);
gd = uigridlayout(pd, [3 2]); gd.RowHeight = {'1x', 24, 36}; gd.ColumnWidth = {150, '1x'}; gd.Padding = [8 8 8 8];
txt = {[b ' Configurations: rotor-stator (with or without the last stator), rotor-rotor on one shaft, rotor-rotor on two shafts (same or counter-rotating)'], ...
       [b ' 1 to 12 stages or rotors; any stage can get its own ' char(966) ', ' char(968) ', R or DF'], ...
       [b ' Design space of ' char(966) ', ' char(968) ', R (and U2/U1) on four interactive maps'], ...
       [b ' Objectives: maximum pressure ratio or efficiency, smallest size, weighted'], ...
       [b ' Limits: solidity, inlet Mach number, de Haller, hub/tip, h/c, exit swirl'], ...
       [b ' Detailed design: velocity triangles, losses, NACA-65 metal angles, annulus, blades'], ...
       [b ' Compare designs; export the design file to the off-design app']};
l = uilabel(gd, 'Text', txt, 'WordWrap', 'on', 'VerticalAlignment', 'top', 'FontSize', 12); l.Layout.Row = 1; l.Layout.Column = [1 2];
l = uilabel(gd, 'Text', 'Start with configuration'); l.Layout.Row = 2; l.Layout.Column = 1;
dd = uidropdown(gd, 'Items', {'Rotor-Stator', 'Rotor-Rotor, same shaft', 'Rotor-Rotor, two shafts'}, 'ItemsData', {'RS', 'RR-S', 'RR-D'}, 'Value', 'RS');
dd.Layout.Row = 2; dd.Layout.Column = 2;
bt = uibutton(gd, 'Text', ['Open the design app  ' char(9654)], 'FontSize', 13, 'FontWeight', 'bold', 'BackgroundColor', [0.85 0.92 1], ...
    'ButtonPushedFcn', @(~, ~) open_design(dd.Value));
bt.Layout.Row = 3; bt.Layout.Column = [1 2];

po = uipanel(gp, 'Title', '2  Off-design app', 'FontWeight', 'bold', 'FontSize', 13);
go = uigridlayout(po, [3 1]); go.RowHeight = {'1x', 24, 36}; go.Padding = [8 8 8 8];
txt = {[b ' Reads the design file written by the design app (or your own .mat file)'], ...
       [b ' Rotor-stator (any number of stages, with or without the last stator), rotor-rotor on one or two shafts'], ...
       [b ' Speed lines from 50 to 120 % speed: pressure ratio and efficiency maps'], ...
       [b ' Boundaries: choke, peak pressure ratio (surge), Howell stall onset, first stability limit'], ...
       [b ' Stall margin, choke margin and usable range; Greitzer B (surge or rotating stall); Koch indicator'], ...
       [b ' Non-dimensional, relative and corrected maps with fitted boundary lines'], ...
       [b ' Validation against measured maps and correlation settings for sensitivity studies']};
l = uilabel(go, 'Text', txt, 'WordWrap', 'on', 'VerticalAlignment', 'top', 'FontSize', 12); l.Layout.Row = 1;
l = uilabel(go, 'Text', 'Load a design file in the app, then press Run.', 'FontColor', [0.35 0.35 0.35]); l.Layout.Row = 2;
bt = uibutton(go, 'Text', ['Open the off-design app  ' char(9654)], 'FontSize', 13, 'FontWeight', 'bold', 'BackgroundColor', [0.85 0.95 0.85], ...
    'ButtonPushedFcn', @(~, ~) open_app('Compressor_offdesign_app'));
bt.Layout.Row = 3;

% ---- footer
gf = uigridlayout(g, [1 4]); gf.ColumnWidth = {'1x', 170, 190, 100}; gf.Padding = [0 0 0 0]; gf.Layout.Row = 4;
uilabel(gf, 'Text', 'Version 1.0  |  Cairo University, Aerospace Engineering  |  Close this window to quit.', 'FontColor', [0.4 0.4 0.4]);
uibutton(gf, 'Text', 'Guide: design app', 'ButtonPushedFcn', @(~, ~) open_guide('cda_guide.html'));
uibutton(gf, 'Text', 'Guide: off-design app', 'ButtonPushedFcn', @(~, ~) open_guide('cda_offdesign_guide.html'));
uibutton(gf, 'Text', 'Close', 'ButtonPushedFcn', @(~, ~) delete(f));

f.Visible = 'on';
if isdeployed
    waitfor(f);                                   % keeps the compiled program running
end

    function a = open_app(name)
        a = [];
        try
            a = feval(name);
            if ~isempty(icon), try, a.UIFigure.Icon = icon; catch, end, end
        catch err
            uialert(f, err.message, ['Could not start ' name]);
        end
    end

    function open_design(cfg)
        a = open_app('Compressor_design_app');
        if isempty(a), return; end
        try
            if ~strcmp(a.ConfigDD.Value, cfg)
                a.ConfigDD.Value = cfg;
                a.ConfigDD.ValueChangedFcn(a.ConfigDD, []);
            end
        catch
        end
    end

    function open_guide(name)
        p = local_file(name);
        if isempty(p), uialert(f, [name ' was not found next to the launcher.'], 'Guide'); return; end
        try, web(p, '-browser'); catch, web(p); end
    end
end

function p = local_file(name)
% file next to this launcher (also inside an installed toolbox or a compiled program)
p = fullfile(fileparts(mfilename('fullpath')), name);
if exist(p, 'file'), return; end
p = which(name);
if ~isempty(p), return; end
p = '';
if isdeployed
    d = dir(fullfile(ctfroot, '**', name));
    if ~isempty(d), p = fullfile(d(1).folder, d(1).name); end
end
end
