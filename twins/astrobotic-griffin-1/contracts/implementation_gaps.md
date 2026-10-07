# Griffin implementation and standards gap review

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


**Reviewed:** 2026-09-27
**Scope:** Griffin as the active model, FLIP as a separately loaded hosted
vehicle, and the generic Rust/Rhai/Editor capabilities needed to build and
verify the model.

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

## Current runtime acceptance — 2026-10-05

Core `568f5146f` canonicalizes authored USD contact endpoints before narrow
phase and computes surface gravity from native Position in the active frame.
Both mechanisms have native RED/GREEN regressions; nine bridge and fifteen
environment tests pass. The source-pinned fresh-process pair has exactly zero
final trajectory deltas, with four-pad contact in all 361 stability samples of
each run. Owned High rendered 49835 passes the unchanged strict 94-sample
retained replay, all 16 surface mission gates, and all 10 held-command reflight
checks. Actual rendered rover egress, seated legs, connected ramps and FLIP HUD
switching are inspected. Requirements record sources and rationale under GR-031.
See the current handover for artifact paths and the separation of evidence
scopes. Earlier reload/contact failures below describe earlier revisions.

The hardware model remains a source-documented integration study. Unpublished
flight dimensions, detailed bus plan shape/panel interfaces and folded ramp
backs remain estimates; runtime PASS does not establish hardware equivalence
or flight qualification. No new sustained FPS acceptance is claimed.

## Hardware appearance checkpoint — 2026-10-04

The June 15 real-hardware photos now drive three tall, shaped solar faces,
clipped rectangular cells and copper/silver appearance. SysML documents each
metric and silhouette estimate; the solar fixture passes 152 checks and the
combined visual fixture passes 126. These are saved-source component/graphics
results. The broad frame is estimated 1.866 × 1.727 m; the retained clipped-square
bus yields a much narrower chamfer panel. Bus plan shape, panel interface and
folded ramp backs/mechanism remain the next visual gaps. Detailed priorities
and references are in `requirements/griffin-size-evidence.md`.

A warm Editor dependency update stalled the vehicle preview fence at port
49759 even after lease renewal/reopening. Fresh port 49760 reads and renders
the saved vehicle with a ready generation-0 preview. This does not close warm
reload, deterministic contact, reflight or full route acceptance. No physical
landing or guidance parameters changed in this appearance pass.

## Current bounded update — 2026-10-03

The current saved bus/ramp fixtures pass 355/1277 checks after shared silver
foil authoring, directed mesh-winding correction and root shaft clearance.
Photo estimates and owner/readback evidence are recorded in
`requirements/griffin-size-evidence.md`. The current seven-engine underside
passed its separate clearance and configuration gates. These close bounded
geometry assertions, not physical landing, egress or reload.

Local core `2711489c1` admits the tracked standalone Editor preview as a live
canonical reader for explicit document geometry queries. The production
windowed material/geometry projection regression passes. Retained previews
can still be emptied by ClearScene; warm reload and deterministic landing
remain unresolved. Do not merge the pending core stack as an accepted
deterministic-reload fix.

The latest smooth-ramp pair passes the unchanged 60-second landing stability
predicate: four-foot contact in all 361 samples of each fresh run, no contact
drop records, measured ramp deployment and adapter release. Six-second
quintic quarter-turn commands are an explicit SysML study estimate; the source
ramp gate remains PASS 1277. Fresh-process determinism still FAILS (0.11 mm X
divergence versus 1 micrometre limit). Full route and warm reload remain open.
Local core `3a70f8692` fixes script-admitted command sampling before Modelica
dispatch, with red/green production rocket evidence (PASS 15 after the fix).
The lander-controls fixture fails the same eight assertions on both binaries.

## Finding

The Twin has source-owned parameters, split requirements, a componentized
visual assembly, a separately loaded FLIP asset, a resolved SysML relationship
projection, a bounded executable-constraint slice, and composed USD geometry
queries. It remains an integration study, not a complete Griffin system model.
The largest gaps are requirement coverage and binding workflows over the
resolved graph, complete typed provider provenance, source-to-realization
mapping, and physically qualified mission evidence.

The latest recorded Griffin requirements packet passed for its 37 requirement
usages and 23 verification cases: all 39 emitted evidence checks passed,
including composed geometry and the typed GR-005 source catalog. This checks
the authored study configuration and its verification procedures; it does not
qualify flight behavior or remove the separate geometry, physics, and mission
data gaps below. That packet's solver log recorded five Avian joint-start
seating errors: three angular residuals of 90° or 180° and two translation
residuals of 3.44 m. A later surface-operations run also reported five seating
residuals, including 1.963 m translation residuals; it stopped before touchdown
and produced no mission verdict. These runs are diagnostic observations, not
flight-physics acceptance.

The earlier combined Editor packet reported 25 of 76 checks failing (11 in
GV-002, seven in GV-004, one in GV-006, five in GV-007, and one in FVG-001).
After the bus and vehicle visual updates, a fresh run passed all 82 checks in
six packets at source revision `6305100017349410906`. This closes those
authored visual assertions for that composed fixture. It does not establish
dynamic ramp articulation, rover traversal, or mission acceptance. The saved
review image frames the lander, hosted FLIP, ramps, solar panels, legs, and
polar terrain together.

FLIP now has one integrated vehicle asset. Its SysML source owns the published
battery-energy and solar-peak ratings; the Editor builder converts energy to
the battery model's Ah input and projects the solar rating as a finite output
limit. The generic panel defaults to an infinite limit, and the panel's live
Sun direction is routed through the FLIP network boundary from its local
environment probe. The USD and Modelica source validators accept this wiring
and branch-free cap. Dynamic battery/solar performance remains unverified.

