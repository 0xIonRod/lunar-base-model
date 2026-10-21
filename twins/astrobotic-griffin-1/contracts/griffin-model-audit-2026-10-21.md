# Griffin model correctness review — 2026-10-21

The model is a public-reference reconstruction and a bounded landing study.
It is not an as-built CAD model or a flight-qualified Griffin digital twin.
This review covers Griffin's structure, arrays, propulsion, tanks, landing
gear, ramps and guidance.

## Reference comparison

| Item | Evidence and model status |
| --- | --- |
| Seven main engines | Confirmed by [Astrobotic's current product description](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/). Seven visible bells and seven independent pressure-fed engine members are authored. |
| Four shock-absorbing legs and four attitude-thruster clusters | Confirmed by that same source. Axial leg compliance, hard stops and source-derived structural collision proxies are modeled; supplier mechanism dimensions and spring characteristics remain unavailable. |
| Three faceted solar faces | Compared with the [15 June 2026 hardware photograph](https://www.nasa.gov/image-detail/26-06-15-griffin-1-pressconference-1348-edit/). The current bank joins front and side frame edges, retains separate stepped/cut-out contours and uses a nominal 12-column/24-row cell field. Counts and metric sizes are reconstructed, not supplier drawings. |
| Lower body and surface appearance | June 2026 hardware is the selected baseline. The bus presentation exposes the separately modeled tank contours and structural members below the solar bank. The 3.60 m span and 0.72 m internal-frame height remain unqualified packaging dimensions; see `griffin-june-bus.md`. This does not establish as-built hidden structure or calibrated dimensions. Yellow-gold MLI is the requested presentation finish; the hardware photograph shows predominantly pale/silver blankets. |
| Engine size and packing | An independent isentropic sizing calculation reproduces a 36.795 mm throat bore, 367.948 mm exit bore and 494.352 mm bell length. Inputs are the historical 700 lbf unit rating, assumed 1.5 MPa pressure and assumed 100:1 expansion. Current seven-engine unit ratings and dimensions are unpublished in the reviewed sources. The 0.64 m ring pitch, skirt and heat shields are packaging estimates. |
| Mission environment | The [NASA launch page](https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/) and Astrobotic manifest identify Nobile. Mounted LROC NOBILE03 terrain and its regional anchor define a reproducible study site, not a released touchdown coordinate or landing date. |

The [13 October JPL report](https://science.nasa.gov/photojournal/voyager-technologies-griffin-1-completes-environmental-testing-at-nasa-jpl/)
documents completed hardware environmental testing. Those tests do not validate
the simulator's thermal parameters, masses, geometry or guidance equations.

## Mass-property correction

The audit found four tank centers at local Y=1.39 m while
`MainPropulsion/PropellantStatus` placed the reactant point loads at Y=+0.8 m
and Y=-0.8 m. That yielded initial COM Y=0 rather than 0.695 m for the same
2,000 kg dry body and two 1,000 kg inventories. The failed coherent read and
its document/stage provenance are retained in the original audit evidence.

`GriffinPropellantMassStudy` now owns the dry-body assumptions and an explicit
study assignment: equal fuel loads at TankPX/TankNX and equal oxidizer loads
at TankPZ/TankNZ. The flight pairing is unpublished. The builder derives both
species centroids and mass-normalized intrinsic diagonal inertia from the
canonical tank stations. The shared Modelica component scales that intrinsic
inertia with live reactant mass and applies the parallel-axis theorem about
the changing vehicle centroid. Tank points exclude liquid shape and slosh.

Initial native body properties are derived by the same authoring plan:
mass 4,000 kg, COM (0, 0.695, 0) m and diagonal inertia
(7,279.6, 7,695, 7,279.6) kg m². These remain study mass properties, not measured
flight values. The existing pilot-thrust gate now independently sums all four
tank loads during depletion and also checks native solver propagation.

## Fidelity gaps

- **Electrical and thermal calibration:** the three photovoltaic faces now
  feed a solved battery/avionics bus and individual thermal masses/coolers.
  The 45-second production gate passes all three GEP requirements, measuring
  geometry-derived area, temperature-dependent generation, radiant/thermal/
  electrical balance and the cooling cap. AZUR cell properties are a declared
  study reference, not an identified Griffin supplier. Battery inventory,
  heat capacity and cooler ratings remain project assumptions. A production
  low-battery vehicle case now passes GEP-004: persistent thrust/yaw demands
  lose authority at solved avionics UVLO, and both main engines and RCS settle
  through their own actuator dynamics. The shared controller's separate power
  interruption/recovery gate passes 108 checks. Disconnected-network
  qualification is recorded in [the subsystem contract](griffin-power-thermal.md).
- **Heat protection:** the apron, engine liner, skirt and MLI have explicit
  geometry/material assignments. Radiative exchange, plume heating, shield
  temperature, coolant capacity and protection of neighboring equipment are
  not solved by those display materials.
- **Mass and propulsion calibration:** the 4,000 kg initial root-body mass,
  inertia tensor, 1,000 kg fuel and 1,000 kg oxidizer loads, tank pressure,
  mixture ratio, nozzle expansion and transient constants are study inputs.
  Public configuration confirmation does not make these flight values.
- **Guidance and sensing:** the final-approach model composes reduced guidance,
  attitude reference, IMU/altimeter and physical actuation. It does not qualify
  Astrobotic's terrain-relative navigation, hazard avoidance, flight software,
  cruise or orbit phases.
- **Structure and mechanisms:** mount closure, panel seams, engine clearances,
  ramp articulation and native contacts can be checked. They do not establish
  strength, buckling, fatigue, real deployment hardware or measured thermal
  allowables. Some geometry, including body collision proxies, is simplified.

Keep these study assumptions explicit until configuration-specific supplier
data or measurements support replacement. The lower-bus checkpoint removes
the unsupported continuous polygonal blanket belt and exposes the separately
modeled tanks and support structure. Its scoped inventory, interfaces and
visual inspection are recorded in [the June bus contract](griffin-june-bus.md);
this does not establish hidden hardware dimensions or exact open-bay collisions.

## Production validation

The scoped Griffin run and visual inspection use the evidence under LunCoSim
`.cache/codex-evidence/griffin-correctness-20261021/`. Its `suite/cohort.json`
records the binary, engine revision and individual runtime source hashes.
All 21 scoped Griffin baseline cases passed on engine `3d9ad023e`, binary SHA-256
`f5c2d75b201fdf6ce8c1f1c38dfc11869c6146fda70a7714014c6b0018dbc3e5`.
That baseline exposed the coverage gap: passing existing checks did not catch
the tank/mass inconsistency.

Correction evidence lives under
`.cache/codex-evidence/griffin-mass-20261021/`. The production Modelica solve
passed 441 independent mass/COM/inertia comparisons over 21 trajectory samples,
including uneven depletion, dry limit, negative-inventory clamping and default
point-load semantics. All eight affected vehicle gates passed: sustained pilot
thrust with the independent four-tank mass oracle and native propagation,
pilot attitude recovery, landing stability, Sun-facing descent, single-engine
failure, fuel exhaustion, oxidizer exhaustion and engine-off impact. The
latest result per case is recorded in `suite/acceptance-summary.json`; rejected
observer-development trials remain in the raw evidence.

Equation owner: shared Modelica commit `8a1604463`. The same eight vehicle gates
and 441 authored equation checks also pass after integration with newer main
physics at `a4f4faca24432102dd9c4852217623db95e30424`. The integrated binary is
SHA-256 `33c4f93de00781b54a0544c5ff13e58437c5412c91e841b823596c07a536a4a6`.
Evidence is under `.cache/codex-evidence/griffin-mass-integration-20261021/`.
The 60-second settling window retained all four contacts at 361/361 samples.
A separate High-quality native Sun-facing landing passed with zero runtime
diagnostics and broken connections; its inspected screenshot is 1024 × 1024.
The concurrent qualification workloads do not establish clean FPS acceptance.
Owned API sessions on 4291, 4292 and 4293 were closed and their ports released.
