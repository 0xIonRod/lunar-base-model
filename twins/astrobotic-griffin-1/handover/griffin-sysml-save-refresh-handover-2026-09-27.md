# Griffin SysML save refresh handover

## Outcome

Saving a mounted SysML source now refreshes the Twin's formal analysis from the
saved document snapshot. The refresh is generic to Twin analysis; it is not a
Griffin-specific check or editor workaround.

LunCoSim commit `54acee747` adds the `DocumentSaved` observer in
`crates/lunco-sysml/src/analysis.rs`. It matches the saved file against the
mounted Twin's typed source set, marks analysis pending, reloads the matching
`twin://` asset, and analyzes after the fresh asset event. Reload or analysis
errors remain visible as failed analysis state. Authoring guidance is in
`docs/architecture/24-domain-sysml.md` and
`skills/sysml-requirements/SKILL.md` in the LunCoSim repository.

## Verification evidence

- Focused analysis tests passed: `scripts/run_rust_tests.sh -p lunco-sysml --lib --filter analysis::` (10 passed).
- `cargo build --bin luncosim` passed.
- A disposable headless production session loaded the Griffin landing-legs
  requirements scene and its mounted SysML document. Baseline analysis used
  source revision `3668496134584719680`; GLL-008's usage offset was `10515`.
- A reversible newline edit at that offset did not affect Twin analysis before
  save. Saving refreshed analysis to source revision `9173006176266995611` and
  moved the usage offset to `10516`. Reverting and saving again restored the
  baseline revision and offset.
- The requirements file SHA256 before and after the operation was
  `e1408760a703a799cbc91c227092af3078e2f6d35ac20b1b9749c1cad1f89512`; no edit
  remains in the source file.
- Griffin's `contracts/implementation_gaps.md` records closure of the saved
  SysML analysis gap in model commit `1bcd051`.

Both repositories were pushed and checked against their remotes: LunCoSim
`main` is at `54acee747`; the Griffin model `main` is at `1bcd051`. Each matched
its `origin/main` at handover time.

## Scope limits

This proves save-triggered source snapshot refresh and formal analysis for the
tested SysML subset. It does not verify Griffin geometry, physical behavior,
flight accuracy, or landing acceptance. Use the current prioritized work list
in `contracts/implementation_gaps.md` for model work.

## Continuation work (2026-09-27)

The follow-on authoring work was completed and committed in the model checkout.
The exact visual fixture was reloaded in an isolated Editor session before the capture;
the saved review camera now frames the lander study, FLIP on its adapter, both
ramps, solar arrays, legs, and South Pole surrogate terrain together. The
review image is
[`griffin-visual-review-2026-09-27.png`](griffin-visual-review-2026-09-27.png)
(2560 x 1568, SHA256
`06be93fbf1129e931bd14fc4bf40d838ede072f8926dc92bd8316aa089867bfd`). It is
framing evidence, not physical or mission acceptance.

Port and starboard ramp transition bodies were authored through the production
typed Editor API and saved to `vehicles/griffin_1.usda`. Composed readback at
document generation 58 found each transition as an unscaled rigid-body Xform,
with its source-owned mass and inertia, an enabled collidable contact cube,
and a fixed joint to the lander. This establishes the static deck interface;
it does not establish deployed articulation or successful FLIP traversal.

The referenced toe component's contact geometry was also read through the
composed vehicle stage for all four port/starboard track meshes. At document
generation 58 / stage generation 3, each was an enabled convex-hull Mesh with
the source-mitered 8-point section: the upper toe edge ends at `x = 4.0762014
m`, the lower edge at `x = 3.9197299 m`, a 0.1564715 m bevel. Its transform
places the tracks at `z = +/-1.15 m`. This closes static mesh presence and
readback; transformed deployment contact and rover traversal remain unverified.

The same typed Editor path restored the seven engine-bell references and skirt
visual reference. Composed readback found `Engine01/Bell` and the skirt shell.
These remain render-only geometry; propulsion behavior and photometry stay
under their existing owners. The save serialized the composed vehicle stage
and caused a broad textual diff in `vehicles/griffin_1.usda`; that source diff
was reviewed before commit.

