# Griffin-1 surface Twin assumptions

This file separates public mission facts from simulator-only assumptions. It is
part of the Twin's provenance record and must be updated whenever an authored
number changes.

## Public mission facts

- Mission: Astrobotic Griffin Mission One, also described by NASA as Moon Base
  II / CLPS Griffin-1.
- Operator/lander developer: Astrobotic, with the 2026 corporate transition
  announced as an agreement to join Voyager Technologies; Griffin-1 remains
  the mission identity.
- Planned landing region: Nobile Crater area near the lunar South Pole.
- Primary rover payload: Astrolab FLIP (FLEX Lunar Innovation Platform).
- Regional terrain source: LROC NAC DTM NOBILE03, an official 4 m/pixel
  polar-stereographic DTM covering the Nobile South-Pole region. This is a
  source-backed terrain product, not evidence of the exact touchdown point.
- Public status at handoff: lander environmental testing and late-2026 launch
  planning; exact flight state and final surface coordinates remain subject to
  change.
- Astrobotic's [manifest](https://www.astrobotic.com/lunar-delivery/manifest/)
  lists the Griffin destination as Nobile Region 2026; NASA's [Moon Base
  update](https://www.nasa.gov/news-release/nasa-provides-update-on-moon-base-rovers-landers-missions/)
  describes launch as planned later in 2026. Public material reviewed here
  does not provide the launch UTC or lunar landing epoch. The scene's authored
  epoch is a repeatable study condition, not a flight date.
- Griffin-1 solar configuration: Astrobotic's [solar setup post](https://lnkd.in/p/dJHz9duN)
  describes transit Sun-pointing and places the surface panels in the single
  quadrant traversed by the mission-window Sun path. Its two-installed,
  one-remaining wording records build status at publication; the mission
  configuration requirement remains the canonical `solarArrayCount` in
  `griffin_lander_requirements.sysml`. The June 2026 [integration image](https://www.astrobotic.com/wp-content/uploads/2026/06/26.06.15_Griffin-1_PressConference_1348_Edit-scaled.jpg)
  shows upright panels across adjacent sides of one lander sector. Image
  evidence supports qualitative layout only, not scale, exact normals, mount
  interfaces, or performance tolerances.
- Griffin propulsion baseline: Astrobotic's current Griffin product page says
  seven main engines. The older polar/VIPER Griffin User Guide describes a
  five-engine baseline, so the older count is not applied to Griffin-1.

## Simulator assumptions

The first Twin deliberately reuses generic LunCoSim vehicle assets. Until
mission-owner data is supplied, do not present these as Griffin flight values:

| Parameter | Status | Treatment |
|---|---|---|
| Griffin dimensions and geometry | unknown | inherited visual/physical surrogate; public material describes a stout aluminum frame and isogrid deck, not an as-built dimension set |
| dry mass, propellant load, inertia, center of mass | unknown | NASA says Griffin-1 completed mass-properties testing but public numerical values were not found; inherited lander values remain proxies |
| engine thrust, throttle, station and cant angles | unknown | inherited powered-descent model; current product page supports seven main engines, while older Griffin/VIPER guidance describes five |
| FLIP wheel count, geometry, wheel loads, motor data, battery ICD | mostly unknown | active four-wheel all-wheel-steer study proxy; Astrolab confirms full-size wheels/battery but not the station ICD; replace from supplier data |
| exact landing coordinates | unresolved | reproducible NOBILE03 regional study anchor; not a flight touchdown coordinate |
| terrain relief | source-backed regional product | 512 m NOBILE03 crop, locally reprojected and vertically normalized for the Twin |
| lighting / epoch | deterministic study condition | surface-operations and visual-review scene roots use TDB JD 2461395.5 (2026-12-21 TDB calendar date) at the NOBILE03 regional anchor. The simulator ephemeris gives Sun azimuth 7.52° clockwise from north and elevation 6.49° at that epoch. The visual-review scene references the same solar-system model and copies its typed site/time values from the surface-operations composition. Public material gives a late-2026 launch window, not a landing timestamp; this study epoch does not assert flight timing. Reproduce with `cargo run -p lunco-celestial-ephemeris --example sun_at_site -- -84.72672255 29.14428685 2461395.5 1.0 0.125` |
| communications geometry | study setup | deterministic local environment |
| FLIP flight-stack attachment | unresolved in public data and previous solver trial | active prototype now uses a scene-level fixed top-deck adapter joint, detached after touchdown; validate against the next runtime test |
| Griffin payload capacity | source-backed product value | 625 kg published by Astrobotic; integrated mission load is a separate manifest quantity |
| deck and egress | public mechanical ICD not released | four-leg wrapper with isogrid deck and optional side ramps; FLIP's public concept supports direct top-deck egress |
| Griffin-1 solar configuration | count, transit Sun-pointing intent, and surface quadrant are source-backed; exact engineering values are unknown | SysML requires the canonical array count, adjacent-side installation within the mission Sun quadrant, and transit Sun-pointing when constraints permit. Current Twin still composes two opposite-side arrays and is nonconforming. Stations, panel normals, dimensions, support/hinge geometry, cell layout, control limits, electrical data, and deployment states are unresolved |
| propellant tank count/type | unknown | four COPV-style visual assemblies are a Twin study assumption, not a published Griffin-1 tank ICD |

## NOBILE03 terrain processing record

The terrain source is the official LROC product [NAC DTM
NOBILE03](https://data.lroc.im-ldi.com/lroc/view_rdr_product/NAC_DTM_NOBILE03)
and its PDS3 label. The direct source URLs and SHA-256 checksums are pinned in
`Assets.toml`; the raw TIF and LBL remain under the ignored Twin-local cache.
The label identifies a polar-stereographic product centered on the south pole,
so it cannot be passed honestly to the native equirectangular-only DEM
processor as if it were already in the runtime frame.

The checked-in adapter
`tools/terrain/reproject_lroc_polar_dem.py` performs the source projection
conversion and writes a LunCoSim-compatible float32 GeoTIFF with `MOON_ME`
frame tags. The active crop is:

| Field | Authored value | Confidence |
|---|---:|---|
| regional center latitude | -84.72672255 deg | simulator study anchor |
| regional center longitude | 29.14428685 deg east | simulator study anchor |
| local window | 512 m × 512 m | simulator study choice |
| node spacing / resolution | 4 m / 129 × 129 | source-aligned processing choice |
| source border datum | 5187.322 m | computed from the selected crop |
| local vertical offset | -5187.322 m | explicit normalization into the Twin scene frame |

The resulting local height range is approximately -33.674 m to +27.445 m.
This is the terrain relief used by the simulation, not an assertion about the
absolute elevation of the Griffin touchdown point. The scene root remains at
local height zero; the terrain georeference records the source datum for
provenance. The current runtime does not apply `lunco:anchor:height_m` as a
second static-scene vertical placement, so applying that offset again would
double-place the surface. A native datum/vertical-normalization contract is a
Rust/runtime feature still missing.

## FLIP engineering basis used by the Twin

The Astrolab FLIP design video shows the current rover concept for Griffin-1
and describes maturation of the full-size batteries, tires, avionics, sensors,
and software, including lunar-dust mitigation. Astrolab's public material also
describes hyper-deformable airless tires, a collapsible solar array, and a
nearly half-metric-ton rover with 30 kg payload capacity. Exact FLIP wheel
count, dimensions, wheel torque, battery capacity, thermal limits, and steering
map are not published in the reviewed primary sources.

The executable asset therefore uses a clearly labelled engineering proxy:

| Parameter | Active study value | Status |
|---|---:|---|
| Vehicle mass | 450 kg | dynamic study proxy; public source only states nearly 500 kg class |
| Envelope | 2.4 m × 1.8 m × 0.7 m | simulator assumption |
| Wheel count / steering | 4 / all-wheel-steer | architecture study proxy; FLIP-specific count is not public |
| Wheel radius / width | 0.45 m / 0.28 m | simulator assumption |
| Battery | 28 V, 83.33 Ah, 85% initial SOC | inherited simulator electrical proxy |
| Solar array | 3 m², 30% efficiency, fixed +Y incidence | fixed-panel visual/power proxy; Astrolab describes a collapsible FLIP array |
| Motor/gearbox | 0.9 N·m motor, 200:1, 400 N·m output limit | simulator actuator proxy |

## Twin study implementation requirements

The 2026-08-30 backlog task adds the following implementation requirements;
they are not substitutes for the published Griffin/FLIP facts above:

- use the published 625 kg Griffin payload capacity as the acceptance boundary;
- four landing legs, isogrid top deck, and side-mounted solar arrays;
- FLIP mounted on the top deck through a payload adapter during descent;
- two solid integrated side ramps with physical collision surfaces and paired
  edge rails; a typed hinge command is modeled, while deployed runtime
  stability and rover traversal remain unaccepted;
- landing → ramp deployment → adapter release → rover egress → base-site route.

The current SysML and Editor-builder study uses a 12.228605 m top contact face,
a 0.18 m track thickness, and mirrored 49 degree deployment commands from the
3.98 m touchdown COM datum. Each physical track is authored as a convex mesh;
its toe miter is derived from track thickness and deployment angle so the
upper and lower toe edges meet the terrain plane together. The 3.50 m rail
envelope, paired tracks, hinge, transition, and apron remain explicit Twin
assumptions because Astrobotic has not published a ramp or site-interface ICD.
The 95 kg body mass and (210, 34, 210) kg m² diagonal inertia are also
source-owned study proxies; supplier mass properties and body center of mass
remain unverified.

These values and the typed geometry plan are not yet confirmed in the composed
Editor stage. The checked-in vehicle layer still requires the Editor migration,
composed readback of both track meshes and deck transitions, and deployed FLIP
wheel-contact evidence before any ramp or egress acceptance is claimed. Public
mission material describes optional rover egress but does not provide the
as-built ramp geometry or site-apron design.

These values are suitable for Modelica coupling, control-flow, power-budget,
thermal, and mobility sensitivity studies. They are not flight data.

The Twin is therefore suitable for composition, control-flow, contact,
deployment, mobility, and subsystem integration studies. It is not a flight-
certified Griffin model and does not claim validated Nobile Crater geography,
trajectory, regolith mechanics, or vehicle performance.
