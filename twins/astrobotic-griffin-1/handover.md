# Griffin-1 Twin handover

**Latest update:** 2026-10-07 (older sections retain their original evidence scope)

## Differential FLIP and verified component completion — 2026-10-07

FLIP uses the skid Modelica law and standard TankDifferentialAPI, with fixed
wheel headings and differential steering geometry. Its possessed vehicle HUD
starts/stops the route; manual input takes control. Alt-click route points use
the core waypoint program. Twin runtime persistence is disabled. USD changes
were saved and read back through the simulator document API.

Production evidence from the built source integrated as simulator `804c54144`
(binary stamp `cd1c7918-dirty`; final Rust edits were formatting only):

- Route/HUD/manual takeover: PASS 16; three points visited in 26.5 s,
  minimum upright Y 0.992339. A fresh process began with an empty route.
- FLIP wheel requirements: PASS 73.
- Griffin/FLIP visual contract: PASS 126; the static fixture disables its
  inherited flight latches alongside its other disabled joints.
- Lander requirements: PASS 122.
- Engine pilot hold/release and native mass properties: PASS 13 at
  2073 ticks / 34.55 s. Fuel reduces native mass and X/Z inertia; Y inertia
  retains the source model value. COM and all inertia endpoints track current
  or preceding Modelica samples within binary64 roundoff.
- Flight stow topology and negative plans: PASS 272. The powered pilot run
  held all six flight latches within 0.000057 rad.
- Full surface operations: PASS 16 at 7273 ticks / 121.22 s, including
  sequential release of the six flight locks, deployment and differential egress.
- General Griffin requirements now finish with a passing verdict and valid
  full SysML projection. Mesh geometry is measured separately from explicitly
  source-bound design constraint parameters.

The native f64 mass/COM/inertia path and strict-closure prepared-solver cache
are committed in the simulator. Low-level owner gates passed (2 native mass
checks, 3 cache closure checks), as did the production build and worker CLI
compile check. See the simulator performance handover for measured cold/warm
preparation costs; sustained FPS and faster cold lowering are not established.

Manual pilot attitude stability remains unresolved. The new
`tests/griffin_pilot_attitude.usda` reproduces the failure after a 0.1 s semantic
pitch tap with thrust held. Tight flight locks and retiring all four leg
spring joints do not eliminate it. All 12 commanded RCS jets reconstruct the
correct restoring pitch moment, approximately -277.178 N m, while rotation
grows. This proves commanded wrench, not native backend delivery. The next
causal check must separate external angular acceleration from attachment
constraint contributions; no controller gain changes were made.

The earlier standalone trail result does not prove mission rendered-trail
continuity. A headful exact surface scene reached touchdown and ramp deployment
and displayed FLIP's standard HUD while possessed. It did not reach a rover
trail-cutoff observation before the requested finalization. Trace-cutoff
reproduction remains open.

## HUD GNC disconnect — 2026-10-06

The surface-operation HUD has a DISCONNECT GNC / RECONNECT GNC action. It
takes or releases the lander's `piloted` authority through the existing
`AcquireControl`/`ReleaseControlSource` commands, so the flight law ignores or
resumes guidance; no second control path exists. Production
`tests/griffin_gnc_toggle.usda` (GRIFFIN_GNC_TOGGLE) PASS 7 during powered
descent, including the unknown-action rejection. Manual powered flight is not
yet stable: at full thrust a single pitch input grows into a flip although the
RCS delivers the requested torque (diagnosis in the 2026-10-06 session notes).

## Surface-ops settle verdict and ramp tick cost — 2026-10-06

Unattended surface operations now keep `landing_status_task` running until the
mission completes, so GR-004 reads the live qualified landing state instead of
the first post-touchdown sample, taken while the hull still rocks above the
0.005 rad/s gate. A GR-004 failure now names each live landing predicate.
Production `Verify_GriffinSurfaceOperations` PASS 16 at 7173 ticks / 119.55 s
(core `9aa272c94`).

Ramp-unfold stalls (160-460 ms fixed ticks) came from `griffin_spec`
accessors: each opened `sysml_model`, which rebuilt the full validation report
(~10 ms). Core `9aa272c94` opens Twin models from the prepared analysis; ramp
ticks now peak at 8-26 ms and the full unfold completes in about 34 s.

## Nested payload bay and one-side arrays — 2026-10-05

Supersedes the raised-deck checkpoint below. The operator identified the wrong
layout assumption: a tall array occupied an egress side, and lifting the entire
payload above it preserved that error. Arrays now occupy the forward face and
both forward chamfers; the +/-X exits remain clear. The 3.60 m bus is retained
as a low-confidence reconstruction because the study 2.60 x 2.28 m wheel envelope
fits it. The public photos do not calibrate a current flight bus dimension.
See `requirements/griffin-size-evidence.md` and the linked current hardware
photographs for assumptions and the historical/current configuration boundary.

The local walking plane is Y2.12, 0.72 m below the rejected Y2.84 platform,
and 0.5946 m below the panel tops. The 40 mm addition over the old Y2.08 plane
keeps 80 mm crossmembers about 14 mm above the tank caps. Columns, central mast,
contact deck, FLIP station/fixed joint, camera focus, both hinges/bridges/toe
miters and RCS stations follow this datum. Solar clearance now checks a
conservative separating axis in 3D instead of requiring vertical separation.
Missing panel identities or incomplete snapshots cannot pass; the source-sized
three-panel snapshot measured 99.16 mm minimum stowed clearance on each exit.
The 180 mm forward bank offset, narrow five-column chamfers and longer links
are explicit packaging estimates. Current photographs do not qualify them.

