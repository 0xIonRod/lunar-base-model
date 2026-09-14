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

## Simulator assumptions

The first Twin deliberately reuses generic LunCoSim vehicle assets. Until
mission-owner data is supplied, do not present these as Griffin flight values:

| Parameter | Status | Treatment |
|---|---|---|
| Griffin dimensions and geometry | unknown | inherited visual/physical surrogate; public material describes a stout aluminum frame and isogrid deck, not an as-built dimension set |
| dry mass, propellant load, inertia, center of mass | unknown | inherited lander values; replace with sourced opinions |
| engine thrust and throttle envelope | unknown | inherited powered-descent model |
| FLIP wheel count, geometry, wheel loads, motor data, battery ICD | mostly unknown | active four-wheel all-wheel-steer study proxy; Astrolab confirms full-size wheels/battery but not the station ICD; replace from supplier data |
| exact landing coordinates | unresolved | reproducible NOBILE03 regional study anchor; not a flight touchdown coordinate |
| terrain relief | source-backed regional product | 512 m NOBILE03 crop, locally reprojected and vertically normalized for the Twin |
| lighting, epoch, communications geometry | study setup | deterministic local environment |
| FLIP flight-stack attachment | unresolved in public data and previous solver trial | active prototype now uses a scene-level fixed top-deck adapter joint, detached after touchdown; validate against the next runtime test |
| Griffin payload capacity | source-backed product value | 625 kg published by Astrobotic; integrated mission load is a separate manifest quantity |
| deck and egress | public mechanical ICD not released | four-leg wrapper with isogrid deck and optional side ramps; FLIP's public concept supports direct top-deck egress |
| Griffin solar layout | public structural data incomplete | two side-mounted visual arrays; electrical sizing remains a Modelica study input |

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
  edge rails; the accepted runtime pose is authored from the deck datum to the
  terrain plane, while stable articulated folding remains future work;
- landing → ramp deployment → adapter release → rover egress → base-site route.

For the current bounded contact study, each ramp is an 8 m solid collision
surface with paired edge rails, authored at ±50° from the deck datum so its
working span reaches the landing plane. Those dimensions and angles are
geometry/control surrogates chosen to keep the 4.8 m-wide FLIP proxy on the
physical ramp; they are not a released Griffin mechanical ICD. The accepted
runtime keeps the ramps integrated with the lander compound; the previous
independent rigid-body hinge attempt was rejected because it could escape the
bounded physics world. The top-deck adapter plate and restraints are
visual-only after release, while the deck, ramps, and rails remain the contact
path. The shared waypoint consumer also ignores waypoint sensors for fixed-joint
cargo, so FLIP cannot consume the surface route before the adapter release
boundary.

These requirements are now authored in `vehicles/griffin_1.usda` and
`scenes/griffin_1_surface_ops.usda`. They are a simulation prototype, not a
claim about the released Griffin flight configuration. In particular, Astrolab's
public mission material describes direct top-deck egress and does not publish an
egress-ramp ICD; the two ramps are therefore a deliberate project assumption.

These values are suitable for Modelica coupling, control-flow, power-budget,
thermal, and mobility sensitivity studies. They are not flight data.

The Twin is therefore suitable for composition, control-flow, contact,
deployment, mobility, and subsystem integration studies. It is not a flight-
certified Griffin model and does not claim validated Nobile Crater geography,
trajectory, regolith mechanics, or vehicle performance.