`requirements/griffin_vehicle_assembly.sysml` now defines the system-level
composition and multiplicities, a separate FLIP reference part, and typed
adapter/joint paths. `griffin_requirements.sysml` imports the vehicle type and
owns its single `missionVehicle` usage. The payload release interface records
touchdown-and-settle and egress-path readiness as separate required gates.
Identity/station arrays and compatibility count attributes still have
multiple owners, and no generic source-feature-to-USD/provider binding was
added. A fresh mounted-Twin analysis included all 23 SysML sources at source
revision `6305100017349410906`; the new package, imported subsystem types,
`missionVehicle`, and hosted-FLIP reference all resolved with no parser
diagnostics. `ValidateTwin` passed its manifest/source-set preflight.
`ValidateSysml` still returns `ok=false` for 16 existing missing-subject lint
findings in `flip_cad_requirements.sysml`; none are in the new graph.

The earlier combined Editor packet reported 25/76 visual checks failing. After
the bus and vehicle visual updates, a fresh run passed all 82 checks in six
packets at source revision `6305100017349410906`. This closes the authored
visual assertions for that composed fixture, but does not establish dynamic
ramp articulation, rover traversal, or mission acceptance.

The surface-operations route preflight was also repaired: it now checks the
authored marker positions before simulation, uses absolute USD path lookup,
and agrees with the SysML rover exit marker at `x = 12.8 m`. A fresh run passed
preflight and began powered descent. The lander moved from its 60 m start
altitude, but no `lander_touchdown` event was observed before the session was
stopped; the mission remains `NO-VERDICT`, and ramp deployment and FLIP egress
were not reached. The runtime reported five Avian joint-start seating residuals
(angular residuals of 90° or
180° and translation residuals of 1.963 m), so physical acceptance remains
open. Do not infer it from the camera or static readback.

Public sources do not provide the controlled interface/CAD package, full mass,
centre-of-mass and inertia set, released propellant and engine parameters, or
the exact Nobile landing timeline needed for an as-built, flight-accurate
simulation. Keep those as explicitly replaceable study assumptions until
authoritative source data is available. The pulled model update `86796da` fixes
the propulsion inputs; the fresh production session compiled the main
propulsion, attitude, GNC, sensor, and FLIP systems. Dynamic plume behavior is
not established by compilation.

The remaining model work is tracked in `contracts/implementation_gaps.md`:
collapse component identities and multiplicities to canonical source ownership;
bind the typed graph to composed USD and provider observations; investigate the
fresh Avian joint-start seating residuals; demonstrate dynamic ramp articulation
and FLIP traversal; and produce a touchdown/mission verdict. The 82/82 visual
run, engine-reference restoration, and static ramp/transition readbacks close
their corresponding construction checks. Do not promote surrogate inputs to
flight-accuracy claims without source provenance.

## Workspace state for continuation

- At the earlier save-refresh handover, the model checkout was on `main`,
  matching `origin/main` at `1bcd051`. This continuation was fast-forwarded to
  pulled `origin/main` commit `86796da`; the reviewed Twin source, reports,
  requirements, and visual evidence are committed on `main` in one follow-up
  commit. That local commit has not been pushed.
- LunCoSim `main` matches `origin/main` at `54acee747`.
- `cargo clean` was run in the LunCoSim checkout and removed 10.2 GiB of build
  output. The sccache contents were preserved; its disk limit is configured to
  25 GiB.
- An existing windowed Editor process on port `47123` was left running because
  its USD documents had unsaved edits. It was not used for this validation.
  The disposable headless process on port `47124` exited cleanly.
- Earlier Editor sessions on ports `3864` and `3865` remain open. The vehicle
  source document in `3864` and visual camera document in `3865` reported dirty
  state; they were not saved again or closed. Headless sessions on ports
  `3869` and `3870` were used for the fresh checks and exited cleanly. The
  earlier session on port `3868` was left untouched.
