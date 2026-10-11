% CDA Compressor - Copyright (C) 2026 Ahmed Mohamed Ahmed Hassan, Abdalmoez Ahmed Abdullah Hemid,
% Thabet Saber Thabet Abdelhamid and Deyaa ElHaq Nabil Elshebiny (Cairo University).
% Free for noncommercial use under the PolyForm Noncommercial License 1.0.0; see LICENSE.
% https://github.com/AhmedDMoHassan/CDA-Compressor
classdef Compressor_design_app < matlab.apps.AppBase
    % COMPRESSOR_DESIGN_APP  Mean-line preliminary design of axial compressors
    % (rotor-stator, rotor-rotor on one shaft, rotor-rotor on two shafts) with any
    % number of stages / rotors, interactive design-space maps, point selection by
    % criteria or by clicking a map, and a direct link to Compressor_offdesign_app.
    %
    %   Compressor_design_app          standalone
    %   Compressor_design_app(main)    from the CDA launcher (main.mlapp)
    %
    % Needs cda_core.m in the same folder (or on the MATLAB path). The "Send to
    % off-design" button needs Compressor_offdesign_app (step 27 or later).

    % ============================== components ==============================
    properties (Access = public)
        UIFigure
        MainGrid; InputPanel; InGrid; Tabs; StatusLabel
        % inputs
        ConfigDD; NSpin; NLabel; LastStatorCB; LastExitDD; RotationDD
        RatioMin; RatioStep; RatioMax
        MdotEF; NrpmEF; Tt1EF; Pt1EF; Mr1EF; DFEF; DFSEF; ChordEF; GammaEF; RgEF
        LossRDD; LossSDD; C1DD
        PhiMin; PhiStep; PhiMax; PsiMin; PsiStep; PsiMax; RMin; RStep; RMax
        PointsLabel; ComputeBtn; DefaultsBtn; OpenProjBtn; SaveProjBtn
        % tabs
        GuideTab; SpaceTab; DesignTab; GeomTab; ExportTab; GuideArea; GuideHTML
        % design space tab
        RSliceDD; RatioSliceDD; PhiSliceDD; RowDD; ColorDD; ContourDD; NLinesSpin; ShowInfCB; AllRatiosCB
        AxSigma; AxSizing; AxPareto; AxContour
        ObjectiveDD; WeightEF; PRminCB; PRminEF; EtaMinCB; EtaMinEF; AmaxCB; AmaxEF; FixRCB; FixRatioCB
        SigMinEF; SigMaxEF; MmaxEF; DHminEF; ZetaMinEF; ZetaMaxEF; HCminEF; SwirlMaxEF
        FindBtn; CandTable; SelArea; UseBtn; FeasLabel; LegendLabel
        % design tab
        PhiEF; PsiEF; REF; RatioEF; DesignBtn; SendBtn2; OvTable; OvHint; ClearOvBtn; SumTable; RowTable; StaTable; WarnArea
        % geometry tab
        AxMerid; AxBlades; AxTri; TriRowDD
        % compare tab
        CompareTab; CmpTable; CmpRowDD; CmpStaDD; CmpTriDD; CmpSumTable; CmpHint
        AxCmpMap; AxCmpSize; AxCmpMerid; AxCmpRow; AxCmpSta; AxCmpTri
        % export tab
        SaveMatBtn; SendBtn; ExcelBtn; PngBtn; IncludeSpaceCB; ProjSpaceCB; VarTable
        ListTable; AddListBtn; RemoveListBtn; LoadListBtn; SaveAllBtn; LogArea
    end

    % ================================ state =================================
    properties (Access = public)
        Mainapp = []            % CDA launcher (main.mlapp) when started from it
        OffApp = []             % off-design app opened from here
        S = []                  % design space (cda_core.sweep)
        P = []                  % design point (phi, psi, R, ratio)
        Pv = []                 % selected (previewed) point of the design space (sweep index)
        VarOff = {}             % variables the user unticked for the design file
        D = []                  % design of P (cda_core.design)
        ov = struct('phi', [], 'psi', [], 'R', [], 'DF', [])   % per-stage / per-row overrides
        best = []               % best point for the criteria (sweep index)
        cand = []               % candidate list (sweep indices, best first)
        maps = cell(1, 4)       % clickable points of each map: x, y, i
        matfile = ''            % last saved design file (cleared when the design changes)
        list = {}               % design list (comparison)
        listsel = []
        cmpsel = []             % selected row of the comparison table
        last_folder = ''
        BusyDlg = []            % progress bar of the running operation
        test_dir = ''           % tests only: write files here instead of asking
    end

    % ============================== constants ===============================
    methods (Static)
        function g = gk()
            g = struct('phi', char(966), 'psi', char(968), 'sig', char(963), 'eta', char(951), ...
                       'pi', char(960), 'deg', char(176), 'zeta', char(950));
        end
        function place(c, r, k)
            % grid position (skipped for objects without a Layout property)
            if isprop(c, 'Layout')
                c.Layout.Row = r; c.Layout.Column = k;
            end
        end
        function s = f4(x)
            if ischar(x), s = x; elseif isempty(x) || ~isfinite(x), s = ''; else, s = sprintf('%.4g', x); end
        end
        function C = fmt_cells(C)
            % numbers -> short text for the display tables
            for i = 1:numel(C)
                x = C{i};
                if isnumeric(x) || islogical(x)
                    if isempty(x), C{i} = '';
                    elseif numel(x) > 1, C{i} = mat2str(x, 4);
                    elseif x == round(x) && abs(x) < 1e6, C{i} = sprintf('%d', x);
                    else, C{i} = sprintf('%.4g', x);
                    end
                end
            end
        end
        function v = vrange(a, s, b)
            if ~(s > 0) || b <= a, v = a; return; end
            v = a:s:(b + 1e-9*s);
            v = round(v*1e9)/1e9;
        end
    end

    % =========================== component creation ==========================
    methods (Access = private)
        function createComponents(app)
            G = app.gk();
            try, ss = get(groot, 'ScreenSize'); catch, ss = [1 1 1920 1080]; end
            w = min(1500, ss(3) - 50); h = min(900, ss(4) - 100);                % fits the screen above the taskbar
            pos = [max(1, floor((ss(3) - w)/2)), max(52, floor((ss(4) - h)/2)), w, h];
            app.UIFigure = uifigure('Visible', 'off', 'Position', pos, ...
                'Name', 'CDA - Compressor design (mean-line) | design space, point selection, export to off-design');
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @onClose, true);
            try                                                                  % window icon (CDA_icon_512.png next to the app)
                ic = fullfile(fileparts(mfilename('fullpath')), 'CDA_icon_512.png');
                if ~exist(ic, 'file'), ic = which('CDA_icon_512.png'); end
                if ~isempty(ic) && exist(ic, 'file'), app.UIFigure.Icon = ic; end
            catch
            end
            app.MainGrid = uigridlayout(app.UIFigure, [2 2]);
            app.MainGrid.ColumnWidth = {310, '1x'}; app.MainGrid.RowHeight = {'1x', 22};
            app.MainGrid.Padding = [6 6 6 6]; app.MainGrid.ColumnSpacing = 6; app.MainGrid.RowSpacing = 4;

            % ------------------------------ inputs ------------------------------
            app.InputPanel = uipanel(app.MainGrid, 'Title', 'Step 1 - Inputs', 'FontWeight', 'bold', 'Scrollable', 'on');
            app.place(app.InputPanel, 1, 1);
            g = uigridlayout(app.InputPanel, [32 4]);
            g.ColumnWidth = {112, '1x', '1x', '1x'}; g.RowHeight = repmat({20}, 1, 32);
            g.RowHeight{30} = 28; g.Padding = [4 3 4 3]; g.RowSpacing = 2; g.ColumnSpacing = 3;
            app.InGrid = g; r = 0;
            try, g.Scrollable = 'on'; catch, end
            r = r + 1; app.hdr(g, r, 'Machine');
            r = r + 1; app.lab(g, r, 'Configuration', 'Rotor-stator stages, rotor-rotor on one shaft, or rotor-rotor on two shafts (odd rotors on shaft 1, even rotors on shaft 2).');
            app.ConfigDD = uidropdown(g, 'Items', {'Rotor-Stator', 'Rotor-Rotor, same shaft', 'Rotor-Rotor, two shafts'}, ...
                'ItemsData', {'RS', 'RR-S', 'RR-D'}, 'Value', 'RS', 'ValueChangedFcn', createCallbackFcn(app, @onConfig, true));
            app.place(app.ConfigDD, r, [2 4]);
            r = r + 1; app.NLabel = app.lab(g, r, 'Number of stages', 'Rotor-stator: number of stages. Rotor-rotor: number of rotors.');
            app.NSpin = uispinner(g, 'Value', 2, 'Limits', [1 12], 'Step', 1, 'RoundFractionalValues', 'on', ...
                'ValueChangedFcn', createCallbackFcn(app, @onRowsChanged, true));
            app.place(app.NSpin, r, [2 4]);
            r = r + 1; app.LastStatorCB = uicheckbox(g, 'Text', 'Last stator present (rotor-stator)', 'Value', true, ...
                'ValueChangedFcn', createCallbackFcn(app, @onRowsChanged, true));
            app.place(app.LastStatorCB, r, [1 4]);
            r = r + 1; app.lab(g, r, 'Last stator exit', 'Exit flow angle of the last stator: the stage inlet angle (repeating stage) or axial (no exit swirl).');
            app.LastExitDD = uidropdown(g, 'Items', {'Stage inlet angle (repeating)', 'Axial (no swirl)'}, ...
                'ItemsData', {'repeat', 'axial'}, 'Value', 'repeat', 'ValueChangedFcn', createCallbackFcn(app, @onInputEdited, true));
            app.place(app.LastExitDD, r, [2 4]);
            r = r + 1; app.lab(g, r, 'Even rotors', 'Two shafts: direction of the even rotors (shaft 2). Counter-rotating rotors get a negative U2 in the design file.');
            app.RotationDD = uidropdown(g, 'Items', {'Same direction', 'Counter-rotating'}, 'ItemsData', {'same', 'counter'}, ...
                'Value', 'same', 'ValueChangedFcn', createCallbackFcn(app, @onInputEdited, true));
            app.place(app.RotationDD, r, [2 4]);
            r = r + 1; app.lab(g, r, 'Speed ratio U2/U1', 'Two shafts: blade-speed ratio of the even rotors (min, step, max of the design space).');
            [app.RatioMin, app.RatioStep, app.RatioMax] = app.rng3(g, r, [0.80 0.05 1.70]);

            r = r + 1; app.hdr(g, r, 'Operating point');
            r = r + 1; app.MdotEF = app.num(g, r, 'Mass flow [kg/s]', 0.5, 'Design mass flow.');
            r = r + 1; app.NrpmEF = app.num(g, r, 'Shaft speed [rpm]', 110e3, 'Speed of rotor 1 (shaft 1). It sets the mean radius: r_m = 60 U / (2 pi N).');
            r = r + 1; app.Tt1EF = app.num(g, r, 'Inlet Tt [K]', 288, 'Inlet stagnation temperature.');
            r = r + 1; app.Pt1EF = app.num(g, r, 'Inlet pt [Pa]', 1e5, 'Inlet stagnation pressure.');
            r = r + 1; app.Mr1EF = app.num(g, r, 'Rotor-1 Mach Mr1', 0.75, 'Relative inlet Mach number of rotor 1: with phi, psi and R it fixes the velocities.');

            r = r + 1; app.hdr(g, r, 'Blading and losses');
            r = r + 1; app.DFEF = app.num(g, r, 'DF rotors', 0.45, 'Lieblein diffusion factor of the rotors: sets the rotor solidity.');
            r = r + 1; app.DFSEF = app.num(g, r, 'DF stators', 0.45, 'Diffusion factor of the stators.');
            r = r + 1; app.ChordEF = app.num(g, r, 'Chord [mm]', 10, 'Blade chord (all rows): sets h/c and the blade numbers.');
            r = r + 1; app.lab(g, r, 'Loss model rotors', 'Profile loss y/c(DF): linear 0.08DF-0.008 (reference study: rotor-stator and two shafts) or quartic polynomial (reference study: same shaft).');
            app.LossRDD = uidropdown(g, 'Items', {'Linear 0.08DF-0.008', 'Quartic polynomial'}, 'ItemsData', {'linear', 'quartic'}, ...
                'Value', 'linear', 'ValueChangedFcn', createCallbackFcn(app, @onInputEdited, true));
            app.place(app.LossRDD, r, [2 4]);
            r = r + 1; app.lab(g, r, 'Loss model stators', 'Stator profile loss y/c(DF): linear 0.06DF-0.004 (reference study) or 6th-order polynomial.');
            app.LossSDD = uidropdown(g, 'Items', {'Linear 0.06DF-0.004', '6th-order polynomial'}, 'ItemsData', {'linear', 'poly6'}, ...
                'Value', 'linear', 'ValueChangedFcn', createCallbackFcn(app, @onInputEdited, true));
            app.place(app.LossSDD, r, [2 4]);
            r = r + 1; app.lab(g, r, 'Inlet velocity C1', ['How the inlet velocity is solved from the rotor-1 Mach number. Exact: closed form. ' ...
                'Iterative: fsolve from 100 m/s with the default tolerance (1e-6), as used for the reference designs; the two differ by 1e-6 to 1e-4.']);
            app.C1DD = uidropdown(g, 'Items', {'Exact (closed form)', 'Iterative (fsolve, tol. 1e-6)'}, 'ItemsData', {'exact', 'fsolve'}, ...
                'Value', 'exact', 'ValueChangedFcn', createCallbackFcn(app, @onInputEdited, true));
            app.place(app.C1DD, r, [2 4]);
            try, hasOpt = exist('fsolve', 'file') > 0 && license('test', 'Optimization_Toolbox'); catch, hasOpt = false; end
            if ~hasOpt
                app.C1DD.Items = {'Exact (closed form)', 'Iterative (needs Optimization Toolbox; exact used)'};
                app.C1DD.Tooltip = ['The Optimization Toolbox (fsolve) is not available: the exact closed form is used in both cases. ' ...
                    'The results differ from the iterative solution by 1e-6 to 1e-4 only.'];
            end
            r = r + 1; app.GammaEF = app.num(g, r, 'Gamma', 1.4, 'Ratio of specific heats.');
            r = r + 1; app.RgEF = app.num(g, r, 'Gas constant [J/kgK]', 287, 'Specific gas constant.');

            r = r + 1; app.hdr(g, r, 'Design space (sweep)');
            r = r + 1; app.lab(g, r, '');
            t = uilabel(g, 'Text', 'min', 'HorizontalAlignment', 'center'); app.place(t, r, 2);
            t = uilabel(g, 'Text', 'step', 'HorizontalAlignment', 'center'); app.place(t, r, 3);
            t = uilabel(g, 'Text', 'max', 'HorizontalAlignment', 'center'); app.place(t, r, 4);
            r = r + 1; app.lab(g, r, ['Flow coeff. ' G.phi], 'phi = Cx/U of stage 1.');
            [app.PhiMin, app.PhiStep, app.PhiMax] = app.rng3(g, r, [0.40 0.01 1.20]);
            r = r + 1; app.lab(g, r, ['Loading ' G.psi], 'psi = dh0/U^2 of every stage / rotor.');
            [app.PsiMin, app.PsiStep, app.PsiMax] = app.rng3(g, r, [0.20 0.01 0.50]);
            r = r + 1; app.lab(g, r, 'Reaction R', 'Degree of reaction of stage 1.');
            [app.RMin, app.RStep, app.RMax] = app.rng3(g, r, [0.50 0.01 0.75]);
            r = r + 1; app.PointsLabel = uilabel(g, 'Text', '', 'FontColor', [0.25 0.25 0.25]); app.place(app.PointsLabel, r, [1 4]);
            r = r + 1; app.ComputeBtn = uibutton(g, 'Text', ['Step 2 - Compute the design space  ' char(9654)], 'FontWeight', 'bold', ...
                'BackgroundColor', [0.85 0.92 1], 'ButtonPushedFcn', createCallbackFcn(app, @onCompute, true));
            app.place(app.ComputeBtn, r, [1 4]);
            r = r + 1; app.DefaultsBtn = uibutton(g, 'Text', 'Default inputs (reference study)', ...
                'Tooltip', ['Inputs of the reference study for the chosen configuration: 2 stages / rotors, its loss models, ' ...
                'mass flow, speed, Mr1, DF, chord, sweep ranges and limits, iterative inlet velocity.'], ...
                'ButtonPushedFcn', createCallbackFcn(app, @onDefaults, true));
            app.place(app.DefaultsBtn, r, [1 4]);
            r = r + 1; app.OpenProjBtn = uibutton(g, 'Text', 'Open project', 'ButtonPushedFcn', createCallbackFcn(app, @onOpenProject, true));
            app.place(app.OpenProjBtn, r, [1 2]);
            app.SaveProjBtn = uibutton(g, 'Text', 'Save project', 'ButtonPushedFcn', createCallbackFcn(app, @onSaveProject, true));
            app.place(app.SaveProjBtn, r, [3 4]);

            % ------------------------------ tabs ------------------------------
            app.Tabs = uitabgroup(app.MainGrid); app.place(app.Tabs, 1, 2);
            app.GuideTab = uitab(app.Tabs, 'Title', 'Guide');
            app.SpaceTab = uitab(app.Tabs, 'Title', 'Steps 2-3  Design space');
            app.DesignTab = uitab(app.Tabs, 'Title', 'Step 4  Design');
            app.GeomTab = uitab(app.Tabs, 'Title', 'Geometry');
            app.CompareTab = uitab(app.Tabs, 'Title', 'Compare designs');
            app.ExportTab = uitab(app.Tabs, 'Title', 'Step 5  Export & off-design');
            app.Tabs.SelectedTab = app.GuideTab;

            % guide: cda_guide.html (next to the app) in an HTML viewer, else plain text
            gg = uigridlayout(app.GuideTab, [2 2]); gg.RowHeight = {'1x', 30}; gg.ColumnWidth = {'1x', 280}; gg.Padding = [4 4 4 4];
            gf = app.guide_file(); shown = false;
            if ~isempty(gf)
                try
                    app.GuideHTML = uihtml(gg, 'HTMLSource', gf); app.place(app.GuideHTML, 1, [1 2]); shown = true;
                catch
                end
            end
            if ~shown
                app.GuideArea = uitextarea(gg, 'Editable', 'off', 'FontSize', 13, 'Value', app.guide_text());
                app.place(app.GuideArea, 1, [1 2]);
            end
            t = uilabel(gg, 'Text', 'Start here: the guide shows the workflow, every tab, the inputs and the outputs.', 'FontColor', [0.3 0.3 0.3]);
            app.place(t, 2, 1);
            b = uibutton(gg, 'Text', 'Open the guide in the web browser', 'ButtonPushedFcn', createCallbackFcn(app, @onOpenGuide, true));
            app.place(b, 2, 2);

            % ---------------------------- design space ----------------------------
            gs = uigridlayout(app.SpaceTab, [2 2]);
            gs.ColumnWidth = {'1x', 340}; gs.RowHeight = {98, '1x'}; gs.Padding = [4 4 4 4]; gs.RowSpacing = 4; gs.ColumnSpacing = 6;
            gc = uigridlayout(gs, [4 6]); app.place(gc, 1, 1);
            gc.ColumnWidth = {150, '1x', 136, '1x', 96, 62}; gc.RowHeight = {22, 22, 22, 18};
            gc.Padding = [0 0 0 0]; gc.RowSpacing = 3; gc.ColumnSpacing = 4;
            cb = createCallbackFcn(app, @plot_all, true);
            app.lab(gc, 1, 'Reaction R of the maps', 'The design map and the contour map show the points with this reaction R.');
            app.RSliceDD = uidropdown(gc, 'Items', {'-'}, 'ItemsData', 1, 'Value', 1, 'ValueChangedFcn', createCallbackFcn(app, @onSlice, true)); app.place(app.RSliceDD, 1, 2);
            t = uilabel(gc, 'Text', 'Speed ratio U2/U1', 'Tooltip', 'Two shafts only: the maps show the points with this speed ratio.'); app.place(t, 1, 3);
            app.RatioSliceDD = uidropdown(gc, 'Items', {'-'}, 'ItemsData', 1, 'Value', 1, 'ValueChangedFcn', createCallbackFcn(app, @onSlice, true)); app.place(app.RatioSliceDD, 1, 4);
            app.AllRatiosCB = uicheckbox(gc, 'Text', 'All speed ratios in the PR-eta map', 'Value', false, 'ValueChangedFcn', cb); app.place(app.AllRatiosCB, 1, [5 6]);
            t = uilabel(gc, 'Text', 'Solidity shown (design map)', 'Tooltip', 'Which blade row''s solidity is the x-axis of the design map.'); app.place(t, 2, 1);
            app.RowDD = uidropdown(gc, 'Items', {'-'}, 'ItemsData', 1, 'Value', 1, 'ValueChangedFcn', cb); app.place(app.RowDD, 2, 2);
            t = uilabel(gc, 'Text', [G.phi ' of the sizing lines'], 'Tooltip', 'The coloured lines of the sizing map are drawn at this flow coefficient.'); app.place(t, 2, 3);
            app.PhiSliceDD = uidropdown(gc, 'Items', {'-'}, 'ItemsData', 1, 'Value', 1, 'ValueChangedFcn', cb); app.place(app.PhiSliceDD, 2, 4);
            t = uilabel(gc, 'Text', 'Lines per map'); app.place(t, 2, 5);
            app.NLinesSpin = uispinner(gc, 'Value', 6, 'Limits', [2 20], 'Step', 1, 'RoundFractionalValues', 'on', 'ValueChangedFcn', cb); app.place(app.NLinesSpin, 2, 6);
            [it, id] = app.quantity_list();
            t = uilabel(gc, 'Text', 'Colour of the PR-eta map', 'Tooltip', ['The points of the pressure ratio - efficiency map are coloured by this quantity ' ...
                '(e.g. phi shows where along the Pareto front the flow coefficient changes).']); app.place(t, 3, 1);
            app.ColorDD = uidropdown(gc, 'Items', it, 'ItemsData', id, 'Value', 'phi', 'ValueChangedFcn', cb); app.place(app.ColorDD, 3, 2);
            t = uilabel(gc, 'Text', 'Contour map shows', 'Tooltip', 'Quantity drawn as filled contours over the phi-psi plane (at the R of the maps).'); app.place(t, 3, 3);
            app.ContourDD = uidropdown(gc, 'Items', it, 'ItemsData', id, 'Value', 'eta', 'ValueChangedFcn', cb); app.place(app.ContourDD, 3, 4);
            app.ShowInfCB = uicheckbox(gc, 'Text', 'Show infeasible points', 'Value', false, 'ValueChangedFcn', cb); app.place(app.ShowInfCB, 3, [5 6]);
            app.LegendLabel = uilabel(gc, 'Text', [char(9733) ' best point for the objective      ' char(9632) ' selected point (click a map or a candidate)      ' ...
                char(9675) ' current design (Design tab)      To pick points, switch off zoom / pan in the plot toolbar.'], 'FontColor', [0.25 0.25 0.25]);
            app.place(app.LegendLabel, 4, [1 6]);

            ga = uigridlayout(gs, [2 2]); app.place(ga, 2, 1);
            ga.Padding = [0 0 0 0]; ga.RowSpacing = 4; ga.ColumnSpacing = 4;
            app.AxSigma = uiaxes(ga); app.place(app.AxSigma, 1, 1);
            app.AxSizing = uiaxes(ga); app.place(app.AxSizing, 1, 2);
            app.AxPareto = uiaxes(ga); app.place(app.AxPareto, 2, 1);
            app.AxContour = uiaxes(ga); app.place(app.AxContour, 2, 2);
            for axm = {app.AxSigma, app.AxSizing, app.AxPareto, app.AxContour}
                set(axm{1}, 'ButtonDownFcn', createCallbackFcn(app, @onMapClick, true));   % click a map to select a point
            end

            % right column: criteria (scrolls) + selected point (always visible)
            grc = uigridlayout(gs, [2 1]); app.place(grc, [1 2], 2);
            grc.RowHeight = {'1x', 236}; grc.Padding = [0 0 0 0]; grc.RowSpacing = 4;
            cp = uipanel(grc, 'Title', 'Step 3 - Choose the design point', 'FontWeight', 'bold', 'Scrollable', 'on'); app.place(cp, 1, 1);
            gcr = uigridlayout(cp, [21 3]);
            gcr.ColumnWidth = {'1x', 64, 64}; gcr.RowHeight = repmat({22}, 1, 21);
            gcr.RowHeight{21} = 190; gcr.RowHeight{19} = 28;
            gcr.Padding = [4 4 4 4]; gcr.RowSpacing = 3; gcr.ColumnSpacing = 3;
            try, gcr.Scrollable = 'on'; catch, end
            lc = createCallbackFcn(app, @onCriteria, true);
            r = 1; app.hdr(gcr, r, 'Objective', 3);
            r = 2; app.ObjectiveDD = uidropdown(gcr, 'Items', {'Maximum pressure ratio', 'Maximum efficiency', 'Minimum inlet area (A1/m)', ...
                'Maximum (PR-1) per A1/m', 'Weighted PR and efficiency'}, 'ItemsData', {'max_PR', 'max_eta', 'min_A', 'max_PR_per_A', 'weighted'}, ...
                'Value', 'max_eta', 'ValueChangedFcn', lc); app.place(app.ObjectiveDD, r, [1 3]);
            r = 3; t = uilabel(gcr, 'Text', 'Weight of PR (weighted, 0-1)'); app.place(t, r, [1 2]);
            app.WeightEF = uieditfield(gcr, 'numeric', 'Value', 0.5, 'Limits', [0 1], 'ValueChangedFcn', lc); app.place(app.WeightEF, r, 3);
            r = 4; app.hdr(gcr, r, 'Constraints', 3);
            r = 5; app.PRminCB = uicheckbox(gcr, 'Text', 'Pressure ratio at least', 'ValueChangedFcn', lc); app.place(app.PRminCB, r, [1 2]);
            app.PRminEF = uieditfield(gcr, 'numeric', 'Value', 1.5, 'ValueChangedFcn', lc); app.place(app.PRminEF, r, 3);
            r = 6; app.EtaMinCB = uicheckbox(gcr, 'Text', 'Efficiency at least', 'ValueChangedFcn', lc); app.place(app.EtaMinCB, r, [1 2]);
            app.EtaMinEF = uieditfield(gcr, 'numeric', 'Value', 0.9, 'ValueChangedFcn', lc); app.place(app.EtaMinEF, r, 3);
            r = 7; app.AmaxCB = uicheckbox(gcr, 'Text', 'A1/m at most [cm^2 s/kg]', 'ValueChangedFcn', lc); app.place(app.AmaxCB, r, [1 2]);
            app.AmaxEF = uieditfield(gcr, 'numeric', 'Value', 40, 'ValueChangedFcn', lc); app.place(app.AmaxEF, r, 3);
            r = 8; app.FixRCB = uicheckbox(gcr, 'Text', 'Only the R of the maps', 'ValueChangedFcn', lc); app.place(app.FixRCB, r, [1 3]);
            r = 9; app.FixRatioCB = uicheckbox(gcr, 'Text', 'Only the speed ratio of the maps', 'ValueChangedFcn', lc); app.place(app.FixRatioCB, r, [1 3]);
            r = 10; app.hdr(gcr, r, 'Limits (a point violating one is infeasible)', 3);
            ll = createCallbackFcn(app, @onLimits, true);
            r = 11; app.lab(gcr, r, 'Solidity min / max', 'NACA-65 incidence and Carter deviation charts: 0.5-2.');
            app.SigMinEF = uieditfield(gcr, 'numeric', 'Value', 0.5, 'ValueChangedFcn', ll); app.place(app.SigMinEF, r, 2);
            app.SigMaxEF = uieditfield(gcr, 'numeric', 'Value', 2, 'ValueChangedFcn', ll); app.place(app.SigMaxEF, r, 3);
            r = 12; app.lab(gcr, r, 'Inlet Mach (all rows) max', 'Highest relative (rotor) or absolute (stator) inlet Mach number of any row.');
            app.MmaxEF = uieditfield(gcr, 'numeric', 'Value', 0.75, 'ValueChangedFcn', ll); app.place(app.MmaxEF, r, [2 3]);
            r = 13; app.lab(gcr, r, 'de Haller min', 'W2/W1 (rotors), C2/C1 (stators). 0 = no limit; 0.72 is the classical value.');
            app.DHminEF = uieditfield(gcr, 'numeric', 'Value', 0, 'ValueChangedFcn', ll); app.place(app.DHminEF, r, [2 3]);
            r = 14; app.lab(gcr, r, 'Hub/tip min / max', 'At every station.');
            app.ZetaMinEF = uieditfield(gcr, 'numeric', 'Value', 0, 'ValueChangedFcn', ll); app.place(app.ZetaMinEF, r, 2);
            app.ZetaMaxEF = uieditfield(gcr, 'numeric', 'Value', 1, 'ValueChangedFcn', ll); app.place(app.ZetaMaxEF, r, 3);
            r = 15; app.lab(gcr, r, 'Blade h/c min', 'Blade height / chord at every station (0 = no limit).');
            app.HCminEF = uieditfield(gcr, 'numeric', 'Value', 0, 'ValueChangedFcn', ll); app.place(app.HCminEF, r, [2 3]);
            r = 16; app.lab(gcr, r, ['Exit swirl max [' G.deg ']'], 'Absolute flow angle leaving the machine (90 = no limit).');
            app.SwirlMaxEF = uieditfield(gcr, 'numeric', 'Value', 90, 'ValueChangedFcn', ll); app.place(app.SwirlMaxEF, r, [2 3]);
            r = 17; app.FeasLabel = uilabel(gcr, 'Text', '', 'FontColor', [0.25 0.25 0.25], 'WordWrap', 'on'); app.place(app.FeasLabel, [r r + 1], [1 3]);
            r = 19; app.FindBtn = uibutton(gcr, 'Text', 'Find the best point', 'FontWeight', 'bold', 'BackgroundColor', [0.85 0.92 1], ...
                'ButtonPushedFcn', createCallbackFcn(app, @onFind, true)); app.place(app.FindBtn, r, [1 3]);
            r = 20; app.hdr(gcr, r, 'Best candidates (click a row to select it)', 3);
            r = 21; app.CandTable = uitable(gcr, 'ColumnName', {'#', G.phi, G.psi, 'R', 'ratio', 'PR', G.eta, 'A1/m'}, 'RowName', {}, ...
                'Data', cell(0, 8), 'CellSelectionCallback', createCallbackFcn(app, @onCandSelect, true)); app.place(app.CandTable, r, [1 3]);
            app.CandTable.ColumnWidth = {24, 40, 40, 38, 38, 46, 46, 'auto'};
            sp = uipanel(grc, 'Title', 'Selected point', 'FontWeight', 'bold'); app.place(sp, 2, 1);
            gsp = uigridlayout(sp, [2 1]); gsp.RowHeight = {'1x', 34}; gsp.Padding = [4 4 4 4]; gsp.RowSpacing = 4;
            app.SelArea = uitextarea(gsp, 'Editable', 'off', 'Value', {'No point selected yet.', 'Compute the design space, then click a map', 'or a candidate, or press "Find the best point".'});
            app.place(app.SelArea, 1, 1);
            app.UseBtn = uibutton(gsp, 'Text', ['Use this point  ' char(9654) '  Design tab'], 'FontWeight', 'bold', 'BackgroundColor', [0.80 0.92 0.80], ...
                'Tooltip', 'Design the selected point in detail (all rows and stations) and open the Design tab.', ...
                'ButtonPushedFcn', createCallbackFcn(app, @onUsePoint, true)); app.place(app.UseBtn, 2, 1);

            % ------------------------------- design -------------------------------
            gd = uigridlayout(app.DesignTab, [4 2]);
            gd.ColumnWidth = {'1.1x', '1x'}; gd.RowHeight = {96, 200, '1x', 210}; gd.Padding = [4 4 4 4]; gd.RowSpacing = 4; gd.ColumnSpacing = 6;
            pp = uipanel(gd, 'Title', 'Step 4 - Design point of stage 1 / rotor 1 (from the Design space tab, or type it)', 'FontWeight', 'bold'); app.place(pp, 1, 1);
            gp = uigridlayout(pp, [2 8]); gp.ColumnWidth = {28, '1x', 28, '1x', 22, '1x', 40, '1x'}; gp.RowHeight = {22, 28};
            gp.Padding = [4 4 4 4]; gp.RowSpacing = 4; gp.ColumnSpacing = 3;
            t = uilabel(gp, 'Text', G.phi, 'HorizontalAlignment', 'right'); app.place(t, 1, 1);
            app.PhiEF = uieditfield(gp, 'numeric', 'Value', 0.6, 'ValueDisplayFormat', '%.4g'); app.place(app.PhiEF, 1, 2);
            t = uilabel(gp, 'Text', G.psi, 'HorizontalAlignment', 'right'); app.place(t, 1, 3);
            app.PsiEF = uieditfield(gp, 'numeric', 'Value', 0.3, 'ValueDisplayFormat', '%.4g'); app.place(app.PsiEF, 1, 4);
            t = uilabel(gp, 'Text', 'R', 'HorizontalAlignment', 'right'); app.place(t, 1, 5);
            app.REF = uieditfield(gp, 'numeric', 'Value', 0.5, 'ValueDisplayFormat', '%.4g'); app.place(app.REF, 1, 6);
            t = uilabel(gp, 'Text', 'U2/U1', 'HorizontalAlignment', 'right'); app.place(t, 1, 7);
            app.RatioEF = uieditfield(gp, 'numeric', 'Value', 1, 'ValueDisplayFormat', '%.4g'); app.place(app.RatioEF, 1, 8);
            app.DesignBtn = uibutton(gp, 'Text', 'Design the typed point', 'FontWeight', 'bold', 'ButtonPushedFcn', createCallbackFcn(app, @onDesignTyped, true));
            app.place(app.DesignBtn, 2, [1 4]);
            app.SendBtn2 = uibutton(gp, 'Text', ['Send to the off-design app  ' char(9654)], 'FontWeight', 'bold', 'BackgroundColor', [0.85 0.92 1], ...
                'ButtonPushedFcn', createCallbackFcn(app, @onSend, true));
            app.place(app.SendBtn2, 2, [5 8]);
            op = uipanel(gd, 'Title', 'Stages / rotors - double-click a cell to give that stage its own value', 'FontWeight', 'bold'); app.place(op, 2, 1);
            go = uigridlayout(op, [2 2]); go.RowHeight = {'1x', 26}; go.ColumnWidth = {'1x', 200}; go.Padding = [2 2 2 2]; go.RowSpacing = 3;
            app.OvTable = uitable(go, 'RowName', {}, 'Data', cell(0, 6), 'CellEditCallback', createCallbackFcn(app, @onOvEdit, true));
            app.place(app.OvTable, 1, [1 2]);
            app.OvHint = uilabel(go, 'Text', 'Blue row = design point. Yellow cell = this stage differs from stage 1 (or from the global DF).', ...
                'FontColor', [0.3 0.3 0.3], 'WordWrap', 'on'); app.place(app.OvHint, 2, 1);
            app.ClearOvBtn = uibutton(go, 'Text', 'Reset: all stages repeat stage 1', 'ButtonPushedFcn', createCallbackFcn(app, @onClearOv, true));
            app.place(app.ClearOvBtn, 2, 2);
            app.SumTable = uitable(gd, 'ColumnName', {'Quantity', 'Value', 'Unit'}, 'RowName', {}, 'Data', cell(0, 3));
            app.place(app.SumTable, [1 2], 2);
            app.RowTable = uitable(gd, 'RowName', {}, 'Data', cell(0, 1)); app.place(app.RowTable, 3, [1 2]);
            app.StaTable = uitable(gd, 'RowName', {}, 'Data', cell(0, 1)); app.place(app.StaTable, 4, 1);
            app.WarnArea = uitextarea(gd, 'Editable', 'off', 'Value', {'No design yet: choose a point in the Design space tab and press "Use this point", or type a point above.'});
            app.place(app.WarnArea, 4, 2);

            % ------------------------------ geometry ------------------------------
            gq = uigridlayout(app.GeomTab, [2 2]); gq.RowHeight = {'1x', '1.15x'}; gq.Padding = [4 4 4 4];
            app.AxMerid = uiaxes(gq); app.place(app.AxMerid, 1, [1 2]);
            app.AxBlades = uiaxes(gq); app.place(app.AxBlades, 2, 1);
            gt = uigridlayout(gq, [2 2]); app.place(gt, 2, 2); gt.RowHeight = {22, '1x'}; gt.ColumnWidth = {110, '1x'}; gt.Padding = [0 0 0 0];
            t = uilabel(gt, 'Text', 'Velocity triangles of'); app.place(t, 1, 1);
            app.TriRowDD = uidropdown(gt, 'Items', {'-'}, 'ItemsData', 1, 'Value', 1, 'ValueChangedFcn', createCallbackFcn(app, @plot_triangles, true)); app.place(app.TriRowDD, 1, 2);
            app.AxTri = uiaxes(gt); app.place(app.AxTri, 2, [1 2]);

            % ------------------------------- compare -------------------------------
            gk = uigridlayout(app.CompareTab, [2 2]); gk.ColumnWidth = {330, '1x'}; gk.RowHeight = {'1x', 210};
            gk.Padding = [4 4 4 4]; gk.RowSpacing = 4; gk.ColumnSpacing = 6;
            kp = uipanel(gk, 'Title', 'Designs compared (the design list)', 'FontWeight', 'bold'); app.place(kp, 1, 1);
            gkl = uigridlayout(kp, [11 2]); gkl.RowHeight = {'1x', 28, 28, 18, 22, 18, 22, 18, 22, 28, 54};
            gkl.ColumnWidth = {'1x', '1x'}; gkl.Padding = [4 4 4 4]; gkl.RowSpacing = 3; gkl.ColumnSpacing = 4;
            app.CmpTable = uitable(gkl, 'RowName', {}, 'ColumnName', {'Show', 'Name (editable)', 'Type', 'PR', G.eta}, 'Data', cell(0, 5), ...
                'ColumnEditable', [true true false false false], 'CellEditCallback', createCallbackFcn(app, @onCmpEdit, true), ...
                'CellSelectionCallback', createCallbackFcn(app, @onCmpSelect, true));
            app.CmpTable.ColumnWidth = {40, 'auto', 52, 46, 46};
            app.place(app.CmpTable, 1, [1 2]);
            b = uibutton(gkl, 'Text', 'Add current design', 'Tooltip', 'Adds the design of the Design tab to the list.', ...
                'ButtonPushedFcn', createCallbackFcn(app, @onListAdd, true)); app.place(b, 2, 1);
            b = uibutton(gkl, 'Text', 'Add files (.mat)...', 'Tooltip', ['Design files written by this app (rebuilt from their design record) ' ...
                'or project files (their design list).'], 'ButtonPushedFcn', createCallbackFcn(app, @onCmpFiles, true)); app.place(b, 2, 2);
            b = uibutton(gkl, 'Text', 'Remove selected', 'ButtonPushedFcn', createCallbackFcn(app, @onCmpRemove, true)); app.place(b, 3, 1);
            b = uibutton(gkl, 'Text', 'Remove all', 'ButtonPushedFcn', createCallbackFcn(app, @onCmpClear, true)); app.place(b, 3, 2);
            cbk = createCallbackFcn(app, @plot_compare, true);
            t = uilabel(gkl, 'Text', 'Blade-row plot (per row)'); app.place(t, 4, [1 2]);
            [it, id] = app.cmp_row_list();
            app.CmpRowDD = uidropdown(gkl, 'Items', it, 'ItemsData', id, 'Value', 'sigma', 'ValueChangedFcn', cbk); app.place(app.CmpRowDD, 5, [1 2]);
            t = uilabel(gkl, 'Text', 'Through the machine (per station)'); app.place(t, 6, [1 2]);
            [it, id] = app.cmp_sta_list();
            app.CmpStaDD = uidropdown(gkl, 'Items', it, 'ItemsData', id, 'Value', 'PR', 'ValueChangedFcn', cbk); app.place(app.CmpStaDD, 7, [1 2]);
            t = uilabel(gkl, 'Text', 'Velocity triangles of'); app.place(t, 8, [1 2]);
            app.CmpTriDD = uidropdown(gkl, 'Items', {'Row 1'}, 'ItemsData', 1, 'Value', 1, 'ValueChangedFcn', cbk); app.place(app.CmpTriDD, 9, [1 2]);
            b = uibutton(gkl, 'Text', 'Save the plots (PNG)', 'ButtonPushedFcn', createCallbackFcn(app, @onCmpPng, true)); app.place(b, 10, 1);
            b = uibutton(gkl, 'Text', 'Export the table', 'Tooltip', 'Comparison table to Excel (.xlsx) or text (.csv).', ...
                'ButtonPushedFcn', createCallbackFcn(app, @onCmpTable, true)); app.place(b, 10, 2);
            app.CmpHint = uilabel(gkl, 'Text', ['Each design has one colour in all plots. Tick "Show" to hide or show a design; ' ...
                'click a row, then "Remove selected" to delete it. Circles: rotors, squares: stators.'], 'WordWrap', 'on', 'FontColor', [0.3 0.3 0.3]);
            app.place(app.CmpHint, 11, [1 2]);
            gka = uigridlayout(gk, [2 3]); app.place(gka, 1, 2); gka.Padding = [0 0 0 0]; gka.RowSpacing = 4; gka.ColumnSpacing = 4;
            app.AxCmpMap = uiaxes(gka); app.place(app.AxCmpMap, 1, 1);
            app.AxCmpSize = uiaxes(gka); app.place(app.AxCmpSize, 1, 2);
            app.AxCmpMerid = uiaxes(gka); app.place(app.AxCmpMerid, 1, 3);
            app.AxCmpRow = uiaxes(gka); app.place(app.AxCmpRow, 2, 1);
            app.AxCmpSta = uiaxes(gka); app.place(app.AxCmpSta, 2, 2);
            app.AxCmpTri = uiaxes(gka); app.place(app.AxCmpTri, 2, 3);
            app.CmpSumTable = uitable(gk, 'RowName', {}, 'ColumnName', {'Quantity'}, 'Data', cell(0, 1)); app.place(app.CmpSumTable, 2, [1 2]);

            % ------------------------------- export -------------------------------
            ge = uigridlayout(app.ExportTab, [2 2]); ge.ColumnWidth = {'1x', '1.2x'}; ge.RowHeight = {'1x', 140}; ge.Padding = [4 4 4 4];
            bp = uipanel(ge, 'Title', 'Step 5 - Export the current design', 'FontWeight', 'bold'); app.place(bp, 1, 1);
            gb = uigridlayout(bp, [8 3]); gb.RowHeight = {34, 30, 20, '1x', 26, 30, 22, 30}; gb.ColumnWidth = {'1x', '1x', '1x'};
            gb.Padding = [6 6 6 6]; gb.RowSpacing = 4;
            app.SendBtn = uibutton(gb, 'Text', ['Send to the off-design app  ' char(9654)], 'FontWeight', 'bold', 'BackgroundColor', [0.85 0.92 1], ...
                'Tooltip', 'Saves the design file (.mat) with the variables ticked below and loads it into the off-design app.', ...
                'ButtonPushedFcn', createCallbackFcn(app, @onSend, true)); app.place(app.SendBtn, 1, [1 3]);
            app.SaveMatBtn = uibutton(gb, 'Text', 'Save the design file (.mat) only', 'ButtonPushedFcn', createCallbackFcn(app, @onSaveMat, true)); app.place(app.SaveMatBtn, 2, [1 3]);
            app.hdr(gb, 3, 'Variables written to the design file (tick / untick)', 3);
            app.VarTable = uitable(gb, 'RowName', {}, 'ColumnName', {'Write', 'Variable', 'Meaning', 'Size', 'Off-design app'}, ...
                'Data', cell(0, 5), 'ColumnEditable', [true false false false false], 'CellEditCallback', createCallbackFcn(app, @onVarEdit, true));
            app.VarTable.ColumnWidth = {44, 112, 'auto', 46, 120};
            app.place(app.VarTable, 4, [1 3]);
            b = uibutton(gb, 'Text', 'Tick all', 'ButtonPushedFcn', createCallbackFcn(app, @onVarAll, true)); app.place(b, 5, 1);
            b = uibutton(gb, 'Text', 'Required only', 'ButtonPushedFcn', createCallbackFcn(app, @onVarRequired, true)); app.place(b, 5, 2);
            b = uibutton(gb, 'Text', 'Required + blading', 'Tooltip', 'Required variables, stator blading and solidities/chord (Koch check).', ...
                'ButtonPushedFcn', createCallbackFcn(app, @onVarBlading, true)); app.place(b, 5, 3);
            app.ExcelBtn = uibutton(gb, 'Text', 'Export the tables to Excel', 'ButtonPushedFcn', createCallbackFcn(app, @onExcel, true)); app.place(app.ExcelBtn, 6, [1 2]);
            app.PngBtn = uibutton(gb, 'Text', 'Save all plots (PNG, 300 dpi)', 'ButtonPushedFcn', createCallbackFcn(app, @onPng, true)); app.place(app.PngBtn, 6, 3);
            app.IncludeSpaceCB = uicheckbox(gb, 'Text', 'Excel: include the feasible design space (large)', 'Value', false); app.place(app.IncludeSpaceCB, 7, [1 3]);
            app.ProjSpaceCB = uicheckbox(gb, 'Text', 'Projects (left panel): also save the design space', 'Value', false); app.place(app.ProjSpaceCB, 8, [1 3]);
            lp = uipanel(ge, 'Title', 'Design list - keep designs to compare them and to export several at once', 'FontWeight', 'bold'); app.place(lp, 1, 2);
            gl = uigridlayout(lp, [2 4]); gl.RowHeight = {'1x', 30}; gl.Padding = [4 4 4 4];
            app.ListTable = uitable(gl, 'RowName', {}, 'Data', cell(0, 1), 'CellSelectionCallback', createCallbackFcn(app, @onListSelect, true)); app.place(app.ListTable, 1, [1 4]);
            app.AddListBtn = uibutton(gl, 'Text', 'Add current design', 'ButtonPushedFcn', createCallbackFcn(app, @onListAdd, true)); app.place(app.AddListBtn, 2, 1);
            app.LoadListBtn = uibutton(gl, 'Text', 'Load selected', 'ButtonPushedFcn', createCallbackFcn(app, @onListLoad, true)); app.place(app.LoadListBtn, 2, 2);
            app.RemoveListBtn = uibutton(gl, 'Text', 'Remove selected', 'ButtonPushedFcn', createCallbackFcn(app, @onListRemove, true)); app.place(app.RemoveListBtn, 2, 3);
            app.SaveAllBtn = uibutton(gl, 'Text', 'Save all as .mat (folder)', 'ButtonPushedFcn', createCallbackFcn(app, @onListSaveAll, true)); app.place(app.SaveAllBtn, 2, 4);
            app.LogArea = uitextarea(ge, 'Editable', 'off', 'Value', {''}); app.place(app.LogArea, 2, [1 2]);

            app.StatusLabel = uilabel(app.MainGrid, 'Text', 'Ready.', 'FontColor', [0.2 0.2 0.2]);
            app.place(app.StatusLabel, 2, [1 2]);
            app.UIFigure.Visible = 'on';
        end

        % --------------------------- small UI helpers ---------------------------
        function l = lab(app, g, r, txt, tip)
            l = uilabel(g, 'Text', txt);
            if nargin > 4, l.Tooltip = tip; end
            app.place(l, r, 1);
        end
        function hdr(app, g, r, txt, ncol)
            if nargin < 5, ncol = 4; end
            l = uilabel(g, 'Text', txt, 'FontWeight', 'bold', 'FontColor', [0.1 0.25 0.5]);
            app.place(l, r, [1 ncol]);
        end
        function f = num(app, g, r, txt, val, tip)
            app.lab(g, r, txt, tip);
            f = uieditfield(g, 'numeric', 'Value', val, 'ValueDisplayFormat', '%.6g', 'Tooltip', tip, ...
                'ValueChangedFcn', createCallbackFcn(app, @onInputEdited, true));
            app.place(f, r, [2 4]);
        end
        function [a, b, c] = rng3(app, g, r, v)
            cb = createCallbackFcn(app, @onInputEdited, true);
            a = uieditfield(g, 'numeric', 'Value', v(1), 'ValueDisplayFormat', '%.4g', 'ValueChangedFcn', cb); app.place(a, r, 2);
            b = uieditfield(g, 'numeric', 'Value', v(2), 'ValueDisplayFormat', '%.4g', 'ValueChangedFcn', cb); app.place(b, r, 3);
            c = uieditfield(g, 'numeric', 'Value', v(3), 'ValueDisplayFormat', '%.4g', 'ValueChangedFcn', cb); app.place(c, r, 4);
        end
        function goTab(app, t)
            app.Tabs.SelectedTab = t;
        end
    end

    % ============================== inputs ===============================
    methods (Access = private)
        function o = read_inputs(app)
            o = cda_core.defaults(app.ConfigDD.Value);
            o.n = max(1, round(app.NSpin.Value));
            o.last_stator = logical(app.LastStatorCB.Value);
            o.last_exit = app.LastExitDD.Value;
            o.rotation = app.RotationDD.Value;
            o.ratio_vec = app.vrange(app.RatioMin.Value, app.RatioStep.Value, app.RatioMax.Value);
            o.m_dot = app.MdotEF.Value; o.N_rpm = app.NrpmEF.Value;
            o.Tt1 = app.Tt1EF.Value; o.Pt1 = app.Pt1EF.Value; o.Mr1 = app.Mr1EF.Value;
            o.DF = app.DFEF.Value; o.DF_S = app.DFSEF.Value; o.chord = app.ChordEF.Value/1000;
            o.loss_R = app.LossRDD.Value; o.loss_S = app.LossSDD.Value;
            o.gamma = app.GammaEF.Value; o.Rg = app.RgEF.Value; o.C1_solver = app.C1DD.Value;
            o.phi_vec = app.vrange(app.PhiMin.Value, app.PhiStep.Value, app.PhiMax.Value);
            o.psi_vec = app.vrange(app.PsiMin.Value, app.PsiStep.Value, app.PsiMax.Value);
            o.R_vec = app.vrange(app.RMin.Value, app.RStep.Value, app.RMax.Value);
            o.lim = app.read_limits();
            o.ov = app.ov;
            if ~isempty(app.P), o.ratio_U = app.P.ratio; end
            if ~strcmp(o.config, 'RS'), o.last_stator = true; end
        end

        function set_inputs(app, o)
            app.ConfigDD.Value = o.config; app.NSpin.Value = o.n;
            app.LastStatorCB.Value = o.last_stator; app.LastExitDD.Value = o.last_exit; app.RotationDD.Value = o.rotation;
            app.set_range(app.RatioMin, app.RatioStep, app.RatioMax, o.ratio_vec);
            app.MdotEF.Value = o.m_dot; app.NrpmEF.Value = o.N_rpm; app.Tt1EF.Value = o.Tt1; app.Pt1EF.Value = o.Pt1;
            app.Mr1EF.Value = o.Mr1; app.DFEF.Value = o.DF; app.DFSEF.Value = o.DF_S; app.ChordEF.Value = 1000*o.chord;
            app.LossRDD.Value = o.loss_R; app.LossSDD.Value = o.loss_S; app.GammaEF.Value = o.gamma; app.RgEF.Value = o.Rg;
            if isfield(o, 'C1_solver'), app.C1DD.Value = o.C1_solver; end
            app.set_range(app.PhiMin, app.PhiStep, app.PhiMax, o.phi_vec);
            app.set_range(app.PsiMin, app.PsiStep, app.PsiMax, o.psi_vec);
            app.set_range(app.RMin, app.RStep, app.RMax, o.R_vec);
            app.set_limits(o.lim);
            app.update_enable();
        end

        function set_range(~, a, b, c, v)
            a.Value = v(1); c.Value = v(end);
            if numel(v) > 1, b.Value = round((v(2) - v(1))*1e9)/1e9; else, b.Value = 0; end
        end

        function L = read_limits(app)
            L = struct('sigma', [app.SigMinEF.Value app.SigMaxEF.Value], 'M_max', app.MmaxEF.Value, ...
                'dH_min', app.DHminEF.Value, 'zeta', [app.ZetaMinEF.Value app.ZetaMaxEF.Value], ...
                'h_c_min', app.HCminEF.Value, 'exit_swirl_max', app.SwirlMaxEF.Value);
        end

        function set_limits(app, L)
            app.SigMinEF.Value = L.sigma(1); app.SigMaxEF.Value = L.sigma(2); app.MmaxEF.Value = L.M_max;
            app.DHminEF.Value = L.dH_min; app.ZetaMinEF.Value = L.zeta(1); app.ZetaMaxEF.Value = L.zeta(2);
            app.HCminEF.Value = L.h_c_min; app.SwirlMaxEF.Value = L.exit_swirl_max;
        end

        function update_enable(app)
            c = app.ConfigDD.Value; oo = {'off', 'on'};
            isRS = strcmp(c, 'RS'); isD = strcmp(c, 'RR-D');
            app.LastStatorCB.Enable = oo{isRS + 1}; app.LastExitDD.Enable = oo{isRS + 1}; app.DFSEF.Enable = oo{isRS + 1};
            app.LossSDD.Enable = oo{isRS + 1};
            app.RotationDD.Enable = oo{isD + 1};
            app.RatioMin.Enable = oo{isD + 1}; app.RatioStep.Enable = oo{isD + 1}; app.RatioMax.Enable = oo{isD + 1};
            app.RatioEF.Enable = oo{isD + 1};
            if isRS, app.NLabel.Text = 'Number of stages'; else, app.NLabel.Text = 'Number of rotors'; end
        end

        function msg = check_inputs(~, o)
            msg = {};
            pos = {'m_dot', 'N_rpm', 'Tt1', 'Pt1', 'Mr1', 'chord', 'gamma', 'Rg', 'DF', 'DF_S'};
            for i = 1:numel(pos)
                if ~(o.(pos{i}) > 0), msg{end+1} = sprintf('%s must be > 0.', pos{i}); end %#ok<AGROW>
            end
            if o.gamma <= 1, msg{end+1} = 'Gamma must be > 1.'; end
            if o.DF >= 1 || o.DF_S >= 1, msg{end+1} = 'The diffusion factors must be < 1.'; end
            if any(o.phi_vec <= 0), msg{end+1} = 'phi must be > 0.'; end
            if any(o.psi_vec <= 0), msg{end+1} = 'psi must be > 0.'; end
            if strcmp(o.config, 'RR-D') && any(o.ratio_vec <= 0), msg{end+1} = 'The speed ratio must be > 0 (choose the direction with "Even rotors").'; end
        end

        function n = n_points(~, o)
            n = numel(o.phi_vec)*numel(o.psi_vec)*numel(o.R_vec);
            if strcmp(o.config, 'RR-D'), n = n*numel(o.ratio_vec); end
        end

        function st = is_stale(app)
            % the design space was computed with other inputs than the current ones
            st = false;
            if isempty(app.S), return; end
            a = app.S.opts; b = app.read_inputs();
            f = {'config', 'n', 'last_stator', 'last_exit', 'rotation', 'm_dot', 'N_rpm', 'Tt1', 'Pt1', 'Mr1', 'DF', 'DF_S', ...
                 'chord', 'loss_R', 'loss_S', 'gamma', 'Rg', 'phi_vec', 'psi_vec', 'R_vec'};
            if strcmp(b.config, 'RR-D'), f{end+1} = 'ratio_vec'; end
            for i = 1:numel(f)
                if ~isequal(a.(f{i}), b.(f{i})), st = true; return; end
            end
        end
    end

    % ============================== callbacks ===============================
    methods (Access = private)
        function startupFcn(app, main)
            if nargin < 2, main = []; end
            app.Mainapp = main;
            app.set_inputs(cda_core.defaults('RS'));
            app.update_points_label();
            app.blank_maps();
            app.log('Ready. Set the inputs, press "Compute design space", then pick a point (criteria or click on a map).');
        end

        function onClose(app, ~)
            try
                if ~isempty(app.Mainapp) && isvalid(app.Mainapp)
                    app.Mainapp.GotooperationButton.Enable = 'on';
                end
            catch
            end
            delete(app);
        end

        function onConfig(app, ~)
            if strcmp(app.ConfigDD.Value, 'RR-S'), app.LossRDD.Value = 'quartic'; else, app.LossRDD.Value = 'linear'; end
            app.update_enable();
            app.onInputChanged(true);
        end

        function onDefaults(app, ~)
            % inputs of the reference study for the chosen configuration: 2 stages / rotors,
            % same-direction shafts, its loss models, inputs, sweep ranges and limits, and the
            % iterative inlet velocity; the last-stator choice is kept
            o = cda_core.defaults(app.ConfigDD.Value);
            o.last_stator = logical(app.LastStatorCB.Value);
            o.C1_solver = 'fsolve';
            app.ov = struct('phi', [], 'psi', [], 'R', [], 'DF', []);
            app.set_inputs(o);
            app.onInputChanged(true);
            msg = sprintf(['Default inputs of the reference study set for %s: %d %s, rotor loss %s, stator loss %s, mass flow %.3g kg/s, %.0f rpm, ' ...
                'Mr1 %.2f, DF %.2f, chord %.0f mm, iterative C1, reference sweep ranges and limits.'], cda_core.offdesign_type(o), o.n, ...
                app.NLabel.Text(11:end), o.loss_R, o.loss_S, o.m_dot, o.N_rpm, o.Mr1, o.DF, 1e3*o.chord);
            app.log(msg);
            if isempty(app.test_dir), uialert(app.UIFigure, msg, 'Default inputs', 'Icon', 'success'); end
        end

        function onRowsChanged(app, ~)
            app.onInputChanged(true);
        end

        function onInputEdited(app, ~)
            app.onInputChanged(false);
        end

        function onDetails(app, ~)
            app.Tabs.SelectedTab = app.DesignTab;
        end

        function onInputChanged(app, rows_changed)
            if nargin < 2, rows_changed = false; end
            if rows_changed, app.ov.DF = []; end            % row numbering changed
            app.update_enable();
            app.update_points_label();
            if ~isempty(app.P), app.redesign(); end
            if app.is_stale()
                app.status('Inputs changed since the design space was computed: the maps show the old inputs - press "Compute design space".');
            end
        end

        function update_points_label(app)
            o = app.read_inputs(); np = app.n_points(o); nr = numel(cda_core.row_list(o));
            app.PointsLabel.Text = sprintf('%s points x %d rows (about %.0f s)', app.thousands(np), nr, max(1, np*nr/1.5e6));
        end

        function onCompute(app, ~)
            o = app.read_inputs();
            msg = app.check_inputs(o);
            if ~isempty(msg), app.alert(strjoin(msg, newline), 'Input error'); return; end
            np = app.n_points(o); nr = numel(cda_core.row_list(o));
            if np*nr > 1.5e8
                a = app.confirm(sprintf('%s points x %d rows is a very large design space (memory and time). Continue?', app.thousands(np), nr), ...
                    'Large design space', {'Continue', 'Cancel'});
                if ~strcmp(a, 'Continue'), return; end
            end
            app.ComputeBtn.Enable = 'off'; dlg = [];
            if isempty(app.test_dir)
                try
                    dlg = uiprogressdlg(app.UIFigure, 'Title', 'Computing the design space', ...
                        'Message', sprintf('Designing %s points x %d rows...', app.thousands(np), nr));
                    drawnow;
                catch
                end
            end
            try
                tic;
                if isempty(dlg), S = cda_core.sweep(o); else, S = cda_core.sweep(o, @(f) app.set_progress(dlg, f)); end
                t = toc;
            catch err
                app.ComputeBtn.Enable = 'on'; app.close_dlg(dlg);
                app.alert(['Design space failed: ' err.message], 'Error'); return;
            end
            app.ComputeBtn.Enable = 'on';
            cl = onCleanup(@() app.close_dlg(dlg)); %#ok<NASGU>
            if ~isempty(dlg)
                try, dlg.Indeterminate = 'on'; dlg.Message = 'Selecting the best point and drawing the maps...'; drawnow; catch, end
            end
            app.S = S;
            app.setup_slices();
            app.update_feasible_label();
            app.refresh_best();
            app.log(sprintf('Design space: %s points, %s feasible, %.1f s.', app.thousands(np), app.thousands(nnz(S.ok)), t));
            if isempty(app.best)
                app.plot_all();
                app.status('No feasible point: relax the limits or change the ranges / inputs.');
            else
                app.preview_point(app.best);
                app.status(sprintf(['Design space ready (%.1f s). The best point for "%s" is selected (black square): click any map or a ' ...
                    'candidate to select another one, then press "Use this point".'], ...
                    t, app.ObjectiveDD.Items{strcmp(app.ObjectiveDD.ItemsData, app.ObjectiveDD.Value)}));
            end
        end

        function d = busy(app, msg)
            % progress bar (indeterminate) shown while an operation runs
            d = [];
            if ~isempty(app.test_dir), return; end
            try
                d = uiprogressdlg(app.UIFigure, 'Title', 'Please wait', 'Message', msg, 'Indeterminate', 'on');
                app.BusyDlg = d;
                drawnow;
            catch
            end
        end

        function set_progress(~, dlg, f)
            dlg.Value = min(1, f); drawnow limitrate;
        end

        function close_dlg(~, dlg)
            if ~isempty(dlg)
                try, if isvalid(dlg), close(dlg); end, catch, end
            end
        end

        function onLimits(app, ~)
            dlgb = app.busy('Applying the limits and redrawing the maps...'); cl = onCleanup(@() app.close_dlg(dlgb)); %#ok<NASGU>
            if ~isempty(app.S)
                app.S.opts.lim = app.read_limits();
                [app.S.ok, app.S.code] = cda_core.feasibility(app.S, app.S.opts);
                app.update_feasible_label();
                app.refresh_best();
            end
            if ~isempty(app.P), app.redesign(); end
            app.plot_all();
        end

        function onCriteria(app, ~)
            dlgb = app.busy('Updating the candidates and the maps...'); cl = onCleanup(@() app.close_dlg(dlgb)); %#ok<NASGU>
            if isempty(app.S), return; end
            app.refresh_best();
            app.plot_all();
        end

        function onFind(app, ~)
            dlgb = app.busy('Selecting the best point...'); cl = onCleanup(@() app.close_dlg(dlgb)); %#ok<NASGU>
            if isempty(app.S), app.alert('Compute the design space first.', 'No design space'); return; end
            app.refresh_best();
            if isempty(app.best)
                app.alert('No feasible point meets these criteria.', 'No candidate');
            else
                app.preview_point(app.best);
                app.status('Best point selected (black square). Press "Use this point" to design it in the Design tab.');
            end
        end

        function onSlice(app, ~)
            dlgb = app.busy('Redrawing the maps...'); cl = onCleanup(@() app.close_dlg(dlgb)); %#ok<NASGU>
            if app.FixRCB.Value || app.FixRatioCB.Value, app.refresh_best(); end
            app.plot_all();
        end

        function onCandSelect(app, e)
            try, ix = e.Indices; catch, ix = []; end
            if isempty(ix), return; end
            dlgb = app.busy('Showing the selected candidate...'); cl = onCleanup(@() app.close_dlg(dlgb)); %#ok<NASGU>
            j = ix(1, 1);
            if j <= numel(app.cand), app.preview_point(app.cand(j)); end
        end

        function onMapClick(app, e)
            which = 0;
            for w = 1:4
                if isequal(e.Source, app.map_axes(w)), which = w; end
            end
            if which == 0, return; end
            m = app.maps{which};
            if isempty(m) || isempty(m.i), return; end
            ax = app.map_axes(which);
            p = [];
            try, p = e.IntersectionPoint; catch, end
            if isempty(p), cp = get(ax, 'CurrentPoint'); p = cp(1, 1:2); end
            xl = get(ax, 'XLim'); yl = get(ax, 'YLim');
            d = ((m.x - p(1))/diff(xl)).^2 + ((m.y - p(2))/diff(yl)).^2;
            [~, j] = min(d);
            db = app.busy('Showing the selected point...'); cl = onCleanup(@() app.close_dlg(db)); %#ok<NASGU>
            app.preview_point(m.i(j));
        end

        function onDesignTyped(app, ~)
            dlgb = app.busy('Designing the point...'); cl = onCleanup(@() app.close_dlg(dlgb)); %#ok<NASGU>
            P = struct('phi', app.PhiEF.Value, 'psi', app.PsiEF.Value, 'R', app.REF.Value, 'ratio', app.RatioEF.Value);
            if ~strcmp(app.ConfigDD.Value, 'RR-D'), P.ratio = 1; end
            if ~(P.phi > 0 && P.psi > 0), app.alert('phi and psi must be > 0.', 'Input error'); return; end
            app.P = P; app.redesign(); app.plot_all();
            app.status('Design point typed in - the maps mark it with the red circle.');
        end

        function onOvEdit(app, ~)
            % Every cell shows the value of its stage; a value that differs from stage 1
            % (or from the global DF) is kept as that stage's own value.
            dlgb = app.busy('Redesigning with the stage values...'); cl = onCleanup(@() app.close_dlg(dlgb)); %#ok<NASGU>
            if isempty(app.P), return; end
            o = app.read_inputs(); d = app.OvTable.Data; n = o.n;
            nr = numel(cda_core.row_list(o));
            ovn = struct('phi', nan(1, n), 'psi', nan(1, n), 'R', nan(1, n), 'DF', nan(1, nr));
            num = @(x) app.cellnum(x);
            own = @(v, base) app.ownval(v, base);
            if strcmp(o.config, 'RS')
                v = num(d{1, 2}); if isfinite(v) && v > 0, app.P.phi = v; end
                v = num(d{1, 3}); if isfinite(v) && v > 0, app.P.psi = v; end
                v = num(d{1, 4}); if isfinite(v), app.P.R = v; end
                for k = 1:size(d, 1)
                    if k > 1
                        ovn.phi(k) = own(num(d{k, 2}), app.P.phi); ovn.psi(k) = own(num(d{k, 3}), app.P.psi); ovn.R(k) = own(num(d{k, 4}), app.P.R);
                    end
                    if 2*k - 1 <= nr, ovn.DF(2*k - 1) = own(num(d{k, 5}), o.DF); end
                    if 2*k <= nr, ovn.DF(2*k) = own(num(d{k, 6}), o.DF_S); end
                end
            else
                v = num(d{1, 2}); if isfinite(v) && v > 0, app.P.psi = v; end
                for k = 1:size(d, 1)
                    if k > 1, ovn.psi(k) = own(num(d{k, 2}), app.P.psi); end
                    ovn.DF(k) = own(num(d{k, 3}), o.DF);
                end
            end
            app.ov = ovn;
            app.redesign(); app.plot_all();
            nown = nnz(isfinite([ovn.phi ovn.psi ovn.R ovn.DF]));
            if nown == 0, app.status('All stages repeat stage 1.');
            else, app.status(sprintf('%d stage value(s) differ from stage 1 / the global DF (yellow cells).', nown)); end
        end

        function v = ownval(~, v, base)
            if ~(isfinite(v) && abs(v - base) > 1e-12), v = NaN; end
        end

        function v = cellnum(~, x)
            if isnumeric(x), v = double(x); if isempty(v), v = NaN; end, else, v = str2double(x); end
        end

        function onClearOv(app, ~)
            dlgb = app.busy('Redesigning...'); cl = onCleanup(@() app.close_dlg(dlgb)); %#ok<NASGU>
            app.ov = struct('phi', [], 'psi', [], 'R', [], 'DF', []);
            if ~isempty(app.P), app.redesign(); app.plot_all(); end
        end
    end

    % ============================ selection & design ============================
    methods (Access = private)
        function setup_slices(app)
            S = app.S; ax = S.axes;
            f = @(v) arrayfun(@(x) sprintf('%.4g', x), v, 'UniformOutput', false);
            [~, iR] = min(abs(ax.R - 0.5));
            app.setdd(app.RSliceDD, f(ax.R), 1:numel(ax.R), iR);
            app.setdd(app.RatioSliceDD, f(ax.ratio), 1:numel(ax.ratio), 1);
            app.setdd(app.PhiSliceDD, f(ax.phi), 1:numel(ax.phi), 1);
            app.setdd(app.RowDD, [{S.rows.name}, {'Highest of all rows'}], [1:numel(S.rows), 0], 1);
            oo = {'off', 'on'}; isD = strcmp(S.opts.config, 'RR-D');
            app.RatioSliceDD.Enable = oo{isD + 1}; app.AllRatiosCB.Enable = oo{isD + 1}; app.FixRatioCB.Enable = oo{isD + 1};
        end

        function [iR, ira, iphi] = slices(app)
            iR = app.RSliceDD.Value; ira = app.RatioSliceDD.Value; iphi = app.PhiSliceDD.Value;
            g = app.S.grid;
            iR = min(max(1, iR), g(2)); iphi = min(max(1, iphi), g(3)); ira = min(max(1, ira), g(4));
        end

        function c = criteria(app)
            c = struct('w', app.WeightEF.Value);
            if app.PRminCB.Value, c.PR_min = app.PRminEF.Value; end
            if app.EtaMinCB.Value, c.eta_min = app.EtaMinEF.Value; end
            if app.AmaxCB.Value, c.Aperm_max = app.AmaxEF.Value/1e4; end
            if ~isempty(app.S)
                [iR, ira] = app.slices();
                if app.FixRCB.Value, c.R_fix = app.S.axes.R(iR); end
                if app.FixRatioCB.Value && strcmp(app.S.opts.config, 'RR-D'), c.ratio_fix = app.S.axes.ratio(ira); end
            end
        end

        function refresh_best(app)
            S = app.S;
            [idx, info] = cda_core.rank(S, app.ObjectiveDD.Value, app.criteria(), 10);
            app.cand = idx; if isempty(idx), app.best = []; else, app.best = idx(1); end
            d = cell(numel(idx), 8);
            for j = 1:numel(idx)
                k = idx(j);
                d(j, :) = {j, S.phi(k), S.psi(k), S.R(k), S.ratio(k), S.PR(k), S.eta(k), 1e4*S.A_per_m(k)};
            end
            app.CandTable.Data = app.fmt_cells(d);
            app.FeasLabel.Text = sprintf('%s feasible points, %s meet the constraints.', ...
                app.thousands(nnz(S.ok)), app.thousands(info.n_candidates));
        end

        function update_feasible_label(app)
            S = app.S; nm = {'not physical', 'solidity', 'inlet Mach', 'hub/tip', 'de Haller', 'no turning', 'h/c', 'exit swirl'};
            s = {};
            for b = 0:7
                n = nnz(bitand(S.code, 2^b));
                if n > 0, s{end+1} = sprintf('%s %s', nm{b + 1}, app.thousands(n)); end %#ok<AGROW>
            end
            if isempty(s), s = {'none'}; end
            app.status(sprintf('Feasible %s of %s points. Excluded by: %s.', app.thousands(nnz(S.ok)), app.thousands(numel(S.ok)), strjoin(s, ', ')));
        end

        function preview_point(app, k)
            % select a point of the design space: shown on the maps and in "Selected point";
            % the Design tab changes only with "Use this point"
            S = app.S; app.Pv = k;
            [~, iR, iphi, ira] = ind2sub(S.grid, k);
            app.RSliceDD.Value = iR; app.PhiSliceDD.Value = iphi; app.RatioSliceDD.Value = ira;
            app.update_sel_text();
            app.plot_all();
        end

        function onUsePoint(app, ~)
            if isempty(app.S) || isempty(app.Pv)
                app.alert('Select a point first: click a map or a candidate, or press "Find the best point".', 'No point selected'); return;
            end
            dlgb = app.busy('Designing the point (all rows and stations)...'); cl = onCleanup(@() app.close_dlg(dlgb)); %#ok<NASGU>
            app.P = cda_core.point(app.S, app.Pv);
            app.redesign(); app.plot_all();
            app.Tabs.SelectedTab = app.DesignTab;
            app.status('The selected point is now the design (Design tab). Edit stages there, then send it to the off-design app.');
        end

        function redesign(app)
            if isempty(app.P), return; end
            o = app.read_inputs();
            if ~strcmp(o.config, 'RR-D'), app.P.ratio = 1; end
            o.ratio_U = app.P.ratio;
            try
                D = cda_core.design(o, app.P);
            catch err
                app.status(['Design failed: ' err.message]); return;
            end
            app.D = D; app.matfile = '';
            app.PhiEF.Value = app.P.phi; app.PsiEF.Value = app.P.psi; app.REF.Value = app.P.R; app.RatioEF.Value = app.P.ratio;
            app.fill_design();
            app.plot_geometry();
            app.update_sel_text();
        end

        function update_sel_text(app)
            % "Selected point" box: values of the selected design-space point
            if isempty(app.S) || isempty(app.Pv)
                app.SelArea.Value = {'No point selected yet.'}; return;
            end
            S = app.S; k = app.Pv; G = app.gk();
            t = {sprintf('%s = %.3f   %s = %.3f   R = %.3f', G.phi, S.phi(k), G.psi, S.psi(k), S.R(k))};
            if strcmp(S.opts.config, 'RR-D'), t{end+1} = sprintf('U2/U1 = %.3f (%s)', S.ratio(k), S.opts.rotation); end
            t = [t, {sprintf('PR = %.4f    %s = %.4f', S.PR(k), G.eta, S.eta(k)), ...
                sprintf('A1/m = %.2f cm^2 s/kg   r_m = %.1f mm', 1e4*S.A_per_m(k), 1e3*S.r_m(k)), ...
                sprintf('solidity %.2f - %.2f   inlet Mach max %.3f', S.sigma_min(k), S.sigma_max(k), S.M_max(k)), ...
                sprintf('hub/tip %.3f -> %.3f   de Haller min %.3f', S.zeta_in(k), S.zeta_out(k), S.dH_min(k)), ...
                ['Status: ' strjoin(cda_core.reason_text(S.code(k)), '; ')]}];
            if ~isempty(app.D) && app.same_point(app.D.point, cda_core.point(S, k)) && isempty(app.overrides_used())
                t{end+1} = '= the current design (Design tab).';
            else
                t{end+1} = 'Press "Use this point" to design it in detail.';
            end
            app.SelArea.Value = t;
        end

        function tf = same_point(~, a, b)
            tf = abs(a.phi - b.phi) < 1e-9 && abs(a.psi - b.psi) < 1e-9 && abs(a.R - b.R) < 1e-9 && abs(a.ratio - b.ratio) < 1e-9;
        end

        function u = overrides_used(app)
            u = find(isfinite([app.ov.phi(:); app.ov.psi(:); app.ov.R(:); app.ov.DF(:)]));
        end

        function fill_design(app)
            D = app.D; o = D.opts; G = app.gk(); n = o.n;
            [~, d] = cda_core.summary_table(D); app.SumTable.Data = app.fmt_cells(d);
            [c, d] = cda_core.row_table(D); app.RowTable.ColumnName = c; app.RowTable.Data = app.fmt_cells(d);
            [c, d] = cda_core.station_table(D); app.StaTable.ColumnName = c; app.StaTable.Data = app.fmt_cells(d);
            f = @Compressor_design_app.f4; P = D.point;
            own = [];                                            % [row col] of the cells with a stage's own value
            ev = @(fld, k, base) app.stage_value(fld, k, base);
            if strcmp(o.config, 'RS')
                d = cell(n, 6);
                for k = 1:n
                    [vp, op_] = ev('phi', k, P.phi); [vs, os] = ev('psi', k, P.psi); [vr, or_] = ev('R', k, P.R);
                    if k == 1, op_ = false; os = false; or_ = false; end
                    [vd, od] = ev('DF', 2*k - 1, o.DF);
                    d(k, 1:5) = {sprintf('%d', k), f(vp), f(vs), f(vr), f(vd)};
                    own = [own; [k 2]*op_; [k 3]*os; [k 4]*or_; [k 5]*od]; %#ok<AGROW>
                    if k < n || o.last_stator
                        [vd, od] = ev('DF', 2*k, o.DF_S); d{k, 6} = f(vd); own = [own; [k 6]*od]; %#ok<AGROW>
                    else
                        d{k, 6} = '-';
                    end
                end
                app.OvTable.ColumnName = {'Stage', G.phi, G.psi, 'R', 'DF rotor', 'DF stator'};
                app.OvTable.ColumnEditable = [false true true true true true];
            else
                d = cell(n, 3);
                for k = 1:n
                    [vs, os] = ev('psi', k, P.psi); if k == 1, os = false; end
                    [vd, od] = ev('DF', k, o.DF);
                    d(k, :) = {sprintf('%d', k), f(vs), f(vd)};
                    own = [own; [k 2]*os; [k 3]*od]; %#ok<AGROW>
                end
                app.OvTable.ColumnName = {'Rotor', G.psi, 'DF'};
                app.OvTable.ColumnEditable = [false true true];
            end
            app.OvTable.Data = d;
            if ~isempty(own), own = own(all(own > 0, 2), :); end
            try
                removeStyle(app.OvTable);
                addStyle(app.OvTable, uistyle('BackgroundColor', [0.88 0.94 1]), 'row', 1);
                if ~isempty(own), addStyle(app.OvTable, uistyle('BackgroundColor', [1 0.93 0.55], 'FontWeight', 'bold'), 'cell', own); end
            catch
            end
            w = [{['Status: ' strjoin(D.reasons, '; ')]}, D.warnings];
            if app.is_stale(), w{end+1} = 'The maps were computed with other inputs: press "Compute design space" to update them.'; end
            app.WarnArea.Value = w;
            v = app.TriRowDD.Value; if ~isnumeric(v) || isempty(v) || v > numel(D.S.rows), v = 1; end
            app.setdd(app.TriRowDD, {D.S.rows.name}, 1:numel(D.S.rows), v);
            app.refresh_vars();
        end

        function [v, isown] = stage_value(app, fld, k, base)
            % value used by stage / row k and whether it is the stage's own value
            v = base; isown = false; x = app.ov.(fld);
            if numel(x) >= k && isfinite(x(k)), v = x(k); isown = true; end
        end

        function v = ovget(app, f, k)
            v = NaN; x = app.ov.(f);
            if numel(x) >= k, v = x(k); end
        end
    end

    % ================================ maps ================================
    methods (Access = private)
        function ax = map_axes(app, which)
            A = {app.AxSigma, app.AxSizing, app.AxPareto, app.AxContour};
            ax = A{which};
        end

        function [items, ids] = quantity_list(~)
            G = Compressor_design_app.gk();
            items = {['Efficiency ' G.eta], 'Pressure ratio', 'A1/m [cm^2 s/kg]', ['Flow coefficient ' G.phi], ['Loading ' G.psi], ...
                'Reaction R', 'Speed ratio U2/U1', 'Highest solidity', 'Highest inlet Mach', 'Lowest de Haller', ...
                'Inlet hub/tip', 'Exit hub/tip', 'Blade speed U [m/s]', 'Mean radius [mm]', ['Exit swirl [' G.deg ']']};
            ids = {'eta', 'PR', 'A', 'phi', 'psi', 'R', 'ratio', 'sigma_max', 'M_max', 'dH_min', 'zeta_in', 'zeta_out', 'U', 'r_m', 'exit_swirl'};
        end

        function [v, name] = quantity(app, id, S)
            [it, ids] = app.quantity_list(); name = it{strcmp(ids, id)};
            switch id
                case 'A', v = 1e4*S.A_per_m;
                case 'r_m', v = 1e3*S.r_m;
                otherwise, v = double(S.(id));
            end
        end

        function blank_maps(app)
            for w = 1:4
                ax = app.map_axes(w); app.prep(ax);
                text(0.5, 0.5, 'Press "Compute design space"', 'Parent', ax, 'HorizontalAlignment', 'center', 'Color', [0.5 0.5 0.5]);
                set(ax, 'XLim', [0 1], 'YLim', [0 1]);
                app.maps{w} = [];
            end
        end

        function prep(~, ax)
            cla(ax); hold(ax, 'on');
            set(ax, 'XLimMode', 'auto', 'YLimMode', 'auto');
            try, colorbar(ax, 'off'); catch, end
            try, legend(ax, 'off'); catch, end
            try, disableDefaultInteractivity(ax); catch, end
            grid(ax, 'on'); box(ax, 'on');
        end

        function finish(app, ax, which)
            ch = get(ax, 'Children');
            if ~isempty(ch), set(ch, 'HitTest', 'off'); end
            % the click callback is set once when the axes are created; it is set again only if it was lost.
            % (Setting it while a zoom/pan/data-tip mode of the axes toolbar is on raises a warning, so it is not re-set every time.)
            if isempty(get(ax, 'ButtonDownFcn'))
                ws = warning('off', 'all'); set(ax, 'ButtonDownFcn', createCallbackFcn(app, @onMapClick, true)); warning(ws); %#ok<NASGU> which: from event.Source
            end
            hold(ax, 'off');
        end

        function plot_all(app, ~)
            if isempty(app.S), app.blank_maps(); return; end
            app.plot_sigma(); app.plot_sizing(); app.plot_pareto(); app.plot_contour();
        end

        function K = slice_idx(app, iR, ira)
            g = app.S.grid;
            [I1, I3] = ndgrid(1:g(1), 1:g(3));
            K = sub2ind(g, I1, iR + 0*I1, I3, ira + 0*I1);      % psi x phi
        end

        function mark(app, ax, x, y, xb, yb, xp, yp)
            % best point (star), selected point (black square), current design (red circle)
            if nargin < 7, xp = []; yp = []; end
            if ~isempty(xb), plot(ax, xb, yb, 'p', 'MarkerSize', 13, 'MarkerFaceColor', [1 0.85 0], 'MarkerEdgeColor', 'k'); end
            if ~isempty(xp), plot(ax, xp, yp, 's', 'MarkerSize', 12, 'LineWidth', 2, 'Color', 'k'); end
            if ~isempty(x), plot(ax, x, y, 'o', 'MarkerSize', 15, 'LineWidth', 2.2, 'Color', [0.85 0 0]); end
        end

        function k = pv_in(app, K)
            % selected point if it is among the indices K (else empty)
            k = [];
            if ~isempty(app.Pv) && any(K(:) == app.Pv), k = app.Pv; end
        end

        function plot_sigma(app)
            ax = app.AxSigma; app.prep(ax); S = app.S; G = app.gk();
            [iR, ira] = app.slices(); K = app.slice_idx(iR, ira); q = app.RowDD.Value;
            if q == 0, X = double(S.sigma_max(K)); rn = 'highest of all rows'; else, X = reshape(double(S.sigma(K(:), q)), size(K)); rn = S.rows(q).name; end
            Y = S.eta(K); F = S.ok(K); nl = round(app.NLinesSpin.Value);
            if app.ShowInfCB.Value && any(~F(:))
                plot(ax, X(~F), Y(~F), 'x', 'Color', [0.95 0.6 0.6], 'MarkerSize', 3);
            end
            plot(ax, X(F), Y(F), '.', 'Color', [0.72 0.72 0.72], 'MarkerSize', 5);
            Xf = X; Xf(~F) = NaN; Yf = Y; Yf(~F) = NaN;
            jp = unique(round(linspace(1, size(K, 2), min(nl, size(K, 2)))));
            ip = unique(round(linspace(1, size(K, 1), min(nl, size(K, 1)))));
            for j = jp                                           % constant phi
                plot(ax, Xf(:, j), Yf(:, j), '-', 'Color', [0 0.45 0.74], 'LineWidth', 1.4);
                f = find(isfinite(Xf(:, j)), 1, 'last');
                if ~isempty(f), text(Xf(f, j), Yf(f, j), sprintf(' %s=%.2f', G.phi, S.axes.phi(j)), 'Parent', ax, 'FontSize', 8, 'Color', [0 0.3 0.6]); end
            end
            for i = ip                                           % constant psi
                plot(ax, Xf(i, :), Yf(i, :), '-', 'Color', [0.85 0.33 0.1], 'LineWidth', 1.4);
                f = find(isfinite(Xf(i, :)), 1, 'last');
                if ~isempty(f), text(Xf(i, f), Yf(i, f), sprintf(' %s=%.2f', G.psi, S.axes.psi(i)), 'Parent', ax, 'FontSize', 8, 'Color', [0.6 0.2 0]); end
            end
            L = S.opts.lim.sigma; yl = [min(Y(F)) max(Y(F))];
            if ~isempty(yl) && all(isfinite(yl)) && yl(2) > yl(1)
                for s = L(isfinite(L)), plot(ax, [s s], yl, '--', 'Color', [0.4 0.4 0.4]); end
            end
            [xd, yd, xb, yb] = deal([]);
            if ~isempty(app.D)
                if q == 0, xd = max(app.D.S.sigma); elseif q <= numel(app.D.S.rows), xd = app.D.S.sigma(q); end
                if ~isempty(xd), yd = app.D.S.eta; end
            end
            if ~isempty(app.best) && any(K(:) == app.best)
                if q == 0, xb = S.sigma_max(app.best); else, xb = double(S.sigma(app.best, q)); end
                yb = S.eta(app.best);
            end
            [xp, yp] = deal([]); kp = app.pv_in(K);
            if ~isempty(kp)
                if q == 0, xp = S.sigma_max(kp); else, xp = double(S.sigma(kp, q)); end
                yp = S.eta(kp);
            end
            app.mark(ax, xd, yd, xb, yb, xp, yp);
            app.ttl(ax, sprintf('Design map: %s vs solidity', G.eta), sprintf('%s, R = %.3g%s', rn, S.axes.R(iR), app.ratio_txt(ira)));
            xlabel(ax, ['Solidity ' G.sig]); ylabel(ax, ['Isentropic efficiency ' G.eta]);
            if app.ShowInfCB.Value, m = true(size(F)); else, m = F; end
            app.maps{1} = struct('x', X(m), 'y', Y(m), 'i', K(m));
            app.finish(ax, 1);
        end

        function plot_sizing(app)
            ax = app.AxSizing; app.prep(ax); S = app.S; G = app.gk();
            [~, ira, iphi] = app.slices(); g = S.grid;
            % cloud: all feasible points of this speed ratio (thinned)
            [I1, I2, I3] = ndgrid(1:g(1), 1:g(2), 1:g(3));
            Kall = sub2ind(g, I1(:), I2(:), I3(:), ira + 0*I1(:));
            kc = Kall(S.ok(Kall)); kc = app.thin(kc, 15000);
            plot(ax, 1e4*S.A_per_m(kc), S.PR(kc), '.', 'Color', [0.82 0.82 0.82], 'MarkerSize', 4);
            % lines of constant R and psi at the chosen phi
            [J1, J2] = ndgrid(1:g(1), 1:g(2));
            K = sub2ind(g, J1, J2, iphi + 0*J1, ira + 0*J1);    % psi x R
            X = 1e4*S.A_per_m(K); Y = S.PR(K); F = S.ok(K);
            if app.ShowInfCB.Value, plot(ax, X(~F), Y(~F), 'x', 'Color', [0.95 0.6 0.6], 'MarkerSize', 3); end
            Xf = X; Xf(~F) = NaN; Yf = Y; Yf(~F) = NaN; nl = round(app.NLinesSpin.Value);
            for j = unique(round(linspace(1, g(2), min(nl, g(2)))))
                plot(ax, Xf(:, j), Yf(:, j), '.-', 'Color', [0.1 0.55 0.2], 'LineWidth', 1.2, 'MarkerSize', 6);
                f = find(isfinite(Xf(:, j)), 1, 'last');
                if ~isempty(f), text(Xf(f, j), Yf(f, j), sprintf(' R=%.2f', S.axes.R(j)), 'Parent', ax, 'FontSize', 8, 'Color', [0.05 0.4 0.1]); end
            end
            for i = unique(round(linspace(1, g(1), min(nl, g(1)))))
                plot(ax, Xf(i, :), Yf(i, :), '-', 'Color', [0.5 0.2 0.6], 'LineWidth', 1.1);
                f = find(isfinite(Xf(i, :)), 1, 'first');
                if ~isempty(f), text(Xf(i, f), Yf(i, f), sprintf('%s=%.2f ', G.psi, S.axes.psi(i)), 'Parent', ax, 'FontSize', 8, ...
                        'Color', [0.4 0.1 0.5], 'HorizontalAlignment', 'right'); end
            end
            if app.AmaxCB.Value
                yl = [min(S.PR(kc)) max(S.PR(kc))];
                if numel(yl) == 2 && yl(2) > yl(1), plot(ax, app.AmaxEF.Value*[1 1], yl, '--', 'Color', [0.3 0.3 0.3]); end
            end
            [xd, yd, xb, yb] = deal([]);
            if ~isempty(app.D), xd = 1e4*app.D.S.A_per_m; yd = app.D.S.PR; end
            if ~isempty(app.best) && S.ratio(app.best) == S.axes.ratio(ira), xb = 1e4*S.A_per_m(app.best); yb = S.PR(app.best); end
            [xp, yp] = deal([]); kp = app.Pv;
            if ~isempty(kp), xp = 1e4*S.A_per_m(kp); yp = S.PR(kp); end
            app.mark(ax, xd, yd, xb, yb, xp, yp);
            app.ttl(ax, 'Sizing map', sprintf('lines at %s = %.3g%s (grey: all %s)', G.phi, S.axes.phi(iphi), app.ratio_txt(ira), G.phi));
            xlabel(ax, 'Inlet area per unit mass flow A_1/m [cm^2 s/kg]'); ylabel(ax, 'Pressure ratio');
            if app.ShowInfCB.Value, m = true(size(F)); else, m = F; end
            app.maps{2} = struct('x', [X(m); 1e4*S.A_per_m(kc)], 'y', [Y(m); S.PR(kc)], 'i', [K(m); kc]);
            app.finish(ax, 2);
        end

        function plot_pareto(app)
            ax = app.AxPareto; app.prep(ax); S = app.S;
            [~, ira] = app.slices();
            m = S.ok;
            if strcmp(S.opts.config, 'RR-D') && ~app.AllRatiosCB.Value, m = m & S.ratio == S.axes.ratio(ira); end
            idx = find(m);
            if isempty(idx)
                text(0.5, 0.5, 'No feasible point', 'Parent', ax, 'HorizontalAlignment', 'center');
                app.maps{3} = []; app.finish(ax, 3); return;
            end
            fr = cda_core.pareto(S.PR, S.eta, m);
            ks = unique([app.thin(idx, 30000); fr(:)]);
            [c, cname] = app.quantity(app.ColorDD.Value, S);
            scatter(ax, S.PR(ks), S.eta(ks), 7, c(ks), 'filled');
            try, colormap(ax, parula(256)); catch, end
            try, colorbar(ax); catch, end
            plot(ax, S.PR(fr), S.eta(fr), 'k-', 'LineWidth', 1.6);
            xl = [min(S.PR(ks)) max(S.PR(ks))]; yl = [min(S.eta(ks)) max(S.eta(ks))];
            if app.PRminCB.Value, plot(ax, app.PRminEF.Value*[1 1], yl, '--', 'Color', [0.3 0.3 0.3]); end
            if app.EtaMinCB.Value, plot(ax, xl, app.EtaMinEF.Value*[1 1], '--', 'Color', [0.3 0.3 0.3]); end
            [xd, yd, xb, yb] = deal([]);
            if ~isempty(app.D), xd = app.D.S.PR; yd = app.D.S.eta; end
            if ~isempty(app.best), xb = S.PR(app.best); yb = S.eta(app.best); end
            [xp, yp] = deal([]); kp = app.Pv;
            if ~isempty(kp), xp = S.PR(kp); yp = S.eta(kp); end
            app.mark(ax, xd, yd, xb, yb, xp, yp);
            t = sprintf('colour: %s; %s feasible; black: Pareto front', cname, app.thousands(numel(idx)));
            if strcmp(S.opts.config, 'RR-D') && ~app.AllRatiosCB.Value, t = [t app.ratio_txt(ira)]; end
            app.ttl(ax, 'Pressure ratio - efficiency', t); xlabel(ax, 'Pressure ratio'); ylabel(ax, 'Isentropic efficiency');
            app.maps{3} = struct('x', S.PR(ks), 'y', S.eta(ks), 'i', ks);
            app.finish(ax, 3);
        end

        function plot_contour(app)
            ax = app.AxContour; app.prep(ax); S = app.S; G = app.gk();
            [iR, ira] = app.slices(); K = app.slice_idx(iR, ira); F = S.ok(K);
            [v, name] = app.quantity(app.ContourDD.Value, S); Z = v(K);
            if ~app.ShowInfCB.Value, Z(~F) = NaN; end
            ph = S.axes.phi; ps = S.axes.psi;
            [PH, PS] = meshgrid(ph, ps);
            done = false;
            if numel(ph) > 1 && numel(ps) > 1 && nnz(isfinite(Z)) > 3
                try
                    contourf(ax, ph, ps, Z, 14, 'LineColor', 'none'); done = true;
                    if any(F(:)) && ~all(F(:)), contour(ax, ph, ps, double(F), [0.5 0.5], 'k-', 'LineWidth', 1.3); end
                catch
                end
            end
            if ~done
                ok = isfinite(Z);
                if any(ok(:)), scatter(ax, PH(ok), PS(ok), 18, Z(ok), 'filled'); end
            end
            try, colormap(ax, parula(256)); catch, end
            try, colorbar(ax); catch, end
            [xd, yd, xb, yb] = deal([]);
            if ~isempty(app.D), xd = app.D.point.phi; yd = app.D.point.psi; end
            if ~isempty(app.best) && any(K(:) == app.best), xb = S.phi(app.best); yb = S.psi(app.best); end
            [xp, yp] = deal([]); kp = app.pv_in(K);
            if ~isempty(kp), xp = S.phi(kp); yp = S.psi(kp); end
            app.mark(ax, xd, yd, xb, yb, xp, yp);
            app.ttl(ax, sprintf('%s over %s-%s', name, G.phi, G.psi), sprintf('R = %.3g%s; black line: feasible limit', S.axes.R(iR), app.ratio_txt(ira)));
            xlabel(ax, ['Flow coefficient ' G.phi]); ylabel(ax, ['Loading coefficient ' G.psi]);
            set(ax, 'XLim', [min(ph) max(ph) + (numel(ph) == 1)], 'YLim', [min(ps) max(ps) + (numel(ps) == 1)]);
            if app.ShowInfCB.Value, m = true(size(F)); else, m = F; end
            app.maps{4} = struct('x', PH(m), 'y', PS(m), 'i', K(m));
            app.finish(ax, 4);
        end

        function t = ratio_txt(app, ira)
            t = '';
            if strcmp(app.S.opts.config, 'RR-D'), t = sprintf(', U2/U1 = %.3g', app.S.axes.ratio(ira)); end
        end

        function k = thin(~, k, nmax)
            k = k(:);
            if numel(k) > nmax, k = k(unique(round(linspace(1, numel(k), nmax)))); end
        end
    end

    % ============================== geometry ==============================
    methods (Access = private)
        function plot_geometry(app)
            app.plot_meridional(); app.plot_blades(); app.plot_triangles();
        end

        function x = row_x(app)
            % axial positions [mm]: leading / trailing edge of every row
            D = app.D; c = 1e3*D.opts.chord; nr = numel(D.S.rows);
            x = zeros(nr, 2); gap = 0.35*c; xs = 0.6*c;
            for q = 1:nr
                cx = c*max(0.3, abs(cosd(D.G.stagger(q))));
                x(q, :) = [xs, xs + cx]; xs = xs + cx + gap;
            end
        end

        function plot_meridional(app)
            ax = app.AxMerid; cla(ax); hold(ax, 'on'); set(ax, 'XLimMode', 'auto', 'YLimMode', 'auto'); grid(ax, 'on'); box(ax, 'on');
            D = app.D; S = D.S; nr = numel(S.rows); x = app.row_x(); c = 1e3*D.opts.chord;
            rt = 1e3*S.r_t; rh = 1e3*S.r_h;
            xe = [0, reshape(x', 1, []), x(end, 2) + 0.6*c];          % hub / tip polyline
            st = [1, reshape([1:nr; 2:nr + 1], 1, []), nr + 1];
            patch('Parent', ax, 'XData', [xe fliplr(xe)]', 'YData', [rh(st) zeros(size(xe))]', 'FaceColor', [0.88 0.88 0.88], 'EdgeColor', 'none');
            plot(ax, xe, rt(st), 'k-', 'LineWidth', 1.5); plot(ax, xe, rh(st), 'k-', 'LineWidth', 1.5);
            plot(ax, xe([1 end]), 1e3*S.r_m*[1 1], '-.', 'Color', [0.4 0.4 0.4]);
            for q = 1:nr
                if S.rows(q).kind == 'R'
                    col = [0.3 0.55 0.9]; if S.Urow(q) < 0, col = [0.55 0.35 0.85]; end
                else
                    col = [0.95 0.6 0.25];
                end
                patch('Parent', ax, 'XData', [x(q, 1) x(q, 2) x(q, 2) x(q, 1)]', 'YData', [rh(q) rh(q + 1) rt(q + 1) rt(q)]', ...
                    'FaceColor', col, 'EdgeColor', 'k');
                nm = S.rows(q).name; nm = [nm(1) nm(find(nm == ' ', 1) + 1:end)];
                text(mean(x(q, :)), rt(q)*1.03 + 0.5, nm, 'Parent', ax, 'HorizontalAlignment', 'center', 'FontSize', 9);
            end
            axis(ax, 'equal'); set(ax, 'XLim', [xe(1) xe(end)], 'YLim', [0 1.18*max(rt)]);
            app.ttl(ax, sprintf('Meridional section: r_m = %.1f mm, hub/tip %.3f -> %.3f, h/c %.2f -> %.2f', ...
                1e3*S.r_m, S.zeta(1), S.zeta(end), S.h_c(1), S.h_c(end)), 'rotor blue, counter-rotating rotor violet, stator orange');
            xlabel(ax, 'Axial position [mm] (chord projected with the stagger angle)'); ylabel(ax, 'Radius [mm]');
            hold(ax, 'off');
        end

        function plot_blades(app)
            ax = app.AxBlades; cla(ax); hold(ax, 'on'); set(ax, 'XLimMode', 'auto', 'YLimMode', 'auto'); grid(ax, 'on'); box(ax, 'on');
            D = app.D; S = D.S; Gm = D.G; nr = numel(S.rows); c = 1e3*D.opts.chord; x0 = app.row_x();
            s = linspace(0, 1, 41)'; tc = 0.10; ytop = -Inf; ybot = Inf; lab = zeros(nr, 1);
            th = 5*tc*(0.2969*sqrt(s) - 0.126*s - 0.3516*s.^2 + 0.2843*s.^3 - 0.1036*s.^4);   % illustrative thickness
            for q = 1:nr
                if S.rows(q).kind == 'R', sg = -sign(S.Urow(q)); col = [0.3 0.55 0.9]; if S.Urow(q) < 0, col = [0.55 0.35 0.85]; end
                else, sg = 1; col = [0.95 0.6 0.25]; end
                b = sg*(Gm.b1d(q) + (Gm.b2d(q) - Gm.b1d(q))*s);     % camber-line angle (circular arc)
                xc = cumtrapz(s, cosd(b)); yc = cumtrapz(s, sind(b));
                k = c/max(1e-9, hypot(xc(end), yc(end))); xc = xc*k; yc = yc*k;   % chord length c
                nx = -sind(b); ny = cosd(b); pitch = c/S.sigma(q);
                for j = -1:1
                    xu = x0(q, 1) + xc + th*c.*nx; yu = yc + th*c.*ny + j*pitch;
                    xl = x0(q, 1) + xc - th*c.*nx; yl = yc - th*c.*ny + j*pitch;
                    patch('Parent', ax, 'XData', [xu; flipud(xl)], 'YData', [yu; flipud(yl)], 'FaceColor', col, 'EdgeColor', 'k', 'LineWidth', 0.5);
                    ytop = max([ytop; yu; yl]); ybot = min([ybot; yu; yl]);
                end
                lab(q) = x0(q, 1);
            end
            for q = 1:nr
                text(lab(q), ytop + 0.9*c, S.rows(q).name, 'Parent', ax, 'FontSize', 8, 'VerticalAlignment', 'bottom');
                text(lab(q), ytop + 0.25*c, sprintf('%s = %.2f', char(963), S.sigma(q)), 'Parent', ax, 'FontSize', 8, 'VerticalAlignment', 'bottom');
            end
            axis(ax, 'equal'); set(ax, 'YLim', [ybot - 0.2*c, ytop + 1.6*c]);
            app.ttl(ax, 'Blade sections at the mean radius', 'metal angles, circular-arc camber, illustrative 10% thickness');
            xlabel(ax, 'Axial [mm]'); ylabel(ax, 'Tangential [mm] (positive: rotor-1 rotation)');
            hold(ax, 'off');
        end

        function plot_triangles(app, ~)
            % Velocity triangles of one row, common apex (both triangles start at the origin).
            % Rotor: C (absolute), W (relative) and U close each triangle. Stator: C only (U = 0);
            % its axial and tangential components close the triangles and the vertical line
            % between the two tips is the swirl the stator removes.
            ax = app.AxTri; cla(ax); hold(ax, 'on'); set(ax, 'XLimMode', 'auto', 'YLimMode', 'auto'); grid(ax, 'on'); box(ax, 'on');
            try, legend(ax, 'off'); catch, end
            if isempty(app.D), hold(ax, 'off'); return; end
            D = app.D; S = D.S; q = app.TriRowDD.Value; if q > numel(S.rows), q = 1; end
            Cx1 = S.Cx_st(q); Ct1 = S.Ct_st(q); Cx2 = S.Cx_st(q + 1); Ct2 = S.Ct_st(q + 1); U = S.Urow(q);
            G = app.gk(); cC = [0 0.35 0.8]; cW = [0.85 0.1 0.1]; cU = [0.1 0.6 0.2]; cg = [0.45 0.45 0.45];
            vec = @(x0, y0, x, y, col, ls) plot(ax, [x0 x], [y0 y], ls, 'Color', col, 'LineWidth', 2.2);
            lab = @(x, y, txt, col) text(x, y, txt, 'Parent', ax, 'Color', col, 'FontSize', 10, 'FontWeight', 'bold');
            xs = [0 Cx1 Cx2]; ys = [0 Ct1 Ct2];
            plot(ax, [0 max(Cx1, Cx2)], [0 0], '-', 'Color', cg, 'LineWidth', 1);              % axial component
            h = {}; lg = {};
            h{end+1} = vec(0, 0, Cx1, Ct1, cC, '-');  lg{end+1} = 'C inlet (absolute)';
            h{end+1} = vec(0, 0, Cx2, Ct2, cC, '--'); lg{end+1} = 'C exit';
            lab(Cx1, Ct1, '  C_{in}', cC); lab(Cx2, Ct2, '  C_{out}', cC);
            if S.rows(q).kind == 'R'
                h{end+1} = vec(0, 0, Cx1, Ct1 - U, cW, '-');  lg{end+1} = 'W inlet (relative)';
                h{end+1} = vec(0, 0, Cx2, Ct2 - U, cW, '--'); lg{end+1} = 'W exit';
                h{end+1} = vec(Cx1, Ct1 - U, Cx1, Ct1, cU, '-'); lg{end+1} = 'U (blade speed)';
                vec(Cx2, Ct2 - U, Cx2, Ct2, cU, '--');
                lab(Cx1, Ct1 - U, '  W_{in}', cW); lab(Cx2, Ct2 - U, '  W_{out}', cW);
                lab(max(Cx1, Cx2), (Ct1 + Ct1 - U)/2, '   U', cU);
                ys = [ys, Ct1 - U, Ct2 - U];
                t = {sprintf('%s: U = %.1f m/s', S.rows(q).name, U), sprintf('%s_{in} = %.1f%s, %s_{out} = %.1f%s, deflection %.1f%s, W_2/W_1 = %.3f', ...
                    char(946), S.b_in(q), G.deg, char(946), S.b_out(q), G.deg, S.defl(q), G.deg, S.dH(q))};
            else
                plot(ax, [Cx1 Cx1], [0 Ct1], ':', 'Color', cg, 'LineWidth', 1.3);            % tangential components
                plot(ax, [Cx2 Cx2], [0 Ct2], ':', 'Color', cg, 'LineWidth', 1.3);
                h{end+1} = plot(ax, [Cx2 Cx2]*0 + max(Cx1, Cx2), [Ct2 Ct1], '-', 'Color', [0.9 0.55 0.1], 'LineWidth', 3);
                lg{end+1} = sprintf('swirl removed %s C_%s = %.1f m/s', char(916), char(952), Ct1 - Ct2);
                lab(0.5*min(Cx1, Cx2), -0.06*max(abs(ys)) - 2, 'C_x', cg);
                t = {sprintf('%s (absolute frame, U = 0)', S.rows(q).name), sprintf('%s_{in} = %.1f%s, %s_{out} = %.1f%s, deflection %.1f%s, C_2/C_1 = %.3f', ...
                    char(945), S.b_in(q), G.deg, char(945), S.b_out(q), G.deg, S.defl(q), G.deg, S.dH(q))};
            end
            try, legend(ax, [h{:}], lg, 'Location', 'northwest'); catch, end
            dx = max(xs) - min(xs); dy = max(ys) - min(ys); pad = 0.12*max(dx, dy);
            daspect(ax, [1 1 1]);
            set(ax, 'XLim', [min(xs) - pad, max(xs) + 2.2*pad], 'YLim', [min(ys) - pad, max(ys) + pad]);
            title(ax, t, 'FontWeight', 'normal', 'FontSize', 10);
            xlabel(ax, 'Axial velocity [m/s]'); ylabel(ax, 'Tangential velocity [m/s] (positive: rotor-1 rotation)');
            hold(ax, 'off');
        end
    end

    % ============================== export ===============================
    methods (Access = private)
        function setdd(~, dd, items, data, v)
            % dropdown contents and selection
            dd.Items = items; dd.ItemsData = data; dd.Value = v;
        end

        function ok = need_design(app)
            ok = ~isempty(app.D);
            if ~ok, app.alert('Choose a design point first (Design space or Design tab).', 'No design'); end
        end

        function save_mat(app, file, D)
            % design file with the variables ticked in the Export tab
            if nargin < 3, D = app.D; end
            mat = cda_core.offdesign_struct(D);
            f = fieldnames(mat); keep = f(~ismember(f, app.VarOff));
            mat = cda_core.offdesign_struct(D, keep); %#ok<NASGU>
            save(file, '-struct', 'mat');
            app.log(sprintf('Design file saved (%d variables): %s', numel(keep), file));
        end

        function refresh_vars(app)
            % table of the variables of the design file (tick = written)
            if isempty(app.D), app.VarTable.Data = cell(0, 5); return; end
            mat = cda_core.offdesign_struct(app.D); cat = cda_core.var_catalog(app.D.opts.config);
            f = fieldnames(mat); d = cell(0, 5);
            for i = 1:size(cat, 1)
                if ~any(strcmp(f, cat{i, 1})), continue; end
                x = mat.(cat{i, 1});
                if isstruct(x), sz = 'struct'; elseif ischar(x), sz = 'text'; else, sz = sprintf('%dx%d', size(x, 1), size(x, 2)); end
                d(end+1, :) = {~any(strcmp(app.VarOff, cat{i, 1})), cat{i, 1}, cat{i, 2}, sz, cat{i, 3}}; %#ok<AGROW>
            end
            app.VarTable.Data = d;
        end

        function onVarEdit(app, ~)
            d = app.VarTable.Data; if isempty(d), return; end
            off = d(~cell2mat(d(:, 1)), 2)';
            others = app.VarOff(~ismember(app.VarOff, d(:, 2)));      % names of other configurations
            app.VarOff = [others, off];
            msg = app.var_check(app.D);
            if isempty(msg), app.status(sprintf('%d of %d variables will be written.', size(d, 1) - numel(off), size(d, 1)));
            else, app.status(msg); end
        end

        function onVarAll(app, ~)
            app.VarOff = {}; app.refresh_vars();
        end

        function onVarRequired(app, ~)
            cat = cda_core.var_catalog(app.ConfigDD.Value);
            app.VarOff = cat(~strcmp(cat(:, 3), 'required'), 1)'; app.refresh_vars();
        end

        function onVarBlading(app, ~)
            cat = cda_core.var_catalog(app.ConfigDD.Value);
            app.VarOff = cat(strcmp(cat(:, 3), 'optional: inlet state') | strcmp(cat(:, 3), 'optional: record'), 1)'; app.refresh_vars();
        end

        function msg = var_check(app, D)
            % what the off-design app will miss with the current selection ('' = fine)
            msg = '';
            if isempty(D), return; end
            mat = cda_core.offdesign_struct(D); f = fieldnames(mat);
            cat = cda_core.var_catalog(D.opts.config);
            req = cat(strcmp(cat(:, 3), 'required'), 1);
            miss = f(ismember(f, req) & ismember(f, app.VarOff));
            if ~isempty(miss)
                msg = sprintf('Required variable(s) not ticked: %s. The off-design app will refuse this file.', strjoin(miss', ', '));
                return;
            end
            st = f(strncmp(f, 'stator_', 7));
            if ~isempty(st) && any(ismember(st, app.VarOff))
                P = D.point; o = D.opts;
                if abs(P.R - 0.5) > 1e-9 || any(isfinite([o.ov.phi(:); o.ov.psi(:); o.ov.R(:)])) || strcmp(o.last_exit, 'axial')
                    msg = ['Stator blading (stator_*) not ticked: with R different from 0.5, stage-specific values or an axial exit ' ...
                           'the off-design app would mirror the rotor blading and give wrong stator angles.'];
                end
            end
        end

        function ok = confirm_vars(app, D)
            ok = true; msg = app.var_check(D);
            if isempty(msg), return; end
            a = app.confirm([msg ' Save anyway?'], 'Variables of the design file', {'Save anyway', 'Cancel'});
            ok = strcmp(a, 'Save anyway');
        end

        function onSaveMat(app, ~)
            if ~app.need_design(), return; end
            if ~app.confirm_vars(app.D), return; end
            file = app.ask_put('*.mat', [cda_core.case_name(app.D.opts, app.D.point) '.mat']);
            if isempty(file), return; end
            dlgb = app.busy('Saving the design file...'); cl = onCleanup(@() app.close_dlg(dlgb)); %#ok<NASGU>
            app.save_mat(file); app.matfile = file;
            app.status(['Saved ' file]);
        end

        function onSend(app, ~)
            if ~app.need_design(), return; end
            D = app.D;
            if ~D.ok
                a = app.confirm(sprintf('This design is outside the limits (%s). The off-design app can still run it. Send it anyway?', ...
                    strjoin(D.reasons, '; ')), 'Design outside the limits', {'Send anyway', 'Cancel'});
                if ~strcmp(a, 'Send anyway'), return; end
            end
            if ~app.confirm_vars(D), return; end
            if isempty(app.matfile) || ~exist(app.matfile, 'file')
                file = app.ask_put('*.mat', [cda_core.case_name(D.opts, D.point) '.mat']);
                if isempty(file), return; end
                db = app.busy('Saving the design file...');
                app.save_mat(file); app.matfile = file; app.close_dlg(db);
            end
            dlgb = app.busy('Opening the off-design app and loading the design...'); cl = onCleanup(@() app.close_dlg(dlgb)); %#ok<NASGU>
            typ = cda_core.offdesign_type(D.opts);
            od = app.find_offdesign();
            if isempty(od)
                try
                    od = Compressor_offdesign_app(app.Mainapp);
                catch err
                    app.alert(sprintf(['Could not open Compressor_offdesign_app (%s).\nThe design file is saved:\n%s\n' ...
                        'Open the off-design app and load it with "mat file input".'], err.message, app.matfile), 'Off-design app');
                    return;
                end
            end
            app.OffApp = od;
            if ismethod(od, 'load_design_file')
                try
                    od.load_design_file(app.matfile, typ);
                    app.status(sprintf('Sent to the off-design app as "%s": press Run there.', typ));
                    app.log(['Sent to the off-design app: ' app.matfile]);
                catch err
                    app.alert(['The off-design app could not load the design: ' err.message], 'Off-design app');
                end
            else
                app.alert(sprintf(['This version of the off-design app cannot receive designs (it needs step 27).\n' ...
                    'The design file is saved:\n%s\nChoose "%s", "mat file input" and upload it.'], app.matfile, typ), 'Off-design app');
            end
        end

        function od = find_offdesign(app)
            od = [];
            try
                if ~isempty(app.OffApp) && isvalid(app.OffApp), od = app.OffApp; return; end
            catch
            end
            try
                figs = findall(groot, 'Type', 'figure');
                for i = 1:numel(figs)
                    try
                        a = figs(i).RunningAppInstance;
                        if isa(a, 'Compressor_offdesign_app'), od = a; return; end
                    catch
                    end
                end
            catch
            end
        end

        function onExcel(app, ~)
            if ~app.need_design(), return; end
            D = app.D;
            file = app.ask_put('*.xlsx', [cda_core.case_name(D.opts, D.point) '.xlsx']);
            if isempty(file), return; end
            dlgb = app.busy('Writing the Excel file...'); cl = onCleanup(@() app.close_dlg(dlgb)); %#ok<NASGU>
            try
                if exist(file, 'file'), delete(file); end
                [c, d] = cda_core.summary_table(D); writecell([c; d], file, 'Sheet', 'Summary');
                [c, d] = cda_core.row_table(D); writecell([c; d], file, 'Sheet', 'Rows');
                [c, d] = cda_core.station_table(D); writecell([c; d], file, 'Sheet', 'Stations');
                writecell(app.inputs_cells(D.opts), file, 'Sheet', 'Inputs');
                mat = cda_core.offdesign_struct(D); f = fieldnames(mat); v = cell(numel(f), 2);
                for i = 1:numel(f)
                    x = mat.(f{i});
                    if isnumeric(x), v(i, :) = {f{i}, mat2str(x, 10)}; elseif ischar(x), v(i, :) = {f{i}, x}; else, v(i, :) = {f{i}, '(struct)'}; end
                end
                writecell([{'Variable', 'Value'}; v], file, 'Sheet', 'Off-design variables');
                if ~isempty(app.cand)
                    writecell([app.CandTable.ColumnName(:)'; app.CandTable.Data], file, 'Sheet', 'Candidates');
                end
                if ~isempty(app.list)
                    [c, d] = app.list_cells(); writecell([c; d], file, 'Sheet', 'Design list');
                end
                if app.IncludeSpaceCB.Value && ~isempty(app.S)
                    S = app.S; k = find(S.ok);
                    hd = {'phi', 'psi', 'R', 'ratio', 'PR', 'eta', 'A1/m [m^2 s/kg]', 'U [m/s]', 'r_m [m]', 'sigma min', 'sigma max', ...
                          'M max', 'de Haller min', 'hub/tip in', 'hub/tip out', 'exit swirl [deg]'};
                    M = [S.phi(k), S.psi(k), S.R(k), S.ratio(k), S.PR(k), S.eta(k), S.A_per_m(k), S.U(k), S.r_m(k), ...
                         S.sigma_min(k), S.sigma_max(k), S.M_max(k), S.dH_min(k), S.zeta_in(k), S.zeta_out(k), S.exit_swirl(k)];
                    writecell(hd, file, 'Sheet', 'Design space');
                    writematrix(M, file, 'Sheet', 'Design space', 'Range', 'A2');
                end
                app.log(['Excel file written: ' file]); app.status(['Saved ' file]);
            catch err
                app.alert(['Excel export failed: ' err.message], 'Export');
            end
        end

        function C = inputs_cells(~, o)
            C = {'Configuration', cda_core.offdesign_type(o); 'Stages / rotors', o.n; 'Last stator', double(o.last_stator); ...
                 'Last stator exit', o.last_exit; 'Even-rotor rotation', o.rotation; 'Speed ratio (design)', o.ratio_U; ...
                 'Mass flow [kg/s]', o.m_dot; 'Shaft speed [rpm]', o.N_rpm; 'Tt1 [K]', o.Tt1; 'pt1 [Pa]', o.Pt1; 'Mr1', o.Mr1; ...
                 'DF rotors', o.DF; 'DF stators', o.DF_S; 'Chord [m]', o.chord; 'Loss model rotors', o.loss_R; ...
                 'Loss model stators', o.loss_S; 'gamma', o.gamma; 'R gas [J/kgK]', o.Rg; ...
                 'Limits: solidity', mat2str(o.lim.sigma); 'Limits: inlet Mach max', o.lim.M_max; 'Limits: de Haller min', o.lim.dH_min; ...
                 'Limits: hub/tip', mat2str(o.lim.zeta); 'Limits: h/c min', o.lim.h_c_min; 'Limits: exit swirl max', o.lim.exit_swirl_max; ...
                 'Overrides phi', mat2str(o.ov.phi, 4); 'Overrides psi', mat2str(o.ov.psi, 4); 'Overrides R', mat2str(o.ov.R, 4); ...
                 'Overrides DF (per row)', mat2str(o.ov.DF, 4); 'Tool', 'Compressor_design_app + cda_core'};
            C = [{'Input', 'Value'}; C];
        end

        function onPng(app, ~)
            if isempty(app.S) && isempty(app.D), app.alert('Nothing to save yet.', 'Plots'); return; end
            folder = app.ask_dir();
            if isempty(folder), return; end
            if isempty(app.D), base = 'design'; else, base = cda_core.case_name(app.D.opts, app.D.point); end
            dlgb = app.busy('Saving the plots (300 dpi)...'); cl = onCleanup(@() app.close_dlg(dlgb)); %#ok<NASGU>
            A = {app.AxSigma, 'map_eta_sigma'; app.AxSizing, 'map_sizing'; app.AxPareto, 'map_PR_eta'; app.AxContour, 'map_contour'; ...
                 app.AxMerid, 'meridional'; app.AxBlades, 'blades'; app.AxTri, 'triangles'};
            n = 0;
            for i = 1:size(A, 1)
                if isempty(get(A{i, 1}, 'Children')), continue; end
                f = fullfile(folder, sprintf('%s_%s.png', base, A{i, 2}));
                try, exportgraphics(A{i, 1}, f, 'Resolution', 300); n = n + 1; catch err, app.log(['PNG failed: ' err.message]); end
            end
            app.status(sprintf('%d plots saved in %s', n, folder)); app.log(sprintf('%d plots saved in %s', n, folder));
        end

        function onSaveProject(app, ~)
            file = app.ask_put('*.mat', 'cda_project.mat');
            if isempty(file), return; end
            dlgb = app.busy('Saving the project...'); cl = onCleanup(@() app.close_dlg(dlgb)); %#ok<NASGU>
            proj = struct('version', 1, 'o', app.read_inputs(), 'P', app.P, 'ov', app.ov, ...
                'objective', app.ObjectiveDD.Value, 'created', datestr(now)); %#ok<DATST>
            proj.list = app.list;
            if app.ProjSpaceCB.Value && ~isempty(app.S), proj.S = app.S; end
            try
                save(file, 'proj', '-v7.3');
            catch
                save(file, 'proj');
            end
            app.log(['Project saved: ' file]); app.status(['Project saved: ' file]);
        end

        function onOpenProject(app, ~)
            file = app.ask_get('*.mat');
            if isempty(file), return; end
            dlgb = app.busy('Opening the project...'); cl = onCleanup(@() app.close_dlg(dlgb)); %#ok<NASGU>
            try
                L = load(file); proj = L.proj;
            catch
                app.alert('This file is not a CDA project (no variable "proj").', 'Open project'); return;
            end
            app.ov = proj.ov; app.set_inputs(proj.o); app.P = proj.P;
            if isfield(proj, 'objective'), app.ObjectiveDD.Value = proj.objective; end
            if isfield(proj, 'list'), app.list = proj.list; app.refresh_list(); end
            app.S = [];
            if isfield(proj, 'S'), app.S = proj.S; app.setup_slices(); app.update_feasible_label(); app.refresh_best(); end
            app.update_points_label();
            if ~isempty(app.P), app.redesign(); end
            app.plot_all();
            app.log(['Project opened: ' file]);
        end

        % ---------------------------- design list ----------------------------
        function [c, d] = list_cells(app)
            G = app.gk();
            c = {'#', 'Name', 'Configuration', 'n', G.phi, G.psi, 'R', 'U2/U1', 'PR', G.eta, 'A1/m [cm^2 s/kg]', 'r_m [mm]', 'U [m/s]', 'Blades', 'Status'};
            d = cell(numel(app.list), numel(c));
            for i = 1:numel(app.list)
                D = app.list{i}; P = D.point; S = D.S;
                d(i, :) = {i, app.cmp_name(i), cda_core.offdesign_type(D.opts), D.opts.n, P.phi, P.psi, P.R, P.ratio, ...
                    S.PR, S.eta, 1e4*S.A_per_m, 1e3*S.r_m, S.U, sum(D.n_blades), strjoin(D.reasons, '; ')};
            end
        end

        function refresh_list(app)
            [c, d] = app.list_cells();
            app.ListTable.ColumnName = c; app.ListTable.Data = app.fmt_cells(d);
            app.refresh_compare();
        end

        function onListAdd(app, ~)
            if ~app.need_design(), return; end
            app.add_to_list(app.D, '');
            app.log(sprintf('Added to the design list (%d designs).', numel(app.list)));
            app.status(sprintf('Design added to the list and to the Compare tab (%d designs).', numel(app.list)));
        end

        function onListSelect(app, e)
            try, ix = e.Indices; catch, ix = []; end
            if ~isempty(ix), app.listsel = ix(1, 1); end
        end

        function onListRemove(app, ~)
            if isempty(app.listsel) || app.listsel > numel(app.list), return; end
            app.list(app.listsel) = []; app.listsel = []; app.refresh_list();
        end

        function onListLoad(app, ~)
            if isempty(app.listsel) || app.listsel > numel(app.list), app.alert('Click a design in the list first.', 'Design list'); return; end
            dlgb = app.busy('Loading the design...'); cl = onCleanup(@() app.close_dlg(dlgb)); %#ok<NASGU>
            D = app.list{app.listsel};
            app.ov = D.opts.ov; app.set_inputs(D.opts); app.P = D.point;
            app.update_points_label(); app.redesign(); app.plot_all();
            if app.is_stale(), app.status('Design loaded; its inputs differ from the design space shown in the maps.'); end
        end

        function onListSaveAll(app, ~)
            if isempty(app.list), app.alert('The design list is empty.', 'Design list'); return; end
            folder = app.ask_dir();
            if isempty(folder), return; end
            used = {};
            dlgb = app.busy('Saving the design files...'); cl = onCleanup(@() app.close_dlg(dlgb)); %#ok<NASGU>
            for i = 1:numel(app.list)
                D = app.list{i}; nm = cda_core.case_name(D.opts, D.point);
                if any(strcmp(used, nm)), nm = sprintf('%s_%d', nm, i); end
                used{end+1} = nm; %#ok<AGROW>
                app.save_mat(fullfile(folder, [nm '.mat']), D);
            end
            app.status(sprintf('%d design files saved in %s', numel(app.list), folder));
        end
    end

    % ============================== compare ===============================
    methods (Access = private)
        function add_to_list(app, D, nm)
            % append a design to the list (shared by the Export and Compare tabs)
            if isempty(nm), nm = cda_core.case_name(D.opts, D.point); end
            used = cellfun(@(x) app.item_name(x), app.list, 'UniformOutput', false);
            base = nm; k = 1;
            while any(strcmp(used, nm)), k = k + 1; nm = sprintf('%s #%d', base, k); end
            D.cmp_name = nm; D.cmp_show = true;
            app.list{end+1} = D; app.refresh_list();
        end

        function ttl(~, ax, l1, l2, interp)
            % two-line plot title (keeps neighbouring titles apart)
            if nargin < 5, interp = 'tex'; end
            title(ax, {l1, l2}, 'FontWeight', 'normal', 'FontSize', 10, 'Interpreter', interp);
        end

        function flat_ylim(~, ax)
            % a y axis whose data are (almost) constant gets a +-5 % range instead of 1e-12 ticks
            y = [];
            for c = reshape(get(ax, 'Children'), 1, [])
                try, y = [y, reshape(get(c, 'YData'), 1, [])]; catch, end %#ok<AGROW>
            end
            y = y(isfinite(y)); if isempty(y), return; end
            r = max(y) - min(y); m = mean(y);
            if r <= 1e-6*max(1, abs(m))
                d = max(0.05*abs(m), 0.05); set(ax, 'YLim', [m - d, m + d]);
            end
        end

        function nm = item_name(~, D)
            if isfield(D, 'cmp_name') && ~isempty(D.cmp_name), nm = D.cmp_name; else, nm = cda_core.case_name(D.opts, D.point); end
        end

        function nm = cmp_name(app, i)
            nm = app.item_name(app.list{i});
        end

        function tf = cmp_shown(app, i)
            D = app.list{i}; tf = ~isfield(D, 'cmp_show') || isempty(D.cmp_show) || logical(D.cmp_show);
        end

        function C = cmp_colors(~, n)
            P = [0 0.447 0.741; 0.850 0.325 0.098; 0.466 0.674 0.188; 0.494 0.184 0.556; 0.929 0.694 0.125; ...
                 0.301 0.745 0.933; 0.635 0.078 0.184; 0.15 0.15 0.15; 0.55 0.55 0.55; 0.75 0.45 0.0];
            C = P(mod((1:max(n, 1)) - 1, size(P, 1)) + 1, :);
        end

        function [items, ids] = cmp_row_list(~)
            G = Compressor_design_app.gk();
            items = {['Solidity ' G.sig], 'de Haller ratio (W2/W1, C2/C1)', 'Inlet Mach number', ['Loss coefficient ' char(969)], ...
                     'Diffusion factor DF', ['Flow deflection [' G.deg ']'], ['Inlet flow angle [' G.deg ']'], ['Exit flow angle [' G.deg ']'], ...
                     ['Inlet metal angle [' G.deg ']'], ['Exit metal angle [' G.deg ']'], ['Stagger angle [' G.deg ']'], ...
                     ['Incidence [' G.deg ']'], ['Deviation [' G.deg ']'], 'Row total-pressure ratio', 'Number of blades', 'Blade h/c (row exit)'};
            ids = {'sigma', 'dH', 'M_in', 'omega', 'DF', 'defl', 'b_in', 'b_out', 'b1d', 'b2d', 'stagger', 'inc', 'dev', 'PRrow', 'blades', 'h_c'};
        end

        function [items, ids] = cmp_sta_list(~)
            G = Compressor_design_app.gk();
            items = {'Pressure ratio pt/pt1', ['Efficiency ' G.eta ' (inlet to station)'], 'Total-temperature ratio Tt/Tt1', ...
                     ['Absolute flow angle (swirl) [' G.deg ']'], 'Axial velocity Cx [m/s]', 'Static pressure [kPa]', 'Static temperature [K]', ...
                     ['Hub/tip ratio ' G.zeta], 'Blade height [mm]', 'Annulus area [cm^2]'};
            ids = {'PR', 'eta', 'TR', 'swirl', 'Cx', 'p', 'T', 'zeta', 'h', 'A'};
        end

        function [v, kind] = cmp_row_val(~, D, id)
            S = D.S; G = D.G; nr = numel(S.rows); kind = [S.rows.kind];
            switch id
                case {'b1d', 'b2d', 'stagger', 'inc', 'dev'}, v = G.(id);
                case 'blades', v = D.n_blades;
                case 'h_c', v = S.h_c(2:end);
                case 'PRrow', pin = [D.opts.Pt1, S.Pt_out(1:end-1)]; v = S.Pt_out./pin;
                otherwise, v = S.(id);
            end
            v = double(v(:)'); v = v(1:min(nr, numel(v)));
        end

        function v = cmp_sta_val(~, D, id)
            S = D.S; o = D.opts; g = o.gamma;
            pt = [o.Pt1, S.Pt_out]; Tt = [o.Tt1, S.Tt_out];
            switch id
                case 'PR', v = pt/o.Pt1;
                case 'TR', v = Tt/o.Tt1;
                case 'eta', pr = pt/o.Pt1; tr = Tt/o.Tt1; v = (pr.^((g - 1)/g) - 1)./(tr - 1); v(abs(tr - 1) < 1e-9) = NaN;
                case 'swirl', v = atand(S.Ct_st./S.Cx_st);
                case 'Cx', v = S.Cx_st;
                case 'p', v = S.P_st/1e3;
                case 'T', v = S.T_st;
                case 'zeta', v = S.zeta;
                case 'h', v = 1e3*S.h;
                case 'A', v = 1e4*S.A;
            end
            v = double(v(:)');
        end

        function ex = cmp_eta_x(~, D)
            % efficiency without recovery of the exit swirl (total pressure of the axial velocity at the exit)
            S = D.S; o = D.opts; g = o.gamma; cp = g*o.Rg/(g - 1);
            T = S.T_st(end); p = S.P_st(end); Cx = S.Cx_st(end);
            ptx = p*((T + Cx^2/(2*cp))/T)^(g/(g - 1));
            ex = ((ptx/o.Pt1)^((g - 1)/g) - 1)/(S.TR - 1);
        end

        function x = cmp_row_x(~, D)
            % axial leading / trailing edges [mm] of every row (as in the Geometry tab)
            c = 1e3*D.opts.chord; nr = numel(D.S.rows); x = zeros(nr, 2); gap = 0.35*c; xs = 0.6*c;
            for q = 1:nr
                cx = c*max(0.3, abs(cosd(D.G.stagger(q)))); x(q, :) = [xs, xs + cx]; xs = xs + cx + gap;
            end
        end

        function refresh_compare(app)
            n = numel(app.list); d = cell(n, 5);
            for i = 1:n
                D = app.list{i};
                d(i, :) = {app.cmp_shown(i), app.cmp_name(i), cda_core.offdesign_type(D.opts), sprintf('%.4f', D.S.PR), sprintf('%.4f', D.S.eta)};
            end
            d(:, 3) = strrep(strrep(strrep(d(:, 3), 'Rotor-Stator', 'RS'), 'Rotor-Rotor same shaft', 'RR-S'), 'Rotor-Rotor different shaft', 'RR-D');
            app.CmpTable.Data = d;
            % colour of every design in its name cell
            try
                removeStyle(app.CmpTable);
                C = app.cmp_colors(n);
                for i = 1:n
                    addStyle(app.CmpTable, uistyle('BackgroundColor', 0.55 + 0.45*C(i, :), 'FontWeight', 'bold'), 'cell', [i 2]);
                end
            catch
            end
            nr = 1;
            for i = 1:n, nr = max(nr, numel(app.list{i}.S.rows)); end
            v = app.CmpTriDD.Value; if isempty(v) || v > nr, v = 1; end
            app.setdd(app.CmpTriDD, arrayfun(@(k) sprintf('Row %d', k), 1:nr, 'UniformOutput', false), 1:nr, v);
            app.plot_compare();
        end

        function onCmpEdit(app, e)
            try, ix = e.Indices; catch, ix = []; end
            d = app.CmpTable.Data;
            if isempty(ix), rows = 1:size(d, 1); else, rows = ix(1); end
            for i = rows
                if i > numel(app.list), continue; end
                D = app.list{i}; D.cmp_show = logical(d{i, 1});
                nm = strtrim(char(d{i, 2})); if ~isempty(nm), D.cmp_name = nm; end
                app.list{i} = D;
            end
            app.refresh_list();
        end

        function onCmpSelect(app, e)
            try, ix = e.Indices; catch, ix = []; end
            if ~isempty(ix), app.cmpsel = ix(1, 1); app.listsel = ix(1, 1); end
        end

        function onCmpRemove(app, ~)
            if isempty(app.cmpsel) || app.cmpsel > numel(app.list), app.alert('Click a design in the table first.', 'Compare'); return; end
            app.list(app.cmpsel) = []; app.cmpsel = []; app.listsel = []; app.refresh_list();
        end

        function onCmpClear(app, ~)
            if isempty(app.list), return; end
            if ~strcmp(app.confirm(sprintf('Remove all %d designs from the list?', numel(app.list)), 'Compare', {'Remove all', 'Cancel'}), 'Remove all'), return; end
            app.list = {}; app.cmpsel = []; app.listsel = []; app.refresh_list();
        end

        function onCmpFiles(app, ~)
            if ~isempty(app.test_dir)
                ff = dir(fullfile(app.test_dir, 'cmp_*.mat')); files = fullfile(app.test_dir, {ff.name});
            else
                [f, p] = uigetfile({'*.mat', 'Design or project files (*.mat)'}, 'Add designs to the comparison', 'MultiSelect', 'on');
                figure(app.UIFigure);
                if isequal(f, 0), return; end
                if ischar(f), f = {f}; end
                files = fullfile(p, f);
            end
            dlgb = app.busy('Adding the designs...'); cl = onCleanup(@() app.close_dlg(dlgb)); %#ok<NASGU>
            nadd = 0; msg = {};
            for j = 1:numel(files)
                [~, base] = fileparts(files{j});
                try
                    L = load(files{j});
                catch err
                    msg{end+1} = sprintf('%s: not readable (%s)', base, err.message); continue; %#ok<AGROW>
                end
                if isfield(L, 'proj') && isfield(L.proj, 'list') && ~isempty(L.proj.list)
                    for i = 1:numel(L.proj.list), app.add_to_list(L.proj.list{i}, ''); nadd = nadd + 1; end
                elseif isfield(L, 'design_info')
                    [D, note] = app.rebuild(L);
                    if isempty(D), msg{end+1} = sprintf('%s: %s', base, note); continue; end %#ok<AGROW>
                    nm = base; if isfield(L, 'case_name'), nm = L.case_name; end
                    app.add_to_list(D, nm); nadd = nadd + 1;
                    if ~isempty(note), msg{end+1} = sprintf('%s: %s', base, note); end %#ok<AGROW>
                else
                    msg{end+1} = sprintf(['%s: no design record. Only design files written by this app (variable design_info) ' ...
                        'and project files can be compared.'], base); %#ok<AGROW>
                end
            end
            app.status(sprintf('%d design(s) added to the comparison.', nadd));
            for k = 1:numel(msg), app.log(msg{k}); end
            if ~isempty(msg), app.alert(strjoin(msg, newline), 'Compare'); end
            app.Tabs.SelectedTab = app.CompareTab;
        end

        function [D, note] = rebuild(~, L)
            % design of a design file, rebuilt from its design record
            D = []; note = '';
            di = L.design_info;
            try
                o = cda_core.defaults(di.config);
                fl = {'n', 'N_rpm', 'DF', 'DF_S', 'Mr1', 'loss_R', 'loss_S', 'rotation', 'last_stator'};
                for k = 1:numel(fl), if isfield(di, fl{k}), o.(fl{k}) = di.(fl{k}); end, end
                fl = {'m_dot', 'chord', 'Tt1', 'Pt1'};
                for k = 1:numel(fl), if isfield(L, fl{k}), o.(fl{k}) = L.(fl{k}); end, end
                o.ratio_U = di.ratio;
                D = cda_core.design(o, struct('phi', di.phi, 'psi', di.psi, 'R', di.R, 'ratio', di.ratio));
                if isfield(di, 'PR') && abs(D.S.PR - di.PR) > 1e-4*di.PR
                    note = sprintf(['rebuilt pressure ratio %.4f differs from the file (%.4f): per-stage values typed in the ' ...
                        'Design tab are not stored in a design file; use a project file to keep them.'], D.S.PR, di.PR);
                end
            catch err
                D = []; note = ['could not be rebuilt: ' err.message];
            end
        end

        function plot_compare(app, ~)
            A = {app.AxCmpMap, app.AxCmpSize, app.AxCmpMerid, app.AxCmpRow, app.AxCmpSta, app.AxCmpTri};
            for k = 1:numel(A)
                ax = A{k}; cla(ax); try, legend(ax, 'off'); catch, end
                hold(ax, 'on'); set(ax, 'XLimMode', 'auto', 'YLimMode', 'auto'); grid(ax, 'on'); box(ax, 'on');
                try, daspect(ax, 'auto'); catch, end
            end
            G = app.gk(); n = numel(app.list); C = app.cmp_colors(n);
            idx = []; for i = 1:n, if app.cmp_shown(i), idx(end+1) = i; end, end %#ok<AGROW>
            if isempty(idx)
                app.ttl(app.AxCmpMap, 'No designs to compare yet', 'press "Add current design" or "Add files (.mat)..."', 'none');
                app.CmpSumTable.ColumnName = {'Quantity'}; app.CmpSumTable.Data = cell(0, 1);
                for k = 1:numel(A), hold(A{k}, 'off'); end
                return;
            end
            rowid = app.CmpRowDD.Value; staid = app.CmpStaDD.Value; tq = app.CmpTriDD.Value;
            [ri, rd] = app.cmp_row_list(); rlab = ri{strcmp(rd, rowid)};
            [si, sd] = app.cmp_sta_list(); slab = si{strcmp(sd, staid)};
            hl = cell(1, 0); nl = cell(1, 0); maxr = 1; nmax = 1; xs = []; ys = [];
            for i = idx
                D = app.list{i}; S = D.S; c = C(i, :); nm = app.cmp_name(i);
                ex = app.cmp_eta_x(D);
                % (a) pressure ratio - efficiency (filled: total-to-total, open: exit swirl not recovered)
                plot(app.AxCmpMap, [S.eta ex], [S.PR S.PR], ':', 'Color', c, 'LineWidth', 1);
                h = plot(app.AxCmpMap, S.eta, S.PR, 'o', 'MarkerSize', 9, 'MarkerFaceColor', c, 'MarkerEdgeColor', 'k');
                plot(app.AxCmpMap, ex, S.PR, 'o', 'MarkerSize', 8, 'MarkerEdgeColor', c, 'LineWidth', 1.5);
                hl{end+1} = h; nl{end+1} = nm; %#ok<AGROW>
                % (b) size
                plot(app.AxCmpSize, 1e4*S.A_per_m, S.PR, 'o', 'MarkerSize', 9, 'MarkerFaceColor', c, 'MarkerEdgeColor', 'k');
                text(1e4*S.A_per_m, S.PR, ['  ' nm], 'Parent', app.AxCmpSize, 'FontSize', 8, 'Color', c, 'Interpreter', 'none');
                % (c) annulus
                x = app.cmp_row_x(D); nr = numel(S.rows); cc = 1e3*D.opts.chord;
                xe = [0, reshape(x', 1, []), x(end, 2) + 0.6*cc];
                st = [1, reshape([1:nr; 2:nr + 1], 1, []), nr + 1];
                plot(app.AxCmpMerid, xe, 1e3*S.r_t(st), '-', 'Color', c, 'LineWidth', 1.8);
                plot(app.AxCmpMerid, xe, 1e3*S.r_h(st), '-', 'Color', c, 'LineWidth', 1.8);
                plot(app.AxCmpMerid, xe([1 end]), 1e3*S.r_m*[1 1], '--', 'Color', c, 'LineWidth', 0.8);
                % (d) per row
                [v, kind] = app.cmp_row_val(D, rowid); q = 1:numel(v); maxr = max(maxr, numel(v));
                plot(app.AxCmpRow, q, v, '-', 'Color', c, 'LineWidth', 1.2);
                r = kind(q) == 'R';
                plot(app.AxCmpRow, q(r), v(r), 'o', 'MarkerSize', 7, 'MarkerFaceColor', c, 'MarkerEdgeColor', 'k');
                plot(app.AxCmpRow, q(~r), v(~r), 's', 'MarkerSize', 7, 'MarkerFaceColor', c, 'MarkerEdgeColor', 'k');
                % (e) per station
                v = app.cmp_sta_val(D, staid); q = 1:numel(v); nmax = max(nmax, numel(v));
                plot(app.AxCmpSta, q, v, '-o', 'Color', c, 'LineWidth', 1.4, 'MarkerSize', 5, 'MarkerFaceColor', c);
                % (f) velocity triangles of row tq (common apex): C thick, W thin; inlet solid, exit dashed
                if tq <= nr
                    Cx1 = S.Cx_st(tq); Ct1 = S.Ct_st(tq); Cx2 = S.Cx_st(tq + 1); Ct2 = S.Ct_st(tq + 1); U = S.Urow(tq);
                    plot(app.AxCmpTri, [0 Cx1], [0 Ct1], '-', 'Color', c, 'LineWidth', 2.4);
                    plot(app.AxCmpTri, [0 Cx2], [0 Ct2], '--', 'Color', c, 'LineWidth', 2.4);
                    xs = [xs 0 Cx1 Cx2]; ys = [ys 0 Ct1 Ct2]; %#ok<AGROW>
                    if S.rows(tq).kind == 'R'
                        plot(app.AxCmpTri, [0 Cx1], [0 Ct1 - U], '-', 'Color', c, 'LineWidth', 1);
                        plot(app.AxCmpTri, [0 Cx2], [0 Ct2 - U], '--', 'Color', c, 'LineWidth', 1);
                        plot(app.AxCmpTri, [Cx1 Cx1], [Ct1 - U, Ct1], ':', 'Color', c, 'LineWidth', 1);
                        ys = [ys, Ct1 - U, Ct2 - U]; %#ok<AGROW>
                    end
                    text(Cx1, Ct1, ['  ' S.rows(tq).name], 'Parent', app.AxCmpTri, 'FontSize', 8, 'Color', c, 'Interpreter', 'none');
                end
            end
            ax = app.AxCmpMap;
            xlabel(ax, ['Isentropic efficiency ' G.eta]); ylabel(ax, ['Pressure ratio ' G.pi]);
            app.ttl(ax, 'Design point', 'filled: total-to-total; open: exit swirl lost', 'none');
            try, legend(ax, [hl{:}], nl, 'Location', 'best', 'Interpreter', 'none', 'FontSize', 8); catch, end
            xlabel(app.AxCmpSize, 'Inlet area per unit mass flow A1/m [cm^2 s/kg]'); ylabel(app.AxCmpSize, ['Pressure ratio ' G.pi]);
            app.ttl(app.AxCmpSize, 'Size', 'pressure ratio vs inlet area per mass flow', 'none');
            xlabel(app.AxCmpMerid, 'Axial position [mm]'); ylabel(app.AxCmpMerid, 'Radius [mm]');
            app.ttl(app.AxCmpMerid, 'Annulus', 'tip and hub (solid), mean radius (dashed)', 'none');
            yl = get(app.AxCmpMerid, 'YLim'); set(app.AxCmpMerid, 'YLim', [0 yl(2)]);
            xlabel(app.AxCmpRow, 'Blade row (1 = rotor 1)'); ylabel(app.AxCmpRow, rlab);
            set(app.AxCmpRow, 'XTick', 1:maxr, 'XLim', [0.5 maxr + 0.5]);
            app.flat_ylim(app.AxCmpRow); app.flat_ylim(app.AxCmpSta);
            app.ttl(app.AxCmpRow, [rlab ' of every row'], 'circle: rotor, square: stator', 'none');
            xlabel(app.AxCmpSta, 'Station (1 = inlet; k+1 = exit of row k)'); ylabel(app.AxCmpSta, slab);
            set(app.AxCmpSta, 'XTick', 1:nmax, 'XLim', [0.75 nmax + 0.25]);
            app.ttl(app.AxCmpSta, slab, 'through the machine', 'none');
            ax = app.AxCmpTri;
            if ~isempty(xs)
                dx = max(xs) - min(xs); dy = max(ys) - min(ys); pad = 0.08*max([dx dy 1]);
                daspect(ax, [1 1 1]); set(ax, 'XLim', [min(xs) - pad, max(xs) + 3*pad], 'YLim', [min(ys) - pad, max(ys) + pad]);
            end
            xlabel(ax, 'Axial velocity [m/s]'); ylabel(ax, 'Tangential velocity [m/s]');
            app.ttl(ax, sprintf('Velocity triangles of row %d', tq), 'C thick, W thin; inlet solid, exit dashed', 'none');
            for k = 1:numel(A), hold(A{k}, 'off'); end
            app.cmp_table(idx);
        end

        function [cols, data] = cmp_table(app, idx)
            % comparison table: one column per shown design
            G = app.gk();
            q = {'Configuration'; 'Stages / rotors'; G.phi; G.psi; 'R'; 'U2/U1'; ['Pressure ratio ' G.pi]; ...
                 ['Efficiency ' G.eta ' (total-to-total)']; [G.eta ' without exit-swirl recovery']; ['Exit swirl angle [' G.deg ']']; ...
                 'Power [kW]'; 'Blade speed U [m/s]'; 'Mean radius [mm]'; 'A1/m [cm^2 s/kg]'; 'Hub/tip inlet / exit'; ...
                 'Blade h/c min'; ['Solidity ' G.sig ' min / max']; 'de Haller min'; 'Inlet Mach max'; 'Blades (total)'; ...
                 'Rows'; 'Feasible (limits)'; 'Warnings'};
            data = q; cols = {'Quantity'};
            for i = idx
                D = app.list{i}; S = D.S; P = D.point; o = D.opts;
                rr = '-'; if strcmp(o.config, 'RR-D'), rr = sprintf('%.3g', P.ratio); end
                rws = strjoin(arrayfun(@(r) r.name, S.rows, 'UniformOutput', false), ', ');
                okt = 'yes'; if ~D.ok, okt = ['no: ' strjoin(D.reasons, '; ')]; end
                col = {cda_core.offdesign_type(o); sprintf('%d', o.n); sprintf('%.4g', P.phi); sprintf('%.4g', P.psi); sprintf('%.4g', P.R); rr; ...
                       sprintf('%.4f', S.PR); sprintf('%.4f', S.eta); sprintf('%.4f', app.cmp_eta_x(D)); sprintf('%.1f', S.exit_swirl); ...
                       sprintf('%.2f', S.power/1e3); sprintf('%.1f', S.U); sprintf('%.2f', 1e3*S.r_m); sprintf('%.2f', 1e4*S.A_per_m); ...
                       sprintf('%.3f / %.3f', S.zeta(1), S.zeta(end)); sprintf('%.2f', min(S.h_c)); sprintf('%.2f / %.2f', min(S.sigma), max(S.sigma)); ...
                       sprintf('%.3f', min(S.dH)); sprintf('%.3f', max(S.M_in)); sprintf('%d', sum(D.n_blades)); rws; okt; sprintf('%d', numel(D.warnings))};
                data = [data, col]; cols{end+1} = app.cmp_name(i); %#ok<AGROW>
            end
            app.CmpSumTable.ColumnName = cols; app.CmpSumTable.Data = data;
        end

        function onCmpPng(app, ~)
            if isempty(app.list), app.alert('The comparison is empty.', 'Compare'); return; end
            folder = app.ask_dir(); if isempty(folder), return; end
            dlgb = app.busy('Saving the comparison plots (300 dpi)...'); cl = onCleanup(@() app.close_dlg(dlgb)); %#ok<NASGU>
            A = {app.AxCmpMap, 'compare_PR_eta'; app.AxCmpSize, 'compare_size'; app.AxCmpMerid, 'compare_annulus'; ...
                 app.AxCmpRow, ['compare_rows_' app.CmpRowDD.Value]; app.AxCmpSta, ['compare_stations_' app.CmpStaDD.Value]; ...
                 app.AxCmpTri, sprintf('compare_triangles_row%d', app.CmpTriDD.Value)};
            n = 0;
            for i = 1:size(A, 1)
                try, exportgraphics(A{i, 1}, fullfile(folder, [A{i, 2} '.png']), 'Resolution', 300); n = n + 1; catch err, app.log(['PNG failed: ' err.message]); end
            end
            app.status(sprintf('%d comparison plots saved in %s', n, folder)); app.log(sprintf('%d comparison plots saved in %s', n, folder));
        end

        function onCmpTable(app, ~)
            if isempty(app.list), app.alert('The comparison is empty.', 'Compare'); return; end
            file = app.ask_put({'*.xlsx'; '*.csv'}, 'design_comparison.xlsx'); if isempty(file), return; end
            C = [app.CmpSumTable.ColumnName(:)'; app.CmpSumTable.Data];
            try
                writecell(C, file);
                app.status(['Comparison table saved: ' file]); app.log(['Comparison table saved: ' file]);
            catch err
                app.alert(['The table could not be written: ' err.message], 'Compare');
            end
        end
    end

    % ============================== utilities ===============================
    methods (Access = private)
        function status(app, msg)
            app.StatusLabel.Text = msg;
        end

        function log(app, msg)
            v = app.LogArea.Value; if ischar(v), v = {v}; end
            v = [{sprintf('[%s] %s', datestr(now, 'HH:MM:SS'), msg)}; v(:)]; %#ok<DATST,TNOW1>
            app.LogArea.Value = v(1:min(end, 200));
            app.status(msg);
        end

        function alert(app, msg, ttl)
            if ~isempty(app.test_dir), app.log(['[' ttl '] ' msg]); return; end
            app.close_dlg(app.BusyDlg);                 % the message replaces the progress bar
            uialert(app.UIFigure, msg, ttl);
        end

        function a = confirm(app, msg, ttl, opts)
            if ~isempty(app.test_dir), a = opts{1}; return; end
            a = uiconfirm(app.UIFigure, msg, ttl, 'Options', opts, 'DefaultOption', 1, 'CancelOption', numel(opts));
        end

        function file = ask_put(app, filt, def)
            if ~isempty(app.test_dir), file = fullfile(app.test_dir, def); return; end
            [f, p] = uiputfile(filt, 'Save as', fullfile(app.last_folder, def));
            figure(app.UIFigure);
            if isequal(f, 0), file = ''; return; end
            app.last_folder = p; file = fullfile(p, f);
        end

        function file = ask_get(app, filt)
            if ~isempty(app.test_dir), file = fullfile(app.test_dir, 'cda_project.mat'); return; end
            [f, p] = uigetfile(filt, 'Open', app.last_folder);
            figure(app.UIFigure);
            if isequal(f, 0), file = ''; return; end
            app.last_folder = p; file = fullfile(p, f);
        end

        function folder = ask_dir(app)
            if ~isempty(app.test_dir), folder = app.test_dir; return; end
            folder = uigetdir(app.last_folder, 'Choose a folder');
            figure(app.UIFigure);
            if isequal(folder, 0), folder = ''; else, app.last_folder = folder; end
        end

        function s = thousands(~, n)
            s = sprintf('%d', round(n));
            k = numel(s) - 3;
            while k > 0, s = [s(1:k) ',' s(k + 1:end)]; k = k - 3; end
        end

        function f = guide_file(~)
            % cda_guide.html next to the app (also inside a compiled app)
            f = fullfile(fileparts(mfilename('fullpath')), 'cda_guide.html');
            if ~exist(f, 'file')
                f = which('cda_guide.html');
            end
            if (isempty(f) || ~exist(f, 'file')) && isdeployed
                d = dir(fullfile(ctfroot, '**', 'cda_guide.html'));
                if ~isempty(d), f = fullfile(d(1).folder, d(1).name); else, f = ''; end
            end
        end

        function onOpenGuide(app, ~)
            f = app.guide_file();
            if isempty(f), app.alert('cda_guide.html was not found next to the app.', 'Guide'); return; end
            try
                web(f, '-browser');
            catch
                try, web(f); catch err, app.alert(err.message, 'Guide'); end
            end
        end

        function t = guide_text(~)
            % short guide, shown only when cda_guide.html cannot be displayed
            t = {
            'COMPRESSOR DESIGN APP - quick guide (the full illustrated guide is cda_guide.html next to the app)'
            ''
            'Step 1  Inputs (left panel): configuration, number of stages / rotors, operating point, blading, loss models, sweep ranges.'
            '        "Default inputs (reference study)" sets every input of the reference study for the chosen configuration.'
            'Step 2  "Compute the design space": every combination of phi, psi and R (and U2/U1 for two shafts) is designed.'
            'Step 3  Design space tab: choose the point - "Find the best point" (objective + constraints + limits), click a candidate,'
            '        or click any of the four maps. The point is shown with a black square and in "Selected point".'
            '        Press "Use this point -> Design tab" to design it in detail.'
            'Step 4  Design tab: summary, every blade row and station, warnings. Double-click a cell of the stage table to give a stage'
            '        its own phi, psi, R or DF (yellow = differs from stage 1). Geometry tab: annulus, blade sections, velocity triangles.'
            'Step 5  Export & off-design tab: tick the variables to write, then "Send to the off-design app" (saves the .mat and loads it'
            '        there - press Run in the off-design app), or save the .mat, Excel tables, PNG plots; keep designs in the design list.'
            'Compare designs tab: every design of the list drawn over the others (PR-eta, size, annulus, per-row and per-station'
            '        quantities, velocity triangles) and a comparison table. Add the current design, design files or project files.'
            ''
            'Map markers:  star = best point for the objective,  black square = selected point,  red circle = current design.'
            'Method: stage 1 from phi, psi, R and the rotor-1 relative Mach number; constant mean radius; solidity from the diffusion'
            'factor (Lieblein); profile loss omega = (y/c)(DF) 2 sigma / cos(exit angle); NACA-65 incidence and Carter deviation; areas from continuity.'
            };
        end
    end

    % ======================= app creation and deletion =======================
    methods (Access = public)
        function app = Compressor_design_app(varargin)
            createComponents(app)
            registerApp(app, app.UIFigure)
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))
            if nargout == 0
                clear app
            end
        end

        function delete(app)
            delete(app.UIFigure)
        end
    end
end
