# Griffin / FLIP: autonomous repair handoff

> Historical checkpoint. The current CAD rover integration and acceptance are
> recorded in `twins/astrobotic-griffin-1/contracts/flip-cad-integration-2026-10-27.md`.
> The process IDs, native dependency work and open blockers below describe the
> 21 October session; they are not instructions for the current checkout.

> Follow-up verification is recorded in
> `runs/griffin-stepwise-2026-10-21/PROGRESS.md`. The captured 295-row
> contact failure now passes a focused native replay and 16 owner tests after
> extending the existing overcomplete-PSD dispatch to include contact rows.
> The rebuilt production mission passed the former t=25.6667 fault and reached
> t=27.45 with qualified touchdown and four ramp flight latches detached, with
> no runtime fault. Full egress/drive acceptance remains open. Owned visible
> PID 3644 / API 4198 was left running; verify ownership before further control.
> The NASA UnknownIssuer download failure was reproduced,
> corrected using Windows platform certificate verification, and both Earth
> and Moon maps were downloaded, processed and reported installed by the app.
> The 2–4 FPS slowdown is reproduced; the same view renders about 59 FPS when
> simulation is paused. Performance and route-event dependency handling remain
> unresolved. Read the newer progress log before acting on historical blockers
> and PIDs below.

Prepared 2026-10-21. This is a historical handoff; older plans and run reports
contain historical intermediate states. All paths below are on this Windows host.

## Assignment for the next agent

Fix the post-touchdown continuous-contact solver failure, validate the route
event-subscription correction, and continue the actual Griffin mission until
Griffin lands carrying CAD FLIP v5, the physical ramps deploy, the payload
adapter releases, and FLIP drives the authored ordered route and stops. Preserve
the validated initialization crash correction and existing local work. Work
autonomously within this scope, report real evidence, and do not manufacture a
PASS by changing acceptance predicates or suppressing faults.

The user asked to fix and continue after the initialization diagnosis, then
requested this report for another agent to fix independently. This report does
not dispatch a chat, publish patches, or authorize unrelated dependency changes.

## Current result: initialization fixed, landing achieved, egress blocked

1. **Fixed and verified:** Windows access violation during Modelica initialization.
   Rumoca/Cranelift JIT omitted stack probing for a large generated stack frame.
   A focused fresh-thread native regression crashes with the old setting and
   passes with inline probes. The rebuilt production simulator initializes Griffin.
2. **Observed:** powered descent with CAD FLIP v5 mounted, followed by qualified
   `touchdown=1` and `landing_contact=1`.
3. **Current blocker:** structured continuous-contact solver fault shortly after
   touchdown, during initial ramp unlatching. This is not another access violation.
4. **Not accepted:** complete ramp deployment, FLIP payload-adapter release,
   egress, route completion, or final performance acceptance.

Previous session PID 18060, API port 4198, is **no longer running** at report
creation. `runs/griffin-mission-2026-10-21/fixed.exit-code.txt` contains 0.
Earlier RUN.md says it was left open; that was true at the preceding handoff,
but is stale now. Do not assume any currently listening port belongs to you.

## Repositories and preservation

| Repository | Path | Tested HEAD |
|---|---|---|
| Simulator | `F:/lunco-sim` | `a4f4faca24432102dd9c4852217623db95e30424` |
| Mission/models | `F:/lunar-base-model` | `7d471dd650b06aa1a2b0a33e7d0484a3f4926874` |

Both checkouts have uncommitted work. Nothing from this task was committed or
published. Do not reset, clean, stash indiscriminately, or overwrite it.

Simulator changes:

- `Cargo.toml`, `Cargo.lock`: local Rumoca package patch used by the built binary.
- `assets/scenarios/route_follow.rhai`: prepared event-filter correction; full
  dynamic acceptance still outstanding.
- `crates/lunco-modelica-compiler/src/lib.rs`,
  `docs/architecture/20-domain-modelica.md`, `skills/run-modelica/SKILL.md`:
  preserved pre-existing Windows path-normalization work; leave intact.

Mission changes include research/README edits, both Griffin scenes, the FLIP v5
vehicle and component files, its mount gate, handover files and run artifacts.
`git status --short` is authoritative; inspect before editing.

Read `F:/lunco-sim/AGENTS.md`, the applicable nested guides, and
`skills/START-HERE.md`. The prior agent used `run-modelica`, `inspect-simulation`,
`test-via-api`, `author-rhai-tests`, `capability-discovery`, and USD assembly skills.
Use typed simulator document operations for USD authoring; never text-patch USD.
Keep each agent's simulator session on an explicit free API port. Read-only
dependency inspection is permitted; follow the repository's explicit permission
rule before any newly needed third-party source modification/publication.

