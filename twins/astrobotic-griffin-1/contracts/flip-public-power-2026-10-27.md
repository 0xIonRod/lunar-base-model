# FLIP public power comparison — 2026-10-27

The running CAD FLIP agrees with the two numerical power specifications in
[Astrolab's primary power post](https://www.linkedin.com/posts/astrolabspace_our-flip-rover-is-equipped-with-a-622-kwh-activity-7508563602279309312-W5Le),
checked on 2026-10-27. That post describes 6.22 kWh battery storage, nearly
270 W peak solar power, and deployment after landing followed by stowage for
the night-survival attempt. These are public specifications, not flight telemetry.

| Quantity | Public FLIP | Running CAD model | Interpretation |
|---|---|---|---|
| Battery nameplate energy | 6.22 kWh | 6.219999878 kWh from 28 V × 222.142852783 Ah | Agrees within floating-point precision |
| Solar peak | Nearly 270 W | 270 W reference rating | Agrees as a rounded model setting |
| Pack/bus voltage | Not stated in this post | 28 V nominal; 28.070257 V observed | Study setting, not validated by that source |
| Delivered solar power | Not stated in this post | 157.895196 W observed | Simulator operating result |
| Charging current | Not stated in this post | +5.625 A observed | Simulator operating result |
| Collection area / efficiency | Not stated in this post | 0.7 m² / 35% | Study assumptions |
| Night survival | Intended attempt | Not tested here | No survival qualification |

The source already exists in `requirements/griffin_requirement_sources.sysml` as
`source_linkedin_astrolab_flip_power_post`; FSP-007/FSP-008 own the existing
battery/solar criteria. This test supplements those contracts for the active CAD
scene and corrects the overly broad statement that all its ratings are assumptions.

## Repeatable live test

From the Twin directory, with the FLIP scene running:

```powershell
python tests/check_flip_public_power.py --port 4202 --output contracts/evidence/flip-public-power-2026-10-27.json
```

The script uses composed `QueryUsdPrim` configuration and 12 same-tick
`ReadPortsBatch` solver observations on the rover. It verifies 6.22 kWh energy,
the rounded 270 W setting, progressing simulation ticks, physical SOC/incidence
bounds, P = V × I, solar delivery no greater than available power, positive
voltage/absolute temperature, and SOC response to a steady signed current.
It rejects missing/nonfinite outputs, non-solver authority, scene faults and
configuration changes during acquisition. The numerical allowances are regression
allowances, not manufacturer tolerances. Paused scenes or intervals without
informative steady current cannot pass the response test.

Result: **9/9 PASS**, ticks **479564–479912**. SOC increased by
**0.0000407958207** (0.00407958 percentage points), with **+5.625 A** throughout.
Evidence: `evidence/flip-public-power-2026-10-27.json`, including raw observations
and composed configuration. No control commands or scene changes were issued.

The roughly 158 W delivery has an identifiable model explanation: the generic
`LunCo.Electrical.SolarPanel` uses a default `v_mp = 48 V` and a current plateau
below that voltage. At 270 W available this gives 270/48 = 5.625 A; multiplying
by the observed 28.070257 V gives 157.895196 W. This source-code explanation is
not evidence for the real FLIP's converter efficiency or operating voltage.
The panel temperature input is fixed at 298.15 K in the observed scene.

This run does not test shadow transitions, panel motion, full discharge,
charge-controller behavior, thermal survival or mobility. No measured FLIP I-V,
converter, thermal or discharge curves were supplied. Agreement with public
nameplates and internal consistency must not be presented as hardware validation.
