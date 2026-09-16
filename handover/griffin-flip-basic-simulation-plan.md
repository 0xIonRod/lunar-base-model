# Griffin-1 + FLIP basic simulation plan

**Updated:** 2026-09-11
**Shared-tooling snapshot:** `ba79950d618358004fafa1182f3c06c3e25a6d7e` (`main`, including `530b2a0be` explicit editor/physics workflow tools)
**Status:** planning and capability review; no asset or Rust changes made in this update
**Scope:** a visually credible, numerically inspectable surface-operations study Twin

## Executive decision

The current LunCoSim tooling is sufficient to build the first useful Griffin/FLIP
simulation without adding a Griffin-specific Rust subsystem or a full CAD system.
The right implementation is a staged authored-data workflow:

```text
USD components and assembly topology
        + Modelica continuous domains
        + Twin-local Rhai recipes and mission policy
        + Editor/API review, audit, and runtime verdicts
```

The previous failure mode was not a lack of primitive geometry. It was an
uncontrolled mixture of visual transforms, collision proxies, nested rigid
bodies, guessed joint frames, and scene-level placement edits. The updated
generic authoring tools now expose enough read-before-write and fail-closed
checks to prevent most of that class of error, provided the Twin recipe uses
them instead of writing ad-hoc geometry or guessing placement from screenshots.

This plan deliberately targets a **basic surface simulation**:

- Griffin body, landing legs, landing contact, and a bounded descent/settling
  demonstration;
- a four-wheel FLIP-like rover with recognizable chassis, wheels, drive
  components, solar array, and camera;
- rover mounted on the lander through one explicit payload adapter;
- authoritative release after touchdown;
- rover possession and bounded driving after release;
- enough electrical/thermal wiring to prove solar generation, battery state,
  and motor load;
- visual inspection and numeric verdicts that distinguish authored-asset,
  projection, and runtime-physics failures.

It is not a flight-certified Griffin model, a full CAD reconstruction, a
terramechanics validation, or a claim that public FLIP/Griffin dimensions are
complete. Assumed values must remain labelled in the Twin.

## What changed in the tooling

The live shared tooling in `main` now provides these reusable boundaries.

### USD authoring and editing

`assembly_edit` owns the document lifecycle, preview, typed operations,
proposal/review/commit, attachment/detachment, and undo/redo. Every stage edit
must carry an explicit document, edit target, exact USD path, and generation.
This is the correct path for scene changes; direct USDA rewriting should not be
used for live authoring.

The latest shared commit also adds `editor_workflow` and
`physics_acceptance`. These are important orchestration layers for this Twin:

- `editor_workflow` makes the inspect -> lint -> proposal -> commit ->
  after-edit checkpoint sequence explicit. It verifies the focused document,
  runs the admitted lint report, and captures post-commit state without
  silently saving a stale or unrelated preview.
- `physics_acceptance` provides reusable runtime evidence helpers for settling,
  contact, pose, velocity, and bounded motion checks. Griffin and FLIP verdicts
  should use these Rhai helpers rather than vehicle-specific checks in Rust.
- `assembly_ui` provides the corresponding explicit editor/physics workflow
  surface, so visual inspection can be tied to the same document and
  generation that produced the authored plan.

The recommended working loop is therefore:

```text
inspect exact document and topology
  -> run lint/preflight
  -> create dry typed plan
  -> review and commit one proposal
  -> verify projection and physics evidence
  -> save/capture only after the checkpoint
```

`assembly_builder` provides generic plans for:

- reusable referenced instances and ordered patterns;
- mirrored placements where the reflected pose is unambiguous;
- standard-schema property patches;
- cubes, cylinders, frames, rigid bodies, fixed joints, revolute joints,
  hinges, and component bundles;
- component mounts, socket/plug alignment, and existing-mount frame
  realignment;
- collision-bound alignment and placement with an explicit minimum clearance.

The important improvement is that placement can now use composed collision
bounds from `QueryUsdPrim { collision_bounds: true }`. That lets the payload
rover be seated against a lander deck using authored physical envelopes rather
than a hand-tuned visual offset. The helper remains conservative: it requires
an explicit common translation-only parent chain and rejects malformed,
missing, overlapping, or ambiguous bounds.

`component_bundle_plan` is suitable for small reusable parts and visual/collider
bundles. It can author standard geometry, collision roles, mass facts, named
frames, mount plugs, actuator endpoints, and explicit material bindings. It
does not create a complete moving mechanism, a Modelica declaration, a socket
occupancy policy, or a folding animation. Moving parts still require an
explicit rigid body and joint plan.