## Exact next failure

At the last admitted simulation time, t=25.6666666667 s:

- Griffin scene Y=0.6087079048 m, vertical velocity=-0.0006040145 m/s.
- FLIP scene Y=3.4177129269 m, still attached to Griffin.
- `touchdown=1`, `landing_contact=1` on the lander.
- Four ramp flight joints had detached. These are not FLIP payload release.

`GetReadiness`:

```json
{
  "ready": false,
  "world_hold": false,
  "faulted": true,
  "fault": {
    "kind": "physics-continuous-contact-invalid",
    "subject": "continuous contact solve",
    "detail": "coupled minimum-residual solve did not converge"
  },
  "pending_count": 0
}
```

Native diagnostic at `2026-10-21T11:01:38.987187Z` in `fixed.stderr.log`:

```text
coupled Krylov convergence failed rows=295 max_iterations=1024
NoConvergence {
  abs_residual: 5.79938257154144e-13,
  rel_residual: 9.216437328144082e-12
}
```

Physics snapshot: 41 bodies, 23 dynamic, 117 colliders, 26 joints, no pending
joints, 4 detached joint paths/sets, 123 contact graph edges. Last measured
continuous solve cost about 1836 ms; earlier steps were roughly 300–400 ms,
so simulation progresses substantially slower than real time.

`RuntimeDiagnostics` returned zero findings even while `GetReadiness` exposed
the terminal fault. Do not interpret zero findings as a healthy simulation.

### Owning code and investigation path

- `F:/lunco-sim/crates/lunco-physics/src/constraint_response.rs`:
  `solve` (~197), `PreparedResponse` (~260), `solve_island` (~467),
  `solve_minimum_residual` (~654).
- `.../constraint_response/factorization.rs`: existing complete orthogonal
  minimum-norm response and feasible-pivot implementation.
- `.../ccd.rs`: continuous projection caller, near `constraint_response::solve`.
- `.../joint_solver.rs`: another shared consumer of the same response solver.

The LSMR relative tolerance is 1e-12, deliberately independent of geometric
slack. A small absolute residual alone does not justify accepting its rejection.
Do not raise tolerances, iteration limits, or disable collisions as a substitute
for identifying the first faulty layer.

The existing dense/minimum-norm branch is selected for a self-adjoint island
when the count of permanent bilateral rows exceeds `response_rank_ceiling`.
Otherwise the active face uses LSMR. Investigate rank, scaling, active unilateral
contacts, and feasibility. It is **not yet proven** that branch selection is
wrong, that the failed matrix is singular, or that the physical configuration
is inconsistent. Do not present those hypotheses as the root cause.

Capture the actual failing row/operator/RHS system, produce a focused replay,
and fix its authoritative owner before repeating the full mission. Existing
trace targets can help without inventing a parallel exporter:

```powershell
$env:RUST_LOG='warn,lunco_physics::constraint_response::systems=trace,lunco_physics::constraint_response::native_rows=trace,lunco_physics::constraint_response::iterations=trace'
```

These targets emit full admitted rows, native inertias, and iteration results.
Trace volume may be large: only ~2.38 GB was free on F: at report creation.
Capture deliberately and preserve the exact failing input. Root cause of this
second failure has not been determined.

## Verified initialization fix — keep it enabled

Pinned upstream Rumoca revision:
`f8df42b448c31273d94926183dac2fffeccef9d0`, version 0.10.2.

Task-local package:
`F:/lunar-base-model/runs/griffin-mission-2026-10-21/dependency-fix/rumoca-exec-cranelift`.
The simulator's Cargo.toml Git-source patch selects it. The shared Cargo Git
checkout was not modified. Other Rumoca packages retain the original exact pin.

`src/emit/host_runtime.rs` now sets:

```rust
("enable_probestack", "true"),
("probestack_strategy", "inline"),
```

Regression `emit::host_runtime_tests::large_jit_frame_on_fresh_worker_stack`
compiles a 768 KiB stack frame on one thread, then executes it on a fresh 16 MiB
worker stack. It checks values at both frame edges across a native helper call.
The old configuration exits `-1073741819` (`0xC0000005`); the corrected one passes.

```powershell
cargo test --manifest-path F:/lunar-base-model/runs/griffin-mission-2026-10-21/dependency-fix/rumoca-exec-cranelift/Cargo.toml --target-dir F:/lunco-sim/target large_jit_frame_on_fresh_worker_stack -j 4 --offline
```

