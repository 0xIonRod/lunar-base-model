# Griffin qualification checkpoint — 22 October 2026

This records the earlier checkpoint. The subsequent
[integrated packaging correction](griffin-integrated-packaging-review.md)
supersedes its outward ramp pose and dimensional assumptions; the results
below retain their original source and acceptance scope.

The goal remains open. This checkpoint strengthens skirt verification and
establishes a current full-registry baseline; it does not certify the whole
model as accurate, visually accepted, fast or fully passing.

## Current visual review

The current structural visual gate passes all **134 checks** after updating
the review layer to the source-selected native WESL terrain shader. This
checks authored geometry and topology; it does not qualify ramp appearance.

The user rejected the ramp appearance. The [ramp analysis](griffin-ramp-visual-analysis-2026-10-22.md)
confirms that the current root sections flare outward, while the supplied
photograph shows inward stowage. Their approximately 6.36 m outer-end span
makes the 3.60 m bus look small. Body resizing is not established by that
reference. Ramp visual acceptance remains open; component conformance passes
below do not override this finding. No ramp geometry was changed in that analysis.

## Current Griffin authoring checkpoint

The physics errors are handed to the optimization worktree in
`/home/rod/Documents/luncosim-workspace/optimization/docs/reviews/griffin-physics-handoff-2026-10-22.md`.
That report includes a five-second isolated loaded-slider reproduction, the
zero-drift unloaded control, Griffin's leg rotation/rate discrepancy, and the
open landing/impact gates. Avian and its pin remain unchanged by this task.
Optimization owns the physics repair; Griffin authoring continues independently.

The common landing-leg physics component now owns body properties only. Six
obsolete geometric children and their 24 integrated instance opinions were
removed through the document API. Each integrated leg retains exactly
`LandingLegVisual` and `ShockPiston`. Their current integrated mass, centre of
mass, collider geometry, joint laws and transforms are preserved. The reusable
body's mass and centre of mass now match those existing integrated overrides;
its engineering values remain uncalibrated study parameters.

`GriffinLandingLegBodyChild` in SysML owns the integrated child inventory.
The GLL-008 contact-ownership predicate now requires an exact inventory match.
The focused landing-leg observer consumes the same four formal pad/mount
checks as the model audit and broad requirements observer, through one shared
`landing_pad_constraint_report` owner. It passes **189 checks** at source
revision `13713739519996139823`. A document-fork trial adding one unexpected
Xform below LegPX fails exactly `GLL-008-contact-ownership`, with the other
**188 checks passing**, zero errors and a terminal failed verdict. Both scratch
layers were removed after retaining their authoring receipts and hashes.
The broad Griffin requirements gate also passes all **40 checks** after using
the shared pad/mount report (terminal tick 10, same source revision).

The latest complete mission on the cleaned model **fails at the later surface
route** (tick 6881, approximately 1.6764 m remaining, throttle 0.03148). Ramp
deployment completes. The earlier 16-check passes below qualify their recorded
source cohort only. The shared skid guidance approach envelope is included in
the optimization handoff as an unisolated finding. The route failure's report
is truncated; it is not complete diagnostic acceptance.

Front, rear and underside Editor captures show the cleaned leg structure,
folded ramps, seven-engine cluster and retained authored PBR materials. These
are component inspection views, separate from physical mission illumination
and FPS acceptance. Receipts and captures are under the USD worktree at
`.cache/codex-evidence/griffin-contact-audit-20261022/`;
`landing-leg-inventory-qualification.json` records the two terminal leg verdicts,
exact negative failure and source hashes.

## Physics follow-up

The held engine-command gate passes after correcting its native mass-property
comparison to two binary32 machine epsilons relative to each observed value.
The independent binary64 four-tank equation oracle and one-tick propagation
fence remain unchanged. This result uses the earlier preserved executable and
is separate from the original 35-case cohort.

