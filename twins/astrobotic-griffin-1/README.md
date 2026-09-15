# Astrobotic Griffin-1 / Moon Base II Twin

This Twin is a LunCoSim study model for the planned Astrobotic Griffin-1
mission, now presented by NASA as Moon Base II. It composes a generic LunCoSim
powered-descent lander and a four-wheel FLIP dynamics/visual study proxy, a
source-backed
LROC NOBILE03 South-Pole DEM, live Modelica co-simulation, USD-authored
connections, and a Rhai mission sequence.

It is an integration and operations study, not a flight-validated Griffin
vehicle model. Public Griffin and FLIP engineering data must replace the
surrogate vehicle values before any performance, landing, structural, or
mobility claim is made. The terrain source is real LROC data, but the selected
regional center is a reproducible study anchor, not a confirmed touchdown
coordinate.

## Current public mission baseline

The latest primary-source baseline used for this package is:

- NASA describes Griffin-1 / Moon Base II as a 2026 mission to the lunar
  South-Pole region, carrying more than 499 kg of cargo including
  Astrolab's FLIP rover to Nobile Crater.
- NASA's August 2026 update says Griffin-1 is undergoing environmental testing
  at NASA's Jet Propulsion Laboratory, has completed mass-properties testing,
  and is planned for a late-2026 launch.
- Astrobotic's June 2026 update says the integrated lander is moving through
  environmental testing, with FLIP to be integrated at the Florida launch
  processing site.
- Astrolab's public announcement describes FLIP as a FLEX Lunar Innovation
  Platform, with a public mass of nearly half a metric ton and a 30 kg payload
  capacity. These public values are not silently copied into the generic
  vehicle asset; the Twin records where the real values still need to enter.
- LROC's official NAC DTM NOBILE03 product is a 4 m/pixel polar-stereographic
  digital terrain model covering the Nobile South-Pole region. The source
  product, label, checksums, crop, and reprojection are recorded in
  `Assets.toml`, `tools/terrain/README.md`, and the research record.

Sources:

