# Agent-to-agent missing-code report: Griffin-1 Twin

Date: 2026-09-18
Owner of this handover: implementation agent
Next owner: LunCoSim mission/Twin agent
Baseline: 042f024679900c9916dc23ee52f0485ceae5392f
Branch: codex/astrobotic-griffin-1-twin

## Current revision

The active package is a four-wheel all-wheel-steer FLIP study proxy with
compound collision, frame-mounted vertical solar-panel geometry, explicit
Modelica EPS and thermal networks, a scene-level fixed top-deck adapter, and
two typed physical ramp components. The render-only ramps additionally expose
typed underside beams, edge posts, traction treads, hinge collars, and
inboard hinge gussets through GRR-014/GRR-015. The supported `AcquireControl` command
now drives the released rover through the complete landing → deployment →
egress → survey → base-site sequence. The latest deterministic production run
reports `GRIFFIN_SURFACE_OPS PASS` at 5,525 ticks / 92.08 simulated seconds
with 11 structured checks and zero failures. The flight-attached joint,
supplier FLIP ICD, and exact Griffin touchdown coordinate remain open; the
regional Nobile03 DEM is integrated through a checked-in reprojection adapter.

## Handoff in one paragraph

The Twin package is source-valid and now has an end-to-end prototype mission
verdict. The active boundary uses the four-wheel FLIP proxy, a scene-level
fixed top-deck adapter during descent, two typed physical side ramps, and
interactive release after touchdown. The older six-wheel joint failure and
staged NO-VERDICT remain below as historical evidence. The current PASS is a
simulation acceptance result, not a claim about released Griffin or FLIP ICD
data.

## Current follow-up gaps from the SysML provenance pass (2026-09-17)

The Griffin/FLIP component requirements now have 155 unique IDs, authored
metric geometry datums, explicit verification memberships, and a separate
typed `RequirementEvidence` catalog. The catalog is verified through the
qualified `source_with_attributes` path in the production Twin. The following
generic capabilities remain useful additions rather than Twin-specific fixes:

1. Add a native `ValidateSysml` provenance projection keyed by requirement ID
   that returns source reference, rationale, optional status, and source span
   in one bounded request. Implemented in the terrain validator as the opt-in
   `provenance_ids` compact projection, with the generic Rhai
   `sysml_requirements::provenance()` helper now consuming it. The normal
   compact path remains lazy and does not transport the catalog. This still
   needs the normal terrain-to-main fast-forward before other checkouts
   receive it.
2. Add a live Editor/Edit-perspective evidence command that captures the exact
   composed document generation, selected component path, source revision, and
   screenshot together. This pass now established the connected Edit
   perspective and read back the same document generation; only the one-shot
   evidence bundle remains missing.
3. Mission-runtime repair is complete for the current study boundary. The
   supported `AcquireControl` handoff, ramp deployment, FLIP release, and
   Ackermann route now pass in one deterministic production run. The current
   historical failure evidence follows for regression context:
   reaches the supported `AcquireControl` handoff, ramp deployment, FLIP
   release/deployment, and Ackermann route start, then emits a structured
   route-stall verdict. The current deterministic replay with the typed
   world-down ray-frame repair and the SysML-derived 1.21 m transition plates
   stops at tick 2637 (43.78 s), with `target=(10.5,0,0)`,
   `pose=(0.7814989929538841,7.148665844483091,-0.7791807818896852)`,
   `support_contact_count=1`, and `height_above_terrain=7.027 m`.
   Native `QueryPhysicsState.wheel_contacts` evidence now proves the bridge is
   using `ray_direction=[0,-1,0]`, `ray_max_distance_m=1.200001247...`, and
   exact wheel/rover self-exclusion. The rear-left probe hits `/Lander` at
   1.1694 m while the other three report no hit. The 1.20 m physical
   suspension datum is active but does not by itself restore support. The
   remaining model defect is the deck-to-ramp interface: the hexagonal
   `TopDeckCollisionProxy` tapers to x = +/-3.16 m at the wheel plane while
   the ramp hinges are at x = +/-3.20 m, leaving a front-wheel transition
   gap. GRR-012 now specifies separate 1.21 m collision-enabled
   `TransitionPlate` children, authored by the typed Editor builder, to close
   that interface without changing the 8.00 m hinge-to-tip ramp datum. The
   applied geometry does not yet restore four-wheel support, so the remaining
   defect was upstream of the physical ramp transition and is now closed by
   the typed transition components and source-owned route policy. Do not reuse
   this historical failure as the active verdict.
   The latest corrected run reaches all 15 authored route markers and emits a
   structured `GRIFFIN_SURFACE_OPS PASS` with 11 checks, zero failures,
   `ticks=5525`, and `sim=92.08 s`.
