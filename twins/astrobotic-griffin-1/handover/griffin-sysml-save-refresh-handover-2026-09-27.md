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