- LunCoSim runtime source for the latest checks came from the `terrain`
  worktree on `terrain-streaming` at `eaa9bad`; it still has six unrelated
  staged SolarPanel/acausal changes. They were not touched or committed.

The earlier save-refresh report remains a separate historical record. This
continuation updates its model evidence without changing that save-refresh
result. The existing engine-plume handover is unchanged.

## Continuation work (2026-09-27, ramp flight stow)

The physical three-section ramps now hold a source-owned +90° middle fold and
-90° toe fold for descent. The rail cubes stay on the upper side of their
walking tracks: their local bottom Y is 0.09 m, equal to the walking-face Y.
After `lander_touchdown`, the mission waits 1.5 s, commands the four
intermediate joints to 0°, waits 3 s, then deploys the two deck hinges. The
stow angles are replaceable study assumptions; the supplier mechanism ICD is
still unavailable.

`GRR-017` and `GRR-018` now cover flight fold, post-touchdown unfold target,
rail-to-track face placement, and composed rail clearance above the landing
legs. `GRC-025` evaluates the composed-world envelope. The focused
`Verify_GriffinRampFlightStow` run passed 61/61 checks at source revision
`1134567362502136608`. It queried 12 rail shapes and 40 landing-leg geometry
shapes: lowest stowed rail bottom Y=5.19 m, highest leg top Y=2.44 m, clearance
2.75 m. The new requirement evidence links resolve through
`griffin_requirement_sources.sysml`.

A production surface-operations attempt began powered descent and advanced
2,000 ticks (33.3 simulated seconds), then ended `NO-VERDICT` without a
touchdown event. The unfold and deck deployment steps were not reached. That
run reported two 180° Avian joint-start seating residuals (zero translation
residual). A separate older run in the preceding section reported five
residuals; neither run proves a rail-caused rebound. Dynamic touchdown, joint
seating, ramp articulation, and FLIP egress remain unverified. The focused
static pass does not close them.

The `terrain` worktree was checked against `origin/main` at `b61caad`; it was
already synchronized (zero ahead/behind), so no merge was needed. Six
preexisting SolarPanel/acausal changes remain staged and untouched. `luncosim
test --list` currently hits an unrelated parse error in
`assets/scenarios/tests/scripting_task_contract.rhai:94`; direct execution of
the explicit Griffin scene works. No terrain or remote publication was made.

## Continuation work (2026-09-27, touchdown geometry and rail concern)

The landing reference is now explicit as a vehicle-reference height of 0.44 m.
It is a replaceable estimate from the current 4,950 kg study mass, four
4 kN/m landing-gear springs at lunar gravity, and the 0.06 m unloaded pad
bottom datum; it is not Griffin flight data. The body collision proxy is
translated to Y=3.2 m to align it with the rendered bus and keep the lower hull
clear of the landing pads.

The physical ramp deployment angle is now +/-0.4857867749 rad (27.833532
degrees). This includes the upper-face track thickness and derived toe miter.
The focused `Verify_GriffinRampTouchdownGeometry` run passed 6/6 checks at
source revision `13950898190506578966`; for both ramps the top and bottom toe
edges compute to Y=-7.52e-11 m against terrain Y=0. The route exit marker was
moved to X=15.60 m beyond the deployed ramp tip near X=14.06 m.

The same source revision passed `Verify_GriffinRampFlightStow` 61/61 checks.
All 12 composed rail shapes are on the upper face of their tracks. The lowest
stowed rail point is Y=5.19 m and the highest of 40 landing-leg geometry
shapes is Y=2.44 m, giving 2.75 m of clearance. During descent, the rails
remain folded; after the `lander_touchdown` event, the mission waits 1.5 s,
commands the four middle/toe hinges level, waits 3 s, then deploys the two
deck hinges.