4. Add a route-frame validation helper that checks marker coordinates against
   the active vehicle forward axis, ramp envelope, and terrain plane before
   the task starts. Implemented in `griffin_surface_ops::surface_route_preflight()`:
   it compares all 15 SysML marker datums with composed scene poses, rejects
   non-finite/degenerate terrain-plane markers, checks the first target against
   FLIP's horizontal forward hemisphere, and records the structured
   `GR-034-route-frame` result in the mission verdict. A generic route-frame
   helper remains useful for other Twin missions.
5. Keep the new control-command contract covered in the Twin acceptance path.
   `AcquireControl` now takes `target` and optional `bind_camera` (with
   `source` available for an explicit handoff); the old `PossessVessel`/`id`
   shape is rejected by schema validation. A live request against the visual
   Griffin assembly was accepted by the command layer and then correctly
   refused because that assembly exposes no writable input ports. In the
   physical mission scene, `AcquireControl(target=FLIP, bind_camera=true)` was
   accepted and a zeroed `SetPorts` write was accepted as well; the physical
   FLIP assembly is therefore the valid control target for the mission
   scenario.

6. Add a generic exclusion filter to the `Raycast` scene-query provider. The
   native wheel-contact bridge has exact physics-owned exclusions, but the
   generic Rhai `raycast({origin, dir, max})` query still returns the querying
   FLIP body at distance zero because it uses the default spatial filter. A
   typed `exclude_entities`/`exclude_api_ids` request and a compact collider
   admission readback would make generic evidence as trustworthy as the
   native wheel-contact record.

7. Add `.btxml` validation support to the generic `--validate` command. The
   Griffin behavior file is present and used by the Twin, but the current
   validator rejects it solely because its extension is unsupported; this is
   a tooling coverage gap, not a passing behavior validation.

8. Add a native mission-task completion result to the task runner. A child
   route task can emit a completion edge and return success, but a parent Rhai
   task that waits for those same already-emitted events can remain pending
   indefinitely. The Twin now avoids that pattern by using the ordered route
   child as the completion gate; a first-class child-result/status value would
   make this safe and observable for other missions.

9. Add an explicit `ensure_over`/target-layer override operation to the typed
   Editor assembly API. A composed scene can query an inherited nested prim,
   but a batch that sets an attribute or relationship on that nested path can
   currently fail with `path not found` when the scene has not authored an
   `over` for it. The Griffin builder had to update the existing scene-level
   ramp geometry and leave the inherited nested transition joint untouched;
   this should be a first-class, diagnostic-rich operation rather than a
   model-specific workaround.

10. Add runtime-overlay invalidation and provenance to the document lifecycle.
    A saved Editor layer can be correct on disk while a stale
    `.lunco/runtime` overlay is restored on the next headful launch and
    silently wins composition. This pass had to use the typed
    `ApplyUsdOp(ReplaceSource -> @runtime@)` command after each fresh open to
    remove the stale ramp metadata; clearing the overlay fixed the live
    evidence without touching authored USD. The native API should expose
    overlay generation/source revision in `ListOpenDocuments`, make
    `SaveDocument` reconcile or invalidate the overlay, and report a clear
    conflict instead of presenting stale geometry.

11. Make `SaveDocument` and `SaveAsDocument` report terminal typed results.
    In the live Editor, both commands were admitted as `pending` without a
    terminal `CommandOutcome`; the document could therefore remain reported
    dirty even when the owner-side write path had run. Implemented in the
    terrain worktree's generic USD command owner: both commands are deferred,
    record terminal outcomes, return the written path and generation, reset the
    file watermark, and emit `DocumentSaved` only after persistence. This still
    needs the normal terrain-to-main fast-forward before other checkouts
    receive it.

12. Add a typed `ClearPrimSpec`/"remove only this layer's local opinion"
    operation. `RemovePrim` correctly authors a tombstone, but that also masks
    a same-path child supplied by a referenced component. Implemented in the
    terrain worktree and exercised through the headful Editor: the Griffin
    assembly now keeps only the ramp references and mount/interface metadata,
    while `griffin_ramp_visual.usda` owns all 31 replaceable ramp children,
    including the eight edge-support posts. The operation must mutate the
    canonical authored `sdf::Data` directly; transient Stage cleanup can leave
    empty placeholder prim specs and does not recompose a live dependent stage.
    Fresh open currently restores the composed component correctly; native
    runtime projection still needs explicit dependency invalidation for this
    new operation.

