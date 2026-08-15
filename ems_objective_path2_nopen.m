function [cost, LPSP_pct, SSR] = ems_objective_path2_nopen(x, nasa_data, load_kW, batt_cost_per_kWh, pv_cost_per_m2)%% Unpack
A_pv      = x(1);
A_wind    = x(2);

Batt_cap  = x(3);
Tank_cap  = x(4);
N_cells   = x(5);
T_sim = length(load_kW);

%% Constants
eta_pv       = 0.18;
temp_coeff   = 0.004;
rho_air      = 1.225;
Cp           = 0.40;
v_cutin      = 2.5;
v_cutout     = 25.0;
v_rated      = 12.0;
P_cell_kW    = 1.0;
eta_elec     = 0.70;
eta_fc       = 0.55;
kWh_per_kgH2 = 33.3;
SOC_min      = 0.20;
SOC_max      = 1.00;
eta_batt     = 0.90;

%% Extract
GHI  = nasa_data(:,1);
WS   = nasa_data(:,2);
Temp = nasa_data(:,3);

%% PV
P_pv = eta_pv .* A_pv .* GHI/1000 .* (1 - temp_coeff .* (Temp - 25));
P_pv = max(P_pv, 0);

%% Wind (vectorized)
P_wind = zeros(T_sim, 1);
v = WS;
mid  = (v >= v_cutin) & (v < v_rated);
high = (v >= v_rated) & (v <= v_cutout);
P_wind(mid)  = 0.5 * rho_air * Cp * A_wind * v(mid).^3 / 1000;
P_wind(high) = 0.5 * rho_air * Cp * A_wind * v_rated^3 / 1000;

%% Dispatch (off-grid)
SOC       = 0.50 * Batt_cap;
H2_stored = 0.50 * Tank_cap;
unmet     = zeros(T_sim, 1);
curtailed = zeros(T_sim, 1);

for t = 1:T_sim
    P_gen  = P_pv(t) + P_wind(t);
    P_fc   = N_cells * P_cell_kW * eta_fc;
    P_load = load_kW(t);
    surplus = P_gen - P_load;
    if surplus >= 0
        charge = min(surplus * eta_batt, (SOC_max*Batt_cap - SOC));
        SOC = SOC + charge;
        rem_surplus = surplus - charge/eta_batt;
        H2_made = min(rem_surplus * eta_elec / kWh_per_kgH2, Tank_cap - H2_stored);
        H2_stored = H2_stored + H2_made;
        curtailed(t) = max(rem_surplus - H2_made * kWh_per_kgH2 / eta_elec, 0);
    else
        deficit = -surplus;
        batt_out = min(deficit, (SOC - SOC_min*Batt_cap) * eta_batt);
        SOC = SOC - batt_out/eta_batt;
        deficit = deficit - batt_out;
        fc_out = min(deficit, min(P_fc, H2_stored * kWh_per_kgH2 * eta_fc));
        H2_stored = H2_stored - fc_out / (kWh_per_kgH2 * eta_fc);
        deficit = deficit - fc_out;
        unmet(t) = deficit;
    end
end
% SSR (off-grid: fraction of load met by renewables)
SSR = (1 - sum(unmet) / sum(load_kW)) * 100;
%% LPSP
LPSP = sum(unmet) / sum(load_kW);
LPSP_pct = LPSP * 100;
LPSP_penalty = 5 * max(0, LPSP - 0.05);

%% Cost
INR_USD  = 1/83;
lifetime = 20;
r        = 0.08;
CRF      = (r*(1+r)^lifetime) / ((1+r)^lifetime - 1);

if nargin < 4, batt_cost_per_kWh = 25000; end
if nargin < 5, pv_cost_per_m2    = 22000; end
C_pv   = A_pv    * pv_cost_per_m2;
C_wind = A_wind  * 15000;
C_batt = Batt_cap/1000 * batt_cost_per_kWh;
C_tank = Tank_cap * 80000;
C_fc   = N_cells  * 150000;

CAPEX_INR = C_pv + C_wind + C_batt + C_tank + C_fc;
CAPEX_INR = CAPEX_INR - (0.30*C_pv + 0.20*C_wind);

OPEX_annual   = 0.02 * CAPEX_INR;
CO2_tonnes    = (sum(P_pv + P_wind) * 0.82) / 1000;
carbon_credit = CO2_tonnes * 50;

TAC_INR  = CAPEX_INR * CRF + OPEX_annual - carbon_credit;
E_served = sum(load_kW) * (1 - LPSP) / 20;  % annual kWh
LCOE_raw = (TAC_INR * INR_USD) / E_served;
cost = LCOE_raw;

end  % <-- only ONE end, here at the very bottom