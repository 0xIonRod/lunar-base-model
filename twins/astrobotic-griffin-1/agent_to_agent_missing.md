# Agent-to-agent missing-code report: Griffin-1 Twin

Date: 2026-09-02
Owner of this handover: implementation agent
Next owner: LunCoSim mission/Twin agent
Baseline: 042f024679900c9916dc23ee52f0485ceae5392f
Branch: codex/astrobotic-griffin-1-twin

## Current revision

The active package was corrected on 2026-08-30. `vehicles/flip.usda` is now a
four-wheel all-wheel-steer FLIP study proxy with compound collision,
frame-mounted vertical solar-panel geometry, explicit Modelica EPS and thermal
networks; `behaviors/griffin_1_flip_patrol.btxml` owns the scene-local route,
and `tools/griffin_controls.rhai` exposes the lander/rover handoff. The
original staged baseline reported `GRIFFIN_SURFACE_OPS PASS` at 3,983 ticks /
66.38 simulated seconds; that result predates the physical ramp and
attached-adapter re-qualification and must not be reused as the active
prototype verdict. The current production run reaches release and autopilot
engagement, then expires NO-VERDICT because the FLIP body does not advance
after detach. The flight-attached joint, supplier FLIP ICD, and Nobile DEM
also remain open.

## Handoff in one paragraph

The Twin package is authored and source-valid, but it is not an end-to-end
flight-stack acceptance product. The active boundary uses the four-wheel FLIP
proxy, a scene-level fixed top-deck adapter during descent, two physical side
ramps, and interactive release after touchdown. The older six-wheel joint
failure and staged NO-VERDICT are retained below as historical evidence. The
current production run reaches adapter release and autopilot engagement, then
expires NO-VERDICT because FLIP does not advance after detach; do not reuse the
historical PASS or claim mission completion until that lifecycle is repaired.

## Existing package

The package is at twins/astrobotic-griffin-1:

- scenes/griffin_1_surface_ops.usda: mission composition
- vehicles/griffin_1.usda: reusable Griffin lander wrapper
- vehicles/flip.usda: four-wheel FLIP study wrapper with Modelica EPS/thermal networks
- environments/lunar_surface_base.usda: twin-local gravity/sun/contact preamble
- environments/south_pole_surrogate.usda: labelled procedural surface
- scenarios/griffin_1_surface_ops.rhai: task-tree mission policy
- tools/griffin_controls.rhai: Twin-local lander/rover control and handoff helpers
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
5. Check that the route command is accepted by FLIP's actual drive ports.
6. Keep mission policy in task-tree Rhai; do not use on_tick as a controller.
7. If a task-tree leaf fails at runtime, surface the error in the headless
   runner instead of leaving NO-VERDICT.

## Priority 2: make FLIP data-driven

Public information is insufficient for a flight model. The current wrapper
uses a four-wheel all-wheel-steer study proxy only to obtain a working surface
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

## Rust/runtime feedback from this build

The Twin-local Rhai layer is sufficient for mission sequencing, visible
briefings, possession requests, autopilot requests, and typed source edits.
The following production features are missing or too implicit for a reliable
lander-to-rover handoff:

1. `DetachJoint` needs a vehicle-aware release transition that invalidates the
   old physics island and promotes/wakes a released raycast vehicle body. A
   generic rigid-body detach regression passes, but FLIP remains at its
   adapter pose after the same lifecycle.
2. Rhai/API needs a live physics-state query exposing body mode, velocity,
   contacts, wheel contact/suspension state, and current joint ownership. The
   current script can observe events and command ports, but cannot explain this
   failure without temporary instrumentation.
3. Waypoint arrival should be phase-scoped and joint-aware by default. An
   attached payload must not consume ramp or surface sensors, and route
   ownership should be visible in the emitted event metadata.
4. Possession should expose a vehicle-control deck with the active vehicle,
   bound input channels, autopilot authority, and release state. Generic
   `PossessVessel` works as a primitive, but the mission currently has to
   rebuild the operator-facing contract in Twin-local Rhai.
5. Vehicle steering needs a native mode-aware control surface. The Twin-local
   helper currently uses reflected `SteeringActuator.max_steer_angle` and
   `SteeringActuator.ackermann_strength` to implement one-command front-only
   Ackermann versus all-wheel parallel crab steering, but that state is live
   actuator tuning rather than an authored, replicated, undoable vehicle mode.
6. Solar generation needs a frame-aware Sun direction and panel-normal
   contract. The FLIP panel is now vertical rear-deck geometry for the polar
   study, but the simplified electrical model still needs dynamic incidence
   wiring to make illumination physically meaningful.
7. The assembly editor needs stable source-preview handles and a viewport
   inspection query in the production command surface. The documented query
   is unavailable in the installed binary, so visual review currently relies
   on focusing the dedicated source preview and capturing it.

## Acceptance test matrix

| Test | Required result |
|---|---|
| six-file validation | every Twin-local USD/Rhai/BTXML file reports OK |
| clean package load | no unresolved Twin-local asset |
| generic fixed stack control | stock LANDER_ROVER_STACK remains PASS |
| FLIP standalone | four-wheel Ackermann control and camera contract have a verdict |
| guided Griffin lander | no escaped body through landing bound |
| jointed Griffin stack | PASS only after attachment contract is stable |
| landing event chain | all three events with correct sources |
| physical release | joint/state change observed, not only emitted event |
| route | all post-release markers reached in order |
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