`component_bundle_update_plan` and `component_editor` allow a Twin-owned recipe
to update geometry, transforms, mass, ports, and explicit bindings while
preserving existing topology and material ownership. They reject topology
drift, role drift, material drift, and stale generations. This is the safe way
to iterate on FLIP proportions after the first accepted topology.

### USD inspection and physics audits

`QueryUsdPrim` now supports opt-in `topology:true` and
`collision_bounds:true`. The topology record reports composed visual and
collision parts, purposes, body owner, transforms, bounds, materials, joints,
projection state, and diagnostics. The collision query reports aggregate
envelopes owned by the composed asset.

`assembly_audit` provides read-only reports for:

- composed transforms and axis-aligned bounds;
- standard component/schema compliance;
- mount reciprocity and socket/plug contracts;
- joint body targets, axes, limits, and frames;
- rigid-body/joint coverage;
- collider/mass coverage;
- a fail-closed physicality manifest separating `physical` and
  `visual-only` parts.

These audits are the missing defense against the earlier “white thing works,
render mesh falls through” problem. A collision proxy may differ from render
geometry, but that difference must be explicit, owned, and inspectable. A
visual-only part must not silently carry a collision envelope.

The newest physics workflow does not replace these authored audits. It adds the
runtime half of the contract: first prove that the composed topology is valid,
then prove that the running bodies actually contact, settle, detach, and move.
For Griffin, a correct `PhysicsCollisionAPI` report can still coexist with a
bad initial pose, bad frame, or unstable touchdown.

### Vehicle and mobility support

The shared vehicle contract now has reusable chassis, wheel, tire, suspension,
motor, gearbox, shaft, battery, solar, thermal, camera, and control components.
The `skid_rover` structure is the starting exemplar. The four-wheel FLIP study
should begin with the raycast realization, because it has fewer moving rigid
bodies and is the fastest way to prove steering, wheel placement, controls,
and terrain contact.

The physical drivetrain is a later variant. It requires explicit wheel
carriers/joints and a parity test; it must not be introduced while the basic
raycast rover is still visually or numerically wrong. Wheel drive is bound by
explicit USD connections, not guessed by left/right parity or by a Rust motor
fallback.

### Modelica, Rhai, and multidomain ownership

- USD assembles objects, frames, masses, colliders, joints, references,
  variants, and native connections.
- Modelica owns continuous propulsion, guidance math, wheel/motor laws,
  battery/power, and thermal equations.
- Rhai owns Twin-local recipes, phase transitions, operator intent, release
  policy, and verdict orchestration.
- Rust remains the generic projection, physics, schema, port, and command
  substrate. It must not contain Griffin/FLIP names, geometry assumptions, or
  a second copy of Modelica/Rhai policy.

The electrical tooling also has a defined proof boundary: one explicit
network root, explicit component membership, direct panel-to-battery/motor
wiring, and observable generation, incidence, SOC, and current/power signals.
The generated Modelica wrapper is transient/read-only; the authored USD
network and stable program ports are the durable contract.

## Current Twin state and migration boundary

The Twin already has useful authored material:

- `vehicles/griffin_1.usda`, `griffin_body.usda`, and `griffin_leg.usda`;
- `vehicles/flip.usda` plus a legacy six-wheel reference;
- isolated FLIP, lander, no-joint, and delivery test scenes;
- `scenes/griffin_1_surface_ops.usda` with terrain, avatar, lighting, GNC,
  lander, FLIP, payload adapter, and route markers;
- Twin-local requirements, control, surface-operations, and builder scripts;
- a separate egress-ramp component and a delivery-release scenario.

The current baseline also exposes the risks that the new plan must address:

1. `twin.toml` points `default_scene` at
   `vehicles/griffin_1_standalone.usda`, which is not present in the current
   asset list. The manifest must point to an existing intentional entry scene
   before palette/default-scene acceptance.
2. The Twin-local `griffin_cad_builder.rhai` and
   `griffin_flip_builder.rhai` are legacy policy/geometry helpers. They should
   not remain a second geometry writer. Keep only a thin Twin-local recipe
   facade that calls generic `assembly_builder` plans, or retire each helper
   after its behavior is covered by a generic plan.
3. Existing delivery and surface-operation scenes are useful fixtures, but
   their runtime verdicts are not yet a passing integrated acceptance. A scene
   that composes or looks correct is not proof that touchdown, release, and
   rover motion work.
