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
- Primary rover payload: Astrolab FLIP.
- Public status at handoff: lander environmental testing and late-2026 launch
  planning; exact flight state and final surface coordinates remain subject to
  change.

## Simulator assumptions

The first Twin deliberately reuses generic LunCoSim vehicle assets and a
procedural surface surrogate. Until mission-owner data is supplied, do not
present these as Griffin flight values:

| Parameter | Status | Treatment |
|---|---|---|
| Griffin dimensions and geometry | unknown | inherited visual/physical surrogate |
| dry mass, propellant load, inertia, center of mass | unknown | inherited lander values; replace with sourced opinions |
| engine thrust and throttle envelope | unknown | inherited powered-descent model |
| FLIP wheel count, geometry, wheel loads, motor data, battery ICD | mostly unknown | active four-wheel all-wheel-steer study proxy; replace from supplier ICD |
| landing coordinates and terrain relief | unresolved | labelled procedural flat/cratered surrogate |
| lighting, epoch, communications geometry | study setup | deterministic local environment |
| FLIP flight-stack attachment | unresolved in public data and previous solver trial | active prototype now uses a scene-level fixed top-deck adapter joint, detached after touchdown; validate against the next runtime test |
| Griffin payload class | MoonDAO backlog requirement | 625 kg prototype class, explicitly not a public Griffin flight value |
| deck and egress | public mechanical ICD not released | four-leg polar wrapper with isogrid deck and two solver-jointed side ramps |
| Griffin solar layout | public structural data incomplete | two side-mounted visual arrays; electrical sizing remains a Modelica study input |

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
| Vehicle mass | 450 kg | proxy, consistent with public “nearly half a metric ton” scale |
| Envelope | 2.4 m × 1.8 m × 0.7 m | simulator assumption |
| Wheel count / steering | 4 / all-wheel-steer | architecture study proxy; FLIP-specific count is unconfirmed |
| Wheel radius / width | 0.45 m / 0.28 m | simulator assumption |
| Battery | 28 V, 83.33 Ah, 85% initial SOC | inherited simulator electrical proxy |
| Solar array | 3 m², 30% efficiency, fixed +Y incidence | FLEX-family proxy for surface power study |
| Motor/gearbox | 0.9 N·m motor, 200:1, 400 N·m output limit | simulator actuator proxy |

## MoonDAO Griffin prototype requirements

The 2026-08-30 backlog task adds the following implementation requirements:

- 625 kg payload-class prototype;
- four landing legs, isogrid top deck, and side-mounted solar arrays;
- FLIP mounted on the top deck through a payload adapter during descent;
- two deployable side ramps with `PhysicsRevoluteJoint` hinges and physical
  collision surfaces;
- landing → ramp deployment → adapter release → rover egress → base-site route.

For the current bounded contact study, each ramp has a 12 m clear collision
envelope and is commanded to ±0.58 rad from the stowed pose. Those dimensions
are geometry/control surrogates chosen to keep the 4.8 m-wide FLIP proxy on the
physical ramp; they are not a released Griffin mechanical ICD. The top-deck
adapter plate and restraints are visual-only after release, while the deck and
ramp surfaces remain the contact path. The shared waypoint consumer also
ignores waypoint sensors for fixed-joint cargo, so FLIP cannot consume the
surface route before the adapter release boundary.

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
