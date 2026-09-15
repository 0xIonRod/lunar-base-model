# Griffin-1 Twin build handover

> **Current status (2026-09-10): superseded implementation notes below.**
> This document now ends with the authoritative next-agent handover. The old
> historical notes are retained for provenance, but their PASS claims and
> FreeCAD-based workflow must not be used as current acceptance evidence.

Status: temporary implementation handover; **Griffin rebuild not complete**
Working branch: `codex/astrobotic-griffin-1-twin`
Package: `twins/astrobotic-griffin-1`

## Executive result

The latest incremental pass keeps the runtime boundary generic: raw altimeter
ray outputs are authored as USD ports, detached joint paths are recorded on
generic physics endpoints, and the lander attitude loop uses measured
navigation position rather than the ballistic prediction channel. Griffin
selects the reusable signed RCS allocator through USD `info:sourceAsset`. The
target COM datum is 3.98 m in both SysML and the composed scene, and the GNC
scope now receives the generic `any_leg_contact` recovery signal. A full
14,400-tick run still stops in the landing watchdog with NO-VERDICT; this is an
open control/physics issue, not an acceptance result.

The Griffin-1 package now exists as a self-contained LunCoSim Twin package. It
parses successfully, resolves Twin-local USD references, composes the current
Modelica lander chain and a four-wheel FLIP study proxy, and includes a
Griffin-local patrol behavior tree.

The package is intentionally not marked as a completed flight-stack
simulation. The earlier fixed-joint attempt used the six-wheel rover and
produced a terminal escaped-body failure in the current Avian solver. The
active prototype now uses a four-wheel FLIP proxy, a scene-level fixed
top-deck adapter joint through descent, two solid integrated side ramps with
paired rails, and an interactive joint release after touchdown. The ramp
mechanism is a MoonDAO prototype requirement; public Astrolab material
describes direct top-deck egress and does not publish a ramp ICD.

The historical staged Griffin scenario reported PASS at 3,983 ticks / 66.38
simulated seconds with the installed
`luncosim 0.6.0-nightly.64.1 (042f0246)` binary. That result predates the
attached-ramp and interactive adapter-release changes. The current production
run reaches terminal descent with valid raw-ray navigation and RCS activity,
but the strict touchdown gates do not complete within the 14,400-tick bound.
No timer-only PASS was added.

## Mission baseline

As of this handover, the primary public sources say:

- NASA calls the mission Moon Base II / Astrobotic Griffin-1.
- The mission is planned for 2026 and targets the lunar South-Pole region and
  Nobile Crater.
- Griffin is planned to carry more than 499 kg of cargo, including
  Astrolab's FLIP rover.
- NASA's August 2026 update says Griffin-1 has completed mass-properties
  testing and is undergoing environmental testing at JPL.
- Astrobotic's June 2026 update says the integrated spacecraft is proceeding
  through environmental testing, with FLIP integration at the Florida launch
  processing site.
- Public Astrolab material describes FLIP as the FLEX Lunar Innovation Platform
  with nearly half a metric ton of mass and a 30 kg payload capacity.

These facts define mission identity only. They do not authorize copying generic
LunCoSim dimensions, masses, thrust curves, or wheel models into a flight
claim.

Primary sources:

- https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/
- https://www.nasa.gov/missions/moon-base/nasa-provides-updates-on-moon-base-cargo-landers-tech-demonstrations/
- https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/
- https://www.astrobotic.com/astrolabs-flip-rover-joins-astrobotics-griffin-1-to-the-moon/

## Implementation map

| Layer | File | Responsibility |
|---|---|---|
| identity | twin.toml | Twin name, version, default scene, scene glob |
| mission scene | scenes/griffin_1_surface_ops.usda | composition, frame anchor, GNC wires, camera, waypoints, target |
| lander wrapper | vehicles/griffin_1.usda | Griffin identity over the reusable descent lander |
| FLIP asset | vehicles/flip.usda | FLIP identity over the four-wheel all-wheel-steer study proxy, collision topology, solar panel, EPS, and thermal network |
| route | behaviors/griffin_1_flip_patrol.btxml | Scene-local ramp actions, surface-waypoint, and base-site route |
| terrain manifest | Assets.toml | pinned LROC NOBILE03 downloads and checksums; raw bytes are ignored |
| terrain adapter | tools/terrain/reproject_lroc_polar_dem.py | polar-stereo to runtime-local float32 GeoTIFF conversion |
| environment | environments/south_pole_surrogate.usda | DEM-backed NOBILE03 terrain container; legacy filename retained for scene compatibility |
| policy | scenarios/griffin_1_surface_ops.rhai | descent waits, deployment boundary, control brief, patrol route, verdict channel |
| controls | tools/griffin_controls.rhai | Twin-local lander/FLIP possession, release, and autopilot helpers |
| assumptions | research/griffin_1_assumptions.md | facts, surrogate values, and confidence boundaries |
| instructions | README.md | setup, build, parse, run, and replacement-data sequence |
| follow-up | agent_to_agent_missing.md | missing code and acceptance tests |