4. The FLIP file contains the correct direction of travel for a basic start
   but still needs topology and visual inspection with composed reports before
   any visual redesign. In particular, inspect wheel station frames, motor and
   gearbox placement, payload-deck placement, solar-array orientation, and
   every collision owner.
5. The current shared-tooling snapshot is ahead of the older baseline reviewed
   in the original handover. Use `editor_workflow` and `physics_acceptance` for
   new evidence; do not copy an older ad-hoc test loop into a new builder.
6. The surface scene uses a top-deck adapter and prototype ramp story. The
   ramp is a project assumption, not a confirmed public FLIP interface. Keep
   it optional and clearly labelled.

Do not restore the discarded broad rewrite. Work from the clean committed
baseline and make narrow, reviewed authoring changes.

## Revised implementation sequence

### Phase 0 — establish a trustworthy baseline

1. Correct the Twin entry-scene contract through the normal authored workflow
   so `twin.toml` opens the intended scene. Do not solve this by adding a fake
   standalone asset.
2. Run `ValidateTwin`/`ValidateAsset` as preflight for reference closure,
   namespaces, standard schemas, and known linter rules. Treat this as an
   authoring gate only, not as physics evidence.
3. Open the existing lander and FLIP scenes in the headful Editor. Capture
   `describe`, `sync_document`, and `QueryUsdPrim` topology/collision reports
   for the selected root and each moving body.
4. Build a small physicality manifest. Mark fixed internal pieces such as
   battery housings, motor housings, and solar frames as children of their host
   body. Mark only independently moving assemblies as separate physical
   bodies.
5. Record an initial evidence bundle: source revision, scene path, document
   generation, topology report, collision report, screenshot, and preflight
   diagnostics.

**Exit gate:** the intended scene opens; all required references resolve; all
physical parts have an explicit mass/collider/joint policy; no nested-body or
missing-collision error remains unexplained.

### Phase 1 — make Griffin land and settle

Use the existing `griffin_1.usda` as the starting asset. Do not redesign the
lander while diagnosing its landing behavior.

1. Inspect the lander root, body collision proxy, four leg references, pad
   colliders, and every leg joint with `topology:true` and `joint_frame_report`.
2. Define one coordinate contract: Y-up, metres, right-handed, and the local
   lander axes used by Modelica, leg frames, camera, and terrain. Keep the
   contract in the Twin documentation and component metadata.
3. Ensure the lander has one root rigid body with authored mass, centre of
   mass, diagonal inertia, and compound body colliders. A leg is independently
   physical only if it has its own rigid body, two explicit joint frames, a
   cardinal axis, limits, and its own collider/mass policy.
4. Place the touchdown test using collision envelopes and a positive initial
   clearance. Start sufficiently above the terrain that the full lander and
   pads are outside the terrain collider at time zero.
5. Run a bounded settle/drop test. Measure touchdown position, pad/terrain
   penetration, linear and angular velocity, body tilt, leg displacement, and
   whether any body detaches or jumps laterally.
6. Fix authored frames, dimensions, initial pose, or mass properties in small
   typed proposals. Do not tune solver settings or add a hidden “white” body
   to conceal a bad collider.

**Exit gate:** the lander reaches the terrain without initial overlap, remains
 upright within the authored tilt bound, all pads remain supported, no leg
 passes through the terrain, and the settled pose is stable for a hold window.

### Phase 2 — build the smallest FLIP mobility proof

Start from the shared `skid_rover` vehicle contract and adapt it in the Twin.
The first rover is a four-wheel raycast FLIP-like study, not the final visual
model.

1. Author four explicit wheel stations with a documented rover frame and
   ordered names `FL`, `FR`, `RL`, and `RR`. Use an explicit placement list;
   use mirror planning only where the source orientation is truly symmetric.
2. Compose one wheel, tire, and suspension arc per station. Supply every
   required wheel/suspension/tire value, including radius, width, mass, MOI,
   damping/drag, friction, stiffness, and contact parameters. Do not rely on
   defaults or infer wheel drive from names.
3. Keep the chassis as the root body and use a compound chassis collider.
   Motor, gearbox, shaft, battery, sensor mast, and fixed solar support are
   internal children unless a part genuinely moves relative to the chassis.
