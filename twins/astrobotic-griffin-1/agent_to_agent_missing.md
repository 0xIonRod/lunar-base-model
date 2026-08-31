# Agent-to-agent missing-code report: Griffin-1 Twin

Date: 2026-08-30
Owner of this handover: implementation agent
Next owner: LunCoSim mission/Twin agent
Baseline: 042f024679900c9916dc23ee52f0485ceae5392f
Branch: codex/astrobotic-griffin-1-twin

## Current revision

The active package was corrected on 2026-08-30. `vehicles/flip.usda` is now a
four-wheel all-wheel-steer FLIP study proxy with explicit Modelica EPS and
thermal networks; `behaviors/griffin_1_flip_patrol.btxml` owns the scene-local
route. The original staged baseline reported `GRIFFIN_SURFACE_OPS PASS` at
3,983 ticks / 66.38 simulated seconds; that result predates the physical ramp
and attached-adapter re-qualification and must not be reused as the active
prototype verdict. Current source preflight is clean, while the final
post-adapter route run remains pending. The flight-attached joint, supplier
FLIP ICD, and Nobile DEM also remain open.

## Handoff in one paragraph

The Twin package is authored and source-valid, but it is not an end-to-end
flight-stack acceptance product. The active boundary uses the four-wheel FLIP
proxy, a scene-level fixed top-deck adapter during descent, two physical side
ramps, and interactive release after touchdown. The older six-wheel joint
failure and staged NO-VERDICT are retained below as historical evidence. The
current post-adapter route still requires a fresh runtime verdict; do not
reuse the historical PASS or claim mission completion until that run passes.

## Existing package

The package is at twins/astrobotic-griffin-1:

- scenes/griffin_1_surface_ops.usda: mission composition
- vehicles/griffin_1.usda: reusable Griffin lander wrapper
- vehicles/flip.usda: four-wheel FLIP study wrapper with Modelica EPS/thermal networks
- environments/lunar_surface_base.usda: twin-local gravity/sun/contact preamble
- environments/south_pole_surrogate.usda: labelled procedural surface
- scenarios/griffin_1_surface_ops.rhai: task-tree mission policy
- research/griffin_1_assumptions.md: data confidence record
- README.md: setup and run instructions
- handover.md: full evidence handover

## Historical Priority 0 evidence: payload attachment contract

Observed result:

- Stock assets/scenes/tests/lander_rover_stack.usda passes with the generic
  lander and skid rover.
- The guided Griffin composition with a six-wheel FLIP fixed joint produces
  body-left-world terminal failures.
- The failure persists after switching from six_wheel_independent.usda to the
  supported six_wheel_rover.usda.
- Reducing the wrapper mass to the stock 1,000 kg regime prevented the short
  fault but was rejected as an unvalidated physical override.
- The pre-correction scene therefore removed the joint and surface-staged FLIP.
  The active scene now uses a scene-level fixed adapter joint and releases it
  interactively after touchdown; re-qualification remains open.

Required implementation:

1. Add a payload configuration layer that defines whether FLIP is
   flight-attached, surface-staged, or test-only.
2. Make the flight-attached configuration explicit in USD, not inferred by a
   script path.
3. Define how the payload mass, center of mass, and inertia are aggregated
   into the lander body and into the Modelica guidance mass input.
4. Define a stable constraint topology. A fixed joint between two articulated
   assemblies must not create a solver island that ejects the lander legs.
5. Add a bounded body-escape diagnostic that reports the first failed body,
   phase, joint state, mass properties, and last valid pose.
6. Add a dedicated test scene that runs only the flight-attached configuration.
7. Keep the staged configuration as a valid fallback, but never let it report
   the flight-attached test as PASS.

Likely files to inspect:

- assets/scenes/tests/lander_rover_stack.usda
- assets/scenes/luncosim/lander_ops.usda
- assets/vessels/landers/descent_lander.usda
- assets/vessels/rovers/six_wheel_rover.usda
- crates/lunco-physics
- crates/lunco-usd-sim
- crates/lunco-scripting/src/world_bridge.rs

## Priority 1: prove the mission event chain

The Griffin Rhai task waits for:

- lander_engine_cutoff from /Griffin1SurfaceOps/Lander/GNC
- lander_flight_handoff from /Griffin1SurfaceOps/Lander/GNC
- lander_touchdown from /Griffin1SurfaceOps/Lander
- three waypoint.reached events from FLIP

The staged 6,000-tick run did not reach GRIFFIN_SURFACE_OPS PASS. The runtime
did not expose enough phase detail to say whether the missing transition is
guidance, touchdown qualification, event source routing, deployment, or rover
navigation.

Required implementation:

1. Add a Griffin acceptance observer, modelled on
   assets/scenarios/tests/descent_lander_runtime.rhai, that records each event
   name, source gid, source path, and simulation time.
2. Add a failure verdict for each missing event after a separate phase timeout.
3. Check source paths with the same strictness as the stock acceptance test.
4. Check that the final rover pose is within the final marker radius.
5. Check that the route command is accepted by the six-wheel rover's actual
   drive ports.