Already passed; do not rerun unchanged merely to repeat evidence.
Upstream-shaped patch: `dependency-fix/rumoca-inline-stack-probes.patch`.
The standalone manifest metadata is local integration plumbing, not part of the
upstream source correction. No patch was published.

## Build and reproduce

Use the existing target directory, normal optimized development profile, and
four build jobs. Avoid a full clean or another target directory on this disk.

```powershell
Set-Location F:/lunco-sim
$env:LIBCLANG_PATH='F:/lunar-base-model/runs/griffin-mission-2026-10-21/build-deps/clang/native'
$env:PATH='C:/Program Files/Git/usr/bin;'+$env:PATH
cargo build -p lunco-luncosim --bin luncosim -j 4 --offline
```

This command passed after the fix in 3m14s. Binary:
`F:/lunco-sim/target/debug/luncosim.exe`, version `0.6.0-dev (a4f4faca-dirty)`.
The local libclang 18.1.1 package was needed by FMI bindgen, not as a runtime
workaround. See the run report for its official-wheel checksum.

Launch configuration used:

```powershell
$env:LUNCOSIM_CONFIG='F:/lunar-base-model/runs/griffin-mission-2026-10-21/fixed-config'
$env:LUNCOSIM_CACHE='F:/lunar-base-model/runs/griffin-mission-2026-10-21/clean-cache'
$env:LUNCO_SCENARIO_UNATTENDED='1'
# Verify a free port, then launch visibly from F:/lunar-base-model:
# F:/lunco-sim/target/debug/luncosim.exe --api <owned-free-port> --scene F:/lunar-base-model/twins/astrobotic-griffin-1/scenes/griffin_1_surface_ops.usda
```

`launch-fixed.ps1` implements that monitored launch on 4198, but **overwrites its
fixed.* log/PID files**. Create a new run directory/log names before reusing it.
Leave the previous reproduction evidence intact. Never control another session.
`LUNCO_SCENARIO_UNATTENDED=1` is the maintained authored auto-mission mode;
the production window remains visible.

API helper: `runs/griffin-flip-v5-2026-10-20/api.ps1` (hardcoded to 4198; adjust
your own copy if you select another port). Both commands and queries use:

```json
{"type":"ExecuteCommand","command":"GetReadiness","params":{}}
```

POST to `http://127.0.0.1:<port>/api/commands`. Schema from the tested build:
`runs/griffin-mission-2026-10-21/api-schema.json`. Discover current fields rather
than guessing them. Important working calls:

- `CosimStatus`: save full response, then filter entities by exact name.
- `ReadPorts {api_id, port_names:["touchdown","landing_contact"]}`.
- `QueryPhysicsState {id}` — parameter is `id`, not `target`.
- `ScriptStatus {target}` and `ScriptInspect {target}`.
- `PhysicsPerformance`, `GetReadiness`, `RuntimeDiagnostics`.
- `RunRhai {code}`; `CaptureScreenshot {save_to_file:true,path:"absolute.png"}`.

Observed stable IDs (re-resolve each run using `find`/ListEntities):

| Subject | ID |
|---|---|
| Lander `/Griffin1SurfaceOps/Lander` | 6394538761663565 |
| Rover `/Griffin1SurfaceOps/FLIP` | 5811092977805847 |
| Mission host `/Griffin1SurfaceOps/Scenario` | 7114085941306766 |
| Route host `/Griffin1SurfaceOps/FlipRoute` | 4900232228771049 |
| Route program `/Griffin1SurfaceOps/FlipRoute/Program` | 4166624318423159 |
| FLIP payload adapter | 5504410603518397 |

`ScriptComplete` is code completion/autocomplete, **not mission completion**.
`ScriptInspect` for the mission currently fails to serialize a SysmlFeatureHandle;
this does not mean the mission has failed. Route inspection is usable. A transient
ready=true with no admitted scene is insufficient: verify actual participants,
physics admission, increasing simulation time, and scene identities together.

## Route-script follow-up

Before release, route ScriptStatus reported receiving `lander_engine_cutoff`
from an undeclared Modelica participant. The generic route's on_event ignores
that name but had no subscription filter, so delivery was checked first.
Prepared fix in `F:/lunco-sim/assets/scenarios/route_follow.rhai:on_start`:

- Subscribe to existing consumed names: `usd.document.projected`,
  `program.selected`, `runtime.ui.action`, `cmd:ReleaseControl`, `intent.edge`,
  and `route_start`.