A fixed-clock post-touchdown diagnostic ran under a 650 s wall timeout and
reached 390 simulated seconds without the lander's touchdown output. It
recorded a deep-contact sample at body-reference Y=-1.386 m with both
`any_leg_contact` and `all_legs_contact` set, then a sample at Y=9.115 m with
vertical speed +6.566 m/s. At the deep-contact sample the folded rails were
still about 3.80 m above terrain, so they could not have caused that ground
contact. The contact/landing path still needs investigation; the run did not
reach the ramp-unfold step or the full 60 s post-touchdown stability window.
This continuation does not diagnose or modify the Modelica landing dynamics.

An offscreen visual capture was attempted but did not produce a frame before
its 120 s timeout. The composed geometry checks above are the verification
evidence. The model repo changes remain local; no remote publication was made.

## Continuation work (2026-09-27, corrected transport fold and control sequence)

The physical flight-stow pose now folds all three ramp sections beside the
lander. Each root hinge holds a mirrored 90-degree upright target; both local
section hinges hold -90 degrees. The port root joint limits are -50/+120
degrees and starboard limits are -120/+50 degrees, keeping deployment travel
at the 50-degree operational limit while allowing the 120-degree stow side.
These are source-owned Twin study datums, not released supplier geometry. The
saved Editor document reached generation 36, root-layer revision 36, and
`dirty=false` after typed, generation-checked edits to both ramps.

The current `Verify_GriffinRampFlightStow` run passed 70/70 checks at source
revision `225344422510235598` (45 for GRR-017 and 25 for GRR-018). Its composed
stage query measured 12 rails and 40 landing-leg shapes: rail bottom Y=5.19 m,
leg top Y=2.44 m, clearance 2.75 m. The Editor review capture is
`handover/griffin-ramp-stow-review-2026-09-27.png`.

The operator sequence now keeps the root hinges upright while U or the guided
HUD action straightens the four section hinges, waits 3 s, then lowers the two
root hinges to their terrain targets and waits 4 s before enabling rover
release. G and the RELEASE ROVER button remain unavailable until that settle.
The app-wide objectives overlay and hint are cleared when this scenario stops.

