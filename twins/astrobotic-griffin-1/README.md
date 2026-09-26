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
- Astrobotic's current manifest lists the destination as Nobile Region 2026,
  while NASA describes launch as planned later this year. Neither publishes a
  surface landing timestamp. The scene's JD 2461395.5 TDB is therefore a
  deterministic study epoch, not a flight schedule.
- Astrobotic's Griffin-1 solar post records three arrays, transit Sun-pointing,
  and a surface Sun path contained in one mission quadrant. The June 2026
  integration image shows upright panels across adjacent lander faces in one
  sector. The Twin composes three referenced panel assemblies on the forward,
  beveled forward-starboard, and starboard faces. Their study stations, widths,
  support geometry, and surface appearance do not replace released installation
  dimensions, deployment limits, or electrical performance data.
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
- NASA, [NASA Provides Update on Moon Base Rovers, Landers, Missions](https://www.nasa.gov/news-release/nasa-provides-update-on-moon-base-rovers-landers-missions/)
- Astrobotic, [Moon Manifest: Nobile Region 2026](https://www.astrobotic.com/lunar-delivery/manifest/)
- Astrobotic, [Griffin-1 Lunar Lander Unveiled Ahead of Environmental Testing](https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/)
- Astrobotic, [Griffin-1 integration photo, June 15, 2026](https://www.astrobotic.com/wp-content/uploads/2026/06/26.06.15_Griffin-1_PressConference_1348_Edit-scaled.jpg)
- Astrobotic, [Griffin's Solar Setup for Space and Moon Missions](https://lnkd.in/p/dJHz9duN) ([canonical LinkedIn activity](https://www.linkedin.com/posts/astrobotic_two-solar-panels-integrated-to-griffin-just-activity-7450595533745975296-qBEA))
- Astrobotic, [Griffin lander current product page](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/)
- Astrolab/Astrobotic, [FLIP rover joins Griffin-1](https://www.astrobotic.com/astrolabs-flip-rover-joins-astrobotics-griffin-1-to-the-moon/)

## Package layout

| Path | Purpose |
|---|---|
| twin.toml | Twin identity and default scene |
| twin.toml `[[components]]` | Explicit component ownership: one SysML requirement source and one unique Rhai verification binding per lander/rover subassembly |
| Assets.toml | Reproducible LROC NOBILE03 download manifest and checksums |
| scenes/griffin_1_surface_ops.usda | Mission composition and USD topology |
| scenes/griffin_flip_visual.usda | Componentized headful review composition for Griffin and FLIP |
| scenes/griffin_1_editor.usda | Clean derived headful Editor scene containing only the Griffin lander reference |
| vehicles/griffin_1.usda | Reusable Griffin lander wrapper around the LunCoSim descent lander |
| vehicles/flip.usda | Canonical FLIP study vehicle with mobility, chassis collision geometry, referenced visual components, EPS, and thermal networks |
| components/lander/ | Twin-local visual components for the bus, landing legs, tanks, panels, bells, and ramps |
| components/rover/ | Twin-local visual components for chassis, wheels, mast, and solar array |
| behaviors/griffin_1_flip_patrol.btxml | Griffin-local route tree targeting the deck approach, ramp exit, waypoints, and base site |
| environments/south_pole_surrogate.usda | DEM-backed NOBILE03 South-Pole environment |
| terrain/nobile03/ | Ignored processed heightfield output, regenerated from the manifest and adapter |
| tools/terrain/ | Polar-stereo download, reprojection, and provenance instructions |
| scenarios/griffin_1_surface_ops.rhai | Mission sequencing and route policy |
| scenarios/tests/griffin_requirements.rhai | Twin-owned structural/parameter verdict and boundary checks |
| scenarios/tests/griffin_lander_requirements.rhai | Rhai observer for the standalone lander-component contract |
| scenarios/tests/griffin_bus_requirements.rhai | Component-owned Rhai gate for bus geometry, tank-support openings, and source-owned appearance |
| scenarios/tests/griffin_landing_legs_requirements.rhai | Component-owned Rhai gate for the four landing legs |
| scenarios/tests/griffin_propulsion_requirements.rhai | Component-owned Rhai gate for the seven-engine bell cluster |
| scenarios/tests/griffin_tank_requirements.rhai | Component-owned Rhai gate for the four propellant tanks |
| scenarios/tests/griffin_solar_requirements.rhai | Component-owned Rhai gate for solar geometry; mission-window placement and transit attitude/power evidence are tracked in the implementation gap report |
| scenarios/tests/flip_requirements.rhai | Rhai observer for the standalone four-wheel FLIP contract |
| scenarios/tests/flip_chassis_requirements.rhai | Component-owned Rhai gate for the FLIP chassis |
| scenarios/tests/flip_wheel_requirements.rhai | Component-owned Rhai gate for the four directional wheel stations |
| scenarios/tests/flip_sensor_power_requirements.rhai | Component-owned Rhai gate for the FLIP sensor mast and solar array |
| scenarios/tests/griffin_ramp_requirements.rhai | Rhai observer for independent port/starboard ramp topology, placement, geometry, and deployment checks |
| LunCoSim `sysml_requirement_checks` | Shared typed observation records, SysML source helpers, provenance linking, and structured verdict formatting |
| tests/griffin_requirements.usda | Minimal composed fixture for the Griffin contract test |
| tests/griffin_lander_requirements.usda | Minimal Griffin-only fixture for the lander-component gate |
| tests/flip_requirements.usda | Minimal FLIP-only fixture for the rover-component gate |
| tests/griffin_*_requirements.usda | Editor-authored, one-component lander verification fixtures |
| tests/flip_*_requirements.usda | Editor-authored, one-component FLIP verification fixtures |
| tests/griffin_ramp_requirements.usda | Griffin-only fixture for the independent ramp gate |
| requirements/griffin_requirements.sysml | Griffin integration subjects, system requirement usages, mission context, and aggregate verification |
| requirements/griffin_functional_requirements.sysml | Functional and mission-interface requirements, including payload and adapter-release constraints |
| requirements/griffin_visual_requirements.sysml | Griffin visual presentation and evidence requirements |
| requirements/griffin_mechanical_requirements.sysml | Mechanical and physical-interface requirements |
| requirements/griffin_simulation_accuracy_requirements.sysml | Simulation accuracy, landing stability, and determinism requirements |
| requirements/griffin_assurance_requirements.sysml | Provenance, authoring, and evidence assurance requirements |
| requirements/griffin_lander_requirements.sysml | Standalone Griffin lander-component SysML v2 contract for bus, legs, tanks, engines, and solar arrays |
| requirements/griffin_bus_requirements.sysml | Bus-owned SysML v2 requirements and verification case |
| requirements/griffin_landing_legs_requirements.sysml | Landing-leg-owned SysML v2 requirements and verification case |
| requirements/griffin_propulsion_requirements.sysml | Propulsion-owned SysML v2 requirements and verification case |
| requirements/griffin_tank_requirements.sysml | Tank-owned SysML v2 requirements and verification case |
| requirements/griffin_solar_requirements.sysml | Griffin-array-owned SysML v2 requirements and verification case |
| requirements/griffin_requirement_sources.sysml | Typed, requirement-ID-keyed source and rationale catalog for every mounted requirement definition |
| tools/verify_requirement_sources.sh | Read-only authoring/CI gate for catalog coverage and complete typed evidence records |
| requirements/flip_requirements.sysml | Rover-owned FLIP SysML v2 values and visual verification case |
| requirements/flip_chassis_requirements.sysml | Chassis-owned SysML v2 requirements and verification case |
| requirements/flip_wheel_requirements.sysml | Wheel-owned SysML v2 requirements and verification case |
| requirements/flip_sensor_power_requirements.sysml | Sensor/power-owned SysML v2 requirements and verification case |
| requirements/griffin_ramp_requirements.sysml | Dedicated Griffin ramp subsystem requirements, metric envelope, hinge contract, and independent verification case |
| twin.toml `[verification]` | Single registry binding each qualified SysML verification to its Twin scene, Rhai observer, and verdict channel |
| contracts/ | Part contracts, verification boundary, standards/gap audit, and typed authoring procedure |
| contracts/implementation_gaps.md | SysML standards alignment, workaround inventory, Rust/Editor feature gaps, and Griffin migration order |
| contracts/verification.md | Active verification boundary, current constraint slice, and open physical-interface evidence gap |
| tools/griffin_spec.rhai | Rhai compatibility projection of limits read from the SysML source |
| tools/griffin_requirements.rhai | Stable public contract API, visual-only and physical part/layout audits, payload/ramp gates, and typed live-edit gate |
| tools/check_landing_determinism.sh | Twin-local two-process harness comparing the Rhai landing trial at a fixed SI clock |
| tools/griffin_visual_builder.rhai | Idempotent dry/apply runtime builder using generic `assembly_builder` + `assembly_edit` |
| tools/griffin_controls.rhai | Twin-local possession, handoff, and control briefing helpers |
| assets/models/LunCo/Actuation/SignedTorqueAllocator.mo | Reusable signed X/Y/Z RCS torque-to-valve allocator selected through the Griffin USD source-asset contract |
| ../../requirements/griffin-lander.md | Human-readable requirement IDs, provenance, and executable-check traceability |
| research/griffin_1_assumptions.md | Public facts, surrogate values, and confidence boundaries |
| handover.md | Detailed implementation and verification handover |
| instructions.md | Step-by-step setup and completion procedure |

Each component has the same three-part acceptance contract: its own SysML v2
file declares the requirement usages and verification case, its own Twin Rhai
observer performs read-only generic USD checks, and the existing Griffin-only
or FLIP-only fixture provides the composed stage. The observer is scoped to one
component even when the fixture contains its sibling visual components; no
combined mission gate can hide a component failure. Component packages reuse
canonical names/counts/dimensions from `griffin_lander_requirements.sysml` or
`flip_requirements.sysml` through qualified source-name attributes, so Rhai does
not carry a second geometry catalog. The same packages own the ordered metric
station datums; the builder and component observers both consume those lists
and the observers compare them with composed `xformOp:translate` values. The
generic evaluator rejects ambiguous short-name lookups instead of guessing and
indexes requirement/verification coverage once per report so detailed station
gates remain fast.

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

For Griffin work, open the integrated `vehicles/griffin_1.usda` source through
`scenes/griffin_1_editor.usda`; its visual components remain replaceable assets
under `components/lander/`. Edit one component at a time through a dry Rhai
plan and typed Editor batch, then inspect the composed result. Open
Open `vehicles/flip.usda` to edit the integrated FLIP vehicle. Its chassis,
wheel, suspension, mast, and solar geometry are referenced component assets
under `components/rover/`; vehicle-level physics and visual placements stay in
the same composed FLIP stage.
Follow the repository-local
[`interactive-component-authoring`](../../skills/interactive-component-authoring/SKILL.md)
cycle: one component plan, one Editor batch, one projection/readback, one
focused visual check, and one Rhai/SysML gate before moving on. The Twin
`griffin_visual_builder` library is a dry-plan and typed-apply facade; use its
component-scoped entry points for the current task rather than applying a whole
vehicle recipe. Each operation is journaled and saved through the Editor; never
rewrite scene or component USDA text by hand. Ramp geometry and FLIP wheel-path
verification remain tied to their shared SysML interface datums.

The combined `scenes/griffin_flip_visual.usda` review scene uses the same
source-backed `environments/south_pole_surrogate.usda` as the mission scene.
Its `Terrain` prim is bound to LunCoSim's canonical
`lunco://shaders/terrain_layered.wgsl` shader and the old `Ground/RegolithPad`
is retained only as an invisible, non-colliding measurement guide. To repair
or reapply this contract in a live Editor document, use the Twin-local
`griffin_visual_builder::apply_standard_terrain(doc_id, "@root@",
"/GriffinFlipVisual", parent_generation)` entry point through `RunRhai`; it
is idempotent, generation-checked, undoable, and persists through
`SaveDocument`. The visual Rhai gate verifies the terrain prim and shader
identity, so a flat proxy cannot silently replace the standard terrain.

`assembly_builder` remains the shared LunCoSim tool library. Do not copy it into
the Twin: a Twin-local file with that name would shadow the generic policy and
silently diverge from the shared authoring substrate.

### Build

On native Windows, the current EOP-data build helper expects the Unix date
utility. If Git for Windows is installed, build with its utility directory
temporarily prepended to PATH:

    $env:PATH = 'C:\Program Files\Git\usr\bin;' + $env:PATH
    cargo build -p lunco-luncosim --bin luncosim

The PATH change is process-local and does not change the repository.

### Parse/lint the Twin files

    .\target\debug\luncosim.exe --validate twins\astrobotic-griffin-1\requirements\griffin_requirements.sysml twins\astrobotic-griffin-1\requirements\griffin_lander_requirements.sysml twins\astrobotic-griffin-1\requirements\flip_requirements.sysml twins\astrobotic-griffin-1\requirements\griffin_ramp_requirements.sysml twins\astrobotic-griffin-1\requirements\moonbase_project_requirements.sysml twins\astrobotic-griffin-1\vehicles\griffin_1.usda twins\astrobotic-griffin-1\vehicles\flip.usda twins\astrobotic-griffin-1\environments\south_pole_surrogate.usda twins\astrobotic-griffin-1\scenarios\griffin_1_surface_ops.rhai twins\astrobotic-griffin-1\scenarios\tests\griffin_lander_requirements.rhai twins\astrobotic-griffin-1\scenarios\tests\flip_requirements.rhai twins\astrobotic-griffin-1\scenarios\tests\griffin_ramp_requirements.rhai twins\astrobotic-griffin-1\tools\griffin_controls.rhai

All supported source files listed above must report OK; `.btxml` is intentionally
omitted because the current generic validator does not yet support that
extension. The Twin requirements test below is the composed-stage check rather
than a text-only parse. The Rhai test also validates the same SysML source
through `ValidateSysml` before checking USD facts.

The separate typed provenance catalog is covered by a read-only authoring gate:

    bash twins/astrobotic-griffin-1/tools/verify_requirement_sources.sh

It compares requirement IDs from the owning Griffin, FLIP, and Moon Base
SysML documents with `RequirementEvidence` usages and checks that every usage
has a typed requirement ID, qualified requirement, source reference, and
rationale. This complements the runtime qualified lookup; it does not copy
those values into the Twin manifest or the Rhai check table.

### Run the Twin requirements test

The Griffin-specific structural lint is a Rhai tool owned by this Twin. It
checks the composed wrapper rather than parsing USDA text, and the test fixture
does not load terrain, FLIP, guidance, or the mission timeline:

    target/debug/luncosim test --scene /home/rod/Documents/models/lunar-base-model/twins/astrobotic-griffin-1/tests/griffin_requirements.usda --verification Griffin1Requirements::Verify_GriffinRequirements --max-ticks 120 --tick-hz 60 --threads 1 --jitter 0

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

`requirements/griffin_simulation_accuracy_requirements.sysml` owns the
landing-stability horizon and speed/drift/upright-axis bounds. The integration
source owns the separate repeatability tolerances. The Rhai contract test
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

* component-scoped `*_plan_for(...)` functions for one dry operation list;
* component-scoped `apply_*_component(...)` functions for one journaled
  `ApplyUsdOps` change set;
* aggregate plans only for inspection or a deliberate, reviewed rebuild.

The Griffin helper uses the generic LunCoSim `assembly_builder`/`assembly_edit`
surface, accepts Twin-local `twin://` references, and requires the parent frames
to be present before submission. The live Editor remains open; after each
small command is acknowledged, query the same document generation, inspect the
focused preview, and run the owning component gate. The aggregate
`griffin_flip_visual.rhai` gate verifies the canonical Griffin and FLIP vehicle
references after component edits. Wheel FWW-006 checks the shared suspension
component's type, metric offset/scale, render purpose, and disabled collision.
FLIP wheel stations and their component visuals live in `vehicles/flip.usda`;
the typed station identities and dimensions come from FlipRover SysML.

Assembly identities are read from typed SysML enumerations (`landingLegInstances`,
`tankInstances`, `rampInstances`, `solarArrayInstances`, and
`mainEngineInstances`) at test time. FLIP's own wheel identities remain owned
by its source model.
This keeps the component decomposition and the requirement source aligned
without baking a second identity catalog into Rhai. The test emits a
structured `<channel>_EVIDENCE` event before its normal
verdict line so the result can be paired with a same-generation composed query
and frame.

For the render-only Editor document, use
`griffin_requirements::visual_report_live(doc_id, "/Griffin1")`. It reports the
authored document generation, Edit perspective, SysML source revision,
component roots, leg/panel station transforms, and ramp load-path children.
The physical `lint_live`/`layout_report_live` functions remain intentionally
separate because the render document does not own flight mass or colliders.

The Twin scenario now calls `griffin_requirements::runtime_report((), root)`.
That report validates the Twin SysML source set and checks for the selected
`Verify_GriffinRequirements` case. The shared evaluator executes the supported
SysML constraint subset; Rhai binds composed observations and still owns
structural predicates whose generic USD-provider migration remains open.
The report distinguishes the authored requirement-check catalog from results
actually measured in this run. Payload and ramp boundary rows use their
focused SysML verification cases. The current suite checks all 20 manifest parts
individually, verifies the relational layout report, executes the Moon Base SI
metric/metres/Y-up contract, validates the metres/Y-up policy catalog, and
exercises both sides of the payload and ramp limiter boundaries. These results
do not imply that every requirement in the catalog was verified. Run it
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
5. The Griffin wrapper carries source-backed values useful for integration:
   625 kg payload capacity, four landing legs, seven main engines, and an
   octagonal payload deck. It composes the three adjacent solar-array faces
   shown in Griffin-1 integration imagery through one reusable referenced
   panel component. Their installed widths derive from ordered bus-rail pairs;
   stations and supports remain visual-study values. The four-tank set is
   also a Twin study assumption, not published flight configuration data.
   The wrapper includes a top-deck adapter and two optional ramps with paired
   rails. Geometry, mass properties, and mechanism details remain non-flight
   surrogates.
6. The canonical FLIP vehicle uses a four-wheel front-steer Ackermann study
   configuration with chassis collision geometry, explicit wheel assemblies,
   a rear-deck solar-panel proxy, motor/gearbox, finite-EPS, and motor-thermal
   Modelica contracts. Geometry, mass, and mobility values remain study
   assumptions until the FLIP ICD is available.
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
ramp branch is an optional Griffin study assumption rather than a FLIP ICD.
Both the review composition and test fixtures reference the canonical
`vehicles/flip.usda` vehicle.
The generic joint regression and the isolated FLIP adapter release now pass:
the live detach retires the native joint and graph edge (7 → 6), leaves the
28-body/30-collider population unchanged, wakes the released endpoint, and
stays topologically stable over the post-release observation window. Full
surface-route acceptance still requires the authored release input and route
arrival events; no timer-only PASS was added.

For long-run slowdown triage, sample the generic physics snapshot at phase
boundaries from the Rhai console:

    query("PhysicsPerformance", #{})

Compare `step_time_ms` with `bodies`, `colliders`, `joints`, and
`joint_graph_edges`. A detach must remove the native joint and graph edge while
leaving the body/collider population unchanged; a rising step time with stable
counts is solver/contact cost, while rising counts indicate lifecycle churn.
The isolated Rhai joint regression asserts this topology invariant.
The mission scenarios also declare exact event subscriptions, so high-rate
collision pulses are not repeatedly entered into their Rhai `on_event` hooks.

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
`griffin_controls::crab_walk()` for the parallel steering experiment,
`griffin_controls::ackermann_steering()` for the source-selected front-steer
Ackermann study mode, or
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
Ackermann-strength attribute, and rely on the runtime's in-place steering
resync. Public FLIP information does not specify the production steering
geometry, so this remains a simulation-study configuration.

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
