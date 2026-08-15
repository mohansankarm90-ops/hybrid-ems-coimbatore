# Hybrid EMS â€” PV/Wind/Battery/Hâ‚‚ Microgrid, Coimbatore

Academic research project. Designs and optimizes an off-grid hybrid energy management system for a 50 kW village load in Coimbatore, India using 20 years of NASA POWER hourly data (8760 Ã— 20 = 175,320 hours).

## System Architecture

- **PV array** â€” GHI-driven, temperature-corrected (Î· = 0.18)
- **Wind turbine** â€” cubic power curve, cut-in 2.5 m/s, rated 12 m/s
- **Li-ion battery** â€” 61.95 kWh, SOC limits 20â€“100%
- **Hydrogen subsystem** â€” electrolyzer (Î· = 0.70) + fuel cell (Î· = 0.55) + compressed tank
- **Dispatch** â€” priority: PV/Wind â†’ Battery â†’ Hydrogen â†’ Unmet

## Optimization

Four algorithms compared on LCOE minimization (design variables: PV area, wind area, battery capacity, Hâ‚‚ tank, electrolyzer cells):

| Algorithm | LCOE ($/kWh) | Notes |
|-----------|-------------|-------|
| GA        | 0.0908      | Off-grid rerun |
| PSO       | 0.0788      | Wind-heavy config |
| GWO       | 0.0789      | Balanced config |
| Surrogate DE (XGBoost) | 0.0687 | Best LCOE |

## Surrogate Model

- 5000 LHS samples â†’ XGBoost surrogate
- 5-fold CV: RÂ² = 0.9984 Â± 0.0001, RMSE = 0.0147 Â± 0.0008 $/kWh
- Feature importance: PV area (51.2%), Wind area (43.5%)

## Key Results

- **Annual SSR**: SW Monsoon 100%, Winter Dry worst at LPSP = 22.97%
- **30-day dispatch**: LPSP = 38.81% (January â€” low wind, high night load)
- **Cost sensitivity**: PV cost dominant driver over battery cost

## Files

| File | Description |
|------|-------------|
| `ems_objective_path2_nopen.m` | Core objective function â€” dispatch + LCOE |
| `hybrid_ems_p8.slx` | Simulink SOC validation model |
| `hybrid_ems.slx` | Simulink base model |
| `p5_cv.py` | XGBoost surrogate 5-fold cross-validation |
| `surrogate_data.csv` | 5000-sample LHS dataset [PV, Wind, Batt, Tank, Cells, LCOE] |
| `coimbatore_nasa_20yr.csv` | NASA POWER 20yr hourly data [GHI, WS, Temp] |

## Parameters

- Location: Coimbatore, Tamil Nadu (11.0Â°N, 76.9Â°E)
- Load: 50 kW peak, mean ~24.54 kW
- Lifetime: 20 years, discount rate 8%
- Subsidies: 30% PV, 20% Wind (Indian government)
- Carbon credit: â‚¹50/tonne COâ‚‚

## Author

Mohanasankar M (25EE034) â€” EEE-A, Sri Krishna College of Engineering and Technology, Coimbatore.