Saved-source bus, nominal ramp, flight-stow and propulsion gates passed.
The six signed production RCS commands also passed without changing the
allocator or relaxing its tolerance; the rejected high mounting had failed.
The solar gate caught stale geometry on the narrowed forward-starboard panel;
its rows were regenerated and the saved-source solar gate passed all 152 checks.
The main-engine continuous-burn test passed on the preceding raised assembly;
that scope must not be silently promoted to the revised payload geometry.

Editor 49840 lost dependent layer refreshes and reported a terrain material
fault. All edits remained in typed document operations and explicit saves.
Fresh Editor 49841 completed the lowered component edits. Fresh High
review 49843 resolved the saved rover station at Y3.06 and the one-side arrays;
its overview and array-side captures were inspected. Later row updates also
required explicit SaveDocument followed by fresh-load inspection because the
matching Editor preview generation stopped advancing. A warm Editor query
can still expose an older referenced stage; fresh source gates and captures
are required. Smooth CAD-style animated focus remains a generic Editor task;
only component focus has been exercised here.

The source-pinned fresh landing pair passed for this saved assembly: both
confirmed touchdown at tick 1502 and ended at tick 5110. All 361 samples over
60.1333 s after touchdown retained four-pad contact, with no unready samples.
Final position, upright axis and speed deltas were exactly zero. Maximum drift
was 0.151482 m, minimum upright Y 0.995968 and maximum angular speed 0.009388 rad/s.
Evidence: `terrain/target/griffin-nested-landing-pair/` and
`terrain/target/griffin-nested-landing-driver.log`. Binary SHA-256:
`158c6cb7c1b2fde13bc2cc4b9075af8a5544eed726dfebd1075373d6ea9f9fcd`;
Twin source fingerprint: `ca0991d67ace9fc16a5af5a27567fc36b3730d0b0ae110a4b81a680356d5b4cd`.
The executable identifies itself as `75f376e5-dirty`; this evidence identifies
that frozen artifact, not a fresh build of the current core checkout.
After the pair, only the separate static stow observer gained fail-closed
cardinality/path guards and clearance metrics; its rerun passed 230 checks
(`terrain/target/griffin-nested-stow-final.log`). Physical/guidance sources
were unchanged.

Additional runtime acceptance, 2026-10-06 local time (2026-10-05 UTC): the
nested assembly passed all ten production held-engine-command checks on the
headless fixture. A single five-second command sustained climb; after the
three-second release window chamber pressure was 25.043 Pa and thrust 0.364 N.
Evidence: `terrain/target/griffin-nested-engine-commands.log`.

Owned High rendered API 49844 passed all 16 surface mission gates after the
shared U/F request functions: middle, toe and root hinges commanded and settled
in order; the rover drove down the ramp onto four native DEM contacts and
completed the survey route. No pose teleport was used. The inspected captures
`griffin-nested-unfold-close-49844.png` and
`griffin-nested-egress-array-side-49844.png` are under `terrain/target/`.
Visible pads remained on terrain and the skirt contained the main nozzles.
The final lander observation had four-pad contact, upright Y 0.995806 and
angular speed 0.000434 rad/s. The route switched to the FLIP HUD. This mission
pass does not establish minimum clearance at every intermediate motion sample.

Strict rendered retained replay FAILED at relative tick 300: main thrust was
11574.437294925785 N versus 11574.436325920178 N (difference about 0.000969 N).
The saved failure is in `terrain/target/griffin-nested-runtime-49844.log` and
`/tmp/griffin-nested-rendered-replay-49844.json`. The process reported eight
physics compute threads, compared with one in the passing fresh-process pair;
threading is a diagnostic distinction, not an established cause or a workaround.
Disassembly confirmed the recovered binary's gravity path contains the new
`pose_in_grid` calls; its old build banner alone does not identify this failure
as a stale gravity implementation. No limits were relaxed and no core fix is
claimed. Strict rendered reload, continuous sweep clearance and uncontended
performance remain open. The owned validation app has exited.

## Raised deck and recessed engine bay — 2026-10-05

The current unqualified integration study raises the payload walking top to
vehicle Y2.84 above the tall-array top, restores the original inboard bridge
span, recalculates the nominal slope/toe miter, and updates FLIP attachment,
initial position and camera focus together. Four cardinal columns and two
crossmembers join bus, central mast and payload plate. Rear avionics leaves
the central tank/mast space open. All seven main nozzles fit inside the deep
open skirt with a 20 mm recessed exit. Twelve existing A110 force owners now
sit in four exposed upper-corner groups; no extra thruster proxies were added.
Sources and explicit dimensional guesses are in SysML and the size evidence.
The square engine adapter has also been replaced by the shared octagonal
profile; the existing containment observation now includes its vertices. An
initial shared-material reference omitted the Twin identity and was unresolved;
that authored path was corrected before restarting runtime acceptance.

Focused saved-source gates pass: flight stow 230, bus 356, nominal ramp 1281,
propulsion 94 checks. The RCS wrench check retains all six pure-axis groups.
These are geometry/authority results, not landing or unfolding acceptance.
The fresh integrated Editor preview was inspected after reopening the saved
vehicle. A warm parent preview can retain old referenced geometry despite a
ready fence; dependency invalidation remains a generic Editor gap. The target
cache was removed externally during this work; the exact running core568
executable was recovered through /proc without rebuilding. Older target
artifacts named below were deleted; surviving /tmp JSON has narrower scope.