13. Make typed command routing owner-aware for shared command names. A
    `SaveDocument` sent to the open SysML document was dispatched to the USD
    owner and returned `unknown USD document`, even though the SysML document
    was valid and its edit had already reached the source file. The command
    catalog needs one typed dispatcher with document-kind routing, terminal
    diagnostics, and no owner-order dependence.

14. Preserve Twin context when opening an isolated USD component preview.
    A FLIP source document containing a valid
    `twin://astrobotic-griffin-1/components/rover/...` reference resolved in
    the Twin assembly, but the isolated preview rewrote the root asset to a
    `twin://__viewport_DocumentId_...` asset and then reported the Twin-local
    component as missing. The preview service should carry the mounted Twin
    asset resolver/context into temporary overlay documents, or show an
    explicit unresolved-reference diagnostic before presenting a blank part.

15. Make authored mission Scope/program attachment observable in the test
    runner. The Griffin ramp scenario mounted the Twin and reached a ready
    scripting prelude, but a `LunCoProgramAPI` Mission Scope with a Twin-local
    `info:implementationSource` produced no scenario-attach trace and no
    verdict before the tick bound expired. The runner needs a typed attach
    result (owner, source asset, generation, and failure reason) so a missing
    program cannot look like a silent `NO-VERDICT` timeout.

16. Expose viewport image readiness and render-target dimensions in the typed
    inspection contract. `InspectUsdViewport` currently reports projection and
    stage-generation readiness, but not the actual render-target width/height,
    image generation, or whether the displayed image belongs to the focused
    preview. After a Twin preview replacement, a stale secondary target can
    therefore appear as a blurred model even while `projection_ready` is true.
    The native query should return target dimensions, image generation, and a
    focused-preview/image identity so Editor automation can wait for the real
    frame and diagnose undersized or stale targets deterministically.

17. Make Twin-local test-program attachment observable in the headless runner.
    On 2026-09-18 the production binary mounted the Griffin Twin and opened all
    SysML sources, but a positive `GriffinBusRequirements` run with a
    `twin://astrobotic-griffin-1/scenarios/tests/griffin_bus_requirements.rhai`
    `info:sourceAsset` produced no scenario-attach trace and ended as
    `NO-VERDICT`, rather than returning a typed attach/load error. The runner
    needs an explicit result containing the program owner, source URI,
    document generation, and failure reason so an unavailable Twin-local
    observer cannot be confused with a geometry verdict. This is a runner/core
    observability gap; it is not a reason to add a negative geometry test.

## Existing package

The package is at twins/astrobotic-griffin-1:

- scenes/griffin_1_surface_ops.usda: mission composition
- vehicles/griffin_1.usda: reusable Griffin lander wrapper
- vehicles/flip.usda: four-wheel FLIP study wrapper with Modelica EPS/thermal networks
- environments/lunar_surface_base.usda: twin-local gravity/sun/contact preamble
- environments/south_pole_surrogate.usda: DEM-backed NOBILE03 surface container
- Assets.toml: pinned LROC downloads and checksums
- terrain/nobile03/: ignored processed heightfield output
- tools/terrain/: checked-in polar reprojection adapter and workflow
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

The environment now uses an official LROC NAC DTM NOBILE03 source product. It
is a source-backed regional terrain study, not the exact Griffin touchdown
site. The raw polar-stereographic source is downloaded from `Assets.toml` and
converted by `tools/terrain/reproject_lroc_polar_dem.py` into the runtime's
current local GeoTIFF contract. The raw and processed bytes are intentionally
ignored by Git and must be regenerated from the manifest.

Add:

- the registered NOBILE03 DEM and its source checksums;
- horizontal and vertical datum;
- landing-site origin and orientation;
- solar azimuth/elevation and epoch;
- hazard and slope layers;
- regolith friction, restitution, sinkage, and bearing assumptions;
- a numeric surface report and processing parameters;
- a native polar-stereo reprojection and vertical-datum contract in Rust.

