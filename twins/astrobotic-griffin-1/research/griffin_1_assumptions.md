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
- Griffin-1 stowed egress ramps: Astrobotic's [2021 Griffin-1 product image](https://www.astrobotic.com/wp-content/uploads/2021/02/griffin-1.png)
  shows two raised ramp assemblies folded over the deck. This supports a
  qualitative stowed silhouette; it does not disclose section dimensions,
  hinge datums, joint travel, actuation, or the supplier mechanism ICD.
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
| FLIP geometry, wheel loads, motor data, battery and steering ICD | mostly unknown | the active study configuration is owned by the FLIP SysML packages; Astrolab's public material does not provide the vehicle ICD |
| exact landing coordinates | unresolved | reproducible NOBILE03 regional study anchor; not a flight touchdown coordinate |
| terrain relief | source-backed regional product | 512 m NOBILE03 crop, locally reprojected and vertically normalized for the Twin |
| lighting / epoch | deterministic study condition | surface-operations and visual-review scene roots use TDB JD 2461395.5 (2026-12-21 TDB calendar date) at the NOBILE03 regional anchor. The simulator ephemeris gives Sun azimuth 7.52° clockwise from north and elevation 6.49° at that epoch. The visual-review scene references the same solar-system model and copies its typed site/time values from the surface-operations composition. Public material gives a late-2026 launch window, not a landing timestamp; this study epoch does not assert flight timing. Reproduce with `cargo run -p lunco-celestial-ephemeris --example sun_at_site -- -84.72672255 29.14428685 2461395.5 1.0 0.125` |
| communications geometry | study setup | deterministic local environment |
| FLIP flight-stack attachment | unresolved in public data | the mission adapter and release interface require controlled integration data; current implementation status is recorded in `../contracts/implementation_gaps.md` |
| Griffin payload capacity | source-backed product value | 625 kg published by Astrobotic; integrated mission load is a separate manifest quantity |
| deck and egress | qualitative public image; mechanical ICD not released | Griffin owns the isogrid deck and ramp interface in its requirements. The 2021 Astrobotic image informs a raised, folded ramp silhouette only; hinge angles, section offsets, deployment kinematics, and FLIP's detailed interface remain Twin study values or unresolved |
| Griffin-1 solar configuration | Three arrays, transit Sun-pointing intent, and the surface Sun quadrant are source-backed; exact installation data is unpublished | SysML owns three named arrays across the consecutive forward, bevel, and starboard faces. The Editor-authored vehicle references the shared panel component at all three rail-derived stations and uses panel widths derived from the mounting-rail pairs. Stations, panel normals, cutout outlines, support/hinge interfaces, deployment limits, control limits, and electrical behavior remain visual-study values or unresolved |
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

The executable study inputs are owned by `FlipRequirements::FlipRover`,
`FlipSensorPowerRequirements::FlipSensorPowerAssembly`, and the corresponding
subsystem packages. This report does not repeat their numeric values. The
published battery and solar ratings are requirements; the gap report records
whether the physical storage and generation models realize them. Supplier
geometry, mobility, thermal, and mass-property data remain unavailable, so the
study configuration is not flight data.

The Twin is therefore suitable for composition, control-flow, contact,
deployment, mobility, and subsystem integration studies. It is not a flight-
certified Griffin model and does not claim validated Nobile Crater geography,
trajectory, regolith mechanics, or vehicle performance.
