# Griffin-1 Twin build handover

Status: implementation handover
Date: 2026-09-02
Repository baseline: LunCoSim main at 042f024679900c9916dc23ee52f0485ceae5392f
Working branch: codex/astrobotic-griffin-1-twin
Package: twins/astrobotic-griffin-1

## Executive result

The Griffin-1 package now exists as a self-contained LunCoSim Twin package. It
parses successfully, resolves Twin-local USD references, composes the current
Modelica lander chain and a four-wheel FLIP study proxy, and includes a
Griffin-local patrol behavior tree.

The package is intentionally not marked as a completed flight-stack
simulation. The earlier fixed-joint attempt used the six-wheel rover and
produced a terminal escaped-body failure in the current Avian solver. The
active prototype now uses a four-wheel FLIP proxy, a scene-level fixed
top-deck adapter joint through descent, two finite-mass physical side ramps,
and an interactive joint release after touchdown. The ramp mechanism is a
MoonDAO prototype requirement; public Astrolab material describes direct
top-deck egress and does not publish a ramp ICD.

The historical staged Griffin scenario reported PASS at 3,983 ticks / 66.38
simulated seconds with the installed
`luncosim 0.6.0-nightly.64.1 (042f0246)` binary. That result predates the
attached-ramp and interactive adapter-release changes. The current production
run reaches landing, ramp deployment, adapter release, and FLIP autopilot
engagement, then expires NO-VERDICT at 7,200 ticks / 120 simulated seconds
because FLIP remains at its release pose and emits no post-release waypoint
events. No timer-only PASS was added.

## Mission baseline

As of this handover, the primary public sources say:

- NASA calls the mission Moon Base II / Astrobotic Griffin-1.
- The mission is planned for 2026 and targets the lunar South-Pole region and
  Nobile Crater.
- Griffin is planned to carry more than 1,100 lb of cargo, including
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
| environment | environments/south_pole_surrogate.usda | deterministic flat collision plane and visual berms |
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
| 6 | Author a deterministic South-Pole environment | Done; procedural surrogate, not a DEM |
| 7 | Compose celestial anchor and landing frame | Done; explicit study values |
| 8 | Compose guided lander and sensor/GNC wires | Done using PositionPIDGuidance |
| 9 | Compose waypoint markers and rover patrol policy | Done using EngageAutopilot and Griffin-local BTXML route |
| 10 | Test physical lander/FLIP attachment | Active prototype uses an explicit fixed adapter joint; bounded validation below |
| 11 | Establish a stable MVP boundary | Done; attached descent, interactive release, and physical ramps |
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
fixed adapter joint during descent. After touchdown the scenario commands both
physical revolute ramp hinges, waits for deployment, removes the live adapter
joint with interactive intent, and engages the Griffin-local surface route.

Command:

    .\target\debug\luncosim.exe test --scene twins\astrobotic-griffin-1\scenes\griffin_1_surface_ops.usda --max-ticks 14400 --tick-hz 60 --verdict-channel GRIFFIN_SURFACE_OPS

Result: the current run reaches `griffin_touchdown_confirmed`,
`griffin_ramps_deploy_commanded`, `griffin_ramp_deployment_settled`,
`griffin_flip_released`, and `griffin_flip_deployed`, then expires
NO-VERDICT at 7,200 ticks / 120 simulated seconds. FLIP is owned by its
vehicle controller after release but remains at approximately its release
pose, so no post-release waypoint events arrive. This is an integration
acceptance boundary for the authored proxy, not flight validation.

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
- the South-Pole terrain is explicitly a procedural surrogate;
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
5. Both ramps deploy through their revolute joints and the rover reaches the
   deck approach, ramp exit, surface waypoints, and base site through the
   supported control surface.
6. GRIFFIN_SURFACE_OPS emits PASS with a reproducible command and seed.
7. A jittered and multi-thread diagnostic run is recorded separately from the
   deterministic single-thread gate.
