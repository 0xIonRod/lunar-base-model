# Griffin-1 surface operations handover — 2026-09-30

This handover records the work completed in the Griffin Twin and LunCoSim, the evidence collected so far, and the remaining work for the next agent. The mission is **not yet accepted**: the current evidence does not show a successful touchdown, landing-leg verification, ramp deployment, or rover egress.

## Goal and ownership boundaries

The task is to make the Griffin-1 powered descent and surface-operations scene behave credibly, with traceable requirements and a usable lander/ramp/rover model. Keep mission sequencing and acceptance policy in authored Rhai. Keep reusable physics, port validation, and actuator state in generic Rust APIs. Do not add Griffin-specific behavior to the simulator core to compensate for Twin authoring errors.

## Repository and commit state

### LunCoSim

- Sim checkout: `luncosim-workspace/terrain`, branch `terrain-streaming`.
- At handoff, `terrain-streaming`, local `main`, and `origin/main` all point to `432655ce8` (`docs(perf): update Builder and startup handover`). The terrain branch was fast-forwarded to local main after the task commit and again after main advanced.
- Task implementation commit: `9e26e7f0a` (`feat(physics): expose dynamic joint island mass`).
- Integration commit on main: `9e70e56a5` (`merge: integrate terrain physics updates`).
- The integration and later main commits are in the ancestry of the current terrain branch. The current sim worktree was clean at the last status check.
- `cargo build` completed successfully from the current `432655ce8` checkout. No tests were run in this handover pass.

### Griffin Twin

- Repository: `lunar-base-model`, branch `main`.
- Implementation commit: `428041d` (`feat(griffin): add landing and mission evidence gates`).
- This handover document is being committed separately. The Twin changes were ahead of `origin/main` before this document was added. No push was made as part of this work.

Do not assume a remote push occurred just because a local branch is aligned with its remote. The sim remote ref was observed at `432655ce8`; the Griffin branch was ahead of its remote. This agent did not push either repository.

## Work completed

### Generic simulator changes

- Added a reusable dynamic-joint-island mass calculation in `crates/lunco-physics/src/assembly.rs`. It aggregates the live dynamic bodies connected through enabled/admitted joints, so an attached payload contributes to the lander assembly mass.
- Exposed assembly mass and validity through owner-provided ports. Guidance reads the complete mass and fails closed when the sample is invalid instead of silently reverting to a fixed or partial mass.
- Reused the generic joint-island traversal in escape handling, avoiding a second traversal implementation.
- Updated the GNC Modelica component and its USD-authored component layout so the mass input follows the same source of truth through the authored guidance component and Modelica model.
- Updated vertical navigation correction to use geometric 3D back-projection when valid, instead of relying only on a near-nadir altitude-confidence gate.

### Griffin Twin changes

- Split surface-mission reporting and ramp operation helpers into `tools/griffin_surface_mission_report.rhai` and `tools/griffin_surface_ramp_ops.rhai`. The scenario retains mission sequencing and policy.
- Expanded landing-leg and simulation-accuracy requirements, their source links, and the implementation-gap ledger.
- Added `scenarios/tests/griffin_landing_legs_requirements.rhai` for authored landing-leg checks.
- Updated the surface-ops scenario, the ramp and vehicle USD, the visual builder, and the requirement/spec tools. The goal was to make deployment evidence explicit and to keep the ramp sequence reusable and inspectable.

These edits are committed, but their existence is not acceptance evidence. In particular, a requirement script being present does not mean it has passed against a completed mission run.

## Runtime evidence collected

### Fresh headless startup on the integrated simulator revision

A task-owned headless LunCoSim process was started against the exact Twin scene:

```sh
target/debug/luncosim --no-ui --headless-max-speed --api 49631 \
  --scene /path/to/lunar-base-model/twins/astrobotic-griffin-1/scenes/griffin_1_surface_ops.usda
```

This run used the simulator binary built at `9e70e56a5`; the subsequent successful `cargo build` at `432655ce8` was not followed by another mission run.

- `/api/ready` reported `ready: true`, with no world hold, pending work, or runtime fault.
- `/api/diagnostics` reported zero broken connections, pending connections, algebraic loops, and faults.
- The mission automatically entered powered descent. Its mass preflight reported `ok: true`, `ready: true`, an assembly mass of approximately `5510 kg`, and zero difference between the assembly mass and guidance mass.
- Terrain collider admission logged short holds while selected tiles were not resident, followed by hold release. This is evidence that the admission gate ran; it does not prove that the legs later made valid contact.
- The headless process was stopped during the early descent before touchdown or requirement acceptance. No final landing verdict was collected.

### Earlier full-descent run

An earlier owned GUI/API run of this task reached about 190 seconds of simulation time but failed to land. The last captured state was approximately `(x, y, z) = (11.45, 3.71, -16.98) m`, with velocity `(1.17, -1.97, -2.12) m/s`; there was no all-leg contact, touchdown, or rover handoff. Around 182 seconds, altitude was about `6.9 m` and horizontal speed about `3.9 m/s`, near the target-zone edge.