Public [NASA ramp material](https://www.nasa.gov/image-article/off-ramps-moon/)
and [Astrobotic Griffin/VIPER test coverage](https://www.astrobotic.com/astrobotics-griffin-lander-and-nasas-viper-moon-rover-complete-complex-test-drives/)
show deployment or testing but do not publish the exact launch-stowed pose or
supplier mechanism ICD. The fold remains a replaceable study assumption; the
review image documents the model's current assumption, not as-built hardware.

This gate is a static pose/requirement check, not a touchdown, hinge-motion,
or rover-egress verdict. The headless test log still reports two ramp-transition
joint-start seating residuals of 1.388 m and 90 degrees before seating those
bodies onto their authored frames. Powered descent has not produced a touchdown
event in the recorded mission runs, so ramp motion, rover release, and the
post-touchdown stability verdict remain open. The new gate does not diagnose or
modify the unrelated Modelica landing dynamics.

## Continuation (2026-09-28, inward transport fold)

The user reference showed the folded ramps grouped over the lander deck rather
than flaring away from it. The saved source now uses a +120 degree port root
target and -120 degree starboard target (the starboard mount has a 180 degree Y
rotation); both intermediate hinges stow at +180 degrees. The builder, source
requirement, and focused verification all use this mirrored pose. These remain
image-based study angles, not released supplier geometry.

The saved Editor document is generation 50, root-layer revision 28, and
`dirty=false`. `Verify_GriffinRampFlightStow` passed 119/119 checks at source
revision `15986075037362209922`. Its composed envelope covered 12 rails and 40
landing-leg shapes: lowest rail bottom Y=4.785 m, leg top Y=2.44 m, and
clearance 2.345 m. The saved-pose Editor capture is
`handover/griffin-ramp-stow-review-2026-09-28.png`.

This is static pose and clearance evidence only. It does not establish the
touchdown trigger, powered hinge motion, rover traversal, or post-touchdown
stability; the full Griffin mission remains `NO-VERDICT`.

## Continuation (2026-09-28, reference-parallel transport fold)

After reviewing the supplied image, the earlier inward +120/-120 degree pose
still placed the two three-section bundles across one another. The source now
owns separate root datums: port holds +45 degrees with a +60 degree stow limit;
starboard holds -135 degrees locally with a -150 degree stow limit. Its 180
degree Y mount makes the two bundles parallel above the deck. The four
intermediate joints hold +180 degrees with their complete +/-180 degree travel
exposed. These are replaceable image-derived study assumptions.

Both side plans were applied through the Editor component builder, port at
generation 1359 and starboard at generation 1812. The matching projection for
generation 1812 reported `projection_ready=true`; the saved vehicle document is
generation 1812 with `dirty=false`. Composed readback placed the port middle
hinge at (6.0823, 8.0723) m and starboard at (-0.3177, 8.0723) m, preserving
their 6.4 m root-station separation. Root joint readback reported port limits
-50/+60 degrees and target +45 degrees, starboard limits -150/+50 degrees and
target -135 degrees. Each of the four section joints reported limits
-180/+180 degrees and target +180 degrees.

The composed rail/landing-leg bounds query measured all 12 rail paths and all
40 landing-leg shape paths. Lowest rail bottom Y=4.6172 m, highest leg top
Y=2.4400 m, for 2.1772 m clearance. The updated focused stow script now reads
the side-specific SysML values. No fresh `luncosim test` verdict was recorded
for this continuation; the earlier 119/119 result above belongs to the
superseded +120/-120 pose. The current model-only Editor capture is
`handover/griffin-ramp-stow-review-2026-09-28.png`.

This remains static fold and clearance evidence. It does not establish powered
hinge motion, touchdown gating, rover release, terrain traversal, or
post-touchdown stability; the complete Griffin mission remains `NO-VERDICT`.

## Continuation (2026-09-28, stacked section frames and focused verification)

The reference-parallel pose still authored all three ramp panels in the same
plane when both intermediate hinges were at 180 degrees. The physical-ramp
builder now offsets the middle section by 1.62 m and the toe by -0.18 m in
their respective parent frames. Their hinge anchors use the matching 0.81 m
rail-top and -0.09 m surface-half-thickness datums, so the panel frames coincide
at the deployed zero-angle targets. Typed local `Mesh` overlays preserve the
referenced ramp-track geometry instead of shadowing it with untyped prims.

The refreshed headless binary passed
`Verify_GriffinRampFlightStow` at 58 ticks: 131 checks, zero failures. The
composed bounds covered 12 rails and 40 landing-leg shapes; the lowest rail
bottom was Y=3.3444513 m, the highest leg point Y=2.44 m, and the measured
clearance was 0.9044513 m. The test emitted one transient startup warning while
the selected SysML source projection was not ready, then completed the full
verdict. Root limits remain port -50/+60 degrees and starboard -150/+50 degrees;
the four intermediate joints expose +/-180 degrees.

U and `request_ramp_unfold()` route through the touchdown gate to the staged
section-then-root drive sequence. G and `request_rover_release()` share the
post-touchdown release gate, and the HUD presents `UNWIND RAMP  U` and
`RELEASE ROVER  G` only in their corresponding phases. The Twin still defaults
to `scenes/griffin_flip_visual.usda`; the powered mission is the separate
`scenes/griffin_1_surface_ops.usda` scene.

The full surface mission was rerun with the refreshed terrain binary and
exhausted its 14,400-tick bound without a verdict or `lander_touchdown`; the
post-touchdown ramp drive and rover release therefore remain unverified. The
saved `griffin-ramp-stow-review-2026-09-28.png` predates this stack-frame
change and still shows the earlier splayed pose. The live Editor screenshot
endpoint returned a 16x16 render target, so there is no fresh visual acceptance
capture for the corrected pose. The stow geometry has a focused static PASS,
but its visual match and powered hinge motion remain open.

The ramp changes are committed locally as `5121fb0` on `main`; nothing was
pushed. The terrain checkout was fast-forwarded to `54ad69a32`, equal to
`origin/main`. Its six staged solar/acausal-network files were pre-existing and
left untouched.
