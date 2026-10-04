# Griffin-1 Twin handover

**Latest update:** 2026-10-05 (older sections retain their original evidence scope)


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