- NASA, [Moon Base II: Astrobotic Griffin-1](https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/)
- NASA, [NASA Provides Updates on Moon Base Cargo Landers and Tech Demonstrations](https://www.nasa.gov/missions/moon-base/nasa-provides-updates-on-moon-base-cargo-landers-tech-demonstrations/)
- Astrobotic, [Griffin-1 Lunar Lander Unveiled Ahead of Environmental Testing](https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/)
- Astrolab/Astrobotic, [FLIP rover joins Griffin-1](https://www.astrobotic.com/astrolabs-flip-rover-joins-astrobotics-griffin-1-to-the-moon/)

## Package layout

| Path | Purpose |
|---|---|
| twin.toml | Twin identity and default scene |
| Assets.toml | Reproducible LROC NOBILE03 download manifest and checksums |
| scenes/griffin_1_surface_ops.usda | Mission composition and USD topology |
| scenes/griffin_flip_visual.usda | Componentized headful review composition for Griffin and FLIP |
| scenes/griffin_1_editor.usda | Clean derived headful Editor scene containing only the Griffin lander reference |
| vehicles/griffin_1.usda | Reusable Griffin lander wrapper around the LunCoSim descent lander |
| vehicles/griffin_1_visual.usda | Render-only Griffin assembly of replaceable bus, leg, tank, panel, bell, and ramp components |
| vehicles/flip.usda | Reusable FLIP study asset with four-wheel all-wheel-steer mobility, EPS, and thermal networks |
| vehicles/flip_visual.usda | Render-only FLIP assembly with four directional wheel stations, chassis, mast, and solar-array components |
| components/lander/ | Twin-local visual components for the bus, landing legs, tanks, panels, bells, and ramps |
| components/rover/ | Twin-local visual components for chassis, wheels, mast, and solar array |
| behaviors/griffin_1_flip_patrol.btxml | Griffin-local route tree targeting the deck approach, ramp exit, waypoints, and base site |
| environments/south_pole_surrogate.usda | DEM-backed NOBILE03 environment (legacy filename retained for scene compatibility) |
| terrain/nobile03/ | Ignored processed heightfield output, regenerated from the manifest and adapter |
| tools/terrain/ | Polar-stereo download, reprojection, and provenance instructions |
| scenarios/griffin_1_surface_ops.rhai | Mission sequencing and route policy |
| scenarios/tests/griffin_requirements.rhai | Twin-owned structural/parameter verdict and boundary checks |
| scenarios/tests/griffin_lander_requirements.rhai | Rhai observer for the standalone lander-component contract |
| scenarios/tests/griffin_bus_requirements.rhai | Component-owned Rhai gate for the hexagonal bus |
| scenarios/tests/griffin_landing_legs_requirements.rhai | Component-owned Rhai gate for the four landing legs |
| scenarios/tests/griffin_propulsion_requirements.rhai | Component-owned Rhai gate for the seven-engine bell cluster |
| scenarios/tests/griffin_tank_requirements.rhai | Component-owned Rhai gate for the four propellant tanks |
| scenarios/tests/griffin_solar_requirements.rhai | Component-owned Rhai gate for the two Griffin solar arrays |
| scenarios/tests/flip_requirements.rhai | Rhai observer for the standalone four-wheel FLIP contract |
| scenarios/tests/flip_chassis_requirements.rhai | Component-owned Rhai gate for the FLIP chassis |
| scenarios/tests/flip_wheel_requirements.rhai | Component-owned Rhai gate for the four directional wheel stations |
| scenarios/tests/flip_sensor_power_requirements.rhai | Component-owned Rhai gate for the FLIP sensor mast and solar array |
| scenarios/tests/griffin_ramp_requirements.rhai | Rhai observer for independent port/starboard ramp topology, placement, geometry, and deployment checks |
| tools/component_requirements.rhai | Shared generic SysML/USD component-check constructors and verdict metadata |
| tests/griffin_requirements.usda | Minimal composed fixture for the Griffin contract test |
| tests/griffin_lander_requirements.usda | Minimal Griffin-only fixture for the lander-component gate |
| tests/flip_requirements.usda | Minimal FLIP-only fixture for the rover-component gate |
| tests/griffin_*_requirements.usda | Editor-authored, one-component lander verification fixtures |
| tests/flip_*_requirements.usda | Editor-authored, one-component FLIP verification fixtures |
| tests/griffin_ramp_requirements.usda | Griffin-only fixture for the independent ramp gate |
| requirements/griffin_requirements.sysml | Normative Griffin lander/integration SysML v2 requirements, usages, study values, and verification case |
| requirements/griffin_lander_requirements.sysml | Standalone Griffin lander-component SysML v2 contract for bus, legs, tanks, engines, and solar arrays |
| requirements/griffin_bus_requirements.sysml | Bus-owned SysML v2 requirements and verification case |
| requirements/griffin_landing_legs_requirements.sysml | Landing-leg-owned SysML v2 requirements and verification case |
| requirements/griffin_propulsion_requirements.sysml | Propulsion-owned SysML v2 requirements and verification case |
| requirements/griffin_tank_requirements.sysml | Tank-owned SysML v2 requirements and verification case |
| requirements/griffin_solar_requirements.sysml | Griffin-array-owned SysML v2 requirements and verification case |
| requirements/flip_requirements.sysml | Rover-owned FLIP SysML v2 values and visual verification case |
| requirements/flip_chassis_requirements.sysml | Chassis-owned SysML v2 requirements and verification case |
| requirements/flip_wheel_requirements.sysml | Wheel-owned SysML v2 requirements and verification case |
| requirements/flip_sensor_power_requirements.sysml | Sensor/power-owned SysML v2 requirements and verification case |
| requirements/griffin_ramp_requirements.sysml | Dedicated Griffin ramp subsystem requirements, metric envelope, hinge contract, and independent verification case |
| twin.toml `[verification]` | Single registry binding each qualified SysML verification to its Twin scene, Rhai observer, and verdict channel |
| contracts/ | Part contracts, full active/planned check catalog, and typed authoring procedure |
| tools/griffin_spec.rhai | Rhai compatibility projection of limits read from the SysML source |
| tools/griffin_requirements.rhai | Stable public contract API, generic part/layout audit, payload/ramp gates, and typed live-edit gate |
| tools/check_landing_determinism.sh | Twin-local two-process harness comparing the Rhai landing trial at a fixed SI clock |
| tools/griffin_visual_builder.rhai | Idempotent dry/apply runtime builder using generic `assembly_builder` + `assembly_edit` |
| tools/griffin_controls.rhai | Twin-local possession, handoff, and control briefing helpers |
| assets/models/LunCo/Actuation/SignedTorqueAllocator.mo | Reusable signed X/Y/Z RCS torque-to-valve allocator selected through the Griffin USD source-asset contract |
| ../../requirements/griffin-lander.md | Human-readable requirement IDs, provenance, and executable-check traceability |
| research/griffin_1_assumptions.md | Public facts, surrogate values, and confidence boundaries |
| handover.md | Detailed implementation and verification handover |
| agent_to_agent_missing.md | Concrete follow-up work for the next coding agent |
| instructions.md | Step-by-step setup and completion procedure |

Each component has the same three-part acceptance contract: its own SysML v2
file declares the requirement usages and verification case, its own Twin Rhai
observer performs read-only generic USD checks, and the existing Griffin-only
or FLIP-only fixture provides the composed stage. The observer is scoped to one
component even when the fixture contains its sibling visual components; no
combined mission gate can hide a component failure. Component packages reuse
canonical names/counts/dimensions from `griffin_lander_requirements.sysml` or
`flip_requirements.sysml` through qualified source-name attributes, so Rhai does
not carry a second geometry catalog. The generic evaluator rejects ambiguous
short-name lookups instead of guessing.

## Provision the NOBILE03 terrain

The checked-in `Assets.toml` is the source manifest. Raw downloads are stored
under the Twin-local `.cache/` directory and are ignored by Git. The processed
heightfield is also ignored because it is reproducible; only the manifest,
adapter, provenance, and USD wiring are reviewable source.

From the LunCoSim repository root, follow
[`tools/terrain/README.md`](tools/terrain/README.md). The current reproducible
study crop is a 512 m × 512 m local ENU window at 4 m node spacing (129 × 129
nodes), centered at latitude `-84.72672255` and east longitude `29.14428685`.
The source is polar stereographic, so the checked-in Python adapter converts it
to the equirectangular local GeoTIFF format currently consumed by LunCoSim and
normalizes the source datum into the scene-local height frame. This center is a
regional simulation anchor until the flight site is published.

## Build and run

Run from the LunCoSim repository root, which is the directory containing
Cargo.toml and assets/.

For clean lander authoring, open
`twins/astrobotic-griffin-1/scenes/griffin_1_editor.usda` in the headful
Assembly Editor. It derives only the reusable `vehicles/griffin_1.usda`
asset, so FLIP, the payload adapter, route markers, terrain payload, and
mission/tutorial scenario do not obscure the lander. Keep that scene for
visual authoring; use `scenes/griffin_1_surface_ops.usda` for integration and
runtime acceptance.

For render-only component work, open `vehicles/griffin_1_visual.usda` and
`vehicles/flip_visual.usda` as two independent USD previews in Editor
Perspective. Use the Twin `griffin_visual_builder` library for the complete
vehicle recipe, or its isolated `apply_isolated_griffin_ramp(..., "port"|
"starboard", ...)` entry point when refining one ramp. Each operation is
typed, journaled, and saved through the Editor; never rewrite the USDA text by
hand. The ramp requirements and Rhai verification are intentionally separate
so a ramp can be accepted without coupling it to FLIP's visual review.

### Build

On native Windows, the current EOP-data build helper expects the Unix date
utility. If Git for Windows is installed, build with its utility directory
temporarily prepended to PATH:

    $env:PATH = 'C:\Program Files\Git\usr\bin;' + $env:PATH
    cargo build -p lunco-luncosim --bin luncosim

The PATH change is process-local and does not change the repository.

### Parse/lint the Twin files

    .\target\debug\luncosim.exe --validate twins\astrobotic-griffin-1\requirements\griffin_requirements.sysml twins\astrobotic-griffin-1\requirements\griffin_lander_requirements.sysml twins\astrobotic-griffin-1\requirements\flip_requirements.sysml twins\astrobotic-griffin-1\requirements\griffin_ramp_requirements.sysml twins\astrobotic-griffin-1\requirements\moonbase_project_requirements.sysml twins\astrobotic-griffin-1\vehicles\griffin_1.usda twins\astrobotic-griffin-1\vehicles\flip.usda twins\astrobotic-griffin-1\environments\south_pole_surrogate.usda twins\astrobotic-griffin-1\scenarios\griffin_1_surface_ops.rhai twins\astrobotic-griffin-1\scenarios\tests\griffin_lander_requirements.rhai twins\astrobotic-griffin-1\scenarios\tests\flip_requirements.rhai twins\astrobotic-griffin-1\scenarios\tests\griffin_ramp_requirements.rhai twins\astrobotic-griffin-1\tools\griffin_controls.rhai twins\astrobotic-griffin-1\behaviors\griffin_1_flip_patrol.btxml

All listed source files must report OK; the Twin requirements test below is the
composed-stage check rather than a text-only parse. The Rhai test also validates
the same SysML source through `ValidateSysml` before checking USD facts.

### Run the Twin requirements test

The Griffin-specific structural lint is a Rhai tool owned by this Twin. It
checks the composed wrapper rather than parsing USDA text, and the test fixture
does not load terrain, FLIP, guidance, or the mission timeline:

    /home/rod/Documents/luncosim-workspace/terrain/target/debug/luncosim test --scene /home/rod/Documents/models/lunar-base-model/twins/astrobotic-griffin-1/tests/griffin_requirements.usda --verification Griffin1Requirements::Verify_GriffinRequirements --max-ticks 120 --tick-hz 60 --threads 1 --jitter 0

The `[verification]` registry in `twin.toml` is the only execution binding:
the qualified SysML verification name selects the Twin-relative `.usda` scene,
`.rhai` observer, and expected verdict channel. The production runner rejects
an unknown, duplicate, unindexed, or mismatched mapping before starting the
simulation. Keep the requirements and verification declarations in SysML;
the registry contains no thresholds or copied requirement values.

The same tool runs against the open headful Editor document through
`griffin_requirements::lint_live(doc_id, "/Griffin1")` for the aggregate gate or
`griffin_requirements::part_report_live(doc_id, "/Griffin1")` to inspect each
part and its known/TBD parameter status. The report checks named geometry
ownership, so an inherited substitute cannot hide a hidden Griffin wrapper. Use
`griffin_requirements::layout_report_live(doc_id, "/Griffin1")` for exact
inventory, signed-side placement, symmetry, body-shape, leg-attachment, and
legacy-proxy checks. Use
`payload_limit_live` before accepting a payload load and
`apply_ramp_deployment` for a command-limited typed ramp edit. The full
active/planned requirement matrix is in `contracts/checks.md`; planned checks
are intentionally not represented as passing. Re-run
`lint_live` after the projection advances; do not close or reload the document
between edit and inspection.

Run the isolated component gates with the same fixed-clock settings:

    luncosim test --scene twins/astrobotic-griffin-1/tests/griffin_lander_requirements.usda --verification GriffinLanderRequirements::Verify_GriffinLanderRequirements --verdict-channel GRIFFIN_LANDER_REQUIREMENTS --max-ticks 120 --tick-hz 60 --threads 1 --jitter 0
    luncosim test --scene twins/astrobotic-griffin-1/tests/griffin_bus_requirements.usda --verification GriffinBusRequirements::Verify_GriffinBusRequirements --verdict-channel GRIFFIN_BUS_REQUIREMENTS --max-ticks 120 --tick-hz 60 --threads 1 --jitter 0
    luncosim test --scene twins/astrobotic-griffin-1/tests/griffin_landing_legs_requirements.usda --verification GriffinLandingLegRequirements::Verify_GriffinLandingLegRequirements --verdict-channel GRIFFIN_LANDING_LEG_REQUIREMENTS --max-ticks 120 --tick-hz 60 --threads 1 --jitter 0
    luncosim test --scene twins/astrobotic-griffin-1/tests/griffin_propulsion_requirements.usda --verification GriffinPropulsionRequirements::Verify_GriffinPropulsionRequirements --verdict-channel GRIFFIN_PROPULSION_REQUIREMENTS --max-ticks 120 --tick-hz 60 --threads 1 --jitter 0
    luncosim test --scene twins/astrobotic-griffin-1/tests/griffin_tank_requirements.usda --verification GriffinTankRequirements::Verify_GriffinTankRequirements --verdict-channel GRIFFIN_TANK_REQUIREMENTS --max-ticks 120 --tick-hz 60 --threads 1 --jitter 0
    luncosim test --scene twins/astrobotic-griffin-1/tests/griffin_solar_requirements.usda --verification GriffinSolarRequirements::Verify_GriffinSolarRequirements --verdict-channel GRIFFIN_SOLAR_REQUIREMENTS --max-ticks 120 --tick-hz 60 --threads 1 --jitter 0
    luncosim test --scene twins/astrobotic-griffin-1/tests/flip_requirements.usda --verification FlipRequirements::Verify_FLIPComponentRequirements --verdict-channel FLIP_REQUIREMENTS --max-ticks 120 --tick-hz 60 --threads 1 --jitter 0
    luncosim test --scene twins/astrobotic-griffin-1/tests/flip_chassis_requirements.usda --verification FlipChassisRequirements::Verify_FLIPChassisRequirements --verdict-channel FLIP_CHASSIS_REQUIREMENTS --max-ticks 120 --tick-hz 60 --threads 1 --jitter 0
    luncosim test --scene twins/astrobotic-griffin-1/tests/flip_wheel_requirements.usda --verification FlipWheelRequirements::Verify_FLIPWheelRequirements --verdict-channel FLIP_WHEEL_REQUIREMENTS --max-ticks 120 --tick-hz 60 --threads 1 --jitter 0
    luncosim test --scene twins/astrobotic-griffin-1/tests/flip_sensor_power_requirements.usda --verification FlipSensorPowerRequirements::Verify_FLIPSensorPowerRequirements --verdict-channel FLIP_SENSOR_POWER_REQUIREMENTS --max-ticks 120 --tick-hz 60 --threads 1 --jitter 0
    luncosim test --scene twins/astrobotic-griffin-1/tests/griffin_ramp_requirements.usda --verification GriffinRampRequirements::Verify_GriffinRampRequirements --verdict-channel GRIFFIN_RAMP_REQUIREMENTS --max-ticks 120 --tick-hz 60 --threads 1 --jitter 0

The fixtures deliberately load one vehicle at a time, while each registered
observer scopes its checks to one component. A component gate is not replaced
by the combined visual gate: it is the evidence that a bus, leg set, engine
cluster, tank set, solar array, chassis, wheel set, sensor/power assembly,
lander, rover, or ramp can be reviewed and diagnosed independently.

### Check landing divergence

`requirements/griffin_requirements.sysml` owns the landing-stability horizon,
tilt/speed/drift bounds, and repeatability tolerances. The Rhai contract test
(`scenarios/tests/griffin_surface_ops_contract.rhai`) samples the composed
lander every ten fixed ticks and emits a `GRIFFIN_LANDING_STABILITY` verdict
plus a `GRIFFIN_LANDING_STABILITY_METRICS` JSON line. Run two fresh processes
with the same scene revision and compare those metrics:

    LUNCOSIM_BIN=/path/to/terrain/target/debug/luncosim \
      twins/astrobotic-griffin-1/tools/check_landing_determinism.sh

The harness is deliberately not a second physics implementation: it only
orchestrates two existing `luncosim test` invocations and applies the tolerances
read by Rhai from SysML. A failing command is evidence of run-to-run divergence
or a stability-limit violation, not a hidden pass.

### Componentized visual authoring

The visual review composition is intentionally not a CAD or B-rep deliverable.
Each visible subsystem is a referenced USDA component with its own stable
children and SI geometry. `tools/griffin_visual_builder.rhai` exposes:

* `griffin_visual_builder::visual_component_plan(doc, edit_target, root)` for a
  dry, idempotent operation list;
* `griffin_visual_builder::apply_visual_components(doc, edit_target, root,
  parent_generation)` for one journaled `ApplyUsdOps` change set.

The helper uses the generic LunCoSim `assembly_builder`/`assembly_edit` surface,
accepts Twin-local `twin://` references, and requires the parent frames to be
present before submission. The live Editor remains open; after the command is
acknowledged, query the same document generation and run
`scenarios/tests/griffin_flip_visual.rhai`. The test checks every leg, tank,
ramp, solar panel, engine bell, wheel subpart, mast subpart, and the composed
geometry bounds against SysML metre datums. Both visual and dynamic assemblies
use the source-backed four-wheel directional topology; a presentation-only
proxy must not silently change that count.

Station names are read from the SysML source (`landingLegNames`,
`propellantTankNames`, `rampNames`, `solarArrayNames`, `mainEngineNames`, and
`visualWheelNames`) at test time. This keeps the component decomposition and
the requirement source aligned without baking a second identity catalog into
Rhai. The test emits a structured `<channel>_EVIDENCE` event before its normal
verdict line so the result can be paired with a same-generation composed query
and frame.

The Twin scenario now calls `griffin_requirements::runtime_report((), root)`.
That report first validates `requirements/griffin_requirements.sysml` and checks
for the selected `Verify_GriffinRequirements` case. Rhai remains the executable
test backend; SysML is the normative requirement and threshold source.
That runtime suite enumerates all executable rule IDs, checks all 20 manifest
parts individually, verifies the relational layout report, executes the Moon
Base SI metric/metres/Y-up contract, validates the metres/Y-up policy catalog,
and exercises both sides of the payload and ramp limiter boundaries. Run it
through the already-running headful session with
the `RunScenario`/`RunRhai` API path; do not launch a second simulator just to
execute the suite.

### Run the scene

    .\target\debug\luncosim.exe --scene twins\astrobotic-griffin-1\scenes\griffin_1_surface_ops.usda

The old sandbox binary is not the target for this Twin. Use the production
luncosim binary and the default scene from twin.toml.

The Griffin wrapper keeps attitude command inputs and valve activities in USD.
`AttitudeActuation` selects the generic `SignedTorqueAllocator.mo` through
`info:sourceAsset`; Rhai does not duplicate its equations. The altimeter wrapper
also authors raw ray-return output ports, so composed USD wiring supplies the
sensor evidence consumed by Modelica navigation.

The mission GNC scope also wires the generic `any_leg_contact` signal. This is
what allows the reusable controller to request a physical go-around when a
leg touches down outside the marked target; it is not a scripted pose reset.

### Run the bounded headless check

    .\target\debug\luncosim.exe test --scene twins\astrobotic-griffin-1\scenes\griffin_1_surface_ops.usda --max-ticks 14400 --tick-hz 60 --verdict-channel GRIFFIN_SURFACE_OPS

Exit code 0 means the Rhai scenario emitted PASS. Exit code 1 means a
terminal runtime or scenario failure. Exit code 2 means the bound expired
without a verdict. The current 14,400-tick run reaches terminal descent with
valid raw-ray navigation and RCS activity, but the strict target/velocity
touchdown gates do not yet emit the typed touchdown event. This is the active
prototype result, not a mission PASS; no acceptance threshold is relaxed.
Keep the failure evidence from `griffin_surface_ops::landing_gate_report()`
with the run while tuning the generic guidance/physics boundary.

## What the MVP demonstrates

The current stable boundary demonstrates:

1. A Twin-local package resolves through twin:// references.
2. Griffin and FLIP are reusable USD wrappers, not Rust-only entities.
3. The lander owns its Modelica propulsion, attitude, sensor, and touchdown
   contracts.
4. The mission scene owns guidance wiring, landing target, camera, anchors,
   waypoint markers, and mission metadata.
5. The Griffin wrapper carries the source-backed public configuration that is
   useful for integration: 625 kg payload capacity, four landing legs, seven
   main engines, four propellant tanks, and an isogrid deck. It also carries a
   clearly labelled study configuration with side-mounted solar-array proxies,
   a top-deck adapter, and two optional ramps with paired rails. Geometry,
   mass properties, and mechanism details remain non-flight surrogates.
6. FLIP uses a four-wheel all-wheel-steer study topology with compound chassis
   collision, explicit wheel geometry, a vertical rear-deck solar-panel proxy,
   motor/gearbox, finite-EPS, and motor-thermal Modelica contracts. The wheel
   count and numeric values are proxy assumptions until FLIP ICD data is
   available.
7. The surface environment uses a typed `LunCoTerrainAPI`/DEM layer wired to
   the processed LROC NOBILE03 crop; the old flat `Ground` fixture is inactive.
8. The Rhai task tree expresses descent event waits, the selected direct-deck or
   optional-ramp egress path, adapter-joint release, and a post-release
   surface-transit → base-site route.
   The close-spaced transit and base-arc markers are authored to keep the
   current four-wheel proxy on a feasible turn path. Ramp approach and ramp
   exit remain authored route actions, but are not used as pre-release mission
   gates because an attached payload can own those sensors.

The active scene now keeps FLIP on a scene-level fixed top-deck adapter joint
during descent, confirms the authored egress path, then removes the live
adapter joint before the rover route begins.
Fixed-joint cargo is prevented from consuming route sensors before that
release. The ramps span the deck datum to the terrain plane and carry paired
edge rails. Astrolab's public material describes direct top-deck egress, so the
ramp branch is an optional Griffin study assumption rather than a FLIP ICD. The
historical six-wheel wrapper is retained as
`vehicles/flip.legacy-six-wheel.usda` for comparison, not as the active asset.
The generic joint regression passes after detach, but the FLIP-specific
vehicle body does not yet fall onto the surface or advance after release; a
runtime body-promotion/wake feature is needed before route completion can be
claimed. No timer-only PASS was added.

The headful Griffin-only Editor check exposed a second runtime boundary: the
current USD projector admits child `PhysicsCollisionAPI` geometry as loose
physics bodies instead of aggregating it into the lander's rigid body. The
wrapper therefore keeps collision schemas on every solid deck, panel, ramp,
rail, strut, pad, and hinge; the source contract is correct, but the live
viewport cannot be called physically accepted until compound-child admission
is fixed. See `research/griffin_1_vehicle_spec.md` for the acceptance gate and
the missing Rust capabilities.

## Interactive control contract

The mission starts with an explicit persistent control brief. Click the
vehicle in the viewport to possess it; the Command Deck and vehicle HUD remain
the authority/status surface. The Twin-local `griffin_controls` library also
provides `control_lander()`, `control_rover()`, `release_control()`,
`toggle_rover_autopilot()`, `start_rover_autopilot()`, and
`stop_rover_autopilot()` for the Rhai console. For FLIP steering, use
`griffin_controls::crab_walk()` for parallel angles on all four authored
steering joints, `griffin_controls::ackermann_steering()` for left/right
wheel-geometry correction on those four joints, or
`griffin_controls::toggle_rover_steering_mode()` to switch between them from
one command. Change the steering mode while FLIP is stopped; if it is moving,
the helper holds the brake until the crawl threshold is reached and reports
the active mode in the HUD. The HUD repeats these commands after rover
possession.

While the Griffin lander is possessed, `W/S` command pitch, `A/D` command roll,
`Q/E` command yaw, `Space` commands thrust, and `G` is the authored release
action. While FLIP is possessed, `W/S` drive, `A/D` steer, `Space` brakes, and
`F` toggles the authored rover route. `Escape`/`Backspace` releases the active
vehicle. Manual input disengages rover autopilot; the mission route remains a
separate, visible autopilot phase after adapter release.

The controls are a study interface, not a claim about the flight command
dictionary. The generic simulator still owns possession, input routing,
autopilot authority, and release semantics. The steering-mode helpers are
Twin-local live control commands: they stop a moving route, write the vehicle
Ackermann-strength attribute, and rely on the runtime's in-place four-wheel
resync. They are not yet a native replicated, undoable vehicle mode, and the
current topology does not provide a separate front-only Ackermann mode.

## Next required data

Replace the surrogates in this order:

1. Mission configuration: final launch window, landing site frame, landing
   coordinates, epoch, and mission timeline.
2. Griffin vehicle: dimensions, mass properties, propulsion thrust curve,
   propellant loads, attitude-actuator limits, leg geometry, and landing
   qualification thresholds.
3. FLIP: as-built dimensions, wheel/suspension geometry, mass properties,
   tire/traction model, actuator limits, battery, solar, thermal, payload
   interfaces, and command/telemetry dictionary.
4. Surface: registered DEM, slopes, illumination, hazards, regolith
   parameters, and a frame-transform validation report.
5. Operations: release mechanism, landed-state authority handoff, route,
   communications delays, power/thermal constraints, and payload activities.

Every replacement must update research/griffin_1_assumptions.md and add a
verification result that distinguishes sourced data from inferred values.