## Twelve implementation actions

| # | Action | State |
|---:|---|---|
| 1 | Create an isolated clean LunCoSim checkout | Done |
| 2 | Define the Twin package identity | Done in twin.toml |
| 3 | Record latest public Griffin and FLIP facts | Done in README and assumptions |
| 4 | Add a reusable Griffin lander wrapper | Done; generic descent lander is labelled surrogate |
| 5 | Add a reusable FLIP asset | Done; four-wheel all-wheel-steer study proxy with explicit EPS and thermal networks |
| 6 | Author a deterministic South-Pole environment | Done; NOBILE03 regional DEM wired through typed terrain APIs |
| 7 | Compose celestial anchor and landing frame | Done; explicit study values |
| 8 | Compose guided lander and sensor/GNC wires | Done using PositionPIDGuidance |
| 9 | Compose waypoint markers and rover patrol policy | Done using EngageAutopilot and Griffin-local BTXML route |
| 10 | Test physical lander/FLIP attachment | Active prototype uses an explicit fixed adapter joint; bounded validation below |
| 11 | Establish a stable MVP boundary | Done; attached descent, interactive release, and solid integrated ramp pose |
| 12 | Add handover, instructions, and evidence | Updated for the Griffin backlog prototype; flight fidelity remains open |

## Build procedure

Run from the repository root containing Cargo.toml and assets/.

On native Windows, the current celestial EOP build helper invokes date.exe.
Git for Windows supplies it at C:\Program Files\Git\usr\bin:

    $env:PATH = 'C:\Program Files\Git\usr\bin;' + $env:PATH
    cargo build -p lunco-luncosim --bin luncosim

This process-local PATH workaround was needed for the clean build. No source
change was made to celestial-eop-data. The build completed in about 14 minutes
37 seconds on the audited checkout.

## Verification evidence

### Source validation

Command:

    .\target\debug\luncosim.exe --validate twins\astrobotic-griffin-1\vehicles\griffin_1.usda twins\astrobotic-griffin-1\vehicles\flip.usda twins\astrobotic-griffin-1\environments\south_pole_surrogate.usda twins\astrobotic-griffin-1\scenarios\griffin_1_surface_ops.rhai twins\astrobotic-griffin-1\tools\griffin_controls.rhai twins\astrobotic-griffin-1\behaviors\griffin_1_flip_patrol.btxml

Result: PASS. All six Twin-local source files reported OK, including the
Griffin-local behavior tree and control library.

### Repository control

Scene: assets/scenes/tests/lander_rover_stack.usda

Result: PASS. The stock lander plus sprung rover stack emitted
LANDER_ROVER_STACK PASS at 547 ticks and 9.12 simulated seconds. This proves
the checkout can stabilize the generic fixed lander/rover stack.

### Guided stock-rover comparison

Scene: assets/scenes/luncosim/lander_ops.usda

Result: no verdict within the short 20-second comparison bound, but no
escaped-body terminal fault. It was not used as a Griffin PASS.

### Six-wheel independent-drive comparison

Scene: assets/scenes/tests/six_independent_parity.usda

Result: NO-VERDICT after the 500-second simulated bound. The asset compiled,
but its existing parity script did not provide a usable verdict in this
headless invocation. It was not selected for the production FLIP wrapper.

### Griffin fixed-joint attempt

The first Griffin scene attached FLIP with PhysicsFixedJoint and used the
independent six-wheel rover. The run produced:

    body left the world: /Griffin1SurfaceOps/Lander/LegPX

After switching to the supported six-wheel skid-steer implementation, the same
class of failure remained:

    body left the world: /Griffin1SurfaceOps/Lander/LegNZ
    position approximately (-351.1, -230.9, 125.5) m
    velocity approximately (-1115.2, -812.5, 990.1) m/s

The failure occurred at 100 simulated seconds in the 6,000-tick bound. This is
why the current MVP does not retain the physical joint.

### Griffin corrected integration path

The current scene composes FLIP on the Griffin top deck with a scene-level
fixed adapter joint during descent. After touchdown the scenario confirms both
solid integrated ramps in their authored deployed pose, removes the live
adapter joint with interactive intent, and engages the Griffin-local surface
route. The unstable independent rigid-body hinge path is not part of the
accepted runtime.

Command:

    .\target\debug\luncosim.exe test --scene twins\astrobotic-griffin-1\scenes\griffin_1_surface_ops.usda --max-ticks 14400 --tick-hz 60 --verdict-channel GRIFFIN_SURFACE_OPS

Result: the current 14,400-tick run reaches terminal descent with valid raw-ray
navigation and RCS activity, but the strict target/velocity touchdown gates do
not emit `lander_touchdown`; the watchdog therefore reports NO-VERDICT. This
is an integration acceptance boundary for the authored proxy, not flight
validation.