CAD-style edit feedback requested by the operator remains a small Editor
requirement: focus the changed component, smoothly reframe after its projection
fence, and highlight changed paths briefly. Cancel the transition on manual
camera input or document/generation replacement. Respect the active preview
and leave simulation camera/physical poses untouched. Implement through the
existing Editor camera policy and interpolation mechanism rather than a Twin
animation framework. Smooth reframing is not implemented by this checkpoint.

## Current runtime checkpoint, 2026-10-05

Core `568f5146f` closes the two remaining reproduced determinism faults:

- Fresh native traces matched through tick 2362, then ramp-to-toe contacts
  appeared with opposite collider/body endpoint roles at tick 2363. Canonical
  composed USD identity now selects roles before narrow phase creates oriented
  manifolds and caches. Edge and pair roles change together; existing solved
  manifolds are preserved. Native/generated identities remain backend owned.
  The 40-step native contact regression is RED before/GREEN after; all nine
  bridge tests pass. No contact removal, rounding or tolerance changes.
- Rendered replay diverged at tick 300 in exact thrust by about 0.000740 N.
  Surface gravity now reads native double-precision Position in the admitted
  frame, and composes the provider into that frame through their common
  ancestor. Render interpolation, f32 writeback and astronomical ancestor
  motion no longer perturb the force. The deliberately mismatched native/render
  pose regression is RED before/GREEN after; all 15 environment tests pass.

The clean production binary passes both required replay modes:

- Source-pinned fresh processes: both land at tick 1502, finish at tick 5110,
  and retain four-pad contact in 361/361 samples over 60 seconds. Final position,
  upright axis, ground speed and angular speed deltas are exactly zero. Drift
  is 0.150166 m and minimum upright Y is 0.996041. Evidence:
  `terrain/target/griffin-native-gravity-fresh-replay/` and
  `griffin-native-gravity-fresh-driver.log`.
- Owned High rendered API 49835: strict retained replay PASS, two 90-second
  replacements, 94 samples including admission and the first three solver
  steps, cooked FLIP bounds, exact thrust/throttle and touchdown/handoff states.
  Evidence: `terrain/target/griffin-native-gravity-rendered-49835.log` and
  `/tmp/griffin-native-gravity-rendered-replay-49835.json`.

Rendered 49835 also passes all 16 surface mission gates after U then F. The
rover physically drives down the connected ramps onto DEM, completes the survey
route and selects the FLIP HUD. Visible footpads remain above terrain and the
bus stays upright. Capture:
`terrain/target/griffin-native-gravity-egress-49835.png`.
The subsequent production pilot trial passes all 10 engine-command checks:
one five-second held command yields 26.240 m sustained lift, 12.199 m/s upward
speed and 21,794 N peak thrust, consuming 32.132 kg of propellant. At the end
of the three-second release window, chamber pressure is 33.325 Pa and thrust
0.484 N. Evidence: the same rendered log and
`/tmp/griffin-native-gravity-engine-49835.json`.

Executable acceptance source revision is `10696714418594102912`. The later
GR-031 documentation addition changes no geometry, limits or physical inputs;
it was applied through the typed SysML API, saved and read back exactly at
owned 49835. Core is pushed to `origin/griffin-pressure-fed-engines` and
fast-forwarded into local core main. Remote core main is not pushed. All owned
validation apps have exited; incomplete duplicate headless 49836 supplies no
additional acceptance claim.

Previous source-pinned fresh A/B failures and rendered 49834 failure remain
historical evidence, not the verdict for `568f5146f`. Headless, rendered,
component geometry and performance remain separate evidence scopes. No new
sustained FPS or hardware flight-qualification claim is made. Prior High
49831 short post-egress timing window was p50 11.076 ms, p95 19.492 ms,
p99 20.933 ms and max 22.930 ms at 2560 x 1568. Prior warm Tracy 49832 contains
no PrepareModelica event and does not prove cold compilation speed.

Earlier core fixes remain: exclude inactive compound subtrees, preserve seated
quaternion hemisphere, retain authored participant names, clear disposable view
edits at restart, and wait for replacement readiness before retained dependency
rebinding. Live contact notices restore without re-emitting touchdown/resetting
egress. Route markers use the same frozen landing frame as navigation; progress
uses horizontal arrival, without marker triggers or domes.

## Deterministic contact checkpoint, 2026-10-05

The source-pinned production fresh pair now passes strict replay: both runs
reach touchdown at tick 1508, finish at tick 5110, and retain all four contacts
in 361/361 samples over the following 60 seconds. Final position, upright
axis, ground speed and angular speed deltas are exactly zero. Evidence:
`terrain/target/griffin-enhanced-determinism-replay/` and its driver log;
Twin source revision `8632437958443190011`.

Warm replay also passes on owned API 49817: one retained observer compares 91
samples across two 5400-tick replacements, including pose, velocity, thrust,
guidance and touchdown signals. Evidence:
`terrain/target/griffin-egress-contact-deterministic-49817.log` and
`griffin-enhanced-determinism-warm-49817-status.json`.

The production build enables Avian's maintained `enhanced-determinism`
feature, which selects Parry's ordered contact-subdetector caches as well as
deterministic math. Terrain collider admission and fixed-clock force delivery
use the same readiness boundary. The root-ramp/fixed-transition mating pair
alone excludes proxy overlap contact; rover and terrain collisions remain
enabled. These results are same-host evidence, not a cross-platform promise.

