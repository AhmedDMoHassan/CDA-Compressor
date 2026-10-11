% CDA Compressor - Copyright (C) 2026 Ahmed Mohamed Ahmed Hassan, Abdalmoez Ahmed Abdullah Hemid,
% Thabet Saber Thabet Abdelhamid and Deyaa ElHaq Nabil Elshebiny (Cairo University).
% Free for noncommercial use under the PolyForm Noncommercial License 1.0.0; see LICENSE.
% https://github.com/AhmedDMoHassan/CDA-Compressor
classdef Compressor_offdesign_app < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        ResetButton                  matlab.ui.control.Button
        InstructionsPanel            matlab.ui.container.Panel
        ForRotorStatoronlyremove_1fromthenamingofthevariablesLabel  matlab.ui.control.Label
        Image                        matlab.ui.control.Image
        Flowchart                    matlab.ui.control.Image
        RunButton                    matlab.ui.control.Button
        Inputs                       matlab.ui.container.TabGroup
        ManualTab                    matlab.ui.container.Tab
        n_stagesEditField            matlab.ui.control.NumericEditField
        n_stagesEditFieldLabel       matlab.ui.control.Label
        A_vecEditField               matlab.ui.control.EditField
        A_vecEditFieldLabel          matlab.ui.control.Label
        m_dotEditField               matlab.ui.control.NumericEditField
        m_dotEditFieldLabel          matlab.ui.control.Label
        U2EditField                  matlab.ui.control.NumericEditField
        U2EditFieldLabel             matlab.ui.control.Label
        U1EditField                  matlab.ui.control.NumericEditField
        U1EditFieldLabel             matlab.ui.control.Label
        deflection2EditField         matlab.ui.control.NumericEditField
        deflection2EditFieldLabel    matlab.ui.control.Label
        incidence2EditField          matlab.ui.control.NumericEditField
        incidence2EditFieldLabel     matlab.ui.control.Label
        deviation2EditField          matlab.ui.control.NumericEditField
        deviation2EditFieldLabel     matlab.ui.control.Label
        beta4_dashEditField          matlab.ui.control.NumericEditField
        beta4_dashEditFieldLabel     matlab.ui.control.Label
        beta3_dashEditField          matlab.ui.control.NumericEditField
        beta3_dashEditFieldLabel     matlab.ui.control.Label
        w_loss_rotor2EditField       matlab.ui.control.NumericEditField
        w_loss_rotor2EditFieldLabel  matlab.ui.control.Label
        w_loss_rotorEditField        matlab.ui.control.NumericEditField
        w_loss_rotorEditFieldLabel   matlab.ui.control.Label
        deflectionEditField          matlab.ui.control.NumericEditField
        deflectionEditFieldLabel     matlab.ui.control.Label
        incidenceEditField           matlab.ui.control.NumericEditField
        incidenceEditFieldLabel      matlab.ui.control.Label
        deviationEditField           matlab.ui.control.NumericEditField
        deviationEditFieldLabel      matlab.ui.control.Label
        beta2_dashEditField          matlab.ui.control.NumericEditField
        beta2_dashEditFieldLabel     matlab.ui.control.Label
        beta1_dashEditField          matlab.ui.control.NumericEditField
        beta1_dashEditFieldLabel     matlab.ui.control.Label
        alpha_1EditField             matlab.ui.control.NumericEditField
        alpha_1EditFieldLabel        matlab.ui.control.Label
        FileTab                      matlab.ui.container.Tab
        upload_message               matlab.ui.control.TextArea
        uploadfileButton             matlab.ui.control.Button
        YourMatFileEditField         matlab.ui.control.EditField
        YourMatFileEditFieldLabel    matlab.ui.control.Label
        InputTypeButtonGroup         matlab.ui.container.ButtonGroup
        matfileinputButton           matlab.ui.control.RadioButton
        ManualinputButton            matlab.ui.control.RadioButton
        ChooseInputtypeButton        matlab.ui.control.Button
        TextArea                     matlab.ui.control.TextArea
        Choosethecompressortype      matlab.ui.control.DropDown
        ChoosethecompressortypeDropDownLabel  matlab.ui.control.Label
    end

    properties (Access = private)
        Mainapp % connection to main app
        Compressor_type % the type of the compressor being analyzed
        InputType_value % the inputs will be from which source
        loadedData % Stores the data loaded from the .mat file
        % Greitzer B parameter (compression-system inputs, optional). They can
        % also be supplied as extra variables V_plenum, L_duct, B_crit in the .mat
        V_plenum = NaN   % m^3, volume downstream of the compressor (plenum); NaN = not given
        L_duct = NaN     % m, effective length of compressor + inlet/exit ducts; NaN = not given
        B_crit = 0.8     % critical B: surge if B > B_crit, rotating stall otherwise (machine dependent)
        % Corrected (standard-day) reference conditions for the corrected map
        T_ref = 288.15   % K
        p_ref = 101325   % Pa
        % Off-design correlations (swappable): 'polynomial' (default), 'three-point', 'user'
        CorrelationSet = 'polynomial'
        corr = struct()  % active correlation data, rebuilt at the start of every run
        howell_factor = 2  % Howell stall onset: loss = howell_factor x design (minimum) loss
        bucket_width = 1   % step 24: width factor of the loss bucket and deviation curve, x = (i - i_des)/(bucket_width*deflection)
        bucket_width_neg = []      % step 25: width on the choke side (i < i_des); [] = same as bucket_width
        min_ref_deflection = 0     % step 25: x = (i - i_des)/(width*max(deflection, this)) [deg]; 0 = off
        blockage = 1               % step 25: effective area = blockage x A_vec at every station; 1 = off
        re_exponent = 0            % step 25: loss x (Re/Re_des)^(-n) below Re_crit = 2.5e5; 0 = off
        meas_speeds_only = false   % step 26: compute only the measured speeds (+ N/N_des = 1)
        % Koch (1981) stage stall criterion: needs row solidities + chord in the .mat
        % (sigma_rotor, sigma_stator / sigma_1, sigma_2, chord). Optional overrides
        % in the .mat: eps_over_g, dz_over_s (defaults = Koch reference values).
        koch_eps_over_g = 0.055   % tip clearance / staggered spacing (Koch reference)
        koch_dz_over_s = 0.38     % axial gap / blade pitch (Koch reference)
        koch_Fef_seen = []        % effective dynamic-pressure factors met at the Koch limit points
        koch_in_limit = false     % true: the Koch limit also counts in the 'first stability limit'
        koch_target_ratio = 0.85  % design target: Ch_ef/Ch_max at the design point (designer's margin choice)
        equation_log = {}         % boundary equations of the last run (Equations tab)
        report_log = ''           % full text report of the last run (Report tab / command window)
        % Step 12: components of the result tabs, created in code by build_results_ui
        MainTabGroup
        GuideTab
        SettingsTab
        MapsTab
        TablesTab
        EquationsTab
        DiagnosticsTab
        ReportTab
        CorrelationSetDropDown
        HowellFactorEditField
        BucketWidthEditField
        ModelTab
        BucketWidthNegEditField
        MinRefDeflEditField
        BlockageEditField
        ReExponentEditField
        ShowMeasuredCheckBox
        MeasSpeedsOnlyCheckBox
        KochTargetEditField
        KochEpsOverGEditField
        KochDzOverSEditField
        KochInLimitCheckBox
        BcritEditField
        VplenumEditField
        LductEditField
        TrefEditField
        PrefEditField
        MapsTabGroup
        StdPRAxes
        StdEffAxes
        NondimPRAxes
        NondimEffAxes
        RelPRAxes
        RelEffAxes
        CorrPRAxes
        CorrEffAxes
        ExportFiguresButton
        SeparateWindowsCheckBox
        TableSelectDropDown
        ExportTablesButton
        ResultsTable
        EquationsTextArea
        CopyEquationsButton
        DiagnosticsTextArea
        ReportTextArea
        CopyReportButton
        EchoCommandWindowCheckBox
        % Step 14: settings, comparisons and the new components
        Tt1_in = 288              % design inlet total temperature [K] (a Tt1 saved in the .mat wins)
        Pt1_in = 1e5              % design inlet total pressure [Pa] (a Pt1 saved in the .mat wins)
        N_min = 0.5               % run range: lowest N/N_des
        N_max = 1.2               % run range: highest N/N_des
        n_speed = 15              % run range: number of speed lines
        m_density = 100           % mass-flow grid points per 0.7*m_design
        koch_mode = 'Auto (app decides)'   % Koch line: 'Auto (app decides)', 'Always show', 'Hide'
        quiet = false             % true while a comparison file is computed (no pop-ups)
        last_folder = ''          % last folder used in a file dialog
        compare_runs = []         % runs of the Compare tab
        compare_sel = []          % selected rows of the comparison table
        mat_name = ''             % step 18: name of the uploaded .mat (without extension), used in export names
        pdf_progress = []         % step 20: progress bar while a PDF is written
        pdf_total = 14            % step 20: expected number of pages (progress bar)
        TinEditField
        PinEditField
        NminEditField
        NmaxEditField
        NspeedEditField
        MdensEditField
        KochModeDropDown
        SaveSessionButton
        OpenSessionButton
        SaveInputsButton
        ExportReportButton
        ShowSpeedCheckBox
        ShowSurgeCheckBox
        ShowStallCheckBox
        ShowChokeCheckBox
        ShowKochCheckBox
        ShowDesignCheckBox
        CompareTab
        CompareTypeDropDown
        CompareAddFileButton
        CompareAddLastButton
        CompareRemoveButton
        CompareClearButton
        CompareExportButton
        CompareTable
        CmpRelPRAxes
        CmpRelEffAxes
        CmpNdPRAxes
        CmpNdEffAxes
        % the inputs for the main functions (off-design in general)
        % choose only what is relevent to you 
        % you can see the manual input as indicator too! 
        % use the same name if uploading a file
        alpha1 %deg
        %number of your compressor stage: 
        %1- for rotor-stator:stage is a combination of a rotor and a stator
        %2- for rotor-rotor: stage is one rotor only
        n_stages 
        A_vec %vector in form 1 2 3 4 no commas, no [], no (), only decimals
        beta1_dash %deg
        beta2_dash %deg
        beta3_dash %deg not for rotor-stator
        beta4_dash %deg not for rotor-stator
        deviation_1 %deg
        deviation_2 %deg not for rotor-stator
        incidence_1 %deg
        incidence_2 %deg not for rotor-stator
        deflection_1 %deg
        deflection_2 %deg not for rotor-stator
        m_dot %Kg_per_sec
        w_loss_rotor  %non-dimensional: rotor loss (all configs)
        w_loss_rotor2 %non-dimensional: 2nd rotor loss (rotor-rotor) / stator loss (rotor-stator)
        U1 %m_per_sec
        U2 %%m_per_sec not for rotor-stator or same shaft rotor-rotor
        computation_results % Store computation results for plotting
    end
    
    methods (Access = private)
        
        function success = validate_inputs(app)
            % Validate inputs based on compressor type
            success = true;
            
            switch app.Compressor_type
                case 'Rotor-Stator'
                    required_fields = {'alpha1','n_stages', 'A_vec', 'beta1_dash', 'beta2_dash', ...
                                      'deviation_1', 'incidence_1', 'deflection_1', ...
                                      'm_dot', 'w_loss_rotor', 'w_loss_rotor2', 'U1'};
                case 'Rotor-Rotor same shaft'
                    required_fields = {'alpha1', 'n_stages','A_vec', 'beta1_dash', 'beta2_dash', ...
                                      'beta3_dash', 'beta4_dash', 'deviation_1', 'deviation_2', ...
                                      'incidence_1', 'incidence_2', 'deflection_1', 'deflection_2', ...
                                      'm_dot', 'w_loss_rotor', 'w_loss_rotor2', 'U1'};
                case 'Rotor-Rotor different shaft'
                    required_fields = {'alpha1','n_stages', 'A_vec', 'beta1_dash', 'beta2_dash', ...
                                      'beta3_dash', 'beta4_dash', 'deviation_1', 'deviation_2', ...
                                      'incidence_1', 'incidence_2', 'deflection_1', 'deflection_2', ...
                                      'm_dot', 'w_loss_rotor', 'w_loss_rotor2', 'U1', 'U2'};
            end
            
            % Check if all required fields have values
            for i = 1:length(required_fields)
                field_name = required_fields{i};
                value = app.(field_name);
                
                if isempty(value)
                    uialert(app.UIFigure, sprintf('Missing value for %s', field_name), 'Input Error');
                    success = false;
                    return;
                end
                
                if isnumeric(value) && any(isnan(value))
                    uialert(app.UIFigure, sprintf('Invalid value for %s', field_name), 'Input Error');
                    success = false;
                    return;
                end
            end
            
            % Step 14: clearer checks, all problems listed at once
            msgs = {};
            if ~isscalar(app.n_stages) || app.n_stages < 1 || mod(app.n_stages, 1) ~= 0
                msgs{end+1} = 'n_stages must be a whole number >= 1.';
            end
            if app.m_dot <= 0, msgs{end+1} = 'm_dot must be > 0.'; end
            if any(app.U1 <= 0), msgs{end+1} = 'U1 (U in the .mat) must be > 0.'; end
            if strcmp(app.Compressor_type, 'Rotor-Rotor different shaft') && any(app.U2 == 0)
                msgs{end+1} = 'U2 must not be 0 (a negative U2 means counter-rotating even rotors).';
            end
            if any(app.w_loss_rotor < 0) || any(app.w_loss_rotor2 < 0), msgs{end+1} = 'Loss coefficients cannot be negative.'; end
            nA = numel(app.A_vec);
            if isscalar(app.n_stages)
                if strcmp(app.Compressor_type, 'Rotor-Stator')
                    okA = any(nA == [2*app.n_stages + 1, 2*app.n_stages]);
                    need = sprintf('%d (or %d without the last stator)', 2*app.n_stages + 1, 2*app.n_stages);
                else
                    okA = nA == app.n_stages + 1; need = sprintf('%d', app.n_stages + 1);
                end
                if ~okA
                    msgs{end+1} = sprintf('A_vec has %d areas; %s are needed for n_stages = %d.', nA, need, app.n_stages);
                end
            end
            if app.N_min >= 1 || app.N_max <= 1
                msgs{end+1} = 'Run range (Settings): the lowest speed must be below 1 and the highest above 1.';
            end
            if isempty(msgs)          % step 23: per-row inputs (scalars or vectors) fit the number of rows
                try
                    app.row_model();
                catch err
                    msgs{end+1} = err.message;
                end
            end
            if ~isempty(msgs)
                uialert(app.UIFigure, strjoin(msgs, newline), 'Input Error');
                success = false;
                return;
            end
            if ~app.quiet && app.has_ui('ManualinputButton') && isequal(app.InputType_value, app.ManualinputButton)
                w = app.consistency_warnings();
                if ~isempty(w)
                    uialert(app.UIFigure, strjoin(w, newline), 'Input Warning', 'Icon', 'warning');
                end
            end

            % Additional validation for A_vec
            if ~isnumeric(app.A_vec) || any(app.A_vec <= 0)
                uialert(app.UIFigure, 'A_vec must be a positive numeric array', 'Input Error');
                success = false;
                return;
            end

            % Deflection sign convention: deflection = beta_in - beta_out > 0
            % for a compressor blade row. A negative value mirrors the
            % normalized-incidence axis of the loss/deviation correlations
            % (stall side <-> choke side) without any error, so warn.
            rr = app.row_model();     % step 23: every row (checked above)
            defl = [rr.defl];
            if any(defl < 0)
                uialert(app.UIFigure, ['Negative deflection detected. Convention used by the ' ...
                    'off-design model: deflection = beta_in - beta_out (> 0). Please check the ' ...
                    'design script that produced this file.'], 'Input Warning', 'Icon', 'warning');
            end
        end

        
        % =================== step 23: ONE general solver for every configuration ===================
        % The design is described as a list of blade rows in flow order (row_model).
        % Rotor-Stator : any number of stages; each stage = rotor + stator (the last
        %                stator may be omitted: A_vec with 2n instead of 2n+1 areas).
        % Rotor-Rotor  : any number of rotors (n_stages = rotors); each rotor is one
        %                stage. Same shaft: every rotor turns at U. Different shafts:
        %                every rotor has its own speed.
        % Per-row inputs may be scalars (same value for every row of the group) or
        % vectors with one value per row of the group:
        %   Rotor-Stator: beta1_dash, beta2_dash, incidence, deviation, deflection,
        %                 w_loss_rotor -> one per stage; w_loss_stator -> one per stator
        %                 optional stator_beta_in, stator_beta_out, stator_incidence,
        %                 stator_deviation, stator_deflection -> one per stator (step 24;
        %                 without them a stator repeats its rotor's angles)
        %   Rotor-Rotor : rotor-1 inputs (beta1_dash, beta2_dash, *_1, w_loss_rotor, U1)
        %                 -> odd rotors 1, 3, 5, ...; rotor-2 inputs (beta3_dash,
        %                 beta4_dash, *_2, w_loss_rotor2, U2) -> even rotors 2, 4, ...
        function results = compute_rotor_stator(app)
            results = app.compute_general();
        end

        function results = compute_rotor_rotor_same_shaft(app)
            results = app.compute_general();
        end

        function results = compute_rotor_rotor_diff_shaft(app)
            results = app.compute_general();
        end

        function v = per_row(app, val, j, count, name, what)
            % Value of a per-row input for the j-th row of its group (count rows)
            if isscalar(val)
                v = double(val);
            elseif numel(val) == count
                v = double(val(j));
            else
                error('%s has %d values: give 1 value or %d (one per %s).', name, numel(val), count, what);
            end
        end

        function rows = row_model(app)
            % Blade rows of the design in flow order. Each row: name, Koch name, kind
            % ('R' rotor / 'S' stator), design blade speed U (0 for a stator), metal
            % angles, design incidence / deviation / deflection / loss, inlet and exit
            % areas, stage number and its index in its input group.
            typ = app.Compressor_type;
            n = double(app.n_stages);
            A = double(app.A_vec(:)');
            bk = app.blockage_vector(numel(A));              % step 25: choke area factor of every station
            rows = struct('name', {}, 'kname', {}, 'kind', {}, 'U', {}, 'b_in', {}, 'b_out', {}, 'inc', {}, ...
                          'dev', {}, 'defl', {}, 'w', {}, 'A_in', {}, 'A_out', {}, 'stage', {}, 'group', {}, 'gi', {});
            iA = [];                                          % station index of each row's inlet (step 25)
            if isempty(n) || ~isscalar(n) || n < 1 || mod(n, 1) ~= 0
                error('n_stages must be a whole number >= 1.');
            end
            if strcmp(typ, 'Rotor-Stator')
                if numel(A) == 2*n + 1
                    n_stat = n;
                elseif numel(A) == 2*n
                    n_stat = n - 1;
                else
                    error(['A_vec has %d areas; a rotor-stator compressor with %d stage(s) needs %d ' ...
                        '(or %d without the last stator).'], numel(A), n, 2*n + 1, 2*n);
                end
                if ~isscalar(app.U1), error('U must be one value (all rotors of a rotor-stator compressor turn together).'); end
                for k = 1:n
                    g = struct('b_in', app.per_row(app.beta1_dash, k, n, 'beta1_dash', 'stage'), ...
                               'b_out', app.per_row(app.beta2_dash, k, n, 'beta2_dash', 'stage'), ...
                               'inc', app.per_row(app.incidence_1, k, n, 'incidence', 'stage'), ...
                               'dev', app.per_row(app.deviation_1, k, n, 'deviation', 'stage'), ...
                               'defl', app.per_row(app.deflection_1, k, n, 'deflection', 'stage'));
                    rows(end+1) = struct('name', sprintf('Rotor %d', k), 'kname', sprintf('R%d', k), 'kind', 'R', ...
                        'U', double(app.U1), 'b_in', g.b_in, 'b_out', g.b_out, 'inc', g.inc, 'dev', g.dev, 'defl', g.defl, ...
                        'w', app.per_row(app.w_loss_rotor, k, n, 'w_loss_rotor', 'stage'), ...
                        'A_in', A(2*k - 1), 'A_out', A(2*k), 'stage', k, 'group', 1, 'gi', k);
                    iA(end+1) = 2*k - 1;
                    if k <= n_stat
                        % stator angles: its own when the .mat has them, else the rotor's
                        % (symmetric, 50 % reaction stage)   (step 24)
                        sg = app.stator_geometry(g, k, n_stat);
                        if numel(app.w_loss_rotor2) == n && n_stat < n
                            ws = double(app.w_loss_rotor2(k));
                        else
                            ws = app.per_row(app.w_loss_rotor2, k, n_stat, 'w_loss_stator', 'stator');
                        end
                        rows(end+1) = struct('name', sprintf('Stator %d', k), 'kname', sprintf('S%d', k), 'kind', 'S', ...
                            'U', 0, 'b_in', sg.b_in, 'b_out', sg.b_out, 'inc', sg.inc, 'dev', sg.dev, 'defl', sg.defl, ...
                            'w', ws, 'A_in', A(2*k), 'A_out', A(2*k + 1), 'stage', k, 'group', 2, 'gi', k);
                        iA(end+1) = 2*k;
                    end
                end
            else
                N = n;                                    % number of rotors, each one stage
                if numel(A) ~= N + 1
                    error('A_vec has %d areas; %d rotor(s) need %d (one more than the number of rotors).', numel(A), N, N + 1);
                end
                n1 = ceil(N/2); n2 = floor(N/2);          % odd rotors / even rotors
                diffShaft = strcmp(typ, 'Rotor-Rotor different shaft');
                if ~diffShaft && ~isscalar(app.U1)
                    error('U must be one value: all rotors on one shaft turn together.');
                end
                for k = 1:N
                    if mod(k, 2) == 1
                        j = (k + 1)/2; c = n1; what = 'odd rotor (1, 3, 5, ...)';
                        b_in = app.per_row(app.beta1_dash, j, c, 'beta1_dash', what);
                        b_out = app.per_row(app.beta2_dash, j, c, 'beta2_dash', what);
                        inc = app.per_row(app.incidence_1, j, c, 'incidence_1', what);
                        dev = app.per_row(app.deviation_1, j, c, 'deviation_1', what);
                        defl = app.per_row(app.deflection_1, j, c, 'deflection_1', what);
                        w = app.per_row(app.w_loss_rotor, j, c, 'w_loss_rotor', what);
                        if diffShaft, U = app.per_row(app.U1, j, c, 'U1', what); else, U = double(app.U1); end
                        grp = 1;
                    else
                        j = k/2; c = n2; what = 'even rotor (2, 4, ...)';
                        b_in = app.per_row(app.beta3_dash, j, c, 'beta3_dash', what);
                        b_out = app.per_row(app.beta4_dash, j, c, 'beta4_dash', what);
                        inc = app.per_row(app.incidence_2, j, c, 'incidence_2', what);
                        dev = app.per_row(app.deviation_2, j, c, 'deviation_2', what);
                        defl = app.per_row(app.deflection_2, j, c, 'deflection_2', what);
                        w = app.per_row(app.w_loss_rotor2, j, c, 'w_loss_rotor2', what);
                        if diffShaft, U = app.per_row(app.U2, j, c, 'U2', what); else, U = double(app.U1); end
                        grp = 2;
                    end
                    rows(end+1) = struct('name', sprintf('Rotor %d', k), 'kname', sprintf('R%d', k), 'kind', 'R', ...
                        'U', U, 'b_in', b_in, 'b_out', b_out, 'inc', inc, 'dev', dev, 'defl', defl, 'w', w, ...
                        'A_in', A(k), 'A_out', A(k + 1), 'stage', k, 'group', grp, 'gi', j);
                    iA(end+1) = k;
                end
            end
            for q = 1:numel(rows)                            % step 25: choke area factors (1 = geometric area)
                rows(q).bk_in = bk(iA(q)); rows(q).bk_out = bk(iA(q) + 1);
            end
        end

        function [PR, Eff, fail_row, fail_type, loss_ratio, stall_row, kst, rec, TR, Re_rows] = solve_point(app, m_dot, Nr, M, lean)
            % Performance at ONE operating point of any configuration.
            %   m_dot : mass flow [kg/s];  Nr : speed ratio N/N_des (scales every rotor speed)
            %   M     : model from row_model plus inlet state and correlations
            %   lean  : true -> skip the Koch station data and the blade-row records
            % fail_row/fail_type are empty if the point can be computed; otherwise
            % they name the station and the reason ('choked' or 'invalid').
            % loss_ratio/stall_row: highest omega/omega_des at positive incidence (Howell).
            if nargin < 5, lean = false; end
            gamma = 1.4; R = 287; cp = gamma*R/(gamma - 1); ex = gamma/(gamma - 1);
            PR = NaN; Eff = NaN; TR = NaN; fail_row = ''; fail_type = '';
            loss_ratio = NaN; stall_row = ''; lr_max = 0; sr_max = '';
            kst = app.koch_row(); rec = app.row_rec();
            rows = M.rows;
            Re_rows = nan(1, numel(rows));                    % step 25: row inlet Reynolds numbers (chord based)

            % Station 1: inlet, absolute frame
            al = deg2rad(M.alpha1);
            [Mn, st] = app.calculate_M_scalar(m_dot, R, M.Tt1, rows(1).A_in, M.Pt1, al, gamma);
            if strcmp(st, 'ok') && isfield(rows, 'bk_in') && rows(1).bk_in < 1      % step 25: choke on the effective area
                [~, st] = app.calculate_M_scalar(m_dot, R, M.Tt1, rows(1).A_in*rows(1).bk_in, M.Pt1, al, gamma);
            end
            if ~strcmp(st, 'ok')
                fail_row = sprintf('%s inlet (absolute)', rows(1).name); fail_type = st; return;
            end
            Tt = M.Tt1; Pt = M.Pt1;
            T = Tt/(1 + (gamma - 1)/2*Mn^2);
            C = Mn*sqrt(gamma*R*T);
            Cx = C*cos(al); Ct = Cx*tan(al);
            p = Pt*(T/Tt)^ex;
            Vup = [Cx, Ct]; Uup = 0;                 % flow leaving the upstream row, in its own frame

            for q = 1:numel(rows)
                r = rows(q);
                U = Nr*r.U;
                sg = 1;
                if r.kind == 'R' && U < 0, sg = -1; end      % step 27: counter-rotating rotor, solved in its own frame
                if r.kind == 'R'
                    b = atan((sg*U - sg*Ct)/Cx);     % relative inlet angle (positive against the row's own rotation)
                    V = Cx/cos(b);                   % W
                    Ttf = T + V^2/(2*cp);            % relative total temperature (conserved: constant radius)
                    ptf = Pt*(Ttf/Tt)^ex;            % relative total pressure
                    Vin = [Cx, Ct - U];
                else
                    b = atan(Ct/Cx);                 % absolute inlet angle
                    V = Cx/cos(b);                   % C
                    Ttf = Tt; ptf = Pt;
                    Vin = [Cx, Ct];
                end
                i_row = rad2deg(b) - r.b_in;
                di = i_row - r.inc;
                if di < 0, kx = M.kx_neg; else, kx = M.kx; end    % step 25: own width on the choke side
                x = di/(max(r.defl, M.eps_min)*kx);                % step 24/25: bucket width, minimum reference deflection
                omega = M.w_func(x) + (r.w - M.w_func(0));   % loss anchored to the design loss
                if ~isempty(M.chord)                               % step 25: Reynolds correction (anchored at design)
                    Re_rows(q) = (p/(R*T))*V*M.chord/app.air_viscosity(T);
                    if M.re_n > 0 && numel(M.Re_des) >= q
                        omega = omega*(min(Re_rows(q), M.re_crit)/min(M.Re_des(q), M.re_crit))^(-M.re_n);
                    end
                end
                delta = M.dev_func(x)*r.defl + r.dev;        % deviation anchored to the design deviation
                if x > 0 && omega/r.w > lr_max             % Howell: positive-incidence side only
                    lr_max = omega/r.w; sr_max = r.name;
                end
                if ~(omega >= 0)                              % step 26: negative loss = polynomial extrapolated far outside its data
                    fail_row = sprintf('%s (loss coefficient %.2f out of range)', r.name, omega); fail_type = 'invalid'; return;
                end
                bo = deg2rad(r.b_out + delta);               % exit flow angle in the row frame
                ptf_out = ptf - omega*(ptf - p);

                % Exit station, in the frame of this row (choking test of the row)
                [Mo, st] = app.calculate_M_scalar(m_dot, R, Ttf, r.A_out, ptf_out, bo, gamma);
                if strcmp(st, 'ok') && isfield(r, 'bk_out') && r.bk_out < 1          % step 25: choke on the effective area
                    [~, st] = app.calculate_M_scalar(m_dot, R, Ttf, r.A_out*r.bk_out, ptf_out, bo, gamma);
                end
                if ~strcmp(st, 'ok')
                    if r.kind == 'R', fr = 'relative'; else, fr = 'absolute'; end
                    fail_row = sprintf('%s exit (%s)', r.name, fr); fail_type = st; return;
                end
                T2 = Ttf/(1 + (gamma - 1)/2*Mo^2);
                V2 = Mo*sqrt(gamma*R*T2);
                Cx2 = V2*cos(bo);
                p2 = ptf_out*(T2/Ttf)^ex;
                if r.kind == 'R'
                    Ct2 = U - sg*Cx2*tan(bo);         % step 27: sg = -1 for a counter-rotating rotor
                    a2 = atan(Ct2/Cx2);
                    C2 = Cx2/cos(a2);
                    Tt2 = T2 + C2^2/(2*cp);
                    Pt2 = ptf_out*(Tt2/Ttf)^ex;
                    Vout = [Cx2, -sg*Cx2*tan(bo)];
                else
                    Ct2 = Cx2*tan(bo);
                    Tt2 = Ttf; Pt2 = ptf_out;
                    Vout = [Cx2, Ct2];
                end
                if ~lean
                    kst(end+1) = app.koch_row(r.kname, p, T, Vin, Vup, Uup, U, p2);
                    rec(end+1) = app.row_rec(r.name, i_row, x, omega, r.w, V/sqrt(gamma*R*T), Mo, V2/V, delta);
                end
                % hand over to the next row
                T = T2; Cx = Cx2; Ct = Ct2; Tt = Tt2; Pt = Pt2; p = p2;
                Vup = Vout; Uup = U;
            end

            PR = Pt/M.Pt1;
            TR = Tt/M.Tt1;
            Eff = (PR^((gamma - 1)/gamma) - 1)/(TR - 1);
            loss_ratio = lr_max;
            stall_row = sr_max;
        end

        function results = compute_general(app)
            % Off-design maps, boundaries and diagnostics of the loaded design
            % (any configuration, any number of stages or rotors)
            try
                typ = app.Compressor_type;
                rows = app.row_model();
                if strcmp(typ, 'Rotor-Stator')
                    if sum([rows.kind] == 'S') == app.n_stages
                        app.info_alert('Normal configuration: last stator considered.', 'Configuration Detected');
                    else
                        app.info_alert('Special case: last stator abandoned, one less area.', 'Configuration Detected');
                    end
                    label = 'Rotor-Stator';
                elseif strcmp(typ, 'Rotor-Rotor same shaft')
                    label = 'Rotor-Rotor Same Shaft';
                else
                    label = 'Rotor-Rotor Different Shaft';
                end
                fprintf('\n%s: %d blade row(s): %s\n', label, numel(rows), strjoin({rows.kname}, ' '));

                R = 287; gamma = 1.4;
                [Tt1_initial, Pt1_initial] = app.inlet_state();   % .mat > Settings > 288 K / 1e5 Pa
                alpha1 = app.alpha1;
                alpha1_rad = deg2rad(alpha1);
                A1 = double(app.A_vec(1));                       % geometric inlet area (MFP, Greitzer)
                m_dot_design = app.m_dot;
                U_design = rows(1).U;                            % rotor-1 blade speed at design
                MFP1_design = (m_dot_design*sqrt(R*Tt1_initial))/(A1*Pt1_initial*cos(alpha1_rad));

                % Loss and deviation correlations: ONE shared model, anchored to the design point
                app.corr = app.build_correlations();
                M = struct('rows', rows, 'Tt1', Tt1_initial, 'Pt1', Pt1_initial, 'alpha1', alpha1, ...
                           'w_func', @(x) app.loss_bucket(x), 'dev_func', @(x) app.deviation_curve(x), ...
                           'kx', app.bucket_width);
                M = app.add_model_options(M);                     % step 25: blockage is in the rows already
                if ~isempty(M.chord)                              % design Reynolds numbers (anchor of the correction)
                    [~, ~, ~, ~, ~, ~, ~, ~, ~, M.Re_des] = app.solve_point(m_dot_design, 1, M, true);
                end
                ev = @(m, Nr) app.solve_point(m, Nr, M);          % full point (Koch data, blade rows)
                evl = @(m, Nr) app.solve_point(m, Nr, M, true);   % lean point (grid, searches)

                % Speed lines and mass-flow grid: from 0.3*m_des up to the choke flow of the
                % FASTEST speed line (+2 %), at least 1.2*m_des; 100 points per 0.7*m_des
                speed_ratio = app.speed_ratios(); speed_ratio = speed_ratio(:)';
                m_upper = app.find_max_flow(@(m) evl(m, speed_ratio(end)), m_dot_design);
                upper = max(1.2, 1.02*m_upper/m_dot_design);
                mass_dot_range = m_dot_design.*linspace(0.3, upper, round(app.m_density*(upper - 0.3)/0.7));
                n_U = numel(speed_ratio);
                n_mass = numel(mass_dot_range);
                U_range = U_design*speed_ratio;

                % Design point
                [PR_design, Eff_design, dp_row, dp_type, ~, ~, kst_design] = ev(m_dot_design, 1);
                if ~isempty(dp_type)
                    error('The design point itself cannot be computed (%s at %s). Check the design file.', dp_type, dp_row);
                end

                Total_PR = nan(n_U, n_mass); Overall_Eff = nan(n_U, n_mass); MFP1_matrix = nan(n_U, n_mass);
                choke_mask = false(n_U, n_mass);
                choke_m = nan(n_U, 1); choke_PR = nan(n_U, 1); choke_Eff = nan(n_U, 1); choke_row = repmat({''}, n_U, 1);
                stall_points = nan(n_U, 1); stall_PR = nan(n_U, 1); stall_Eff = nan(n_U, 1); stall_row = repmat({''}, n_U, 1);
                surge_points = nan(n_U, 1); surge_PR = nan(n_U, 1); surge_Eff = nan(n_U, 1);
                koch_points = nan(n_U, 1); koch_PR = nan(n_U, 1); koch_Eff = nan(n_U, 1); koch_stage = repmat({''}, n_U, 1);
                kg = app.koch_geometry(rows);                      % [] if no solidity/chord -> Koch skipped
                koch_design = app.koch_design_check(kst_design, kg);

                for u_idx = 1:n_U
                    Nr = speed_ratio(u_idx);
                    for m_idx = 1:n_mass
                        m_i = mass_dot_range(m_idx);
                        MFP1_matrix(u_idx, m_idx) = (m_i*sqrt(R*Tt1_initial))/(A1*Pt1_initial*cos(alpha1_rad));
                        [PR_i, Eff_i, ~, ft, ~, ~, ~, ~, TR_i] = evl(m_i, Nr);
                        if isempty(ft) && isfinite(PR_i)
                            Total_PR(u_idx, m_idx) = PR_i;
                            if (TR_i - 1) > 1e-3
                                Overall_Eff(u_idx, m_idx) = Eff_i;
                            end
                        end
                    end

                    evalfun = @(m) evl(m, Nr);
                    % Choke: exact, by bisection between the last computable grid point and the next
                    j_last = find(~isnan(Total_PR(u_idx, :)), 1, 'last');
                    if ~isempty(j_last) && j_last < n_mass
                        [choke_m(u_idx), choke_PR(u_idx), choke_Eff(u_idx), choke_row{u_idx}] = ...
                            app.find_choke_point(evalfun, mass_dot_range(j_last), mass_dot_range(j_last + 1));
                        if ~isnan(choke_m(u_idx))
                            choke_mask(u_idx, j_last) = true;
                        end
                    end
                    % Stall onset (Howell), exact by bisection
                    [stall_points(u_idx), stall_PR(u_idx), stall_Eff(u_idx), stall_row{u_idx}] = ...
                        app.find_stall_point(evalfun, mass_dot_range, Total_PR(u_idx, :), Overall_Eff(u_idx, :));
                    % Koch (1981) stage limit (indicator), if the geometry is available
                    if ~isempty(kg)
                        [koch_points(u_idx), koch_PR(u_idx), koch_Eff(u_idx), koch_stage{u_idx}] = ...
                            app.find_koch_point(@(m) ev(m, Nr), kg, mass_dot_range, Total_PR(u_idx, :), Overall_Eff(u_idx, :));
                    end
                    % Peak (zero slope), golden-section refinement (NaN on the grid edge)
                    [~, j_peak] = max(Total_PR(u_idx, :));
                    [surge_points(u_idx), surge_PR(u_idx), surge_Eff(u_idx)] = app.find_peak_point(evalfun, ...
                        mass_dot_range, Total_PR(u_idx, :), j_peak);
                end

                mfp = @(m) (m*sqrt(R*Tt1_initial))/(A1*Pt1_initial*cos(alpha1_rad));
                valid_surge = ~isnan(surge_points) & surge_PR > 0;
                [sorted_surge_MFP, i_s] = sort(mfp(surge_points(valid_surge)));
                sp = surge_PR(valid_surge); sorted_surge_PR = sp(i_s);
                valid_stall = ~isnan(stall_points);
                [sorted_stall_MFP, i_t] = sort(mfp(stall_points(valid_stall)));
                tp = stall_PR(valid_stall); sorted_stall_PR = tp(i_t);
                choke_MFP = mfp(choke_m);
                choke_in_region = ~isnan(choke_m) & (real(choke_PR) > 1);   % choke at PR <= 1 is not drawn
                app.print_choke_table(speed_ratio, choke_m, choke_MFP, choke_PR, choke_Eff, choke_row, choke_in_region);
                app.print_stall_table(speed_ratio, stall_points, stall_PR, stall_Eff, stall_row);
                app.print_surge_table(speed_ratio, surge_points, surge_PR, stall_points);
                app.print_koch_table(speed_ratio, koch_points, koch_PR, koch_Eff, koch_stage, kg);
                app.print_koch_design(koch_design);

                meas_pred = [];                                    % step 24: prediction at each measured point
                Dm = app.measured_data();
                if ~isempty(Dm)
                    meas_pred = nan(numel(Dm.N), 2);
                    for q = 1:numel(Dm.N)
                        [pq, eq, ~, fq, ~, ~, ~, ~, tq] = evl(Dm.m(q), Dm.N(q));
                        if isempty(fq) && isfinite(pq)
                            meas_pred(q, 1) = pq;
                            if (tq - 1) > 1e-3 && pq > 1 && eq > 0 && eq <= 1, meas_pred(q, 2) = eq; end   % efficiency defined only for PR > 1
                        end
                    end
                end
                o = M; o = rmfield(o, {'rows', 'w_func', 'dev_func'});
                o.blockage = app.blockage_vector(numel(app.A_vec)); o.re_req = app.model_option('re_exponent', 're_exponent') > 0;
                results = struct( ...
                    'model_options', o, ...
                    'meas_pred', meas_pred, ...
                    'mass_dot_range', mass_dot_range, 'U_range', U_range, 'speed_ratio', speed_ratio, 'U_ref', U_range, ...
                    'choke_m', choke_m, 'choke_MFP', choke_MFP, 'choke_PR', choke_PR, 'choke_Eff', choke_Eff, ...
                    'choke_row', {choke_row}, 'choke_in_region', choke_in_region, ...
                    'stall_Eff', stall_Eff, 'stall_row', {stall_row}, 'stall_points', stall_points, 'stall_PR', stall_PR, ...
                    'stall_MFP', sorted_stall_MFP, 'stall_PR_sorted', sorted_stall_PR, ...
                    'Total_PR', Total_PR, 'Overall_Eff', Overall_Eff, ...
                    'surge_points', surge_points, 'surge_PR', surge_PR, 'surge_Eff', surge_Eff, ...
                    'A1', A1, 'Tt1', Tt1_initial, 'Pt1', Pt1_initial, ...
                    'koch_points', koch_points, 'koch_PR', koch_PR, 'koch_Eff', koch_Eff, 'koch_stage', {koch_stage}, ...
                    'koch_geometry', kg, 'koch_design', koch_design, ...
                    'choke_mask', choke_mask, 'MFP1_matrix', MFP1_matrix, 'MFP1_design', MFP1_design, ...
                    'PR_design', PR_design, 'Eff_design', Eff_design, ...
                    'surge_MFP', sorted_surge_MFP, 'surge_PR_sorted', sorted_surge_PR, ...
                    'compressor_type', label, 'n_rows', numel(rows), 'row_names', {{rows.name}});
                results = app.postprocess_results(results);   % corrected flow, stability limit, Greitzer B
                results.row_detail = app.collect_row_detail(ev, results, m_dot_design);
            catch ME
                uialert(app.UIFigure, sprintf('Computation error: %s', ME.message), 'Computation Error');
                results = [];
            end
        end

        function [M, status] = calculate_M_scalar(app, m_dot, R, Tt, A, Pt, alpha_rad, gamma)
            % Subsonic Mach number at a station from its mass-flow parameter
            %   MFP = m_dot*sqrt(R*Tt)/(A*Pt*cos(alpha)) = sqrt(gamma)*M*(1+(gamma-1)/2*M^2)^(-(gamma+1)/(2*(gamma-1)))
            % Tt, Pt, alpha are taken in the frame of the blade row (relative
            % for a rotor exit, absolute otherwise), so the test below is the
            % choking condition of that row in its own frame.
            % status: 'ok'      - subsonic solution found
            %         'choked'  - MFP above its sonic maximum (M = 1): this area
            %                     cannot pass the requested mass flow
            %         'invalid' - non-physical state (Pt <= 0, |alpha| >= 90 deg, ...)
            M = nan;
            status = 'invalid';
            if m_dot <= 0 || ~isreal(Tt) || ~isreal(Pt) || Tt <= 0 || Pt <= 0 || A <= 0
                return;
            end
            MFP = (m_dot * sqrt(R*Tt)) / (A * Pt * cos(alpha_rad));
            if ~isreal(MFP) || ~isfinite(MFP) || MFP <= 0
                return;
            end
            mfp_of_M = @(x) sqrt(gamma)*x.*(1 + (gamma-1)/2*x.^2).^(-(gamma+1)/(2*(gamma-1)));
            MFP_sonic = mfp_of_M(1);          % = 0.6847 for gamma = 1.4
            if MFP > MFP_sonic
                status = 'choked';
                return;
            end
            % Bracketed solve on the subsonic branch [0, 1]: f(0) > 0 >= f(1),
            % so it always converges and can never jump to the supersonic root
            M = fzero(@(x) MFP - mfp_of_M(x), [0, 1]);
            status = 'ok';
        end

        function [PR, Eff, fail_row, fail_type] = point_failed(app, fail_row, fail_type)
            % Outputs of a single-point evaluation that could not be completed
            PR = NaN;
            Eff = NaN;
        end

        function [m_choke, PR_choke, Eff_choke, row_choke] = find_choke_point(app, evalfun, m_lo, m_hi)
            % Exact choke mass flow of one speed line, by bisection.
            %   evalfun(m) -> [PR, Eff, fail_row, fail_type] at mass flow m
            %   m_lo : a mass flow that can be computed
            %   m_hi : a larger mass flow that cannot
            % The bracket is used only if the failure at m_hi is a choke (some
            % blade row would need M > 1 in its own frame); otherwise NaN/'' is
            % returned. Converges to 1e-6 relative accuracy in mass flow.
            m_choke = NaN; PR_choke = NaN; Eff_choke = NaN; row_choke = '';
            [~, ~, row_hi, type_hi] = evalfun(m_hi);
            if ~strcmp(type_hi, 'choked')
                return;
            end
            while (m_hi - m_lo) > 1e-6*m_hi
                m_mid = 0.5*(m_lo + m_hi);
                [PR_mid, ~, row_mid, type_mid] = evalfun(m_mid);
                if isempty(type_mid) && isfinite(PR_mid)
                    m_lo = m_mid;
                else
                    m_hi = m_mid;
                    if strcmp(type_mid, 'choked')
                        row_hi = row_mid;
                    end
                end
            end
            [PR_choke, Eff_choke] = evalfun(m_lo);
            m_choke = m_lo;
            row_choke = row_hi;
        end

        function m_max = find_max_flow(app, evalfun, m_dot_design)
            % Choke (maximum) mass flow of one speed line: march from
            % 0.5*m_design to 3*m_design in steps of 0.5% of m_design, take the
            % last computable point, then refine with find_choke_point. Used on
            % the fastest speed line to size the mass-flow grid.
            m_grid = m_dot_design*(0.5:0.005:3);
            ok = false(size(m_grid));
            for i = 1:numel(m_grid)
                [PR_i, ~, ~, type_i] = evalfun(m_grid(i));
                ok(i) = isempty(type_i) && isfinite(PR_i);
            end
            i_last = find(ok, 1, 'last');
            m_max = NaN;
            if ~isempty(i_last) && i_last < numel(m_grid)
                m_max = app.find_choke_point(evalfun, m_grid(i_last), m_grid(i_last+1));
            end
        end

        function print_choke_table(app, speed_ratio, choke_m, choke_MFP, choke_PR, choke_Eff, choke_row, in_region)
            % Command-window table of the choke point of every speed line
            fprintf('\nChoke points (first blade row reaching M = 1 in its own frame; bisection to 1e-6 in mass flow):\n');
            fprintf('  N/N_des   m_choke [kg/s]   MFP_1     PR      Eff     choking row\n');
            for k = 1:numel(choke_m)
                if isnan(choke_m(k))
                    fprintf('  %6.3f    no choke found within the computed range\n', speed_ratio(k));
                elseif in_region(k)
                    fprintf('  %6.3f    %10.5f     %7.4f  %6.3f  %6.3f   %s\n', speed_ratio(k), choke_m(k), ...
                        choke_MFP(k), real(choke_PR(k)), real(choke_Eff(k)), choke_row{k});
                else
                    fprintf('  %6.3f    %10.5f     %7.4f  %6.3f     -     %s  [PR <= 1: speed line crosses PR = 1 before choking]\n', ...
                        speed_ratio(k), choke_m(k), choke_MFP(k), real(choke_PR(k)), choke_row{k});
                end
            end
        end
        
        
        function [m_s, PR_s, Eff_s, row_s] = find_stall_point(app, evalfun, m_grid, PR_line, Eff_line)
            % Stall onset on one speed line - Howell's criterion: the first blade
            % row whose profile loss reaches TWICE its minimum value at positive
            % incidence (the minimum is the design-point loss, to which the loss
            % bucket is anchored). The loss ratio grows as the flow is reduced, so
            % the onset is the crossing of loss ratio = 2 on the line:
            %  - normally it lies at lower flow than the best-efficiency point;
            %  - at part speed the front row can already exceed the criterion at
            %    the best-efficiency point, then the crossing lies at higher flow.
            % The crossing is bracketed on the computed grid (compressor region
            % only: PR > 1, 0.1 < Eff < 1) and refined by bisection to 1e-6.
            %   evalfun(m) -> [PR, Eff, fail_row, fail_type, loss_ratio, stall_row]
            m_s = NaN; PR_s = NaN; Eff_s = NaN; row_s = '';
            drawn = ~isnan(PR_line) & real(PR_line) > 1 & real(Eff_line) > 0.1 & real(Eff_line) < 1;
            if ~any(drawn)
                return;
            end
            E = real(Eff_line);
            E(~drawn) = -Inf;
            [~, j0] = max(E);                            % best-efficiency point of the line
            [~, ~, ~, ~, ratio_0, row_0] = evalfun(m_grid(j0));
            if isnan(ratio_0)
                return;
            end
            j_st = NaN;                                  % grid index on the stalled side
            if ratio_0 < app.howell_factor
                for j = j0-1:-1:1                        % walk towards lower flow
                    if isnan(PR_line(j))
                        break;
                    end
                    [~, ~, ~, type_j, ratio_j] = evalfun(m_grid(j));
                    if ~isempty(type_j)
                        break;
                    end
                    if ratio_j >= app.howell_factor
                        j_st = j;
                        break;
                    end
                end
            else
                for j = j0+1:numel(m_grid)               % walk towards higher flow
                    if ~drawn(j)
                        break;
                    end
                    [~, ~, ~, type_j, ratio_j] = evalfun(m_grid(j));
                    if ~isempty(type_j)
                        break;
                    end
                    if ratio_j < app.howell_factor
                        j_st = j - 1;
                        break;
                    end
                end
                if isnan(j_st)
                    % the criterion is exceeded from the best-efficiency point up to
                    % the end of the line (choke): the whole line lies beyond onset
                    row_s = ['BEYOND|' row_0];
                    return;
                end
            end
            if isnan(j_st)
                return;
            end
            m_lo = m_grid(j_st);                         % loss ratio >= 2 (stalled side)
            m_hi = m_grid(j_st + 1);                     % loss ratio <  2
            while (m_hi - m_lo) > 1e-6*m_hi
                m_mid = 0.5*(m_lo + m_hi);
                [~, ~, ~, type_m, ratio_m] = evalfun(m_mid);
                if isempty(type_m) && ratio_m < app.howell_factor
                    m_hi = m_mid;
                else
                    m_lo = m_mid;
                end
            end
            [PR_s, Eff_s, ~, ~, ~, row_s] = evalfun(m_lo);
            m_s = m_lo;
            if ~(real(PR_s) > 1)                         % outside the compressor region
                m_s = NaN; PR_s = NaN; Eff_s = NaN; row_s = '';
            end
        end

        function print_stall_table(app, speed_ratio, stall_m, stall_PR, stall_Eff, stall_row)
            % Command-window table of the stall-onset point of every speed line
            fprintf('\nStall onset (Howell: first blade row whose loss reaches %gx its design value at positive incidence):\n', app.howell_factor);
            fprintf('  N/N_des   m_stall [kg/s]     PR      Eff     stalling row\n');
            for k = 1:numel(stall_m)
                if isnan(stall_m(k)) && strncmp(stall_row{k}, 'BEYOND|', 7)
                    fprintf('  %6.3f    beyond onset on the whole computed line (%s above the Howell limit up to choke)\n', ...
                        speed_ratio(k), stall_row{k}(8:end));
                elseif isnan(stall_m(k))
                    fprintf('  %6.3f    not reached on the computed part of the line\n', speed_ratio(k));
                else
                    fprintf('  %6.3f    %10.5f     %6.3f  %6.3f   %s\n', speed_ratio(k), stall_m(k), ...
                        real(stall_PR(k)), real(stall_Eff(k)), stall_row{k});
                end
            end
        end

        function [m_pk, PR_pk, Eff_pk] = find_peak_point(app, evalfun, m_grid, PR_line, j)
            % Exact peak (zero slope) of one speed line = the FIRST local maximum met
            % when the line is throttled from its high-flow end (the global maximum
            % can sit on a post-stall branch at very low flow and is not the
            % stability limit). The grid peak is refined on [m(j-1), m(j+1)] by
            % golden-section search to 1e-6 relative in mass flow. A peak on the
            % low-flow edge of the computed line is not a true peak -> NaN.
            % (Input j is not used any more; kept so the calls stay unchanged.)
            % The result is never below the grid value.
            m_pk = NaN; PR_pk = NaN; Eff_pk = NaN;
            jr = find(~isnan(PR_line), 1, 'last');       % last computed point (choke side)
            if isempty(jr)
                return;
            end
            j = jr;
            while j > 1 && ~isnan(PR_line(j-1)) && PR_line(j-1) >= PR_line(j)
                j = j - 1;                               % PR still rising on throttling
            end
            if j == 1 || isnan(PR_line(j-1))             % reached the low-flow edge: no true peak
                return;
            end
            if j == jr                                   % peak at the last computed point: keep grid value
                m_pk = m_grid(j); [PR_pk, Eff_pk] = evalfun(m_pk);
                return;
            end
            f = @(m) app.pr_or_minus_inf(evalfun, m);
            a = m_grid(j-1); b = m_grid(j+1);
            gr = (sqrt(5) - 1)/2;
            c = b - gr*(b - a); d = a + gr*(b - a);
            fc = f(c); fd = f(d);
            while (b - a) > 1e-6*b
                if fc >= fd
                    b = d; d = c; fd = fc;
                    c = b - gr*(b - a); fc = f(c);
                else
                    a = c; c = d; fc = fd;
                    d = a + gr*(b - a); fd = f(d);
                end
            end
            m_pk = 0.5*(a + b); PR_pk = f(m_pk);
            if ~(PR_pk >= PR_line(j))                    % safety: never worse than the grid peak
                m_pk = m_grid(j);
            end
            [PR_pk, Eff_pk] = evalfun(m_pk);
        end

        function r = koch_row(app, name, p_in, T_in, Vin, Vup, U_up, U_row, p_out)
            % One blade row for the Koch criterion. No argument -> empty struct array.
            % Vin: row inlet velocity in the row's own frame [Vx, Vtheta];
            % Vup: exit velocity of the upstream row (or inlet flow) in ITS frame;
            % U_up / U_row: frame speeds (0 = stationary), theta+ = rotation direction.
            if nargin == 1
                r = struct('name', {}, 'p_in', {}, 'T_in', {}, 'Vin', {}, 'Vup', {}, ...
                           'U_up', {}, 'U_row', {}, 'p_out', {});
                return;
            end
            r = struct('name', name, 'p_in', p_in, 'T_in', T_in, 'Vin', Vin, 'Vup', Vup, ...
                       'U_up', U_up, 'U_row', U_row, 'p_out', p_out);
        end

        function kg = koch_geometry(app, rows)
            % Blade-row geometry for Koch's criterion: L/g2 of every row and the
            % stage grouping (any number of rows). Returns [] (Koch skipped) if the
            % .mat has no solidities/chord. L = meanline length of a circular-arc
            % blade, g2 = s*cos(exit metal angle): L/g2 = (L/c)*sigma/cos(beta_out').
            % Solidities may be scalars or one value per row of their group:
            %   Rotor-Stator: sigma_rotor (per stage), sigma_stator (per stator)
            %   Rotor-Rotor : sigma_1 (odd rotors), sigma_2 (even rotors)
            % Groups ("stages" for Koch): rotor + stator; for rotor-rotor, rotor pairs
            % (R1+R2, R3+R4, ...) and a last single rotor when the number is odd.
            kg = [];
            d = app.loadedData;
            if ~isstruct(d) || ~isfield(d, 'chord'), return; end
            if nargin < 2, rows = app.row_model(); end
            isRS = strcmp(app.Compressor_type, 'Rotor-Stator');
            if isRS
                if ~(isfield(d, 'sigma_rotor') && isfield(d, 'sigma_stator')), return; end
                sg_names = {'sigma_rotor', 'sigma_stator'};
            else
                if ~(isfield(d, 'sigma_1') && isfield(d, 'sigma_2')), return; end
                sg_names = {'sigma_1', 'sigma_2'};
            end
            nrow = numel(rows);
            names = {rows.kname};
            LG = zeros(1, nrow); SG = zeros(1, nrow);
            for q = 1:nrow
                grp = rows(q).group;
                cnt = sum([rows.group] == grp);
                SG(q) = app.per_row(double(d.(sg_names{grp})), rows(q).gi, cnt, sg_names{grp}, 'row of its group');
                LG(q) = app.koch_L_over_g2(rows(q).b_in, rows(q).b_out, SG(q));
            end
            groups = {}; glabel = {};
            if isRS
                for st = unique([rows.stage])
                    idx = find([rows.stage] == st);
                    groups{end+1} = idx;
                    if numel(idx) == 2
                        glabel{end+1} = sprintf('Stage %d (R%d+S%d)', st, st, st);
                    else
                        glabel{end+1} = sprintf('Stage %d (R%d only)', st, st);
                    end
                end
            else
                for q = 1:2:nrow
                    if q < nrow
                        groups{end+1} = [q, q + 1]; glabel{end+1} = sprintf('Rotors R%d+R%d', q, q + 1);
                    else
                        groups{end+1} = q; glabel{end+1} = sprintf('Rotor R%d (single)', q);
                    end
                end
            end
            app.koch_Fef_seen = [];
            eg = app.koch_eps_over_g; dz = app.koch_dz_over_s;
            if isfield(d, 'eps_over_g'), eg = double(d.eps_over_g); end
            if isfield(d, 'dz_over_s'),  dz = double(d.dz_over_s);  end
            kg = struct('names', {names}, 'L_g2', LG, 'sigma', SG, 'groups', {groups}, 'labels', {glabel}, ...
                        'chord', double(d.chord), 'eps_over_g', eg, 'dz_over_s', dz);
        end

        function LG = koch_L_over_g2(app, b_in, b_out, sigma)
            % L/g2 of a circular-arc blade row (angles in degrees from axial)
            phi = abs(b_in - b_out)*pi/180;                   % camber
            if phi < 1e-6, Lc = 1; else, Lc = (phi/2)/sin(phi/2); end
            LG = Lc*sigma/cos(b_out*pi/180);
        end

        function [ratio, label, Ch_ef, Ch_max, Fef] = koch_ratio(app, kst, kg)
            % Koch (1981): stage enthalpy-equivalent static-pressure-rise coefficient
            % with the EFFECTIVE dynamic head, divided by its stalling value.
            %   Ch_ef = cp*t1*((p2/p1)^((g-1)/g) - 1) / sum(V_ef^2/2)
            %   V_ef^2 = (V^2 + 2.5*Vmin^2 + 0.5*V0^2)/4   (Koch Fig. 13)
            %   Vmin = lowest inlet velocity that upstream wakes can reach in this
            %          row's frame, V0 = frame-speed difference to the upstream row.
            %   Ch_max = C(L/g2) * f_Re(Re) * f_eps(eps/g) * f_dz(dz/s)
            % C(L/g2): Koch Fig. 15 (2-D diffuser, 9% blockage), f_*: Figs. 4-6,
            % digitized. Stage averages weighted by the row inlet dynamic heads.
            gamma = 1.4; R = 287; cp = gamma*R/(gamma-1);
            ng = numel(kg.groups);
            Ch_ef = nan(ng, 1); Ch_max = nan(ng, 1); r = nan(ng, 1);
            Fef = nan(1, numel(kst));               % effective dynamic-pressure factor of every row
            for g = 1:ng
                idx = kg.groups{g};
                if max(idx) > numel(kst), continue; end
                p1 = kst(idx(1)).p_in; t1 = kst(idx(1)).T_in; p2 = kst(idx(end)).p_out;
                num = cp*t1*((p2/p1)^((gamma-1)/gamma) - 1);
                den = 0; wsum = 0; LGs = 0; Res = 0;
                for j = idx
                    rw = kst(j);
                    V2 = sum(rw.Vin.^2);
                    dU = rw.U_up - rw.U_row;              % frame-speed difference
                    a = sum(rw.Vup.^2); b = 2*rw.Vup(2)*dU; c = dU^2;
                    kk = min(max(-b/(2*a), 0), 1);         % k*Vup + dU*e_theta, k in [0,1]
                    Vmin2 = max(a*kk^2 + b*kk + c, 0);
                    den = den + 0.5*(V2 + 2.5*Vmin2 + 0.5*dU^2)/4;
                    Fef(j) = (V2 + 2.5*Vmin2 + 0.5*dU^2)/(4*V2);
                    rho = rw.p_in/(R*rw.T_in);
                    mu = 1.716e-5*(rw.T_in/273.15)^1.5*(273.15 + 110.4)/(rw.T_in + 110.4);   % Sutherland
                    Res = Res + V2*rho*sqrt(V2)*kg.chord/mu;
                    LGs = LGs + V2*kg.L_g2(j);
                    wsum = wsum + V2;
                end
                LGst = LGs/wsum; Rest = Res/wsum;
                Ch_ef(g) = num/den;
                Ch_max(g) = app.koch_curve(LGst)*app.koch_f_re(Rest)*app.koch_f_eps(kg.eps_over_g)*app.koch_f_dz(kg.dz_over_s);
                r(g) = Ch_ef(g)/Ch_max(g);
            end
            [ratio, gi] = max(r);
            if isnan(ratio), label = ''; else, label = kg.labels{gi}; end
        end

        function C = koch_curve(app, LG)
            % Koch (1981) Fig. 15: stalling effective static-pressure-rise coefficient
            % vs L/g2 (2-D diffuser correlation of Sovran & Klomp, 9% blockage),
            % digitized 0.3 <= L/g2 <= 2.8 and fitted (max. deviation 0.0035).
            x = log(min(max(LG, 0.3), 2.8));
            C = -0.01267111*x^3 + 0.01200204*x^2 + 0.19447772*x + 0.39380675;
        end

        function f = koch_f_re(app, Re)
            % Koch Fig. 4: Ch/Ch(Re = 1.3e5) vs Reynolds number (chord, inlet velocity)
            ReT = [0.1 0.12 0.15 0.2 0.25 0.3 0.4 0.5 0.6 0.8 1.0 1.3 1.6 2 3 4 6 8 10]*1e5;
            fT  = [0.820 0.851 0.873 0.902 0.920 0.935 0.959 0.970 0.977 0.987 0.9945 1.000 1.008 1.012 1.020 1.026 1.034 1.039 1.042];
            f = interp1(log10(ReT), fT, log10(min(max(Re, ReT(1)), ReT(end))));
        end

        function f = koch_f_eps(app, eg)
            % Koch Fig. 5: Ch/Ch(eps/g = 0.055) vs tip clearance / staggered spacing
            eT = [0 0.003 0.01 0.015 0.02 0.03 0.04 0.055 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15];
            fT = [1.225 1.190 1.149 1.109 1.089 1.060 1.033 1.000 0.970 0.952 0.936 0.920 0.905 0.892 0.877 0.864 0.852];
            f = interp1(eT, fT, min(max(eg, 0), 0.15));
        end

        function f = koch_f_dz(app, dz)
            % Koch Fig. 6: Ch/Ch(dz/s = 0.38) vs axial gap / blade pitch
            zT = [0.03 0.05 0.08 0.10 0.15 0.20 0.25 0.30 0.35 0.38 0.45 0.50 0.55 0.60 0.70 0.80];
            fT = [1.099 1.089 1.074 1.066 1.045 1.030 1.018 1.009 1.003 1.000 0.995 0.993 0.992 0.991 0.9905 0.991];
            f = interp1(zT, fT, min(max(dz, 0.03), 0.8));
        end

        function [ratio, label, Fef] = koch_eval(app, evalfun, kg, m)
            % Koch ratio (Ch_ef/Ch_max, stall at 1) of one operating point; NaN if it fails
            [~, ~, ~, ftype, ~, ~, kst] = evalfun(m);
            if ~isempty(ftype)
                ratio = NaN; label = ''; Fef = []; return;
            end
            [ratio, label, ~, ~, Fef] = app.koch_ratio(kst, kg);
        end

        function [m_s, PR_s, Eff_s, lab_s] = find_koch_point(app, evalfun, kg, m_grid, PR_line, Eff_line)
            % Koch stall limit on one speed line: crossing of Ch_ef/Ch_max = 1,
            % bracketed on the computed grid from the best-efficiency point (same
            % logic as the Howell search) and refined by bisection to 1e-6.
            m_s = NaN; PR_s = NaN; Eff_s = NaN; lab_s = '';
            drawn = ~isnan(PR_line) & real(PR_line) > 1 & real(Eff_line) > 0.1 & real(Eff_line) < 1;
            if ~any(drawn), return; end
            E = real(Eff_line); E(~drawn) = -Inf;
            [~, j0] = max(E);
            [r0, lab0, F0] = app.koch_eval(evalfun, kg, m_grid(j0));
            if isnan(r0), return; end
            j_st = NaN;
            if r0 < 1
                for j = j0-1:-1:1                        % towards lower flow
                    if isnan(PR_line(j)), break; end
                    rj = app.koch_eval(evalfun, kg, m_grid(j));
                    if isnan(rj), break; end
                    if rj >= 1, j_st = j; break; end
                end
            else
                for j = j0+1:numel(m_grid)               % towards higher flow
                    if ~drawn(j), break; end
                    rj = app.koch_eval(evalfun, kg, m_grid(j));
                    if isnan(rj), break; end
                    if rj < 1, j_st = j - 1; break; end
                end
                if isnan(j_st)
                    lab_s = ['BEYOND|' lab0];              % above the limit up to choke
                    app.koch_Fef_seen = [app.koch_Fef_seen, F0];
                    return;
                end
            end
            if isnan(j_st), return; end
            m_lo = m_grid(j_st); m_hi = m_grid(j_st + 1);
            while (m_hi - m_lo) > 1e-6*m_hi
                m_mid = 0.5*(m_lo + m_hi);
                rm = app.koch_eval(evalfun, kg, m_mid);
                if ~isnan(rm) && rm < 1, m_hi = m_mid; else, m_lo = m_mid; end
            end
            [~, lab_s, Fs] = app.koch_eval(evalfun, kg, m_lo);
            app.koch_Fef_seen = [app.koch_Fef_seen, Fs];
            [PR_s, Eff_s] = evalfun(m_lo);
            m_s = m_lo;
            if ~(real(PR_s) > 1)
                m_s = NaN; PR_s = NaN; Eff_s = NaN; lab_s = '';
            end
        end

        function print_koch_table(app, speed_ratio, km, kPR, kEff, kstage, kg)
            % Command-window table of the Koch stall limit of every speed line
            if isempty(kg)
                fprintf('\nKoch stall limit: skipped (the .mat has no row solidities + chord: sigma_rotor/sigma_stator or sigma_1/sigma_2, chord)\n');
                return;
            end
            fprintf('\nKoch (1981) stage stall limit (Ch_ef = Ch_max; eps/g = %.3f, dz/s = %.2f):\n', kg.eps_over_g, kg.dz_over_s);
            rl = [kg.names; num2cell(kg.L_g2)];
            fprintf('  rows:'); fprintf('  %s L/g2 = %.3f', rl{:}); fprintf('\n');
            fprintf('  N/N_des   m_Koch [kg/s]     PR      Eff     limiting stage\n');
            for k = 1:numel(km)
                if isnan(km(k)) && strncmp(kstage{k}, 'BEYOND|', 7)
                    fprintf('  %6.3f    beyond the Koch limit on the whole computed line (%s)\n', speed_ratio(k), kstage{k}(8:end));
                elseif isnan(km(k))
                    fprintf('  %6.3f    not reached on the computed part of the line\n', speed_ratio(k));
                else
                    fprintf('  %6.3f    %10.5f     %6.3f  %6.3f   %s\n', speed_ratio(k), km(k), real(kPR(k)), real(kEff(k)), kstage{k});
                end
            end
            % range of validity of the correlation (Koch 1981 data)
            LGr = [min(kg.L_g2), max(kg.L_g2)];
            msg = sprintf('  validity: L/g2 = %.2f-%.2f (Koch data about 0.6-2.2)', LGr(1), LGr(2));
            out = LGr(1) < 0.6 || LGr(2) > 2.2;
            F = app.koch_Fef_seen(~isnan(app.koch_Fef_seen));
            if ~isempty(F)
                msg = [msg, sprintf(', F_ef at the limit = %.2f-%.2f (Koch data 0.39-1.11)', min(F), max(F))];
                out = out || min(F) < 0.39 || max(F) > 1.11;
            end
            if out, msg = [msg, '  -> outside the data: EXTRAPOLATED']; end
            fprintf('%s\n', msg);
        end

        function plot_koch_limit(app, ax, results, mode)
            % Koch stall limit on a PR map: mode 'MFP' (non-dimensional) or 'relative'
            if ~isfield(results, 'koch_points') || ~any(~isnan(results.koch_points)), return; end
            if strcmp(mode, 'auto')                  % mass-flow axis or MFP axis
                if ~isempty(strfind(lower(get(get(ax, 'XLabel'), 'String')), 'mass flow')), mode = 'mass'; else, mode = 'MFP'; end
            end
            v = ~isnan(results.koch_points);
            x = results.koch_points(v);              % mass flow
            y = real(results.koch_PR(v));
            if ~strcmp(mode, 'mass')
                x = x*results.MFP1_design/app.m_dot;  % MFP is proportional to the mass flow
            end
            if strcmp(mode, 'relative')
                x = x/results.MFP1_design; y = y/results.PR_design;
            end
            [x, o] = sort(x); y = y(o);
            plot(ax, x, y, '-^', 'Color', [0 0.5 0], 'MarkerFaceColor', [0.2 0.8 0.2], ...
                'MarkerEdgeColor', 'k', 'MarkerSize', 8, 'LineWidth', 2, 'Tag', 'KochLimit', ...
                'DisplayName', 'Koch Stall Limit');
        end

        function S = koch_stage_details(app, kst, kg)
            % Koch quantities of every stage at one operating point (see koch_ratio)
            gamma = 1.4; R = 287; cp = gamma*R/(gamma-1);
            S = struct('label', {}, 'rows', {}, 'Fef', {}, 'LG', {}, 'Re', {}, 'fRe', {}, ...
                       'feps', {}, 'fdz', {}, 'num', {}, 'den', {}, 'denV2', {}, 'Ch_ef', {}, ...
                       'Ch_max', {}, 'ratio', {});
            for g = 1:numel(kg.groups)
                idx = kg.groups{g};
                if max(idx) > numel(kst), continue; end
                p1 = kst(idx(1)).p_in; t1 = kst(idx(1)).T_in; p2 = kst(idx(end)).p_out;
                num = cp*t1*((p2/p1)^((gamma-1)/gamma) - 1);
                den = 0; denV2 = zeros(1, numel(idx)); wsum = 0; LGs = 0; Res = 0; F = zeros(1, numel(idx));
                for q = 1:numel(idx)
                    rw = kst(idx(q));
                    V2 = sum(rw.Vin.^2);
                    dU = rw.U_up - rw.U_row;
                    a = sum(rw.Vup.^2); b = 2*rw.Vup(2)*dU; c = dU^2;
                    kk = min(max(-b/(2*a), 0), 1);
                    Vmin2 = max(a*kk^2 + b*kk + c, 0);
                    Vef2 = (V2 + 2.5*Vmin2 + 0.5*dU^2)/4;
                    den = den + 0.5*Vef2; denV2(q) = 0.5*V2; F(q) = Vef2/V2;
                    rho = rw.p_in/(R*rw.T_in);
                    mu = 1.716e-5*(rw.T_in/273.15)^1.5*(273.15 + 110.4)/(rw.T_in + 110.4);
                    Res = Res + V2*rho*sqrt(V2)*kg.chord/mu;
                    LGs = LGs + V2*kg.L_g2(idx(q));
                    wsum = wsum + V2;
                end
                st.label = kg.labels{g}; st.rows = idx; st.Fef = F;
                st.LG = LGs/wsum; st.Re = Res/wsum;
                st.fRe = app.koch_f_re(st.Re); st.feps = app.koch_f_eps(kg.eps_over_g); st.fdz = app.koch_f_dz(kg.dz_over_s);
                st.num = num; st.den = den; st.denV2 = denV2;
                st.Ch_ef = num/den;
                st.Ch_max = app.koch_curve(st.LG)*st.fRe*st.feps*st.fdz;
                st.ratio = st.Ch_ef/st.Ch_max;
                S(end+1) = st;
            end
        end

        function KD = koch_design_check(app, kst, kg)
            % Koch check of the DESIGN point with quantified design advice.
            % Ratio Ch_ef/Ch_max: <= target -> OK, target..1 -> low margin, > 1 -> beyond
            % the stall limit already at design. For a stage above the target the
            % advice gives what would bring it back: solidity (L/g2), stage loading,
            % tip clearance, axial gap, effective dynamic head, Reynolds number.
            KD = struct('label', {}, 'ratio', {}, 'Ch_ef', {}, 'Ch_max', {}, 'LG', {}, ...
                        'Fef', {}, 'Re', {}, 'status', {}, 'advice', {});
            if isempty(kg) || isempty(kst), return; end
            tgt = app.koch_target_ratio;
            d = app.loadedData;
            S = app.koch_stage_details(kst, kg);
            for g = 1:numel(S)
                s = S(g); adv = {};
                if s.ratio <= tgt
                    status = sprintf('OK (Ch_ef/Ch_max = %.2f <= target %.2f)', s.ratio, tgt);
                elseif s.ratio <= 1
                    status = sprintf('LOW MARGIN (%.2f, target %.2f)', s.ratio, tgt);
                else
                    status = sprintf('BEYOND THE LIMIT AT DESIGN (%.2f)', s.ratio);
                end
                if s.ratio > tgt || s.ratio < tgt - 0.10
                    % (1) solidity: stage L/g2 that gives Ch_max = Ch_ef/target
                    %     (L/g2 is proportional to the solidity of every row)
                    need = s.Ch_ef/tgt/(s.fRe*s.feps*s.fdz);
                    if need > app.koch_curve(2.8)
                        adv{end+1} = 'solidity alone cannot reach the target (L/g2 > 2.8 would be needed)';
                    elseif need >= app.koch_curve(0.3)
                        lo = 0.3; hi = 2.8;
                        for it = 1:60
                            mid = 0.5*(lo + hi);
                            if app.koch_curve(mid) < need, lo = mid; else, hi = mid; end
                        end
                        fac = hi/s.LG;
                        sig_txt = {}; sig_new = [];
                        for q = s.rows
                            sg = kg.sigma(q);
                            if ~isnan(sg)
                                sig_txt{end+1} = sprintf('%s %.2f -> %.2f', kg.names{q}, sg, sg*fac);
                                sig_new(end+1) = sg*fac;
                            end
                        end
                        if fac > 1, verb = 'RAISE the solidity'; else, verb = 'margin available: the solidity could be LOWERED'; end
                        a1 = sprintf('%s x%.2f (stage L/g2 %.2f -> %.2f): %s; re-run the design script with it (profile loss changes)', ...
                            verb, fac, s.LG, hi, strjoin(sig_txt, ', '));
                        if any(sig_new > 2)
                            a1 = [a1, '  [solidity above 2: outside the Carter/NACA-65 range of the design scripts]'];
                        end
                        if hi > 2.2 || hi < 0.6
                            a1 = [a1, '  [L/g2 outside Koch''s data 0.6-2.2]'];
                        end
                        adv{end+1} = a1;
                    end
                end
                if s.ratio < tgt - 0.10
                    adv{end+1} = sprintf('or RAISE the stage static-pressure rise by up to about %.0f%% before reaching the target', 100*(tgt/s.ratio - 1));
                end
                if s.ratio > tgt
                    % (2) stage loading
                    adv{end+1} = sprintf('or LOWER the stage static-pressure rise by about %.0f%% at the same velocities (lower loading psi or degree of reaction, or a larger flow coefficient)', 100*(1 - tgt/s.ratio));
                    % (3) tip clearance / axial gap
                    if kg.eps_over_g > 0.02
                        r_eps = s.ratio*s.feps/app.koch_f_eps(0.02);
                        adv{end+1} = sprintf('REDUCE the tip clearance to eps/g = 0.020 (now %.3f) -> ratio %.2f', kg.eps_over_g, r_eps);
                    end
                    if kg.dz_over_s > 0.10
                        r_dz = s.ratio*s.fdz/app.koch_f_dz(0.10);
                        adv{end+1} = sprintf('REDUCE the axial gap to dz/s = 0.10 (now %.2f) -> ratio %.2f', kg.dz_over_s, r_dz);
                    end
                    % (4) effective dynamic head of rows that cannot re-energize upstream wakes
                    for q = 1:numel(s.rows)
                        if s.Fef(q) < 0.6
                            den1 = s.den - (s.denV2(q)*s.Fef(q)) + s.denV2(q);   % this row with F_ef = 1
                            r1 = (s.num/den1)/s.Ch_max;
                            adv{end+1} = sprintf(['%s: effective dynamic-head factor F_ef = %.2f (upstream wakes enter in the same or a ' ...
                                'nearly equal frame and are not re-energized); with F_ef = 1 the ratio would be %.2f -> a stator ' ...
                                'between the rotors or a larger frame-speed difference (e.g. counter-rotation) helps'], ...
                                kg.names{s.rows(q)}, s.Fef(q), r1);
                        end
                    end
                    % (5) Reynolds number
                    if s.Re < 1.3e5
                        adv{end+1} = sprintf('Re = %.3g is below 1.3e5 (f_Re = %.3f): a LONGER chord raises Ch_max', s.Re, s.fRe);
                    end
                end
                % range of validity of Koch's data
                out = {};
                if s.LG < 0.6 || s.LG > 2.2, out{end+1} = sprintf('L/g2 = %.2f (data 0.6-2.2)', s.LG); end
                if any(s.Fef < 0.39) || any(s.Fef > 1.11)
                    out{end+1} = sprintf('F_ef = %s (data 0.39-1.11)', mat2str(round(s.Fef*100)/100));
                end
                if ~isempty(out)
                    adv{end+1} = ['note: outside Koch''s data: ', strjoin(out, ', '), ' -> indicative only'];
                end
                KD(end+1) = struct('label', s.label, 'ratio', s.ratio, 'Ch_ef', s.Ch_ef, 'Ch_max', s.Ch_max, ...
                                   'LG', s.LG, 'Fef', s.Fef, 'Re', s.Re, 'status', status, 'advice', {adv});
            end
        end

        function sg = koch_row_sigma(app, d, name)
            % Solidity of a blade row from the .mat (R*/S* for rotor-stator, R1/R2 for rotor-rotor)
            sg = NaN;
            if ~isstruct(d), return; end
            if strcmp(app.Compressor_type, 'Rotor-Stator')
                if name(1) == 'R' && isfield(d, 'sigma_rotor'),  sg = d.sigma_rotor;  end
                if name(1) == 'S' && isfield(d, 'sigma_stator'), sg = d.sigma_stator; end
            else
                if strcmp(name, 'R1') && isfield(d, 'sigma_1'), sg = d.sigma_1; end
                if strcmp(name, 'R2') && isfield(d, 'sigma_2'), sg = d.sigma_2; end
            end
        end

        function print_koch_design(app, KD)
            % Command-window report of the Koch check at the design point
            if isempty(KD), return; end
            fprintf('\nKoch check at the DESIGN point (target Ch_ef/Ch_max <= %.2f):\n', app.koch_target_ratio);
            for g = 1:numel(KD)
                fprintf('  %-20s Ch_ef = %.3f  Ch_max = %.3f  L/g2 = %.2f  F_ef = %s  ->  %s\n', KD(g).label, KD(g).Ch_ef, ...
                    KD(g).Ch_max, KD(g).LG, mat2str(round(KD(g).Fef*100)/100), KD(g).status);
                for a = 1:numel(KD(g).advice)
                    fprintf('      - %s\n', KD(g).advice{a});
                end
            end
        end

        function report_equations(app, eq_msgs, ax)
            % Boundary equations of one map: kept for the Equations tab; shown as a
            % popup only when the app has no Equations tab
            ttl = get(get(ax, 'Title'), 'String');
            if iscell(ttl), ttl = strjoin(ttl, ' '); end
            app.equation_log{end+1} = sprintf('==== %s ====\n%s', ttl, strjoin(eq_msgs, sprintf('\n\n')));
            if ~app.has_ui('EquationsTextArea')
                uialert(app.UIFigure, strjoin(eq_msgs, sprintf('\n\n')), 'Stability Boundary Equations');
            end
        end

        function ok = has_ui(app, name)
            % True if the app has a valid UI component with this name
            % (made in Design View or by build_results_ui)
            ok = false;
            try
                h = app.(name);
                ok = ~isempty(h) && all(isvalid(h));
            catch
            end
        end

        function build_results_ui(app)
            % Builds the Guide, Settings, Maps, Tables, Equations, Diagnostics and
            % Report tabs in code - no Design View work. Called once from startupFcn.
            % The tab group takes the place of the instructions panel, which moves
            % into the Guide tab. Skipped if a MainTabGroup already exists.
            if app.has_ui('MainTabGroup'), return; end
            W = 1044; H = 596;                              % tab group size [px]
            Wi = W - 4; Hi = H - 28;                        % usable area inside a tab
            mono = 'Courier New'; if ispc, mono = 'Consolas'; end

            app.MainTabGroup   = uitabgroup(app.UIFigure, 'Position', [430 2 W H]);
            app.GuideTab       = uitab(app.MainTabGroup, 'Title', 'Guide');
            app.SettingsTab    = uitab(app.MainTabGroup, 'Title', 'Settings');
            app.ModelTab       = uitab(app.MainTabGroup, 'Title', 'Model options');
            app.MapsTab        = uitab(app.MainTabGroup, 'Title', 'Maps');
            app.CompareTab     = uitab(app.MainTabGroup, 'Title', 'Compare');
            app.TablesTab      = uitab(app.MainTabGroup, 'Title', 'Tables');
            app.EquationsTab   = uitab(app.MainTabGroup, 'Title', 'Equations');
            app.DiagnosticsTab = uitab(app.MainTabGroup, 'Title', 'Diagnostics');
            app.ReportTab      = uitab(app.MainTabGroup, 'Title', 'Report');

            % ---------- Guide: How to use | Inputs | Flowchart ----------
            % guide_workflow.png, guide_inputs.png and guide_flowchart.png must sit
            % next to the app file. The flowchart image replaces the old Design-View
            % flowchart panel (which is hidden); without the image the old panel is shown.
            gtg = uitabgroup(app.GuideTab, 'Position', [0 0 Wi Hi]);
            here = fileparts(mfilename('fullpath'));
            pages = {'How to use', 'guide_workflow.png'; 'Inputs', 'guide_inputs.png'; ...
                     'Flowchart', 'guide_flowchart.png'};
            for k = 1:size(pages, 1)
                f = fullfile(here, pages{k, 2});
                if isfile(f)
                    t = uitab(gtg, 'Title', pages{k, 1});
                    uiimage(t, 'ImageSource', f, 'ScaleMethod', 'fit', 'Position', [2 2 Wi-6 Hi-32]);
                end
            end
            if app.has_ui('InstructionsPanel')
                if isfile(fullfile(here, 'guide_flowchart.png'))
                    app.InstructionsPanel.Visible = 'off';     % replaced by the new flowchart image
                else
                    t = uitab(gtg, 'Title', 'Flowchart (old)');
                    app.InstructionsPanel.Parent = t;
                    app.InstructionsPanel.Position = [0 0 Wi-2 Hi-28];
                end
            end

            % ---------- Settings (2 columns x 3 rows of panels) ----------
            pw = 505; ph = 178; xL = 10; xR = 527;
            yT = Hi - ph - 6; yM = yT - ph - 6; yB = yM - ph - 6;
            rw = [124 96 68 40];                              % field rows inside a panel
            grey = [0.35 0.35 0.35];
            p1 = uipanel(app.SettingsTab, 'Title', 'Off-design correlations', 'FontWeight', 'bold', 'Position', [xL yT pw ph]);
            uilabel(p1, 'Text', 'Correlation set', 'Position', [15 rw(1) 255 22]);
            app.CorrelationSetDropDown = uidropdown(p1, 'Items', {'polynomial', 'three-point', 'user'}, 'Position', [280 rw(1) 200 22], ...
                'Tooltip', 'polynomial: default loss/deviation fits | three-point: quadratic loss + spline deviation | user: loss_coeffs, dev_coeffs from the .mat');
            app.HowellFactorEditField = app.ui_num_field(p1, rw(2), 'Howell stall onset (x design loss)', [1.1 10], '%.2f', ...
                'Stall onset when the loss of a row reaches this multiple of its design (minimum) loss');
            app.BucketWidthEditField = app.ui_num_field(p1, rw(3), 'Loss-bucket width factor', [0.2 5], '%.2f', ...
                ['x = (i - i_des)/(factor x deflection). 1 = Howell normalisation (default); > 1 widens the loss bucket ' ...
                 'and the deviation curve (lightly loaded, low-deflection rows), < 1 narrows them']);
            uilabel(p1, 'Text', 'The "user" set needs loss_coeffs (6 values) and dev_coeffs (7 values) in the .mat file.', ...
                'WordWrap', 'on', 'FontColor', grey, 'Position', [15 4 470 34]);

            % ---------- Model options (steps 25-26): all off by default = the original model ----------
            pm = uipanel(app.ModelTab, 'Title', 'Off-design model options (all off = original model)', 'FontWeight', 'bold', ...
                'Position', [10 Hi-306 Wi-18 300]);
            ym = [246 192 138 84];                           % one option per row, its explanation on the right
            tx = @(y, t) uilabel(pm, 'Text', t, 'WordWrap', 'on', 'FontColor', grey, 'Position', [495 y-20 Wi-525 52]);
            app.BucketWidthNegEditField = app.ui_num_field(pm, ym(1), 'Choke-side bucket width (0 = same as Settings)', [0 5], '%.2f', ...
                'Bucket width on the high-flow side only. 0 = use Settings > Loss-bucket width factor on both sides.');
            tx(ym(1), ['Widens (> 1) or narrows (< 1) the loss bucket only on the high-flow side, where the air meets the ' ...
                'blades at negative incidence. Leave 0 to use the Settings width on both sides.']);
            app.MinRefDeflEditField = app.ui_num_field(pm, ym(2), 'Minimum reference deflection [deg] (0 = off)', [0 60], '%.1f', ...
                'Rows that turn the flow less than this angle are treated as if they turned this much. 0 = off.');
            tx(ym(2), ['The loss bucket is scaled by how much each row turns the flow. A row that turns it very little gets a ' ...
                'bucket narrower than real blades show. Rows turning less than this angle are treated as if they turned this ' ...
                'much; the others are not affected. Try 10-15 deg.']);
            app.BlockageEditField = app.ui_num_field(pm, ym(3), 'Choke area factor (1 = off)', [0.5 1], '%.3f', ...
                'A row chokes when its flow would need Mach 1 in this fraction of A_vec. 1 = off.');
            tx(ym(3), ['Real passages are narrower than the annulus (blade thickness, boundary layers), so they choke earlier. ' ...
                'A row chokes when its flow would need Mach 1 in this fraction of A_vec. Lower = earlier choke. Velocities still ' ...
                'use A_vec, so the design point does not change. Typical 0.93-0.99.']);
            app.ReExponentEditField = app.ui_num_field(pm, ym(4), 'Reynolds-correction exponent n (0 = off)', [0 1], '%.2f', ...
                'Loss x (Re/Re_design)^(-n) below Re = 2.5e5. Needs chord in the .mat. 0 = off.');
            tx(ym(4), ['Blade losses grow at low Reynolds number (small blades, low speed, low inlet pressure). The loss is ' ...
                'multiplied by (Re/Re_design)^(-n) below Re = 2.5e5. Typical n = 0.2. Needs chord in the .mat.']);
            uilabel(pm, 'Text', ['All four are off by default, so the app gives the original results. None of them changes the ' ...
                'design point (same design PR and efficiency); they only change the speed lines away from it. Use them for ' ...
                'the correlation-sensitivity study and say in your paper which ones you switched on. If the loaded .mat ' ...
                'contains bucket_width_neg, min_ref_deflection, blockage or re_exponent, that value is used and the field ' ...
                'is greyed out.'], 'WordWrap', 'on', 'Position', [15 6 Wi-50 54]);

            pv = uipanel(app.ModelTab, 'Title', 'Validation against measured data', 'FontWeight', 'bold', ...
                'Position', [10 Hi-462 Wi-18 150]);
            app.MeasSpeedsOnlyCheckBox = uicheckbox(pv, 'Text', 'Compute only the measured speed lines (plus N/N_des = 1)', ...
                'Position', [15 98 600 22], 'Tooltip', 'Clean maps for validation: one computed line per measured speed');
            uilabel(pv, 'Text', ['For a .mat that contains measured data (meas_N, meas_m, meas_PR, meas_eta). When ticked, the ' ...
                'maps show only the speeds that were measured, so every measured point sits on its own line, and the run is ' ...
                'faster. Not ticked: the usual speed lines of Settings > Run range plus the measured speeds. The errors are in ' ...
                'Diagnostics and in Tables > Validation summary / points / lines; Tables > Export all tables (Excel) saves them.'], ...
                'WordWrap', 'on', 'FontColor', grey, 'Position', [15 8 Wi-50 80]);

            p2 = uipanel(app.SettingsTab, 'Title', 'Run range', 'FontWeight', 'bold', 'Position', [xR yT pw ph]);
            app.NminEditField = app.ui_num_field(p2, rw(1), 'Lowest speed N/N_des', [0.2 0.99], '%.2f', 'Slowest speed line');
            app.NmaxEditField = app.ui_num_field(p2, rw(2), 'Highest speed N/N_des', [1.01 1.6], '%.2f', 'Fastest speed line');
            app.NspeedEditField = app.ui_num_field(p2, rw(3), 'Number of speed lines', [3 40], '%.0f', 'N/N_des = 1 is added if it is not on the grid');
            app.MdensEditField = app.ui_num_field(p2, rw(4), 'Mass-flow points (per 0.7 m_des)', [30 600], '%.0f', ...
                'Grid density of every speed line; more points = smoother maps and a longer run');
            app.NspeedEditField.RoundFractionalValues = 'on';
            app.MdensEditField.RoundFractionalValues = 'on';
            uilabel(p2, 'Text', 'Default: 0.50 to 1.20, 15 lines, 100 points. N/N_des = 1 is always computed.', ...
                'WordWrap', 'on', 'FontColor', grey, 'Position', [15 4 470 32]);

            p3 = uipanel(app.SettingsTab, 'Title', 'Koch (1981) stage-loading indicator', 'FontWeight', 'bold', 'Position', [xL yM pw ph]);
            uilabel(p3, 'Text', 'Koch line on the maps', 'Position', [15 rw(1) 255 22]);
            app.KochModeDropDown = uidropdown(p3, 'Items', {'Auto (app decides)', 'Always show', 'Hide'}, 'Position', [280 rw(1) 200 22], ...
                'Tooltip', 'Auto: shown only when Koch''s data cover this design (Diagnostics says why). The Koch tables are always computed.');
            app.KochTargetEditField = app.ui_num_field(p3, rw(2), 'Design target Ch_ef/Ch_max', [0.3 1], '%.2f', ...
                'The Koch design check gives advice for stages above this ratio');
            app.KochEpsOverGEditField = app.ui_num_field(p3, rw(3), 'Tip clearance eps/g', [0 0.15], '%.3f', ...
                'Tip clearance / staggered spacing (Koch reference 0.055)');
            app.KochDzOverSEditField = app.ui_num_field(p3, rw(4), 'Axial gap dz/s', [0.03 0.8], '%.2f', ...
                'Axial gap / blade pitch (Koch reference 0.38)');
            uilabel(p3, 'Text', 'Indicator only: Koch never sets the stability limit.', ...
                'FontColor', grey, 'Position', [15 8 470 22]);

            p4 = uipanel(app.SettingsTab, 'Title', 'Surge or rotating stall (Greitzer B)', 'FontWeight', 'bold', 'Position', [xR yM pw ph]);
            app.BcritEditField = app.ui_num_field(p4, rw(1), 'B critical', [0.1 5], '%.2f', ...
                'B above this value: surge; below: rotating stall');
            app.VplenumEditField = app.ui_num_field(p4, rw(2), 'Plenum volume V_p [m^3]  (0 = not given)', [0 Inf], '%.4g', ...
                'Volume downstream of the compressor');
            app.LductEditField = app.ui_num_field(p4, rw(3), 'Duct length L_c [m]  (0 = not given)', [0 Inf], '%.4g', ...
                'Effective length of the compressor and its ducts');
            uilabel(p4, 'Text', 'Without V_p and L_c the app gives U/(2a_p) and the critical volume ratio V_p/(A_c L_c) above which the installation surges.', ...
                'WordWrap', 'on', 'FontColor', grey, 'Position', [15 4 470 46]);

            p5 = uipanel(app.SettingsTab, 'Title', 'Inlet and reference conditions', 'FontWeight', 'bold', 'Position', [xL yB pw ph]);
            app.TinEditField = app.ui_num_field(p5, rw(1), 'Design inlet Tt1 [K]', [150 1500], '%.2f', ...
                'Inlet total temperature of the design script (288 K in yours). A Tt1 saved in the .mat wins.');
            app.PinEditField = app.ui_num_field(p5, rw(2), 'Design inlet pt1 [Pa]', [1000 1e7], '%.0f', ...
                'Inlet total pressure of the design script (100000 Pa in yours). A Pt1 saved in the .mat wins.');
            app.TrefEditField = app.ui_num_field(p5, rw(3), 'Corrected map T_ref [K]', [150 400], '%.2f', 'Standard-day temperature (288.15 K)');
            app.PrefEditField = app.ui_num_field(p5, rw(4), 'Corrected map p_ref [Pa]', [1000 1e7], '%.0f', 'Standard-day pressure (101325 Pa)');
            uilabel(p5, 'Text', 'Tt1, pt1 must match the design script. T_ref, p_ref only rescale the Corrected map.', ...
                'WordWrap', 'on', 'FontColor', grey, 'Position', [15 4 470 32]);

            p6 = uipanel(app.SettingsTab, 'Title', 'Session and files', 'FontWeight', 'bold', 'Position', [xR yB pw ph]);
            app.SaveSessionButton = uibutton(p6, 'Text', 'Save session...', 'Position', [15 rw(1)-2 222 26], ...
                'Tooltip', 'Inputs, settings, results, report and comparisons in one .mat', ...
                'ButtonPushedFcn', @(~, ~) app.save_session());
            app.OpenSessionButton = uibutton(p6, 'Text', 'Open session...', 'Position', [258 rw(1)-2 222 26], ...
                'Tooltip', 'Restore a saved session (no recomputation)', ...
                'ButtonPushedFcn', @(~, ~) app.open_session());
            app.SaveInputsButton = uibutton(p6, 'Text', 'Save inputs as .mat (template)...', 'Position', [15 rw(2)-4 465 26], ...
                'Tooltip', 'The inputs of the chosen compressor type with the right variable names (Manual-tab values)', ...
                'ButtonPushedFcn', @(~, ~) app.save_inputs_template());
            uilabel(p6, 'Text', ['Settings are read each time you press Run. A greyed-out field is set by the loaded ' ...
                '.mat file (hover for details); Run uses exactly what you see.'], ...
                'WordWrap', 'on', 'FontColor', grey, 'Position', [15 4 470 52]);

            % ---------- Maps ----------
            app.MapsTabGroup = uitabgroup(app.MapsTab, 'Position', [0 36 Wi Hi-36]);
            maps = {'Standard', 'StdPRAxes', 'StdEffAxes'; 'Non-dimensional', 'NondimPRAxes', 'NondimEffAxes'; ...
                    'Relative', 'RelPRAxes', 'RelEffAxes'; 'Corrected', 'CorrPRAxes', 'CorrEffAxes'};
            aw = floor((Wi - 30)/2); ah = Hi - 36 - 28 - 20;
            for k = 1:size(maps, 1)
                t = uitab(app.MapsTabGroup, 'Title', maps{k, 1});
                app.(maps{k, 2}) = uiaxes(t, 'Position', [10 10 aw ah]);
                app.(maps{k, 3}) = uiaxes(t, 'Position', [20+aw 10 aw ah]);
            end
            app.ExportFiguresButton = uibutton(app.MapsTab, 'Text', 'Export maps (PNG)', 'Position', [10 5 150 26], ...
                'ButtonPushedFcn', @(~, ~) app.ui_export_figures());
            app.SeparateWindowsCheckBox = uicheckbox(app.MapsTab, 'Text', 'Separate windows', 'Position', [168 7 124 22], ...
                'Tooltip', 'Also open the maps in separate figure windows at the next Run');
            uilabel(app.MapsTab, 'Text', 'Show:', 'FontWeight', 'bold', 'Position', [296 7 42 22]);
            tg = {'ShowSpeedCheckBox', 'Speed lines', 86; 'ShowSurgeCheckBox', 'Surge (peak)', 96; ...
                  'ShowStallCheckBox', 'Stall onset (Howell)', 128; 'ShowChokeCheckBox', 'Choke', 62; ...
                  'ShowKochCheckBox', 'Koch', 150; 'ShowDesignCheckBox', 'Design point', 92; ...
                  'ShowMeasuredCheckBox', 'Measured', 82};
            x = 338;
            for k = 1:size(tg, 1)
                app.(tg{k, 1}) = uicheckbox(app.MapsTab, 'Text', tg{k, 2}, 'Value', true, 'Position', [x 7 tg{k, 3} 22], ...
                    'ValueChangedFcn', @(~, ~) app.apply_line_visibility());
                x = x + tg{k, 3};
            end

            % ---------- Compare (runs and configurations) ----------
            uilabel(app.CompareTab, 'Text', 'Configuration', 'FontWeight', 'bold', 'Position', [10 Hi-32 90 22]);
            app.CompareTypeDropDown = uidropdown(app.CompareTab, 'Items', {'Rotor-Stator', 'Rotor-Rotor same shaft', ...
                'Rotor-Rotor different shaft'}, 'Position', [100 Hi-32 190 22], ...
                'Tooltip', 'Configuration of the .mat file you add next');
            app.CompareAddFileButton = uibutton(app.CompareTab, 'Text', 'Add .mat file...', 'Position', [300 Hi-34 120 26], ...
                'Tooltip', 'Computes this design file with the chosen configuration and the current settings', ...
                'ButtonPushedFcn', @(~, ~) app.compare_add_file());
            app.CompareAddLastButton = uibutton(app.CompareTab, 'Text', 'Add last run', 'Position', [430 Hi-34 110 26], ...
                'ButtonPushedFcn', @(~, ~) app.compare_add_last());
            app.CompareRemoveButton = uibutton(app.CompareTab, 'Text', 'Remove selected', 'Position', [550 Hi-34 120 26], ...
                'ButtonPushedFcn', @(~, ~) app.compare_remove());
            app.CompareClearButton = uibutton(app.CompareTab, 'Text', 'Clear', 'Position', [680 Hi-34 70 26], ...
                'ButtonPushedFcn', @(~, ~) app.compare_clear());
            app.CompareExportButton = uibutton(app.CompareTab, 'Text', 'Export comparison...', 'Position', [760 Hi-34 150 26], ...
                'Tooltip', 'Excel table + the four overlay maps as PNG', ...
                'ButtonPushedFcn', @(~, ~) app.compare_export());
            app.CompareTable = uitable(app.CompareTab, 'Position', [10 Hi-200 Wi-20 160], 'RowName', {}, ...
                'CellEditCallback', @(~, evt) app.compare_cell_edited(evt), ...
                'CellSelectionCallback', @(~, evt) app.compare_selected(evt));
            ctg = uitabgroup(app.CompareTab, 'Position', [0 0 Wi Hi-206]);
            cw = floor((Wi - 30)/2); chh = Hi - 206 - 28 - 16;
            t1 = uitab(ctg, 'Title', 'Relative (PR/PR_des vs MFP/MFP_des)');
            app.CmpRelPRAxes = uiaxes(t1, 'Position', [10 8 cw chh]);
            app.CmpRelEffAxes = uiaxes(t1, 'Position', [20+cw 8 cw chh]);
            t2 = uitab(ctg, 'Title', 'Non-dimensional (PR vs MFP)');
            app.CmpNdPRAxes = uiaxes(t2, 'Position', [10 8 cw chh]);
            app.CmpNdEffAxes = uiaxes(t2, 'Position', [20+cw 8 cw chh]);
            app.compare_refresh();

            % ---------- Tables ----------
            uilabel(app.TablesTab, 'Text', 'Table', 'FontWeight', 'bold', 'Position', [10 Hi-32 45 22]);
            app.TableSelectDropDown = uidropdown(app.TablesTab, 'Items', app.result_table_names(), 'Position', [60 Hi-32 320 22], ...
                'ValueChangedFcn', @(~, ~) app.update_table_view());
            app.ExportTablesButton = uibutton(app.TablesTab, 'Text', 'Export all tables (Excel)', 'Position', [400 Hi-34 220 26], ...
                'ButtonPushedFcn', @(~, ~) app.ui_export_tables());
            app.ResultsTable = uitable(app.TablesTab, 'Position', [10 10 Wi-20 Hi-52], 'RowName', {});

            % ---------- Equations ----------
            app.EquationsTextArea = uitextarea(app.EquationsTab, 'Editable', 'off', 'FontName', mono, 'FontSize', 12, ...
                'Position', [10 46 Wi-20 Hi-56], 'Value', {'Press Run: the fitted equations of the surge, stall-onset and choke lines appear here.'});
            app.CopyEquationsButton = uibutton(app.EquationsTab, 'Text', 'Copy equations', 'Position', [10 10 170 26], ...
                'ButtonPushedFcn', @(~, ~) clipboard('copy', strjoin(app.EquationsTextArea.Value(:)', newline)));

            % ---------- Diagnostics ----------
            app.DiagnosticsTextArea = uitextarea(app.DiagnosticsTab, 'Editable', 'off', 'FontName', mono, 'FontSize', 13, ...
                'Position', [10 10 Wi-20 Hi-20], 'Value', {'Press Run: stability limit, margins, surge or rotating stall, and the Koch design check appear here.'});

            % ---------- Report ----------
            app.ReportTextArea = uitextarea(app.ReportTab, 'Editable', 'off', 'FontName', mono, 'FontSize', 11, ...
                'Position', [10 46 Wi-20 Hi-56], 'Value', {'Press Run: the full text report of the computation appears here.'});
            app.CopyReportButton = uibutton(app.ReportTab, 'Text', 'Copy report', 'Position', [10 10 170 26], ...
                'ButtonPushedFcn', @(~, ~) clipboard('copy', app.report_log));
            app.EchoCommandWindowCheckBox = uicheckbox(app.ReportTab, 'Text', 'Also print to the command window', 'Position', [200 12 320 22]);
            app.ExportReportButton = uibutton(app.ReportTab, 'Text', 'Export PDF report...', 'Position', [540 10 170 26], ...
                'Tooltip', 'Summary, diagnostics, all maps, all tables and equations in one PDF (MATLAB R2021b+)', ...
                'ButtonPushedFcn', @(~, ~) app.export_pdf_report());

            app.set_input_tooltips();
            app.MainTabGroup.SelectedTab = app.GuideTab;
        end

        function f = ui_num_field(app, parent, y, label, lims, fmt, tip)
            % Label + numeric edit field on one row of a settings panel
            uilabel(parent, 'Text', label, 'Tooltip', tip, 'Position', [15 y 260 22]);
            f = uieditfield(parent, 'numeric', 'Value', lims(1), 'Limits', lims, 'ValueDisplayFormat', fmt, ...
                'Tooltip', tip, 'Position', [280 y 200 22]);
        end

        function ui_export_tables(app)
            % Export all tables (button of the Tables tab)
            if isempty(app.computation_results)
                uialert(app.UIFigure, 'Run the computation first.', 'Nothing to export'); return;
            end
            try
                app.export_tables();
            catch err
                uialert(app.UIFigure, err.message, 'Export failed');
            end
        end

        function ui_export_figures(app)
            % Export all maps (button of the Maps tab)
            if isempty(app.computation_results)
                uialert(app.UIFigure, 'Run the computation first.', 'Nothing to export'); return;
            end
            try
                app.export_figures();
            catch err
                uialert(app.UIFigure, err.message, 'Export failed');
            end
        end

        % =================== step 14: inputs, run range, rows, Koch indicator ===================
        function [Tt, Pt] = inlet_state(app)
            % Inlet total state of the run: .mat (Tt1, Pt1) > Settings tab > 288 K / 1e5 Pa.
            % It must be the inlet state the design script used.
            Tt = app.Tt1_in; Pt = app.Pt1_in;
            d = app.loadedData;
            if isstruct(d)
                if isfield(d, 'Tt1'), Tt = double(d.Tt1); end
                if isfield(d, 'Pt1'), Pt = double(d.Pt1); end
            end
        end

        function Nr = speed_ratios(app)
            % Speed lines N/N_des of the run (Settings tab); N/N_des = 1 is always included
            Nr = linspace(app.N_min, app.N_max, max(3, round(app.n_speed)));
            Nm = app.measured_speeds();                 % step 24: every measured speed gets its line
            if ~isempty(Nm) && app.meas_speeds_only     % step 26: validation view, measured speeds only
                Nr = unique(round([Nm, 1]*1e6)/1e6);
                return;
            end
            if ~isempty(Nm)
                tol = min(0.011, 0.45*(Nr(end) - Nr(1))/max(numel(Nr) - 1, 1));
                for q = 1:numel(Nm)                     % a grid line next to a measured speed moves onto it
                    [dq, jq] = min(abs(Nr - Nm(q)));
                    if dq < tol && abs(Nr(jq) - 1) > 1e-9, Nr(jq) = Nm(q); end
                end
                Nr = unique(round([Nr, Nm]*1e6)/1e6);
            end
            [dmin, j] = min(abs(Nr - 1));
            if dmin < 1e-9
                Nr(j) = 1;
            else
                Nr = sort([Nr, 1]);
            end
        end

        function info_alert(app, msg, ttl)
            % Information message: pop-up in normal runs, report line only in comparison runs
            fprintf('%s: %s\n', ttl, msg);
            if ~app.quiet
                uialert(app.UIFigure, msg, ttl, 'Icon', 'info');
            end
        end

        function enable_run(app)
            % Re-enable the Run button (called when a run ends, also after an error)
            if app.has_ui('RunButton'), app.RunButton.Enable = 'on'; end
        end

        function r = row_rec(app, name, i, x, omega, omega_des, Min, Mout, DH, dev)
            % One blade row at one operating point (no input: empty record list)
            if nargin < 2
                r = struct('name', {}, 'i', {}, 'x', {}, 'omega', {}, 'ratio', {}, ...
                           'M_in', {}, 'M_out', {}, 'DH', {}, 'dev', {});
                return;
            end
            r = struct('name', name, 'i', i, 'x', x, 'omega', omega, 'ratio', omega/omega_des, ...
                       'M_in', Min, 'M_out', Mout, 'DH', DH, 'dev', dev);
        end

        function RD = collect_row_detail(app, ev, results, m_des)
            % Blade-row quantities at the design point, at the first stability limit
            % and near choke of the design speed line. ev(m, N/N_des) = point solver.
            % No extra input is needed: the solver already computes every row.
            RD = struct('point', {}, 'm', {}, 'rows', {});
            k1 = find(abs(results.speed_ratio - 1) < 1e-9, 1);
            pts = {'Design point', m_des};
            if ~isempty(k1)
                if ~isnan(results.lim_m(k1))
                    pts(end+1, :) = {sprintf('First limit (%s)', results.lim_type{k1}), results.lim_m(k1)};
                end
                if ~isnan(results.choke_m(k1))
                    pts(end+1, :) = {'Near choke (0.99 m_choke)', 0.99*results.choke_m(k1)};
                end
            end
            for p = 1:size(pts, 1)
                try
                    [~, ~, ~, ft, ~, ~, ~, rows] = ev(pts{p, 2}, 1);
                    if isempty(ft) && ~isempty(rows)
                        RD(end+1) = struct('point', pts{p, 1}, 'm', pts{p, 2}, 'rows', rows);
                    end
                catch
                end
            end
        end

        function KA = get_koch_applicability(app, results)
            if isfield(results, 'koch_applicability')
                KA = results.koch_applicability;
            else
                KA = app.koch_applicability(results);
            end
        end

        function KA = koch_applicability(app, results)
            % Does Koch's correlation apply to this design? Koch is an INDICATOR only:
            % it never sets the stability limit. Levels: 'recommended', 'indicative',
            % 'not recommended', 'not available'.
            KA = struct('level', 'not available', 'verdict', '', 'reasons', {{}});
            if ~isfield(results, 'koch_geometry') || isempty(results.koch_geometry)
                KA.verdict = ['Not available: the .mat has no blade solidities and chord (sigma_rotor, sigma_stator ' ...
                    'or sigma_1, sigma_2, and chord). Nothing else is affected.'];
                return;
            end
            kg = results.koch_geometry; KD = results.koch_design;
            reasons = {}; far = false; fef_out = false;
            isRR = ~strncmp(results.compressor_type, 'Rotor-Stator', 12);
            for g = 1:numel(KD)
                if KD(g).LG < 0.6 || KD(g).LG > 2.2
                    if KD(g).LG < 0.6, side = 'below 0.6 (low solidity)'; else, side = 'above 2.2 (high solidity)'; end
                    reasons{end+1} = sprintf(['%s: L/g2 = %.2f is %s, outside Koch''s data, so its stalling ' ...
                        'pressure rise is extrapolated.'], KD(g).label, KD(g).LG, side);
                    if KD(g).LG < 0.45 || KD(g).LG > 2.75, far = true; end
                end
                idx = kg.groups{g};
                for q = 1:numel(KD(g).Fef)
                    F = KD(g).Fef(q);
                    if F < 0.39 || F > 1.11
                        fef_out = true;
                        if strcmp(results.compressor_type, 'Rotor-Rotor Same Shaft')
                            how = 'in the same rotating frame (same shaft), so they are not re-energized';
                        elseif isRR
                            how = 'in a frame turning the same way at a similar speed';
                        else
                            how = 'with little relative motion';
                        end
                        reasons{end+1} = sprintf(['%s: effective dynamic-head factor F_ef = %.2f, outside 0.39-1.11. ' ...
                            'The upstream wakes enter %s; Koch''s correlation does not cover this.'], kg.names{idx(q)}, F, how);
                    end
                end
            end
            if isRR
                reasons{end+1} = 'Rotor-rotor stage: Koch''s database holds rotor-stator stages only.';
            end
            if fef_out || far
                KA.level = 'not recommended';
                KA.verdict = ['Not recommended for this design: it is outside the basis of Koch''s correlation (see why). ' ...
                    'The Koch line is hidden by default; use Howell, the peak and the Blade rows table instead.'];
            elseif ~isempty(reasons)
                KA.level = 'indicative';
                KA.verdict = ['Indicative: near Koch''s data. Read the ratio as a trend (more or less loaded than a ' ...
                    'typical stage), not as a limit. Howell and the peak set the limit.'];
            else
                KA.level = 'recommended';
                KA.verdict = ['Applies: the design is inside Koch''s data. Use the Koch line and the design check: ' ...
                    'they add a stage static-pressure-rise limit that the row-loss (Howell) and peak checks do not see, ' ...
                    'and say what geometry to change.'];
            end
            KA.reasons = reasons;
        end

        function set_koch_toggle(app, results)
            % Koch line on/off after a run, from the Settings choice (Auto = applicability).
            % The check box text says when there is nothing to draw, and why.
            if ~app.has_ui('ShowKochCheckBox'), return; end
            KA = app.get_koch_applicability(results);
            cb = app.ShowKochCheckBox;
            [nk, nb] = app.koch_line_count(results);
            if strcmp(KA.level, 'not available')
                cb.Text = 'Koch (no data)'; cb.Value = false; cb.Enable = 'off';
                cb.Tooltip = 'The .mat has no solidities/chord, so Koch is not computed.';
                return;
            elseif nk == 0
                if nb > 0, cb.Text = 'Koch (above limit)'; else, cb.Text = 'Koch (not reached)'; end
                cb.Value = false; cb.Enable = 'off';
                cb.Tooltip = app.koch_line_text(results);
                return;
            end
            switch KA.level
                case 'recommended', cb.Text = 'Koch';
                case 'indicative',  cb.Text = 'Koch (indicative)';
                otherwise,          cb.Text = 'Koch (not recommended)';
            end
            cb.Enable = 'on';
            cb.Tooltip = sprintf('%s Applicability: %s (see Diagnostics).', app.koch_line_text(results), KA.level);
            if strncmp(app.koch_mode, 'Always', 6)
                app.ShowKochCheckBox.Value = true;
            elseif strncmp(app.koch_mode, 'Hide', 4)
                app.ShowKochCheckBox.Value = false;
            else
                app.ShowKochCheckBox.Value = strcmp(KA.level, 'recommended');
            end
        end

        % =================== step 14: line toggles ===================
        function names = map_axes_names(app)
            names = {'StdPRAxes', 'StdEffAxes', 'NondimPRAxes', 'NondimEffAxes', 'RelPRAxes', 'RelEffAxes', 'CorrPRAxes', 'CorrEffAxes'};
        end

        function grp = map_object_group(app, h)
            % Which family a plotted object belongs to (for the Show check boxes)
            grp = '';
            ty = get(h, 'Type');
            if strcmp(ty, 'text')
                if strcmp(get(h, 'String'), 'Design Point'), grp = 'design'; end
                return;
            end
            if ~strcmp(ty, 'line'), return; end
            if strcmp(get(h, 'Tag'), 'KochLimit'), grp = 'koch'; return; end
            if strcmp(get(h, 'Tag'), 'Measured'), grp = 'meas'; return; end      % step 25
            dn = get(h, 'DisplayName');
            if strncmp(dn, 'N/N_', 4),          grp = 'speed';
            elseif strncmp(dn, 'Surge', 5),     grp = 'surge';
            elseif strncmp(dn, 'Stall', 5),     grp = 'stall';
            elseif strncmp(dn, 'Choke', 5),     grp = 'choke';
            elseif strcmp(dn, 'Design Point'),  grp = 'design';
            else
                mk = get(h, 'Marker'); fc = get(h, 'MarkerFaceColor');
                if isnumeric(fc) && numel(fc) == 3
                    if any(strcmp(mk, {'s', 'square'})) && isequal(fc, [1 0 0]),     grp = 'surge';
                    elseif any(strcmp(mk, {'d', 'diamond'})) && isequal(fc, [1 0 1]), grp = 'stall';
                    elseif any(strcmp(mk, {'s', 'square'})) && isequal(fc, [0 0 1]), grp = 'choke';
                    end
                end
                if isempty(grp) && strcmp(mk, 'none'), grp = 'speed'; end   % speed-line extension to choke
            end
        end

        function on = line_toggle_state(app)
            grp = {'speed', 'ShowSpeedCheckBox'; 'surge', 'ShowSurgeCheckBox'; 'stall', 'ShowStallCheckBox'; ...
                   'choke', 'ShowChokeCheckBox'; 'koch', 'ShowKochCheckBox'; 'design', 'ShowDesignCheckBox'; ...
                   'meas', 'ShowMeasuredCheckBox'};
            on = struct();
            for g = 1:size(grp, 1)
                v = true;
                if app.has_ui(grp{g, 2}), v = logical(app.(grp{g, 2}).Value); end
                on.(grp{g, 1}) = v;
            end
        end

        function apply_visibility_to(app, axs)
            % Show/hide the line families on the given axes
            on = app.line_toggle_state();
            for a = 1:numel(axs)
                kids = allchild(axs(a));
                for q = 1:numel(kids)
                    gname = app.map_object_group(kids(q));
                    if ~isempty(gname)
                        if on.(gname), vis = 'on'; else, vis = 'off'; end
                        set(kids(q), 'Visible', vis);
                    end
                end
            end
        end

        function apply_line_visibility(app)
            % Check boxes of the Maps tab: works on the maps already drawn (no re-run)
            axn = app.map_axes_names();
            for a = 1:numel(axn)
                if app.has_ui(axn{a}), app.apply_visibility_to(app.(axn{a})); end
            end
        end

        % =================== step 24: own stator geometry, measured data, validation ===================
        function sg = stator_geometry(app, g, k, n_stat)
            % Angles of stator k. A real stage has its own stator blading: when the .mat
            % has stator_beta_in, stator_beta_out, stator_incidence, stator_deviation,
            % stator_deflection (one value, or one value per stator) they are used.
            % A missing one takes the rotor's value of the same stage (symmetric, 50 %
            % reaction stage, as written by the design script).
            sg = g;
            d = app.loadedData;
            if ~isstruct(d), return; end
            F = app.stator_fields();
            for q = 1:size(F, 1)
                if isfield(d, F{q, 2})
                    sg.(F{q, 1}) = app.per_row(d.(F{q, 2}), k, n_stat, F{q, 2}, 'stator');
                end
            end
        end

        function F = stator_fields(app)
            F = {'b_in', 'stator_beta_in'; 'b_out', 'stator_beta_out'; 'inc', 'stator_incidence'; ...
                 'dev', 'stator_deviation'; 'defl', 'stator_deflection'};
        end

        function tf = has_stator_geometry(app)
            d = app.loadedData;
            F = app.stator_fields();
            tf = strcmp(app.Compressor_type, 'Rotor-Stator') && isstruct(d) && any(isfield(d, F(:, 2)'));
        end

        function D = measured_data(app)
            % Measured (test or CFD) points stored in the .mat, [] if none:
            %   meas_N   : N/N_des of each point
            %   meas_m   : mass flow [kg/s] at the run's inlet state (Tt1, Pt1)
            %   meas_PR  : total-pressure ratio
            %   meas_eta : isentropic efficiency (optional, NaN where not measured)
            %   meas_source : text naming the source (optional)
            D = [];
            d = app.loadedData;
            if ~isstruct(d) || ~all(isfield(d, {'meas_N', 'meas_m', 'meas_PR'})), return; end
            N = double(d.meas_N(:)); m = double(d.meas_m(:)); PR = double(d.meas_PR(:));
            if isempty(N) || numel(m) ~= numel(N) || numel(PR) ~= numel(N), return; end
            eta = nan(size(N));
            if isfield(d, 'meas_eta') && numel(d.meas_eta) == numel(N), eta = double(d.meas_eta(:)); end
            src = 'Measured';
            if isfield(d, 'meas_source') && ~isempty(d.meas_source), src = char(d.meas_source); end
            D = struct('N', round(N*1e6)/1e6, 'm', m, 'PR', PR, 'eta', eta, 'source', src);
        end

        function Nm = measured_speeds(app)
            D = app.measured_data();
            if isempty(D), Nm = []; else, Nm = unique(D.N(:))'; end
        end

        function V = validation_metrics(app, results)
            % Measured points against the model. The prediction at each measured
            % point is solved directly at its (m, N/N_des) during the run
            % (results.meas_pred); every measured speed also gets its speed line on
            % the maps (speed_ratios). Error measures:
            %   dPR                      predicted - measured total-pressure ratio
            %   |dPR|/(PR_max,line - 1)  error relative to the pressure rise of that
            %                            measured speed line (fair for low-PR machines)
            %   d eta                    in efficiency points, only where the measured
            %                            pressure rise is >= 25 % of the line's maximum
            %                            (near PR = 1 the efficiency is ill-defined)
            V = [];
            D = app.measured_data();
            if isempty(D), return; end
            N = results.speed_ratio(:)';
            np = numel(D.N);
            P = struct('N', num2cell(D.N), 'm', num2cell(D.m), 'PR_meas', num2cell(D.PR), 'eta_meas', num2cell(D.eta), ...
                       'PR_pred', NaN, 'eta_pred', NaN, 'line', 0, 'rise_ref', NaN, 'use_eta', false, 'note', '');
            direct = isfield(results, 'meas_pred') && size(results.meas_pred, 1) == np;
            for i = 1:np
                k = find(abs(N - D.N(i)) < 1e-4, 1);
                if ~isempty(k), P(i).line = k; end
                same = D.N == D.N(i);
                P(i).rise_ref = max(D.PR(same)) - 1;
                P(i).use_eta = ~isnan(D.eta(i)) && (D.PR(i) - 1) >= 0.25*P(i).rise_ref;
                if direct
                    P(i).PR_pred = results.meas_pred(i, 1); P(i).eta_pred = results.meas_pred(i, 2);
                elseif ~isempty(k)
                    [xs, ys, es] = app.line_curve(results, k);
                    if numel(xs) >= 2 && D.m(i) >= xs(1) && D.m(i) <= xs(end)
                        P(i).PR_pred = interp1(xs, ys, D.m(i));
                        ok = ~isnan(es);
                        if sum(ok) >= 2 && D.m(i) >= min(xs(ok)) && D.m(i) <= max(xs(ok))
                            P(i).eta_pred = interp1(xs(ok), es(ok), D.m(i));
                        end
                    end
                end
                if isnan(P(i).PR_pred)
                    if ~isempty(k) && ~isnan(results.choke_m(k)) && D.m(i) > results.choke_m(k)
                        P(i).note = 'beyond the predicted choke flow';
                    else
                        P(i).note = 'no prediction at this point';
                    end
                end
            end
            Ns = unique(D.N(:))';
            S = struct('N', {}, 'n', {}, 'm_low_meas', {}, 'm_lim_pred', {}, 'lim_type', {}, 'err_low', {}, ...
                       'm_high_meas', {}, 'm_choke_pred', {}, 'err_high', {}, 'dPR', {}, 'dRise', {}, 'dEta', {});
            for s = Ns
                j = find([P.N] == s); k = P(j(1)).line;
                pm = [P(j).PR_meas]; pp = [P(j).PR_pred]; em = [P(j).eta_meas]; ep = [P(j).eta_pred]; ue = [P(j).use_eta];
                e = struct('N', s, 'n', numel(j), 'm_low_meas', min([P(j).m]), 'm_lim_pred', NaN, 'lim_type', '-', ...
                           'err_low', NaN, 'm_high_meas', max([P(j).m]), 'm_choke_pred', NaN, 'err_high', NaN, ...
                           'dPR', app.nmean(abs(pp - pm)), 'dRise', 100*app.nmean(abs(pp - pm))/max(P(j(1)).rise_ref, 1e-3), ...
                           'dEta', 100*app.nmean(abs(ep(ue) - em(ue))));
                if k > 0
                    e.m_lim_pred = results.lim_m(k); e.lim_type = results.lim_type{k};
                    e.err_low = 100*(e.m_lim_pred/e.m_low_meas - 1);
                    % high-flow end: flow at which the predicted line falls to the PR of the
                    % highest-flow measured point (the predicted choke flow if it chokes first)
                    [~, jh] = max([P(j).m]); PR_end = P(j(jh)).PR_meas;
                    [xs, ys] = app.line_curve(results, k);
                    e.m_choke_pred = app.flow_at_pr(xs, ys, PR_end);
                    e.err_high = 100*(e.m_choke_pred/e.m_high_meas - 1);
                end
                S(end+1) = e;
            end
            pm = [P.PR_meas]; pp = [P.PR_pred]; em = [P.eta_meas]; ep = [P.eta_pred]; rr = [P.rise_ref];
            okp = ~isnan(pp); oke = [P.use_eta] & ~isnan(ep);
            V = struct('points', P, 'speeds', S, 'source', D.source, 'n', np, 'n_pr', sum(okp), 'n_eta', sum(oke), ...
                       'mae_PR', mean(abs(pp(okp) - pm(okp))), 'rms_PR', sqrt(mean((pp(okp) - pm(okp)).^2)), ...
                       'mae_rise', 100*mean(abs(pp(okp) - pm(okp))./max(rr(okp), 1e-3)), ...
                       'mae_eta', 100*mean(abs(ep(oke) - em(oke))), 'rms_eta', 100*sqrt(mean((ep(oke) - em(oke)).^2)), ...
                       'bias_PR', mean(pp(okp) - pm(okp)), 'bias_eta', 100*mean(ep(oke) - em(oke)));
        end

        function m = flow_at_pr(app, xs, ys, PR_end)
            % Flow on the descending (choke-side) branch of a speed line where PR = PR_end;
            % the last point of the line if it never falls that low
            m = NaN;
            if numel(xs) < 2, return; end
            [~, jp] = max(ys);
            xb = xs(jp:end); yb = ys(jp:end);
            q = find(yb <= PR_end, 1);
            if isempty(q), m = xb(end);
            elseif q == 1, m = xb(1);
            else, m = xb(q-1) + (PR_end - yb(q-1))*(xb(q) - xb(q-1))/(yb(q) - yb(q-1));
            end
        end

        function v = nmean(app, x)
            x = x(~isnan(x));
            if isempty(x), v = NaN; else, v = mean(x); end
        end

        function [xs, ys, es] = line_curve(app, results, k)
            % Computed speed line k as increasing flow: grid points, then its exact choke point
            v = ~isnan(results.Total_PR(k, :));
            xs = results.mass_dot_range(v); ys = results.Total_PR(k, v); es = results.Overall_Eff(k, v);
            if ~isnan(results.choke_m(k)) && (isempty(xs) || results.choke_m(k) > xs(end))
                xs = [xs, results.choke_m(k)]; ys = [ys, results.choke_PR(k)]; es = [es, results.choke_Eff(k)];
            end
            xs = real(xs(:)'); ys = real(ys(:)'); es = real(es(:)');
        end

        function h = plot_measured(app, ax, results, what)
            % Measured points on a dimensional / corrected map, in the colour of their speed line
            h = [];
            V = [];
            if isfield(results, 'validation'), V = results.validation; end
            if isempty(V), return; end
            sc = 1;
            if isfield(results, 'meas_scale'), sc = results.meas_scale; end
            colors = lines(length(results.U_range));
            P = V.points;
            for k = unique([P.line])
                j = find([P.line] == k);
                if strcmp(what, 'PR'), y = [P(j).PR_meas]; else, y = [P(j).eta_meas]; end
                x = [P(j).m]*sc;
                ok = ~isnan(y);
                if ~any(ok), continue; end
                if k > 0, c = colors(k, :); else, c = [0.3 0.3 0.3]; end
                hh = plot(ax, x(ok), y(ok), '^', 'MarkerSize', 8, 'LineWidth', 1.2, 'MarkerFaceColor', c, ...
                    'MarkerEdgeColor', 'k', 'LineStyle', 'none', 'DisplayName', ['Measured: ' V.source], 'Tag', 'Measured');
                if isempty(h), h = hh; else, set(hh, 'HandleVisibility', 'off'); end
            end
        end

        function L = validation_lines(app, results)
            % Diagnostics text of the comparison with measured data
            L = {};
            V = [];
            if isfield(results, 'validation'), V = results.validation; end
            if isempty(V), return; end
            L{end+1} = '';
            L{end+1} = sprintf('VALIDATION against %s: %d points (%d with a prediction).', V.source, V.n, V.n_pr);
            L{end+1} = sprintf(['   pressure ratio: mean |dPR| = %.4f, RMS = %.4f, bias %+.4f; mean |dPR| relative to the ' ...
                'pressure rise of its speed line = %.1f %%'], V.mae_PR, V.rms_PR, V.bias_PR, V.mae_rise);
            if V.n_eta > 0
                L{end+1} = sprintf(['   efficiency: mean |d eta| = %.1f points, RMS = %.1f, bias %+.1f points (%d points with at ' ...
                    'least 25 %% of the line''s pressure rise)'], V.mae_eta, V.rms_eta, V.bias_eta, V.n_eta);
            end
            for s = V.speeds
                L{end+1} = sprintf(['   N/N_des = %.3f (%d pts): lowest measured flow %.4f vs predicted first limit %.4f (%s, %+.1f %%); ' ...
                    'highest measured flow %.4f vs predicted %.4f at the same PR (%+.1f %%); mean |dPR| %.4f (%.1f %% of the rise), |d eta| %.1f pts'], ...
                    s.N, s.n, s.m_low_meas, s.m_lim_pred, s.lim_type, s.err_low, s.m_high_meas, s.m_choke_pred, s.err_high, s.dPR, s.dRise, s.dEta);
            end
            nn = sum(~cellfun(@isempty, {V.points.note}));
            if nn > 0
                L{end+1} = sprintf('   %d point(s) outside the computed lines (Tables > Validation points, column "Note").', nn);
            end
        end

        % =================== step 25: model options (blockage, bucket shape, Reynolds), measured toggle ===================
        function bk = blockage_vector(app, nA)
            % Area blockage factor of every station of A_vec (effective area = factor x A_vec).
            % .mat variable blockage (one value, or one per station of A_vec) wins over Settings.
            bk = app.blockage*ones(1, nA);
            d = app.loadedData;
            if isstruct(d) && isfield(d, 'blockage')
                v = double(d.blockage(:)');
                if isscalar(v), bk = v*ones(1, nA);
                elseif numel(v) == nA, bk = v;
                else, error('blockage has %d values: give 1 value or %d (one per station of A_vec).', numel(v), nA);
                end
            end
            if any(bk <= 0.5 | bk > 1)
                error('blockage must be between 0.5 and 1 (1 = no blockage).');
            end
        end

        function v = model_option(app, matname, prop)
            % A model option: the .mat value if the file has it, otherwise the Settings value
            v = app.(prop);
            d = app.loadedData;
            if isstruct(d) && isfield(d, matname), v = double(d.(matname)(1)); end
        end

        function M = add_model_options(app, M, ~)
            % Off-design model options carried by the operating-point model M
            M.kx = app.bucket_width;
            kn = app.model_option('bucket_width_neg', 'bucket_width_neg');
            if isempty(kn) || isnan(kn) || kn <= 0, kn = M.kx; end
            M.kx_neg = kn;
            M.eps_min = max(0, app.model_option('min_ref_deflection', 'min_ref_deflection'));
            M.re_n = max(0, app.model_option('re_exponent', 're_exponent'));
            M.re_crit = 2.5e5;
            M.chord = [];
            d = app.loadedData;
            if isstruct(d) && isfield(d, 'chord'), M.chord = double(d.chord(1)); end
            if isempty(M.chord), M.re_n = 0; end            % Reynolds correction needs the chord
            M.Re_des = [];
            if M.kx_neg < 0.1 || M.kx_neg > 10, error('bucket_width_neg must be between 0.1 and 10.'); end
            if M.eps_min > 60, error('min_ref_deflection must be between 0 and 60 deg.'); end
            if M.re_n > 1, error('re_exponent must be between 0 and 1 (typical 0.2).'); end
        end

        function mu = air_viscosity(app, T)
            % Sutherland's law for air [Pa s]
            mu = 1.716e-5*(T/273.15)^1.5*(273.15 + 110.4)/(T + 110.4);
        end

        function set_meas_toggle(app, results)
            % Measured points on/off; disabled when the .mat has none
            if ~app.has_ui('ShowMeasuredCheckBox'), return; end
            cb = app.ShowMeasuredCheckBox;
            if isfield(results, 'validation') && ~isempty(results.validation)
                cb.Text = 'Measured'; cb.Enable = 'on';
                cb.Tooltip = sprintf('%d measured points (%s). Errors: Diagnostics, Tables > Validation.', ...
                    results.validation.n, results.validation.source);
            else
                cb.Text = 'Measured (none)'; cb.Enable = 'off'; cb.Value = false;
                cb.Tooltip = 'No measured data in the .mat (meas_N, meas_m, meas_PR, meas_eta).';
            end
        end

        function L = model_option_lines(app, results)
            % Diagnostics: which off-design model options were active
            L = {};
            if ~isfield(results, 'model_options'), return; end
            o = results.model_options;
            parts = {};
            if any(o.blockage ~= 1), parts{end+1} = sprintf('choke area factor %s', mat2str(round(o.blockage*1000)/1000)); end
            if o.kx_neg ~= o.kx, parts{end+1} = sprintf('choke-side bucket width %.2f', o.kx_neg); end
            if o.eps_min > 0, parts{end+1} = sprintf('minimum reference deflection %.1f deg', o.eps_min); end
            if o.re_n > 0, parts{end+1} = sprintf('Reynolds correction exponent %.2f (Re_crit %.1e)', o.re_n, o.re_crit); end
            if o.re_req && o.re_n == 0, parts{end+1} = 'Reynolds correction requested but the .mat has no chord: not applied'; end
            if isempty(parts)
                L{end+1} = 'Model options: none (original model: geometric areas, Howell bucket scaled by each row''s design deflection).';
            else
                L{end+1} = ['Model options: ', strjoin(parts, '; '), '.'];
            end
        end

        % =================== step 14: input checks, templates, sessions ===================
        function map = input_map(app, typ)
            % {app property, .mat variable} of the required inputs of a configuration
            map = {'alpha1', 'alpha1'; 'n_stages', 'n_stages'; 'A_vec', 'A_vec'; 'beta1_dash', 'beta1_dash'; ...
                   'beta2_dash', 'beta2_dash'; 'm_dot', 'm_dot'; 'w_loss_rotor', 'w_loss_rotor'};
            switch typ
                case 'Rotor-Stator'
                    map = [map; {'deviation_1', 'deviation'; 'incidence_1', 'incidence'; 'deflection_1', 'deflection'; ...
                                 'w_loss_rotor2', 'w_loss_stator'; 'U1', 'U'}];
                otherwise
                    map = [map; {'beta3_dash', 'beta3_dash'; 'beta4_dash', 'beta4_dash'; 'deviation_1', 'deviation_1'; ...
                                 'deviation_2', 'deviation_2'; 'incidence_1', 'incidence_1'; 'incidence_2', 'incidence_2'; ...
                                 'deflection_1', 'deflection_1'; 'deflection_2', 'deflection_2'; 'w_loss_rotor2', 'w_loss_rotor2'}];
                    if strcmp(typ, 'Rotor-Rotor different shaft')
                        map = [map; {'U1', 'U1'; 'U2', 'U2'}];
                    else
                        map = [map; {'U1', 'U'}];
                    end
            end
        end

        function v = optional_mat_vars(app)
            v = {'V_plenum', 'L_duct', 'B_crit', 'correlation_set', 'howell_factor', 'bucket_width', 'bucket_width_neg', ...
                 'min_ref_deflection', 'blockage', 're_exponent', 'loss_coeffs', 'dev_coeffs', ...
                 'dev_x_min', 'sigma_rotor', 'sigma_stator', 'sigma_1', 'sigma_2', 'chord', 'eps_over_g', ...
                 'dz_over_s', 'koch_in_limit', 'Tt1', 'Pt1', ...
                 'stator_beta_in', 'stator_beta_out', 'stator_incidence', 'stator_deviation', 'stator_deflection', ...
                 'meas_N', 'meas_m', 'meas_PR', 'meas_eta', 'meas_source', 'case_name', 'reference', 'design_info'};
        end

        function hint = closest_name(app, name, list)
            % Closest known variable name (same letters ignoring case, or <= 2 edits)
            hint = '';
            j = find(strcmpi(name, list), 1);
            if ~isempty(j), hint = list{j}; return; end
            best = 3;
            for k = 1:numel(list)
                a = lower(name); b = lower(list{k});
                D = zeros(numel(a)+1, numel(b)+1); D(:, 1) = 0:numel(a); D(1, :) = 0:numel(b);
                for p = 1:numel(a)
                    for q = 1:numel(b)
                        D(p+1, q+1) = min([D(p, q+1) + 1, D(p+1, q) + 1, D(p, q) + (a(p) ~= b(q))]);
                    end
                end
                if D(end, end) < best, best = D(end, end); hint = list{k}; end
            end
        end

        function [ok, msg] = check_mat_variables(app, d, typ)
            % Names of the required variables, unknown names (with a guess) and the
            % optional groups found. ok = all required variables present.
            map = app.input_map(typ);
            req = map(:, 2)';
            opt = app.optional_mat_vars();
            have = fieldnames(d)';
            missing = req(~ismember(req, have));
            unknown = have(~ismember(have, [req, opt]));
            ok = isempty(missing);
            msg = {};
            other = false;
            if ok
                msg{end+1} = sprintf('great! your file uploaded successfully (%s: all %d required variables found).', typ, numel(req));
            else
                msg{end+1} = sprintf('Not loaded: %d required variable(s) missing for %s: %s.', numel(missing), typ, strjoin(missing, ', '));
                types = {'Rotor-Stator', 'Rotor-Rotor same shaft', 'Rotor-Rotor different shaft'};
                for t = 1:numel(types)
                    if strcmp(types{t}, typ), continue; end
                    m2 = app.input_map(types{t});
                    if all(isfield(d, m2(:, 2)))
                        msg{end+1} = sprintf('This file fits "%s": choose that compressor type and upload again.', types{t});
                        other = true;
                    end
                end
            end
            if other, unknown = {}; end          % the file is fine, only the type is wrong
            for u = 1:numel(unknown)
                hint = app.closest_name(unknown{u}, [req, opt]);
                if isempty(hint)
                    msg{end+1} = sprintf('Unknown variable "%s" (ignored).', unknown{u});
                else
                    msg{end+1} = sprintf('Unknown variable "%s": did you mean "%s"?', unknown{u}, hint);
                end
            end
            if ok
                if isfield(d, 'chord') && (isfield(d, 'sigma_rotor') || isfield(d, 'sigma_1'))
                    msg{end+1} = ['Solidities and chord found: the Koch check will be computed. After Run, Diagnostics ' ...
                        'says whether Koch applies to this design and whether a Koch line exists to plot.'];
                else
                    msg{end+1} = 'No solidities/chord in the file: the Koch check is skipped (optional; everything else runs).';
                end
                if strcmp(typ, 'Rotor-Stator') && any(isfield(d, {'stator_beta_in', 'stator_beta_out', 'stator_incidence', ...
                        'stator_deviation', 'stator_deflection'}))
                    msg{end+1} = 'Stator angles found (stator_*): the stators use their own blading instead of the rotor''s.';
                end
                if isfield(d, 'design_info') && isstruct(d.design_info)        % step 27: file written by the design app
                    di = d.design_info;
                    msg{end+1} = sprintf(['Design from the design app: %s, %d stage(s)/rotor(s), phi = %.3f, psi = %.3f, R = %.3f; ' ...
                        'design PR %.4f, efficiency %.4f.'], app.Compressor_type, di.n, di.phi, di.psi, di.R, di.PR, di.eta);
                end
                if strcmp(typ, 'Rotor-Rotor different shaft') && isfield(d, 'U2') && any(double(d.U2) < 0)
                    msg{end+1} = 'Negative U2: the even rotors are counter-rotating (solved in their own frame).';
                end
                if all(isfield(d, {'meas_N', 'meas_m', 'meas_PR'}))
                    msg{end+1} = sprintf(['Measured data found: %d points at %d speed(s). They are drawn on the maps and ' ...
                        'compared in Diagnostics and Tables > Validation.'], numel(d.meas_N), numel(unique(round(double(d.meas_N(:))*1e6))));
                end
            end
        end

        function load_inputs_from_struct(app, d, typ)
            % Required inputs of a configuration from a .mat struct into the properties
            map = app.input_map(typ);
            for k = 1:size(map, 1)
                v = double(d.(map{k, 2}));
                if strcmp(map{k, 1}, 'A_vec'), v = v(:)'; end
                app.(map{k, 1}) = v;
            end
        end

        function fld = manual_field_of(app, prop)
            % Manual-tab edit field of an input property ('' if none)
            P = {'alpha1', 'alpha_1EditField'; 'n_stages', 'n_stagesEditField'; 'A_vec', 'A_vecEditField'; ...
                 'beta1_dash', 'beta1_dashEditField'; 'beta2_dash', 'beta2_dashEditField'; 'beta3_dash', 'beta3_dashEditField'; ...
                 'beta4_dash', 'beta4_dashEditField'; 'deviation_1', 'deviationEditField'; 'deviation_2', 'deviation2EditField'; ...
                 'incidence_1', 'incidenceEditField'; 'incidence_2', 'incidence2EditField'; 'deflection_1', 'deflectionEditField'; ...
                 'deflection_2', 'deflection2EditField'; 'm_dot', 'm_dotEditField'; 'w_loss_rotor', 'w_loss_rotorEditField'; ...
                 'w_loss_rotor2', 'w_loss_rotor2EditField'; 'U1', 'U1EditField'; 'U2', 'U2EditField'};
            j = find(strcmp(P(:, 1), prop), 1);
            if isempty(j), fld = ''; else, fld = P{j, 2}; end
        end

        function fill_manual_fields(app)
            % Show the current inputs in the Manual tab
            if isempty(app.Compressor_type), return; end
            map = app.input_map(app.Compressor_type);
            for k = 1:size(map, 1)
                prop = map{k, 1}; fld = app.manual_field_of(prop); v = app.(prop);
                if isempty(fld) || ~app.has_ui(fld) || isempty(v), continue; end
                if strcmp(prop, 'A_vec')
                    app.(fld).Value = strtrim(sprintf('%.8g ', v));
                else
                    app.(fld).Value = double(v(1));
                    if numel(v) > 1          % step 23: per-row values from the .mat
                        app.(fld).Tooltip = sprintf('Per-row values from the .mat: %s (first shown; Run uses all of them)', ...
                            strtrim(sprintf('%.6g ', v)));
                    end
                end
            end
            app.sync_settings_from_mat();   % step 15: Settings fixed by the .mat are shown and locked
        end

        function w = consistency_warnings(app)
            % deflection = (beta_in' + i) - (beta_out' + delta) for every row
            w = {};
            if isempty(app.Compressor_type), return; end
            try
                rr = app.row_model();          % step 23: every blade row
            catch
                return;                        % sizes are reported by validate_inputs
            end
            for k = 1:numel(rr)
                if rr(k).kind == 'S' && ~app.has_stator_geometry(), continue; end   % a stator repeats its rotor's data
                calc = (rr(k).b_in + rr(k).inc) - (rr(k).b_out + rr(k).dev);
                if abs(calc - rr(k).defl) > 0.5
                    w{end+1} = sprintf(['Check %s: deflection = %.2f deg, but (beta_in'' + i) - (beta_out'' + delta) = %.2f deg. ' ...
                        'One of the angles may be wrong.'], lower(rr(k).name), rr(k).defl, calc);
                end
            end
        end

        function save_inputs_template(app, file)
            % Save the inputs of the chosen configuration as a .mat with the right names
            % (Manual-tab values; also a template to fill in for a new design)
            typ = app.Compressor_type;
            if app.has_ui('Choosethecompressortype'), typ = app.Choosethecompressortype.Value; end
            if nargin < 2
                [fn, pth] = uiputfile('*.mat', 'Save inputs', fullfile(app.last_folder, ...
                    sprintf('inputs_%s.mat', regexprep(lower(typ), '[^a-z]+', '_'))));
                if isequal(fn, 0), return; end
                file = fullfile(pth, fn); app.last_folder = pth;
            end
            map = app.input_map(typ);
            S = struct();
            for k = 1:size(map, 1)
                prop = map{k, 1}; fld = app.manual_field_of(prop); v = [];
                if app.has_ui(fld)
                    v = app.(fld).Value;
                    if strcmp(prop, 'A_vec')
                        v = str2double(regexp(strtrim(regexprep(v, '[\[\]()]', '')), '[,\s]+', 'split'));
                        v = v(~isnan(v));
                    end
                end
                if isempty(v), v = app.(prop); end
                if isempty(v), v = NaN; end
                S.(map{k, 2}) = v;
            end
            [S.Tt1, S.Pt1] = app.inlet_state();
            save(file, '-struct', 'S');
        end

        function f = settings_fields(app)
            f = {'CorrelationSet', 'howell_factor', 'bucket_width', 'bucket_width_neg', 'min_ref_deflection', 'blockage', 're_exponent', 'meas_speeds_only', 'koch_target_ratio', 'koch_eps_over_g', 'koch_dz_over_s', 'koch_mode', ...
                 'B_crit', 'V_plenum', 'L_duct', 'T_ref', 'p_ref', 'Tt1_in', 'Pt1_in', 'N_min', 'N_max', 'n_speed', 'm_density'};
        end

        function f = state_fields(app)
            f = {'Compressor_type', 'loadedData', 'alpha1', 'n_stages', 'A_vec', 'beta1_dash', 'beta2_dash', 'beta3_dash', ...
                 'beta4_dash', 'deviation_1', 'deviation_2', 'incidence_1', 'incidence_2', 'deflection_1', 'deflection_2', ...
                 'm_dot', 'w_loss_rotor', 'w_loss_rotor2', 'U1', 'U2', 'computation_results', 'report_log', ...
                 'equation_log', 'koch_Fef_seen', 'corr', 'mat_name'};
        end

        function S = snapshot_state(app, fields)
            if nargin < 2, fields = app.state_fields(); end
            S = struct();
            for k = 1:numel(fields), S.(fields{k}) = app.(fields{k}); end
        end

        function restore_state(app, S)
            f = fieldnames(S);
            for k = 1:numel(f)
                if isprop(app, f{k}) || any(strcmp(f{k}, [app.state_fields(), app.settings_fields()]))
                    app.(f{k}) = S.(f{k});
                end
            end
        end

        function save_session(app, file)
            % Inputs, settings, results, report and comparisons in one .mat
            if nargin < 2
                [fn, pth] = uiputfile('*.mat', 'Save session', fullfile(app.last_folder, 'compressor_session.mat'));
                if isequal(fn, 0), return; end
                file = fullfile(pth, fn); app.last_folder = pth;
            end
            app.read_settings_from_ui();
            compressor_session = struct('version', 14, 'saved', datestr(now), ...
                'state', app.snapshot_state(), 'settings', app.snapshot_state(app.settings_fields()), ...
                'compare_runs', app.compare_runs);
            save(file, 'compressor_session');
        end

        function open_session(app, file)
            % Restore a saved session (no recomputation)
            if nargin < 2
                [fn, pth] = uigetfile(fullfile(app.last_folder, '*.mat'), 'Open session');
                if isequal(fn, 0), return; end
                file = fullfile(pth, fn); app.last_folder = pth;
            end
            d = load(file);
            if ~isfield(d, 'compressor_session')
                uialert(app.UIFigure, 'This is not a session file (it has no compressor_session variable).', 'Open session');
                return;
            end
            S = d.compressor_session;
            app.restore_state(S.state);
            app.restore_state(S.settings);
            app.compare_runs = S.compare_runs;
            if app.has_ui('Choosethecompressortype') && ~isempty(app.Compressor_type)
                app.Choosethecompressortype.Value = app.Compressor_type;
            end
            app.fill_manual_fields();
            app.init_settings_ui();
            if ~isempty(app.computation_results)
                rep = app.report_log;
                evalc('app.show_results_in_app(app.computation_results);');
                app.report_log = rep;
                if app.has_ui('ReportTextArea'), app.ReportTextArea.Value = strsplit(app.report_log, newline)'; end
            end
            app.compare_refresh();
        end

        function set_input_tooltips(app)
            % Units, meaning and .mat name on every Manual-tab field
            T = {'alpha_1EditField', 'alpha1 [deg]: inlet absolute flow angle';
                 'n_stagesEditField', 'n_stages: Rotor-Stator = number of stages (rotor + stator); Rotor-Rotor = number of ROTORS (even)';
                 'A_vecEditField', 'A_vec [m^2]: flow areas at the row boundaries in flow order, e.g. 0.002831 0.002623 0.002433 (RS: 2n+1, or 2n without the last stator; RR: n+1)';
                 'beta1_dashEditField', 'beta1_dash [deg]: inlet metal angle of row 1 (Rotor-Stator: also the stator)';
                 'beta2_dashEditField', 'beta2_dash [deg]: exit metal angle of row 1';
                 'beta3_dashEditField', 'beta3_dash [deg]: inlet metal angle of rotor 2 (rotor-rotor only)';
                 'beta4_dashEditField', 'beta4_dash [deg]: exit metal angle of rotor 2 (rotor-rotor only)';
                 'incidenceEditField', 'incidence [deg]: design incidence of row 1 (.mat: incidence, or incidence_1 for rotor-rotor)';
                 'incidence2EditField', 'incidence_2 [deg]: design incidence of rotor 2 (rotor-rotor only)';
                 'deviationEditField', 'deviation [deg]: design deviation of row 1 (.mat: deviation, or deviation_1 for rotor-rotor)';
                 'deviation2EditField', 'deviation_2 [deg]: design deviation of rotor 2 (rotor-rotor only)';
                 'deflectionEditField', 'deflection [deg]: design flow turning of row 1 = (beta_in'' + i) - (beta_out'' + delta) > 0';
                 'deflection2EditField', 'deflection_2 [deg]: design flow turning of rotor 2 (rotor-rotor only)';
                 'm_dotEditField', 'm_dot [kg/s]: design mass flow';
                 'w_loss_rotorEditField', 'w_loss_rotor [-]: design total-pressure loss coefficient of row 1';
                 'w_loss_rotor2EditField', 'w_loss_rotor2 [-]: design loss coefficient of the stator (Rotor-Stator, .mat: w_loss_stator) or of rotor 2';
                 'U1EditField', 'U1 [m/s]: mean blade speed (.mat: U; U1 for rotor-rotor different shaft)';
                 'U2EditField', 'U2 [m/s]: mean blade speed of rotor 2 (rotor-rotor different shaft only)'};
            for k = 1:size(T, 1)
                if app.has_ui(T{k, 1}), app.(T{k, 1}).Tooltip = T{k, 2}; end
            end
            if app.has_ui('upload_message'), app.upload_message.FontSize = 12; end
        end

        % =================== step 14: comparisons ===================
        function s = short_type(app, typ)
            switch typ
                case 'Rotor-Stator', s = 'RS';
                case 'Rotor-Rotor same shaft', s = 'RR same';
                otherwise, s = 'RR diff';
            end
        end

        function compare_push(app, lab, typ, src, r, md)
            e = struct('show', true, 'label', lab, 'type', typ, 'source', src, 'results', r, 'm_dot', md);
            if isempty(app.compare_runs), app.compare_runs = e; else, app.compare_runs(end+1) = e; end
            app.compare_refresh();
        end

        function compare_add_last(app)
            % Add the last run of the app to the comparison
            if isempty(app.computation_results)
                uialert(app.UIFigure, 'Run the computation first.', 'Nothing to add'); return;
            end
            lab = sprintf('Run %d: %s', numel(app.compare_runs) + 1, app.short_type(app.Compressor_type));
            app.compare_push(lab, app.Compressor_type, 'last run', app.computation_results, app.m_dot);
        end

        function compare_add_file(app, file, typ)
            % Compute a design file with the chosen configuration (current settings)
            % and add it to the comparison. The main inputs and results are kept.
            if nargin < 3
                typ = app.CompareTypeDropDown.Value;
                [fn, pth] = uigetfile(fullfile(app.last_folder, '*.mat'), sprintf('Design file (%s)', typ));
                if isequal(fn, 0), return; end
                file = fullfile(pth, fn); app.last_folder = pth;
            end
            d = load(file);
            if isfield(d, 'compressor_session')
                uialert(app.UIFigure, 'This is a session file: use Open session in the Settings tab.', 'Not a design file'); return;
            end
            [ok, msg] = app.check_mat_variables(d, typ);
            if ~ok
                uialert(app.UIFigure, strjoin(msg, newline), 'Cannot add this file'); return;
            end
            snap = app.snapshot_state();
            dlg = [];
            r = []; md = NaN; err_msg = '';
            try
                if app.has_ui('UIFigure')
                    dlg = uiprogressdlg(app.UIFigure, 'Title', 'Comparison', 'Message', ...
                        sprintf('Computing %s ...', typ), 'Indeterminate', 'on');
                end
                app.read_settings_from_ui();
                app.Compressor_type = typ; app.loadedData = d;
                [~, app.mat_name] = fileparts(file);
                app.load_inputs_from_struct(d, typ);
                app.quiet = true;
                if app.validate_inputs()
                    app.run_computation();
                    r = app.computation_results; md = app.m_dot;
                end
            catch err
                err_msg = err.message;
            end
            app.quiet = false;
            app.restore_state(snap);
            if ~isempty(dlg), close(dlg); end
            if isempty(r)
                uialert(app.UIFigure, ['The computation failed for this file. ' err_msg], 'Comparison'); return;
            end
            [~, nm] = fileparts(file);
            app.compare_push(sprintf('%s (%s)', nm, app.short_type(typ)), typ, file, r, md);
        end

        function compare_selected(app, evt)
            if isempty(evt.Indices), app.compare_sel = []; else, app.compare_sel = unique(evt.Indices(:, 1))'; end
        end

        function compare_cell_edited(app, evt)
            i = evt.Indices(1); j = evt.Indices(2);
            if j == 1, app.compare_runs(i).show = logical(evt.NewData); end
            if j == 2, app.compare_runs(i).label = char(evt.NewData); end
            app.compare_refresh();
        end

        function compare_remove(app)
            if isempty(app.compare_sel)
                uialert(app.UIFigure, 'Click a row of the table first.', 'Remove'); return;
            end
            app.compare_runs(app.compare_sel(app.compare_sel <= numel(app.compare_runs))) = [];
            app.compare_sel = [];
            app.compare_refresh();
        end

        function compare_clear(app)
            app.compare_runs = []; app.compare_sel = [];
            app.compare_refresh();
        end

        function M = run_metrics(app, r, md)
            % Design-speed summary of one run (comparison table)
            M = struct('PR', r.PR_design, 'eta', r.Eff_design, 'lim_type', '-', 'SM', NaN, 'CM', NaN, ...
                       'range', NaN, 'koch', NaN, 'koch_level', '-', 'Bstar', NaN);
            k1 = find(abs(r.speed_ratio - 1) < 1e-9, 1);
            if ~isempty(k1)
                M.lim_type = r.lim_type{k1};
                if ~isnan(r.lim_m(k1)), M.SM = 100*((r.lim_PR(k1)/r.lim_m(k1))*(md/r.PR_design) - 1); end
                if ~isnan(r.choke_m(k1))
                    M.CM = 100*(r.choke_m(k1)/md - 1);
                    if ~isnan(r.lim_m(k1)), M.range = 100*(1 - r.lim_m(k1)/r.choke_m(k1)); end
                end
                M.Bstar = r.B_star(k1);
            end
            if ~isempty(r.koch_design), M.koch = max([r.koch_design.ratio]); end
            KA = app.get_koch_applicability(r); M.koch_level = KA.level;
        end

        function [cols, data] = compare_table_data(app)
            cols = {'Show', 'Label', 'Configuration', 'Source', 'PR_des', 'eta_des', 'First limit (N=1)', 'SM [%]', ...
                    'Choke margin [%]', 'Range [%]', 'Koch ratio (max)', 'Koch applicability', 'U/(2a_p)'};
            runs = app.compare_runs;
            data = cell(numel(runs), numel(cols));
            f = @(x, n) round(real(x)*10^n)/10^n;
            for k = 1:numel(runs)
                e = runs(k); M = app.run_metrics(e.results, e.m_dot);
                src = e.source;
                if ~strcmp(src, 'last run'), [~, n1, x1] = fileparts(src); src = [n1, x1]; end
                data(k, :) = {logical(e.show), e.label, e.type, src, f(M.PR, 4), f(M.eta, 4), M.lim_type, f(M.SM, 1), ...
                              f(M.CM, 1), f(M.range, 1), f(M.koch, 3), M.koch_level, f(M.Bstar, 3)};
            end
        end

        function compare_refresh(app)
            % Comparison table and overlay maps
            if app.has_ui('CompareTable')
                [cols, data] = app.compare_table_data();
                app.CompareTable.ColumnName = cols;
                app.CompareTable.Data = data;
                ed = false(1, numel(cols)); ed(1:2) = true;
                app.CompareTable.ColumnEditable = ed;
            end
            P = {'CmpRelPRAxes', 'CmpRelEffAxes', 'relative'; 'CmpNdPRAxes', 'CmpNdEffAxes', 'MFP'};
            for p = 1:size(P, 1)
                if app.has_ui(P{p, 1}) && app.has_ui(P{p, 2})
                    app.plot_compare(app.(P{p, 1}), app.(P{p, 2}), P{p, 3});
                end
            end
        end

        function plot_compare(app, axPR, axEff, mode)
            % Overlay of the shown runs: speed lines (light), first stability limit
            % (solid, thick), choke line (dash-dot) and design point (star) per run
            app.clear_axes(axPR); app.clear_axes(axEff); hold(axPR, 'on'); hold(axEff, 'on');
            pal = [0 0.447 0.741; 0.85 0.325 0.098; 0.466 0.674 0.188; 0.494 0.184 0.556; ...
                   0.301 0.745 0.933; 0.635 0.078 0.184; 0.929 0.694 0.125; 0.25 0.25 0.25];
            runs = app.compare_runs;
            hP = []; hE = []; labs = {};
            for k = 1:numel(runs)
                if ~runs(k).show, continue; end
                r = runs(k).results; md = runs(k).m_dot;
                c = pal(mod(k-1, size(pal, 1)) + 1, :); cl = c + (1 - c)*0.6;
                if strcmp(mode, 'relative')
                    sx = 1/md; sP = 1/r.PR_design; sE = 1/r.Eff_design; xd = 1; yP = 1; yE = 1;
                else
                    sx = r.MFP1_design/md; sP = 1; sE = 1; xd = r.MFP1_design; yP = r.PR_design; yE = r.Eff_design;
                end
                m = r.mass_dot_range(:)';
                for u = 1:numel(r.speed_ratio)
                    PRu = real(r.Total_PR(u, :)); Eu = real(r.Overall_Eff(u, :));
                    v = ~isnan(PRu) & ~isnan(Eu) & Eu > 0.1 & Eu < 1 & PRu > 1;
                    if ~isnan(r.lim_m(u)), v = v & m >= r.lim_m(u); end
                    if ~isnan(r.choke_m(u)), v = v & m <= r.choke_m(u); end
                    if sum(v) < 2, continue; end
                    plot(axPR, m(v)*sx, PRu(v)*sP, '-', 'Color', cl, 'LineWidth', 0.8, 'HandleVisibility', 'off');
                    plot(axEff, m(v)*sx, Eu(v)*sE, '-', 'Color', cl, 'LineWidth', 0.8, 'HandleVisibility', 'off');
                end
                ok = ~isnan(r.lim_m(:));
                [xl, o] = sort(r.lim_m(ok)*sx);
                yl = real(r.lim_PR(ok)); yl = yl(o)*sP; ye = real(r.lim_Eff(ok)); ye = ye(o)*sE;
                hP(end+1) = plot(axPR, xl, yl, '-', 'Color', c, 'LineWidth', 2.5);
                hE(end+1) = plot(axEff, xl, ye, '-', 'Color', c, 'LineWidth', 2.5);
                ci = logical(r.choke_in_region(:)) & ~isnan(r.choke_m(:));
                if sum(ci) > 1
                    [xc, o] = sort(r.choke_m(ci)*sx);
                    yc = real(r.choke_PR(ci)); yc = yc(o)*sP; yce = real(r.choke_Eff(ci)); yce = yce(o)*sE;
                    plot(axPR, xc, yc, '-.', 'Color', c, 'LineWidth', 1.8, 'HandleVisibility', 'off');
                    plot(axEff, xc, yce, '-.', 'Color', c, 'LineWidth', 1.8, 'HandleVisibility', 'off');
                end
                plot(axPR, xd, yP, 'p', 'MarkerSize', 13, 'MarkerFaceColor', c, 'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
                plot(axEff, xd, yE, 'p', 'MarkerSize', 13, 'MarkerFaceColor', c, 'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
                labs{end+1} = runs(k).label;
            end
            if strcmp(mode, 'relative')
                xlabel(axPR, 'MFP / MFP_{des}'); ylabel(axPR, 'PR / PR_{des}');
                xlabel(axEff, 'MFP / MFP_{des}'); ylabel(axEff, '\eta / \eta_{des}');
                title(axPR, 'Relative pressure ratio'); title(axEff, 'Relative efficiency');
            else
                xlabel(axPR, 'MFP_1'); ylabel(axPR, 'PR'); xlabel(axEff, 'MFP_1'); ylabel(axEff, '\eta');
                title(axPR, 'Non-dimensional pressure ratio'); title(axEff, 'Non-dimensional efficiency');
            end
            grid(axPR, 'on'); grid(axEff, 'on');
            if isempty(hP)
                legend(axPR, 'off'); legend(axEff, 'off');
                text(axPR, 0.5, 0.5, 'Add runs with "Add last run" or "Add .mat file"', 'Units', 'normalized', ...
                    'HorizontalAlignment', 'center', 'Color', [0.4 0.4 0.4]);
            else
                legend(axPR, hP, labs, 'Location', 'best', 'Interpreter', 'none');
                legend(axEff, hE, labs, 'Location', 'best', 'Interpreter', 'none');
            end
        end

        function compare_export(app, file, opts)
            % Comparison export: the user chooses runs, graphs, contents and file types
            if isempty(app.compare_runs)
                uialert(app.UIFigure, 'Add runs to the comparison first.', 'Nothing to export'); return;
            end
            if nargin < 3
                opts = app.compare_export_dialog();
                if isempty(opts), return; end
            end
            if isempty(opts.runs)
                uialert(app.UIFigure, 'Choose at least one run.', 'Export comparison'); return;
            end
            if ~(opts.pdf || opts.png || opts.xlsx)
                uialert(app.UIFigure, 'Choose at least one file type (PDF, PNG or Excel).', 'Export comparison'); return;
            end
            if nargin < 2 || isempty(file)
                [fn, pth] = uiputfile('*.pdf', 'Base name of the comparison files', fullfile(app.start_folder(), ...
                    sprintf('Comparison_%druns.pdf', numel(opts.runs))));
                if isequal(fn, 0), return; end
                file = fullfile(pth, fn); app.last_folder = pth;
            end
            try
                files = app.compare_report(opts, file);
            catch err
                uialert(app.UIFigure, ['Comparison export failed: ' err.message], 'Export comparison'); return;
            end
            uialert(app.UIFigure, sprintf('%d file(s) written:\n%s', numel(files), strjoin(files, newline)), ...
                'Export comparison', 'Icon', 'success');
        end

        function opts = compare_export_dialog(app)
            % Small window: which runs, which graphs, which contents, which files
            opts = [];
            runs = app.compare_runs;
            labs = {runs.label};
            d = uifigure('Name', 'Export comparison', 'Position', [300 200 580 390], 'WindowStyle', 'modal', 'Resize', 'off');
            uilabel(d, 'Text', 'Runs to include (Ctrl+click for several)', 'FontWeight', 'bold', 'Position', [15 355 280 22]);
            lb = uilistbox(d, 'Items', labs, 'ItemsData', 1:numel(labs), 'Multiselect', 'on', 'Position', [15 150 270 200]);
            sel = find([runs.show]); if isempty(sel), sel = 1:numel(labs); end
            lb.Value = sel;
            uilabel(d, 'Text', 'Graphs', 'FontWeight', 'bold', 'Position', [305 355 260 22]);
            g = {'Relative: pressure ratio', 'Relative: efficiency', 'Non-dimensional: pressure ratio', 'Non-dimensional: efficiency'};
            cg = cell(1, 4);
            for k = 1:4
                cg{k} = uicheckbox(d, 'Text', g{k}, 'Value', true, 'Position', [315 355-24*k 250 22]);
            end
            uilabel(d, 'Text', 'Contents', 'FontWeight', 'bold', 'Position', [305 230 260 22]);
            c1 = uicheckbox(d, 'Text', 'Comparison table', 'Value', true, 'Position', [315 206 250 22]);
            c2 = uicheckbox(d, 'Text', 'Inputs of each run (.mat data)', 'Value', true, 'Position', [315 182 250 22]);
            c3 = uicheckbox(d, 'Text', 'Diagnostics of each run', 'Value', false, 'Position', [315 158 250 22]);
            uilabel(d, 'Text', 'Files', 'FontWeight', 'bold', 'Position', [15 115 260 22]);
            f1 = uicheckbox(d, 'Text', 'PDF report', 'Value', true, 'Position', [25 91 120 22]);
            f2 = uicheckbox(d, 'Text', 'PNG images (300 dpi)', 'Value', false, 'Position', [150 91 170 22]);
            f3 = uicheckbox(d, 'Text', 'Excel tables', 'Value', false, 'Position', [330 91 150 22]);
            uilabel(d, 'Text', 'All files share the base name you choose next.', 'FontColor', [0.4 0.4 0.4], 'Position', [25 64 400 22]);
            uibutton(d, 'Text', 'Export...', 'Position', [350 18 100 30], 'ButtonPushedFcn', @(~, ~) uiresume(d));
            uibutton(d, 'Text', 'Cancel', 'Position', [460 18 100 30], 'ButtonPushedFcn', @(~, ~) delete(d));
            uiwait(d);
            if ~isvalid(d), return; end          % cancelled or closed
            opts = struct('runs', lb.Value, 'graphs', [cg{1}.Value, cg{2}.Value, cg{3}.Value, cg{4}.Value], ...
                'table', c1.Value, 'inputs', c2.Value, 'diagnostics', c3.Value, ...
                'pdf', f1.Value, 'png', f2.Value, 'xlsx', f3.Value);
            delete(d);
        end

        function files = compare_report(app, opts, file)
            % Writes the chosen comparison outputs. opts.graphs = [rel PR, rel eff, nd PR, nd eff]
            [p, n] = fileparts(file);
            files = {};
            sel = opts.runs(:)';
            saved_show = [app.compare_runs.show];
            for k = 1:numel(app.compare_runs), app.compare_runs(k).show = ismember(k, sel); end
            runs = app.compare_runs(sel);
            G = {'relative', 'Relative', 'pressure ratio', 1; 'relative', 'Relative', 'efficiency', 2; ...
                 'MFP', 'NonDimensional', 'pressure ratio', 1; 'MFP', 'NonDimensional', 'efficiency', 2};
            try
                [cols, data] = app.compare_table_data();
                data = data(sel, 2:end); cols = cols(2:end);          % without the Show column
                tag = sprintf('Comparison of %d runs  |  %s', numel(sel), datestr(now, 'yyyy-mm-dd HH:MM'));
                if opts.pdf
                    final_pdf = fullfile(p, [n, '.pdf']);
                    pdf = [tempname, '.pdf'];   % step 20: moved to the chosen name when complete
                    app.open_progress('Export comparison', 1 + sum([any(opts.graphs(1:2)), any(opts.graphs(3:4))]) + ...
                        numel(runs)*(opts.inputs + opts.diagnostics));
                    pg = 0;
                    L = {'Runs:'};
                    for k = 1:numel(runs)
                        L{end+1} = sprintf('  %d. %s  -  %s  -  %s', k, runs(k).label, runs(k).type, runs(k).source);
                    end
                    L = [L, {'', 'Line styles on the graphs: solid = first stability limit, dash-dot = choke line, star = design point, light lines = speed lines.', ''}];
                    if opts.table, L = [L, app.table_text(cols, data)]; end
                    pg = app.pdf_text(pdf, 'Comparison', L, pg, tag, true);
                    for q = [1 3]                                       % one page per map kind
                        want = opts.graphs([q, q+1]);
                        if ~any(want), continue; end
                        pg = pg + 1;
                        f = app.pdf_page(sprintf('%s comparison', G{q, 2}), pg, tag);
                        [a1, a2, junk] = app.pdf_axes_pair(f, want);
                        app.plot_compare(a1, a2, G{q, 1});
                        if ~isempty(junk), close(junk); end
                        app.pdf_save(f, pdf, pg);
                    end
                    for k = 1:numel(runs)
                        r = runs(k).results;
                        if opts.inputs
                            [c2, d2] = app.result_table(r, 'Inputs');
                            pg = app.pdf_text(pdf, ['Inputs: ', runs(k).label], app.table_text(c2, d2), pg, tag, true);
                        end
                        if opts.diagnostics
                            m_saved = app.m_dot; app.m_dot = runs(k).m_dot;
                            Ld = app.diagnostics_lines(r);
                            app.m_dot = m_saved;
                            pg = app.pdf_text(pdf, ['Diagnostics: ', runs(k).label], Ld, pg, tag);
                        end
                    end
                    movefile(pdf, final_pdf, 'f');
                    app.close_progress();
                    files{end+1} = final_pdf;
                end
                if opts.png
                    for q = 1:4
                        if ~opts.graphs(q), continue; end
                        f = figure('Visible', 'off', 'Color', 'w', 'Position', [50 50 900 680]);
                        a = axes(f); fj = figure('Visible', 'off'); b = axes(fj);
                        if G{q, 4} == 1, app.plot_compare(a, b, G{q, 1}); else, app.plot_compare(b, a, G{q, 1}); end
                        close(fj);
                        fn = fullfile(p, sprintf('%s_%s_%s.png', n, G{q, 2}, strrep(G{q, 3}, ' ', '_')));
                        exportgraphics(f, fn, 'Resolution', 300);
                        close(f); files{end+1} = fn;
                    end
                end
                if opts.xlsx
                    xl = fullfile(p, [n, '.xlsx']);
                    if isfile(xl), delete(xl); end
                    writecell([cols; data], xl, 'Sheet', 'Comparison');
                    if opts.inputs
                        for k = 1:numel(runs)
                            [c2, d2] = app.result_table(runs(k).results, 'Inputs');
                            writecell([c2; d2], xl, 'Sheet', sprintf('Inputs %d', k));
                        end
                    end
                    files{end+1} = xl;
                end
            catch err
                for k = 1:numel(app.compare_runs), app.compare_runs(k).show = saved_show(k); end
                app.close_progress();
                rethrow(err);
            end
            for k = 1:numel(app.compare_runs), app.compare_runs(k).show = saved_show(k); end
        end

        % =================== step 14: PDF report ===================
        function L = wrap_lines(app, L, w)
            out = {};
            for k = 1:numel(L)
                s = L{k};
                while numel(s) > w
                    cut = find(s(1:w) == ' ', 1, 'last');
                    if isempty(cut) || cut < w/2, cut = w; end
                    out{end+1} = s(1:cut); s = ['      ', strtrim(s(cut+1:end))];
                end
                out{end+1} = s;
            end
            L = out;
        end

        function L = table_text(app, cols, data)
            % A results table as aligned text lines
            S = [cols(:)'; data];
            for k = 1:numel(S)
                v = S{k};
                if islogical(v), if v, v = 'yes'; else, v = 'no'; end
                elseif isnumeric(v), if isempty(v), v = ''; else, v = sprintf('%.5g', v + 0); end   % +0 turns -0 into 0
                end
                v = char(v);
                if numel(v) > 38, v = [v(1:35), '...']; end
                S{k} = v;
            end
            w = max(cellfun(@numel, S), [], 1);
            L = {};
            for i = 1:size(S, 1)
                s = '';
                for j = 1:size(S, 2), s = [s, sprintf('%-*s  ', w(j), S{i, j})]; end
                L{end+1} = s;
                if i == 1, L{end+1} = repmat('-', 1, numel(s)); end
            end
        end

        function [f, fr] = pdf_page(app, ttl, pg, tag)
            % One A4-landscape report page with a frame, a title and a footer. The frame
            % gives every page the same size (exportgraphics crops to the content).
            f = figure('Visible', 'off', 'Color', 'w', 'Units', 'centimeters', 'Position', [1 1 29.7 21]);
            fr = axes(f, 'Units', 'normalized', 'Position', [0 0 1 1], 'XLim', [0 1], 'YLim', [0 1], 'Visible', 'off');
            hold(fr, 'on');
            plot(fr, [0.004 0.996 0.996 0.004 0.004], [0.006 0.006 0.994 0.994 0.006], '-', 'Color', [0.82 0.82 0.82], 'LineWidth', 0.5);
            plot(fr, [0.03 0.97], [0.935 0.935], '-', 'Color', [0.15 0.15 0.15], 'LineWidth', 0.8);
            text(fr, 0.03, 0.962, ttl, 'FontSize', 13, 'FontWeight', 'bold', 'Interpreter', 'none', 'VerticalAlignment', 'middle');
            text(fr, 0.97, 0.025, sprintf('%s   |   page %d', tag, pg), 'FontSize', 8, 'Color', [0.4 0.4 0.4], ...
                'HorizontalAlignment', 'right', 'Interpreter', 'none');
        end

        function pdf_save(app, f, file, pg)
            % Write one page (the first page creates the file) and close the figure
            if pg <= 1
                exportgraphics(f, file, 'ContentType', 'vector');
            else
                exportgraphics(f, file, 'ContentType', 'vector', 'Append', true);
            end
            close(f);
            if ~isempty(app.pdf_progress) && isvalid(app.pdf_progress)
                app.pdf_progress.Value = min(0.98, pg/max(app.pdf_total, pg + 1));
                app.pdf_progress.Message = sprintf('Writing page %d of about %d ...', pg, max(app.pdf_total, pg));
            end
        end

        function open_progress(app, ttl, total)
            % Progress bar for a PDF export (nothing in a test without a window)
            app.pdf_total = total; app.pdf_progress = [];
            if app.has_ui('UIFigure')
                app.pdf_progress = uiprogressdlg(app.UIFigure, 'Title', ttl, 'Message', 'Starting ...', 'Value', 0);
            end
        end

        function close_progress(app)
            if ~isempty(app.pdf_progress) && isvalid(app.pdf_progress), close(app.pdf_progress); end
            app.pdf_progress = [];
        end

        function [a1, a2, junk] = pdf_axes_pair(app, f, want)
            % Two side-by-side axes on a page; if only one of the pair is wanted it
            % fills the page and the other is drawn in a hidden scratch figure (junk)
            junk = [];
            if all(want)
                a1 = axes(f, 'Units', 'normalized', 'Position', [0.06 0.10 0.41 0.78]);
                a2 = axes(f, 'Units', 'normalized', 'Position', [0.555 0.10 0.41 0.78]);
            else
                big = axes(f, 'Units', 'normalized', 'Position', [0.08 0.10 0.86 0.78]);
                junk = figure('Visible', 'off'); other = axes(junk);
                if want(1), a1 = big; a2 = other; else, a1 = other; a2 = big; end
            end
        end

        function pg = pdf_text(app, file, ttl, L, pg, tag, istable)
            % Text on one or more report pages; the font fits the longest line
            % (5.5-9 pt) and long texts continue on the next page. Prose is wrapped
            % at 150 characters; table rows (istable) are kept on one line.
            if nargin < 7, istable = false; end
            if isempty(L), L = {''}; end
            if istable, wmax = 240; else, wmax = 150; end
            L = app.wrap_lines(L(:)', wmax);
            W = max(cellfun(@numel, L));
            usable_w = 0.94*29.7/2.54*72;                  % points
            usable_h = 0.87*21/2.54*72;
            fs = max(5.5, min(9, usable_w/(0.6*max(W, 1))));
            npp = max(10, floor(usable_h/(1.22*fs)));
            nP = ceil(numel(L)/npp);
            for q = 1:nP
                pg = pg + 1;
                t = ttl; if q > 1, t = [ttl, ' (continued)']; end
                [f, fr] = app.pdf_page(t, pg, tag);
                chunk = L((q-1)*npp + 1:min(q*npp, numel(L)));
                text(fr, 0.03, 0.915, chunk, 'VerticalAlignment', 'top', 'FontName', 'Courier New', ...
                    'FontSize', fs, 'Interpreter', 'none');
                app.pdf_save(f, file, pg);
            end
        end

        function export_pdf_report(app, file)
            % One PDF, all pages A4 landscape: summary + diagnostics, inputs, the four
            % maps (standard, non-dimensional, relative, corrected), the fitted
            % equations, then every table. (MATLAB R2021b or newer)
            if isempty(app.computation_results)
                uialert(app.UIFigure, 'Run the computation first.', 'Nothing to export'); return;
            end
            if nargin < 2
                [fn, pth] = uiputfile('*.pdf', 'Export report', fullfile(app.start_folder(), sprintf('Report_%s.pdf', app.run_name())));
                if isequal(fn, 0), return; end
                file = fullfile(pth, fn); app.last_folder = pth;
            end
            final = file;
            file = [tempname, '.pdf'];        % step 20: written here, moved to the chosen name when complete
            r = app.computation_results;
            saved_eq = app.equation_log;
            tag = sprintf('%s  |  %s', app.run_name(), datestr(now, 'yyyy-mm-dd HH:MM'));
            app.open_progress('Export report', 7 + numel(app.result_table_names()) - 3);
            try
                pg = 0;
                L = [{sprintf('%s  |  run: %s', r.compressor_type, app.run_name()), ''}, app.diagnostics_lines(r)];
                pg = app.pdf_text(file, 'Compressor off-design report: summary and diagnostics', L, pg, tag);
                [cols, data] = app.result_table(r, 'Inputs');
                pg = app.pdf_text(file, 'Inputs of this run (.mat data and settings)', app.table_text(cols, data), pg, tag, true);
                n0 = numel(app.equation_log);
                K = app.map_kinds();
                for p = 1:size(K, 1)
                    pg = pg + 1;
                    f = app.pdf_page(sprintf('%s  -  %s', K{p, 2}, r.compressor_type), pg, tag);
                    [a1, a2] = app.pdf_axes_pair(f, [true true]);
                    app.plot_map_kind(K(p, :), r, a1, a2);
                    set([a1, a2], 'FontSize', 9);                     % page title names the map;
                    title(a1, 'Pressure ratio'); title(a2, 'Efficiency');   % short axes titles do not overlap
                    app.pdf_save(f, file, pg);
                end
                eq = app.equation_log(n0+1:end);
                if isempty(eq), eq = saved_eq; end
                eq = strsplit(strjoin(eq, sprintf('\n\n')), newline);
                pg = app.pdf_text(file, 'Fitted boundary equations (surge, stall onset, choke)', eq, pg, tag, true);
                names = app.result_table_names();
                for t = 1:numel(names)
                    if any(strcmp(names{t}, {'Koch design check', 'Inputs', 'Validation lines'})), continue; end   % pages 1-2 / Excel only
                    [cols, data] = app.result_table(r, names{t});
                    pg = app.pdf_text(file, names{t}, app.table_text(cols, data), pg, tag, true);
                end
                movefile(file, final, 'f');    % the finished report appears only now
            catch err
                app.equation_log = saved_eq;
                app.close_progress();
                if isfile(file), delete(file); end
                uialert(app.UIFigure, ['Report export failed: ' err.message], 'Export report');
                return;
            end
            app.equation_log = saved_eq;
            app.close_progress();
            uialert(app.UIFigure, sprintf('Report written (%d pages):\n%s', pg, final), 'Export report', 'Icon', 'success');
        end

        function sync_settings_from_mat(app)
            % A Settings value that the loaded .mat file sets (howell_factor, eps_over_g,
            % V_plenum, Tt1, ...) is written into its field and the field is locked,
            % so the Settings tab always shows what Run will use. Without that
            % variable in the .mat, the field is editable as usual.
            M = {'correlation_set', 'CorrelationSetDropDown'; 'howell_factor', 'HowellFactorEditField'; ...
                 'bucket_width', 'BucketWidthEditField'; 'bucket_width_neg', 'BucketWidthNegEditField'; ...
                 'min_ref_deflection', 'MinRefDeflEditField'; 'blockage', 'BlockageEditField'; 're_exponent', 'ReExponentEditField'; ...
                 'eps_over_g', 'KochEpsOverGEditField'; 'dz_over_s', 'KochDzOverSEditField'; ...
                 'B_crit', 'BcritEditField'; 'V_plenum', 'VplenumEditField'; 'L_duct', 'LductEditField'; ...
                 'Tt1', 'TinEditField'; 'Pt1', 'PinEditField'};
            d = app.loadedData;
            for k = 1:size(M, 1)
                fld = M{k, 2};
                if ~app.has_ui(fld), continue; end
                h = app.(fld);
                fromMat = isstruct(d) && isfield(d, M{k, 1});
                locked = strcmp(h.Enable, 'off') && isstruct(h.UserData);
                if fromMat
                    if ~locked                                            % keep the user's own value and tooltip
                        h.UserData = struct('val', h.Value, 'tip', h.Tooltip);
                    end
                    v = d.(M{k, 1});
                    try
                        if ischar(v) || isstring(v)
                            h.Value = char(v);
                        else
                            v = double(v(1));
                            if isnan(v) || v <= 0, v = 0; end                % NaN / 0 = not given (V_p, L_c)
                            h.Value = v;
                        end
                    catch
                    end
                    h.Enable = 'off';
                    h.Tooltip = sprintf('Set by the loaded .mat file (variable %s). Remove it from the .mat to edit it here.', M{k, 1});
                elseif locked                                             % .mat gone: give the user's value back
                    h.Value = h.UserData.val;
                    h.Tooltip = h.UserData.tip;
                    h.Enable = 'on';
                    h.UserData = [];
                end
            end
        end

        function clear_axes(app, ax)
            % Delete every plotted object of an axes, also those with hidden handles
            % (cla keeps them); title and axis labels stay
            keep = {get(ax, 'Title'), get(ax, 'XLabel'), get(ax, 'YLabel'), get(ax, 'ZLabel')};
            k = allchild(ax);
            for q = 1:numel(k)
                if ~any(cellfun(@(h) isequal(h, k(q)), keep))
                    delete(k(q));
                end
            end
        end

        function lock_inputs(app)
            % All Manual and File inputs disabled, as at start-up; the user opens them
            % again with "Choose Input type" (used by Reset)
            set(findobj(app.ManualTab, 'Type', 'uieditfield'), 'Enable', 'off');
            set(findobj(app.ManualTab, 'Type', 'uinumericeditfield'), 'Enable', 'off');
            set(findobj(app.ManualTab, 'Type', 'uilabel'), 'Enable', 'off');
            set(findobj(app.FileTab, 'Type', 'uieditfield'), 'Enable', 'off');
            set(findobj(app.FileTab, 'Type', 'uilabel'), 'Enable', 'off');
            set(findobj(app.FileTab, 'Type', 'uibutton'), 'Enable', 'off');
            app.Inputs.SelectedTab = app.ManualTab;
        end

        function [nk, nb] = koch_line_count(app, results)
            % nk: speed lines with a Koch limit point; nb: lines above the limit everywhere
            nk = 0; nb = 0;
            if isfield(results, 'koch_points'), nk = sum(~isnan(results.koch_points)); end
            if isfield(results, 'koch_stage') && iscell(results.koch_stage)
                nb = sum(strncmp(results.koch_stage, 'BEYOND|', 7));
            end
        end

        function t = koch_line_text(app, results)
            % Whether a Koch line can be drawn on the maps, in words
            [nk, nb] = app.koch_line_count(results);
            N = results.speed_ratio(:);
            if nk > 0
                v = ~isnan(results.koch_points(:));
                t = sprintf('Koch line: drawn on %d of %d speed lines (N/N_des %.2f to %.2f).', nk, numel(N), min(N(v)), max(N(v)));
            elseif nb > 0
                t = sprintf(['Koch line: none to draw. The stage is above the Koch limit (Ch_ef/Ch_max > 1) on the whole ' ...
                    'computed part of %d speed line(s); see the Koch design check.'], nb);
            else
                t = ['Koch line: none to draw. No speed line reaches Ch_ef/Ch_max = 1 before the peak or Howell limit, ' ...
                    'so the stage stays below its Koch limit over the whole stable range.'];
            end
        end

        function p = start_folder(app)
            if isempty(app.last_folder) || ~isfolder(app.last_folder), p = pwd; else, p = app.last_folder; end
        end

        function nm = make_run_name(app)
            % .mat name for file runs (comparison runs too), Manual_<type> for manual input
            fromMat = app.quiet || (app.has_ui('matfileinputButton') && isequal(app.InputType_value, app.matfileinputButton));
            if fromMat && ~isempty(app.mat_name)
                nm = app.mat_name;
            else
                nm = ['Manual_', app.Compressor_type];
            end
            nm = regexprep(nm, '[^\w\-]+', '_');
        end

        function nm = run_name(app)
            nm = 'compressor';
            r = app.computation_results;
            if isstruct(r) && isfield(r, 'run_name'), nm = r.run_name; end
        end

        function data = inputs_table_data(app, results)
            % Variable / value / unit / source of everything the run used
            U = {'alpha1', 'deg'; 'n_stages', '-'; 'A_vec', 'm^2'; 'beta1_dash', 'deg'; 'beta2_dash', 'deg'; ...
                 'beta3_dash', 'deg'; 'beta4_dash', 'deg'; 'deviation', 'deg'; 'deviation_1', 'deg'; 'deviation_2', 'deg'; ...
                 'incidence', 'deg'; 'incidence_1', 'deg'; 'incidence_2', 'deg'; 'deflection', 'deg'; ...
                 'deflection_1', 'deg'; 'deflection_2', 'deg'; 'm_dot', 'kg/s'; 'w_loss_rotor', '-'; ...
                 'w_loss_stator', '-'; 'w_loss_rotor2', '-'; 'U', 'm/s'; 'U1', 'm/s'; 'U2', 'm/s'; ...
                 'sigma_rotor', '-'; 'sigma_stator', '-'; 'sigma_1', '-'; 'sigma_2', '-'; 'chord', 'm'; ...
                 'eps_over_g', '-'; 'dz_over_s', '-'; 'V_plenum', 'm^3'; 'L_duct', 'm'; 'B_crit', '-'; ...
                 'Tt1', 'K'; 'Pt1', 'Pa'; 'howell_factor', '-'; 'bucket_width', '-'; 'bucket_width_neg', '-'; ...
                 'min_ref_deflection', 'deg'; 'blockage', '-'; 're_exponent', '-'; 'correlation_set', '-'; 'loss_coeffs', '-'; ...
                 'dev_coeffs', '-'; 'dev_x_min', '-'; 'koch_in_limit', '-'; ...
                 'stator_beta_in', 'deg'; 'stator_beta_out', 'deg'; 'stator_incidence', 'deg'; 'stator_deviation', 'deg'; ...
                 'stator_deflection', 'deg'; 'meas_N', '-'; 'meas_m', 'kg/s'; 'meas_PR', '-'; 'meas_eta', '-'};
            unit = @(n) app.lookup(U, n, '');
            fmt = @(v) app.value_text(v);
            fromMat = app.quiet || (app.has_ui('matfileinputButton') && isequal(app.InputType_value, app.matfileinputButton));
            if fromMat && ~isempty(app.mat_name), src = ['.mat: ', app.mat_name]; else, src = 'Manual input'; end
            data = {'Configuration', app.Compressor_type, '', ''; 'Input source', src, '', ''};
            map = app.input_map(app.Compressor_type);
            for k = 1:size(map, 1)
                data(end+1, :) = {map{k, 2}, fmt(app.(map{k, 1})), unit(map{k, 2}), src};
            end
            d = app.loadedData;
            if fromMat && isstruct(d)
                opt = app.optional_mat_vars();
                for k = 1:numel(opt)
                    if isfield(d, opt{k})
                        data(end+1, :) = {opt{k}, fmt(d.(opt{k})), unit(opt{k}), [src, ' (optional)']};
                    end
                end
            end
            S = {'Correlation set', results.correlation_set, '';
                 'Howell factor', fmt(results.howell_factor), '-';
                 'Loss-bucket width factor', fmt(results.bucket_width), '-';
                 'Design inlet Tt1', fmt(results.Tt1), 'K';
                 'Design inlet pt1', fmt(results.Pt1), 'Pa';
                 'Speed lines N/N_des', sprintf('%.2f to %.2f (%d lines)', min(results.speed_ratio), max(results.speed_ratio), numel(results.speed_ratio)), '-';
                 'Mass-flow points per line', sprintf('%d', numel(results.mass_dot_range)), '-';
                 'Koch target Ch_ef/Ch_max', fmt(app.koch_target_ratio), '-';
                 'B critical', fmt(results.B_crit), '-';
                 'T_ref / p_ref (corrected map)', sprintf('%.2f / %.0f', app.T_ref, app.p_ref), 'K / Pa'};
            if isfield(results, 'model_options')                     % step 25
                o = results.model_options;
                S = [S; {'Choke-side bucket width', fmt(o.kx_neg), '-'; 'Minimum reference deflection', fmt(o.eps_min), 'deg'; ...
                         'Choke area factor(s)', fmt(o.blockage), '-'; 'Reynolds-correction exponent', fmt(o.re_n), '-'}];
            end
            if isfield(results, 'koch_geometry') && ~isempty(results.koch_geometry)
                S(end+1, :) = {'Koch tip clearance eps/g', fmt(results.koch_geometry.eps_over_g), '-'};
                S(end+1, :) = {'Koch axial gap dz/s', fmt(results.koch_geometry.dz_over_s), '-'};
            end
            for k = 1:size(S, 1)
                data(end+1, :) = {S{k, 1}, S{k, 2}, S{k, 3}, 'Run settings'};
            end
        end

        function v = lookup(app, T, name, default)
            j = find(strcmp(T(:, 1), name), 1);
            if isempty(j), v = default; else, v = T{j, 2}; end
        end

        function t = value_text(app, v)
            if ischar(v) || isstring(v), t = char(v);
            elseif islogical(v), if all(v), t = 'true'; else, t = 'false'; end
            elseif isnumeric(v) && isempty(v), t = '';
            elseif isnumeric(v), t = strtrim(sprintf('%.6g ', v));
            else, t = class(v);
            end
        end

        function K = map_kinds(app)
            % {file prefix, page title, PR plot function, efficiency plot function}
            K = {'Dimensional', 'Standard (dimensional) map', 'plot_standard_compressor_map_PR', 'plot_standard_compressor_map_Eff'; ...
                 'NonDimensional', 'Non-dimensional map', 'plot_non_dimensional_compressor_map_PR', 'plot_non_dimensional_compressor_map_Eff'; ...
                 'Relative', 'Relative non-dimensional map', 'plot_relative_non_dimensional_compressor_map_PR', 'plot_relative_non_dimensional_compressor_map_Eff'; ...
                 'Corrected', 'Corrected map', 'corrected', ''};
        end

        function plot_map_kind(app, k, r, a1, a2)
            % One map kind into two axes (PR, efficiency), Show boxes applied
            if strcmp(k{3}, 'corrected')
                evalc('app.plot_corrected_compressor_map(a1, a2, r);');
            else
                evalc('app.(k{3})(a1, r);'); evalc('app.(k{4})(a2, r);');
            end
            app.apply_visibility_to([a1, a2]);
        end

        function f = map_figure(app, k, r)
            % Hidden figure with one map kind (PR left, efficiency right) for the PNG export
            f = figure('Visible', 'off', 'Color', 'w', 'Position', [50 50 1500 660]);
            a1 = subplot(1, 2, 1, 'Parent', f); a2 = subplot(1, 2, 2, 'Parent', f);
            app.plot_map_kind(k, r, a1, a2);
            try
                sgtitle(f, sprintf('%s  -  %s', k{2}, strrep(app.run_name(), '_', '\_')));
            catch
            end
        end

        function files = write_map_pngs(app, pth)
            % <kind>_<run name>.png for the four map kinds
            r = app.computation_results; saved_eq = app.equation_log; files = {};
            K = app.map_kinds();
            for p = 1:size(K, 1)
                f = app.map_figure(K(p, :), r);
                fn = fullfile(pth, sprintf('%s_%s.png', K{p, 1}, app.run_name()));
                exportgraphics(f, fn, 'Resolution', 300);
                close(f); files{end+1} = fn;
            end
            app.equation_log = saved_eq;
        end

        function names = result_table_names(app)
            % Tables available in the Tables tab (same order as the drop-down items)
            names = {'Inputs', 'Design point', 'Choke', 'Stall onset (Howell)', 'Peak (zero slope)', ...
                     'Koch limit', 'Koch design check', 'Stability limit & Greitzer B', 'Blade rows', ...
                     'Validation summary', 'Validation points', 'Validation lines'};
        end

        function [cols, data] = result_table(app, results, which)
            % One results table as column names + cell data (for uitable / export)
            N = results.speed_ratio(:);
            nU = numel(N);
            f = @(x, n) round(real(x)*10^n)/10^n;
            switch which
                case 'Inputs'
                    cols = {'Variable', 'Value', 'Unit', 'Source'};
                    if isfield(results, 'inputs_table'), data = results.inputs_table;
                    else, data = {'not stored with this run: run again', '', '', ''}; end
                case 'Design point'
                    cols = {'Quantity', 'Value'};
                    data = {'Configuration', results.compressor_type; ...
                            'Pressure ratio PR_des', f(results.PR_design, 5); ...
                            'Isentropic efficiency eta_des', f(results.Eff_design, 5); ...
                            'Mass flow m_des [kg/s]', app.m_dot; ...
                            'MFP_1,des', f(results.MFP1_design, 5); ...
                            'Corrected mass flow [kg/s]', f(results.m_corr_design, 5); ...
                            'Inlet Tt1 [K] / Pt1 [Pa]', sprintf('%g / %g', results.Tt1, results.Pt1); ...
                            'Correlation set', results.correlation_set; ...
                            'Howell factor', results.howell_factor; ...
                            'Loss-bucket width factor', results.bucket_width};
                case 'Choke'
                    cols = {'N/N_des', 'm_choke [kg/s]', 'MFP_1', 'PR', 'Eff', 'Choking row', 'Inside compressor region (PR>1)'};
                    data = cell(nU, 7);
                    for k = 1:nU
                        ef = f(results.choke_Eff(k), 3);
                        if ~results.choke_in_region(k), ef = []; end   % PR <= 1: efficiency not defined
                        data(k, :) = {f(N(k), 3), f(results.choke_m(k), 5), f(results.choke_MFP(k), 4), f(results.choke_PR(k), 3), ...
                            ef, results.choke_row{k}, logical(results.choke_in_region(k))};
                    end
                case 'Stall onset (Howell)'
                    cols = {'N/N_des', 'm_stall [kg/s]', 'PR', 'Eff', 'Stalling row'};
                    data = cell(nU, 5);
                    for k = 1:nU
                        row = results.stall_row{k};
                        if strncmp(row, 'BEYOND|', 7), row = ['beyond onset on the whole line (' row(8:end) ')']; end
                        if isnan(results.stall_points(k)) && isempty(row), row = 'not reached'; end
                        data(k, :) = {f(N(k), 3), f(results.stall_points(k), 5), f(results.stall_PR(k), 3), f(results.stall_Eff(k), 3), row};
                    end
                case 'Peak (zero slope)'
                    cols = {'N/N_des', 'm_peak [kg/s]', 'PR', 'Eff', 'm_stall - m_peak [kg/s]', 'First limit on throttling'};
                    data = cell(nU, 6);
                    for k = 1:nU
                        dm = results.stall_points(k) - results.surge_points(k);
                        if isnan(dm), lim = '-'; elseif dm > 0, lim = 'stall onset (Howell)'; else, lim = 'peak (zero slope)'; end
                        data(k, :) = {f(N(k), 3), f(results.surge_points(k), 5), f(results.surge_PR(k), 3), f(results.surge_Eff(k), 3), f(dm, 5), lim};
                    end
                case 'Koch limit'
                    cols = {'N/N_des', 'm_Koch [kg/s]', 'PR', 'Eff', 'Limiting stage'};
                    data = cell(nU, 5);
                    for k = 1:nU
                        stg = results.koch_stage{k};
                        if strncmp(stg, 'BEYOND|', 7), stg = ['beyond the limit on the whole line (' stg(8:end) ')']; end
                        if isnan(results.koch_points(k)) && isempty(stg)
                            if isempty(results.koch_geometry), stg = 'Koch skipped (no solidity/chord in the .mat)'; else, stg = 'not reached'; end
                        end
                        data(k, :) = {f(N(k), 3), f(results.koch_points(k), 5), f(results.koch_PR(k), 3), f(results.koch_Eff(k), 3), stg};
                    end
                case 'Koch design check'
                    cols = {'Stage', 'Koch applies?', 'Ch_ef', 'Ch_max', 'Ch_ef/Ch_max', 'L/g2', 'F_ef (rows)', 'Status', 'What to change'};
                    KD = results.koch_design;
                    KA = app.get_koch_applicability(results);
                    data = cell(numel(KD), 9);
                    for g = 1:numel(KD)
                        data(g, :) = {KD(g).label, KA.level, f(KD(g).Ch_ef, 3), f(KD(g).Ch_max, 3), f(KD(g).ratio, 3), f(KD(g).LG, 2), ...
                            mat2str(round(KD(g).Fef*100)/100), KD(g).status, strjoin(KD(g).advice, ' | ')};
                    end
                    if isempty(KD)
                        data = {'-', KA.level, [], [], [], [], '', 'Koch skipped (no solidity/chord in the .mat)', ''};
                    end
                case 'Stability limit & Greitzer B'
                    cols = {'N/N_des', 'First limit', 'm_lim [kg/s]', 'PR', 'U [m/s]', 'a_p [m/s]', 'U/(2a_p)', ...
                            '(V_p/(A_c L_c))_crit', 'B', 'Beyond the limit'};
                    data = cell(nU, 10);
                    for k = 1:nU
                        if isnan(results.B(k)), v = '-'; elseif results.B(k) > results.B_crit, v = 'SURGE'; else, v = 'rotating stall'; end
                        data(k, :) = {f(N(k), 3), results.lim_type{k}, f(results.lim_m(k), 5), f(results.lim_PR(k), 3), ...
                            f(results.U_ref(k), 1), f(results.a_plenum(k), 1), f(results.B_star(k), 4), ...
                            f(results.Vratio_crit(k), 2), f(results.B(k), 3), v};
                    end
                case 'Blade rows'
                    cols = {'Operating point (N = 1)', 'm [kg/s]', 'Blade row', 'Incidence i [deg]', '(i - i_des)/deflection', ...
                            'Loss omega', 'omega/omega_des', 'M_in (row frame)', 'M_out (row frame)', 'de Haller V_out/V_in', ...
                            'Deviation [deg]', 'Watch'};
                    data = cell(0, 12);
                    if isfield(results, 'row_detail')
                        for p = 1:numel(results.row_detail)
                            P = results.row_detail(p);
                            for q = 1:numel(P.rows)
                                rw = P.rows(q); w = {};
                                if rw.x > 0 && rw.ratio >= results.howell_factor, w{end+1} = 'Howell stall';
                                elseif rw.x > 0 && rw.ratio >= 0.8*results.howell_factor, w{end+1} = 'near Howell'; end
                                if rw.DH < 0.72, w{end+1} = 'de Haller < 0.72'; end
                                if rw.M_in > 0.9, w{end+1} = 'M_in > 0.9'; end
                                if rw.M_out > 0.95, w{end+1} = 'near choke'; end
                                data(end+1, :) = {P.point, f(P.m, 5), rw.name, f(rw.i, 2), f(rw.x, 3), f(rw.omega, 4), ...
                                    f(rw.ratio, 3), f(rw.M_in, 3), f(rw.M_out, 3), f(rw.DH, 3), f(rw.dev, 2), strjoin(w, ', ')};
                            end
                        end
                    end
                    if isempty(data)
                        data = {'not available: run again', [], '', [], [], [], [], [], [], [], [], ''};
                    end
                case 'Validation summary'
                    cols = {'N/N_des', 'Points', 'Lowest measured m [kg/s]', 'Predicted first limit m [kg/s]', 'Limit type', ...
                            'Error low end [%]', 'Highest measured m [kg/s]', 'Predicted m at that PR [kg/s]', 'Error high end [%]', ...
                            'Mean |dPR|', 'Mean |dPR| / line pressure rise [%]', 'Mean |d eta| [points] (rise >= 25 %)'};
                    V = []; if isfield(results, 'validation'), V = results.validation; end
                    if isempty(V)
                        data = {'no measured data in the .mat (meas_N, meas_m, meas_PR, meas_eta)', [], [], [], '', [], [], [], [], [], [], []};
                    else
                        data = cell(numel(V.speeds), 12);
                        for q = 1:numel(V.speeds)
                            e = V.speeds(q);
                            data(q, :) = {f(e.N, 4), e.n, f(e.m_low_meas, 4), f(e.m_lim_pred, 4), e.lim_type, f(e.err_low, 1), ...
                                f(e.m_high_meas, 4), f(e.m_choke_pred, 4), f(e.err_high, 1), f(e.dPR, 4), f(e.dRise, 1), f(e.dEta, 1)};
                        end
                        data(end+1, :) = {'all', V.n, [], [], '', [], [], [], [], f(V.mae_PR, 4), f(V.mae_rise, 1), f(V.mae_eta, 1)};
                    end
                case 'Validation points'
                    cols = {'N/N_des', 'm [kg/s]', 'PR measured', 'PR predicted', 'dPR', 'eta measured', 'eta predicted', ...
                            'd eta [points]', 'eta compared', 'Note'};
                    V = []; if isfield(results, 'validation'), V = results.validation; end
                    if isempty(V)
                        data = {'no measured data in the .mat', [], [], [], [], [], [], [], false, ''};
                    else
                        P = V.points; data = cell(numel(P), 10);
                        for q = 1:numel(P)
                            data(q, :) = {f(P(q).N, 4), f(P(q).m, 4), f(P(q).PR_meas, 4), f(P(q).PR_pred, 4), ...
                                f(P(q).PR_pred - P(q).PR_meas, 4), f(P(q).eta_meas, 3), f(P(q).eta_pred, 3), ...
                                f(100*(P(q).eta_pred - P(q).eta_meas), 1), logical(P(q).use_eta), P(q).note};
                        end
                    end
                case 'Validation lines'
                    cols = {'N/N_des', 'm [kg/s]', 'PR predicted', 'eta predicted', 'Part of the line'};
                    V = []; if isfield(results, 'validation'), V = results.validation; end
                    if isempty(V)
                        data = {'no measured data in the .mat', [], [], [], ''};
                    else
                        data = cell(0, 5);
                        for k = unique([V.points.line])
                            if k == 0, continue; end
                            [xs, ys, es] = app.line_curve(results, k);
                            for q = 1:numel(xs)
                                if xs(q) < results.lim_m(k), part = 'beyond first limit'; else, part = 'stable'; end
                                e = es(q); if ~(ys(q) > 1 && e > 0 && e <= 1), e = []; else, e = f(e, 4); end
                                data(end+1, :) = {f(N(k), 4), f(xs(q), 5), f(ys(q), 5), e, part};
                            end
                        end
                    end
                otherwise
                    error('Unknown table "%s".', which);
            end
        end

        function lines = diagnostics_lines(app, results)
            % Plain-language summary of the checks (Diagnostics tab)
            lines = {};
            bw = 1; if isfield(results, 'bucket_width'), bw = results.bucket_width; end
            lines{end+1} = sprintf('%s  |  PR_des = %.4f, eta_des = %.4f  |  correlations: %s, Howell factor %.2f, bucket width %.2f', ...
                results.compressor_type, results.PR_design, results.Eff_design, results.correlation_set, results.howell_factor, bw);
            lines = [lines, app.model_option_lines(results)];   % step 25
            lines{end+1} = '';
            k1 = find(abs(results.speed_ratio - 1) < 1e-9, 1);
            if ~isempty(k1) && ~isnan(results.lim_m(k1))
                SM = (results.lim_PR(k1)/results.lim_m(k1))*(app.m_dot/results.PR_design) - 1;
                lines{end+1} = sprintf(['STABILITY (design speed): first limit = %s at m = %.4f kg/s (PR %.3f); ' ...
                    'stall margin SM = %.1f %%'], results.lim_type{k1}, results.lim_m(k1), results.lim_PR(k1), 100*SM);
                lines{end+1} = sprintf('   peak of the speed line (zero slope): m = %.4f kg/s | Howell stall onset: m = %.4f kg/s', ...
                    results.surge_points(k1), results.stall_points(k1));
                if ~isempty(results.koch_geometry)
                    if isnan(results.koch_points(k1))
                        lines{end+1} = '   Koch stage limit: not reached on the computed part of the line';
                    else
                        lines{end+1} = sprintf('   Koch stage limit: m = %.4f kg/s (indicative, see the Koch check below)', results.koch_points(k1));
                    end
                end
                if ~isnan(results.choke_m(k1))
                    lines{end+1} = sprintf(['CHOKE (design speed): m_choke = %.4f kg/s (%s) -> choke margin %.1f %%, ' ...
                        'operating range (m_choke - m_lim)/m_choke = %.1f %%'], results.choke_m(k1), results.choke_row{k1}, ...
                        100*(results.choke_m(k1)/app.m_dot - 1), 100*(1 - results.lim_m(k1)/results.choke_m(k1)));
                end
            end
            nolim = find(strncmp(results.lim_type, 'none', 4));
            for k = nolim(:)'
                lines{end+1} = sprintf('WARNING: N/N_des = %.2f has no stable range (%s).', results.speed_ratio(k), results.lim_type{k});
            end
            if ~isempty(k1)
                lines{end+1} = sprintf(['SURGE OR ROTATING STALL (design speed): U/(2a_p) = %.3f -> surge if the installation has ' ...
                    'V_p/(A_c L_c) > %.2f (B > %.2f), rotating stall below.'], results.B_star(k1), results.Vratio_crit(k1), results.B_crit);
                if ~isnan(results.B(k1))
                    if results.B(k1) > results.B_crit, v = 'SURGE'; else, v = 'ROTATING STALL'; end
                    lines{end+1} = sprintf('   with the given V_p and L_c: B = %.3f -> %s', results.B(k1), v);
                end
            end
            jl = [];
            if isfield(results, 'row_detail') && ~isempty(results.row_detail)
                jl = find(strncmp({results.row_detail.point}, 'First', 5), 1);
            end
            if ~isempty(jl)
                P = results.row_detail(jl);         % first stability limit at design speed
                [~, j1] = max([P.rows.ratio]);
                [~, j2] = min([P.rows.DH]);
                lines{end+1} = sprintf(['BLADE ROWS at the %s: highest loss rise %s (omega/omega_des = %.2f), ' ...
                    'lowest de Haller %s (%.2f). Details: Tables > Blade rows.'], lower(P.point), P.rows(j1).name, ...
                    P.rows(j1).ratio, P.rows(j2).name, P.rows(j2).DH);
            end
            lines{end+1} = '';
            if app.has_stator_geometry()
                lines{end+1} = 'Stators: own blade angles from the .mat (stator_* variables).';
            end
            KA = app.get_koch_applicability(results);
            lines{end+1} = sprintf('KOCH STAGE-LOADING INDICATOR (never a stability limit): %s', upper(KA.level));
            lines{end+1} = ['   ', KA.verdict];
            if ~strcmp(KA.level, 'not available')
                lines{end+1} = ['   ', app.koch_line_text(results)];
            end
            for q = 1:numel(KA.reasons)
                lines{end+1} = ['   why: ', KA.reasons{q}];
            end
            KD = results.koch_design;
            if isempty(KD)
                lines{end+1} = '   (save sigma_rotor/sigma_stator or sigma_1/sigma_2 and chord in the .mat to enable it)';
            else
                lines{end+1} = sprintf('Koch check at the design point (target Ch_ef/Ch_max <= %.2f):', app.koch_target_ratio);
                for g = 1:numel(KD)
                    lines{end+1} = sprintf('  %s: %s', KD(g).label, KD(g).status);
                    for a = 1:numel(KD(g).advice)
                        lines{end+1} = sprintf('     - %s', KD(g).advice{a});
                    end
                end
            end
            lines = [lines, app.validation_lines(results)];     % step 24
        end

        function read_settings_from_ui(app)
            % Copy the Settings-tab fields (if they exist) into the app properties
            app.sync_settings_from_mat();   % step 15: values set by the .mat are shown (and locked) first
            if app.has_ui('CorrelationSetDropDown'), app.CorrelationSet = app.CorrelationSetDropDown.Value; end
            if app.has_ui('HowellFactorEditField'),  app.howell_factor = app.HowellFactorEditField.Value; end
            if app.has_ui('BucketWidthEditField'),   app.bucket_width = app.BucketWidthEditField.Value; end
            if app.has_ui('BucketWidthNegEditField'), v = app.BucketWidthNegEditField.Value; if v <= 0, v = []; end, app.bucket_width_neg = v; end
            if app.has_ui('MinRefDeflEditField'),    app.min_ref_deflection = app.MinRefDeflEditField.Value; end
            if app.has_ui('BlockageEditField'),      app.blockage = app.BlockageEditField.Value; end
            if app.has_ui('ReExponentEditField'),    app.re_exponent = app.ReExponentEditField.Value; end
            if app.has_ui('MeasSpeedsOnlyCheckBox'), app.meas_speeds_only = logical(app.MeasSpeedsOnlyCheckBox.Value); end
            if app.has_ui('KochInLimitCheckBox'),    app.koch_in_limit = app.KochInLimitCheckBox.Value; end
            if app.has_ui('KochTargetEditField'),    app.koch_target_ratio = app.KochTargetEditField.Value; end
            if app.has_ui('KochEpsOverGEditField'),  app.koch_eps_over_g = app.KochEpsOverGEditField.Value; end
            if app.has_ui('KochDzOverSEditField'),   app.koch_dz_over_s = app.KochDzOverSEditField.Value; end
            if app.has_ui('BcritEditField'),         app.B_crit = app.BcritEditField.Value; end
            if app.has_ui('VplenumEditField')
                v = app.VplenumEditField.Value; if v <= 0, v = NaN; end; app.V_plenum = v;
            end
            if app.has_ui('LductEditField')
                v = app.LductEditField.Value; if v <= 0, v = NaN; end; app.L_duct = v;
            end
            if app.has_ui('TrefEditField'),          app.T_ref = app.TrefEditField.Value; end
            if app.has_ui('PrefEditField'),          app.p_ref = app.PrefEditField.Value; end
            if app.has_ui('TinEditField'),           app.Tt1_in = app.TinEditField.Value; end
            if app.has_ui('PinEditField'),           app.Pt1_in = app.PinEditField.Value; end
            if app.has_ui('NminEditField'),          app.N_min = app.NminEditField.Value; end
            if app.has_ui('NmaxEditField'),          app.N_max = app.NmaxEditField.Value; end
            if app.has_ui('NspeedEditField'),        app.n_speed = app.NspeedEditField.Value; end
            if app.has_ui('MdensEditField'),         app.m_density = app.MdensEditField.Value; end
            if app.has_ui('KochModeDropDown'),       app.koch_mode = app.KochModeDropDown.Value; end
        end

        function show_results_in_app(app, results)
            % Fill the Maps, Tables, Equations and Diagnostics tabs (only the parts that exist)
            pairs = {'StdPRAxes', 'plot_standard_compressor_map_PR'; 'StdEffAxes', 'plot_standard_compressor_map_Eff'; ...
                     'NondimPRAxes', 'plot_non_dimensional_compressor_map_PR'; 'NondimEffAxes', 'plot_non_dimensional_compressor_map_Eff'; ...
                     'RelPRAxes', 'plot_relative_non_dimensional_compressor_map_PR'; 'RelEffAxes', 'plot_relative_non_dimensional_compressor_map_Eff'};
            if any(cellfun(@(n) app.has_ui(n), pairs(:, 1)))
                app.equation_log = {};          % the in-app maps write the equations again
            end
            for p = 1:size(pairs, 1)
                if app.has_ui(pairs{p, 1})
                    app.(pairs{p, 2})(app.(pairs{p, 1}), results);
                end
            end
            if app.has_ui('CorrPRAxes') && app.has_ui('CorrEffAxes')
                app.plot_corrected_compressor_map(app.CorrPRAxes, app.CorrEffAxes, results);
            end
            app.set_koch_toggle(results);       % step 14: Koch shown only where it applies (Auto)
            app.set_meas_toggle(results);       % step 25: measured points on/off
            app.apply_line_visibility();        % step 14: Show check boxes
            app.update_table_view();
            if app.has_ui('EquationsTextArea')
                txt = strjoin(app.equation_log, sprintf('\n\n'));
                app.EquationsTextArea.Value = strsplit(txt, newline)';
            end
            if app.has_ui('DiagnosticsTextArea')
                app.DiagnosticsTextArea.Value = app.diagnostics_lines(results)';
            end
        end

        function run_computation(app)
            % Run the off-design computation of the selected configuration. Everything
            % the solver prints is captured in report_log (Report tab) instead of
            % going straight to the command window.
            switch app.Compressor_type
                case 'Rotor-Stator'
                    cmd = 'app.computation_results = app.compute_rotor_stator();';
                case 'Rotor-Rotor same shaft'
                    cmd = 'app.computation_results = app.compute_rotor_rotor_same_shaft();';
                otherwise
                    cmd = 'app.computation_results = app.compute_rotor_rotor_diff_shaft();';
            end
            app.computation_results = [];
            app.report_log = evalc(cmd);
            if ~isempty(app.computation_results)   % step 18: run name + the data used, stored with the results
                app.computation_results.run_name = app.make_run_name();
                app.computation_results.inputs_table = app.inputs_table_data(app.computation_results);
            end
        end

        function present_results(app)
            % Show the last run: maps (in the app and/or separate windows), tables,
            % equations, diagnostics and the text report
            r = app.computation_results;
            if isempty(r), return; end
            app.equation_log = {};
            txt = '';
            if ~app.has_ui('MapsTabGroup') || (app.has_ui('SeparateWindowsCheckBox') && app.SeparateWindowsCheckBox.Value)
                txt = [txt, evalc('app.plot_in_new_window(r);')];
            end
            txt = [txt, evalc('app.show_results_in_app(r);')];
            app.report_log = [app.report_log, txt];
            if app.has_ui('ReportTextArea')
                app.ReportTextArea.Value = strsplit(app.report_log, newline)';
            end
            if ~app.has_ui('ReportTextArea') || (app.has_ui('EchoCommandWindowCheckBox') && app.EchoCommandWindowCheckBox.Value)
                fprintf('%s', app.report_log);            % classic command-window output
            end
            if app.has_ui('MainTabGroup') && app.has_ui('MapsTab')
                app.MainTabGroup.SelectedTab = app.MapsTab;   % jump to the maps
            end
        end

        function init_settings_ui(app)
            % Put the default values of the properties into the Settings-tab fields
            % (called once in startupFcn; the defaults live only in the properties)
            if app.has_ui('CorrelationSetDropDown')
                app.CorrelationSetDropDown.Items = {'polynomial', 'three-point', 'user'};
                app.CorrelationSetDropDown.Value = app.CorrelationSet;
            end
            if app.has_ui('HowellFactorEditField'),  app.HowellFactorEditField.Value = app.howell_factor; end
            if app.has_ui('BucketWidthEditField'),   app.BucketWidthEditField.Value = app.bucket_width; end
            if app.has_ui('BucketWidthNegEditField'), v = app.bucket_width_neg; if isempty(v), v = 0; end, app.BucketWidthNegEditField.Value = v; end
            if app.has_ui('MinRefDeflEditField'),    app.MinRefDeflEditField.Value = app.min_ref_deflection; end
            if app.has_ui('BlockageEditField'),      app.BlockageEditField.Value = app.blockage; end
            if app.has_ui('ReExponentEditField'),    app.ReExponentEditField.Value = app.re_exponent; end
            if app.has_ui('MeasSpeedsOnlyCheckBox'), app.MeasSpeedsOnlyCheckBox.Value = app.meas_speeds_only; end
            if app.has_ui('KochInLimitCheckBox'),    app.KochInLimitCheckBox.Value = app.koch_in_limit; end
            if app.has_ui('KochTargetEditField'),    app.KochTargetEditField.Value = app.koch_target_ratio; end
            if app.has_ui('KochEpsOverGEditField'),  app.KochEpsOverGEditField.Value = app.koch_eps_over_g; end
            if app.has_ui('KochDzOverSEditField'),   app.KochDzOverSEditField.Value = app.koch_dz_over_s; end
            if app.has_ui('BcritEditField'),         app.BcritEditField.Value = app.B_crit; end
            v = app.V_plenum; if isnan(v), v = 0; end                                     % 0 = not given
            if app.has_ui('VplenumEditField'),       app.VplenumEditField.Value = v; end
            v = app.L_duct; if isnan(v), v = 0; end
            if app.has_ui('LductEditField'),         app.LductEditField.Value = v; end
            if app.has_ui('TinEditField'),           app.TinEditField.Value = app.Tt1_in; end
            if app.has_ui('PinEditField'),           app.PinEditField.Value = app.Pt1_in; end
            if app.has_ui('NminEditField'),          app.NminEditField.Value = app.N_min; end
            if app.has_ui('NmaxEditField'),          app.NmaxEditField.Value = app.N_max; end
            if app.has_ui('NspeedEditField'),        app.NspeedEditField.Value = app.n_speed; end
            if app.has_ui('MdensEditField'),         app.MdensEditField.Value = app.m_density; end
            if app.has_ui('KochModeDropDown'),       app.KochModeDropDown.Value = app.koch_mode; end
            if app.has_ui('TrefEditField'),          app.TrefEditField.Value = app.T_ref; end
            if app.has_ui('PrefEditField'),          app.PrefEditField.Value = app.p_ref; end
            if app.has_ui('TableSelectDropDown')
                app.TableSelectDropDown.Items = app.result_table_names();
                app.TableSelectDropDown.Value = 'Stability limit & Greitzer B';
            end
        end

        function clear_results_view(app)
            % Empty the Maps, Tables, Equations and Diagnostics tabs (Reset button)
            ax_names = {'StdPRAxes', 'StdEffAxes', 'NondimPRAxes', 'NondimEffAxes', 'RelPRAxes', 'RelEffAxes', 'CorrPRAxes', 'CorrEffAxes'};
            for a = 1:numel(ax_names)
                if app.has_ui(ax_names{a})
                    app.clear_axes(app.(ax_names{a})); legend(app.(ax_names{a}), 'off'); title(app.(ax_names{a}), '');
                end
            end
            if app.has_ui('ResultsTable'),        app.ResultsTable.Data = {}; end
            if app.has_ui('EquationsTextArea'),   app.EquationsTextArea.Value = {''}; end
            if app.has_ui('DiagnosticsTextArea'), app.DiagnosticsTextArea.Value = {''}; end
            if app.has_ui('ReportTextArea'),      app.ReportTextArea.Value = {''}; end
            app.equation_log = {}; app.report_log = ''; app.mat_name = '';
            if app.has_ui('ShowKochCheckBox')
                app.ShowKochCheckBox.Text = 'Koch'; app.ShowKochCheckBox.Enable = 'on'; app.ShowKochCheckBox.Value = true;
            end
            if app.has_ui('ShowMeasuredCheckBox')
                app.ShowMeasuredCheckBox.Text = 'Measured'; app.ShowMeasuredCheckBox.Enable = 'on'; app.ShowMeasuredCheckBox.Value = true;
            end
            app.sync_settings_from_mat();   % step 15: no .mat any more -> fields editable again
        end

        function update_table_view(app)
            % Show the table chosen in the Tables-tab drop-down
            if ~app.has_ui('ResultsTable') || isempty(app.computation_results), return; end
            which = 'Stability limit & Greitzer B';
            if app.has_ui('TableSelectDropDown'), which = app.TableSelectDropDown.Value; end
            [cols, data] = app.result_table(app.computation_results, which);
            app.ResultsTable.ColumnName = cols;
            app.ResultsTable.Data = data;
        end

        function export_tables(app, file)
            % Write every results table to one Excel file (one sheet per table)
            % plus the equations and diagnostics as text sheets
            if isempty(app.computation_results), return; end
            if nargin < 2
                [fn, pth] = uiputfile('*.xlsx', 'Save results tables', fullfile(app.start_folder(), ...
                    sprintf('Tables_%s.xlsx', app.run_name())));
                if isequal(fn, 0), return; end
                file = fullfile(pth, fn);
            end
            names = app.result_table_names();
            for t = 1:numel(names)
                [cols, data] = app.result_table(app.computation_results, names{t});
                sheet = regexprep(names{t}, '[^\w ]', '');
                writecell([cols; data], file, 'Sheet', sheet(1:min(31, end)));
            end
            eq = strsplit(strjoin(app.equation_log, sprintf('\n\n')), newline)';
            writecell(eq, file, 'Sheet', 'Equations');
            writecell(app.diagnostics_lines(app.computation_results)', file, 'Sheet', 'Diagnostics');
            writecell(strsplit(app.report_log, newline)', file, 'Sheet', 'Report');
        end

        function export_figures(app)
            % One 300-dpi PNG per map kind (pressure ratio and efficiency side by side),
            % named <kind>_<.mat name>.png, e.g. Relative_Max_eta_Compressor_design_rr_diff_shaft.png
            pth = uigetdir(app.start_folder(), 'Folder for the map images');
            if isequal(pth, 0), return; end
            app.last_folder = pth;
            files = app.write_map_pngs(pth);
            uialert(app.UIFigure, sprintf('%d map images saved in %s', numel(files), pth), 'Export maps', 'Icon', 'success');
        end

        function results = postprocess_results(app, results)
            % Quantities derived after a run (no extra input needed):
            %  - corrected flow and speed (corrected map, valid for any inlet)
            %  - first stability limit of every speed line and Greitzer B
            theta = results.Tt1/app.T_ref;
            delta = results.Pt1/app.p_ref;
            results.theta = theta;
            results.delta = delta;
            results.k_corr = sqrt(theta)/delta;               % m_corr = m*sqrt(theta)/delta
            results.m_corr_range = results.mass_dot_range*results.k_corr;
            results.m_corr_design = app.m_dot*results.k_corr;
            results.U_corr = results.U_ref(:)/sqrt(theta);    % corrected blade speed U/sqrt(theta)
            results.correlation_set = app.corr.name;
            results.howell_factor = app.howell_factor;
            results.bucket_width = app.bucket_width;
            results = app.add_greitzer(results);
            results.m_dot_design = app.m_dot;
            results.koch_applicability = app.koch_applicability(results);   % Koch: indicator, applies or not and why
            results.validation = app.validation_metrics(results);            % step 24: [] without measured data
        end

        function plot_corrected_compressor_map(app, axPR, axEff, results)
            % Corrected map: corrected mass flow m*sqrt(theta)/delta, speed lines of
            % corrected speed N/sqrt(theta) (theta = Tt1/T_ref, delta = Pt1/p_ref).
            % For an ideal gas without Reynolds-number effects this ONE map holds for
            % any inlet condition: physical flow = m_corr*delta/sqrt(theta),
            % physical speed = N_corr*sqrt(theta).
            k = results.k_corr;
            rc = results;
            rc.mass_dot_range = results.mass_dot_range*k;
            rc.surge_points = results.surge_points*k;
            rc.stall_points = results.stall_points*k;
            rc.choke_m = results.choke_m*k;
            if isfield(results, 'koch_points'), rc.koch_points = results.koch_points*k; end
            rc.meas_scale = k;                               % step 24: measured points too
            m_saved = app.m_dot;
            app.m_dot = m_saved*k;                           % design point at corrected design flow
            try
                app.plot_standard_compressor_map_PR(axPR, rc);
                app.plot_standard_compressor_map_Eff(axEff, rc);
            catch err
                app.m_dot = m_saved;
                rethrow(err);
            end
            app.m_dot = m_saved;
            lab = sprintf('Corrected mass flow  m\\surd\\theta / \\delta  [kg/s]   (T_{ref} = %.2f K, p_{ref} = %.0f Pa)', app.T_ref, app.p_ref);
            xlabel(axPR, lab);
            xlabel(axEff, lab);
            title(axPR, sprintf('Corrected Compressor Map - %s', results.compressor_type));
            title(axEff, sprintf('Corrected Efficiency Map - %s', results.compressor_type));
            k1 = find(abs(results.speed_ratio - 1) < 1e-9, 1);
            if ~isempty(k1)
                note = sprintf('speed lines: corrected speed (N/\\surd\\theta)/(N/\\surd\\theta)_{des};  design U/\\surd\\theta = %.1f m/s', results.U_corr(k1));
                text(axPR, 0.02, 0.03, note, 'Units', 'normalized', 'FontSize', 9);
            end
        end

        function results = add_greitzer(app, results)
            % First stability limit of every speed line and Greitzer's B parameter
            %   B = U/(2*a_p) * sqrt(V_p/(A_c*L_c))     (Greitzer 1976)
            % U   = blade speed of rotor 1 on that speed line
            % a_p = speed of sound in the plenum, taken at the compressor-exit
            %       stagnation temperature of the limit point
            % A_c = inlet flow area A1, L_c = effective length of compressor + ducts,
            % V_p = volume downstream of the compressor.
            % B > B_crit -> the instability beyond the limit is SURGE, otherwise
            % ROTATING STALL. Without V_p and L_c the installation-independent
            % output is the critical volume ratio (V_p/(A_c*L_c))_crit = (B_crit/(U/2a_p))^2:
            % a larger plenum-to-compressor volume ratio than this leads to surge.
            gamma = 1.4; R = 287; Tt1 = results.Tt1;
            Vp = app.V_plenum; Lc = app.L_duct; Bc = app.B_crit;
            if isstruct(app.loadedData)                  % optional variables in the .mat file
                if isfield(app.loadedData, 'V_plenum'), Vp = app.loadedData.V_plenum; end
                if isfield(app.loadedData, 'L_duct'),   Lc = app.loadedData.L_duct;   end
                if isfield(app.loadedData, 'B_crit'),   Bc = app.loadedData.B_crit;   end
            end
            nU = numel(results.U_ref);
            lim_m = nan(nU, 1); lim_PR = nan(nU, 1); lim_Eff = nan(nU, 1); lim_type = repmat({''}, nU, 1);
            use_koch = false;   % step 14: Koch is an indicator only, never the stability limit
            has_koch = use_koch && isfield(results, 'koch_points') && any(~isnan(results.koch_points));
            for k = 1:nU
                ms = results.stall_points(k); mp = results.surge_points(k);
                if isnan(ms) && strncmp(results.stall_row{k}, 'BEYOND|', 7)
                    lim_type{k} = 'none (beyond onset)';  % no stable range on this line
                elseif ~isnan(ms) && (isnan(mp) || ms > mp)
                    lim_m(k) = ms; lim_PR(k) = real(results.stall_PR(k));
                    lim_Eff(k) = real(results.stall_Eff(k)); lim_type{k} = 'stall onset';
                elseif ~isnan(mp)
                    lim_m(k) = mp; lim_PR(k) = real(results.surge_PR(k));
                    lim_Eff(k) = real(results.surge_Eff(k)); lim_type{k} = 'peak';
                end
                if has_koch                                  % Koch limit at higher flow -> it comes first
                    mk = results.koch_points(k);
                    if isnan(mk) && strncmp(results.koch_stage{k}, 'BEYOND|', 7)
                        lim_m(k) = NaN; lim_type{k} = 'none (beyond Koch)';
                    elseif ~isnan(mk) && ~isnan(lim_m(k)) && mk > lim_m(k)
                        lim_m(k) = mk; lim_PR(k) = real(results.koch_PR(k));
                        lim_Eff(k) = real(results.koch_Eff(k)); lim_type{k} = 'Koch';
                    end
                end
            end
            TR = 1 + (lim_PR.^((gamma-1)/gamma) - 1)./lim_Eff;
            a_p = sqrt(gamma*R*Tt1*TR);
            B_star = results.U_ref(:)./(2*a_p);
            Vratio_crit = (Bc./B_star).^2;
            B = nan(nU, 1);
            have_sys = isfinite(Vp) && isfinite(Lc) && Vp > 0 && Lc > 0;
            if have_sys
                B = B_star*sqrt(Vp/(results.A1*Lc));
            end
            results.lim_m = lim_m; results.lim_PR = lim_PR; results.lim_Eff = lim_Eff;
            results.lim_type = lim_type; results.a_plenum = a_p; results.B_star = B_star;
            results.Vratio_crit = Vratio_crit; results.B = B; results.B_crit = Bc;

            sr = results.speed_ratio;
            fprintf('\nStability limit and Greitzer B (B = U/(2a_p)*sqrt(V_p/(A_c L_c)), A_c = A1 = %.5f m^2, B_crit = %.2f):\n', results.A1, Bc);
            fprintf('  N/N_des   first limit           m_lim [kg/s]   PR     U [m/s]   a_p [m/s]   U/(2a_p)   (V_p/(A_c L_c))_crit');
            if have_sys, fprintf('      B     beyond the limit'); end
            fprintf('\n');
            for k = 1:nU
                if isnan(lim_m(k))
                    fprintf('  %6.3f    %-20s\n', sr(k), lim_type{k});
                    continue;
                end
                fprintf('  %6.3f    %-20s  %9.5f    %6.3f   %6.1f    %6.1f      %6.4f        %10.2f', sr(k), lim_type{k}, ...
                    lim_m(k), lim_PR(k), results.U_ref(k), a_p(k), B_star(k), Vratio_crit(k));
                if have_sys
                    if B(k) > Bc, verdict = 'SURGE'; else, verdict = 'rotating stall'; end
                    fprintf('    %6.3f   %s', B(k), verdict);
                end
                fprintf('\n');
            end
            if have_sys
                ok = ~isnan(B);
                if any(B(ok) > Bc) && any(B(ok) <= Bc)
                    k1 = find(ok & B > Bc, 1, 'first');
                    k0 = find(ok(1:k1-1), 1, 'last');
                    if ~isempty(k0)
                        Nc = sr(k0) + (Bc - B(k0))*(sr(k1) - sr(k0))/(B(k1) - B(k0));
                        fprintf('  -> surge expected above N/N_des = %.3f (V_p = %.4g m^3, L_c = %.4g m)\n', Nc, Vp, Lc);
                    end
                elseif all(B(ok) > Bc)
                    fprintf('  -> surge expected on every speed line (V_p = %.4g m^3, L_c = %.4g m)\n', Vp, Lc);
                else
                    fprintf('  -> rotating stall expected on every speed line (V_p = %.4g m^3, L_c = %.4g m)\n', Vp, Lc);
                end
            else
                fprintf('  (give V_p and L_c to get B; a plenum volume ratio above the critical value leads to surge)\n');
            end
        end

        function PR = pr_or_minus_inf(app, evalfun, m)
            % Pressure ratio of a single operating point, -Inf if the point fails
            [PR, ~, ~, fail_type] = evalfun(m);
            if ~isempty(fail_type) || isnan(PR) || ~isreal(PR)
                PR = -Inf;
            end
        end

        function print_surge_table(app, speed_ratio, surge_m, surge_PR, stall_m)
            % Command-window table of the zero-slope (peak) point of every speed line,
            % with its position relative to the Howell stall onset of the same line
            fprintf('\nSurge / stability limit (peak of the speed line, golden-section to 1e-6 in mass flow):\n');
            fprintf('  N/N_des   m_peak [kg/s]     PR     m_stall - m_peak [kg/s]   first limit reached on throttling\n');
            for k = 1:numel(surge_m)
                if isnan(surge_m(k))
                    fprintf('  %6.3f    no peak inside the computed range\n', speed_ratio(k));
                    continue;
                end
                if isnan(stall_m(k))
                    fprintf('  %6.3f    %10.5f     %6.3f        -\n', speed_ratio(k), surge_m(k), real(surge_PR(k)));
                else
                    dm = stall_m(k) - surge_m(k);
                    if dm > 0, lim = 'stall onset (Howell)'; else, lim = 'peak (zero slope)'; end
                    fprintf('  %6.3f    %10.5f     %6.3f      %+9.5f            %s\n', speed_ratio(k), surge_m(k), ...
                        real(surge_PR(k)), dm, lim);
                end
            end
        end

        function r2 = fit_r2(app, p, x, y)
            % Coefficient of determination of a polynomial fit
            yh = polyval(p, x);
            r2 = 1 - sum((y - yh).^2)/sum((y - mean(y)).^2);
        end

        function s = poly_to_str(app, p, xname)
            % Polynomial coefficients (highest power first) -> readable string
            n = numel(p) - 1;
            terms = cell(1, n + 1);
            for k = 0:n
                pw = n - k;
                if pw > 1
                    terms{k+1} = sprintf('%.4f*%s^%d', p(k+1), xname, pw);
                elseif pw == 1
                    terms{k+1} = sprintf('%.4f*%s', p(k+1), xname);
                else
                    terms{k+1} = sprintf('%.4f', p(k+1));
                end
            end
            s = strjoin(terms, ' + ');
        end

        function c = build_correlations(app)
            % Active off-design correlation set: profile-loss bucket and deviation
            % curve vs. normalised incidence x = (i - i_design)/deflection.
            %   'polynomial'  (default) polynomial fits of the correlation data
            %   'three-point' coarse fit: quadratic loss through 3 points + cubic-
            %                 spline deviation (the old rotor-stator functions)
            %   'user'        polynomial coefficients from the .mat file:
            %                 loss_coeffs, dev_coeffs (highest power first),
            %                 optional dev_x_min
            % Optional .mat overrides: correlation_set (text), howell_factor.
            % Whatever the set, every row stays anchored to its design loss and
            % deviation (the design point is always reproduced exactly).
            set_name = app.CorrelationSet;
            d = app.loadedData;
            if isstruct(d)
                if isfield(d, 'correlation_set'), set_name = char(d.correlation_set); end
                if isfield(d, 'howell_factor'),   app.howell_factor = double(d.howell_factor); end
                if isfield(d, 'bucket_width'),    app.bucket_width = double(d.bucket_width); end
            end
            if ~(isscalar(app.bucket_width) && app.bucket_width > 0.1 && app.bucket_width < 10)
                error('bucket_width must be one value between 0.1 and 10 (1 = default).');
            end
            c = struct('name', set_name, 'loss_p', [], 'dev_type', 'poly', 'dev_p', [], ...
                       'dev_pp', [], 'dev_x_min', -0.8);
            switch lower(set_name)
                case 'polynomial'
                    c.loss_p = [0.0084, 0.0010, 0.0474, 0.6140, -0.0014, 0.0640];
                    c.dev_p  = [0.216366, -0.436901, -0.154451, 0.781826, 0.517871, 0.085335, 0.004];
                case 'three-point'
                    xq = [-0.8; 0; 0.6]; yq = [0.44; 0.07; 0.275];
                    c.loss_p = ([xq.^2, xq, ones(3, 1)] \ yq).';
                    c.dev_type = 'spline';
                    c.dev_pp = spline([-0.8, -0.6, -0.4, -0.2, 0, 0.067, 0.2, 0.4, 0.8], ...
                                      [0, 0, 0, 0, 0, 0, 0.045, 0.15, 0.6]);
                case 'user'
                    if ~(isstruct(d) && isfield(d, 'loss_coeffs') && isfield(d, 'dev_coeffs'))
                        error('Correlation set ''user'' needs loss_coeffs and dev_coeffs in the .mat file.');
                    end
                    c.loss_p = double(d.loss_coeffs(:)).';
                    c.dev_p  = double(d.dev_coeffs(:)).';
                    if isfield(d, 'dev_x_min'), c.dev_x_min = double(d.dev_x_min); end
                otherwise
                    error('Unknown correlation set "%s" (use polynomial, three-point or user).', set_name);
            end
            fprintf('\nCorrelation set: %s   |   Howell stall onset at %.2f x design loss   |   bucket width %.2f\n', ...
                c.name, app.howell_factor, app.bucket_width);
        end

        function w = loss_bucket(app, x)
            % Profile-loss bucket of the active correlation set
            w = polyval(app.corr.loss_p, x);
        end

        function d = deviation_curve(app, x)
            % Deviation increment (in units of the deflection) of the active set,
            % zero at x = 0 and held constant below dev_x_min (end of the data)
            xc = max(x, app.corr.dev_x_min);
            if strcmp(app.corr.dev_type, 'spline')
                d = ppval(app.corr.dev_pp, xc) - ppval(app.corr.dev_pp, 0);
            else
                d = polyval(app.corr.dev_p, xc) - polyval(app.corr.dev_p, 0);
            end
        end

        function [quadratic_fun, coeffs] = createQuadraticFunction(app, x_data, y_data)
            % Returns a quadratic function fitted to 3 points
            A = [x_data(1)^2, x_data(1), 1;
                 x_data(2)^2, x_data(2), 1;
                 x_data(3)^2, x_data(3), 1];
            
            coeffs = A \ y_data';
            
            %% Create function handle
            quadratic_fun = @(x) coeffs(1)*x.^2 + coeffs(2)*x + coeffs(3);
        end
        
        function [splineFun, coeffs, breaks] = createSplineFunction(app, x, y)
            % Fit cubic spline and get piecewise polynomial (pp) structure
            pp = spline(x, y);
            
            % Extract spline coefficients and breaks (knots)
            coeffs = pp.coefs;
            breaks = pp.breaks;
            
            % Create function handle to evaluate the spline
            splineFun = @(xq) ppval(pp, xq);
        end
                   
        % function plot_in_panel(app, results)
        %     % Plot results in the app panel
        %     delete(app.InstructionsPanel.Children);
        % 
        %     % Create tiled layout
        %     t = tiledlayout(app.InstructionsPanel, 2, 2);
        %     t.TileSpacing = 'compact';
        %     t.Padding = 'compact';
        % 
        %     % Standard compressor map - Pressure Ratio
        %     ax1 = nexttile(t, 1);
        %     plot_standard_compressor_map_PR(ax1, results);
        % 
        %     % Standard compressor map - Efficiency
        %     ax2 = nexttile(t, 2);
        %     plot_standard_compressor_map_Eff(ax2, results);
        % 
        %     % Non-dimensional compressor map - Pressure Ratio
        %     ax3 = nexttile(t, 3);
        %     plot_non_dimensional_compressor_map_PR(ax3, results);
        % 
        %     % Non-dimensional compressor map - Efficiency
        %     ax4 = nexttile(t, 4);
        %     plot_non_dimensional_compressor_map_Eff(ax4, results);
        % end
        
        function plot_in_new_window(app, results)
            % Plot results in new figure windows
            
            % Standard compressor map
            fig1 = figure('Name', 'Standard Compressor Map', 'Position', [100, 100, 1200, 500]);
            t1 = tiledlayout(fig1, 1, 2);
            
            % Pressure ratio
            ax1 = nexttile(t1, 1);
            app.plot_standard_compressor_map_PR(ax1, results);
            
            % Efficiency
            ax2 = nexttile(t1, 2);
            app.plot_standard_compressor_map_Eff(ax2, results);
            
            % Non-dimensional compressor map
            fig2 = figure('Name', 'Non-dimensional Compressor Map', 'Position', [100, 100, 1200, 500]);
            t2 = tiledlayout(fig2, 1, 2);
            
            % Pressure ratio
            ax3 = nexttile(t2, 1);
            app.plot_non_dimensional_compressor_map_PR(ax3, results);
            
            % Efficiency
            ax4 = nexttile(t2, 2);
            app.plot_non_dimensional_compressor_map_Eff(ax4, results);

            % for relative plots
            % Relative non-dimensional compressor map (normalized to design point)
            fig3 = figure('Name', 'Relative Non-dimensional Compressor Map', 'Position', [100, 100, 1200, 500]);
            t3 = tiledlayout(fig3, 1, 2);

            % Pressure ratio
            ax5 = nexttile(t3, 1);
            app.plot_relative_non_dimensional_compressor_map_PR(ax5, results);

            % Efficiency
            ax6 = nexttile(t3, 2);
            app.plot_relative_non_dimensional_compressor_map_Eff(ax6, results);

            % Corrected map (corrected mass flow and corrected speed; any inlet condition)
            fig4 = figure('Name', 'Corrected Compressor Map', 'Position', [100, 100, 1200, 500]);
            t4 = tiledlayout(fig4, 1, 2);
            app.plot_corrected_compressor_map(nexttile(t4, 1), nexttile(t4, 2), results);

        end
        
        function plot_standard_compressor_map_PR(app, ax, results)
    % Plot standard compressor map - Pressure Ratio
    app.clear_axes(ax);   % step 16: also the markers drawn with hidden handles (cla leaves them)
    hold(ax, 'on');
    grid(ax, 'on');
    box(ax, 'on');
    xlabel(ax, 'Mass Flow Rate [kg/s]');
    ylabel(ax, 'Pressure Ratio');
    title(ax, sprintf('Compressor Map - %s', results.compressor_type));
    
    % Create speed parameter
    speed_ratio = results.speed_ratio;   % N/N_des (design speed = 1.00)
    
    % Colors for different speeds
    colors = lines(length(results.U_range));
    
    % Plot surge line if available
    if isfield(results, 'surge_points') && any(~isnan(results.surge_points))
        valid_surge = ~isnan(results.surge_points);
        if any(valid_surge)
            sorted_surge_mass = sort(results.surge_points(valid_surge));
            [~, sort_idx] = sort(results.surge_points(valid_surge));
            sorted_surge_PR = results.surge_PR(valid_surge);
            sorted_surge_PR = sorted_surge_PR(sort_idx);
            
            plot(ax, sorted_surge_mass, sorted_surge_PR, 'k--', 'LineWidth', 2.5, ...
                'DisplayName', 'Surge Line');
        end
    end
    
    % Plot rotating stall line if available
    if isfield(results, 'stall_points') && any(~isnan(results.stall_points))
        valid_stall = ~isnan(results.stall_points);
        if any(valid_stall)
            sorted_stall_mass = sort(results.stall_points(valid_stall));
            [~, sort_idx] = sort(results.stall_points(valid_stall));
            sorted_stall_PR = results.stall_PR(valid_stall);
            sorted_stall_PR = sorted_stall_PR(sort_idx);
            
            plot(ax, sorted_stall_mass, sorted_stall_PR, 'm--', 'LineWidth', 2.5, ...
                'DisplayName', 'Stall Onset Line');
        end
    end
    
    % Plot each speed line
    for u_idx = 1:length(results.U_range)
        % Get valid points
        valid_idx = ~isnan(results.Total_PR(u_idx, :)) & ~isnan(results.Overall_Eff(u_idx, :)) & ...
                   (results.Overall_Eff(u_idx, :) > 0.1) & (results.Overall_Eff(u_idx, :) < 1.0);
        
        if any(valid_idx)
            % Pressure ratio plot
            plot(ax, results.mass_dot_range(valid_idx), results.Total_PR(u_idx, valid_idx), ...
                '--o', 'LineWidth', 1.5, 'Color', colors(u_idx,:), ...
                'DisplayName', sprintf('N/N_{des} = %.2f', speed_ratio(u_idx)));
            
            % Mark surge point if available
            if isfield(results, 'surge_points') && ~isnan(results.surge_points(u_idx))
                plot(ax, results.surge_points(u_idx), results.surge_PR(u_idx), 'ks', ...
                    'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'r', ...
                    'HandleVisibility', 'off');
            end
            
            % Mark stall point if available
            if isfield(results, 'stall_points') && ~isnan(results.stall_points(u_idx))
                plot(ax, results.stall_points(u_idx), results.stall_PR(u_idx), 'kd', ...
                    'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'm', ...
                    'HandleVisibility', 'off');
            end
            
            % Mark the exact choke point of this speed line (if it chokes at PR > 1)
            if results.choke_in_region(u_idx)
                % Extend the speed line down to its exact choke point (the near-
                % vertical drop between the last grid point and choke)
                j_draw = find(valid_idx, 1, 'last');
                if j_draw == find(~isnan(results.Total_PR(u_idx, :)), 1, 'last')
                    plot(ax, [results.mass_dot_range(j_draw), results.choke_m(u_idx)], [results.Total_PR(u_idx, j_draw), results.choke_PR(u_idx)], '--', 'Color', colors(u_idx,:), ...
                        'LineWidth', 1.5, 'HandleVisibility', 'off');
                end
                plot(ax, results.choke_m(u_idx), results.choke_PR(u_idx), 's', 'MarkerSize', 10, ...
                    'LineWidth', 2, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'k', ...
                    'HandleVisibility', 'off');
            end
        end
    end
    
    % Choke line: exact choke points of the speed lines that choke at PR > 1
    in_reg = results.choke_in_region;
    if sum(in_reg) > 1
        x_ch = results.choke_m(in_reg); y_ch = results.choke_PR(in_reg);
        [x_ch, i_ch] = sort(real(x_ch));
        y_ch = real(y_ch(i_ch));
        plot(ax, x_ch, y_ch, 'b-.', 'LineWidth', 2, 'DisplayName', 'Choke Line');
    end

    % Mark design point
    plot(ax, app.m_dot, results.PR_design, 'p', ...
        'MarkerSize', 16, 'LineWidth', 2, 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', ...
        'DisplayName', 'Design Point');
    
    % Add design point text annotation
    text(ax, app.m_dot, results.PR_design, 'Design Point', ...
        'FontSize', 10, 'Color', 'k', 'FontWeight', 'bold');
    
    % Koch (1981) stage stall limit (only if computed)
    app.plot_koch_limit(ax, results, 'auto');

    % Measured points (step 24, only when the .mat has meas_N, meas_m, meas_PR)
    hMeas = app.plot_measured(ax, results, 'PR');

    % Enhanced legend handling - exactly like in the reference file
    hLines = findobj(ax, 'Type', 'Line', '-or', 'Type', 'Scatter');
    legendEntries = {};
    legendObjects = [];
    
    % Design Point
    hDesign = findobj(hLines, 'MarkerFaceColor', 'g', 'Marker', 'p');
    if ~isempty(hDesign)
        legendEntries{end+1} = 'Design Point';
        legendObjects = [legendObjects, hDesign(1)];
    end
    
    % Surge Line
    hSurgeLine = findobj(hLines, 'LineStyle', '--', 'Color', 'k');
    if ~isempty(hSurgeLine)
        legendEntries{end+1} = 'Surge Line';
        legendObjects = [legendObjects, hSurgeLine(1)];
    end
    
    % Stall Onset Line
    hStallLine = findobj(hLines, 'LineStyle', '--', 'Color', 'm');
    if ~isempty(hStallLine)
        legendEntries{end+1} = 'Stall Onset Line';
        legendObjects = [legendObjects, hStallLine(1)];
    end
    
    % Speed Lines (limit to avoid too many entries)
    hSpeedLines = findobj(hLines, 'LineStyle', '--', 'Marker', 'o');
    if ~isempty(hSpeedLines)
        if length(hSpeedLines) > 10
            % Show only every other speed line in legend
            selectedLines = hSpeedLines(1:2:end);
            legendObjects = [legendObjects, selectedLines(:)'];
            for i = 1:2:length(hSpeedLines)
                legendEntries{end+1} = get(hSpeedLines(i), 'DisplayName');
            end
        else
            legendObjects = [legendObjects, hSpeedLines(:)'];
            for i = 1:length(hSpeedLines)
                legendEntries{end+1} = get(hSpeedLines(i), 'DisplayName');
            end
        end
    end
    
    % Choke Point
    hChoke = findobj(hLines, 'MarkerFaceColor', 'b', 'Marker', 's');
    if ~isempty(hChoke)
        legendEntries{end+1} = 'Choke Point';
        legendObjects = [legendObjects, hChoke(1)];
    end
    
    % Choke Line
    hChokeLine = findobj(hLines, 'LineStyle', '-.', 'Color', 'b');
    if ~isempty(hChokeLine)
        legendEntries{end+1} = 'Choke Line';
        legendObjects = [legendObjects, hChokeLine(1)];
    end
    
    % Koch stall limit
    hKoch = findobj(hLines, 'Tag', 'KochLimit');
    if ~isempty(hKoch)
        legendEntries{end+1} = 'Koch Stall Limit';
        legendObjects = [legendObjects, hKoch(1)];
    end
    if ~isempty(hMeas)
        legendEntries{end+1} = get(hMeas, 'DisplayName');
        legendObjects = [legendObjects, hMeas];
    end

    % Create legend with specified objects (two columns)
    if ~isempty(legendObjects)
        legend(ax, legendObjects, legendEntries, 'Location', 'best', 'NumColumns', 2);
    end
    
    % Formatting
    ax.FontSize = 12;
    valid_all = ~isnan(results.Total_PR) & ~isnan(results.Overall_Eff) & (results.Overall_Eff > 0.1) & (results.Overall_Eff < 1.0);
    PR_top = max([real(results.Total_PR(valid_all)); real(results.PR_design)]);
    if isfield(results, 'validation') && ~isempty(results.validation)
        PR_top = max([PR_top; [results.validation.points.PR_meas]']);
    end
    ylim(ax, [1, 1.1*PR_top]);   % from plotted points only
end

function plot_standard_compressor_map_Eff(app, ax, results)
    % Plot standard compressor map - Efficiency
    app.clear_axes(ax);   % step 16: also the markers drawn with hidden handles (cla leaves them)
    hold(ax, 'on');
    grid(ax, 'on');
    box(ax, 'on');
    xlabel(ax, 'Mass Flow Rate [kg/s]');
    ylabel(ax, 'Efficiency');
    title(ax, sprintf('Efficiency Map - %s', results.compressor_type));
    
    % Create speed parameter
    speed_ratio = results.speed_ratio;   % N/N_des (design speed = 1.00)
    
    % Colors for different speeds
    colors = lines(length(results.U_range));
    
    % Plot each speed line
    for u_idx = 1:length(results.U_range)
        % Get valid points
        valid_idx = ~isnan(results.Total_PR(u_idx, :)) & ~isnan(results.Overall_Eff(u_idx, :)) & ...
                   (results.Overall_Eff(u_idx, :) > 0.1) & (results.Overall_Eff(u_idx, :) < 1.0);
        
        if any(valid_idx)
            % Efficiency plot
            plot(ax, results.mass_dot_range(valid_idx), results.Overall_Eff(u_idx, valid_idx), ...
                '--o', 'LineWidth', 1.5, 'Color', colors(u_idx,:), ...
                'DisplayName', sprintf('N/N_{des} = %.2f', speed_ratio(u_idx)));
            
            % Mark the exact choke point of this speed line (if it chokes at PR > 1)
            if results.choke_in_region(u_idx) && real(results.choke_Eff(u_idx)) > 0.1 && real(results.choke_Eff(u_idx)) < 1.0
                % Extend the speed line down to its exact choke point (the near-
                % vertical drop between the last grid point and choke)
                j_draw = find(valid_idx, 1, 'last');
                if j_draw == find(~isnan(results.Total_PR(u_idx, :)), 1, 'last')
                    plot(ax, [results.mass_dot_range(j_draw), results.choke_m(u_idx)], [results.Overall_Eff(u_idx, j_draw), results.choke_Eff(u_idx)], '--', 'Color', colors(u_idx,:), ...
                        'LineWidth', 1.5, 'HandleVisibility', 'off');
                end
                plot(ax, results.choke_m(u_idx), results.choke_Eff(u_idx), 's', 'MarkerSize', 10, ...
                    'LineWidth', 2, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'k', ...
                    'HandleVisibility', 'off');
            end
        end
    end
    
    % Mark design point
    plot(ax, app.m_dot, results.Eff_design, 'p', ...
        'MarkerSize', 16, 'LineWidth', 2, 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', ...
        'DisplayName', 'Design Point');
    
    % Add design point text annotation
    text(ax, app.m_dot, results.Eff_design, 'Design Point', ...
        'FontSize', 10, 'Color', 'k', 'FontWeight', 'bold');

    % Measured points (step 24)
    hMeas = app.plot_measured(ax, results, 'eta');
    if ~isempty(hMeas)
        legend(ax, hMeas, get(hMeas, 'DisplayName'), 'Location', 'best');
    end
    
    % Formatting
    ax.FontSize = 12;
    valid_all = ~isnan(results.Total_PR) & ~isnan(results.Overall_Eff) & (results.Overall_Eff > 0.1) & (results.Overall_Eff < 1.0);
    Eff_top = max([real(results.Overall_Eff(valid_all)); real(results.Eff_design)]);
    ylim(ax, [0.4, min(1.0, max(0.9, Eff_top + 0.02))]);   % grows only to show real points above 0.9; never above 1.0
     
    
end

function plot_non_dimensional_compressor_map_PR(app, ax, results)
    % Plot non-dimensional compressor map - Pressure Ratio
    app.clear_axes(ax);   % step 16: also the markers drawn with hidden handles (cla leaves them)
    eq_msgs = {};   % all boundary equations of this map, shown in ONE popup
    hold(ax, 'on');
    grid(ax, 'on');
    box(ax, 'on');
    xlabel(ax, 'MFP$_1$ = $\frac{\dot{m}\sqrt{R T_{t1}}}{A_1 P_{t1} \cos \alpha_1}$', ...
           'Interpreter', 'latex', 'FontSize', 12);
    ylabel(ax, 'Pressure Ratio');
    title(ax, sprintf('Non-dimensional Compressor Map: Pressure Ratio - %s', results.compressor_type));
    
    % Create speed parameter
    speed_ratio = results.speed_ratio;   % N/N_des (design speed = 1.00)
    
    % Colors for different speeds
    colors = lines(length(results.U_range));
    
    % Filter and plot surge line if available - exactly like in reference file
    if isfield(results, 'surge_MFP') && ~isempty(results.surge_MFP)
        % Filter to ensure monotonic increase in MFP
        filtered_surge_MFP = [];
        filtered_surge_PR = [];
        prev_MFP = -Inf;
        
        for i = 1:length(results.surge_MFP)
            if results.surge_MFP(i) > prev_MFP
                filtered_surge_MFP(end+1) = results.surge_MFP(i);
                filtered_surge_PR(end+1) = results.surge_PR_sorted(i);
                prev_MFP = results.surge_MFP(i);
            end
        end
        
        % Plot surge line using filtered points
        h_surge_line = plot(ax, filtered_surge_MFP, filtered_surge_PR, 'k--', 'LineWidth', 2.5, ...
            'DisplayName', 'Surge Line');
        
        % Mark each surge point with red rectangle (plot on top)
        h_surge_points = plot(ax, filtered_surge_MFP, filtered_surge_PR, 's', 'MarkerSize', 10, 'LineWidth', 2, ...
            'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', ...
            'DisplayName', 'Surge Points');
        
        % Fit a polynomial to the surge line (exactly like reference file)
        if length(filtered_surge_MFP) > 3
            surge_line_function = polyfit(filtered_surge_MFP, filtered_surge_PR, 3);   % cubic: R^2 > 0.998 in all cases
            
            % Plot surge line using fitted points
            surge_fit_x = linspace(min(filtered_surge_MFP), max(filtered_surge_MFP), 100);
            surge_fit_y = polyval(surge_line_function, surge_fit_x);
            h_surge_fit = plot(ax, surge_fit_x, surge_fit_y, 'b--', 'LineWidth', 4.5, ...
                'DisplayName', 'Surge Line Fit');

            % Display equation in command window
            equation_str = sprintf('Surge_PR = %s   [R^2 = %.5f]', app.poly_to_str(surge_line_function, 'MFP'), ...
                app.fit_r2(surge_line_function, filtered_surge_MFP, filtered_surge_PR));
            fprintf('\nSurge Line Functional Relationship:\n%s\n', equation_str);
            
            eq_msgs{end+1} = sprintf('Surge line:\n%s', equation_str);
        else
            fprintf('\nNot enough surge points for polynomial fitting.\n');
        end
    end
    
    % Filter and plot rotating stall line if available - exactly like reference file
    if isfield(results, 'stall_MFP') && ~isempty(results.stall_MFP)
        % Filter to ensure monotonic increase in MFP
        filtered_stall_MFP = [];
        filtered_stall_PR = [];
        prev_MFP = -Inf;
        
        for i = 1:length(results.stall_MFP)
            if results.stall_MFP(i) > prev_MFP
                filtered_stall_MFP(end+1) = results.stall_MFP(i);
                filtered_stall_PR(end+1) = results.stall_PR_sorted(i);
                prev_MFP = results.stall_MFP(i);
            end
        end
        
        % Plot rotating stall line using filtered points
        h_stall_line = plot(ax, filtered_stall_MFP, filtered_stall_PR, 'm--', 'LineWidth', 2.5, ...
            'DisplayName', 'Stall Onset Line');
        
        % Mark each rotating stall point with magenta diamond
        h_stall_points = plot(ax, filtered_stall_MFP, filtered_stall_PR, 'd', 'MarkerSize', 10, 'LineWidth', 2, ...
            'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'k', ...
            'DisplayName', 'Stall Onset Points');
        
        % Fit a polynomial to the stall-onset line (cubic, never above n-1)
        n_st = numel(filtered_stall_MFP);
        if n_st >= 3
            deg_st = min(3, n_st - 1);
            stall_line_function = polyfit(filtered_stall_MFP, filtered_stall_PR, deg_st);
            stall_fit_x = linspace(min(filtered_stall_MFP), max(filtered_stall_MFP), 100);
            stall_fit_y = polyval(stall_line_function, stall_fit_x);
            h_stall_fit = plot(ax, stall_fit_x, stall_fit_y, 'c--', 'LineWidth', 4.5, ...
                'DisplayName', 'Stall Onset Line Fit');
            equation_str = sprintf('StallOnset_PR = %s   [R^2 = %.5f]', app.poly_to_str(stall_line_function, 'MFP'), ...
                app.fit_r2(stall_line_function, filtered_stall_MFP, filtered_stall_PR));
            fprintf('\nStall Onset Line (Howell) Functional Relationship:\n%s\n', equation_str);
            eq_msgs{end+1} = sprintf('Stall-onset line (Howell):\n%s', equation_str);
        else
            fprintf('\nNot enough stall-onset points for polynomial fitting.\n');
        end
    end
    
    % Plot each speed line
    for u_idx = 1:length(results.U_range)
        % Get valid points
        valid_idx = ~isnan(results.Total_PR(u_idx, :)) & ~isnan(results.Overall_Eff(u_idx, :)) & ...
                   (results.Overall_Eff(u_idx, :) > 0.1) & (results.Overall_Eff(u_idx, :) < 1.0);
        
        if any(valid_idx)
            % Extract current MFP values for this speed line
            current_MFP = results.MFP1_matrix(u_idx, valid_idx);
            current_PR = results.Total_PR(u_idx, valid_idx);
            
            % Sort by MFP for clean plotting
            [sorted_MFP, sort_idx] = sort(current_MFP);
            sorted_PR = current_PR(sort_idx);
            
            % Pressure ratio plot
            plot(ax, sorted_MFP, sorted_PR, '--o', 'LineWidth', 1.5, ...
                'Color', colors(u_idx,:), ...
                'DisplayName', sprintf('N/N_{des} = %.2f', speed_ratio(u_idx)));
            
            % Mark the exact choke point of this speed line (if it chokes at PR > 1)
            if results.choke_in_region(u_idx)
                % Extend the speed line down to its exact choke point (the near-
                % vertical drop between the last grid point and choke)
                j_draw = find(valid_idx, 1, 'last');
                if j_draw == find(~isnan(results.Total_PR(u_idx, :)), 1, 'last')
                    plot(ax, [results.MFP1_matrix(u_idx, j_draw), results.choke_MFP(u_idx)], [results.Total_PR(u_idx, j_draw), results.choke_PR(u_idx)], '--', 'Color', colors(u_idx,:), ...
                        'LineWidth', 1.5, 'HandleVisibility', 'off');
                end
                plot(ax, results.choke_MFP(u_idx), results.choke_PR(u_idx), 's', 'MarkerSize', 10, ...
                    'LineWidth', 2, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'k', ...
                    'HandleVisibility', 'off');
            end
        end
    end
    
    % Choke line: exact choke points of the speed lines that choke at PR > 1
    in_reg = results.choke_in_region;
    if sum(in_reg) > 1
        x_ch = results.choke_MFP(in_reg); y_ch = results.choke_PR(in_reg);
        [x_ch, i_ch] = sort(real(x_ch));
        y_ch = real(y_ch(i_ch));
        plot(ax, x_ch, y_ch, 'b-.', 'LineWidth', 2, 'DisplayName', 'Choke Line');
        % Polynomial fit of the choke line (quadratic, never above n-1): the choke
        % line is smooth and has few points, a higher degree only interpolates them
        if numel(x_ch) >= 3
            deg_ch = min(2, numel(x_ch) - 1);
            choke_line_function = polyfit(x_ch, y_ch, deg_ch);
            choke_fit_x = linspace(min(x_ch), max(x_ch), 100);
            plot(ax, choke_fit_x, polyval(choke_line_function, choke_fit_x), ':', 'Color', 'b', ...
                'LineWidth', 3.5, 'DisplayName', 'Choke Line Fit');
            equation_str = sprintf('Choke_PR = %s   [R^2 = %.5f]', app.poly_to_str(choke_line_function, 'MFP'), ...
                app.fit_r2(choke_line_function, x_ch, y_ch));
            fprintf('\nChoke Line Functional Relationship:\n%s\n', equation_str);
            eq_msgs{end+1} = sprintf('Choke line:\n%s', equation_str);
        end
    end

    % Mark design point
    h_design_pr = plot(ax, results.MFP1_design, results.PR_design, 'p', 'MarkerSize', 16, 'LineWidth', 2, ...
        'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', ...
        'DisplayName', 'Design Point');
    
    % Add design point text annotation
    text(ax, results.MFP1_design*1.02, results.PR_design*0.98, 'Design Point', ...
        'FontSize', 10, 'Color', 'k', 'FontWeight', 'bold');
    
    % Koch (1981) stage stall limit (only if computed)
    app.plot_koch_limit(ax, results, 'auto');

    % Enhanced legend handling - exactly like in the reference file
    hLines = findobj(ax, 'Type', 'Line', '-or', 'Type', 'Scatter');
    legendEntries = {};
    legendObjects = [];
    
    % Design Point
    hDesign = findobj(hLines, 'MarkerFaceColor', 'g', 'Marker', 'p');
    if ~isempty(hDesign)
        legendEntries{end+1} = 'Design Point';
        legendObjects = [legendObjects, hDesign(1)];
    end
    
    % Surge Line
    hSurgeLine = findobj(hLines, 'LineStyle', '--', 'Color', 'k');
    if ~isempty(hSurgeLine)
        legendEntries{end+1} = 'Surge Line';
        legendObjects = [legendObjects, hSurgeLine(1)];
    end
    
    % Surge Points
    hSurgePoints = findobj(hLines, 'MarkerFaceColor', 'r', 'Marker', 's');
    if ~isempty(hSurgePoints)
        legendEntries{end+1} = 'Surge Points';
        legendObjects = [legendObjects, hSurgePoints(1)];
    end
    
    % Surge Line Fit
    hSurgeFit = findobj(hLines, 'LineStyle', '--', 'Color', 'b', 'LineWidth', 4.5);
    if ~isempty(hSurgeFit)
        legendEntries{end+1} = 'Surge Line Fit';
        legendObjects = [legendObjects, hSurgeFit(1)];
    end
    
    % Stall Onset Line
    hStallLine = findobj(hLines, 'LineStyle', '--', 'Color', 'm');
    if ~isempty(hStallLine)
        legendEntries{end+1} = 'Stall Onset Line';
        legendObjects = [legendObjects, hStallLine(1)];
    end
    
    % Stall Onset Points
    hStallPoints = findobj(hLines, 'MarkerFaceColor', 'm', 'Marker', 'd');
    if ~isempty(hStallPoints)
        legendEntries{end+1} = 'Stall Onset Points';
        legendObjects = [legendObjects, hStallPoints(1)];
    end
    
    % Stall Onset Line Fit
    hStallFit = findobj(hLines, 'LineStyle', '--', 'Color', 'c', 'LineWidth', 4.5);
    if ~isempty(hStallFit)
        legendEntries{end+1} = 'Stall Onset Line Fit';
        legendObjects = [legendObjects, hStallFit(1)];
    end
    hKoch = findobj(hLines, 'Tag', 'KochLimit');
    if ~isempty(hKoch)
        legendEntries{end+1} = 'Koch Stall Limit';
        legendObjects = [legendObjects, hKoch(1)];
    end
    
    % Speed Lines (limit to avoid too many entries)
    hSpeedLines = findobj(hLines, 'LineStyle', '--', 'Marker', 'o');
    if ~isempty(hSpeedLines)
        if length(hSpeedLines) > 10
            % Show only every other speed line in legend
            selectedLines = hSpeedLines(1:2:end);
            legendObjects = [legendObjects, selectedLines(:)'];
            for i = 1:2:length(hSpeedLines)
                legendEntries{end+1} = get(hSpeedLines(i), 'DisplayName');
            end
        else
            legendObjects = [legendObjects, hSpeedLines(:)'];
            for i = 1:length(hSpeedLines)
                legendEntries{end+1} = get(hSpeedLines(i), 'DisplayName');
            end
        end
    end
    
    % Choke Point
    hChoke = findobj(hLines, 'MarkerFaceColor', 'b', 'Marker', 's');
    if ~isempty(hChoke)
        legendEntries{end+1} = 'Choke Point';
        legendObjects = [legendObjects, hChoke(1)];
    end
    
    % Choke Line
    hChokeLine = findobj(hLines, 'LineStyle', '-.', 'Color', 'b');
    if ~isempty(hChokeLine)
        legendEntries{end+1} = 'Choke Line';
        legendObjects = [legendObjects, hChokeLine(1)];
    end

    % Choke Line Fit
    hChokeFit = findobj(hLines, 'LineStyle', ':', 'Color', 'b');
    if ~isempty(hChokeFit)
        legendEntries{end+1} = 'Choke Line Fit';
        legendObjects = [legendObjects, hChokeFit(1)];
    end
    
    % Create legend with specified objects
    if ~isempty(legendObjects)
        legend(ax, legendObjects, legendEntries, 'Location', 'best');
    end
    
    % Ensure surge and stall points are on top by using uistack
    if exist('h_surge_points', 'var') && ~isempty(h_surge_points)
        uistack(h_surge_points, 'top');
    end
    if exist('h_stall_points', 'var') && ~isempty(h_stall_points)
        uistack(h_stall_points, 'top');
    end
    if exist('h_design_pr', 'var') && ~isempty(h_design_pr)
        uistack(h_design_pr, 'top');
    end
    
    % One popup with all stability-boundary equations of this map
    if ~isempty(eq_msgs)
        app.report_equations(eq_msgs, ax);
    end

    % Formatting
    ax.FontSize = 12;
    valid_all = ~isnan(results.Total_PR) & ~isnan(results.Overall_Eff) & (results.Overall_Eff > 0.1) & (results.Overall_Eff < 1.0);
    PR_top = max([real(results.Total_PR(valid_all)); real(results.PR_design)]);
    ylim(ax, [1, 1.1*PR_top]);   % from plotted points only
end

function plot_non_dimensional_compressor_map_Eff(app, ax, results)
    % Plot non-dimensional compressor map - Efficiency
    app.clear_axes(ax);   % step 16: also the markers drawn with hidden handles (cla leaves them)
    hold(ax, 'on');
    grid(ax, 'on');
    box(ax, 'on');
    xlabel(ax, 'MFP$_1$ = $\frac{\dot{m}\sqrt{R T_{t1}}}{A_1 P_{t1} \cos \alpha_1}$', ...
           'Interpreter', 'latex', 'FontSize', 12);
    ylabel(ax, 'Efficiency');
    title(ax, sprintf('Non-dimensional Compressor Map: Efficiency - %s', results.compressor_type));
    
    % Create speed parameter
    speed_ratio = results.speed_ratio;   % N/N_des (design speed = 1.00)
    
    % Colors for different speeds
    colors = lines(length(results.U_range));
    
    % Plot each speed line
    for u_idx = 1:length(results.U_range)
        % Get valid points
        valid_idx = ~isnan(results.Total_PR(u_idx, :)) & ~isnan(results.Overall_Eff(u_idx, :)) & ...
                   (results.Overall_Eff(u_idx, :) > 0.1) & (results.Overall_Eff(u_idx, :) < 1.0);
        
        if any(valid_idx)
            % Extract current MFP values for this speed line
            current_MFP = results.MFP1_matrix(u_idx, valid_idx);
            current_Eff = results.Overall_Eff(u_idx, valid_idx);
            
            % Sort by MFP for clean plotting
            [sorted_MFP, sort_idx] = sort(current_MFP);
            sorted_Eff = current_Eff(sort_idx);
            
            % Efficiency plot
            plot(ax, sorted_MFP, sorted_Eff, '--o', 'LineWidth', 1.5, ...
                'Color', colors(u_idx,:), ...
                'DisplayName', sprintf('N/N_{des} = %.2f', speed_ratio(u_idx)));
            
            % Mark the exact choke point of this speed line (if it chokes at PR > 1)
            if results.choke_in_region(u_idx) && real(results.choke_Eff(u_idx)) > 0.1 && real(results.choke_Eff(u_idx)) < 1.0
                % Extend the speed line down to its exact choke point (the near-
                % vertical drop between the last grid point and choke)
                j_draw = find(valid_idx, 1, 'last');
                if j_draw == find(~isnan(results.Total_PR(u_idx, :)), 1, 'last')
                    plot(ax, [results.MFP1_matrix(u_idx, j_draw), results.choke_MFP(u_idx)], [results.Overall_Eff(u_idx, j_draw), results.choke_Eff(u_idx)], '--', 'Color', colors(u_idx,:), ...
                        'LineWidth', 1.5, 'HandleVisibility', 'off');
                end
                plot(ax, results.choke_MFP(u_idx), results.choke_Eff(u_idx), 's', 'MarkerSize', 10, ...
                    'LineWidth', 2, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'k', ...
                    'HandleVisibility', 'off');
            end
        end
    end
    
    % Mark design point
    plot(ax, results.MFP1_design, results.Eff_design, 'p', 'MarkerSize', 16, 'LineWidth', 2, ...
        'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', 'DisplayName', 'Design Point');
    
    % Add design point text annotation
    text(ax, results.MFP1_design*1.02, results.Eff_design*0.98, 'Design Point', ...
        'FontSize', 10, 'Color', 'k', 'FontWeight', 'bold');
    
    % Formatting
    ax.FontSize = 12;
    valid_all = ~isnan(results.Total_PR) & ~isnan(results.Overall_Eff) & (results.Overall_Eff > 0.1) & (results.Overall_Eff < 1.0);
    Eff_top = max([real(results.Overall_Eff(valid_all)); real(results.Eff_design)]);
    ylim(ax, [0.4, min(1.0, max(0.9, Eff_top + 0.02))]);   % grows only to show real points above 0.9; never above 1.0
end

function plot_relative_non_dimensional_compressor_map_PR(app, ax, results)
    % Plot relative non-dimensional compressor map - Pressure Ratio
    % Both axes are normalized by the design point (MFP1/MFP1_design,
    % PR/PR_design), so the design point always plots at exactly (1, 1),
    % regardless of configuration or geometry - this is what makes the
    % three configurations directly comparable on one pair of axes.
    app.clear_axes(ax);   % step 16: also the markers drawn with hidden handles (cla leaves them)
    eq_msgs = {};   % all boundary equations of this map, shown in ONE popup
    hold(ax, 'on');
    grid(ax, 'on');
    box(ax, 'on');
    xlabel(ax, 'MFP$_1$ / MFP$_{1,design}$', 'Interpreter', 'latex', 'FontSize', 12);
    ylabel(ax, '\pi / \pi_{design}', 'Interpreter', 'tex');
    title(ax, sprintf('Relative Non-dimensional Compressor Map: Pressure Ratio - %s', results.compressor_type));

    % Create speed parameter
    speed_ratio = results.speed_ratio;   % N/N_des (design speed = 1.00)

    % Colors for different speeds
    colors = lines(length(results.U_range));

    % Relative (normalized-by-design) versions of the full matrices.
    % No special handling here: this divides through exactly the same way
    % results.Total_PR/results.Overall_Eff are used everywhere else in the
    % app, so any complex entries (a numerical artifact - see note near
    % the bottom of this function, not a physical effect) pass through
    % untouched, exactly as they already do in the absolute non-dimensional
    % plot. They are only ever dealt with at the one new operation below
    % (ylim) that does not already tolerate them the way plot()/relational
    % operators do.
    MFP1_rel_matrix = results.MFP1_matrix / results.MFP1_design;
    PR_rel_matrix   = results.Total_PR   / results.PR_design;

    % Filter and plot surge line if available (relative axes)
    if isfield(results, 'surge_MFP') && ~isempty(results.surge_MFP)
        surge_MFP_rel = results.surge_MFP / results.MFP1_design;
        surge_PR_rel  = results.surge_PR_sorted / results.PR_design;

        % Filter to ensure monotonic increase in relative MFP
        filtered_surge_MFP_rel = [];
        filtered_surge_PR_rel = [];
        prev_MFP = -Inf;

        for i = 1:length(surge_MFP_rel)
            if surge_MFP_rel(i) > prev_MFP
                filtered_surge_MFP_rel(end+1) = surge_MFP_rel(i);
                filtered_surge_PR_rel(end+1) = surge_PR_rel(i);
                prev_MFP = surge_MFP_rel(i);
            end
        end

        h_surge_line = plot(ax, filtered_surge_MFP_rel, filtered_surge_PR_rel, 'k--', 'LineWidth', 2.5, ...
            'DisplayName', 'Surge Line');

        h_surge_points = plot(ax, filtered_surge_MFP_rel, filtered_surge_PR_rel, 's', 'MarkerSize', 10, 'LineWidth', 2, ...
            'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', ...
            'DisplayName', 'Surge Points');

        % Fit a polynomial directly in relative space (design point is (1,1))
        if length(filtered_surge_MFP_rel) > 3
            surge_line_function_rel = polyfit(filtered_surge_MFP_rel, filtered_surge_PR_rel, 3);   % cubic

            surge_fit_x = linspace(min(filtered_surge_MFP_rel), max(filtered_surge_MFP_rel), 100);
            surge_fit_y = polyval(surge_line_function_rel, surge_fit_x);
            h_surge_fit = plot(ax, surge_fit_x, surge_fit_y, 'b--', 'LineWidth', 4.5, ...
                'DisplayName', 'Surge Line Fit');

            equation_str = sprintf('(PR/PR_design) = %s   (x = MFP/MFP_design)   [R^2 = %.5f]', ...
                app.poly_to_str(surge_line_function_rel, 'x'), ...
                app.fit_r2(surge_line_function_rel, filtered_surge_MFP_rel, filtered_surge_PR_rel));
            fprintf('\nRelative Surge Line Functional Relationship:\n%s\n', equation_str);

            eq_msgs{end+1} = sprintf('Surge line:\n%s', equation_str);
        else
            fprintf('\nNot enough surge points for relative polynomial fitting.\n');
        end
    end

    % Filter and plot rotating stall line if available (relative axes)
    if isfield(results, 'stall_MFP') && ~isempty(results.stall_MFP)
        stall_MFP_rel = results.stall_MFP / results.MFP1_design;
        stall_PR_rel  = results.stall_PR_sorted / results.PR_design;

        filtered_stall_MFP_rel = [];
        filtered_stall_PR_rel = [];
        prev_MFP = -Inf;

        for i = 1:length(stall_MFP_rel)
            if stall_MFP_rel(i) > prev_MFP
                filtered_stall_MFP_rel(end+1) = stall_MFP_rel(i);
                filtered_stall_PR_rel(end+1) = stall_PR_rel(i);
                prev_MFP = stall_MFP_rel(i);
            end
        end

        h_stall_line = plot(ax, filtered_stall_MFP_rel, filtered_stall_PR_rel, 'm--', 'LineWidth', 2.5, ...
            'DisplayName', 'Stall Onset Line');

        h_stall_points = plot(ax, filtered_stall_MFP_rel, filtered_stall_PR_rel, 'd', 'MarkerSize', 10, 'LineWidth', 2, ...
            'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'k', ...
            'DisplayName', 'Stall Onset Points');

        % Fit a polynomial to the stall-onset line (cubic, never above n-1)
        n_st = numel(filtered_stall_MFP_rel);
        if n_st >= 3
            deg_st = min(3, n_st - 1);
            stall_line_function = polyfit(filtered_stall_MFP_rel, filtered_stall_PR_rel, deg_st);
            stall_fit_x = linspace(min(filtered_stall_MFP_rel), max(filtered_stall_MFP_rel), 100);
            stall_fit_y = polyval(stall_line_function, stall_fit_x);
            h_stall_fit = plot(ax, stall_fit_x, stall_fit_y, 'c--', 'LineWidth', 4.5, ...
                'DisplayName', 'Stall Onset Line Fit');
            equation_str = sprintf('(PR/PR_design) = %s   (x = MFP/MFP_design)   [R^2 = %.5f]', ...
                app.poly_to_str(stall_line_function, 'x'), ...
                app.fit_r2(stall_line_function, filtered_stall_MFP_rel, filtered_stall_PR_rel));
            fprintf('\nRelative Stall Onset Line (Howell) Functional Relationship:\n%s\n', equation_str);
            eq_msgs{end+1} = sprintf('Stall-onset line (Howell):\n%s', equation_str);
        else
            fprintf('\nNot enough stall-onset points for polynomial fitting.\n');
        end
    end

    % Plot each speed line (relative axes). plotted_PR_rel accumulates
    % exactly the values that actually get drawn - same points, same
    % valid_idx filter, same real-part tolerance as the rest of this
    % function - so it can be reused below to size the y-axis without
    % rescanning the raw (unfiltered) matrix.
    plotted_PR_rel = [];
    for u_idx = 1:length(results.U_range)
        valid_idx = ~isnan(results.Total_PR(u_idx, :)) & ~isnan(results.Overall_Eff(u_idx, :)) & ...
                   (results.Overall_Eff(u_idx, :) > 0.1) & (results.Overall_Eff(u_idx, :) < 1.0);

        if any(valid_idx)
            current_MFP_rel = MFP1_rel_matrix(u_idx, valid_idx);
            current_PR_rel  = PR_rel_matrix(u_idx, valid_idx);

            [sorted_MFP_rel, sort_idx] = sort(current_MFP_rel);
            sorted_PR_rel = current_PR_rel(sort_idx);

            plot(ax, sorted_MFP_rel, sorted_PR_rel, '--o', 'LineWidth', 1.5, ...
                'Color', colors(u_idx,:), ...
                'DisplayName', sprintf('N/N_{des} = %.2f', speed_ratio(u_idx)));

            plotted_PR_rel = [plotted_PR_rel, sorted_PR_rel]; %#ok<AGROW>

            % Mark the exact choke point of this speed line (if it chokes at PR > 1)
            if results.choke_in_region(u_idx)
                % Extend the speed line down to its exact choke point (the near-
                % vertical drop between the last grid point and choke)
                j_draw = find(valid_idx, 1, 'last');
                if j_draw == find(~isnan(results.Total_PR(u_idx, :)), 1, 'last')
                    plot(ax, [MFP1_rel_matrix(u_idx, j_draw), results.choke_MFP(u_idx)/results.MFP1_design], [PR_rel_matrix(u_idx, j_draw), results.choke_PR(u_idx)/results.PR_design], '--', 'Color', colors(u_idx,:), ...
                        'LineWidth', 1.5, 'HandleVisibility', 'off');
                end
                plot(ax, results.choke_MFP(u_idx)/results.MFP1_design, results.choke_PR(u_idx)/results.PR_design, 's', 'MarkerSize', 10, ...
                    'LineWidth', 2, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'k', ...
                    'HandleVisibility', 'off');
                plotted_PR_rel = [plotted_PR_rel, real(results.choke_PR(u_idx)/results.PR_design)]; %#ok<AGROW>
            end
        end
    end

    % Choke line: exact choke points of the speed lines that choke at PR > 1
    in_reg = results.choke_in_region;
    if sum(in_reg) > 1
        x_ch = results.choke_MFP(in_reg)/results.MFP1_design; y_ch = results.choke_PR(in_reg)/results.PR_design;
        [x_ch, i_ch] = sort(real(x_ch));
        y_ch = real(y_ch(i_ch));
        plot(ax, x_ch, y_ch, 'b-.', 'LineWidth', 2, 'DisplayName', 'Choke Line');
        % Polynomial fit of the choke line (quadratic, never above n-1): the choke
        % line is smooth and has few points, a higher degree only interpolates them
        if numel(x_ch) >= 3
            deg_ch = min(2, numel(x_ch) - 1);
            choke_line_function = polyfit(x_ch, y_ch, deg_ch);
            choke_fit_x = linspace(min(x_ch), max(x_ch), 100);
            plot(ax, choke_fit_x, polyval(choke_line_function, choke_fit_x), ':', 'Color', 'b', ...
                'LineWidth', 3.5, 'DisplayName', 'Choke Line Fit');
            equation_str = sprintf('(PR/PR_design) = %s   (x = MFP/MFP_design)   [R^2 = %.5f]', ...
                app.poly_to_str(choke_line_function, 'x'), app.fit_r2(choke_line_function, x_ch, y_ch));
            fprintf('\nChoke Line Functional Relationship:\n%s\n', equation_str);
            eq_msgs{end+1} = sprintf('Choke line:\n%s', equation_str);
        end
    end

    % Mark design point - exactly (1, 1) by construction, no lookup needed
    h_design_pr = plot(ax, 1, 1, 'p', 'MarkerSize', 16, 'LineWidth', 2, ...
        'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', ...
        'DisplayName', 'Design Point');

    text(ax, 1.02, 0.98, 'Design Point', ...
        'FontSize', 10, 'Color', 'k', 'FontWeight', 'bold');

    % Koch (1981) stage stall limit (only if computed)
    app.plot_koch_limit(ax, results, 'relative');

    % Enhanced legend handling - identical pattern to the absolute non-dimensional plot
    hLines = findobj(ax, 'Type', 'Line', '-or', 'Type', 'Scatter');
    legendEntries = {};
    legendObjects = [];

    hDesign = findobj(hLines, 'MarkerFaceColor', 'g', 'Marker', 'p');
    if ~isempty(hDesign)
        legendEntries{end+1} = 'Design Point';
        legendObjects = [legendObjects, hDesign(1)];
    end

    hSurgeLine = findobj(hLines, 'LineStyle', '--', 'Color', 'k');
    if ~isempty(hSurgeLine)
        legendEntries{end+1} = 'Surge Line';
        legendObjects = [legendObjects, hSurgeLine(1)];
    end

    hSurgePoints = findobj(hLines, 'MarkerFaceColor', 'r', 'Marker', 's');
    if ~isempty(hSurgePoints)
        legendEntries{end+1} = 'Surge Points';
        legendObjects = [legendObjects, hSurgePoints(1)];
    end

    hSurgeFit = findobj(hLines, 'LineStyle', '--', 'Color', 'b', 'LineWidth', 4.5);
    if ~isempty(hSurgeFit)
        legendEntries{end+1} = 'Surge Line Fit';
        legendObjects = [legendObjects, hSurgeFit(1)];
    end

    hStallLine = findobj(hLines, 'LineStyle', '--', 'Color', 'm');
    if ~isempty(hStallLine)
        legendEntries{end+1} = 'Stall Onset Line';
        legendObjects = [legendObjects, hStallLine(1)];
    end

    hStallPoints = findobj(hLines, 'MarkerFaceColor', 'm', 'Marker', 'd');
    if ~isempty(hStallPoints)
        legendEntries{end+1} = 'Stall Onset Points';
        legendObjects = [legendObjects, hStallPoints(1)];
    end

    hStallFit = findobj(hLines, 'LineStyle', '--', 'Color', 'c', 'LineWidth', 4.5);
    if ~isempty(hStallFit)
        legendEntries{end+1} = 'Stall Onset Line Fit';
        legendObjects = [legendObjects, hStallFit(1)];
    end
    hKoch = findobj(hLines, 'Tag', 'KochLimit');
    if ~isempty(hKoch)
        legendEntries{end+1} = 'Koch Stall Limit';
        legendObjects = [legendObjects, hKoch(1)];
    end

    hSpeedLines = findobj(hLines, 'LineStyle', '--', 'Marker', 'o');
    if ~isempty(hSpeedLines)
        if length(hSpeedLines) > 10
            selectedLines = hSpeedLines(1:2:end);
            legendObjects = [legendObjects, selectedLines(:)'];
            for i = 1:2:length(hSpeedLines)
                legendEntries{end+1} = get(hSpeedLines(i), 'DisplayName');
            end
        else
            legendObjects = [legendObjects, hSpeedLines(:)'];
            for i = 1:length(hSpeedLines)
                legendEntries{end+1} = get(hSpeedLines(i), 'DisplayName');
            end
        end
    end

    hChoke = findobj(hLines, 'MarkerFaceColor', 'b', 'Marker', 's');
    if ~isempty(hChoke)
        legendEntries{end+1} = 'Choke Point';
        legendObjects = [legendObjects, hChoke(1)];
    end

    % Choke Line
    hChokeLine = findobj(hLines, 'LineStyle', '-.', 'Color', 'b');
    if ~isempty(hChokeLine)
        legendEntries{end+1} = 'Choke Line';
        legendObjects = [legendObjects, hChokeLine(1)];
    end

    % Choke Line Fit
    hChokeFit = findobj(hLines, 'LineStyle', ':', 'Color', 'b');
    if ~isempty(hChokeFit)
        legendEntries{end+1} = 'Choke Line Fit';
        legendObjects = [legendObjects, hChokeFit(1)];
    end

    if ~isempty(legendObjects)
        legend(ax, legendObjects, legendEntries, 'Location', 'best');
    end

    % Ensure surge/stall points and the design point stay on top
    if exist('h_surge_points', 'var') && ~isempty(h_surge_points)
        uistack(h_surge_points, 'top');
    end
    if exist('h_stall_points', 'var') && ~isempty(h_stall_points)
        uistack(h_stall_points, 'top');
    end
    uistack(h_design_pr, 'top');

    % One popup with all stability-boundary equations of this map
    if ~isempty(eq_msgs)
        app.report_equations(eq_msgs, ax);
    end

    % Formatting - dynamic y-limits, sized from the same points actually
    % drawn above (plus the exact design point at 1) rather than the raw
    % matrix. This matters because a handful of grid cells in
    % results.Overall_Eff can come out complex - the same numerical
    % artifact discussed for Eff_design in plot_relative_non_dimensional_
    % compressor_map_Eff below, just occurring at scattered off-design
    % points instead of at the design point itself. plot() and the
    % valid_idx comparisons above already tolerate that silently (MATLAB
    % compares/draws complex data by its real part), so plotted_PR_rel is
    % effectively real-valued already; real() here is just a final,
    % harmless safety net, since ylim() - unlike plot() - hard-errors on
    % a complex bound.
    ax.FontSize = 12;
    plotted_PR_rel(end+1) = 1; % exact design point
    plotted_PR_rel = real(plotted_PR_rel);
    if ~isempty(plotted_PR_rel)
        ylim(ax, [min(0.9*min(plotted_PR_rel), 0.9), max(1.1*max(plotted_PR_rel), 1.1)]);
    end
end

function plot_relative_non_dimensional_compressor_map_Eff(app, ax, results)
    % Plot relative non-dimensional compressor map - Efficiency
    % Both axes are normalized by the design point (MFP1/MFP1_design,
    % Eff/Eff_design), so the design point always plots at exactly (1, 1).
    app.clear_axes(ax);   % step 16: also the markers drawn with hidden handles (cla leaves them)
    hold(ax, 'on');
    grid(ax, 'on');
    box(ax, 'on');
    xlabel(ax, 'MFP$_1$ / MFP$_{1,design}$', 'Interpreter', 'latex', 'FontSize', 12);
    ylabel(ax, '\eta / \eta_{design}', 'Interpreter', 'tex');
    title(ax, sprintf('Relative Non-dimensional Compressor Map: Efficiency - %s', results.compressor_type));

    speed_ratio = results.speed_ratio;   % N/N_des (design speed = 1.00)
    colors = lines(length(results.U_range));

    % Relative (normalized-by-design) versions of the full matrices. See the
    % matching note in plot_relative_non_dimensional_compressor_map_PR -
    % no special handling needed here either.
    MFP1_rel_matrix = results.MFP1_matrix / results.MFP1_design;
    Eff_rel_matrix  = results.Overall_Eff / results.Eff_design;

    % plotted_Eff_rel accumulates exactly the values that actually get
    % drawn below (same valid_idx filter, same real-part tolerance as the
    % rest of this function), for the same reason as plotted_PR_rel in
    % the PR version of this plot.
    plotted_Eff_rel = [];
    for u_idx = 1:length(results.U_range)
        valid_idx = ~isnan(results.Total_PR(u_idx, :)) & ~isnan(results.Overall_Eff(u_idx, :)) & ...
                   (results.Overall_Eff(u_idx, :) > 0.1) & (results.Overall_Eff(u_idx, :) < 1.0);

        if any(valid_idx)
            current_MFP_rel = MFP1_rel_matrix(u_idx, valid_idx);
            current_Eff_rel = Eff_rel_matrix(u_idx, valid_idx);

            [sorted_MFP_rel, sort_idx] = sort(current_MFP_rel);
            sorted_Eff_rel = current_Eff_rel(sort_idx);

            plot(ax, sorted_MFP_rel, sorted_Eff_rel, '--o', 'LineWidth', 1.5, ...
                'Color', colors(u_idx,:), ...
                'DisplayName', sprintf('N/N_{des} = %.2f', speed_ratio(u_idx)));

            plotted_Eff_rel = [plotted_Eff_rel, sorted_Eff_rel]; %#ok<AGROW>

            % Mark the exact choke point of this speed line (if it chokes at PR > 1)
            if results.choke_in_region(u_idx) && real(results.choke_Eff(u_idx)) > 0.1 && real(results.choke_Eff(u_idx)) < 1.0
                % Extend the speed line down to its exact choke point (the near-
                % vertical drop between the last grid point and choke)
                j_draw = find(valid_idx, 1, 'last');
                if j_draw == find(~isnan(results.Total_PR(u_idx, :)), 1, 'last')
                    plot(ax, [MFP1_rel_matrix(u_idx, j_draw), results.choke_MFP(u_idx)/results.MFP1_design], [Eff_rel_matrix(u_idx, j_draw), results.choke_Eff(u_idx)/results.Eff_design], '--', 'Color', colors(u_idx,:), ...
                        'LineWidth', 1.5, 'HandleVisibility', 'off');
                end
                plot(ax, results.choke_MFP(u_idx)/results.MFP1_design, results.choke_Eff(u_idx)/results.Eff_design, 's', 'MarkerSize', 10, ...
                    'LineWidth', 2, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'k', ...
                    'HandleVisibility', 'off');
                plotted_Eff_rel = [plotted_Eff_rel, real(results.choke_Eff(u_idx)/results.Eff_design)]; %#ok<AGROW>
            end
        end
    end

    plot(ax, 1, 1, 'p', 'MarkerSize', 16, 'LineWidth', 2, ...
        'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', 'DisplayName', 'Design Point');

    text(ax, 1.02, 0.98, 'Design Point', ...
        'FontSize', 10, 'Color', 'k', 'FontWeight', 'bold');

    % Formatting - dynamic y-limits, sized from the same points actually
    % drawn above (plus the exact design point at 1), not the raw matrix.
    %
    % Root cause note: Eff_design (and, at scattered off-design grid
    % points, individual entries of results.Overall_Eff) can come out
    % complex. This traces back to Eff = (PR^((gamma-1)/gamma) - 1) /
    % (TR - 1) in compute_rotor_stator/calculate_design_point_rs: a
    % negative-real base raised to the non-integer exponent (gamma-1)/
    % gamma is complex in MATLAB. PR going negative at a handful of
    % points is itself the underlying anomaly - almost certainly the
    % omega_S/omega_R loss coefficient (or the deviation spline) being
    % extrapolated outside the incidence range it was actually fitted
    % over, driving a stage's exit total pressure below zero. That is a
    % numerical/modeling artifact, not a physical result - worth
    % tightening the correlation's valid domain or clamping incidence
    % before evaluating it, independent of this plot.
    %
    % None of that is new here: plot() and the valid_idx comparisons
    % above already tolerate it silently (MATLAB compares/draws complex
    % data by its real part), so plotted_Eff_rel is effectively
    % real-valued already; real() below is just a final, harmless safety
    % net, since ylim() - unlike plot() - hard-errors on a complex bound.
    ax.FontSize = 12;
    plotted_Eff_rel(end+1) = 1; % exact design point
    plotted_Eff_rel = real(plotted_Eff_rel);
    if ~isempty(plotted_Eff_rel)
        ylim(ax, [max(0, 0.9*min(plotted_Eff_rel)), max(1.1*max(plotted_Eff_rel), 1.05)]);
    end
end



        
    end

    % step 27: called by the design app (Compressor_design_app, "Send to off-design")
    methods (Access = public)
        function load_design_file(app, file, typ)
            % Load a design .mat as if the user had chosen the compressor type,
            % "mat file input" and pressed "upload file".
            app.Choosethecompressortype.Value = typ;
            app.InputTypeButtonGroup.SelectedObject = app.matfileinputButton;
            app.ChooseInputtypeButtonPushed([]);
            [pth, nm] = fileparts(file);
            app.last_folder = pth; app.mat_name = nm;
            data = load(file);
            app.loadedData = data;
            app.YourMatFileEditField.Value = "MAT file loaded (from the design app): " + string(file);
            [ok, msg] = app.check_mat_variables(data, typ);
            if ok
                app.load_inputs_from_struct(data, typ);
                app.fill_manual_fields();
                msg = [msg, app.consistency_warnings()];
            end
            app.upload_message.Value = msg(:);
            figure(app.UIFigure);
        end
    end
    



    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, main)
                % main: CDA launcher app (optional). Without it the app starts on its own.
                if nargin < 2, main = []; end
                app.Mainapp = main;
                % Prevent the figure window from being resized
                app.UIFigure.Resize = 'off';
                % Keep existing setting for children 
                app.UIFigure.AutoResizeChildren = 'off';
                app.YourMatFileEditField.Value = 'please press upload to choose your ".mat" file';
                % app.FileTab.Children = 'off';
                  % First, disable ALL fields in the ManualTab
                h= findobj(app.ManualTab,'Type','uieditfield');
                set(h,'Enable','off')
                g = findobj(app.ManualTab, 'Type', 'uinumericeditfield');
                set(g, 'Enable', 'off');
                hLabels = findobj(app.ManualTab, 'Type', 'uilabel');
                set(hLabels, 'Enable', 'off');
                k= findobj(app.FileTab,'Type','uieditfield');
                set(k,'Enable','off')
                kLabels = findobj(app.FileTab, 'Type', 'uilabel');
                set(kLabels, 'Enable', 'off');
                kj = findobj(app.FileTab,'Type','uibutton');
                set(kj,'Enable','off')
                app.upload_message.Editable = "off";
                app.build_results_ui();     % step 12: Guide/Settings/Maps/Tables/... tabs made in code
                app.init_settings_ui();     % step 11: defaults into the Settings tab (if it exists)
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            try
                if ~isempty(app.Mainapp) && isvalid(app.Mainapp)
                    app.Mainapp.GotooperationButton.Enable = 'on';
                end
            catch
            end
            delete(app)
            
        end

        % Button pushed function: ChooseInputtypeButton
        function ChooseInputtypeButtonPushed(app, event)
            app.InputType_value = app.InputTypeButtonGroup.SelectedObject;
            app.Compressor_type = app.Choosethecompressortype.Value;
            
            if app.InputType_value == app.ManualinputButton
                app.Inputs.SelectedTab = app.ManualTab;
                k= findobj(app.FileTab,'Type','uieditfield');
                set(k,'Enable','off')
                kLabels = findobj(app.FileTab, 'Type', 'uilabel');
                set(kLabels, 'Enable', 'off');
                kj = findobj(app.FileTab,'Type','uibutton');
                set(kj,'Enable','off')
            else
                app.Inputs.SelectedTab = app.FileTab;
                k= findobj(app.FileTab,'Type','uieditfield');
                set(k,'Enable','on')
                kLabels = findobj(app.FileTab, 'Type', 'uilabel');
                set(kLabels, 'Enable', 'on');
                kj = findobj(app.FileTab,'Type','uibutton');
                set(kj,'Enable','on')
            end
           
            % Then enable fields based on the specific case
            switch app.Compressor_type
                case 'Rotor-Stator'
                    app.A_vecEditField.Enable = "on";
                    app.A_vecEditFieldLabel.Enable = "on";
                    app.n_stagesEditField.Enable = "on" ;
                    app.n_stagesEditFieldLabel.Enable = "on";
                    app.m_dotEditField.Enable = "on";
                    app.m_dotEditFieldLabel.Enable = "on";
                    app.U1EditField.Enable ="on";
                    app.deviationEditFieldLabel.Enable ="on";
                    app.incidenceEditFieldLabel.Enable = "on";
                    app.deflectionEditFieldLabel.Enable = "on";
                    app.w_loss_rotorEditFieldLabel.Enable = "on";
                    app.U1EditFieldLabel.Enable = "on";
                    app.w_loss_rotorEditField.Enable = "on";
                    app.deflectionEditField.Enable = "on";
                    app.incidenceEditField.Enable = "on";
                    app.deviationEditField.Enable = "on";
                    app.beta2_dashEditField.Enable = "on";
                    app.beta2_dashEditFieldLabel.Enable = "on";
                    app.beta1_dashEditField.Enable = "on";
                    app.beta1_dashEditFieldLabel.Enable = "on";
                    app.alpha_1EditField.Enable = "on";
                    app.alpha_1EditFieldLabel.Enable = "on";
                    app.U2EditField.Enable = "off";
                    app.U2EditFieldLabel.Enable = "off";
                    app.deflection2EditField.Enable = "off";
                    app.incidence2EditField.Enable = "off";
                    app.deviation2EditField.Enable = "off";
                    app.beta4_dashEditField.Enable = "off";
                    app.beta4_dashEditFieldLabel.Enable = "off";
                    app.deviation2EditFieldLabel.Enable = "off";
                    app.incidence2EditFieldLabel.Enable = "off";
                    app.deflection2EditFieldLabel.Enable = "off";
                    app.w_loss_rotor2EditFieldLabel.Enable = "on";
                    app.U2EditFieldLabel.Enable = "off";
                    app.beta3_dashEditField.Enable = "off";
                    app.beta3_dashEditFieldLabel.Enable = "off";
                    app.w_loss_rotor2EditField.Enable = "on";
                case 'Rotor-Rotor same shaft'
                    h= findobj(app.ManualTab,'Type','uieditfield');
                    set(h,'Enable','on')
                    g = findobj(app.ManualTab, 'Type', 'uinumericeditfield');
                    set(g, 'Enable', 'on');
                    hLabels = findobj(app.ManualTab, 'Type', 'uilabel');
                    set(hLabels, 'Enable', 'on');
                    app.U2EditField.Enable = "off";
                    app.U2EditFieldLabel.Enable = "off";
                case "Rotor-Rotor different shaft"
                    h= findobj(app.ManualTab,'Type','uieditfield');
                    set(h,'Enable','on')
                    g = findobj(app.ManualTab, 'Type', 'uinumericeditfield');
                    set(g, 'Enable', 'on');
                    hLabels = findobj(app.ManualTab, 'Type', 'uilabel');
                    set(hLabels, 'Enable', 'on');
            end
                    
        end

        % Button pushed function: uploadfileButton
        function uploadfileButtonPushed(app, event)
            app.InputType_value = app.InputTypeButtonGroup.SelectedObject;
            app.Compressor_type = app.Choosethecompressortype.Value;
            [file, path] = uigetfile(fullfile(app.last_folder, '*.mat'), 'Select a MAT file');   % step 14: last folder
            if isequal(file, 0)
                % User canceled the selection
                app.YourMatFileEditField.Value = 'MAT file loading canceled.';
            else
                fullFilePath = fullfile(path, file);
                app.last_folder = path;
                [~, app.mat_name] = fileparts(file);   % step 18: used in the export file names
                data = load(fullFilePath); % Load the .mat file
                app.loadedData = data; % Store the loaded data in the app property
                app.YourMatFileEditField.Value = "MAT file loaded: "+ fullFilePath;
                % Step 14: variables checked by name; the message lists what is missing or misspelled
                if isfield(data, 'compressor_session')
                    app.upload_message.Value = {'This is a session file: open it with "Open session..." in the Settings tab.'};
                    return;
                end
                [ok, msg] = app.check_mat_variables(data, app.Compressor_type);
                if ok
                    app.load_inputs_from_struct(data, app.Compressor_type);
                    app.fill_manual_fields();
                    msg = [msg, app.consistency_warnings()];
                end
                app.upload_message.Value = msg(:);
            end
        end

        % Button pushed function: RunButton
        function RunButtonPushed(app, event)
            app.InputType_value = app.InputTypeButtonGroup.SelectedObject;
            app.Compressor_type = app.Choosethecompressortype.Value; 
            if app.InputType_value == app.ManualinputButton
                 switch app.Compressor_type
                    case 'Rotor-Rotor different shaft'
                            app.alpha1 = app.alpha_1EditField.Value;
                            app.n_stages = app.n_stagesEditField.Value;
                            A_vec_str = app.A_vecEditField.Value;
                            % Remove any brackets or parentheses if present
                            A_vec_str = regexprep(A_vec_str, '[\[\]()]', '');
                            % Split on spaces or commas
                            stringCells = regexp(A_vec_str, '[,\s]+', 'split');
                            % Convert to numbers
                            app.A_vec = str2double(stringCells);
                            % Remove any NaN values (in case of empty cells)
                            app.A_vec = app.A_vec(~isnan(app.A_vec));
                            app.beta1_dash = app.beta1_dashEditField.Value;
                            app.beta2_dash = app.beta2_dashEditField.Value;
                            app.beta3_dash = app.beta3_dashEditField.Value;
                            app.beta4_dash =  app.beta4_dashEditField.Value;
                            app.deviation_1 = app.deviationEditField.Value;
                            app.deviation_2 = app.deviation2EditField.Value;
                            app.incidence_1 = app.incidenceEditField.Value;
                            app.incidence_2 =  app.incidence2EditField.Value;
                            app.deflection_1 = app.deflectionEditField.Value;
                            app.deflection_2 = app.deflection2EditField.Value;
                            app.m_dot = app.m_dotEditField.Value;
                            app.w_loss_rotor = app.w_loss_rotorEditField.Value;
                            app.w_loss_rotor2 =app.w_loss_rotor2EditField.Value;
                            app.U1 = app.U1EditField.Value;
                            app.U2 =  app.U2EditField.Value;
                    case 'Rotor-Rotor same shaft'
                            app.alpha1 = app.alpha_1EditField.Value;
                            app.n_stages = app.n_stagesEditField.Value;
                            A_vec_str = app.A_vecEditField.Value;
                            % Remove any brackets or parentheses if present
                            A_vec_str = regexprep(A_vec_str, '[\[\]()]', '');
                            % Split on spaces or commas
                            stringCells = regexp(A_vec_str, '[,\s]+', 'split');
                            % Convert to numbers
                            app.A_vec = str2double(stringCells);
                            % Remove any NaN values (in case of empty cells)
                            app.A_vec = app.A_vec(~isnan(app.A_vec));
                            app.beta1_dash = app.beta1_dashEditField.Value;
                            app.beta2_dash = app.beta2_dashEditField.Value;
                            app.beta3_dash = app.beta3_dashEditField.Value;
                            app.beta4_dash =  app.beta4_dashEditField.Value;
                            app.deviation_1 = app.deviationEditField.Value;
                            app.deviation_2 = app.deviation2EditField.Value;
                            app.incidence_1 = app.incidenceEditField.Value;
                            app.incidence_2 =  app.incidence2EditField.Value;
                            app.deflection_1 = app.deflectionEditField.Value;
                            app.deflection_2 = app.deflection2EditField.Value;
                            app.m_dot = app.m_dotEditField.Value;
                            app.w_loss_rotor = app.w_loss_rotorEditField.Value;
                            app.w_loss_rotor2 =app.w_loss_rotor2EditField.Value;
                            app.U1 = app.U1EditField.Value;
                    case 'Rotor-Stator'
                            app.alpha1 = app.alpha_1EditField.Value;
                            app.n_stages = app.n_stagesEditField.Value;
                            A_vec_str = app.A_vecEditField.Value;
                            % Remove any brackets or parentheses if present
                            A_vec_str = regexprep(A_vec_str, '[\[\]()]', '');
                            % Split on spaces or commas
                            stringCells = regexp(A_vec_str, '[,\s]+', 'split');
                            % Convert to numbers
                            app.A_vec = str2double(stringCells);
                            % Remove any NaN values (in case of empty cells)
                            app.A_vec = app.A_vec(~isnan(app.A_vec));
                            app.beta1_dash = app.beta1_dashEditField.Value;
                            app.beta2_dash = app.beta2_dashEditField.Value;
                            app.deviation_1 = app.deviationEditField.Value;
                            app.incidence_1 = app.incidenceEditField.Value;
                            app.deflection_1 = app.deflectionEditField.Value;
                            app.m_dot = app.m_dotEditField.Value;
                            app.w_loss_rotor  = app.w_loss_rotorEditField.Value;
                            app.w_loss_rotor2 = app.w_loss_rotor2EditField.Value;   % stator loss for rotor-stator
                            app.U1 = app.U1EditField.Value;
                end
            end
            
            app.read_settings_from_ui();   % step 14: settings first (the input check uses them)

            % Validate inputs
            if ~app.validate_inputs()
                return;
            end
            
            % Settings tab -> properties (step 11; fields that do not exist are skipped)
            app.read_settings_from_ui();

            % Show busy indicator
            d = uiprogressdlg(app.UIFigure, 'Title', 'Please Wait',...
                'Message', 'Computing compressor performance...', 'Indeterminate', 'on');
            app.RunButton.Enable = 'off';                      % step 14: no second run while computing
            runGuard = onCleanup(@() app.enable_run());        % re-enabled when the callback ends
            
            try
                % Perform computation based on compressor type (text report captured)
                app.run_computation();

                % Check if computation was successful
                if isempty(app.computation_results)
                    close(d);
                    return;
                end

                % Maps, tables, equations, diagnostics and report (inside the app;
                % separate windows if the app has no Maps tab or the box is ticked)
                app.present_results();

            catch ME
                uialert(app.UIFigure, sprintf('Error during computation: %s', ME.message), 'Computation Error');
            end
            
            % Close progress dialog
            close(d);
        end

        % Button pushed function: ResetButton
        function ResetButtonPushed(app, event)
           % Reset all input fields to default values (not empty)
            app.alpha_1EditField.Value = 0;
            app.A_vecEditField.Value = '';
            app.beta1_dashEditField.Value = 0;
            app.beta2_dashEditField.Value = 0;
            app.beta3_dashEditField.Value = 0;
            app.beta4_dashEditField.Value = 0;
            app.deviationEditField.Value = 0;
            app.deviation2EditField.Value = 0;
            app.incidenceEditField.Value = 0;
            app.incidence2EditField.Value = 0;
            app.deflectionEditField.Value = 0;
            app.deflection2EditField.Value = 0;
            app.m_dotEditField.Value = 0;
            app.w_loss_rotorEditField.Value = 0;
            app.w_loss_rotor2EditField.Value = 0;
            app.U1EditField.Value = 0;
            app.U2EditField.Value = 0;
            app.n_stagesEditField.Value = 1; % Set to 1 as default
            
            % Reset all app properties that store input values
            app.alpha1 = [];
            app.n_stages = [];
            app.A_vec = [];
            app.beta1_dash = [];
            app.beta2_dash = [];
            app.beta3_dash = [];
            app.beta4_dash = [];
            app.deviation_1 = [];
            app.deviation_2 = [];
            app.incidence_1 = [];
            app.incidence_2 = [];
            app.deflection_1 = [];
            app.deflection_2 = [];
            app.m_dot = [];
            app.w_loss_rotor = [];
            app.w_loss_rotor2 = [];
            app.U1 = [];
            app.U2 = [];
            
            % Reset loaded data
            app.loadedData = [];
            app.YourMatFileEditField.Value = 'please press upload to choose your ".mat" file';
            app.upload_message.Value = '';
            
            % Clear computation results
            app.computation_results = [];
            
            % Close any open figure windows from previous runs
            figHandles = findall(0, 'Type', 'figure');
            for i = 1:length(figHandles)
                if ~isequal(figHandles(i), app.UIFigure) && ~strcmp(figHandles(i).Name, 'MATLAB App')
                    try
                        close(figHandles(i));
                    catch
                        % Ignore errors when closing figures
                    end
                end
            end
            
            % Reset to default compressor type and input type
            app.Choosethecompressortype.Value = 'Rotor-Stator';
            app.ManualinputButton.Value = true;
            app.matfileinputButton.Value = false;
            
            % Step 16: all inputs closed, as at start-up (press "Choose Input type" to open them)
            app.lock_inputs();
            
            
            % Empty the result tabs (step 11)
            app.clear_results_view();

            % Show confirmation message
            uialert(app.UIFigure, 'All inputs and results have been reset successfully.', 'Reset Complete');
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1476 599];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create ChoosethecompressortypeDropDownLabel
            app.ChoosethecompressortypeDropDownLabel = uilabel(app.UIFigure);
            app.ChoosethecompressortypeDropDownLabel.HorizontalAlignment = 'right';
            app.ChoosethecompressortypeDropDownLabel.FontSize = 14;
            app.ChoosethecompressortypeDropDownLabel.Position = [12 481 188 22];
            app.ChoosethecompressortypeDropDownLabel.Text = 'Choose the compressor type';

            % Create Choosethecompressortype
            app.Choosethecompressortype = uidropdown(app.UIFigure);
            app.Choosethecompressortype.Items = {'Rotor-Stator', 'Rotor-Rotor same shaft', 'Rotor-Rotor different shaft'};
            app.Choosethecompressortype.FontSize = 14;
            app.Choosethecompressortype.Position = [215 473 181 37];
            app.Choosethecompressortype.Value = 'Rotor-Stator';

            % Create TextArea
            app.TextArea = uitextarea(app.UIFigure);
            app.TextArea.HorizontalAlignment = 'center';
            app.TextArea.FontSize = 18;
            app.TextArea.Position = [17 522 404 70];
            app.TextArea.Value = {'ًWelcome to compressor Off-design!Please follow Flowchart  and the steps in the instruction section!'};

            % Create ChooseInputtypeButton
            app.ChooseInputtypeButton = uibutton(app.UIFigure, 'push');
            app.ChooseInputtypeButton.ButtonPushedFcn = createCallbackFcn(app, @ChooseInputtypeButtonPushed, true);
            app.ChooseInputtypeButton.FontSize = 16;
            app.ChooseInputtypeButton.Position = [238 416 157 30];
            app.ChooseInputtypeButton.Text = 'Choose Input type';

            % Create InputTypeButtonGroup
            app.InputTypeButtonGroup = uibuttongroup(app.UIFigure);
            app.InputTypeButtonGroup.TitlePosition = 'centertop';
            app.InputTypeButtonGroup.Title = 'Input Type';
            app.InputTypeButtonGroup.FontSize = 14;
            app.InputTypeButtonGroup.Position = [56 397 138 69];

            % Create ManualinputButton
            app.ManualinputButton = uiradiobutton(app.InputTypeButtonGroup);
            app.ManualinputButton.Text = 'Manual input';
            app.ManualinputButton.FontSize = 14;
            app.ManualinputButton.Position = [11 23 104 22];
            app.ManualinputButton.Value = true;

            % Create matfileinputButton
            app.matfileinputButton = uiradiobutton(app.InputTypeButtonGroup);
            app.matfileinputButton.Text = 'mat file input';
            app.matfileinputButton.FontSize = 14;
            app.matfileinputButton.Position = [11 1 102 22];

            % Create Inputs
            app.Inputs = uitabgroup(app.UIFigure);
            app.Inputs.Position = [2 1 427 338];

            % Create ManualTab
            app.ManualTab = uitab(app.Inputs);
            app.ManualTab.Title = 'Manual';

            % Create alpha_1EditFieldLabel
            app.alpha_1EditFieldLabel = uilabel(app.ManualTab);
            app.alpha_1EditFieldLabel.HorizontalAlignment = 'right';
            app.alpha_1EditFieldLabel.Position = [42 244 46 22];
            app.alpha_1EditFieldLabel.Text = 'alpha_1';

            % Create alpha_1EditField
            app.alpha_1EditField = uieditfield(app.ManualTab, 'numeric');
            app.alpha_1EditField.Position = [103 244 100 22];

            % Create beta1_dashEditFieldLabel
            app.beta1_dashEditFieldLabel = uilabel(app.ManualTab);
            app.beta1_dashEditFieldLabel.HorizontalAlignment = 'right';
            app.beta1_dashEditFieldLabel.Position = [22 209 66 22];
            app.beta1_dashEditFieldLabel.Text = 'beta1_dash';

            % Create beta1_dashEditField
            app.beta1_dashEditField = uieditfield(app.ManualTab, 'numeric');
            app.beta1_dashEditField.Position = [103 209 100 22];

            % Create beta2_dashEditFieldLabel
            app.beta2_dashEditFieldLabel = uilabel(app.ManualTab);
            app.beta2_dashEditFieldLabel.HorizontalAlignment = 'right';
            app.beta2_dashEditFieldLabel.Position = [223 209 66 22];
            app.beta2_dashEditFieldLabel.Text = 'beta2_dash';

            % Create beta2_dashEditField
            app.beta2_dashEditField = uieditfield(app.ManualTab, 'numeric');
            app.beta2_dashEditField.Position = [305 209 100 22];

            % Create deviationEditFieldLabel
            app.deviationEditFieldLabel = uilabel(app.ManualTab);
            app.deviationEditFieldLabel.HorizontalAlignment = 'right';
            app.deviationEditFieldLabel.Position = [37 146 51 22];
            app.deviationEditFieldLabel.Text = 'deviation';

            % Create deviationEditField
            app.deviationEditField = uieditfield(app.ManualTab, 'numeric');
            app.deviationEditField.Position = [103 146 100 22];

            % Create incidenceEditFieldLabel
            app.incidenceEditFieldLabel = uilabel(app.ManualTab);
            app.incidenceEditFieldLabel.HorizontalAlignment = 'right';
            app.incidenceEditFieldLabel.Position = [234 146 55 22];
            app.incidenceEditFieldLabel.Text = 'incidence';

            % Create incidenceEditField
            app.incidenceEditField = uieditfield(app.ManualTab, 'numeric');
            app.incidenceEditField.Position = [305 146 100 22];

            % Create deflectionEditFieldLabel
            app.deflectionEditFieldLabel = uilabel(app.ManualTab);
            app.deflectionEditFieldLabel.HorizontalAlignment = 'right';
            app.deflectionEditFieldLabel.Position = [33 86 55 22];
            app.deflectionEditFieldLabel.Text = 'deflection';

            % Create deflectionEditField
            app.deflectionEditField = uieditfield(app.ManualTab, 'numeric');
            app.deflectionEditField.Position = [103 86 100 22];

            % Create w_loss_rotorEditFieldLabel
            app.w_loss_rotorEditFieldLabel = uilabel(app.ManualTab);
            app.w_loss_rotorEditFieldLabel.HorizontalAlignment = 'right';
            app.w_loss_rotorEditFieldLabel.Position = [16 53 72 22];
            app.w_loss_rotorEditFieldLabel.Text = 'w_loss_rotor';

            % Create w_loss_rotorEditField
            app.w_loss_rotorEditField = uieditfield(app.ManualTab, 'numeric');
            app.w_loss_rotorEditField.Position = [103 53 100 22];

            % Create w_loss_rotor2EditFieldLabel
            app.w_loss_rotor2EditFieldLabel = uilabel(app.ManualTab);
            app.w_loss_rotor2EditFieldLabel.HorizontalAlignment = 'right';
            app.w_loss_rotor2EditFieldLabel.Position = [210 53 79 22];
            app.w_loss_rotor2EditFieldLabel.Text = 'w_loss_rotor2';

            % Create w_loss_rotor2EditField
            app.w_loss_rotor2EditField = uieditfield(app.ManualTab, 'numeric');
            app.w_loss_rotor2EditField.Position = [304 53 100 22];

            % Create beta3_dashEditFieldLabel
            app.beta3_dashEditFieldLabel = uilabel(app.ManualTab);
            app.beta3_dashEditFieldLabel.HorizontalAlignment = 'right';
            app.beta3_dashEditFieldLabel.Position = [22 177 66 22];
            app.beta3_dashEditFieldLabel.Text = 'beta3_dash';

            % Create beta3_dashEditField
            app.beta3_dashEditField = uieditfield(app.ManualTab, 'numeric');
            app.beta3_dashEditField.Position = [103 177 100 22];

            % Create beta4_dashEditFieldLabel
            app.beta4_dashEditFieldLabel = uilabel(app.ManualTab);
            app.beta4_dashEditFieldLabel.HorizontalAlignment = 'right';
            app.beta4_dashEditFieldLabel.Position = [223 177 66 22];
            app.beta4_dashEditFieldLabel.Text = 'beta4_dash';

            % Create beta4_dashEditField
            app.beta4_dashEditField = uieditfield(app.ManualTab, 'numeric');
            app.beta4_dashEditField.Position = [305 177 100 22];

            % Create deviation2EditFieldLabel
            app.deviation2EditFieldLabel = uilabel(app.ManualTab);
            app.deviation2EditFieldLabel.HorizontalAlignment = 'right';
            app.deviation2EditFieldLabel.Position = [31 116 57 22];
            app.deviation2EditFieldLabel.Text = 'deviation2';

            % Create deviation2EditField
            app.deviation2EditField = uieditfield(app.ManualTab, 'numeric');
            app.deviation2EditField.Position = [103 116 100 22];

            % Create incidence2EditFieldLabel
            app.incidence2EditFieldLabel = uilabel(app.ManualTab);
            app.incidence2EditFieldLabel.HorizontalAlignment = 'right';
            app.incidence2EditFieldLabel.Position = [228 116 61 22];
            app.incidence2EditFieldLabel.Text = 'incidence2';

            % Create incidence2EditField
            app.incidence2EditField = uieditfield(app.ManualTab, 'numeric');
            app.incidence2EditField.Position = [305 116 100 22];

            % Create deflection2EditFieldLabel
            app.deflection2EditFieldLabel = uilabel(app.ManualTab);
            app.deflection2EditFieldLabel.HorizontalAlignment = 'right';
            app.deflection2EditFieldLabel.Position = [228 86 61 22];
            app.deflection2EditFieldLabel.Text = 'deflection2';

            % Create deflection2EditField
            app.deflection2EditField = uieditfield(app.ManualTab, 'numeric');
            app.deflection2EditField.Position = [304 86 100 22];

            % Create U1EditFieldLabel
            app.U1EditFieldLabel = uilabel(app.ManualTab);
            app.U1EditFieldLabel.HorizontalAlignment = 'right';
            app.U1EditFieldLabel.Position = [63 22 25 22];
            app.U1EditFieldLabel.Text = 'U1';

            % Create U1EditField
            app.U1EditField = uieditfield(app.ManualTab, 'numeric');
            app.U1EditField.Position = [103 22 100 22];

            % Create U2EditFieldLabel
            app.U2EditFieldLabel = uilabel(app.ManualTab);
            app.U2EditFieldLabel.HorizontalAlignment = 'right';
            app.U2EditFieldLabel.Position = [265 22 25 22];
            app.U2EditFieldLabel.Text = 'U2';

            % Create U2EditField
            app.U2EditField = uieditfield(app.ManualTab, 'numeric');
            app.U2EditField.Position = [305 22 100 22];

            % Create m_dotEditFieldLabel
            app.m_dotEditFieldLabel = uilabel(app.ManualTab);
            app.m_dotEditFieldLabel.HorizontalAlignment = 'right';
            app.m_dotEditFieldLabel.Position = [50 278 38 22];
            app.m_dotEditFieldLabel.Text = 'm_dot';

            % Create m_dotEditField
            app.m_dotEditField = uieditfield(app.ManualTab, 'numeric');
            app.m_dotEditField.Position = [103 278 100 22];

            % Create A_vecEditFieldLabel
            app.A_vecEditFieldLabel = uilabel(app.ManualTab);
            app.A_vecEditFieldLabel.HorizontalAlignment = 'right';
            app.A_vecEditFieldLabel.Position = [253 244 37 22];
            app.A_vecEditFieldLabel.Text = 'A_vec';

            % Create A_vecEditField
            app.A_vecEditField = uieditfield(app.ManualTab, 'text');
            app.A_vecEditField.Position = [305 244 100 22];

            % Create n_stagesEditFieldLabel
            app.n_stagesEditFieldLabel = uilabel(app.ManualTab);
            app.n_stagesEditFieldLabel.HorizontalAlignment = 'right';
            app.n_stagesEditFieldLabel.Position = [237 278 53 22];
            app.n_stagesEditFieldLabel.Text = 'n_stages';

            % Create n_stagesEditField
            app.n_stagesEditField = uieditfield(app.ManualTab, 'numeric');
            app.n_stagesEditField.Position = [305 278 100 22];

            % Create FileTab
            app.FileTab = uitab(app.Inputs);
            app.FileTab.Title = 'File';

            % Create YourMatFileEditFieldLabel
            app.YourMatFileEditFieldLabel = uilabel(app.FileTab);
            app.YourMatFileEditFieldLabel.HorizontalAlignment = 'right';
            app.YourMatFileEditFieldLabel.Position = [21 230 71 22];
            app.YourMatFileEditFieldLabel.Text = 'Your Mat File';

            % Create YourMatFileEditField
            app.YourMatFileEditField = uieditfield(app.FileTab, 'text');
            app.YourMatFileEditField.Position = [107 230 286 22];

            % Create uploadfileButton
            app.uploadfileButton = uibutton(app.FileTab, 'push');
            app.uploadfileButton.ButtonPushedFcn = createCallbackFcn(app, @uploadfileButtonPushed, true);
            app.uploadfileButton.Position = [168 177 100 22];
            app.uploadfileButton.Text = 'upload file';

            % Create upload_message
            app.upload_message = uitextarea(app.FileTab);
            app.upload_message.HorizontalAlignment = 'center';
            app.upload_message.FontSize = 18;
            app.upload_message.Position = [77 53 281 94];
            app.upload_message.Value = {'If uploaded successfully, you will find your data inmanual tab, please review them before pressing Run!'};

            % Create RunButton
            app.RunButton = uibutton(app.UIFigure, 'push');
            app.RunButton.ButtonPushedFcn = createCallbackFcn(app, @RunButtonPushed, true);
            app.RunButton.FontSize = 18;
            app.RunButton.Position = [65 350 126 33];
            app.RunButton.Text = 'Run';

            % Create InstructionsPanel
            app.InstructionsPanel = uipanel(app.UIFigure);
            app.InstructionsPanel.TitlePosition = 'centertop';
            app.InstructionsPanel.Title = 'Instructions';
            app.InstructionsPanel.BackgroundColor = [1 1 1];
            app.InstructionsPanel.FontWeight = 'bold';
            app.InstructionsPanel.FontSize = 16;
            app.InstructionsPanel.Position = [428 1 1052 599];

            % Create Flowchart
            app.Flowchart = uiimage(app.InstructionsPanel);
            app.Flowchart.Position = [2 1 295 573];
            app.Flowchart.ImageSource = fullfile(pathToMLAPP, 'Compressor off-design App flowchart_ - visual selection.png');

            % Create Image
            app.Image = uiimage(app.InstructionsPanel);
            app.Image.Position = [296 -2 594 573];
            app.Image.ImageSource = fullfile(pathToMLAPP, 'Untitled design.svg');

            % Create ForRotorStatoronlyremove_1fromthenamingofthevariablesLabel
            app.ForRotorStatoronlyremove_1fromthenamingofthevariablesLabel = uilabel(app.InstructionsPanel);
            app.ForRotorStatoronlyremove_1fromthenamingofthevariablesLabel.BackgroundColor = [0.851 0.3255 0.098];
            app.ForRotorStatoronlyremove_1fromthenamingofthevariablesLabel.FontSize = 14;
            app.ForRotorStatoronlyremove_1fromthenamingofthevariablesLabel.Position = [586 417 452 120];
            app.ForRotorStatoronlyremove_1fromthenamingofthevariablesLabel.Text = {'*Notes*'; '1-For Rotor-Stator only! remove "_1" from the naming of the variables'; '2- enter number of your compressor stage as: '; '        --> for rotor-stator:stage is a combination of a rotor and a stator'; '        --> for rotor-rotor: stage is one rotor only'};

            % Create ResetButton
            app.ResetButton = uibutton(app.UIFigure, 'push');
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
            app.ResetButton.FontSize = 18;
            app.ResetButton.Position = [259 350 126 33];
            app.ResetButton.Text = 'Reset';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Compressor_offdesign_app(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end