The production binary includes two relevant runtime corrections: nested vehicle
behavior is no longer collected by the parent scene, and waypoint sensors are
ignored while a candidate vehicle remains on a `PhysicsFixedJoint`. The trace
verified landing, both ramp commands, adapter release, and autopilot handoff.
A generic fixed-joint regression passes after detach, which narrows the
remaining issue to FLIP's vehicle-specific body admission/wake lifecycle. The
runtime still needs an explicit live physics-state query and a supported
release transition for raycast vehicles before the route can be accepted.

## Non-blocking runtime warnings

- DejaVuSans.ttf is absent from the clean checkout; this affects text rendering
  only.
- Scene tests force exact celestial cadence for determinism.
- Physics telemetry reaches max_channels 4096; extra state is not retained.
- The co-simulation graph contains algebraic loops that the runtime handles
  with a one-step delay. Timing claims must account for this.

## Cleanliness boundary

The package is clean in the architectural sense:

- mission facts are separated from simulator assumptions;
- no public FLIP mass or geometry is represented as measured in the generic
  LunCoSim asset;
- the South-Pole terrain is source-backed NOBILE03 relief with a documented
  regional study anchor; exact touchdown coordinates remain unresolved;
- downloaded and processed terrain bytes are ignored and reproducible from
  `Assets.toml` plus the checked-in adapter;
- frame anchor and epoch are authored rather than inferred;
- the FLIP asset is selected by USD reference, not Rust-side name matching;
- the failed jointed composition is not left as an apparently valid PASS.

The working branch contains the merged remote Griffin-2 FreeCAD study, the
source-only Editor cleanup that hides superseded horizontal solar hardware,
the matched vertical FLIP panel, and the Twin-local control library. The
FreeCAD file is a design-study input, not an executable Twin asset; its
`RampController` proxy also needs rehydration work before it can be treated as
an editable parametric source.

## Acceptance definition for the next handoff

Do not close this work until all of the following are true:

1. A source-backed Griffin lander/FLIP parameter manifest is added.
2. A landing transition test reports the three source-qualified events and
   validates their source paths.
3. The chosen flight-stack attachment stays within world bounds under guided
   descent.
4. FLIP release is a physical joint/state transition, not only a Rhai event.
5. Both authored ramps are solid, rail-equipped, and seated from the deck to
   the terrain plane; the rover reaches the deck approach, ramp exit, surface
   waypoints, and base site through the supported control surface.
6. GRIFFIN_SURFACE_OPS emits PASS with a reproducible command and seed.
7. A jittered and multi-thread diagnostic run is recorded separately from the
   deterministic single-thread gate.

---

# Authoritative next-agent addendum

## Mission

Build a Griffin-1 lander Twin that is visibly recognizable, physically
coherent enough for the supported LunCoSim runtime, and traceable to public
information. The next agent must finish the model itself, not merely improve
test wording or make the existing generic cylinder pass a lint.

The target is contract fidelity: a boxy lander body, deck and payload
interface, four landing legs, seven main-engine nozzles, four propellant-tank
proxies, two side egress ramps, solar hardware, communications hardware, RCS
hardware, and authored runtime subsystem boundaries. Unsupported numerical
details remain explicitly labelled Twin study assumptions.

## Non-negotiable operating rules

1. **Do not use the local FreeCAD model.** The `freecad/` tree and private
   reconstruction are historical material only. Do not inspect it for
   dimensions, convert it, or use it as geometry authority.
2. Use public/global references and clearly labelled Twin assumptions. Keep a
   source URL beside every public-derived contract value.
3. Do not hand-edit `.usda`/`.usd` text, patch a file behind an open document,
   use `SetDocumentSource`, or mutate ECS to force a visual result. Edit Rhai,
   Modelica, and documentation normally; author USD through the headful
   Editor's typed operation/document owner and save through that owner.
4. Do not hide obsolete placeholders. Delete authored placeholder prims with a
   typed `RemovePrim` operation. If a prim is inherited and cannot be removed
   from the target layer, record the capability gap and use a proper fork,
   reference, or future typed inherited-delete operation.
5. Do not create a second branch. Preserve unrelated dirty work. Shared skill
   changes were made on `terrain-streaming` and fast-forwarded to `main`;
   model work remains on `codex/astrobotic-griffin-1-twin`.
6. Use the existing headful production process. Do not launch a second binary
   for a component or assembly test, and do not close/reload the user's open
   documents while iterating.
7. Do not run the final test suite while model/tools/requirements are still
   being modified. After the last edit, run component, assembly, and runtime
   checks in the same process and record each evidence class separately.

The shared procedure is in the `author-rhai-tool`, `author-usd-component`,
`edit-usd-assembly`, and `compose-multidomain-twin` skills in LunCoSim `main`.

## Current repository state

### Model Twin

- Repository: `/home/rod/Documents/models/lunar-base-model`
- Branch: `codex/astrobotic-griffin-1-twin`
- Last committed model revision: `7bc16fd test(griffin): execute runtime contract suite`
- The working tree has intentional uncommitted Griffin changes. Inspect
  `git status` before editing and preserve unrelated changes.
- Relevant earlier commits:
  - `9c0dd2a feat(griffin): add executable contract catalog`
  - `037b6b1 feat(griffin): repair lander geometry through editor`
  - `7bc16fd test(griffin): execute runtime contract suite`