Egress checkpoint: native support casts now follow the mounted local strut
axis without wheel-spin rotation (core `51d7725af`, published and integrated
locally). Root-section guide entries rise from track level rather than placing
a full-height cross-member across the chassis breakover. Their measured guard
contact and explicit estimated profile are recorded in GRR-017 and the size
evidence document. Owned 49820 physically reaches the approach, ramp exit and
both survey gates; all four exit wheel casts hit the DEM within 0.5 mm of the
terrain sampler. Owned 49822 also reaches Base at tick 9408 / 156.8 simulation seconds.
The Modelica arrival taper lies inside the accepted arrival circle; the shared
The differential controller supports forward/reverse recovery.

The route uses one landed port-ramp horizontal frame, frozen when egress
begins. Survey points are through-gates with a one-wheelbase guidance lead;
Base is a stop. Numeric source radii are unchanged. Static marker presentation
still needs to follow the same frozen frame.

Owned headful 49821 exposed a separate source mismatch: workspace restore
retained older dirty Griffin, FLIP chassis and bell buffers. Fresh mount used
the current file, but reload consumed the old referenced-document overlay,
including obsolete pumps and a 0.12 m nozzle throat. Those buffers were
preserved as recovered untitled documents and a workspace snapshot backup;
the file-backed documents now contain the current saved sources. Core reload
must republish current persistent dependency overlays before asset reload;
that fix is core `cdaf079d7`; its focused test and production build pass.
Core `cea9295b5` contains the accepted final-arrival controller and both are
integrated into local core main. Headful source/reload acceptance remains open. This trial does not supersede the
strict same-source replay evidence above.

Releasing FLIP while ramps were still moving also failed the approach; the
candidate release now commands the ordinary wheel parking brake before native
adapter removal. The previously verified unattended unfold-then-release route
and this early manual release are separate acceptance cases. Owned 49822's empty-deck, deployed-ramp sustained pilot burn passes all ten
engine-command checks, including lift, continuing climb, angular envelope,
consumption and extinction. The first full-route verdict had two missing
landing-evidence checks: the preflight assigned a copied Rhai map. The caller
now retains the returned evidence. Final reporting now emits bounded milestone
fields rather than the task tree's function values. A warm full-route verdict
is running. Interactive early release, headful reload and uncontended
performance still need acceptance.


## Geometry-derived main-engine sizing, 2026-10-05

The saved main-engine study replaces inherited 33 kg/s command capability with
7.24479842644317 kg/s. It extrapolates the **historical** 700 lbf unit rating to
seven units, giving 21.7962859 kN; current flight ratings are unconfirmed.
The native isentropic nozzle model derives Mach, exit pressure and effective
velocity from the same bore dimensions used by the visual meshes. References,
applicability limits and numerical derivation are in the latest section of
`requirements/griffin-size-evidence.md` and `GriffinPressureFedStudy`.

The isolated native nozzle benchmark passes Mach 2/Mach 3 analytical cases,
a finite cold chamber and the Griffin rating. Early production runs failed;
those logs remain recorded in `griffin-size-evidence.md`. Rumoca topic fixes
`42c9ab55`, `9267b7bd`, `fb5eaa86`, `2d5ca942` and `da77eb4b` address runtime
start-value folding, Newton domain overshoot, restart selection and feedback
block ownership. Focused checks: 825 lowering, 119 algebraic-runtime and 328
foundation/structural tests pass. The normal locked LunCoSim build with exact
Git pin `da77eb4b200c3b9941c53b36fc2edf1c77b241ff` passes.
No final-refresh fallback or tolerance relaxation was added.

Current production evidence:
- Engine-command PASS 8, owned 49800, tick 2049 / 34.15 s. One held five-second
  pilot demand sustained liftoff; release extinguished useful thrust. During
  this short ascent angular speed stayed below .053 rad/s and upright Y above
  .996; this observation is not full powered-flight attitude acceptance.
  Trace: `terrain/target/griffin-feedback-block-engine-49800.log.gz`.
- Fuel exhaustion PASS 11, owned 49802, tick 241 / 4.016667 s; oxidizer
  exhaustion PASS 11, owned 49803, tick 151 / 2.516667 s. Held commands remain
  demanded; either depleted reactant removes native main/ACS thrust and shared
  plume/light outputs. Logs: `griffin-feedback-block-{fuel,oxidizer}-*.log`.
- Revised propulsion geometry PASS 94 on 49806, tick 2512 / 41.866667 s,
  including the converging chamber mesh. `griffin-engine-geometry-final-49806.log`
  and its status snapshot preserve the current source verdict. Focused Editor
  screenshot/readback at saved generation 30 and the assembled Griffin preview
  separately establish component appearance and saved state.
- Trial 49805 attached the geometry observer to the wrong scene root, replacing
  its command observer. It emitted no valid engine or geometry verdict; exclude
  it from acceptance. The valid command evidence remains 49800.

Starvation observers wait for measured depletion and one second of physical
valve settling, bounded by ten seconds. Fuel loads remain 1000 kg each as
inherited unsourced study inputs, not actual Griffin flight inventory.
Strict warm/fresh replay and full mission acceptance remain unresolved.
Core engine checkpoint `03bdc5018` is published on
`griffin-pressure-fed-engines`; main stays unmerged.

## Flight attitude and replay follow-up, 2026-10-05