- Subscribe to the consumed `enter:` prefix.

Validate filtering and retained route controls/sensors with a focused scenario;
do not add an irrelevant lander dependency to the rover route. Existing
`assets/scenarios/tests/route_lifecycle.rhai` is relevant discovery material.

The attempted inline RunScenario reload compiled but failed its USD program
dependency lookup; it did not validate the fix. Absolute Windows filesystem
paths passed to RunScenarioAsset were incorrectly treated as `lunco://F:/...`
and rejected. Restore/use root-qualified asset identities. The final working
restoration was:

```json
{"target":4900232228771049,"source_asset":"lunco://scenarios/route_follow.rhai","owner_twin_id":1}
```

sent to `RunScenarioAsset`, **without scene_asset**, preserving the landed scene.
The canonical route then reported scripted=true, running=true, status ready/ok,
generation=0. Inline document 119307698777526 is not that active route; do not
apply further edits assuming it is. The engine source edit remains on disk;
its corrected behavior still needs production validation on the next build/run.

## FLIP integration and acceptance boundaries

Mission scene: `F:/lunar-base-model/twins/astrobotic-griffin-1/scenes/griffin_1_surface_ops.usda`.
Mission behavior: `scenarios/griffin_1_surface_ops.rhai`; helpers under `tools/`.
Twin verification bindings: `twin.toml`. The current default IS the surface-ops
scene; an older completion plan saying otherwise is stale.

Canonical v5 vehicle: `vehicles/flip_v5.usda`, with five CAD visual layers and
panel controller under `components/rover/flip_v5/`. Exported source revision was
`c51853f147015346f59bb87cab1d3b86a7eaa63e` on the FLIP visual branch.
Both production and review scenes reference v5. It retains physical wheels,
suspension, motors, gearboxes, shafts, and the movable panel/controller.

Mount gate: `scenarios/tests/griffin_flip_v5_mount.rhai`. Eight authored/composed
checks passed, including adapter endpoints/frames, seating and wheel/drive
topology. This was not a driving test. V5 still uses infinite electrical power
and has no solar-generation/thermal models; full legacy subsystem migration
remains open. Do not claim it finished.

NOBILE03 terrain has already been downloaded/processed. Preserve Twin-local
`.cache/sources/nobile03/` and generated `terrain/nobile03/materials/textures/heightmap.tif`.
Latest upstream Griffin head contains seven engines; do not change this to five
based on the older provisional research decision while fixing solver behavior.

Completion must use real mechanisms and observations: qualified touchdown with
FLIP mounted; all physical ramp deployment/settlement gates; real payload-joint
retirement; FLIP supported after egress; every authored waypoint reached in order;
final stop and authored mission verdict. Record wall/step performance separately.
Do not teleport bodies, skip route points, lower physics fidelity, fabricate port
values, or weaken verification to make the result pass.

## Evidence map

Everything below is under
`F:/lunar-base-model/runs/griffin-mission-2026-10-21/` unless noted:

- `RUN.md`: full chronology and current acceptance boundaries.
- `CRASH-DIAGNOSIS.md`, `dump-16132.txt`, `dump-19496.txt`, `inspect_dump.py`:
  original native crash evidence. Dumps themselves remain local in the user's
  CrashDumps folder; do not upload them.
- `dependency-fix/README.md`, `rumoca-inline-stack-probes.patch` inside that folder:
  verified JIT fix/provenance; before/after logs and exit files at run root.
- `build-fixed.log`, `build-fixed.exit.txt`: successful production rebuild.
- `fixed.stderr.log`: original 295-row solver rejection and other diagnostics.
- `postlanding-readiness.json`, `postlanding-performance.json`,
  `postlanding-cosim.json`, `postlanding-landing-ports.json`,
  `postlanding-route-status.json`, `postlanding-paused.png`: final captured state.
- `fixed.exit-code.txt`: previous process later exited 0.
- `F:/lunar-base-model/runs/update-2026-10-21/UPDATE.md`: repository update evidence.

## Recommended execution order

1. Read instructions, inspect dirty state and preserve the local dependency patch.
2. Reproduce with bounded native-row/system tracing in a fresh owned visible run.
3. Extract the failing constraint system and prove the first divergent owner;
   add the smallest meaningful regression and implement the general correction.
4. Validate the route filter and its existing control/trigger behavior.
5. Rebuild only changed owners as needed, then run one fresh integrated mission
   through landing, ramps, release, egress, full route and stop.
6. Save durable evidence, exact tested revisions/local patches and remaining
   limits. Report success only for observed accepted behavior.
