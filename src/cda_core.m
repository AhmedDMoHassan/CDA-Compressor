classdef cda_core
    % CDA_CORE  Mean-line design of axial compressors (rotor-stator, rotor-rotor on one
    % shaft, rotor-rotor on two shafts) for any number of stages or rotors.
    %
    % Used by Compressor_design_app; every function also works from the command line:
    %   o = cda_core.defaults('RS');  o.n = 3;
    %   S = cda_core.sweep(o);                          % design space (phi, psi, R [, ratio])
    %   k = cda_core.select(S, o, 'max_eta', struct()); % best point for a criterion
    %   D = cda_core.design(o, S.point(k));             % full design of that point
    %   mat = cda_core.offdesign_struct(D);             % variables of the off-design app
    %
    % Method (generalised from research1-3 and design_point1-3):
    %   * stage 1 from the flow coefficient phi = Cx/U, loading psi = dh0/U^2 and
    %     reaction R; the rotor-1 relative inlet Mach number Mr1 fixes the velocities,
    %     the shaft speed N the mean radius (constant mean radius, constant Cx in a stage)
    %   * rotor-stator: repeating stages (same phi, psi, R) unless a stage is overridden;
    %     the stator of stage k returns the flow to the inlet angle of stage k+1
    %   * rotor-rotor: every rotor adds psi*U of swirl in its own frame; on two shafts the
    %     odd rotors turn at U, the even rotors at ratio*U (counter-rotating: -ratio*U)
    %   * solidity from the diffusion factor (Lieblein), profile loss
    %     omega = (y/c)(DF) * 2 sigma / cos(exit angle), y/c linear or polynomial
    %   * blade metal angles from the NACA-65 incidence and Carter deviation charts
    %     (valid for 0.5 <= sigma <= 2)
    %   * annulus areas from continuity A = m R T / (p Cx) at every station

    methods (Static)

        % =============================== inputs ===============================
        function o = defaults(config)
            if nargin < 1, config = 'RS'; end
            o = struct();
            o.config = config;            % 'RS' | 'RR-S' | 'RR-D'
            o.n = 2;                      % stages (RS) or rotors (RR)
            o.last_stator = true;         % RS: last stator present
            o.last_exit = 'repeat';       % RS: last stator exit angle 'repeat' (= stage inlet angle) | 'axial'
            o.rotation = 'same';          % RR-D: 'same' | 'counter'
            o.ratio_U = 1.0;              % RR-D: |U even rotors| / U odd rotors (design point)
            o.gamma = 1.4; o.Rg = 287;
            o.Tt1 = 288; o.Pt1 = 1e5;     % inlet stagnation state [K, Pa]
            o.m_dot = 0.5;                % [kg/s]
            o.N_rpm = 110e3;              % shaft speed of rotor 1 [rpm]
            o.Mr1 = 0.75;                 % rotor-1 relative inlet Mach number
            o.DF = 0.45;                  % diffusion factor of the rotors
            o.DF_S = 0.45;                % diffusion factor of the stators
            o.chord = 0.01;               % blade chord [m]
            o.C1_solver = 'exact';        % inlet velocity: 'exact' (closed form, research1-3) | 'fsolve' (as design_point1-3)
            if strcmp(config, 'RR-S'), o.loss_R = 'quartic'; else, o.loss_R = 'linear'; end
            o.loss_S = 'linear';          % 'linear' | 'poly6'
            o.phi_vec = 0.40:0.01:1.20;   % sweep ranges
            o.psi_vec = 0.20:0.01:0.50;
            o.R_vec = 0.50:0.01:0.75;
            o.ratio_vec = 0.80:0.05:1.70; % RR-D only
            o.lim = struct('sigma', [0.5 2], 'M_max', 0.75, 'dH_min', 0, 'zeta', [0 1], 'h_c_min', 0, 'exit_swirl_max', 90);
            o.ov = struct('phi', [], 'psi', [], 'R', [], 'DF', []);   % per-stage / per-rotor overrides (NaN = repeat)
        end

        function y = loss_yc(model, DF)
            % Profile-loss parameter y/c (wake momentum thickness / chord) against DF
            switch model
                case 'linear',  y = 0.08*DF - 8e-3;                                     % rotor, DF 0.4-0.6
                case 'quartic', y = 0.1447493264*DF.^4 - 0.2682061239*DF.^3 + 0.2228839917*DF.^2 - 0.01455315662*DF + 8e-3;
                case 'stator_linear', y = 0.06*DF - 4e-3;                                % stator, DF 0.4-0.5
                case 'poly6', y = 14.1065*DF.^6 - 23.4385*DF.^5 + 15.0696*DF.^4 - 4.6918*DF.^3 + 0.7752*DF.^2 - 0.0383*DF + 8e-3;
                otherwise, error('Unknown loss model "%s".', model);
            end
        end

        function rows = row_list(o)
            % Blade rows in flow order: kind 'R'/'S', stage index, rotor index
            rows = struct('kind', {}, 'stage', {}, 'name', {});
            switch o.config
                case 'RS'
                    for k = 1:o.n
                        rows(end+1) = struct('kind', 'R', 'stage', k, 'name', sprintf('Rotor %d', k));
                        if k < o.n || o.last_stator
                            rows(end+1) = struct('kind', 'S', 'stage', k, 'name', sprintf('Stator %d', k));
                        end
                    end
                otherwise
                    for k = 1:o.n
                        rows(end+1) = struct('kind', 'R', 'stage', k, 'name', sprintf('Rotor %d', k));
                    end
            end
        end

        function v = ovr(o, field, k, default)
            % Override value of stage/rotor k (default when not set or NaN)
            v = default;
            if isfield(o, 'ov') && isfield(o.ov, field)
                x = o.ov.(field);
                if numel(x) >= k && ~isnan(x(k)), v = x(k) + 0*default; end
            end
        end

        % =============================== stage march ===============================
        function S = march(o, phi, psi, R, ratio)
            % Mean-line march through all rows for column vectors phi, psi, R (and ratio
            % for RR-D). Returns overall and per-row / per-station results.
            g = o.gamma; Rg = o.Rg; cp = g*Rg/(g - 1); ex = g/(g - 1);
            phi = phi(:); psi = psi(:); R = R(:);
            if nargin < 5 || isempty(ratio), ratio = o.ratio_U + 0*phi; end
            ratio = ratio(:) + 0*phi;
            rows = cda_core.row_list(o); nr = numel(rows); np = numel(phi);
            % ---- stage 1 velocity triangles
            a1 = atand((1 - R - psi/2)./phi);
            b1 = atand((R + psi/2)./phi);
            Arat = (cosd(a1)./cosd(b1)).^2;
            C1 = sqrt(o.Mr1^2*g*Rg*o.Tt1./(Arat + o.Mr1^2*g*Rg/(2*cp)));   % from the rotor-1 relative Mach number
            if isfield(o, 'C1_solver') && strcmp(o.C1_solver, 'fsolve')
                % same call as design_point1-3 (fsolve from 100 m/s, default tolerances): reproduces their files
                try
                    fo = optimset('Display', 'off');
                    for i = 1:np
                        C1(i) = fsolve(@(x) x*cosd(a1(i))/cosd(b1(i))/sqrt(g*Rg*(o.Tt1 - x^2/2/cp)) - o.Mr1, 100, fo);
                    end
                catch err
                    C1 = sqrt(o.Mr1^2*g*Rg*o.Tt1./(Arat + o.Mr1^2*g*Rg/(2*cp)));
                    warning('cda_core:fsolve', 'fsolve failed (%s): the exact inlet velocity is used.', err.message);
                end
            end
            Cx = C1.*cosd(a1);
            U = Cx./phi;
            r_m = 60*U/(2*pi*o.N_rpm);
            T = o.Tt1 - C1.^2/(2*cp); Tt = o.Tt1 + 0*phi; Pt = o.Pt1 + 0*phi;
            P = o.Pt1*(T/o.Tt1).^ex;
            Ct = Cx.*tand(a1);
            % ---- outputs
            Z = nan(np, nr);
            S = struct('rows', rows, 'phi', phi, 'psi', psi, 'R', R, 'ratio', ratio, 'U', U, 'r_m', r_m, 'Cx1', Cx, ...
                       'alpha1', a1, 'C1', C1, 'b_in', Z, 'b_out', Z, 'V_in', Z, 'V_out', Z, 'M_in', Z, 'M_out', Z, ...
                       'sigma', Z, 'omega', Z, 'DF', Z, 'dH', Z, 'defl', Z, 'Urow', Z, 'Ct_out', Z, 'Pt_out', Z, 'Tt_out', Z);
            st.T = T; st.P = P; st.Cx = Cx;            % station list (inlet first)
            stT = T; stP = P; stCx = Cx; stCt = Ct;
            yR = o.loss_R; yS = o.loss_S; if strcmp(yS, 'linear'), yS = 'stator_linear'; end
            for q = 1:nr
                rw = rows(q); k = rw.stage;
                if rw.kind == 'R'
                    % --- rotor of stage k (RS) / rotor k (RR)
                    switch o.config
                        case 'RS'
                            Ur = U; sgn = 1 + 0*U;
                            psik = cda_core.ovr(o, 'psi', k, psi);
                        case 'RR-S'
                            Ur = U; sgn = 1 + 0*U;
                            psik = cda_core.ovr(o, 'psi', k, psi);
                        case 'RR-D'
                            if mod(k, 2) == 1
                                Ur = U; sgn = 1 + 0*U;
                            else
                                Ur = ratio.*U;
                                if strcmp(o.rotation, 'counter'), sgn = -1 + 0*U; else, sgn = 1 + 0*U; end
                            end
                            psik = cda_core.ovr(o, 'psi', k, psi);
                    end
                    DFk = cda_core.ovr(o, 'DF', q, o.DF + 0*U);
                    Ctr = sgn.*Ct;                          % swirl in the rotor's own frame
                    Wt1 = Ur - Ctr; bi = atand(Wt1./Cx); W1 = Cx./cosd(bi);
                    Ctr2 = Ctr + psik.*Ur;
                    Wt2 = Ur - Ctr2; bo = atand(Wt2./Cx); W2 = Cx./cosd(bo);
                    sig = (Wt1 - Wt2)./(2*W1.*(DFk - 1 + W2./W1));
                    om = cda_core.loss_yc(yR, DFk)*2.*sig./cosd(bo);
                    Ttr = T + W1.^2/(2*cp); Ptr = P.*(Ttr./T).^ex;
                    Ptr2 = Ptr - om.*(Ptr - P);
                    T2 = Ttr - W2.^2/(2*cp);
                    Ct2 = sgn.*Ctr2; C2 = sqrt(Cx.^2 + Ct2.^2);
                    Tt2 = T2 + C2.^2/(2*cp);
                    P2 = Ptr2.*(T2./Ttr).^ex; Pt2 = Ptr2.*(Tt2./Ttr).^ex;
                    S.b_in(:, q) = bi; S.b_out(:, q) = bo; S.V_in(:, q) = W1; S.V_out(:, q) = W2;
                    S.M_in(:, q) = W1./sqrt(g*Rg*T); S.M_out(:, q) = W2./sqrt(g*Rg*T2);
                    S.sigma(:, q) = sig; S.omega(:, q) = om; S.DF(:, q) = DFk; S.dH(:, q) = W2./W1;
                    S.defl(:, q) = bi - bo; S.Urow(:, q) = sgn.*Ur;
                    T = T2; P = P2; Tt = Tt2; Pt = Pt2; Ct = Ct2;
                else
                    % --- stator of stage k (RS only): returns the flow to the inlet angle of stage k+1
                    if k < o.n
                        phin = cda_core.ovr(o, 'phi', k + 1, phi); psin = cda_core.ovr(o, 'psi', k + 1, psi);
                        Rn = cda_core.ovr(o, 'R', k + 1, R);
                    else
                        phin = cda_core.ovr(o, 'phi', k, phi); psin = cda_core.ovr(o, 'psi', k, psi);
                        Rn = cda_core.ovr(o, 'R', k, R);
                    end
                    if k == o.n && strcmp(o.last_exit, 'axial')
                        ao = 0*phin;
                    else
                        ao = atand((1 - Rn - psin/2)./phin);
                    end
                    Cxo = phin.*U;
                    DFk = cda_core.ovr(o, 'DF', q, o.DF_S + 0*U);
                    ai = atand(Ct./Cx); Ci = Cx./cosd(ai);
                    Co = Cxo./cosd(ao);
                    sig = (Ci.*sind(ai) - Co.*sind(ao))./(2*Ci.*(DFk - 1 + Co./Ci));
                    om = cda_core.loss_yc(yS, DFk)*2.*sig./cosd(ao);
                    Pt2 = Pt - om.*(Pt - P); Tt2 = Tt;
                    T2 = Tt2 - Co.^2/(2*cp); P2 = Pt2.*(T2./Tt2).^ex;
                    S.b_in(:, q) = ai; S.b_out(:, q) = ao; S.V_in(:, q) = Ci; S.V_out(:, q) = Co;
                    S.M_in(:, q) = Ci./sqrt(g*Rg*T); S.M_out(:, q) = Co./sqrt(g*Rg*T2);
                    S.sigma(:, q) = sig; S.omega(:, q) = om; S.DF(:, q) = DFk; S.dH(:, q) = Co./Ci;
                    S.defl(:, q) = ai - ao; S.Urow(:, q) = 0;
                    T = T2; P = P2; Tt = Tt2; Pt = Pt2; Cx = Cxo; Ct = Cxo.*tand(ao);
                end
                S.Ct_out(:, q) = Ct; S.Pt_out(:, q) = Pt; S.Tt_out(:, q) = Tt;
                stT(:, end+1) = T; stP(:, end+1) = P; stCx(:, end+1) = Cx; stCt(:, end+1) = Ct;
            end
            S.PR = Pt/o.Pt1; S.TR = Tt/o.Tt1;
            S.eta = (S.PR.^((g - 1)/g) - 1)./(S.TR - 1);
            S.work = cp*(Tt - o.Tt1); S.power = o.m_dot*S.work;
            S.T_st = stT; S.P_st = stP; S.Cx_st = stCx; S.Ct_st = stCt;
            S.A = o.m_dot*Rg*stT./(stP.*stCx);                       % continuity at every station
            S.zeta = (4*pi*r_m.^2 - S.A)./(4*pi*r_m.^2 + S.A);        % hub/tip ratio
            S.r_t = 2*r_m./(1 + S.zeta); S.r_h = S.zeta.*S.r_t;
            S.h = S.r_t - S.r_h; S.h_c = S.h/o.chord;
            S.A_per_m = S.A(:, 1)/o.m_dot;
            S.exit_swirl = atand(Ct./Cx);
        end

        function S = summaries(S)
            % Per-point extremes over the rows / stations used by the feasibility check
            % (NaN propagates where a NaN must fail the check)
            mn = @(x) cda_core.nanmin_p(x); mx = @(x) -cda_core.nanmin_p(-x);
            S.sigma_min = mn(S.sigma); S.sigma_max = mx(S.sigma);
            S.M_max = mx(S.M_in);
            S.zeta_min = mn(S.zeta); S.zeta_max = mx(S.zeta);
            S.dH_min = min(S.dH, [], 2);                 % NaN ignored, as in any(dH < limit)
            S.defl_min = mn(S.defl);
            S.h_c_min = min(S.h_c, [], 2);
        end

        function m = nanmin_p(x)
            m = min(x, [], 2); m(any(isnan(x), 2)) = NaN;
        end

        function [ok, code] = feasibility(S, o)
            % Feasible design points and the reason code of the others (bit mask):
            %   1 efficiency or pressure ratio not physical   2 solidity outside the chart range
            %   4 inlet Mach number above the limit             8 hub/tip ratio outside the limits
            %  16 de Haller ratio below the limit              32 a row does not turn the flow
            %  64 blade height / chord below the limit        128 exit swirl above the limit
            % Works on a march result or on a sweep (uses the per-point extremes only), so the
            % limits can be changed without recomputing the design space.
            if ~isfield(S, 'sigma_min'), S = cda_core.summaries(S); end
            L = o.lim; tol = 1e-9;
            code = zeros(size(S.PR));
            code = code + 1*~(isfinite(S.eta) & S.eta > 0 & S.eta < 1 & S.PR > 1);
            code = code + 2*~(S.sigma_min >= L.sigma(1) - tol & S.sigma_max <= L.sigma(2) + tol);
            code = code + 4*~(S.M_max <= L.M_max + 5e-4);         % tolerance: values shown as the limit pass (iterative C1 overshoots by ~3e-5)
            code = code + 8*~(S.zeta_min > max(L.zeta(1), 0) & S.zeta_max < min(L.zeta(2), 1));
            code = code + 16*(S.dH_min < L.dH_min - tol);
            code = code + 32*~(S.defl_min > 0);
            code = code + 64*(S.h_c_min < L.h_c_min - tol);
            code = code + 128*(abs(S.exit_swirl) > L.exit_swirl_max + tol);
            ok = code == 0;
        end

        function txt = reason_text(code)
            names = {'efficiency / pressure ratio not physical', 'solidity outside 0.5-2 (NACA-65 charts)', ...
                     'inlet Mach number above the limit', 'hub/tip ratio outside the limits', 'de Haller ratio below the limit', ...
                     'a row does not turn the flow', 'blade height/chord below the limit', 'exit swirl above the limit'};
            txt = {};
            for b = 0:7
                if bitand(code, 2^b), txt{end+1} = names{b + 1}; end %#ok<AGROW>
            end
            if isempty(txt), txt = {'feasible'}; end
        end

        % =============================== design space ===============================
        function S = sweep(o, progress)
            % Every combination of psi, R, phi (and ratio for RR-D), marched in chunks.
            % Kept per point: overall results and the extremes used by the limits; kept per
            % row (single precision, for the maps): solidity, inlet Mach number, de Haller.
            % progress (optional): function handle called with the fraction done.
            if nargin < 2, progress = []; end
            if strcmp(o.config, 'RR-D'), rv = o.ratio_vec; else, rv = o.ratio_U; end
            o.C1_solver = 'exact';                       % closed form in the sweep (as research1-3)
            [PS, RR, PH, RA] = ndgrid(o.psi_vec, o.R_vec, o.phi_vec, rv);
            np = numel(PS); rows = cda_core.row_list(o); nr = numel(rows);
            keep = {'phi', 'psi', 'R', 'ratio', 'PR', 'TR', 'eta', 'U', 'r_m', 'Cx1', 'alpha1', 'A_per_m', 'exit_swirl', 'work', ...
                    'sigma_min', 'sigma_max', 'M_max', 'zeta_min', 'zeta_max', 'dH_min', 'defl_min', 'h_c_min'};
            rowk = {'sigma', 'M_in', 'dH'};
            S = struct('rows', rows);
            for f = keep, S.(f{1}) = nan(np, 1); end
            for f = rowk, S.(f{1}) = nan(np, nr, 'single'); end
            S.zeta_in = nan(np, 1); S.zeta_out = nan(np, 1);
            chunk = max(1, floor(4e6/max(1, 3*nr + 12)));   % about 4e6 numbers per chunk
            for i0 = 1:chunk:np
                j = i0:min(np, i0 + chunk - 1);
                T = cda_core.summaries(cda_core.march(o, PH(j)', PS(j)', RR(j)', RA(j)'));
                for f = keep, S.(f{1})(j) = T.(f{1}); end
                for f = rowk, S.(f{1})(j, :) = single(T.(f{1})); end
                S.zeta_in(j) = T.zeta(:, 1); S.zeta_out(j) = T.zeta(:, end);
                if ~isempty(progress), progress(j(end)/np); end
            end
            S.grid = size(PS); if numel(S.grid) < 4, S.grid(end+1:4) = 1; end
            S.axes = struct('psi', o.psi_vec, 'R', o.R_vec, 'phi', o.phi_vec, 'ratio', rv);
            [S.ok, S.code] = cda_core.feasibility(S, o);
            S.opts = o;
        end

        function P = point(S, k)
            % Design-point parameters of sweep entry k
            P = struct('phi', S.phi(k), 'psi', S.psi(k), 'R', S.R(k), 'ratio', S.ratio(k));
        end

        function [k, info] = select(S, o, objective, c)
            % Best feasible point for an objective under constraints c (see rank)
            [k, info] = cda_core.rank(S, objective, c, 1);
        end

        function [idx, info, score] = rank(S, objective, c, ntop)
            % Feasible points ordered by an objective, best first (at most ntop).
            % objective: 'max_PR' | 'max_eta' | 'min_A' | 'max_PR_per_A' | 'weighted'
            % c (fields optional): PR_min, eta_min, Aperm_max, R_fix, ratio_fix, w (weight of PR)
            if nargin < 4, ntop = Inf; end
            m = S.ok;
            if isfield(c, 'PR_min') && ~isempty(c.PR_min), m = m & S.PR >= c.PR_min; end
            if isfield(c, 'eta_min') && ~isempty(c.eta_min), m = m & S.eta >= c.eta_min; end
            if isfield(c, 'Aperm_max') && ~isempty(c.Aperm_max), m = m & S.A_per_m <= c.Aperm_max; end
            if isfield(c, 'R_fix') && ~isempty(c.R_fix), m = m & abs(S.R - c.R_fix) < 1e-9; end
            if isfield(c, 'ratio_fix') && ~isempty(c.ratio_fix), m = m & abs(S.ratio - c.ratio_fix) < 1e-9; end
            info = struct('n_candidates', nnz(m));
            idx = find(m); score = [];
            if isempty(idx), idx = []; return; end
            switch objective
                case 'max_PR',  sc = S.PR(idx);
                case 'max_eta', sc = S.eta(idx);
                case 'min_A',   sc = -S.A_per_m(idx);
                case 'max_PR_per_A', sc = (S.PR(idx) - 1)./S.A_per_m(idx);
                case 'weighted'
                    w = 0.5; if isfield(c, 'w') && ~isempty(c.w), w = c.w; end
                    pn = (S.PR(idx) - min(S.PR(idx)))/max(eps, max(S.PR(idx)) - min(S.PR(idx)));
                    en = (S.eta(idx) - min(S.eta(idx)))/max(eps, max(S.eta(idx)) - min(S.eta(idx)));
                    sc = w*pn + (1 - w)*en;
                otherwise, error('Unknown objective "%s".', objective);
            end
            [sc, o] = sort(sc, 'descend');            % stable: ties keep the grid order
            n = min(ntop, numel(o));
            idx = idx(o(1:n)); score = sc(1:n);
        end

        function f = pareto(PR, eta, mask)
            % Indices of the PR-eta Pareto front of the points in mask (both maximised)
            idx = find(mask(:));
            [~, o] = sort(PR(idx), 'descend');
            idx = idx(o); e = eta(idx); e = e(:);
            if isempty(e), f = []; return; end
            prev = [-Inf; cummax(e(1:end-1))];
            f = idx(e > prev + 1e-12)';
        end

        % =============================== blade geometry ===============================
        function G = naca65_carter(b_in, b_out, sigma)
            % Metal angles of a NACA-65 row from the incidence charts (i0, n) and Carter's
            % deviation rule (delta = m*theta/sqrt(sigma)), as in design_point1-3.
            x = b_in; y = b_out;
            n1 = -1.005e-6*x.^3 + 6.758e-5*x.^2 - 0.006038*x - 0.01398;      % sigma = 0.5
            n2 = -1.198e-6*x.^3 + 8.017e-5*x.^2 - 0.004556*x - 0.002289;     % sigma = 1
            n3 = -7.272e-7*x.^3 + 1.557e-5*x.^2 - 0.0009442*x - 0.01721;     % sigma = 1.5
            n4 = -6.931e-7*x.^3 + 1.234e-5*x.^2 - 0.000144*x - 0.006293;     % sigma = 2
            i04 = -4.963e-8*x.^5 + 1.002e-5*x.^4 - 0.0007843*x.^3 + 0.02947*x.^2 - 0.372*x + 3.529;
            i03 = -1.345e-5*x.^3 + 0.001251*x.^2 + 0.08313*x + 0.1545;
            i02 = -7.237e-6*x.^3 + 0.0008285*x.^2 + 0.04552*x + 0.3192;
            i01 = -4.399e-6*x.^3 + 0.0005018*x.^2 + 0.01771*x + 0.1913;
            m = -2.436e-7*y.^3 + 4.44e-5*y.^2 + 0.0006728*y + 0.2147;
            s = min(max(sigma, 0.5), 2);                % charts: 0.5 <= sigma <= 2
            nn = n1 + (n2 - n1).*(s - 0.5)/0.5;  i0 = i01 + (i02 - i01).*(s - 0.5)/0.5;
            j = s > 1;    nn(j) = n2(j) + (n3(j) - n2(j)).*(s(j) - 1)/0.5;   i0(j) = i02(j) + (i03(j) - i02(j)).*(s(j) - 1)/0.5;
            j = s > 1.5;  nn(j) = n3(j) + (n4(j) - n3(j)).*(s(j) - 1.5)/0.5; i0(j) = i03(j) + (i04(j) - i03(j)).*(s(j) - 1.5)/0.5;
            a = 1 + nn; b = -nn; c = m./sqrt(sigma); d = 1 - m./sqrt(sigma);
            B1 = x - i0; B2 = y;
            det = a.*d - b.*c;
            G.b1d = (d.*B1 - b.*B2)./det;               % inlet metal angle
            G.b2d = (a.*B2 - c.*B1)./det;               % exit metal angle
            G.inc = x - G.b1d; G.dev = y - G.b2d;
            G.camber = G.b1d - G.b2d; G.stagger = (G.b1d + G.b2d)/2;
            G.i0 = i0; G.n = nn; G.m = m;
            G.in_chart = sigma >= 0.5 - 1e-9 & sigma <= 2 + 1e-9;
        end

        % =============================== one design ===============================
        function D = design(o, P)
            % Full design of point P (struct phi, psi, R, ratio) with the overrides in o.ov
            if ~isfield(P, 'ratio') || isempty(P.ratio), P.ratio = o.ratio_U; end
            o.ratio_U = P.ratio;
            S = cda_core.march(o, P.phi, P.psi, P.R, P.ratio);
            S = cda_core.summaries(S);
            [ok, code] = cda_core.feasibility(S, o);
            nr = numel(S.rows);
            G = cda_core.naca65_carter(S.b_in, S.b_out, S.sigma);
            D = struct('opts', o, 'point', P, 'S', S, 'G', G, 'ok', ok, 'code', code);
            D.N_rpm_rows = 60*S.Urow/(2*pi*S.r_m);
            D.n_blades = ceil(2*pi*S.r_m.*S.sigma/o.chord);
            % warnings in plain words
            W = {};
            for q = 1:nr
                nm = S.rows(q).name;
                if ~G.in_chart(q), W{end+1} = sprintf('%s: solidity %.2f outside the NACA-65/Carter charts (0.5-2); metal angles extrapolated.', nm, S.sigma(q)); end %#ok<AGROW>
                if S.M_in(q) > o.lim.M_max + 5e-4, W{end+1} = sprintf('%s: inlet Mach number %.4f above the limit %.3g.', nm, S.M_in(q), o.lim.M_max); end %#ok<AGROW>
                if S.dH(q) < 0.72, W{end+1} = sprintf('%s: de Haller ratio %.3f below 0.72 (high diffusion).', nm, S.dH(q)); end %#ok<AGROW>
                if S.b_in(q) < 0 || S.b_in(q) > 70, W{end+1} = sprintf('%s: inlet flow angle %.1f deg outside the chart range 0-70 deg.', nm, S.b_in(q)); end %#ok<AGROW>
            end
            if any(S.zeta <= 0 | S.zeta >= 1), W{end+1} = 'Hub/tip ratio outside 0-1 at some station: the annulus does not fit the mean radius.'; end
            if any(S.zeta < 0.4), W{end+1} = sprintf('Lowest hub/tip ratio %.2f: long blades, mean-line assumption weak.', min(S.zeta)); end
            if any(S.h_c < 1), W{end+1} = sprintf('Lowest blade aspect ratio h/c = %.3f (< 1).', min(S.h_c)); end
            D.warnings = W;
            D.reasons = cda_core.reason_text(code);
        end

        function v = compact(x)
            % one value when all rows of a group are equal (repeating stages), else a row vector
            x = x(:)';
            if isempty(x), v = x; return; end
            if all(abs(x - x(1)) <= 1e-12*max(1, abs(x(1)))), v = x(1); else, v = x; end
        end

        function mat = offdesign_struct(D, keep)
            % Variables of the off-design app (Compressor_offdesign_app) for design D.
            % keep (optional): cell array of the variable names to write (default: all);
            % keep = true: the legacy set of cda_core.legacy_vars (no stator blading,
            % inlet state or design record).
            if nargin < 2, keep = {}; end
            if islogical(keep) && isscalar(keep)
                if keep, keep = cda_core.legacy_vars(D.opts.config); else, keep = {}; end
            end
            o = D.opts; S = D.S; G = D.G; rows = S.rows;
            isR = [rows.kind] == 'R'; isS = ~isR;
            mat = struct();
            mat.alpha1 = S.alpha1;
            mat.m_dot = o.m_dot;
            mat.A_vec = S.A;
            mat.n_stages = o.n;
            mat.chord = o.chord;
            mat.Tt1 = o.Tt1; mat.Pt1 = o.Pt1;
            C = @cda_core.compact;
            switch o.config
                case 'RS'
                    r = find(isR); s = find(isS);
                    mat.beta1_dash = C(G.b1d(r)); mat.beta2_dash = C(G.b2d(r));
                    mat.incidence = C(G.inc(r)); mat.deviation = C(G.dev(r)); mat.deflection = C(S.defl(r));
                    mat.w_loss_rotor = C(S.omega(r));
                    mat.U = S.U;
                    mat.sigma_rotor = C(S.sigma(r));
                    if ~isempty(s)
                        mat.w_loss_stator = C(S.omega(s));
                        mat.sigma_stator = C(S.sigma(s));
                        mat.stator_beta_in = C(G.b1d(s)); mat.stator_beta_out = C(G.b2d(s));
                        mat.stator_incidence = C(G.inc(s)); mat.stator_deviation = C(G.dev(s));
                        mat.stator_deflection = C(S.defl(s));
                    else
                        mat.w_loss_stator = mat.w_loss_rotor;          % required by the off-design app, unused
                    end
                otherwise
                    r1 = 1:2:o.n; r2 = 2:2:o.n;
                    if isempty(r2), r2 = r1; end                        % one rotor: the rotor-2 inputs repeat rotor 1 (unused)
                    mat.beta1_dash = C(G.b1d(r1)); mat.beta2_dash = C(G.b2d(r1));
                    mat.beta3_dash = C(G.b1d(r2)); mat.beta4_dash = C(G.b2d(r2));
                    mat.incidence_1 = C(G.inc(r1)); mat.incidence_2 = C(G.inc(r2));
                    mat.deviation_1 = C(G.dev(r1)); mat.deviation_2 = C(G.dev(r2));
                    mat.deflection_1 = C(S.defl(r1)); mat.deflection_2 = C(S.defl(r2));
                    mat.w_loss_rotor = C(S.omega(r1)); mat.w_loss_rotor2 = C(S.omega(r2));
                    mat.sigma_1 = C(S.sigma(r1)); mat.sigma_2 = C(S.sigma(r2));
                    if strcmp(o.config, 'RR-S')
                        mat.U = S.U;
                    else
                        mat.U1 = S.U; mat.U2 = C(S.Urow(r2));           % negative when counter-rotating
                    end
            end
            P = D.point;
            mat.design_info = struct('config', o.config, 'n', o.n, 'phi', P.phi, 'psi', P.psi, 'R', P.R, 'ratio', P.ratio, ...
                'PR', S.PR, 'eta', S.eta, 'N_rpm', o.N_rpm, 'r_m', S.r_m, 'DF', o.DF, 'DF_S', o.DF_S, 'Mr1', o.Mr1, ...
                'loss_R', o.loss_R, 'loss_S', o.loss_S, 'rotation', o.rotation, 'last_stator', o.last_stator, ...
                'tool', 'Compressor_design_app', 'created', datestr(now));
            mat.case_name = cda_core.case_name(o, P);
            if ~isempty(keep)
                f = fieldnames(mat); mat = rmfield(mat, f(~ismember(f, keep)));
            end
        end

        function keep = legacy_vars(config)
            % variable set of the earlier stand-alone design scripts (no stator blading,
            % inlet state, design record or case name)
            switch config
                case 'RS', keep = {'alpha1', 'n_stages', 'A_vec', 'beta1_dash', 'beta2_dash', 'deviation', 'incidence', 'deflection', ...
                                   'm_dot', 'U', 'w_loss_rotor', 'w_loss_stator', 'sigma_rotor', 'sigma_stator', 'chord'};
                case 'RR-S', keep = {'alpha1', 'A_vec', 'beta1_dash', 'beta2_dash', 'beta3_dash', 'beta4_dash', 'deviation_1', 'deviation_2', ...
                                   'incidence_1', 'incidence_2', 'deflection_1', 'deflection_2', 'm_dot', 'n_stages', 'w_loss_rotor', ...
                                   'w_loss_rotor2', 'U', 'sigma_1', 'sigma_2', 'chord'};
                otherwise, keep = {'alpha1', 'n_stages', 'A_vec', 'beta1_dash', 'beta2_dash', 'beta3_dash', 'beta4_dash', 'deviation_1', ...
                                   'deviation_2', 'incidence_1', 'incidence_2', 'deflection_1', 'deflection_2', 'm_dot', 'w_loss_rotor', ...
                                   'w_loss_rotor2', 'U1', 'U2', 'sigma_1', 'sigma_2', 'chord'};
            end
        end

        function T = var_catalog(config)
            % {name, meaning, role} of every variable a design file can hold, in display order.
            % role: 'required' (the off-design app refuses the file without it) or the optional
            % feature it enables.
            rs = strcmp(config, 'RS');
            if rs, rr = 'Rotor'; else, rr = 'Odd rotors (1, 3, ...)'; end
            T = {'alpha1', 'Inlet absolute flow angle [deg]', 'required';
                 'm_dot', 'Design mass flow [kg/s]', 'required';
                 'n_stages', 'Number of stages (rotor-stator) or rotors', 'required';
                 'A_vec', 'Annulus area at every station, inlet first [m^2]', 'required';
                 'beta1_dash', [rr ': inlet metal angle [deg]'], 'required';
                 'beta2_dash', [rr ': exit metal angle [deg]'], 'required';
                 'incidence', 'Rotor: design incidence [deg]', 'required';
                 'deviation', 'Rotor: design deviation [deg]', 'required';
                 'deflection', 'Rotor: flow deflection (turning) [deg]', 'required';
                 'beta3_dash', 'Even rotors (2, 4, ...): inlet metal angle [deg]', 'required';
                 'beta4_dash', 'Even rotors: exit metal angle [deg]', 'required';
                 'incidence_1', 'Odd rotors: design incidence [deg]', 'required';
                 'incidence_2', 'Even rotors: design incidence [deg]', 'required';
                 'deviation_1', 'Odd rotors: design deviation [deg]', 'required';
                 'deviation_2', 'Even rotors: design deviation [deg]', 'required';
                 'deflection_1', 'Odd rotors: flow deflection [deg]', 'required';
                 'deflection_2', 'Even rotors: flow deflection [deg]', 'required';
                 'w_loss_rotor', [rr ': design loss coefficient'], 'required';
                 'w_loss_rotor2', 'Even rotors: design loss coefficient', 'required';
                 'w_loss_stator', 'Stator: design loss coefficient', 'required';
                 'U', 'Blade speed at the mean radius [m/s]', 'required';
                 'U1', 'Shaft 1 (odd rotors): blade speed [m/s]', 'required';
                 'U2', 'Shaft 2 (even rotors): blade speed [m/s]; negative = counter-rotating', 'required';
                 'sigma_rotor', 'Rotor solidity', 'optional: Koch stall check';
                 'sigma_stator', 'Stator solidity', 'optional: Koch stall check';
                 'sigma_1', 'Odd rotors: solidity', 'optional: Koch stall check';
                 'sigma_2', 'Even rotors: solidity', 'optional: Koch stall check';
                 'chord', 'Blade chord [m]', 'optional: Koch stall check';
                 'stator_beta_in', 'Stator: inlet metal angle [deg]', 'optional: stator blading';
                 'stator_beta_out', 'Stator: exit metal angle [deg]', 'optional: stator blading';
                 'stator_incidence', 'Stator: design incidence [deg]', 'optional: stator blading';
                 'stator_deviation', 'Stator: design deviation [deg]', 'optional: stator blading';
                 'stator_deflection', 'Stator: flow deflection [deg]', 'optional: stator blading';
                 'Tt1', 'Inlet stagnation temperature [K]', 'optional: inlet state';
                 'Pt1', 'Inlet stagnation pressure [Pa]', 'optional: inlet state';
                 'design_info', 'Design record: point, PR, efficiency, inputs, date', 'optional: record';
                 'case_name', 'Name of the case (reports and file names)', 'optional: record'};
        end

        function nm = case_name(o, P)
            switch o.config
                case 'RS'
                    if o.last_stator, t = 'rs'; else, t = 'rs_no_last_stator'; end
                case 'RR-S', t = 'rr_same_shaft';
                otherwise
                    if strcmp(o.rotation, 'counter'), t = 'rr_counter_rotating'; else, t = 'rr_diff_shaft'; end
            end
            nm = sprintf('%s_%dst_phi%.2f_psi%.2f_R%.2f', t, o.n, P.phi, P.psi, P.R);
            if strcmp(o.config, 'RR-D'), nm = sprintf('%s_ratio%.2f', nm, P.ratio); end
        end

        function typ = offdesign_type(o)
            switch o.config
                case 'RS', typ = 'Rotor-Stator';
                case 'RR-S', typ = 'Rotor-Rotor same shaft';
                otherwise, typ = 'Rotor-Rotor different shaft';
            end
        end

        % =============================== tables ===============================
        function [cols, data] = row_table(D)
            S = D.S; G = D.G; nr = numel(S.rows);
            cols = {'Row', 'U [m/s]', 'Inlet angle [deg]', 'Exit angle [deg]', 'Deflection [deg]', 'V in [m/s]', 'V out [m/s]', ...
                    'M in', 'M out', 'de Haller', 'DF', 'Solidity', 'Loss coeff.', 'Metal in [deg]', 'Metal out [deg]', ...
                    'Incidence [deg]', 'Deviation [deg]', 'Camber [deg]', 'Stagger [deg]', 'Blades'};
            data = cell(nr, numel(cols));
            for q = 1:nr
                data(q, :) = {S.rows(q).name, S.Urow(q), S.b_in(q), S.b_out(q), S.defl(q), S.V_in(q), S.V_out(q), ...
                    S.M_in(q), S.M_out(q), S.dH(q), S.DF(q), S.sigma(q), S.omega(q), G.b1d(q), G.b2d(q), G.inc(q), ...
                    G.dev(q), G.camber(q), G.stagger(q), D.n_blades(q)};
            end
        end

        function [cols, data] = station_table(D)
            S = D.S; ns = size(S.A, 2);
            cols = {'Station', 'After', 'T [K]', 'p [Pa]', 'Cx [m/s]', 'Area [m^2]', 'Hub/tip', 'r tip [mm]', 'r hub [mm]', 'h [mm]', 'h/c'};
            data = cell(ns, numel(cols));
            for j = 1:ns
                if j == 1, aft = 'inlet'; else, aft = S.rows(j - 1).name; end
                data(j, :) = {j, aft, S.T_st(j), S.P_st(j), S.Cx_st(j), S.A(j), S.zeta(j), 1e3*S.r_t(j), 1e3*S.r_h(j), 1e3*S.h(j), S.h_c(j)};
            end
        end

        function [cols, data] = summary_table(D)
            o = D.opts; S = D.S; P = D.point;
            cols = {'Quantity', 'Value', 'Unit'};
            data = {'Configuration', cda_core.offdesign_type(o), ''; 'Stages / rotors', o.n, '-'; ...
                'Flow coefficient phi', P.phi, '-'; 'Loading coefficient psi', P.psi, '-'; 'Degree of reaction R', P.R, '-'};
            if strcmp(o.config, 'RR-D')
                data(end+1, :) = {'Speed ratio U2/U1', P.ratio, '-'};
                data(end+1, :) = {'Rotation of the even rotors', o.rotation, ''};
            end
            data = [data; {'Pressure ratio', S.PR, '-'; 'Isentropic efficiency', S.eta, '-'; 'Temperature ratio', S.TR, '-'; ...
                'Specific work', S.work/1e3, 'kJ/kg'; 'Power', S.power/1e3, 'kW'; 'Mass flow', o.m_dot, 'kg/s'; ...
                'Shaft speed (rotor 1)', o.N_rpm, 'rpm'; 'Blade speed U (rotor 1)', S.U, 'm/s'; 'Mean radius', 1e3*S.r_m, 'mm'; ...
                'Axial velocity (stage 1)', S.Cx1, 'm/s'; 'Inlet flow angle alpha1', S.alpha1, 'deg'; 'Inlet area per unit flow A/m', S.A_per_m, 'm^2 s/kg'; ...
                'Inlet hub/tip ratio', S.zeta(1), '-'; 'Exit hub/tip ratio', S.zeta(end), '-'; 'Exit swirl angle', S.exit_swirl, 'deg'; ...
                'Total blades', sum(D.n_blades), '-'; 'Rotor DF / stator DF', sprintf('%.3f / %.3f', o.DF, o.DF_S), '-'; ...
                'Loss model rotor / stator', [o.loss_R ' / ' o.loss_S], ''; 'Feasible', strjoin(D.reasons, '; '), ''}];
        end
    end
end