Engine-command observer now also checks every burn tick for <= .1 rad/s
angular speed and upright Y >= cos(10 degrees). These source-owned simulator
acceptance limits reject a tipping straight-up liftoff; no flight GNC tolerance
is implied. Owned 49809 PASS 10, tick 2049 / 34.15 s:
`terrain/target/griffin-held-flight-attitude-49809.log` and status snapshot.
49807 was stopped before a verdict to correct an observer field name; exclude
it. No new alternate command path was introduced.

Latest source-pinned fresh pair: both landing-stability verdicts PASS, with
361/361 four-foot-contact samples over 60 seconds after touchdown. Replay FAIL:
5110 vs 5100 total ticks, touchdown ticks 1508 vs 1496 and different final poses.
Evidence: `terrain/target/griffin-sized-engine-replay/` and its driver log.
Same-process observer on persistent WorldGrid, owned 49808, FAIL at tick 60
of its second restart: Y differs 5.741181185e-6 m before contact. Main thrust
is zero and fuel mass identical at that sample; angular speed differs too.
The generated allocator source is unchanged across the compared reloads.
`terrain/target/griffin-sized-engine-warm-reload-49808.log`, status/readiness and
allocator-source snapshots preserve this failure. Neither test relaxes replay
limits. Initial target attachment by USD path was rejected (WorldGrid is a
runtime named entity); the single valid observer used `find("WorldGrid")`.
Core is published on its topic only; main integration remains prohibited until
strict reload is repaired and passes.

## Pressure-fed engine integration checkpoint, 2026-10-05

Requires core engine/library checkpoint `af6e0f7bf` and its pinned Rumoca
revision `135d8d39`. The core remains unmerged to main because replay fails.


Saved USD now uses two passive valves and a pressure-fed chamber in place of
the pump approximation. Numerical study values and sources are centralized in
`GriffinPressureFedStudy`; the visible seven-engine throat bores match its
derived area. Main bell saved generation 30 has focused Editor/readback evidence.
Production command/pressure PASS 8 at tick 2037 / 33.95 s. Fuel and oxidizer
exhaustion each PASS 11 at tick 180 / 3 s; affected propulsion geometry and
reference observer PASS 94. Logs: `terrain/target/griffin-pressure-fed-*-final-*`
(and `griffin-pressure-fed-engine-final-49788.log`). The first raw-opening
production descent oscillated; the revised
Modelica valve compensates pressure head from normalized flow demand while
retaining valve dynamics and physical saturation. The old command/depletion
PASS results below predate this feed change.

Full-scene trials exposed generic Rumoca Newton restart and compound-row
roundoff failures. The upstream fix is committed/published on Rumoca topic branch
`fix/algebraic-refresh-roundoff` at `135d8d39`; 116 focused tests pass. Core
dependencies now pin that Git revision; the normal locked build passes.
The runtime now reports the unmet variable in convergence failures. Do not
promote the current inherited 33 kg/s capability as real Griffin performance:
it is too aggressive relative to the published historical main-engine rating.
Next revise that estimate, with explicit sources and applicability limits.
Powered-flight attitude stability is still unaccepted, independently of the
command and starvation checks.
Do not merge the core stack as deterministic: fresh/warm replay still fails.

## Earlier A110 engine checkpoint, 2026-10-05

The twelve ACS jets now follow the supplier A110 reference: hollow 60.96 mm
exit, narrower chamber and two valve/inlet branches. Published dimensions,
derived performance and visual estimates are separated in the propulsion
requirements and latest size-evidence section. Production command/flow PASS
19 at 2160 ticks / 36 s; mesh checks PASS at saved component generation 80.
Normalized duty goes to the allocator; native delivered thrust goes to physics.
The current pure-axis control reserve is 277.1778424 Nm.

The sustained pilot observer now has a thin production fixture
`tests/griffin_engine_commands.usda` and a registered verification case.
It passed five checks at 1959 ticks / 32.65 s, including continuous five-second
liftoff and extinction after release (`griffin-a110-held-thrust.log`, exit 0).
Current main-feed architecture is confirmed
pressure-fed by Astrobotic's full-system hot-fire report; numerical flight
ratings remain unavailable and the old pump approximation remains to replace.

Strict fresh replay FAIL: 2.11176 mm final X divergence after identical
qualified touchdown. Same-process single-observer replay FAIL: 5.74177
micrometre Y divergence at tick 60, before contact. The restart observer now
retains the failed sample/field in ScriptInspect and prints the complete
structured result. Original tolerances and 90-second horizon are unchanged.
Do not merge the core stack as deterministic. Owned Editor 49776 also faulted
on terrain material continuation after reference updates; fresh saved-source
49777 has a ready assembly preview. Neither substitutes for warm reload.

## Current engine and terrain checkpoint

RCS now uses twelve referenced hollow nozzles and library exhaust effects.
Historical 25 lbf ratings, nozzle envelopes, mounts and the hypergolic palette
are explicitly sourced or estimated in GriffinPropulsionRequirements and
`requirements/griffin-size-evidence.md`. The geometry-derived allocator owns
normalized valve allocation; force actuators consume computed Newton thrust.
Tank availability crosses public MainPropulsion/AttitudePropulsion ports.