The normal USD production build now succeeds at engine HEAD `3844088aa` with
application changes extending the existing live dimensional drive control to
hinges. No dependency source, solver settings or substeps were changed. Its
banner is `3844088a-dirty`; executable SHA-256 is
`6d69f8af0be13fd0582f4dec3ad96ac5f9d52c0e71c42114f8858ecf0409f452`.
The four touched Rust files were formatted after validation; the as-built
application diff is retained in the evidence directory.

The ramp policy now records the six admitted native motor laws in the mission
instance and suppresses motor effort while the fixed flight latches hold.
Release events restore the selected pair's exact original torque caps. Gains,
targets, travel limits, physical constraints and settlement tolerances are
preserved. The integrated production mission passes all **16 checks** at
simulation tick 5822 (97.03 s). That run used source revision
`17995770647406241040`; a later documentation-only GRR-017 update explicitly
states the motor/latch policy. The flight-stow gate passes **272 checks** at
revision `6405204604486487419`, including missing/duplicate saved-law rejection.
A final replay of the complete mission at that revision also passes all
16 checks at the same simulation tick 5822.

The native force-drive scene passes **24 checks**, including hinge effort
suppression, exact restoration and invalid-law rejection. Its travel-stop
cancellation check now uses a dimensional native-precision envelope relative
to the opposing actuator load: 0.0000771 N residual against 80.0000 N, with
0.0001526 N tolerance (16 binary32 epsilons). Angle, rate, conservation,
analytic motor dynamics and all physical landing limits are unchanged.

Landing stability still fails: maximum ground speed 0.10715 m/s, angular speed
0.017928 rad/s and horizontal drift 2.16788 m over the unchanged 60 s horizon.
All sampled four-leg contact, finite-data and attitude predicates pass. The
engine-off replay still fails footpad clearance, native penetration, final
four-leg contact and hard-stop travel. Do not call the model fully passing.

Mission phase-failure reports now carry one bounded result chunk, a compact
settlement snapshot and the latest two motion samples. A deliberate replay of
the original middle-settlement failure retains its failed check with
`details_truncated=false`. This fixes diagnostics, independently of the later
physical sequencing repair.

Follow-up receipts are in the USD worktree at
`.cache/codex-evidence/griffin-physics-followup-20261022/`; `checkpoint.json`
retains structured reports, source hashes and executable identity. A headful experiment
verified the same deployment sequence at an actual 1280 × 720 viewport, but
later stalled on its surface route. It is diagnostic evidence, not FPS
acceptance. Front-face appearance and clean 60 FPS qualification remain open.

## Original full-registry configuration and evidence

Execution worktree: `/home/rod/Documents/luncosim-workspace/usd`, engine HEAD
`3844088aa`. Twin sources remain in this model repository. Existing unrelated
worktree changes and earlier Griffin edits were preserved. No engine source,
dependency, physics tolerance, graphics preset or substep count was changed.

The executable is the preserved production build
`/home/rod/.cache/roadster-presentation-bin/luncosim-343baf607-grid-final`,
with banner `343baf60-dirty` and SHA-256
`0f5daf8adde208a68312ef998a26c4db85f8986c6dcc8ed4a30abb73a22b84dd`.
This is not a new build of the current checkout. The run uses the USD
checkout's shared assets. Results qualify that executable/asset/Twin cohort.

Evidence lives in the USD worktree at
`.cache/codex-evidence/griffin-resume-20261022/`. The registry coordinator
checks unchanged Twin source hashes before and after every case. All 35
reports retain SysML source revision `17995770647406241040` at both start
and completion. `registry/cohort.json` contains the individual structured
reports; `acceptance-summary.json` records the four failures. The earlier
unchanged positive propulsion run is reused in the registry rather than run
again. All owned processes completed or exited; API ports 4391–4393 are free.

## Original full-registry results