6. Keep mission policy in task-tree Rhai; do not use on_tick as a controller.
7. If a task-tree leaf fails at runtime, surface the error in the headless
   runner instead of leaving NO-VERDICT.

## Priority 2: make FLIP data-driven

Public information is insufficient for a flight model. The current wrapper
selects the supported six-wheel vehicle only to obtain a working surface
topology.

Add a Twin-local manifest, for example research/flip_parameters.toml or
research/flip_parameters.usda, with:

- as-built dimensions and wheelbase
- dry mass, payload mass, center of mass, and full inertia tensor
- wheel radius, width, suspension travel, and contact model
- maximum wheel torque, speed, and control update rate
- battery energy, solar generation, thermal limits, and payload power
- communications endpoints and latency assumptions
- camera and navigation sensor fields of view and update rates
- payload mounting points and release hardware
- evidence source and confidence per parameter

Every parameter needs one of: measured, supplier-provided, public estimate,
simulator assumption, or unknown. Unknown must not silently become zero.

## Priority 3: replace generic Griffin vehicle data

vehicles/griffin_1.usda currently wraps the reusable generic descent lander.
That is useful for graph integration but cannot represent Griffin performance.

Replace or override, with evidence:

- dimensions and collider envelope
- landing-leg geometry and pad locations
- total and time-varying mass
- center of mass and principal inertia
- main engine thrust and throttle envelope
- RCS torque limits and propellant flow
- tank capacity and depletion behavior
- altimeter/IMU characteristics
- guidance limits and landing qualification thresholds
- communications and ground-operations endpoints

The wrapper's parameter_status metadata must be changed only when the
replacement is supported by a source.

## Priority 4: terrain and frame fidelity

The current environment is intentionally flat with visual berms. It is not a
Nobile Crater DEM.

Add:

- a registered DEM or height field with provenance;
- horizontal and vertical datum;
- landing-site origin and orientation;
- solar azimuth/elevation and epoch;
- hazard and slope layers;
- regolith friction, restitution, sinkage, and bearing assumptions;
- a validation image or numeric surface report.

Retain the current flat-site scene as a deterministic development fixture.

## Priority 5: surface-operations realism

The current task demonstrates route policy only. Add real mission operations:

- physical payload release mechanism;
- landed-state authority handoff;
- rover boot and comms acquisition;
- solar/power budget;
- thermal survival and payload warm-up;
- wheel dust and mobility constraints;
- science/payload activity events;
- safe-mode and lost-link behavior;
- command latency and operator acknowledgment;
- route replanning and hazard avoidance.

These should be authored as ports, events, and task-tree policy with tests.

## Acceptance test matrix

| Test | Required result |
|---|---|
| four-file validation | every Twin-local USD/Rhai file reports OK |
| clean package load | no unresolved Twin-local asset |
| generic fixed stack control | stock LANDER_ROVER_STACK remains PASS |
| FLIP standalone | six-wheel control and camera contract have a verdict |
| guided Griffin lander | no escaped body through landing bound |
| jointed Griffin stack | PASS only after attachment contract is stable |
| landing event chain | all three events with correct sources |
| physical release | joint/state change observed, not only emitted event |
| route | all markers reached in order |
| final mission | GRIFFIN_SURFACE_OPS PASS |
| jitter diagnostic | result recorded separately from deterministic gate |
| threaded diagnostic | result recorded separately from single-thread gate |
| provenance review | no assumption presented as measured mission data |

## Known runtime/build issues

- Native Windows build needs Git's date.exe on PATH for the current
  celestial-eop-data build helper.
- The test runner forces exact celestial cadence and warns about cost.
- Physics telemetry reaches max_channels 4096.
- Several current co-simulation connections contain algebraic loops and are
  solved with a one-step delay.
- DejaVuSans.ttf is absent in the clean checkout and affects text only.
- The independent six-wheel parity invocation exhausted its bound without a
  usable verdict; investigate its test lifecycle before reusing it as an
  acceptance gate.

## Safe continuation sequence

1. Preserve the current staged MVP and its NO-VERDICT evidence.
2. Add the event acceptance observer and run it on the staged scene.
3. Add a minimal flight-attached test scene with no route policy.
4. Instrument body-escape phase and payload aggregate properties.
5. Fix the solver topology or add a supported payload joint implementation.
6. Re-run the minimal attached scene.
7. Add release mechanics and verify a real state transition.
8. Re-enable the route, run the deterministic gate, then jitter/thread tests.
9. Update README, handover, assumptions, and this file with every data or
   contract change.
10. Commit the final state only when the acceptance matrix is satisfied.

## Do not do

- Do not copy public FLIP mass into the generic asset without provenance.
- Do not call a surface-staged rover a successful flight-stack deployment.
- Do not use timer-only PASS logic to hide missing events.
- Do not reintroduce the failed fixed joint without a bounded runtime test.
- Do not modify unrelated dirty repositories or stale worktrees.
- Do not use the old sandbox binary as evidence for the production Twin.