The controller's attitude limit is derived from the weakest composed pure-axis
pair with a source-owned 10% reserve (277.19165 Nm). Generic Lander yaw shares
that bound. Shared Modelica WrenchAllocator uses cyclic coordinate equations;
the earlier simultaneous solve left about 18 N of sideways force for a feasible
pitch request. Current production six-direction command fixture PASS 13,
2160 ticks / 36 simulated seconds, with pitch net force below 1e-6 N. Fuel and
oxidizer starvation each PASS 11 at 180 ticks / 3 seconds with demand held.
Four bounded nozzle mesh checks pass at the saved component generation.
Evidence logs and source rationale are in the latest size-evidence section.

The mission no longer includes the artificial landing slab, egress apron or
wrong-axis visual berm cylinders. Its target Y is the measured DEM height plus
the vehicle reference-to-foot height. Preflight and egress observations use
native TerrainHeight and wheel contacts. The last clean-DEM trial retained all
four feet through the stability horizon, but the full route overshot its first
survey target; route acceptance remains open. These observations predate the
new RCS/controller checkpoint and must be rerun before claiming current landing
or egress acceptance.

Core Lander commit b6c1c24e1 caps damping deadband below its own touchdown
angular-rate tolerance. The earlier 0.02 rad/s damping deadband could retain
rotation above the 0.005 rad/s cutoff threshold. The half-tolerance control
margin and simulator provenance are explicit in GriffinEngineControlStudy.
Current production landing stability PASS 1 at 5090 ticks: qualified touchdown
at tick 1484, followed by 361/361 four-foot-contact samples over the unchanged
60-second window including ramp deployment/release. Evidence:
`terrain/target/griffin-engine-contact-rate-margin.log`. This is a single run;
strict fresh/warm replay and current held-thrust reflight still need acceptance.
The observer now reports missing touchdown at the existing 300-second watchdog.

Core camera/input commits ad5813405 and 48b81a302 are local; production
lander-controls now PASS 16. Pending fixed-boundary and terrain causal/order
changes have built, but strict fresh/warm landing replay is still unaccepted.
The previous pair overlapped USD edits and cannot establish unchanged-fixture
repeatability. The fresh-process harness now pins binary, Twin and library
source hashes before and after each trial as well as the runtime SysML revision.
Do not merge the core stack as a deterministic-reload fix before those runs pass.

Remaining appearance work: bus/chamfer and panel packaging, actual folded-ramp
backs/mechanism, leg sleeves and footpad articulation, exposed equipment and
plumbing. Remaining physics work: repeatable landing/reload, full DEM-supported
FLIP route, pressure-fed main-engine fidelity and reconciled nozzle/feed/fuel
parameters. Public current engine performance and propellant inventories are
unavailable; do not substitute historical topology or call study values real.

## Latest visual and Editor update

The solar quadrant now follows the June 15, 2026 real Astrobotic hardware
photos rather than the previous mix of the 2021 belt and tall ESA rendering.
All three faces are tall, with source-owned stepped/equipment/leg contours,
clipped rectangular cells, copper-colored substrate gaps and silver frames.
The estimated broad frame is 1.866 × 1.727 m with a nominal 13 × 24 field;
the rail-fitted chamfer uses five columns at the same pitch. The distinct
contours omit cells instead of placing decorative bars across the openings.
Geometry, appearance and rationale live in `griffin_solar_requirements.sysml`;
source links and remaining gaps are in `requirements/griffin-size-evidence.md`.
Counts, dimensions, face assignment and unseen contours remain study estimates.

Saved-source solar PASS 152 (78 ticks, 1.3 simulated seconds); combined
Griffin/FLIP visual PASS 126 (8 ticks). Both CLI processes exited 0.
One-row-per-tick solar observations retain one source revision and USD snapshot
identity without exceeding Rhai's operation/array limits. The old divider
prims and duplicate solar-component builder were removed. Fresh owned port
49760 reads the saved vehicle with a ready preview at generation 0. Close-up
component review: `terrain/target/assembly-editor/griffin-hardware-solar-component.png`;
whole-vehicle review: `terrain/target/assembly-editor/griffin-hardware-fresh-editor.png`.

Warm port 49759 lost its vehicle preview projection fence after component
reference updates; same-identity renewal and reopening did not restore it.
Explicit authored saves were therefore followed by fresh saved-source gates
and fresh Editor review. This is a recorded generic Editor/reload gap, not
reload acceptance. No landing/contact parameters changed in this appearance
pass. Next visual work is the bus plan shape and array interface, folded ramp
backs/confirmed mechanism, then leg sleeves, footpad joints and exposed
plumbing. Warm reload, held-throttle reflight and full rover egress remain open.

Seven hollow main nozzles and the raised skirt frame are committed in `fed8e99`.
The silver exterior now reuses the shared LunCoSim foil shader with explicit
photo-based estimates in GriffinVisualConfiguration. Prism end-face winding
is corrected, and the two root ramp shafts match the existing 1.408 m
source-owned split-shaft layout. Saved-source bus PASS 355 and ramp PASS 1277;
see the latest evidence section. The correctly framed assembly screenshot is
`terrain/target/assembly-editor/griffin-current-framed.png`. Full-route egress
remains unaccepted.

Core commit `2711489c1` fixes stale explicit geometry queries in standalone
Editor previews; its windowed production projection gate passes. It is local
and unmerged. ClearScene can still empty retained previews, and deterministic
landing/reload remains FAIL; keep these separate from visual gate results.

## Latest landing-gear state