Retain the old flat-site fixture only as a deterministic development fixture;
it is inactive in the Griffin composed environment.

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
2. Implemented in the terrain core on 2026-09-17: `QueryPhysicsState` now
   exposes typed `wheel_contacts` snapshots published by raycast mobility.
   Each record carries the stable wheel path/API id, effective Avian hit
   collider path/API id, hit distance and normal, validity decision, normal
   force, suspension compression, tire force, and sample tick. The Griffin
   Rhai settle/stall evidence includes this array. Remaining work is to add
   equivalent evidence for jointed-wheel realizations and current joint
   ownership, if a future Griffin configuration uses them.
3. Waypoint arrival should be phase-scoped and joint-aware by default. An
   attached payload must not consume ramp or surface sensors, and route
   ownership should be visible in the emitted event metadata.
4. The supported control primitive is now `AcquireControl` with
   `ReleaseControlSource`; the old `PossessVessel` spelling is not registered
   by the production command catalog. The command works for Griffin/FLIP, but
   possession should still expose a vehicle-control deck with the active
   vehicle, bound input channels, autopilot authority, and release state so
   the mission does not have to rebuild that operator-facing contract in
   Twin-local Rhai.
5. Vehicle steering needs a native mode-aware control surface. Physical FLIP
   steering actuators currently live on synthesized joint entities rather than
   the authored wheel prims, so Rhai cannot address them as stable wheel
   handles. The Twin-local helper now uses the vehicle-root
   `physxVehicleAckermannSteering:strength` live-edit path to resync all four
   authored steering joints in place: `0.0` is parallel crab walk and `1.0` is
   the runtime's full left/right wheel-geometry correction. A native API should
   expose an explicit steering mode, axle roles (front-only/all-wheel), stable
   readback, replication, and undo semantics instead of making a mode out of a
   scalar actuator setting.
6. Solar generation needs a frame-aware Sun direction and panel-normal
   contract. The FLIP panel is now vertical rear-deck geometry for the polar
   study, but the simplified electrical model still needs dynamic incidence
   wiring to make illumination physically meaningful.
7. The assembly editor needs stable source-preview handles and a viewport
   inspection query in the production command surface. The documented query
   is unavailable in the installed binary, so visual review currently relies
   on focusing the dedicated source preview and capturing it.
8. The environment-light persistence observer previously skipped render-only
   exposure/bloom edits when no sun field was present. The terrain worktree now
   guards all render-only, ambient, and Earthshine-only requests before the
   persistence path; the rebuilt production binary was relinked successfully
   on 2026-09-17, but the persistence behavior still needs a dedicated live
   regression check.
9. The body-imagery loader needs a checked-in asset fallback or a clear
   degraded-rendering status. The current headful runtime reports missing
   `lunco://textures/earth.png` and `lunco://textures/moon.png`, which leaves
   the scene untextured and can make the lighting read as overexposed during
   visual review.

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

- On 2026-09-18, after fast-forwarding `terrain/` to `main` at
  `ab6e3a00d`, a fresh `cargo check -p lunco-luncosim --bin luncosim` stops in
  `lunco-core`: `lib.rs` declares `ids`, `log`, `mocks`, and `telemetry`, but
  those source modules are absent from the `main` tree. The same failure also
  leaves the command-contract re-exports and core plugin registrations
  unresolved. This prevents a new production binary; keep using the existing
  headful binary only for Editor/Rhai iteration until the owning core change is
  restored or repaired. Do not turn this into a Rust test with embedded Twin
  assets.
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

## Typed SysML/Rhai/Modelica bridge gaps (2026-09-18)

Implemented in the terrain worktree's pure SysML projection:

- standard-aware primitive, structured, quantity, enumeration, collection, and
  multiplicity descriptors;
- unit-bearing quantity literals with finite f64 values;
- Modelica-compatible scalar/enumeration/Real-array/structured classification;
- native Rhai projection of semantic positions to the existing f64 `DVec3`
  and typed quantity/enumeration values.

Remaining generic Rust/tool capabilities required before the Griffin assembly
can be rebuilt from those contracts:

1. Connect the native SysML value projection to the production world-query
   bridge. The current `ValidateSysml` API is JSON-shaped for transport; the
   runtime needs a typed query path that returns the existing f64 Rhai values
   without a stringify/parse round trip.
2. Add a shared f64 `Transform`/`Bounds`/frame type and a single explicit
   f64-to-Bevy-f32 render projection. Do not let SysML or Modelica author
   Bevy f32 transforms directly.