- The current uncommitted files include research/specification,
  requirements/contracts, scene, wrapper, Twin tools, and new CAD-style Rhai
  builders. They have not passed the final live visual/runtime gate.

### Shared skills

- Terrain worktree: `/home/rod/Documents/luncosim-workspace/terrain`
- Terrain branch: `terrain-streaming`
- Main worktree: `/home/rod/Documents/luncosim-workspace/main`
- Main and terrain point at `95079b4ae docs(skills): require typed live USD authoring`.
- Prior skill commit: `afde4ca74 docs(skills): define componentized USD assembly workflow`.
- Main contains unrelated dirty Rust/docs changes. Do not reset or clean them.
- New canonical skill:
  `/home/rod/Documents/luncosim-workspace/main/skills/author-rhai-tool/SKILL.md`
  with `skills/author-rhai-tool/references/tool-authoring-contract.md`.
- All changed skill folders passed
  `skill-creator/scripts/quick_validate.py`; installed aliases were not edited.
- Repository-local interactive authoring skill:
  `skills/interactive-component-authoring/SKILL.md`. It is the mandatory
  cycle for future visual work: one named component, one dry typed plan, one
  Editor batch, one same-generation projection/readback, one focused visual
  inspection, one Rhai/SysML gate, then an explicit save before the next task.

## Live session

Reuse the existing headful production binary:

```text
binary: /home/rod/Documents/luncosim-workspace/main/target/debug/luncosim
api:    http://127.0.0.1:37432
scene:  twins/astrobotic-griffin-1/scenes/griffin_1_editor.usda
```

The last known readiness state was `ready:true`, `world_hold:false`,
`faulted:false`, `pending_count:0`. Re-query `/api/ready` and
`ListOpenDocuments`; ids can change and must not be guessed.

Last known open documents:

| Document | Last known id | Role | Rule |
|---|---:|---|---|
| `griffin_1` / `vehicles/griffin_1.usda` | `111883701669039` | writable Griffin assembly | edit after fresh inspection |
| `descent_lander` | `111895678861192` | read-only global source inspection | do not modify |
| `UntitledStage-3.usda` | `111895797082559` | historical ramp component | historical id; re-discover before use |

The current incremental Editor session has independently exercised the visual
builder against the Griffin and FLIP previews. A bus-only plan was applied to
`griffin_1_visual` (generation 84 -> 85), then a chassis-only plan to
`flip_visual` (20 -> 21), then one front-left wheel task (21 -> 24). Each
change used a generation-checked `assembly_edit::batch`; the previews were
reopened through the typed `OpenUsdPreview` lease after projection invalidation,
not by restarting the simulator. Composed readback reported the authored bus
station `(0, 3.2, 0)` and FLIP front-left station `(-1.75, -0.42, -1.15)` with
`xformOp:rotateXYZ.y = -12 deg`. Dedicated Rhai fixtures passed for the bus,
chassis, and four-wheel contract; the full vehicle recipes remain available
only for a deliberate rebuild, not as the normal iteration unit.

The next isolated tasks added one typed visual suspension connector per active
wheel. Each `isolated_flip_component_plan_for(..., "Wheel_*"`)
produced only that wheel pose plus one `AddPrim`/attribute sequence beneath its
station; the successive preview generations were 35 (FL), 46 (RL), 57 (FR),
and 68 (RR). The focused readbacks all show render-only Cubes with local
scale `(0.14, 0.36, 0.14)`, local offset `(0, 0.20, 0)`, and collision
disabled; world station positions remain the SysML datums. The updated
`FlipWheelRequirements::Verify_FLIPWheelRequirements` gate now checks those
visual connectors as FWW-006 and passes 69/69 results with zero failures.

The remaining FLIP visual checkpoints were then run independently: a
`SensorMast` placement-only batch advanced the preview to generation 69 and
read back the mast root plus `MastPost`, `SensorHead`, `SensorAntenna`, and
`SensorLens`; the `FlipSensorPowerRequirements` gate passed 10/10. A separate
`SolarArray` placement/tilt batch advanced the preview to generation 71 and
read back the SysML mount `(0, 1.45, 1.30)` and tilt `18 deg`, with
`WhiteBacksheet`, `BlueCells`, and `FoldHinge` children; the same focused gate
passed 10/10. Both previews were renewed through typed `OpenUsdPreview` and
reported `projection_ready: true` at their final generations.

The next Griffin checkpoint was a single `TankPX` task. Its dry plan contained
only the SysML station placement `(1.30, 5.85, -1.15)`; the typed Editor batch
advanced the Griffin preview to generation 86. Readback confirmed the tank
root and its `MliTank`, three bands, and `TankCradle` children at that world
station, with `projection_ready: true` after the preview lease renewal.
`GriffinTankRequirements::Verify_GriffinTankRequirements` passed 30/30 with
zero failures. The other tank stations were not touched by this task.