4. Put each motor/gearbox visually and physically at its wheel station, on the
   inboard side of the corresponding wheel, with the shaft axis coincident
   with that wheel’s axle. Verify this using world-frame topology reports and
   a side/bottom preview—not by adding another visible proxy.
5. Place the payload deck flush on the chassis with an intentional, documented
   clearance from wheels and motors. Use typed edge/centre alignment or
   collision-clearance plans for the authored envelopes.
6. Use the shared solar-panel component for the first fixed array. Bind its
   proper solar shader/material and `primvars:st`; orient it according to the
   rover coordinate contract on the intended rear/back support, with enough
   folded clearance that it cannot intersect the mast, camera, payload, or
   lander.
7. Prove the raycast control surface on flat terrain: settle, drive straight,
   steer, brake, reverse, and stop. Run the shared drivetrain parity-style
   assertions adapted to the Twin, recording displacement, heading sign,
   speed, and wheel contact.

**Exit gate:** the rover is recognizable, all four wheels are outside the
chassis at their authored stations, motors/gearboxes are attached to the
correct inboard sides, no floating visual blocks remain, the panel has a
resolved textured material, and the rover moves and steers on terrain.

### Phase 3 — integrate rover and lander as one assembly

The assembly is the authored unit. Do not move the lander and rover as
independent scene decorations and then attempt to repair their relative pose.

1. Create or retain one assembly USD file with direct child references to the
   lander and FLIP assets. The assembly owns only composition, poses, adapter
   joints, release policy metadata, camera/terrain context, and mission
   connections; it does not duplicate vehicle internals.
2. Add explicit lander-deck and rover-deck functional frames. Use
   `place_with_collision_clearance_plan` against the composed lander collision
   envelope and then `fixed_joint_plan` with exact body paths and local frame
   anchors. The rover must begin above the lander with positive clearance and
   no collider intersection, while the fixed adapter supplies the descent
   attachment.
3. Audit the fixed adapter: exactly two intended body targets, correct local
   frames, no accidental collision filter hiding the lander deck, and no
   duplicate joint identity. The adapter must be the only descent attachment.
4. Keep ramps as separate reusable USD components. Mount them through explicit
   sockets/frames only after the basic assembly works. Their deployment is a
   later acceptance gate, not a prerequisite for proving rover release.
5. Implement release in the Twin-local Rhai scenario through the typed
   detach command. After the command, wait for evidence of joint absence,
   rover body wake/pose authority, and continued terrain contact before
   reporting success. A notification saying “released” is not sufficient.
6. After release, select/possess FLIP and prove a short drive away from the
   lander. Keep the lander selected/possessable separately. If click possession
   is ambiguous, inspect selection context and collider/topology ownership;
   do not add invisible pick geometry as a workaround.

**Exit gate:** before release the rover follows the lander as one mounted
payload; after release the adapter is gone, the rover does not fall through the
lander, and FLIP can be possessed and driven independently.

### Phase 4 — add the minimum power and thermal story

Only after mechanical motion passes:

1. Create one explicit FLIP electrical network root with the solar panel,
   battery, motor loads, and stable vehicle boundary outputs in its component
   collection.
2. Prove positive solar power under known illumination, solar incidence,
   battery current/SOC response, and motor load. Read those values through
   authored program ports; do not infer them from panel appearance.
3. Add the thermal model as its own network/program boundary with causal
   motor/battery heat inputs. Do not cross acausal connectors between generated
   domain graphs.
4. Keep all generation and load equations in Modelica. Rhai may gate drive,
   safe mode, and test phases but must not integrate battery or thermal state.

**Exit gate:** the rover drives while electrical values remain physically
  bounded, SOC changes in the expected direction, and thermal outputs are
  observable and tied to actual loads.

### Phase 5 — optional articulated solar array and egress ramp

The first fixed panel is the baseline. A foldable panel is a separate change:

1. Make the panel a moving subassembly with its own render/collision geometry,
   explicit root body, hinge frame, and one `PhysicsRevoluteJoint`.
2. Author the actuator frame, angle limits, drive parameters, and Modelica
   actuator/network endpoint. Do not implement folding as a sequence of
   teleports or Euler animation writes.
3. Use Rhai only for the deploy/stow command and state transition. Verify
   folded clearance against the rover and the lander using collision bounds.
4. Apply the same pattern to ramps: each moving ramp has its own body/joint if
   it moves physically; fixed support geometry remains part of the lander
   compound body.

This phase is optional for the basic simulation and must not destabilize the
accepted fixed-panel or release path.

## Verification matrix