The canonical vehicle uses one inclined bus-to-foot prismatic joint per leg;
barrel and piston are visuals owned by the bus and foot respectively. The
previous V-brace hinge and independent shock bodies are removed. The three
visible members and their attachment datums follow the PGH hardware reference;
secondary brace compliance and the lumped 180 kg/leg mass are documented
approximations. See `requirements/griffin_landing_legs_requirements.sysml` and
the latest section of `requirements/griffin-size-evidence.md` for calculations.
The nominal joint anchor is the foot hub in the bus frame, not the leg root.

The geometry gate passes. Settled live samples show axial compression with
transverse error around 12 micrometres or less. The latest smooth-ramp pair
passes the unchanged 60 s landing stability predicate with 361/361 four-foot
samples in each run. Six-second quintic quarter-turn commands reduce the
observed ramp reaction; timing is explicitly a study estimate in SysML.
Fresh-process trajectories still differ by 0.11 mm in X, above the 1 micrometre
limit, so determinism remains FAIL. Core `3a70f8692` fixes script command
sampling before Modelica dispatch (rocket regression PASS 15); the separate
lander-controls fixture still fails eight assertions with both binaries. Same-app
contact replay and mounted topology refresh safety are also unresolved. Do not
merge the pending core changes to main as a deterministic-reload fix yet.

The route has five milestones and matching five completion events. Model
commit `9cd5a72` is pushed. Artificial landing/egress slabs remain until their
pad-dependent acceptance contracts are replaced with terrain observations.

## Model ownership

- `vehicles/griffin_1.usda` is the canonical integrated Griffin lander. It composes the lander, collision geometry, and replaceable component references.
- `vehicles/flip.usda` is the canonical integrated FLIP study vehicle. It composes the physical mobility model, chassis collision geometry, and reusable wheel, suspension, mast, and solar visual components.
- `scenes/griffin_flip_visual.usda` is the review composition; mission and verification scenes reference the same `griffin_1.usda` and `flip.usda` vehicle sources.
- The combined visual review has one manifest verification binding. Its SysML objective covers Griffin's visual requirements and FLIP's hosted-rover presentation requirement; the independent FLIP component verification owns the full rover contract.
- SysML under `requirements/` owns requirements, typed configuration identities, station datums, and study dimensions. Rhai builders make dry plans from those values and submit typed Editor edits. Composed USD is the realization to inspect. Rust provides shared modeling, authoring, physics, and verification capabilities.
- `scenarios/tests/` contains requirement observers. `tests/` contains their small USD fixtures; fixtures reference the integrated Griffin source.
- Twin-local reusable component assets live under `components/lander/` and `components/rover/`, including Griffin's body collision geometry and physical landing-leg module.

## Landing-leg connection

The four leg roots use the ordered `legStations` and radial rotations in `requirements/griffin_visual_configuration.sysml`. `GLL-009` in `requirements/griffin_landing_legs_requirements.sysml` requires each visible `BodyMountArm` to overlap the bus perimeter frame and mount axle, and requires a suspension joint at that same station. The arm dimensions are derived from the bus envelope, frame section, station, and clevis dimensions.

The Editor observation of the composed vehicle returned, for all four legs:

- body-mount overlap with `Bus/PerimeterFrame`: 0.114 m;
- overlap with `MountAxle`: 0.050 m;
- prismatic joint bodies: `/Griffin1` and the matching `/Griffin1/Leg*` root;
- historical joint anchor: the corresponding typed leg station (superseded by the current foot-hub anchor above).