The GNC and Modelica samples from that run suggested that:

- Lateral braking started too late for the remaining altitude and available thrust-vector authority.
- Guidance pitch/roll requests saturated and engine alignment varied substantially. There was a point where alignment reached zero and throttle closed.
- The outer controller allowed up to `1.5 m/s²` lateral command, but the authored tilt limit of `0.35 rad` caps lateral acceleration near `0.57 m/s²` while hovering. The command and plant therefore did not have enough lateral authority to remove the measured drift in time.
- Attitude control also reached its torque limit: a captured Modelica sample had `torque_z = -6000 N·m` with nonzero attitude error and angular rate. The allocator approximately tracked that saturated request, so the next investigation should include the attitude plant and controller limits, not assume a command-write failure.

These measurements are from the earlier run, before the fresh integrated build. Treat them as a strong lead, not proof that the latest source has the identical trajectory.

### Ground-contact discrepancy to recheck

In the earlier run, the body position appeared about `0.38 m` below the analytic terrain height while native contact remained false. A `GroundHeight` query also appeared to return a hit at the ray origin (`y = 100 m`) for both a site target and the current position. The ray/query frame or result interpretation was not resolved, so do not conclude from that observation alone that the collider is missing. The newer collider admission path logged tile-residency holds and releases, but no touchdown was observed after that change.

## Open issues

1. **Powered descent has no accepted landing.** Re-run the full mission from the current `432655ce8` simulator build and current Twin commit; capture position, velocity, altitude, attitude, thrust alignment, engine commands, and contact state at a shared simulation tick.
2. **Lateral and attitude control may be authority-limited.** Reconcile requested acceleration, commanded attitude, measured attitude/rate, engine direction, and actual body acceleration. Determine whether the limit comes from controller policy, plant dynamics, RCS authority, thrust-vector alignment, or timing before changing gains.
3. **Terrain contact remains unverified.** At touchdown, compare the analytic surface, resident collider tile, each leg’s collider/contact state, and the physics query’s frame/origin. Confirm that admission waits for the tile needed by the moving lander and that all four leg contacts are measured from physics, not inferred from elapsed time.
4. **Ramp deployment and rover egress need a complete state transition.** The previous visual reviews showed incorrectly folded or mirrored rails and a path that did not let the rover descend. Inspect the current stowed pose, left/right symmetry, hinge limits, deployed endpoint, rail clearances, and rover wheel path in the exact scene. Verify hinge convergence before declaring deployment.
5. **Engine flame/engine visuals are not visually accepted.** Earlier feedback reported one visible engine and poor-looking plumes. The current model has multiple engine prims, but no exact current screenshot was checked after the latest visual-builder changes. Confirm plume count, attachment, direction, visibility under throttle, and scale in the running scene.
6. **Requirements have not passed as a complete packet.** Run the landing-leg requirement script and the mission evidence/report tooling only after obtaining a complete run. Preserve pass, fail, inconclusive, error, and unverified as distinct outcomes.

## Recommended next steps

1. Confirm both worktrees are still clean and on the revisions above before changing anything. Resolve stable entity IDs from `ListEntities` on every new run; runtime IDs are session-specific.
2. Rebuild with plain `cargo build` in `luncosim-workspace/terrain` if the checkout or source changes. For headless diagnosis, run with `--no-ui --headless-max-speed --api <free-port> --scene <exact Twin scene>` and query readiness/diagnostics before interpreting telemetry.
3. Use `ReadPortsBatch`, `ReadActuatorStatus`, and `ReadModelicaStepSamples` to collect coherent state. The query and command contracts are documented in the sim repository at `crates/lunco-api/README.md`. Resolve the lander, FLIP, engine, terrain, and leg entity IDs from that run instead of carrying forward old IDs.
4. Save a time-aligned landing report and determine the first point where trajectory, attitude, terrain admission, or contact diverges from the requirement envelope. Reproduce before changing controller values.
5. Inspect the exact Twin scene visually in a windowed run for the stowed/deployed ramp and multi-engine plume. Headless startup and compile success are not visual acceptance.
6. Fix the root cause at its owning layer. Keep Rust changes generic and typed; keep Griffin sequencing and deployment rules in Rhai; keep source geometry and transforms in the Twin. Remove obsolete duplicate behavior instead of adding compatibility fallbacks.
7. Run the authored requirement checks and capture a complete mission verdict. Commit only the verified task changes, then report local commits and remote state separately.

## Important limits of this handover

- The current simulator build at `432655ce8` compiled successfully, but its full Griffin mission was not run after the final fast-forward.
- The only fresh run on the merged terrain changes reached powered descent and passed the mass preflight; it ended before touchdown.
- No full requirement suite, rover egress, visual review of current ramp/engine state, or remote push is claimed.