3. Add unit conversion and dimensional arithmetic for quantity kinds. The
   current adapter preserves unit labels and values but does not yet prove
   `mm + m`, derived units, or incompatible-unit rejection.
4. Add typed records and N-dimensional collection values for SysML structured
   attributes, then map compatible records to Modelica records/parameters.
5. Add semantic support for redefinition, subsetting, derived features,
   constraints, and expression evaluation. Unresolved expressions currently
   remain explicitly unresolved rather than being guessed by Rhai.
6. Add a typed component/assembly contract: parent-owned placement, stable
   mount frames, pose/configuration variants, visual/physics ownership, and
   composed bounds/topology queries.
7. Add a production geometry verifier for winding/normals, duplicate ownership,
   intersections, clearances, panel/rail symmetry, leg contact, and articulated
   ramp states. Name/path checks alone are insufficient for Griffin acceptance.
8. Repair the current terrain `lunco-core` API boundary before production
   rebuild: the dirty tree declares missing `ids`, `log`, `mocks`, and
   `telemetry` modules and has incomplete command-contract re-exports.
9. Keep large-asset and visual acceptance tests in Rhai/Editor runtime. Rust
   tests should cover pure typed conversion and semantic projection only; they
   must not embed Griffin/USD assets.
10. Carry USD prim identity across the Rhai/query boundary as a validated
    `UsdPrimPath`-compatible value, not a concatenated string. The core already
    has a `UsdPrimPath` Bevy component, but public `QueryUsdPrim` and
    `QueryUsdPrims` currently deserialize `path`/`paths` only from JSON
    strings. Add typed Rhai path construction/child resolution and a typed
    query binding, with string conversion confined to the wire adapter. This
    keeps SysML component identities typed through scene lookup and makes
    malformed paths unrepresentable before the query call.

## Typed spatial geometry and Griffin authoring batch (2026-09-19)

The terrain worktree now has an in-progress generic foundation for the Griffin
visual requirements and geometry workflow. This section supersedes the older
items above where the same capability is listed as wholly missing; it does not
claim mission or visual acceptance.

- Native `f64` `Vec2`, `Vec3`, `Quat`, `Transform`, axis-aligned bounds,
  oriented bounds, and separating-axis results are exposed to production Rhai.
- SysML typed Cartesian vector literals project to those native spatial values;
  the Griffin visual configuration now describes its six-point body profile,
  dimensions, stations, and configuration choices with SysML types rather than
  CSV/string-packed geometry.
- A generic convex-profile extrusion kernel returns indexed closed-prism
  topology and explicit outward face-varying normals. The Griffin builder
  derives its hexagonal bus/skirt profile from SysML and consumes that kernel.
- Bus verification reports structured deck/skirt oriented-box clearance and
  compares generated profile topology/points with composed geometry.
- A read-only Editor checkpoint binds a requested generation to the exact
  preview/view, composed-path readback, lint, and a final generation check.
  Screenshot and requirement-verdict binding are still separate.
- The spatial geometry regression is a production-Rhai test; Twin geometry is
  kept in Twin-owned requirement and scenario files rather than Rust fixtures.

Still required for a credible Griffin design and acceptance:

1. Run every changed Griffin/FLIP component gate against the freshly built
   production runtime, then run the landed surface-operations mission and
   inspect its structured verdict. Build/readiness alone is not acceptance.
2. Review the actual Editor render of the body, frame, tanks, legs, panels, and
   stowed/deployed ramps. Mesh topology and OBB envelopes do not prove the
   silhouette, correct component ownership, contact geometry, or visual
   recognizability.
3. Add a generic mesh/primitive measurement and intersection report using
   composed geometry, source layer, and world transform; the present oriented
   box audit only proves the explicit envelopes supplied by the Twin.
4. Add atomic Gprim replacement and reusable generic ring/bracket/rounded-box
   and material recipes. BREP is still not needed for the current open-frame
   study; it becomes valuable only for exact curved intersections, Boolean
   cuts, or fabrication-quality fillets.
5. Bind screenshot identity and declared component-verification results to the
   same document/projected generation as the Editor checkpoint.
6. Continue generic SysML work for dimensional unit conversion/arithmetic,
   records/structured values, derived/constraint expressions, and typed USD
   prim paths at the Rhai query boundary.

No authored Griffin scene has been saved as part of this batch yet. Any live
Editor change must go through the Editor's typed operations in Edit
perspective; do not modify a USD layer by hand.