The next lander tasks followed the same boundary. `LegPX` was authored alone
at `(1.75, 2.35, -1.25)` (generation 87) and read back with `StrutOuter`,
`StrutInner`, `ShockPiston`, and `FootPad`; its landing-leg gate passed 26/26.
`MainEngineCluster` then selected exactly seven engines, applied the SysML
stations and typed bell radii (generation 115), and its propulsion gate passed
48/48. Finally, port and starboard ramps were edited in separate batches
(generations 131 and 147). Each readback shows its own surface/rails/support,
mount plate, hinge pin, mount frame, and socket relationship; the independent
ramp gate passed 65/65 with no geometry, placement, or hinge failures.

The two Griffin solar-array tasks were also kept separate: `SolarPanelPort`
advanced the preview to generation 149 and read back `(2.70, 3.35, 0)` with
its frame/cells/dividers/mount bracket; `SolarPanelStarboard` advanced to
generation 151 and read back `(-2.70, 3.35, 0)` with the same child topology.
Both focused previews reached `projection_ready: true`, and the dedicated
`GriffinSolarRequirements::Verify_GriffinSolarRequirements` gate passed 16/16
after each task.

The last focused preview unexpectedly showed the descent-lander inspection
preview rather than Griffin. Refocus the Griffin preview using typed preview
commands before a screenshot. The old audit image is
`target/assembly-editor/griffin-current-audit.png`; it showed a generic tall
brown cylinder, two solar panels, thin legs, ramps, a top rail/plate, and an
oversized red flame. It is not acceptance evidence.

## Public reference boundary

Use and cite these public/global sources:

- [NASA CLPS deliveries](https://science.nasa.gov/lunar-science/clps-deliveries/)
  — Griffin is described as large and boxy.
- [Astrobotic Griffin Lander](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/)
  — medium-class lander, aluminum/isogrid deck language, dedicated adapter,
  optional egress ramps, four legs, seven main engines, attitude-control
  thruster clusters, communications, and solar hardware.
- [Astrobotic ramp/FLIP egress test](https://www.astrobotic.com/astrobotic-griffin-lander-and-nasas-viper-moon-rover-complete-complex-test-drives/)
  — sizeable ramps on both sides of the deck and a tested 33-degree egress
  condition.
- [NASA Griffin-1 gallery](https://www.nasa.gov/gallery/astrobotics-griffin-1/)
  — additional public mission imagery.

Treat dimensions, mass distribution, tank layout, exact engine spacing,
solar-array area, and RCS count/placement as Twin assumptions unless a source
directly supports them. The current four-tank count is a Twin contract/study
assumption unless a direct source is added to the research record; do not call
it a public fact.

## Required USD architecture

The assembly is a composition of explicit boundaries, not a flattened copy of
a tutorial or private CAD export.

### Assembly-owned facts

`vehicles/griffin_1.usda` owns the `/Griffin1` root and vehicle datum, root
mass/inertia and compound-body ownership, global/runtime references, component
reference identity, placement, mount datums, host-facing joints, solar-array
side placement, engine/tank/leg counts, cross-component connections, runtime
collection membership, and variant selections once typed variant authoring is
available.

### Component-owned facts

The first standalone component is:

```text
components/lander/egress_ramp.usda
```

It owns its local surface, edge rails, hinge/mount datum, mass/collision
policy, and deployment limit. The Griffin assembly owns the two instances,
their placement, host-facing revolute joints, and side-specific configuration.

Later boundaries may include solar array, landing leg, payload adapter, RCS
pod, and propulsion/tank subsystem when a useful independent contract exists.
Do not split one-off visual trim merely to create files.

### Runtime ownership

- USD owns topology, identity, frames, geometry, mass/inertia, joints,
  references, parameters, and connections.
- Modelica owns continuous propulsion, power, thermal, and control equations.
- SysML v2 owns normative requirement/verification intent and study thresholds;
  Rhai owns the read-only adapter, mission sequencing, and bounded executable
  runtime tests.
- Rust owns only generic document/typed-USD, projection, physics, and solver
  substrate. No Griffin-specific Rust behavior is authorized in this phase.

## Current tools and expected tool separation

Twin-local libraries include:

- `requirements/griffin_requirements.sysml`: standard requirement definitions,
  usages, study values, and the `Verify_GriffinRequirements` case;
- `griffin_spec.rhai`: read-only compatibility projection of SysML values and
  canonical parts/check IDs;
- `griffin_requirements.rhai`: read-only assembly requirements/layout reports;
- `griffin_flip_builder.rhai`: historical FLIP study helper only;
- `griffin_controls.rhai` and `griffin_surface_ops.rhai`: runtime policy;
- `scenarios/tests/griffin_requirements.rhai`: assembly test observer.

Maintain this separation:

```text
*_plan    pure typed operation construction; no mutation
*_report  read-only composed facts and structured errors
*_lint    read-only requirement gate; never repairs
*_test    bounded live observer; emits a real verdict
```

Register changed Twin tools with `RegisterToolLibrary` in the existing API
session. Verify `ListToolLibraries`, `GetToolLibrary`, and a minimal
`name::function(...)` call. The prior `griffin_cad_builder` registration was
visible in discovery, but a direct one-shot call returned `Module not found`;
diagnose active-Twin scope and engine-generation timing before proceeding. Do
not paste the tool source into every scenario as a workaround.

## Safe continuation sequence

1. Re-check status and `/api/ready`; do not run tests yet.
2. Query `ListOpenDocuments`, `ResolveUsdTarget`, `InspectUsdDocument`, the
   focused preview, and the composed Griffin root. Record fresh ids, edit
   target, authored layer, and generation.
3. Re-register Twin tools and verify both discovery and one minimal call in the
   already-running headful API session. Do not use a separate
   `luncosim --validate` process as runtime evidence. If the call still fails
   after a maintenance pass, record the bridge issue.
4. Inspect the standalone ramp document. Apply its pure plan with the exact
   target/generation through `assembly_edit::batch`; never author
   `xformOpOrder` manually. Query, screenshot, inspect, then save it as
   `components/lander/egress_ramp.usda` through `save_as_document`.
5. Remove the old authored `/Griffin1` root from the Griffin document with a
   typed operation so obsolete placeholders are deleted. If it is inherited,
   do not hide children; use the proper composition/fork path or report the
   inherited-delete gap.
6. Apply the new Griffin plan: boxy body, deck, adapter, four visible tanks,
   four legs/pads, seven nozzles, RCS pods, solar arrays, communications dish,
   and two ramp references.
7. Keep global/runtime references narrow. Do not reference the entire old
   descent lander root merely to obtain one subsystem if that reintroduces
   legacy geometry.
8. Query exact prims, references, joints, connections, and bounds. Capture and
   inspect a screenshot under `target/assembly-editor/`. Fix all source/tool/
   requirement issues before running tests.
9. Finish per-component requirement/test files. The ramp gate checks root/type,
   surface/rails, local mount datum, mass/collision policy, and deployment
   limit. The assembly gate checks reference identity, two placements, hinge
   endpoints, symmetry, clearance, and deletion of legacy names.
10. Only after all edits are finished, run component and assembly runtime tests
    through the same API session. Label preflight, typed projection, runtime,
    and visual evidence separately.
11. Save only after the visible checkpoint is acceptable; re-query dirty state
    and final generation. Leave the user's documents open.

## Executable requirements

At minimum, the assembly gate must measure:

- a visible rectangular/boxy airframe, not a tall cylinder;
- positive deck and payload-adapter geometry;
- exactly four landing legs, two on X sides and two on Z sides;
- each leg's body-side attachment, strut, pad, and ground clearance;
- exactly seven visible main-engine nozzle/cone prims under the cluster;
- exactly four visible tank proxies with paired symmetry;
- exactly two side egress ramps, mirrored, rail-equipped, and inside their
  deployment limit;
- two solar side assemblies with cell/frame structure and no legacy wings;
- explicit communications dish and attitude-control pod identities;
- one root rigid body, valid mass/inertia, and deliberate compound colliders;
- a typed host-facing joint for every nested moving body;
- source-qualified runtime references and required ports;
- no legacy `Hull`, `UpperDeck`, `SolarWingPX`, `SolarWingNX`, old leg/foot,
  or hidden flame placeholder;
- no duplicate prim/property names or unresolved references;
- public facts separated from Twin assumptions.

Negative cases must include missing nozzle, wrong engine count, wrong leg count,
non-mirrored leg, missing ramp rail, wrong ramp angle, missing reference target,
hidden legacy placeholder, duplicate name, invalid mass/inertia, missing
collider, nested body without a joint, and unavailable runtime port. A failing
test reports the exact path and reason and never repairs the stage.

## Rust features requested, but not implemented

No Rust changes were made for this model phase. The following generic features
would improve UX; the next agent should report them, not implement them without
a separately scoped request:

1. Reference-list operations: explicit generation-checked add/clear/replace
   operations for USD references with asset URI, target prim, inverse/undo,
   diagnostics, and readback.
2. Variant authoring: typed add/remove variant set, add variant branch, and
   author reviewed variant-block/reference opinions. `SetVariantSelection`
   only selects an existing variant.
3. Typed stage/prim metadata: author/read back `defaultPrim`, `kind`, and
   related standard metadata without raw source replacement.
4. Inherited deletion: a proper inherited-delete/reference-fork operation with
   clear layer semantics and undo; current `RemovePrim` is for authored target
   layer prims.
5. Tool-generation readiness: return active Twin scope, registry generation,
   and callable-engine readiness from registration, or expose a wait/query
   command. Discovery can currently succeed while a fresh `RunRhai` sees
   `Module not found` during static-module rebuild.
6. Component-save UX: a typed save flow that sets output path, `defaultPrim`,
   catalog metadata, and provenance in one reviewed document transaction.
7. Runtime tool compilation diagnostics: make registration compile/check the
   source in the active engine atomically, return the diagnostic on failure,
   and report active Twin scope, registry generation, discovered functions, and
   callable-engine readiness. Do not persist an apparently registered library
   with an empty function surface and no actionable error.

Do not add Griffin-specific commands, aliases, fallback geometry, raw file
writers, or direct ECS mutation to avoid these gaps.

## Final handoff checklist

Record `git status`, branch, commits, preserved dirty worktrees, binary/API
port, document/preview/view ids, edit targets, final generations, registered
tool names and minimal-call response, public URLs and assumption table,
component and assembly screenshots, typed count/reference/joint/collider/
connection queries, component and assembly verdicts from the same live process,
preflight results labelled as preflight only, all warnings/timeouts/unresolved
ports, and the exact remaining blocker if any. Record Telegram/Astra delivery
separately from local completion evidence if it was explicitly requested.

Leave the headful Editor open and wait for the next task only after this
checklist is complete.

---

# Current construction recipe for the next agent

This section is the authoritative continuation point for the unfinished
Griffin rebuild. This handover is temporary and must remain uncommitted. The
next agent should update it while working and delete or replace it when the
model is accepted.

## Goal and boundary

Build a new Twin-owned Griffin lander assembly that is visibly close to the
public Griffin silhouette and structurally legible in the Editor. The result
must be a composed USD assembly with explicit component boundaries, not a
flattened copy of the tutorial scene, the old descent lander airframe, or the
local FreeCAD study.

The required visible topology is:

```text
/Griffin1
├── BoxyAirframe
├── IsogridDeck/DeckPlate + rails
├── PayloadAdapter
├── TankPX, TankNX, TankPZ, TankNZ
├── LegPX, LegNX, LegPZ, LegNZ (each with Strut + Pad*)
├── SolarPanelPort, SolarPanelStarboard
├── Nozzle/MainEngineCluster/Engine01..Engine07
├── RcsPodPX, RcsPodNX, RcsPodPZ, RcsPodNZ
├── HighGainDish
├── EgressRampPort
└── EgressRampStarboard
```

The geometry, dimensions, tank arrangement, mass properties, and engine
spacing are Twin study values unless a public source explicitly supports them.
Record the source or assumption in the Twin contract; never present a study
value as a Griffin flight ICD.

## Worktree and process rules

- Work in `/home/rod/Documents/models/lunar-base-model` on
  `codex/astrobotic-griffin-1-twin`. Do not create a branch.
- The Twin is the canonical owner of Griffin geometry, requirements, builders,
  component files, and tests. Do not author new Griffin files in
  `luncosim-workspace/main`.
- Use `/home/rod/Documents/luncosim-workspace/main/target/debug/luncosim` only
  as the production binary. Shared Rust/skill work belongs on `terrain` and
  must be fast-forwarded to `main` only when separately requested.
- Keep the current headful process alive at `http://127.0.0.1:37432`. Do not
  launch a second binary, use `--validate` as runtime evidence, or close and
  reopen the user's Editor documents.
- Do not run the final requirements/tests until all model, tool, and contract
  edits are complete. During authoring, use only source review, tool
  registration, typed plans, document inspection, and screenshots.
- Do not edit USD text. All USD mutation goes through a Rhai plan lowered to
  typed `UsdOp` values and submitted by `assembly_edit::batch` with the exact
  document generation.

## Fresh audit before touching anything

Run only these read-only checks first:

```sh
curl -s http://127.0.0.1:37432/api/ready | jq .
curl -s -X POST http://127.0.0.1:37432/api/commands \
  -H 'content-type: application/json' \
  -d '{"type":"ExecuteCommand","command":"ListOpenDocuments","params":{}}' | jq .
```

Then inspect the current Griffin document and focused preview using the returned
`doc_id`; never reuse the historical IDs in this document. Capture a fresh
viewport screenshot before authoring. The previous generic-cylinder image is
only a defect record, not acceptance evidence.

Record:

- exact Griffin `doc_id`, origin, writable state, `@root@` generation, and
  focused `UsdPreviewId`;
- whether `/Griffin1` is authored in the target layer or inherited through a
  reference;
- current composed children, references, schemas, joints, and connections;
- preview `projection_ready` and the screenshot path.

If `/Griffin1` is inherited, do not pretend that `RemovePrim` deletes it. Use
the explicit inherited-delete/fork capability if available; otherwise report
the Rust gap and do not hide the old geometry.

## Repair the live builder before using it

The current Twin tool is
`twins/astrobotic-griffin-1/tools/griffin_cad_builder.rhai`. It is intended to
be a pure operation planner:

```text
griffin_cad_builder::egress_ramp_plan("@root@")
griffin_cad_builder::lander_plan("@root@", "twin://astrobotic-griffin-1/components/lander/egress_ramp.usda")
```

The helper functions return arrays of typed operation maps. They do not mutate
the caller's array. Before registration, replace every old call of the form
`add_geom(ops, ...)`, `schema(ops, ...)`, `add_frame(ops, ...)`, `add_ref(ops,
...)`, `add_float(ops, ...)`, `add_string(ops, ...)`, `add_bool(ops, ...)`, or
`add_connection(ops, ...)` with explicit accumulation:

```rhai
ops = ops + add_geom(edit_target, parent, name, type_name, dims,
    translation, rotation, scale, color, collision, role);
```

`add_frame` and `add_geom` now return operations, so calculate the path
separately with `path_join(parent, name)` whenever a later operation needs it.
The plan must return `ok: true` and a non-empty `ops` array. Remove duplicate
`let ops = [];` declarations and all stale `ops.push`/old-signature calls.

Register the changed library in the existing process, then prove both
discovery and invocation:

```sh
jq -n --rawfile source twins/astrobotic-griffin-1/tools/griffin_cad_builder.rhai \
  '{type:"ExecuteCommand",command:"RegisterToolLibrary",params:{name:"griffin_cad_builder",source:$source}}' \
| curl -s -X POST http://127.0.0.1:37432/api/commands \
    -H 'content-type: application/json' -d @- | jq .
```

Use a same-session `RunRhai` call to print `plan.ok`, `plan.kind`, and
`plan.ops.len()`. A successful `ListToolLibraries` entry with an empty
function list or a failed namespaced call is a blocker; do not work around it
by pasting the source into a scenario or by starting another process.

## Build the standalone ramp first

1. In the Editor, focus the intended new untitled USD document. Query its exact
   `doc_id`, `@root@` generation, and preview readiness.
2. Call `egress_ramp_plan("@root@")` in `RunRhai` and inspect the returned plan.
   It must contain `/EgressRamp`, one rigid body, `Surface`, both edge rails,
   `HingeBlock`, and `MountSocket`.
3. Pass the returned `ops` to `assembly_edit::batch(doc_id, label, ops,
   parent_gen)`. Do not call `ApplyUsdOp` repeatedly for a compound component.
4. Wait for projection readiness, inspect the composed component, and capture a
   screenshot under `target/assembly-editor/egress-ramp-*.png`.
5. Save through the Editor document owner as
   `twins/astrobotic-griffin-1/components/lander/egress_ramp.usda`. Do not
   write this file with a shell, script, or direct USD serializer.
6. Re-query the saved document and use its canonical Twin URI in the assembly
   plan. If `defaultPrim` or component metadata cannot be authored through the
   typed surface, record that Rust gap instead of replacing the source text.

The component's deployment limit is 0.58 rad (33 degrees) for this Twin study.
The ramp assembly owns the two instance transforms and host-facing joints; the
standalone component owns only local geometry, mass/collision policy, and its
hinge datum.

## Build the lander assembly second

1. On the Griffin document, inspect and remove the old authored `/Griffin1`
   root with one typed structural operation. Delete obsolete placeholders;
   never hide them with visibility, purpose, or a disabled render flag.
2. Re-query the document generation after deletion. Do not reuse the old
   generation in the next batch.
3. Call `lander_plan("@root@", ramp_uri)` and review its full operation map.
   The plan must contain local box/deck/leg/tank/engine/solar/RCS geometry,
   narrow runtime subsystem references, two ramp references, two typed
   `PhysicsRevoluteJoint` prims, and the required root connections.
4. Submit the complete plan as one `assembly_edit::batch` change set. The
   assembly document owns placement, references, sockets, joints, and cross-
   subsystem connections; the ramp file remains a separate composition asset.
5. Wait for projection readiness. Inspect exact paths and references, then
   capture a headful screenshot from the focused Griffin preview. Fix geometry
   or tool source while still in the authoring phase if anything is missing.

The old global descent lander may be referenced only for narrow runtime
equation/sensor boundaries that are already known to the controller. Do not
reference its whole airframe or its legacy Hull/SolidLeg/SolarWing/Nozzle/flame
visuals into Griffin.

## Checks after the final edit only

When the component and assembly source/tools/contracts are finished, run all
checks in the same headful session. The required order is:

1. `egress_ramp_requirements::lint(doc_id, "/EgressRamp")` and its boundary
   checks;
2. `griffin_requirements::lint(doc_id, "/Griffin1")`;
3. the negative cases through disposable typed fixtures or plans, including
   missing nozzle, wrong counts, missing rail, wrong angle, asymmetric legs,
   missing references, duplicate names, invalid body/collider topology, and
   unavailable runtime ports;
4. the assembly runtime scenario/test observer in the current process;
5. `CaptureScreenshot` and `view_image` for final visual acceptance.

The checks must emit structured findings with exact paths and must never repair
the document. `--validate`, a clean parse, `ListToolLibraries`, or a green
build can be recorded as preflight evidence only; none proves that the edited
live model passes.

## Evidence and stop conditions

The next agent may report completion only with:

- final `doc_id`, `@root@` generation, preview id, and projection readiness;
- the successful same-session tool registration and real namespaced call;
- typed inspection showing the complete component/assembly topology,
  references, joints, colliders, connections, and no legacy placeholders;
- component and final Griffin screenshots inspected from the headful Editor;
- ramp, Griffin, negative-case, and runtime verdicts from that same process;
- public source links and a separate table of study assumptions;
- explicit Rust capability gaps, if any, with no Rust code silently added.

If any of these is missing, leave the handover open and report the exact
blocker. Keep all documents open for the next agent.