| Layer | Tool/evidence | What it proves | What it does not prove |
|---|---|---|---|
| Namespace/reference | `ValidateTwin`, `ValidateAsset`, `RunLint` | closure, schemas, collision-name/port/name conflicts, declared contracts | contact stability or driving |
| Authored composition | `QueryUsdPrim` with `topology:true` | composed paths, owners, frames, material, joints, bounds, projection | time evolution |
| Placement | `collision_bounds:true`, clearance/alignment plans | no initial overlap and intentional gap | solver stability after impact |
| Physics topology | `assembly_audit` reports | explicit bodies, joints, masses, colliders, physicality roles | whether friction/tuning produces the expected motion |
| Lander runtime | bounded drop/settle Rhai test plus pose/contact ports | touchdown, no penetration, bounded tilt/velocity, stable hold | flight realism |
| Rover runtime | drive/steer/brake scenario and parity assertions | wheel contact, movement, heading sign, controls | final FLIP performance |
| Assembly runtime | fixed-joint then detach scenario | mounted descent, authoritative release, post-release body ownership | ramp deployment unless separately tested |
| Power/thermal | Modelica compile/status and port snapshots | network topology, solar/battery/load/thermal signals | solar visual texture/material |
| Visual inspection | headful Editor preview, framed screenshots, camera track | orientation, leg/wheel/panel/motor placement, material readability | physics correctness |

Every verdict should include the Twin revision, scene path, document ID and
generation where applicable, test duration, relevant port snapshots, and the
exact failing owner/path. A screenshot alone is never a physics verdict, and a
successful preflight is never a runtime verdict.

## Rules for avoiding another regression

- Keep each phase in a separate scene/test until its exit gate passes.
- Make one concern-changing commit at a time: baseline, lander, FLIP, assembly,
  release, power/thermal, then optional articulation.
- Use the headful Editor and typed Rhai tools for authored USD edits. Review the
  generated operations before commit and save only after visual and typed
  checkpoints.
- Use exact paths and generation checks. Never repair a stale document by
  blindly replaying an old transform.
- Do not add a collider solely to make a screenshot look solid. Every collider
  has an owner, purpose, material, and physicality entry.
- Do not solve a coordinate mismatch by moving individual children until the
  picture looks right. Fix the component frame contract or the assembly mount
  frame, then realign the joint anchors atomically.
- Do not add Rust code for a Griffin name, a FLIP wheel layout, a release key,
  or a Modelica behavior. Escalate to Rust only when a focused generic test
  proves that the current standard USD projection, command, query, port, or
  runtime hook cannot express the requirement.
- Do not treat `deployment` metadata in a component bundle as a mechanism. A
  physical deployment still needs a standard joint/drive and continuous
  actuator model.
- Do not introduce physical wheel bodies before the raycast rover passes its
  motion gate.
- Use `RestartScene` when composed object assets or domain topology change;
  do not emulate a partial reload by manually respawning a visual subtree.

## Explicit remaining gaps

The new tools significantly reduce authoring risk, but they do not provide:

- a general CAD constraint solver or arbitrary mesh/UV generation system;
- automatic inference of functional frames, joint axes, wheel stations, or
  motor sides from a screenshot;
- automatic folding/deployment behavior from metadata alone;
- a universal collision solver for arbitrary rotations and nested parent
  transforms;
- proof of realistic lunar regolith interaction;
- deterministic, flight-quality dynamics or a validated public Griffin/FLIP
  parameter set;
- a safe object-level partial reload for every asset/topology change.

Those are reasons to keep the first simulation small and explicit, not reasons
to build a CAD subsystem. Reusable USD components plus generic placement,
topology, and audit plans cover the mechanical vocabulary needed here. The
remaining mission-specific knowledge belongs in Twin-local recipes and
assumption records, while continuous behavior belongs in reusable Modelica
models and phase policy belongs in Rhai.

## Recommended next implementation task

The next coding/authoring turn should be **Phase 0 only**:

1. choose and correct the default entry scene;
2. run the current Twin preflight;
3. collect composed topology/collision/joint reports for Griffin and FLIP;
4. replace or quarantine legacy builder calls with a thin Twin-local generic
   recipe;
5. write the first evidence-backed failure list.

Do not start by redesigning wheels, panels, motors, camera, ramp, and release
in one scene. Once Phase 0 is clean, proceed to the isolated lander settle
gate, then the isolated raycast FLIP drive gate, then the integrated assembly.