The source contracts are being aligned with OMG SysML v2.0: formal requirement
constraints use requirement-owned `require` memberships; verification cases
place requirement `verify` memberships in `objective` blocks; and a check must
identify the required constraint that produced its verdict. The current
bounded compiler/evaluator does not implement all of SysML/KerML. It must
report unsupported source constructs explicitly rather than treating them as
valid evidence.

Normative references: [OMG SysML v2.0 Language Specification](https://www.omg.org/spec/SysML/2.0/Language/PDF),
[OMG SysML 2.0 documents](https://www.omg.org/spec/SysML/2.0/About-SysML).

## Standards alignment and current mismatches

| Area | Current state | Gap / consequence |
|---|---|---|
| Requirement meaning | Five Griffin domain packages plus separate subsystem packages; some definitions provide only an informal `doc` statement | The audit's 154 informational findings mean “no formal SysML `require` membership”; they do not say that no Rhai procedure exists or that it ran. The current review resolves verification links for all 183 definitions, but the CLI does not check procedure execution or evidence freshness. Use a formal predicate for finite, measurable acceptance; use a bounded verification procedure/rubric and revision-linked evidence for visual, temporal, process, and documentary acceptance. Do not invent scalar predicates for those cases |
| Formal constraint ownership | Requirement membership roles are projected as standard `require`/`assume`; the generic IR selects constraints by snapshot-scoped handles, aggregates required memberships, and checks verification coverage through resolved `verify` links. It retains each usage's resolved formal-parameter handle and typed bound expression. Griffin's shared adapter resolves scalar source-feature bindings against those handles and evaluates the bound constraints | Griffin now exercises usage-bound constraints across solar, ramp, landing-leg, and deck geometry requirements; source literals and composed USD measurements enter as typed feature-path observations. Other verification paths still use name-keyed parameter maps. Defaults, output binding, and full specialization/redefinition traversal remain |
| Verification | Requirement `verify` references are inside `objective` blocks; Rust projects source-linked `require` membership, and `GR-036` owns landing-stability limits. The surface-operations preflight is authored to evaluate `GR-037` target datum and `GR-038` landing-pad/terrain continuity constraints from one SysML revision and one composed USD snapshot | Many text-only requirements still have no executable constraint. Passing `GR-037`/`GR-038` proves setup geometry only; touchdown, all-leg contact, suspension behavior, and post-touchdown stability remain unverified under `GR-036`. `GR-031` remains a separate process gate |
| Traceability | Twin manifest selects source packages, USD fixtures, scripts, and cases; Rust projects snapshot-scoped element handles, resolved references, typed relationship endpoints, and verification-to-requirement handle links. The GR-005 evidence catalog resolves its typed requirement and source references to typed locators and roles | Coverage evaluation compares resolved handles and GR-005 source provenance is exercised in the runtime verifier. Provider observations still do not share one end-to-end identity across source revision, realization, composed-stage generation, physics sampling, and resulting evidence. Status/check catalogs remain authored execution metadata; derive the requirement matrix from requirement, verification, realization, and evidence links |
| Units and frames | SysML type and literal measurement-reference identities use source-snapshot handles. Resolved linear `MeasurementUnit` definitions project SI dimensions, scales, and standard `UnitConversion::isExact` metadata from quantity-power factors, coherent SI base units, reference conversions, prefixes, and supported arithmetic unit initializers. Source quantities retain conversion exactness through typed native `Quantity` operations; the bounded Modelica length-vector adapter requires an exact resolved scale before lowering to SI | Static feature types still do not carry inferred units. Measurement uncertainty and instrument accuracy are not represented by scale exactness. Nonlinear and affine `MeasurementScale` mappings, unsupported definitions, typed frame identity, and end-to-end conversion provenance remain open. Griffin measurements are still mostly normalized to SI at the provider boundary |
| Geometry | Profiles, station vectors, counts, typed source handles, resolved SysML relationships, composed USD queries, effective Avian-cooked Mesh/Cube geometry, exact analytic collider dimensions and poses, and a generic NURBS-to-USD-Mesh collision cook exist. `GriffinVehicleAssemblyRequirements` now declares the top-level parts, multiplicities, and separate FLIP reference-part boundary | The part graph is not yet joined to every canonical instance-identity array or to generic provider bindings; some compatibility count attributes still duplicate multiplicities. Griffin currently has no authored NURBS patch to cook. The planner's successive-level convergence change is not a certified upper bound on exact surface error |
| Behavioral applicability | Mission order, sampling horizon, route phases, and release are mostly Rhai orchestration | The model cannot yet state and evaluate configuration, mode, phase, or temporal applicability as part of a reusable source-defined verification objective |
| Modelica relationship | Continuous models and parameters are selected through Twin tooling | No complete standard realization/parameter provenance graph ties each equation set and result back to the source feature and requirement revision |

SysML allows informal requirement documentation; prose is not itself a
standards violation. The mismatch is claiming implementation or verification
coverage where that prose has not been connected to a resolved predicate,
realized feature, and evidence result.

## Griffin-1 evidence and construction blockers

### Main-engine plume runtime status

Each `MainPropulsion/EngineNNPlume` declares the typed `PlumePhotometry`
outputs its bell's flame pair and light consume: `render_throttle`,
`visual_length_fraction`, `intensity`, and `radius`. The fuel-exhaustion
fixture observes Engine01's plume going dark when a reactant depletes.

### Surface mission run status

The surface route preflight now checks the authored marker positions before
simulation, uses absolute USD path lookup, and agrees with the SysML rover exit
marker at `x = 12.8 m`. A fresh run passed preflight and began powered descent.
The lander moved from its 60 m start altitude, but no `lander_touchdown` event
was observed before the session was stopped; no mission verdict was produced.
Dynamic touchdown, ramp deployment, and FLIP egress remain open. The runtime
also reported five Avian joint-start seating residuals (angular residuals of
90° or 180° and translation residuals of 1.963 m), which need separate
physical investigation.

### Ramp flight-stow and rail-clearance status

The physical ramp sections fold for descent with the middle hinges at the
source-owned +90° target and toe hinges at -90°. After confirmed touchdown, the
mission waits for **U** / **UNWIND RAMP**, commands all four intermediate hinge
angles to the level target, waits 3 s, and then commands the deck hinges to
lower the ramps. The two root deck hinges now have angular drives as well as
limits; they previously had limits but no drives. After a 4 s settle interval,
**G** / **RELEASE ROVER** detaches FLIP from the deck. These angles and drive
values are explicit study assumptions pending the supplier mechanism ICD.

The new `Verify_GriffinRampFlightStow` scene passed all 61 checks at source
revision `1134567362502136608`. It verifies the authored section transforms
and drive targets, section rail placement, and source-linked constraint
results. A composed-world geometry query measured all 12 rail shapes and 40
landing-leg shapes: the lowest stowed rail point is Y=5.19 m, the highest leg
point is Y=2.44 m, and vertical clearance is 2.75 m. Rail bottoms remain at
the track walking face in each section's local frame.

A separate surface-operations run advanced 2,000 ticks (33.3 simulated
seconds) after powered descent began but emitted no touchdown event. The
unfold and deck-deployment commands were therefore not reached. Startup still
reported two 180° Avian joint-seating residuals; the transition/landing
physics investigation and a touchdown verdict remain open. Do not treat the
static fold/clearance pass as dynamic articulation or landing acceptance.

The leg-frame hypothesis was rechecked against the Avian seating equation
`r1_target = r0 * localRot0 * inverse(localRot1)` and USD's `(w, x, y, z)`
quaternion order. The downward `localRot0` is a 180° Z rotation, so it must be
included when solving for each `localRot1`; the original PZ/NZ values satisfy
that relation for the authored ±90° Y body rotations. A temporary sign swap
that omitted `localRot0` has been removed. The earlier two runtime residuals
therefore remain unexplained and must be captured with the exact joint paths
and authored/runtime frame values on the next run. GLL-009 now has a formal
angular-error constraint and a Rhai observer that compares each composed
spring frame with its composed leg pose, retaining USD generation provenance;
that scene check has not yet been executed.

### Landing-leg contact geometry status

Read-only composed-USD checks on the loaded `griffin_1_editor.usda` scene
document and the dedicated landing-leg measurement scene now query all four
effective Avian pad colliders and visible FootPads from one document/stage
snapshot. Each cooked collider is
an analytic cylinder; cooked dimensions and centers match the visible source
with a maximum measured deviation of 0.0 m against the 0.001 m tolerance. The
GLL-008 geometry, contact ownership, and station constraints and the GLL-009
mount-path constraint return no findings. The measured minimum overlap is
0.114 m at the bus frame and 0.05 m at each leg's MountAxle. Both scenes now
declare the Griffin metre/Y-up stage metrics explicitly.

This is static composed geometry and ownership evidence. It does not establish
dynamic contact response, shock travel or damping, landing loads, or flight
geometry. The leg dimensions and stations remain study inputs until controlled
Griffin installation data is available.

The Twin-wide SysML analysis now invalidates when an indexed source document is
saved, reloads the matching `twin://` asset, and waits for the reload event
before rebuilding its snapshot. A headless Editor/API check against this Twin
confirmed that an unsaved edit leaves the snapshot unchanged, saving advances
the source revision and GLL-008 usage offset from byte 10515 to 10516, and
saving the exact revert restores the original revision and offset. The source
file hash and working-tree contents match the original after the check.

Astrobotic's current Griffin product page gives a seven-main-engine design,
four shock-absorbing legs, a flexible isogrid payload deck, and optional
egress ramps. Astrobotic's [solar setup post](https://lnkd.in/p/dJHz9duN)
describes transit Sun-pointing and places the surface panels in the quadrant
crossed by the mission-window Sun path. Its two-installed/one-remaining
statement records status at publication. The June 2026 integration photograph
shows three upright panel faces across adjacent sides of one lander sector,
with structural supports and clearance-shaped lower outlines. That is useful
qualitative installation evidence; perspective, occlusion, and the lack of a
scale datum prevent extracting exact panel dimensions, mount stations, hinge
axes, or load paths. Sources: [Astrobotic Griffin-1 integration photo](https://www.astrobotic.com/wp-content/uploads/2026/06/26.06.15_Griffin-1_PressConference_1348_Edit-scaled.jpg), [Astrobotic solar integration post](https://lnkd.in/p/dJHz9duN) ([canonical LinkedIn activity](https://www.linkedin.com/posts/astrobotic_two-solar-panels-integrated-to-griffin-just-activity-7450595533745975296-qBEA)), and [current Griffin product page](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/).

The authored source configuration and composed vehicle now contain three
referenced panel instances on consecutive forward, forward-starboard bevel,
and starboard faces. Their identities and stations come from SysML; each
instance's width is computed from its ordered pair of source-owned bus rails.
The reusable panel asset provides a centered lower clearance opening shared by
the structural frame, backplane, and cell field; the internal divider members
terminate at or split around the opening. The width and depth are currently
controlled by typed dimensionless study fractions (0.32 of frame width and
0.28 of frame depth), so the same component scales consistently on all three
faces. Those fractions reproduce only the qualitative silhouette in the public
image; they are not measured or approved Griffin-1 dimensions. The exact
installed station offsets, panel contour/cutout dimensions, support dimensions,
hinge/lock details, and electrical behavior still require controlled mission
data. The render-only panel surfaces have no collision proxy.

### Data package needed to make the vehicle construction-ready

The next model update should be driven by a Griffin-1 configuration-controlled
engineering package. Requirements should bind every measurement to that
baseline and declare one of `as-built`, `as-designed`, `mission requirement`,
or `replaceable study assumption` status.

| Requirement area | Required source data and acceptance evidence |
|---|---|
| Configuration and applicability | Vehicle/mission identifier, hardware revision, document revision/date, applicability, supersession, units, frames, uncertainty, and evidence role for each datum. Keep the Griffin-1 flight vehicle distinct from earlier Griffin/VIPER user-guide configurations. |
| As-built geometry | Controlled 3D CAD or dimensioned orthographic drawings; root datum/orientation; leg, tank, engine, solar, adapter, and payload stations; member profiles; panel cutouts; hole/bolt patterns; tolerances; and view/camera references. Compare composed mesh and collider against that source geometry with an explicit measurement method and source tolerance. |
| Solar installation and power | Three panel identities, panel-local frames/normals, installed transforms on adjacent lander sides, support/hinge/lock geometry, stowed/deployed and cruise/surface states, keep-out envelopes, harness/electrical interfaces, panel I-V/temperature behavior, battery usable capacity, attitude-control law and keep-outs, time-aligned Sun/attitude/power telemetry, and mission Sun azimuth/elevation. The post establishes qualitative transit Sun-pointing and surface-quadrant behavior; it does not publish installation datums, pointing limits, or an electrical power budget. |
| Mechanical interfaces | Payload-deck isogrid/bolt pattern and rated load; Griffin-to-FLIP adapter, release datum and loads; leg joints, travel/damping and foot contact; engine and attitude-thruster stations/cant/loads; tank vessels/restraints; and optional ramp hinge and rover-clearance interfaces. Preserve source-mesh-derived collision and prove clearances after composition. |
| Mass properties | Measured total/dry/propellant/payload masses, center of mass, full inertia tensor with declared body frame, uncertainty, and configuration/propellant state. NASA says Griffin-1 completed mass-properties testing, but public numerical results are unavailable. |
| Flight and surface behavior | Engine thrust and throttle maps, propellant properties, RCS thrust/impulse locations, GNC/landing state transitions, terminal velocities/attitude/drift criteria, payload release sequence, and the operational mode each value applies to. |
| Site, lighting, and hazard detection | Confirmed touchdown coordinates and local frame; terrain coverage and resolution appropriate to the 15 cm hazard-detection threshold; time/epoch and Sun ephemeris; thermal and shadow/eclipses; and communications visibility. The current 4 m/pixel regional DEM cannot verify a 15 cm hazard threshold. |
| Verification record | Requirement-specific acceptance procedure, measured source and configuration revision, uncertainty/tolerance, provider/document generation, sample interval where dynamic, raw evidence link, and distinct pass/fail/inconclusive/error outcomes. Image comparison can verify qualitative silhouette only unless calibrated. |

The surface-operations and combined visual-review scenes are time-aligned for
the same deterministic study snapshot: each root selects the solar-system
ephemeris, authored TDB epoch, and NOBILE03 site anchor. The visual-review
scene derives its typed site/time values from the composed surface-operations
root. At JD 2461395.5 TDB (2026-12-21 TDB calendar date), the simulator
ephemeris gives Sun azimuth 7.52° clockwise from north and elevation 6.49° at
that anchor. Astrobotic's [manifest](https://www.astrobotic.com/lunar-delivery/manifest/)
lists Nobile Region 2026 and NASA's [Moon Base update](https://www.nasa.gov/news-release/nasa-provides-update-on-moon-base-rovers-landers-missions/)
describes a launch planned later in 2026, but neither publishes the surface
landing timestamp; the authored epoch is not flight timeline data. The current
solar observer checks array geometry and visible support overlap, but does not
evaluate GSA-003 across the actual mission-window Sun envelope and approved
installation frames. GSA-010 also needs time-aligned transit attitude and
electrical-power observations. Verification against the flight configuration
requires the mission landing epoch/site and installation definition, plus
transit attitude and EPS data.

### Configuration conflicts to resolve

- Astrobotic's current product page specifies seven main engines. The earlier
  [Griffin lunar-lander User Guide](https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf)
  describes a five-engine propulsion baseline for its then-current
  polar/VIPER configuration. Do not blend those
  configurations: retain seven for the current product baseline, and require
  Griffin-1-specific propulsion drawings before asserting the as-built count,
  engine stations, or cant angles.
- The product page supports four legs but does not publish their station
  coordinates, shock travel, stiffness, damping, foot size, or structural
  loads. The Twin's four study stations are not installation data.
- Public photos establish the three-array silhouette and qualitative sector
  arrangement. The Twin now composes the three adjacent faces through one
  reusable referenced panel asset, with rail-pair-derived widths and connected
  study support geometry. The shared frame, backplane, and cell mesh now include
  one matching lower clearance opening driven by SysML study fractions; no
  public scale datum supports treating these fractions or the rest of the
  installation geometry as as-built dimensions.
- NASA confirms completion of Griffin-1 mass-properties testing, but no public
  mass/CG/inertia table was found. Keep inherited lander values explicitly
  surrogate until that measured dataset is supplied.

## Workarounds found

These mechanisms are currently useful migration scaffolding. They must not
become Griffin's permanent source semantics.

- `griffin_spec.rhai` contains a hand-maintained qualified-name ownership map.
  It avoids ambiguous short-name lookup, but it duplicates semantic navigation
  that should come from resolved feature handles.
- Component scripts pass parallel station/name/measurement arrays and compute
  cardinality, clearances, extrema, symmetry, and mesh face counts. A missed
  index or filtering branch can detach evidence from its source feature.
- USD path literals and child-name lists stand in for typed part usages and
  provider bindings. Moving a prim can invalidate verification without a
  compiler finding the affected relationship.
- Several geometric predicates are authored in Rhai even when their bounds
  now live in SysML. This includes mesh topology, layout, frame transforms,
  source-to-USD cardinality, and portions of landing telemetry acceptance.
- Length, angle, mass, and time fields use `Real` plus naming conventions;
  frame axes/origins are strings or comments. This is vulnerable to unit/frame
  errors and does not support safe conversion.
- Some missing runtime data is converted into sentinel values or a local
  Boolean check. Every missing, stale, malformed, or out-of-frame observation
  must instead keep its state (`unavailable`, `invalid`, or `stale`) and produce
  an explicit inconclusive/error result.
- Visual and flight geometry are separate assets, which is a sound ownership
  boundary, but their correspondence is not yet generated or proved from one
  typed feature mapping. The octagonal visual deck and central octagonal tank
  support are source-owned. Editor has migrated the physical deck to eight
  octagonal perimeter colliders plus a separate payload-deck collider, with
  composed readback confirming the source profile and clear tank opening. The
  GRR-012 composed-collider observation path exists. Port and starboard
  transition bodies have now been applied through the typed Editor API and read
  back together at document generation 58. Each is an unscaled Xform rigid body
  with SysML-owned mass/inertia, an enabled collidable contact cube, and a fixed
  joint to the lander. This is static interface evidence; dynamic ramp
  articulation and four-wheel rover traversal remain pending.
- Twin verification observers bind authored requirements to composed source
  and USD observations. The generic evaluator owns requirement membership,
  constraint evaluation, and verdict classification; observers supply the
  component-specific measurements that the shared provider surface exposes.
- Aggregate AABBs overstate adapter contact: the clipped octagon narrows near
  its full-width lateral corners, so contact must be checked across every
  lateral cross-section. SysML owns the transition length, derived from the
  octagonal source profile, adapter width, hinge station, required overlap,
  and interface margin. Generic `QueryUsdPrims` now returns the geometry
  produced by the same Avian collider cook used for runtime projection, with
  composed transforms applied into canonical-stage coordinates. Convex
  decomposition remains separate hull parts, not a filled envelope. The shared
  measurement library builds convex footprints and measures the minimum
  cross-section overlap across the adapter span, alongside transition length,
  top-face step, and hinge seam. Fresh transition and joint readback is recorded
  at generation 58; dynamic articulation and rover traversal remain pending.
- GRR-006/010 specify a mitered convex-mesh track toe. The standard mechanical
  relation derives the bevel run from track thickness and the commanded ramp
  angle. A fresh composed readback of all four port/starboard toe-track meshes
  at document generation 58 / stage generation 3 found the expected 8-vertex
  topology, collision enabled with `convexHull`, and the upper toe at
  `x = 4.0762014 m` versus the lower toe at `x = 3.9197299 m` (0.1564715 m
  bevel). This closes the static mesh presence/readback gap; transformed
  deployed contact and rover traversal remain unverified.
- The GRR-012 footprint and full-span cross-section calculation is a
  Griffin-specific verification relation over the *composed colliders* used by
  the physics scene. It belongs in Griffin's Rhai verification policy; NURBS
  surface geometry is not a better input for this check. Rust's generic job is
  to return exact collider geometry, coordinate frame, and source generation.
  Promote a footprint primitive only if independent Twins need the same
  relation or profiling shows the authored implementation is a bottleneck.
- NURBS collision derivation now uses the shared USD NURBS parser and trim
  handling, but a separate physical tessellation profile; it never reuses the
  Graphics quality setting. `PlanNurbsCollisionProxy` returns a read-only
  plan for an explicit document generation. `nurbs.rhai` turns it into normal
  `CreateUsdProposal` operations, so the generated child `UsdGeomMesh` is
  reviewable, journaled, and refreshable through the Editor. The proxy carries
  `PhysicsCollisionAPI`, `PhysicsMeshCollisionAPI`, `purpose = "proxy"`, and
  `visibility = "invisible"`; its typed `lunco:derived:source` relationship,
  cook settings, and `uint64` geometry fingerprint are authored on the proxy.
  Avian re-cooks the source, checks the generated fingerprint against the
  recorded value, and compares the authored proxy mesh before admission,
  rejecting stale or modified proxies. The Avian reader and proxy planner now
  share one typed capability contract and the plan reports the implemented
  modes. These are `none` (static/kinematic triangle mesh), `convexHull`, and
  `convexDecomposition`. OpenUSD also defines `boundingSphere`, `boundingCube`,
  and `meshSimplification`; all three are explicitly unsupported by Avian until
  their standard semantics can be implemented. Rhai authoring obtains
  structured mode records from one Rust capability contract: each record
  includes the USD token, cooked geometry, and rigid-body compatibility.
  `PlanNurbsCollisionProxy` returns the same records, so authoring and planning
  use the runtime's contract without a second allow-list or locally duplicated
  body restrictions.

  The planner requires a positive canonical-metre `max_refinement_delta_m` and
  adaptively refines untrimmed U/V grids or trimmed curve/grid settings. It
  records the selected resolution and symmetric sampled vertex-to-triangle
  change between the last two levels; physics admission re-cooks and checks
  that result. This is a convergence criterion, not a certified upper bound on
  exact NURBS surface error. Griffin itself currently contains no
  `UsdGeomNurbsPatch`/`LunCoLatheAPI` source, so no Griffin geometry was changed
  to exercise the new generic path.
- GRR-011 moves ramp mass and diagonal-inertia literals into SysML and checks
  their composed realization. They are explicitly labeled study proxies.
  GR-021 remains planned: authoring queries can read mass-property attributes,
  but Griffin still lacks sourced per-body center of mass and full-frame
  mass-property evidence for acceptance.
- Requirement status and check catalogs are still parallel string arrays in
  SysML. Their label is now explicit and they are not used as per-run verdicts,
  but they remain a manual status table. A generic coverage report should
  derive checked, unverified, planned, and blocked views from resolved
  requirement, verification, realization, and evidence records.

## Generic Rust features Griffin needs

### P0 — semantic source and requirement graph

- `lunco-sysml-ast` already projects snapshot-scoped element/feature handles,
  resolved references, and typed relationship endpoints; the IR provides
  source-linked expressions, scalar/quantity types, multiplicity metadata,
  and four-state results. Dotted feature chains and navigation through a
  path-valued argument to a scalar structured predicate input now preserve the
  resolved call-site path and provider dependency; the latter is compile-
  checked but not yet runtime-verified. Whole structured values and
  collection-valued navigation remain unsupported. This is not full-project
  KerML navigation: inherited/owned members, specialization, redefinition, and
  subsetting are not resolved as a complete reusable graph. Griffin still has
  qualified-name selection and manually maintained attribute-name lists in
  `griffin_spec.rhai`.
- The parser projects requirement `require`/`assume` memberships, verification
  target names for display, and snapshot-scoped resolved verification-to-
  requirement handles for coverage. Constraint membership inheritance
  currently follows one direct requirement usage-to-definition type edge.
- `SysmlModel.audit_requirements(policy)` now reports duplicate short names,
  optional project rules for short names, typed subjects and verification
  coverage, text-only requirements, unresolved verification targets, and
  unresolved names inside requirement definitions. The Griffin requirements
  tool exposes this as an explicit review operation; normal Twin startup does
  not enforce it. The `sysml-audit --engineering-review` CLI was run on the 21
  Twin requirement sources: it found no source diagnostics or policy errors,
  and resolved verification links for all 183 definitions. It reported 29
  definitions with formal `require` constraints and 154 informational
  text-only findings. Those findings mean no formal `require` membership; they
  do not imply that no procedure exists. The exact Griffin runtime verifier
  now executes and checks its evidence, but the CLI still does not run mapped
  Rhai procedures or assess evidence freshness, and the in-Editor audit action
  was not run. Standard usage-level feature-value bindings project through
  resolved formal-parameter handles; diagnostics for inherited defaults and
  general binding relationships remain open.
- The asset-level `luncosim --validate` path does not assemble the Twin's SysML
  package context: validating all requirement files together still reports
  cross-file names such as `GriffinRequirementSources::TwinAssetPath` and
  `FlipRequirements::FlipRover` as unresolved. The Twin-loaded review path
  resolves these sources, so this CLI result is not a project verdict. Add a
  manifest-aware validation mode that resolves imports before reporting
  semantic names. Standalone validation also flags the reusable SolarPanel
  mass API as outside a rigid body; its FLIP instance is nested beneath the
  rover body. Asset-context validation must distinguish reusable components
  from unmassed scene roots.
- The generic IR now compiles by exact snapshot-scoped constraint handle and
  evaluates every standard `require` membership on a requirement as one
  four-state result. It can validate the associated verification case through
  resolved `verify` handles. `assume` memberships remain context, not acceptance
  predicates. The Rhai `SysmlModel.evaluate_requirement` boundary accepts the
  typed requirement and verification objects plus typed feature-path
  observations.
- The generic IR now exposes `compile_required_constraints` and the Rhai
  `SysmlModel.required_constraint_irs(requirement)` method. Both the provider
  and evaluator use the same requirement membership selection and apply the
  same standard usage bindings, so a provider can inspect the exact effective
  dependencies instead of compiling a reusable definition in isolation.
  `SysmlModel.source_literal_observation(attribute)` emits a source-revision-
  scoped typed feature path and value for resolved scalar literals.
- Griffin's shared requirements adapter uses this path for source-bound
  constraints across solar, ramp, landing-leg, and deck geometry checks. The
  exact `luncosim test` run passed all 39 evidence checks against 37 requirement
  usages and 23 verification cases, including composed geometry measurements
  and typed GR-005 source provenance. This is runtime verification of the
  authored study fixture, not an interactive Editor audit or flight
  qualification. The source audit resolved all 183 verification links with no
  source diagnostics. Other Griffin checks still use name-keyed parameter maps.
  User-defined predicate calls rebase structured member paths onto resolved
  feature-valued actuals; that path has compile evidence only. Defaults, output
  parameters, and broader redefinition traversal remain open.
- The opt-in generic requirement audit is implemented and exposed from the
  Griffin requirements tool. Run it explicitly and review findings before
  using its policy as a gate. Text-only requirements are reported separately
  from unresolved names and invalid verification targets.

### P1 — quantities, geometry, and provider observations

- `lunco-engineering-values` and the neutral evaluator carry typed `Quantity`
  values and `Unit` contracts. Compatible dimensions are converted for
  arithmetic/comparison; multiplication, division, powers, and square root use
  coherent SI units. Observations reject a separate unit field and textual
  `{ value, unit }` quantity maps. The SysML source projection now resolves
  linear `MeasurementUnit` dimensions and scales into typed definitions for
  source literals; supported literal quantities enter the evaluator as native
  `Quantity` values. The Griffin Modelica length-vector adapter uses that
  reference and converts to SI without a parallel symbol table. Static feature
  type unit inference, affine/nonlinear `MeasurementScale` mappings, and typed
  frame/conversion provenance remain open. Standard conversion exactness now
  remains attached to native units and quantities through arithmetic; this is
  not a measurement-uncertainty or instrument-accuracy model. Most Griffin
  provider measurements still normalize to SI explicitly.
- `QueryUsdPrims` reads one composed snapshot and exposes the effective Avian
  collider for active collision Mesh, Cube, Sphere, Cylinder, Cone, Capsule,
  and finite Plane prims. Meshes return cooked triangle topology or convex
  hull vertices; convex decomposition retains each hull; analytic shapes
  return exact cooked dimensions and a collider-local-to-stage pose. Composed
  transforms and authored scale are included in the query result. It returns
  the document generation and canonical-stage generation as separate values,
  including for live-stage reads. The SysML evaluator now retains tagged source
  and USD-stage provenance and flags mixed generations for one document.
  Griffin's GR-018 observer now batches its eight perimeter beams, payload
  collider, and hierarchy root into
  one query. A source-owned GR-018 constraint checks the body's effective
  eight-vertex Cube hull and exact canonical-stage bounds. The deck observer
  checks each Avian-cooked shape and frame, verifies beam source dimensions and
  transforms, and compares the adapter's authored mesh points
  and topology to its SysML-derived geometry. It passes the batch's document
  and stage revisions through typed provider provenance. The broader SysML
  feature-to-USD mapping, static unit inference, `MeasurementScale` conversion,
  and frame resolution remain open. Interactive Editor preview
  and joined source/render/collider comparison remain unavailable.
- `QueryPhysics` already exposes mass, center of mass, principal inertia,
  readiness, support state, and FLIP wheel-ray samples with sample ticks. It
  does not expose general collider-pair manifolds, per-point impulses, full
  inertia tensors with their body frame, or the solver configuration needed
  to qualify those observations. A real FLIP run can inspect wheel hit target,
  normal force, tire force, and suspension compression; what is still missing
  is an evidence recorder and temporal reducer that proves the required wheels
  contacted the ramp over the full traversal interval. A static fit check is
  not traversal acceptance.
- The generic `UsdGeomNurbsPatch` collision cook uses
  `max_refinement_delta_m` to select adaptive tessellation and records a
  symmetric sampled convergence change. That change is not a certified bound
  on exact surface error. Editor preview/readback and applying the tool to a
  real Griffin NURBS source remain open; Griffin currently authors no NURBS
  patch.
- Preserve provider result states end to end. Inconclusive and error are not
  false requirements and must not be collapsed into a boolean.

### P2 — collections, behavior, and cross-tool provenance

- The generic IR already supports homogeneous scalar collections,
  one-based indexing, `size`, emptiness, `sum`, `product`, Boolean aggregates,
  and scalar `min`/`max`. Remaining collection work is feature-valued and
  structured collections, collection navigation, filtering/selection, and
  reusable reductions over modeled part usages. Apply the remaining semantics
  only when the Griffin source model needs them; keep cardinality and ordering
  from the resolved SysML multiplicity.
- Add configuration/mode/phase/time applicability and temporal sampling
  primitives before relying on scenario state machines for requirement meaning.
- Tie SysML realization/parameter identities to Modelica models, generated
  equations, solver settings, and result snapshots. A successful solve of a
  stale source revision must be rejected.
- Carry one evidence identity across SysML revision, compiled constraint
  fingerprint, provider snapshot/document generation, physics configuration,
  sample tick/time interval, and visual/run artifacts.
- Generate the complete requirement matrix and audit diagnostics from the
  resolved requirement/verification/realization/evidence graph. The shared
  evaluator now checks verify coverage by typed handles, but the Twin
  status/check catalog is manually maintained and each Rhai observer still
  selects authored qualified names and constructs evidence records.

## Editor and workflow tools still missing

- A model browser that navigates the resolved SysML feature graph beside its
  USD/Modelica realizations and shows unresolved/multiple provider mappings.
- A source impact view from edited feature to affected constraints, USD
  builders, Modelica parameters, verification cases, and stale results.
- Typed observation inspection that shows value, unit, frame, timestamp,
  source feature, provider, and source/document generation together.
- A geometry comparison view that overlays the source-derived design envelope
  with composed render and collision geometry, including an explicit physical
  versus visual discrepancy report.
- An Editor panel that previews the NURBS source beside the generated collider,
  reports measured geometric deviation and cooked collider readback, and makes
  an explicitly selected approximation easy to inspect. The Rhai planner and
  proposal path exist; the joined visual readback and tolerance report do not.
- A requirements matrix generated from SysML relations, with pass/fail/
  inconclusive/error/unverified shown separately and links to evidence.
- Editor verification actions for structural checks and controlled physics
  trials that use the active document, record the exact clock/solver settings,
  and reject stale generations.
- Reusable typed builders for octagonal structural members, support rings,
  contact proxies, interfaces, and joints. Builders should consume typed source
  values and return previewable, undoable `ApplyUsdOps` plans; Griffin-local
  Rhai should only select and compose these generic builders.
- The solar-panel refiner is now instance-driven: it consumes canonical typed
  identities, stations, orientations, ordered bus-rail pairs, and a shared
  component asset, then computes each panel width and local support attachment
  from those source values. The generic `SysmlModel.value` projection now
  preserves `Position[n]` as an array of native `DVec3` values; the Griffin
  Rhai tool consumes that typed projection and no longer reconstructs stations
  from `AnalyzeSysml` AST records. Broader object-valued and feature-valued
  collection mapping remains open in the generic SysML subset.
  The visual component now models a matching lower clearance opening through
  the frame, backplane, and cell field, using source-owned study fractions.
  Replace those fractions and refine the contour from the controlled panel
  drawing before as-built acceptance. The standalone solar observer now reads
  the three configured panel identities/stations and their paired bus rails;
  GSA-003 remains verification-link coverage only until the approved
  installation frames and mission-window Sun envelope are authored. The
  visual-configuration type scenario reads the canonical solar count and
  checks the forward identity.

## Griffin-specific model work, in order

1. **Completed in this migration:** correct landing-stability ownership and
   verification mapping. `GR-036` now owns the study bounds and required
   constraint; `GR-031` remains the execution determinism gate. Rust projects
   formal requirement constraint memberships, and the stability observer uses
   the generic evaluator.
2. **Completed in Editor:** migrate the physical deck collider to eight
   source-profile perimeter beams plus the separate payload-deck collider.
   Readback confirms source deviation within 0.001 m and leaves the tank
   opening clear. GRR-012 now has fresh transition-body, contact-surface,
   mass/inertia, and port/starboard joint readback at generation 58. Dynamic
   ramp articulation and rover traversal remain required.
3. **Started:** `requirements/griffin_vehicle_assembly.sysml` defines typed bus,
   propulsion, engine-visual, tank, leg, solar, optional-ramp, adapter, and
   hosted-FLIP parts with explicit multiplicities. Fresh mounted-Twin source
   analysis resolves its imports and the root `missionVehicle` usage with no
   parser diagnostics. Canonical identity/station arrays and legacy scalar
   count aliases still need migration to one owner, and the graph is not yet
   bound to composed USD/provider observations. `ValidateSysml` still reports
   16 pre-existing missing-subject lint errors in `flip_cad_requirements.sysml`.
4. **Partially complete:** the typed graph contains a `ref part hostedRover`,
   adapter path, surface-scene release-joint path, and separate required
   touchdown/settle and egress-path-ready conditions.
   FLIP remains a separate vehicle asset with one fixed adapter joint before
   release. Fresh topology and exactly-once ownership evidence still need to be
   bound to the typed part and evaluated against a new composed generation.
5. Connect source features to reusable component USD references and generic
   provider bindings. Keep FLIP loaded as its own component rather than copying
   its assembly into the Griffin scene.
6. Replace one Rhai geometric predicate at a time with a typed provider value
   and a source-linked constraint. Preserve the old check only until the new
   generic path proves its positive and negative cases.
7. Add mass, inertia, propulsion, thermal, power, contact, and landing cases
   only when their inputs have real source provenance or are explicitly marked
   replaceable study assumptions. Do not call surrogate data flight accuracy.

### Ramp fold and touchdown evidence (2026-09-27)

The physical ramp rails now sit on the walking-surface upper face and remain
folded above the legs during descent. The composed flight-stow check passes
61/61 checks: the lowest rail point is Y=5.19 m, the highest leg geometry is
Y=2.44 m, and vertical clearance is 2.75 m. A focused GRR-010 check passes
6/6 checks for both ramp toe edges at the terrain plane using the 0.44 m
vehicle-reference touchdown datum and 27.833532 degree deployment angle.
These values are explicit Twin study assumptions.

The post-touchdown mission now waits for **U** / **UNWIND RAMP**, levels the
four intermediate hinges, deploys the deck hinges, and enables **G** /
**RELEASE ROVER** only after the ramps settle. The HUD buttons use the generic
typed Rhai hook path. `physical_ramp_hinge_report()` exposes the composed
minimum and maximum of all six hinges in degrees and radians plus live
angle-port records; `set_physical_ramp_hinge_angle(name, radians)` validates
each request against those limits. A fixed-clock descent diagnostic ran for
650 seconds wall time (390 simulated seconds) without touchdown. It recorded
intermittent leg-contact flags, including one sample with all four flags set
at body-reference Y=-1.39 m, followed by a sample at Y=9.12 m and +6.57 m/s
vertical speed. The rails were still at least 3.8 m above the terrain at the
deep-contact sample. This rules out the folded rails touching the ground at
that event; it does not identify the cause of the gear bounce. The new
drive/button sequence and full 60-second post-touchdown stability requirement
remain unverified until touchdown and the operator actions are observed in the
production scene.

## Definition of a proper first Griffin slice

- The source graph contains typed component usages and a formal requirement,
  constraint membership, and verification objective.
- Constraint parameters bind to source/provider features through resolved
  handles; there is no Griffin-specific qualified-name or index relationship
  table.
- Generic Rust resolves the source and returns typed observations with unit,
  frame, source revision, document generation, and stage generation.
  Unsupported SysML remains a visible diagnostic.
- Rhai selects providers and sequences the observation only; it does not
  restate the requirement predicate.
- Editor authors a previewable typed USD plan, applies it undoably, and reads
  back the composed result from the same document generation.
- A result includes all four verdict states, source and document revisions,
  provider snapshot, configuration, and evidence links. Positive, negative,
  missing-data, and stale-generation paths are visible.
- Griffin render, collision, and physical interfaces agree with the same
  source-owned geometry. FLIP remains an independently loaded hosted vehicle.

Until these conditions hold, report Griffin as a structured study model with
explicit unverified and assumption states, not as a validated mission
simulation.