| Goal area | Current evidence and status |
| --- | --- |
| Public configuration and references | Astrobotic's current product page still confirms seven main engines, four legs and four attitude-thruster clusters. NASA's 15 June hardware photograph was inspected. Metric dimensions, masses, performance parameters and display finishes retain their declared study/reconstruction status. |
| Source coverage | Typed provenance check passes: 219 requirement targets, 219 evidence records, 69 source elements and three source roles. This establishes catalog structure and coverage; it is not independent calibration of every engineering value. |
| Requirements | Current `ValidateSysml` has zero errors and 153 warnings, including 97 Griffin formal-acceptance warnings. Missing predicates remain migration work. A passing linked scene is not proof that every requirement has sufficient acceptance criteria. |
| Skirt wall geometry | Positive propulsion gate: 104 passing checks. Both collapsed and over-thick lower-lip cases fail exactly GES-002 with the other 103 checks passing. See [the skirt contract](griffin-engine-skirt.md). |
| Full registry | **31 of 35 pass.** Failures are listed below. The headless visual gate passes 134 topology/geometry checks; that is not pixel-level or aesthetic acceptance. |
| Materials and appearance | The skirt's Editor top and underside were inspected with saved component geometry. Front oblique mission-review captures are too dark to judge the solar face properly under the current review lighting. This remains a visual-review gap. Gold remains the declared presentation preference, while the hardware reference is predominantly pale/silver. |
| Performance | User-selected target: 60 FPS at 1280 × 720, High quality, real-time physics. No clean qualifying mission window exists. See [the performance contract](griffin-performance.md). |
| Excess removal | The legacy disposable zero-lip layer was retired after its replacement driver and rejection receipts were established. Its exact source/hash is retained in `legacy-fixture-retirement.json`. New trials remove their own unique scratch layers; no hand-authored fault asset is shipped. |

Primary references rechecked for this checkpoint:
[Astrobotic Griffin product](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/)
and [NASA hardware photograph](https://www.nasa.gov/image-detail/26-06-15-griffin-1-pressconference-1348-edit/).
The image does not provide calibrated dimensions or qualified material data.

## Original four failing cases

1. **Full surface operations:** times out in `ramp-middle-unfold-settle`.
   At failure, the middle hinges are within about 0.002 rad of their final
   targets, but measured speeds are approximately 2.78 and 2.88 rad/s against
   the unchanged 0.02 rad/s settling limit. Their still-latched toe partners
   also report excessive relative speed. Do not substitute target-angle
   agreement for measured settlement or increase the timeout to hide this.
2. **Landing stability:** four-contact/finite-data and attitude predicates
   remain true, but maximum ground speed is 0.10498 m/s against 0.05 m/s,
   angular speed 0.016812 rad/s against 0.01 rad/s, and horizontal drift
   2.45394 m against 0.35 m. The physical mechanism/landing response requires
   repair; tolerances were not changed.
3. **Held engine commands:** the native mass-property propagation comparison
   fails. The observer assumes two binary64 machine epsilons. Recorded native
   mass and COM match binary32 rounding of the model values; native inertia
   additionally passes through the inverse-tensor reader. The independent
   four-tank equation oracle remains enabled. Determine the backend's declared
   precision contract and owner-specific forward error before changing this
   observer; do not mask a lost/delayed propagation update with a broad bound.
4. **Engine-off impact:** fails footpad rim/centre clearance, native penetration,
   final four-leg contact and the authored suspension hard-stop travel check.
   This is a physical failure, separate from display-skirt thickness.

The mission phase-failure snapshot also exceeds the scene-test per-event
evidence limit. The process still emits its failing verdict and the raw log
retains its snapshot, but the structured report omits those large details.
Split that diagnostic into bounded typed records before further mechanism
debugging. Do not increase the transport budget or count an omitted snapshot
as successful verification.

Current follow-up status is stated above. The remaining repairs include landing
stability and impact response, followed by front/back/underside assembly review
and clean performance acceptance. The
35-case baseline and the older passing checkpoints remain revision-specific
evidence; neither is relabeled as a run of a later repair.