The leg assembly therefore attaches to the bus structure. `Nozzle/MainEngineCluster/EngineSkirt` is a separate render-only engine surround and is not the leg interface. Astrobotic's public lander guide says the four landing legs are fastened to the bus and describes an internal truss tying the shear panels into the central column. The reference image supplied during review is captioned as an earlier Griffin concept, so it is useful for visual comparison but does not establish current flight geometry. Public sources: [Astrobotic Lunar Landers User Guide](https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf), [Space.com's image caption](https://www.space.com/space-exploration/spacex-falcon-heavy-launch-of-private-griffin-moon-lander-now-targeting-mid-2026).

## Current site-time and Editor state

The surface-operations scene owns the reproducible NOBILE03 study anchor and
TDB epoch. The combined visual-review scene now carries that same typed
`LunCoEpochAPI`, anchor, and referenced `SolarSystem`, so its Sun is resolved
from the selected scene time and site. The Editor plan read the values from the
composed surface-operations scene, then applied them in one generation-checked
typed operation batch. Composed readback confirmed latitude
`-84.72672255°`, longitude `29.14428685°` east, normalized height `0 m`, body
`301` (Moon), epoch `2461395.5` TDB, and the referenced Sun/Earth/Moon system.
The saved document is clean after the edit.

JD `2461395.5` is the repeatable study epoch on the 2026-12-21 TDB calendar
date. Public mission material currently gives a late-2026 launch window, not a
surface landing timestamp, so this is not flight-timeline data. The exact
landing site and mission-window Sun envelope remain unresolved.

Current authoring state:

- Every review, mission, and FLIP verification scene references `vehicles/griffin_1.usda` or `vehicles/flip.usda` directly.
- FLIP's storage capacity is projected from its source-owned energy and nominal-voltage requirements into the battery model's Ah interface. Its solar panel reads the live Sun vector through a local EnvironmentProbe and the FLIP system boundary; the source-owned peak rating sets the generic output limit. The Editor-applied inputs and direction wiring were read back from the composed vehicle.
- The review scene contains no detached sphere placeholders.
- The ramp visual component was rebuilt from the SysML plan at its 12.228605 m surface length and saved through the Editor. Its composed component has rails, support members, posts, tracks, and 12 pairs of treads.
- All Griffin requirement fixtures now reference `/Griffin1` from the integrated vehicle.
- Landing-leg readback returned `ok`, with visual-to-proxy pad geometry matching within 0.001 m and all four bus mount/joint observations available.
- The visual-review scene now shares the surface-operations scene's typed site/epoch and celestial-system reference. Its composed root and solar-system child were queried after projection, visually inspected, and saved.
- The solar configuration has three typed identities and stations on the forward, beveled forward-starboard, and starboard faces. The panel component uses paired local brackets and support links; each vehicle instance references that shared asset, uses its rail-derived width, and is checked at the configured station and orientation.
- The solar component and instances now use source-owned pitch-coordinate contours through the frame, backplane, substrate and clipped cell rows. Their distinct equipment/leg openings remain open; old grid dividers were removed. The values are visual-study assumptions guided by the photo, not approved dimensions; the render-only panel has no collision proxy.
- The three-array layout has been visually inspected in the open Editor. Its lower clearance shape is modeled qualitatively, but the released panel contour, installation dimensions, array envelope, and support datums remain replaceable study values pending controlled mission data.

These are Editor and composed-readback observations. They do not establish mission-level landing or egress acceptance. The Editor-loaded review scenario emitted a failing visual packet; the current counts and physics blockers are recorded in `contracts/implementation_gaps.md`. No headless test suite was started during this authoring pass.

## Next work

1. Run `requirement_quality_audit()` explicitly from the Griffin requirements tool and review its findings. Apply only justified requirement edits; startup remains policy-neutral.
2. Migrate remaining Griffin parameter maps to typed feature-path observations. GSA-005, GSA-006, and GSA-009 now author source-owned expected values and tolerances through standard constraint-usage feature bindings; `SysmlModel.required_constraint_irs()` exposes the effective dependency paths and `source_literal_observation()` supplies resolved source literals. No Editor/runtime execution was made for this update.
3. Replace the solar-panel contour estimates and other approximate panel datums with the controlled Griffin-1 panel definition when available; verify cutout clearance, installed transforms, support and hinge interfaces, and electrical behavior against that definition.
4. Compose the saved ramp visual component under the integrated port and starboard physical ramp roots. Preserve the physical track colliders, avoid duplicate visible geometry, and derive both poses from the ramp SysML configuration.
5. Review the leg-to-bus mount appearance in the Editor against current Griffin-1 references. Define any additional visual bracing as a source-backed study requirement derived from the bus and leg interfaces.
6. Use one dry Rhai plan, one generation-checked typed Editor batch, composed readback, and save for each geometry edit. Separate focused requirement observations from full Twin/runtime acceptance.

## Repository integration

The Twin checkout is already on `main`; inspect `git status`, ancestry, and the exact staged diff before each commit. The core `main` worktree already contains the current terrain merge and local render-defaults commit. Report local commits and remote pushes separately; do not push unless requested.

The current prioritized implementation gaps and standards review live in
[`contracts/implementation_gaps.md`](contracts/implementation_gaps.md). Keep
that review as the current status source; this handover records the Twin's
authored ownership and work sequence.

2026-10-04: corrected the protruding engine-skirt corners. One mitered octagonal
rail and matching shell now derive from the body profile; the source records
image references and estimated stock/envelope sizes. Existing propulsion gate:
PASS 94, with bell fit and bus-footprint containment. Fresh Editor review on
owned 49758 confirms the square corners are gone. Warm-reload mismatch remains
open. Next priority is the reported held-Space short hop versus repeated-Space
liftoff: compare live control ownership, held input, delivered force and mass;
chamber feed pressure is not a thrust measurement.

2026-10-04: solar belt now uses two 1.866 x 0.705 m modules plus a narrower
six-column chamfer module on one quadrant, with 129 mm square cell pitch.
Removed the speculative opposite-face array. Ramp intermediate hinges have
compact circular tongues and matching parent fork cheeks at native joint
anchors. Source-backed rationale distinguishes the Astrobotic 2021 layout
from ESA's partly-open artist pose; stock and deployment sequence remain
explicit study estimates. Solar, ramp geometry and flight-stow gates pass.
Fresh owned Editor 49759 confirms saved fittings; earlier 49758 had a stale
canonical-query owner despite current authored data. No physics drives or
masses changed. Held-Space hop/reflight and warm-reload mismatch remain open.
# Ramp appearance checkpoint — 2026-10-05

The physical walking plates now carry the sourced dark finish on the two
reusable ramp assets and all six installed sections. Geometry and physics
attributes are unchanged. Owned Editor API 49838 vehicle generation 74 is
projected and saved, including the last toe after lease renewal/reopening.
Focused component and assembly screenshots are inspected. The saved-source
ramp gate passes 1281 checks; flight-stow also passes. Both observers now
measure the sloped root guide's existing breakover datum correctly.
Logs: `terrain/target/griffin-ramp-finish-final-gate.log` and
`griffin-ramp-finish-stow-gate.log`. Sources and rationale are at the start of
`requirements/griffin-size-evidence.md` and in the owning ramp requirements.

Next correctness defect: the tall side panel intersects the folded toe and
guides. Composed toe origin X=1.602948 m, guide minimum X=1.469811 m, panel
plane X=1.94 m. The 60 mm RCS skin standoff also predates the 220 mm panel
standoff. Repair and verify the actual mount/transition/exhaust interfaces;
do not hide either defect with an independent visual proxy.
