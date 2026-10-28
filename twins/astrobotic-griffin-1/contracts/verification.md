**28 October architecture correction:** compact, steep FLIP egress tracks now
replace the long folding banks in the vehicle. The legacy component and
unfolding receipts below retain their historical scope. The new mounted geometry
and release hold do not qualify tether payout or restrained descent; automatic
egress remains inhibited pending that physical model.

The [source paging repair receipt](../handover/griffin-source-pagination-2026-10-23.json)
records complete reads of all 458 requirements and 53 verification cases with
unchanged Rhai limits. The full composite audit now produces a structured FAIL
for ramp-observer findings; its SysML source phase passes. The fresh lander
component run passes 122 checks.

The [complete hardware and payload-release review](griffin-complete-review-2026-10-23.md)
records twelve passing selected cases, an explicit production egress observation,
and the remaining native topology, impact and composite-audit findings. Its receipt
keeps source revisions and failed cases visible.

# Griffin verification boundary

The [landed ramp contact gate](griffin-ramp-contact-2026-10-23.md) adds actual
cooked toe/terrain and deck-entry tire-corridor checks to the existing hinge
settlement dwell. Its three production replays cover normal deployment and two
authored contact faults; the receipt records 78 focused checks. Full loaded
traversal and clean 60 FPS real-time acceptance remain open.

The earlier [size, independent-track, RCS and waypoint review](griffin-fidelity-review-2026-10-23.md) passes 199 production checks: 54 integration, 40 stow, 16 toe geometry, 43 descent/deployment/waypoint, 31 RCS and 15 panel-contact checks. Four three-span wheel tracks fit terrain independently. Windowed manual opening also reaches all twelve hinge goals. This supersedes the installed equal-span and paired-track coupling checkpoints below; their results retain their original revision scope. Complete loaded rover traversal, flight dimensions and clean 60 FPS real-time acceptance remain open.

The [solar collision repair](griffin-solar-collision-2026-10-23.md) adds
59 frame/backplane stock colliders without filling the panel openings.
Its native contact case passes 15 checks and the existing geometry case passes
170 checks; the disabled-surface negative fails the two expected checks.
Full landed rover interaction and ramp deployment remain separate gates.

The [22 October packaging checkpoint](griffin-integrated-packaging-review.md)
records the installed vehicle geometry and focused verification. Earlier results
below belong to their recorded revisions. Loaded-support physics, complete
mission acceptance and the 60 FPS real-time target remain open.

The [folded-ramp inspection](griffin-ramp-interference-2026-10-22.md) confirms
source interference between all four middle tracks and their corresponding
fixed transitions. Passing angle, panel or leg checks cannot accept this
mechanism. Its provisional unequal-length, opposite-toe-sweep study has only
sampled port-side box coverage; detailed geometry, complete deployment
clearance and native loaded egress remain unqualified.

The [detached root-section checkpoint](griffin-ramp-root-section-2026-10-23.md)
qualifies its 2.149084054 m component geometry independently. Its 119-check
gate includes native metric bounds; a 0.8 X-scale negative fixture fails that
constraint. The [middle/fitting continuation](griffin-ramp-middle-section-2026-10-23.md)
passes 119 checks for each saved root/middle component, including connected
fitting envelopes and explicit structural PBR bindings; both shortened
fixtures each fail exactly one constraint. The installed ramp source gate passes 1,257 checks after its
observer recovers dimensions in the native cooking frame; flight stow passes
272. These source checks do not close the installed interference above.

The [toe and revised interface checkpoint](griffin-ramp-toe-section-2026-10-23.md)
supersedes the earlier 120 mm lower fold candidate with an 80 mm offset.
Root/middle/toe component gates pass 119/119/131 checks. The saved
[two-bank packaging study](griffin-ramp-packaging-study-2026-10-23.md) has a
50.319 mm conservative payload-path gap after between-sample motion allowance,
plus native comparison of all 558 installed reference members. GVA-001 remains
unmapped and unaccepted as a full integration case. The production vehicle's
old mechanism, other obstacle clearances, loaded deployment and 60 FPS remain
open; a static study cannot replace those checks.

The later [raised root interface](griffin-raised-root-interface-2026-10-23.md)
supersedes that candidate's fixed-bridge obstruction. The revised root passes
127 production checks and its shortened-instance negative fails as required.
Both banks pass 22,176 payload/bridge observations with between-sample motion
allowance; minimum payload separation is 50.1168 mm, all four nominal seams
measure 2 mm, and all 558 source-member comparisons pass. Root, fixture,
FLIP and study preflights have zero errors/warnings. SysML validation retains
153 existing warnings. The installed vehicle, complete obstacle clearance,
loaded deployment/traversal and 60 FPS remain unaccepted.

The [root bearing checkpoint](griffin-root-bearing-2026-10-23.md) installs
four inboard housings and connected stems in the review fixture. Housing/root
production gates pass 6/128 checks, and both shortened-instance negatives fail
exactly one constraint. A conditional native geometry certificate passes 776
root/housing/stem comparisons over any root angle; a 1 mm misalignment is
rejected. This does not qualify middle/toe or loaded integration. The separate
assembled runtime attempt panics at the native island owner and is reported
locally to optimization. Asset preflight passes; runtime acceptance remains open.

The [fixed-structure sweep](griffin-ramp-fixed-structures-2026-10-23.md) covers
11,088 section/pose observations against 480 measured targets, including
between-sample motion and the separate root mating prerequisites. A deliberate
track obstruction is rejected. The two unmeasured antenna members and all
moving-to-moving interfaces remain open; this does not accept GVA-001 or loaded
deployment.

The detached [FLIP airless wheel](flip-airless-wheel-2026-10-23.md) passes 62
production checks for its source envelope, closed mesh architecture, four
material networks and render budget. The oversized fixture and wrong-material
negative each fail one check. This does not qualify installed roll, contact
deformation or whole-scene FPS; the production rover still uses its prior visual.

## Sun-facing autonomous descent

The operator-requested GSA-011 study yaws the forward solar bank's +Z outward
normal toward the mounted probe's measured Sun azimuth. The IMU quaternion
keeps this heading reference separate from the thrust-vector tilt needed for
landing. The 60 m final approach begins Sun-aligned with all attached rigid
bodies at rest; guidance commands descent immediately. FLIP shares the initial
yaw so its fixed adapter starts without a rotational constraint error.
`heading_ready` qualifies azimuth error within 5 degrees and yaw rate within
0.02 rad/s for the observer; heading qualification does not pause descent.
First accepted pilot flight input releases the
heading reference through the existing GNC authority gate. Native contact
handoff retires automatic attitude requests.

`GriffinSolarRequirements::GriffinDescentSunPointingStudy` owns the study
limits: initial heading qualification within 2 s, tracking for at least 3 s,
and an observer timeout of 180 s. These are simulation acceptance settings, not flight GNC
tolerances. Transit Sun pointing, thermal exceptions and full mission-window
coverage remain unbaselined work in `implementation_gaps.md`. The former open
GSA-010 placeholder is removed from the geometry verification objective; it had
no acceptance envelope or transit observer. Array electrical performance is
accepted separately by the bounded power/thermal study.

Run the mapped `GriffinSolarRequirements::Verify_GriffinDescentSunPointing`
case on `tests/griffin_sun_pointing.usda`. Its typed SysML constraint consumes
sampled acquisition time, tracking error, automatic authority and qualified
landing handoff, with source-pinned limits and simulation intervals. Run
`GriffinFunctionalRequirements::Verify_GriffinGncHandoff` for selection,
first-input release and reconnect, and
`GriffinSimulationAccuracyRequirements::Verify_GriffinLandingStability` for
the post-touchdown stability interval. The shared simulator
`scripts/api/test_attitude_heading.py --output <evidence-dir>` covers analytic
heading signs, antipodal recovery, tilt, rate readiness and manual authority.

The 2026-10-20 merged production qualification passes all five mapped cases:
Sun pointing, GNC handoff, landing stability, engine-out and full surface
operations (each exits zero with a structured PASS). Both native-window and headless descent observers acquire
heading in 0.05 s and measure a maximum azimuth error of 0.00592636 rad
(0.340 degrees) over 23.5 s of tracking. The landing-stability run observes
all four pads in contact in all 361 observations over 60.0167 s. The GNC
selection/manual/reconnect case passes 22 checks. These observations apply to
the authored site, epoch and initial approach, not the full flight envelope.

## Temperature-sensitive photovoltaics and bounded cooling — 2026-10-20

Solar cell temperature now affects both available conversion power and the
reference-temperature rating. FLIP exposes `inputs:solar_cell_temperature_k`,
`outputs:solar_temperature_k`, `outputs:solar_temperature_factor` and
`outputs:solar_heat_w`. Its current prescribed setting is 298.15 K, not an
estimated lunar operating temperature. The input can instead receive a panel
thermal network's temperature; absorbed radiation minus actual bus delivery
supplies that network's heat load.

The reference temperature is 298.15 K. The configurable -0.0037/K coefficient
is the [PVWatts standard crystalline-silicon study default](https://samrepo.nlr.gov/help/pvwatts_system_design.html),
not FLIP supplier data. Absorptivity 1 is an ideal opaque absorber. Cell
technology, optical properties and a validated operating-temperature range
remain uncalibrated. The 270 W rating applies at the reference temperature;
the hot/cold synthetic bright probes produce 220.05/319.95 W available at
348.15/248.15 K. Actual bus delivery is 128.636878/187.175171 W.

The reusable `LunCo.Thermal.LimitedCoolingSink` and
`lunco://components/thermal/limited_cooling_sink.usda` expose maximum heat
rejection in W (= J/s), minimum reservoir temperature in K and conductance in
W/K. Heat removal saturates at capacity and stops below the reservoir
temperature. It is an ideal external cooling boundary; pump power, finite
coolant storage and flight hardware are separate models. It is available for
thermal composition; the current FLIP panel still uses prescribed temperature.

The production electrothermal driver passes 45 authored checks. Its synthetic
300-second coupled panel starts at 348.15 K with heat capacity 1000 J/K,
sink 298.15 K and conductance 20 W/K. A 600 W cooling capacity lowers the panel
to about 322.658 K and raises available power from 199.675 to 222.783 W.
A 100 W capacity lets it heat to about 486.164 K, reducing output to 74.565 W.
Cooling limits, energy balance, below-sink behavior, invalid inputs and an
intentionally disconnected heat path are checked. These are model witnesses,
not FLIP thermal design values.

FSP-008 now executes the temperature-aware power predicate. The mapped native
gate passes 38 measured checks and 26 criterion diagnostics at source
`4119946244799939613`. Formal observation details use the existing streamed
evidence path; the scene report has no truncated details or oversized-event
rejection. The inspected native SysML panel shows PASS evidence and a passed
mapped test. Source validation reports zero errors and 164 missing-formal-criterion
warnings; provenance covers 214 requirements, 214 records and 63 sources.

The fresh High / standard-PBR rendered mission also passes all 16 gates, with
zero runtime errors and broken connections. The execution image is SHA-256
`55f9ffc9692ec59a5a5a83775a8c56fdf7eef85c7695c4e87303a77b84916058`.
Other host workloads were active and the run retained queued simulation time;
it does not qualify throughput. Warm dependent-layer editing produced a
projection error in a separate authoring session; that session is excluded from
saved-source runtime qualification. Native logs, source edits, trajectories,
images and hashes are retained in simulator
`.cache/codex-evidence/griffin-review/solar-temperature-20261020/`.

## Bounded performance qualification — 2026-10-20

Tutorials binary `382460f1…` shares immutable unit metadata while retaining live
port validation. It passes the 19-check GNC gate, the rendered 16-gate mission,
5/11 production unit/transaction checks and 35 engineering-value/registry tests.
At source `7188239926208515743`, selection preserves GNC, first flight input
selects manual, neutral retains manual and explicit reconnect restores guidance.

Same-source completed-mission 25-second windows at High / standard PBR, 1280 ×
720, give 97.5206 FPS on retained `5a9aa0c5…` and 110.6446 FPS on `382460f1…`.
Camera, terrain readiness, process audits and inspected images are retained.
Fixed-tick p50/p95/p99 are 4.7922/5.4548/6.1519 and 4.7519/5.3197/5.6056 ms.
These short observations do not establish repeatable causal speedup or sustained
full-mission real-time acceptance. Instrumented windows have different backlogs.
A separate process subsequently rebuilt the shared target; these results qualify
the retained artifact. Evidence: simulator `.cache/codex-evidence/griffin-perf-20261020/`.

## Battery energy budget repair — 2026-10-20

The earlier half-energy audit is now reproduced and repaired in the shared
Modelica battery. The [battery analysis](../requirements/flip-battery-energy-analysis.md)
records the primary source, synthetic conditions, model derivation and hardware
limits. The former linear voltage/SOC law delivered only 3.079 kWh over a
nine-hour ideal C/10 discharge from full to 10% charge, against a nominal
5.598 kWh budget. ESR was measured separately and did not explain the shortfall.

The repaired mission-level model uses a flat voltage plateau with a normalized
empty-reserve taper. Its complete internal energy is exactly the authored
`capacity * voltage_nom` Wh. Current, stored energy and heat close the terminal
power balance through empty, recharge and full-charge saturation. Surplus at
full charge is an explicit ideal shunt; this is not a calibrated FLIP BMS or
OCV curve. The current FLIP thermal assembly does not receive the new battery
heat output, so battery-temperature qualification remains open.

The production API gate passes 38 authored Rhai checks: complete finite native
trajectories, full nameplate energy, charge/energy conservation, series losses,
empty/full boundaries, recharge, connected motor regeneration and seven owner
parameter diagnostics. The full ideal run starts with 22,391,999.560546875 J
and supplies 22,391,999.5210135 J. The ESR run supplies 22,214,348.731923215 J
net to the bus and dissipates 177,650.80538277034 J. Maximum energy residuals
are 0.039534 J and 0.023241 J. The normal USD empty-battery actuator gate passes
all four checks.

The rendered High / standard-PBR 1280 × 720 mission then completes all 16
gates, with zero runtime errors and zero broken connections. Native U and F
controls deploy the physical ramps and release FLIP; inspected captures show
the completed route. The solar gate still passes 36 measured checks and 20
criterion diagnostics. Bright/dim delivered bus power is now 157.895196 W /
14.301421 W; both occluded and back-facing cases remain zero. The earlier
solar section's 134.191964 W / 12.150578 W observations belong to the old
battery law. Source revision remains `7188239926208515743`; no SysML or USD
parameter was changed to obtain this result.
A fresh mapped run in the native SysML panel displays FSP-008 VERIFIED with
this storage model. The headless two-restart gate also passes all 94 comparisons
over two 90-second trajectories. Both GR-036 screens pass with 361 four-pad
samples, no contact drops, maximum displacement 0.172714955811522 m, maximum
speed 0.014500082284774805 m/s, maximum angular speed 0.009099031784827825 rad/s
and minimum upright Y 0.995975109925394. These maxima agree between the two
restarts; they do not assert equality with earlier host/source baselines.

Across the powered-descent-to-mission-complete interval, the run advances
88.4 simulated seconds in 94.363494 wall seconds (0.936803×). Native frame
counters record 4,352 frames over 92.728845 seconds (46.9325 frames/s).
A bounded headless solar gate ran concurrently, and host workloads were not
controlled. This observation does not pass sustained real-time acceptance or
establish a controlled speedup over an earlier run.

The production executable remains `5a9aa0c5…`; the interpreted battery model
is SHA-256 `7c2231b98aa6ef78615c990644f58c579f987928c646a8bd6de2d69662343b36`.
Native results, source-bound benches, source snapshots, mission captures and
checksums are retained under the simulator's
`.cache/codex-evidence/griffin-review/battery-energy-20261020/`.

## Solar criterion before the battery repair — 2026-10-20

FSP-008 now owns executable configuration and available-power predicates in
SysML. The numerical allowances remain the existing 0.002 m², 0.002 efficiency
and 0.01 W settings; they are model-verification allowances, not supplier
precision. Astrolab's primary power post was rechecked on 2026-10-20 and says
nearly 270 W. The Twin retains 270 W as its rounded model ceiling. Collection
area and efficiency remain study values, and 28 V is explicitly a study bus
setting; the post does not publish a pack voltage, I-V curve or converter model.

The headful native gate at source revision `7188239926208515743` passes all
36 measured checks across the eight sensor/power requirements. Synthetic
illumination drives the real FLIP electrical root through `SetPorts`; each
read uses the native port batch's tick and owner identity. Observed values are:

| Probe | Irradiance | Visibility | Available power | Delivered bus power |
| --- | ---: | ---: | ---: | ---: |
| Front-facing bright | 2000 W/m² | 1 | 270 W | 134.191964 W |
| Front-facing dim | 100 W/m² | 1 | 24.499999 W | 12.150578 W |
| Occluded | 2000 W/m² | 0 | 0 W | 0 W |
| Back-facing | 2000 W/m² | 1 | 0 W | 0 W |

These are synthetic integration observations, not flight measurements or a
claim that the bus receives 270 W. All five input holds are released; readback
returns to environmental irradiance 1361 W/m² and its actual Sun vector.
The observer retains one bounded component-specific source snapshot while
waiting between probes. It no longer repeats a Twin-wide source projection.

Twenty separate criterion diagnostics accept five nominal fixtures, reject
thirteen wrong configuration/power results, including delivery above available
power, classify a missing observation as inconclusive and classify an unknown parameter as error. They use explicitly
synthetic derived observations. Their event has no terminal verdict field;
the mapped hardware gate can report PASS only after its complete check set.
The default-channel production CLI also exits 0 on
`FLIP_SENSOR_POWER_REQUIREMENTS` after 129 ticks / 2.15 simulated seconds.
The native SysML panel's mapped test passes and FSP-008 displays VERIFIED at
the same source revision. Mounted validation reports zero errors and 164
missing-formal-criterion warnings, down from 165. The source-evidence checker
still covers 214 targets, 62 sources and three source roles.
The GNC handoff production gate also passes all 19 checks at this revision
(257 ticks / 4.28 simulated seconds): selection retains automatic control,
first flight input enters manual, neutral release retains manual and explicit
reconnection restores GNC.

This checkpoint used the former half-energy battery law. Its repair and
independent energy-integral qualification are recorded above. FSP-007 remains
a nameplate criterion and does not qualify flight-pack usable energy or BMS behavior.

The engine artifact remains `5a9aa0c5…`; no Rust or vehicle USD changes were
needed for this work. Retained native logs, input cleanup, validation, inspected
SysML captures and the source-derived energy audit are in the simulator's
`.cache/codex-evidence/griffin-review/solar-contract-20261020/`.

## Native settling qualification — 2026-10-20

Production artifact
`5a9aa0c56d8e429a468fc2920510ec736357bb212d799c3e4c10fdd9ad9afc63`
corrects the rotating-frame differential for prismatic alignment and travel
limits after free slider travel. A central finite-difference regression checks
both rows. Gravity retains its exact persistent native acceleration, while its
sample distinguishes consumer motion from a changed source. Consumer-motion
updates, including the final movement sample at sleep admission, do not publish
an external-force change. Actual source changes retain native wake notification;
external pose edits retain native pose wake detection. The site mount also
preserves an unchanged gravitational-parent link instead of rewriting it.
Native sleep thresholds, required rest time and physics cadence are unchanged.

The selected lander completes automatic descent and then a 90-second native
rest observation. All 14 dynamic vehicle bodies are sleeping at every recorded
observation from 30 through 90 seconds. The root's position and rotation are
exactly unchanged across that 60-second interval. Native U input wakes all 14
bodies; both ramps reach their physical targets and native F releases FLIP.
The complete rendered surface mission passes all 16 gates with clear readiness,
zero runtime errors and no broken connections.

The strict two-restart gate passes all 94 comparisons over two 90-second runs.
Both GR-036 screens pass with 361 four-pad samples over 60 seconds, maximum
horizontal displacement 0.1652981011996565 m, maximum ground speed
0.006837443526173641 m/s, maximum angular speed 0.0047787336240988215 rad/s
and minimum upright Y 0.9959669685720404. These metrics agree between restarts;
they do not assert equality with the earlier artifact's corrected physics.
The GNC gate passes all 19 checks, including selected automatic thrust, first
flight-input manual takeover, neutral release staying manual and airborne
reconnection. A separate native-window W press/release confirms the airborne
handoff; the Twin-owned HUD hook restores automatic ownership after touchdown.
The landed model's flight-command gate remains inhibited by its normal landing
handoff. The inspected SysML Structure view shows integer engine/leg/array/tank
counts 7/4/3/4 and their declared source expressions at source revision
`12035127991521517736`. Mounted validation has zero errors and 165 warnings.

The completed-mission High / standard-PBR 1280 × 720 window renders 789 frames
over 23.984456 seconds (32.8963 frames/s), delivering 1.12912 simulated seconds
per wall second. Median fixed service is 6.414574 ms; pending time decreases
from 71.9651 to 69.0431 seconds. Camera pose and settled terrain are unchanged;
the NVIDIA inventory lists the owned simulator. This is a qualified completed
window, not full-mission throughput acceptance or a controlled speedup ratio.
The focused checks pass 28 joint, 31 CCD, 16 environment and five site-placement
tests, plus native rollback gravity. The source checker passes 214 targets.

Native sleeping now admits the normal resting vehicle. Awake contact precision
remains a separate limitation: the archived generic sprung-platform diagnostic
with sleeping disabled moves about 10 mm over its ten-second measurement on
both box and mesh ground. Its proposed 1 mm criterion fails; it is not a green
acceptance gate or a Griffin hardware calibration. Full-mission performance,
FPS headroom and the 165 missing formal criteria remain open.

Retained evidence is in the simulator's
`.cache/codex-evidence/griffin-review/static-traction-20261020/`, including raw
tests, the diagnostic fixture, production/rest/replay/landing/GNC verdicts,
timing, inspected native UI captures and a SHA-256 manifest. The REPL UI probe
outside Twin context is marked invalid separately; it is not acceptance evidence.
Both qualified graphical sessions exit and release API port 4291.

## Earlier response-reuse qualification — 2026-10-20

Production artifact
`d2cceb6982e8ebb8d7de956884ce2f0433e318f383c74eb335c7ef62a56466b5`
reuses a full orientation row's native symmetric response decomposition while
its complete matrix is exactly unchanged. Preparation clears it, and changed
inertia rebuilds it. Eigenbasis projection, rank handling, tolerances, cadence
and joint order remain the same. The focused joint suite passes 27 checks and
the same built test executable passes all 31 CCD checks. The rendered production
mission passes all 16 gates; the inspected captures retain the vehicle, ramps,
foil surfaces and cast shadows.

The strict rendered two-restart comparison passes all 94 samples, including
exact thrust/guidance/touchdown states and the existing pose/velocity limits.
Both restarts also pass GR-036 with 361 four-pad observations over 60.0333 s.
Nine engineering landing metrics match the preceding qualified `eba164e9…`
artifact exactly in both runs, including maximum displacement
0.3053978887558844 m, maximum ground speed 0.005885101999605289 m/s and maximum
angular speed 0.0042097964122900355 rad/s. That comparison is a bounded set of
metrics, not full cross-artifact trajectory equality. The unchanged creep
remains an open physical-quality issue. Source revision is
`12035127991521517736` throughout these runs.

The completed-mission High / standard-PBR 1280 × 720 window renders 760 frames
over 24.9823 s (30.42 frames/s), delivering 1.0231 simulated seconds per wall
second. Median fixed service is 10.5092 ms; pending time decreases from
21.0657 to 20.7215 s. Terrain is settled, camera pose is unchanged, readiness
is clear, connections are intact and runtime diagnostics are empty. The NVIDIA
process inventory lists only the owned simulator. GPU utilization is 18–22% at
825–930 MHz in the recorded samples, alongside CPU/background workload; the AMD display GPU reports
zero utilization in those samples. This qualifies that completed-mission
window, not sustained real-time operation across the full mission or a
controlled before/after speedup ratio.

The shared `QueryPhysicsState` now exposes native sleep timers, required rest
time, effective velocity thresholds, the disabled marker and persistent linear
acceleration. A separate read-only production review (`15ab09a0…`) finds all
14 dynamic bodies below the default thresholds with sleeping enabled, but still
awake. At the recorded snapshot, even the shortest rest timer exceeds 0.5 s;
several exceed 30 s. Position-dependent gravity continues changing their native
acceleration. Source inspection identifies that change as one native wake-up
path; contact/joint motion remains to be diagnosed. An attempted temporary
uniform-field comparison did not create a prim or change document generation,
so it provides no causal evidence. The source document stays clean and no
gravity setting was saved.

Current evidence is under `/tmp/griffin-joint-response-20261020/`, including
`mission-evidence.json`, `timing.json`, GPU samples/inventory, `strict-replay.json`,
`landing-screen-verdicts.json`, `landing-physics-comparison.json` and inspected
captures. Native sleep evidence is under
`/tmp/griffin-rest-native-query-20261020/`. Both owned sessions exit and release
their API port. A retained local copy, build/test logs and a SHA-256 manifest
are in the simulator's
`.cache/codex-evidence/griffin-review/joint-response-20261020/`.
The remaining acceptance work includes resting creep, broader
throughput/FPS headroom and the 165 missing-formal-criterion warnings below.

## Current acceptance follow-up — 2026-10-20

The production artifact `eba164e94af539c46fde6ca4e25e76ce9a2f409faaea725fc2721156eb70c759`
passes the rendered 16-gate mission again with the current source-owned battery
criterion (`12035127991521517736`). Native-window U/F events deploy the ramps
and release FLIP; the completed route, lander, ramps and cast shadows are visible
in the inspected `lowload-mission-route-finished.png`. Readiness is clear,
runtime errors are zero and connections are intact. Evidence is under
`/tmp/griffin-lowload-20261020/`.

GR-036 now screens the 60-second settling/deployment interval against the
existing ten-degree study attitude envelope, 0.05 m/s horizontal speed,
0.01 rad/s angular speed and one 0.35 m pad radius of horizontal displacement.
These are project screening choices, not supplier landing ratings or a
no-slip equilibrium qualification. The mapped production case passes at source
`7499854067851211207`: all 361 samples have four-pad contact over 60.0333 s,
minimum upright Y is 0.9959324, maximum ground speed is 0.0151342 m/s,
maximum angular speed is 0.00662793 rad/s and maximum displacement is
0.3344101 m. The observed displacement remains an open physical-quality issue.
No strict replay tolerance changed. Three unused `landingDivergenceTolerance*`
attributes and their getter/contract/metric copies were removed; they had no
predicate consumer. The unloaded 0.44 m vehicle-reference datum explanation now
matches pad geometry instead of the obsolete spring/travel numbers.
Evidence: `/tmp/griffin-audit-20261020/stability-contract-tightened/`.

FSP-007 now owns the executable battery nameplate criterion: convert the
source's 6.22 kWh at 28 V to ampere-hours, with the existing 0.02 Ah and
0.002 V configuration allowances. The mapped sensor/power gate passes all
34 checks at source `12035127991521517736`; both battery observations retain
one composed USD snapshot's provenance. A separate read-only native constraint
evaluation accepts nominal synthetic values and rejects capacity +0.10 Ah and
voltage +0.010 V. These diagnostic derived observations do not claim actual USD
measurements or discharge-curve qualification. Native `ValidateSysml` reports
zero errors and 165 missing-formal-criterion warnings (previously 166).
Evidence: `/tmp/griffin-audit-20261020/battery-formal-contract/`,
`/tmp/griffin-formal-window-20261020/validation.json` and
`/tmp/griffin-lowload-20261020/battery-counterexamples.json`.

After the mission, the same High / standard-PBR 1280 × 720 camera renders
659 frames over 23.9869 s (27.47 frames/s) and delivers 0.9045 simulation
seconds per wall second. Terrain is settled and diagnostics remain clear.
Only the owned simulator appears in the recorded process inventory, with
browser/compositor and system memory activity still present. Fixed service
median is approximately 14.6–15.4 ms; pending simulation time grows from
22.20 to 24.82 s. This cohort does not meet real-time throughput and is not a
controlled comparison with earlier competing-simulator runs. Neither physics
fidelity nor convergence limits were reduced. See `timing.json` in the current
evidence directory. Remaining acceptance work includes sustained throughput,
static resting creep and the other 165 formal-criterion warnings.

A separate fresh descent received no operator flight, ramp or release inputs.
Seven native/API observations span 3,619 ticks (60.3167 simulated seconds)
after touchdown and show 0.3046622 m horizontal displacement. Across those
samples the largest main-cluster thrust is 1.1322e-163 N, RCS thrust is exactly
zero, and final root velocity is approximately (0.00102, -0.00035, -0.00457) m/s.
The tiny main value is retained as observed rather than reported as exact zero.
Root throttle and torque requests are zero; readiness, diagnostics and
connections remain clear. This points the resting-motion investigation toward
contact/joint response, but seven observations do not certify every intervening
force sample. Evidence: `idle-zero-thrust/samples.json` and `summary.json` under
the current evidence directory. Read-only native SysML value queries confirm
the resolved 0.984807753012208 upright bound, 0.35 m displacement bound,
6.22 kWh nameplate energy and 28 V nominal voltage on source
`12035127991521517736` (`current-sysml-values.json`).

The focused GNC handoff case also passes all 19 checks on this production
artifact and source `12035127991521517736`, including selection with guidance,
first-input takeover, neutral manual retention and explicit reconnect.
Evidence: `/tmp/griffin-audit-20261020/gnc-current-artifact/`.
Both owned API sessions (4291 and 4292) exit and release their ports.

## SysML values and component review — 2026-10-19

The `tutorials` simulator displays declared parameter types, resolved constants
and source expressions in the SysML Structure detail pane. The view retains
integer precision, collection shape and declared units; unresolved and
unassigned values remain explicit. Document-owner saves refreshed the mounted
analysis after source corrections; the value-review capture revision is
`15940673689723329396`.

The assembly declares three arrays, matching the canonical configuration. The
detached suspension path matches its composed `/World/FlipSuspension` fixture.
Sensor-head full envelopes are 0.40 × 0.16 × 0.24 m for the existing size=1 Cube
study geometry. The sensor/solar checks measure full metric extents without
doubling them, and battery checks read the canonical battery root. Standalone
FLIP fixtures compose the shared lunar environment required by their solar and
thermal participants. Suspension verification reads its precomposed fixture
without rebuilding it. Propulsion verification checks the current integer
engine-count parameter and conservative per-engine/nozzle dataflow.

All 13 component gates have passing relevant-source results, totalling 2,970
checks; typed provenance covers 214 requirement targets. The parameter-view
regression and production build pass; the live view was captured and inspected.
Native `ValidateSysml` resolves this source set with zero errors and 166
warnings for missing formal acceptance predicates. All 27 empty source links
are populated, and the four engine-skirt identities use typed enumerations.
The provenance gate checks 214 targets and evidence records against 62 typed
sources; it rejects empty source collections and blank locators. Project
contracts are labelled as study/project authority rather than flight data.
Formal acceptance remains incomplete.
Numeric evidence is retained in `/tmp/griffin-review-20261019/` and
`/tmp/griffin-realism-20261019/`. The original value-view screenshots were
removed with the simulator's build directory. These component results do not alone qualify
all 30 mapped cases; later mapped runtime results are recorded below.
The solar initialization guard waits for physical observer/source poses; the
native regression and positive day/night plus invalid-sampling production
fixtures pass. The static visual-review initialization and rendered gate are
covered by the 2026-10-20 review below. The full rendered mission is covered by the later registry audit. Shared plume
graphics is also qualified below. Strict replay and clean standard-PBR
performance acceptance remain open. No bounds were relaxed
to produce these results.

## Static review and foil appearance — 2026-10-20

The fixed-pose scene disables its leg joints. It now explicitly supplies the
source-owned unloaded rest coordinates (0 m) and stationary rates (0 m/s)
instead of waiting for nonexistent joint telemetry. Live flight wiring is
unchanged. The mounted production graphics scene reaches readiness with zero
pending inputs and broken connections, and its authored visual gate passes
134/134 checks at SysML revision `17565176433882467050`.

The shared foil shader now uses analytic, footprint-filtered fold normals and
the existing PBR helper. Close before/after views show silver blanket relief
and gold tank highlights without adding geometry or draw calls. The appearance
controls remain explicit artistic estimates. Astrobotic's
[2026-06-15 hardware photograph](https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/)
is a qualitative reference, not calibrated reflectance or blanket metrology.

An uninstrumented High / standard-PBR 1280 × 720 window rendered 2,121 frames
over 23.997 s (88.39 frames/s). Camera pose was unchanged, simulation remained
ready, runtime diagnostics had zero errors/warnings, and no new fixed-tick
budget exceedance occurred during the window. This is a contention-affected
static-review baseline: other-worktree Rust builds, the browser and compositor
were active. It does not qualify mission-scene performance or a clean-machine
frame-rate target. Evidence, complete timing snapshots and inspected captures
are in `/tmp/griffin-visual-20261020/final/`; the source-edit readback is in
the parent directory.

## Ownership and acceptance scope

The SysML requirement packages own normative identities, requirement text,
study limits, and formal `require` constraint memberships. Verification cases
own `verify` relationships inside their `objective` blocks. USD supplies the
realized assembly; Modelica supplies continuous equations; Rhai selects those
providers, samples observations, orchestrates runs, and formats evidence. The
shared Rust/Rhai evaluator executes the supported scalar constraint subset.

## Current executable slice

- Payload capacity, ramp deployment range, bus and tank geometric checks, and
  FLIP suspension rest length now use reusable SysML constraints linked to
  their owning requirements.
- The generic evaluator resolves requirement identity and accepts only a
  matching `require` membership. `assume` is preserved in source projection
  but cannot satisfy an acceptance check. Results preserve `pass`, `fail`,
  `inconclusive`, and `error` with source revision and constraint fingerprint.
- The authored requirement-check catalog and Planned/mission/process
  groupings are implementation metadata, not a runtime invocation trace.
  Current evidence consists of the structural and layout reports, per-part
  observations, provenance record, and explicit payload/ramp constraint
  boundary evaluations. Those checks do not cover all requirements listed by
  `Verify_GriffinRequirements`.
- Rhai still measures composed USD mesh topology, extents, face winding,
  material properties, child presence, and live physics/mission telemetry.
  These measurements are provider observations; their geometry extraction,
  frame conversion, temporal sampling, and collection reductions are not yet a
  generic Rust provider surface.
- The ramp geometry is owned by the replaceable Twin component and its SysML
  child inventory. FLIP remains a separately sourced and loaded component.

## Geometry migration status

The physical top deck uses eight hidden convex beam colliders following the
SysML octagonal profile, and the central rover platform has a separate
geometry-derived collider. Composed Editor readback passed profile, topology,
and source-deviation checks. The render ramp uses two FLIP-aligned
wheel tracks with an open centre, using the same wheel stations and track-width
datum as the physical contact geometry.

GRR-012 uses the shared `QueryUsdPrims` Avian-cooked collider-geometry
observation to measure, from one composed snapshot per side, minimum adapter
overlap at every lateral cross-section, transition length, deck top-face step,
and hinge seam gap. Aggregate AABB intersection cannot prove overlap on the
clipped octagonal adapter profile. SysML owns the transition length needed to retain the
required overlap across the full adapter width; interface tolerance is a
separate datum. The new cooked-geometry path has compile evidence only; fresh
Editor execution and readback remain pending. GRR-006 requires each physical
track to be a convex mesh and checks its composed collision bounds and
upper/lower toe vertices against the same SysML length, thickness, deployment
angle, and FLIP track-width datums. A
shared mechanical relation derives the miter run from thickness and deployment
angle.
GRR-010 checks both transformed toe edges against terrain; the top face is
12.228605 m, the track centre is 5.19 m, the adapter top is 5.28 m, and the
touchdown COM datum is 3.98 m. These remain explicit study values, not accepted
supplier dimensions. The source changes still need typed Editor application,
fresh composed readback on both sides, and deployed FLIP traversal with
wheel-contact evidence. The separate octagonal tank-support perimeter remains
distinct from the outer deck collider.

GRR-011 now owns the existing 95 kg ramp-body mass and (210, 34, 210) kg m²
diagonal-inertia study values in SysML; its composed checks only confirm the
builder uses that source. The values are not mass-properties acceptance. GR-021
remains planned until center of mass and inertia are sourced and frame-checked
for every dynamic body.

## Remaining acceptance boundary

1. `QueryUsdPrims` supplies one-snapshot collision bounds and composed mesh
   point arrays. The standard mechanical relation and SysML/USD check helpers
   now expose the reusable calculations; the Twin observer chooses feature
   paths and SysML supplies required dimensions and tolerances.
2. Add resolved SysML feature navigation, constraint invocation/bindings,
   collection/index/aggregate operations, and quantity/unit/frame validation.
3. Map dynamic-body mass, center of mass, inertia, collider ownership,
   contacts, and solver state to typed provider facts. Keep unavailable or
   stale samples inconclusive.
4. Model configuration and temporal applicability in source before treating
   a landing, ramp, detach, or FLIP egress run as acceptance evidence.
5. Capture a source revision, composed document generation, physics run
   configuration, observation time/frame, and evidence artifact identity in a
   single result package.

The full gap inventory and migration order are in
[`implementation_gaps.md`](implementation_gaps.md). A structural pass does not
qualify landing dynamics, structural loads, propulsion, or FLIP egress.

## Modelica compilation review — 2026-10-19

The normal surface-operations scene admits all ten Modelica participants,
advances them beyond 0.1 s and reaches fault-free readiness with no pending
holds using the reviewed shared library. The current production gates pass
GNC 19, engine-out 20, RCS commands 19 and both depletion cases 11 each.
The shared library review additionally covers motor/thermal conservation,
sensor and tank closures, PID bounds, allocator compilation and cold package
admission; its maintained regression is `scripts/api/test_model_physics.py` in
LunCoSim.

## Verification registry audit — 2026-10-20

Fresh mapped production gates pass aggregate requirements (40 checks), flight
stow (272), touchdown geometry (6), engine-out (20), held engine commands (13)
and pilot attitude (9). These runs use source revision
`17565176433882467050`; each report identifies its qualified verification and
the harness records the executable SHA-256. Evidence is under
`/tmp/griffin-audit-20261020/`, including `dynamics/` and `landing/`.
The mapped landing-stability case also passes: all 361 samples over
60.0333 s after touchdown retain four-pad contact. This is one fixed-clock
production run, not a fresh-process pair or rendered replay qualification.

The later source-pinned fresh-process pair also passes at source revision
`8917579474384013968` on the preserved executable below. Both runs finish at
tick 5000, retain four-pad contact in 361/361 post-touchdown samples over
60.0333 s, and have exactly zero final position, upright-axis, ground-speed
and angular-speed deltas. `landing-pair/` retains both reports, executable/
Twin/library source snapshots, and the native fixed-clock comparator output.
This pair does not replace retained or rendered restart qualification.

The static engine-out producer now writes guidance throttle rather than
assuming possession establishes manual authority. The held-command observer
selects exact entity/name/direction ports and rejects duplicate owners; it no
longer interprets a human-readable solver description as a stable identity.
Its native mass/inertia propagation and physical burn/release bounds remain
unchanged.

The rover/leg fixture's old start heights penetrated the actual DEM. Native
footprint samples measured maxima 0.409260 m at the pads and 0.711725 m over
the rover footprint. The fixture now uses source-owned initial elevations
1.10/1.47 m, including at least 0.25 m sampled clearance above the respective
unloaded bottom datums. Both vehicles settle under gravity; no runtime pose
teleport is used. The observer also checks the authored poses and four-pad
settling before the drive. All 91 checks pass at source revision
`11704465423611673138`, with a 1242.315498 N s impulse attributed to the PX
shock-barrel collider and maximum measured penetration 0.000001 m against
the unchanged 0.01 m allowance.

The contact adapter uses the maintained native GJK/EPA API with a surface
projection seed. Its 31 geometry checks pass, including the captured large
Cylinder/Cuboid query and the previous distant-origin terrain counterexample.
The complete shared physical-rover matrix now passes 33 checks through tick
2229. These production results use executable SHA-256
`a7cb47ac716fa1708efa4a59613a96090b8cf1be7923c387dd2a5fce26cdd0fa`;
logs and reports are in `contact-production/` under the audit directory.
No contact limits or dependency source were changed.
The zero-throttle impact case also passes all nine checks through 1800 ticks
at source revision `8917579474384013968`: maximum main thrust is exactly zero,
maximum sampled rim clearance deficit is 0.000847 m, and all four pads settle.
It now takes manual authority through an actual pitch input and releases that
input to neutral; selection alone correctly preserves guidance. Its evidence
is in `impact-final/`. The shared authored plume-activity fixture passes six
checks after its program stimulus was moved to guidance inputs.

The shared plume graphics observer also passes in a fresh High / standard-PBR
window after the reusable lander's actuator envelope was aligned with its
authored chamber capability. The old 60 kN cap rejected valid full-throttle
output; the source-owned replacement is 31.75 kg/s × 2940 m/s × authored
combustion efficiency = 89611.197997 N, matching the chamber's native
`maximum_thrust_n`. This is the generic reduced-model design envelope, not a
Griffin engine rating or a changed acceptance tolerance. The native USD API
saved the source and read it back. The fresh observer measures activity
0.993015, plume length 4.0 m and momentum flux 83478.847510 N. Readiness and
connections are clear, runtime diagnostics are zero, and the full plume was
inspected after a native camera reframe. `plume-qualified/` retains the result
and captures; `capacity-author/` records the saved parameter and provenance.

The adapter-release observer now declares its SysML query dependencies, uses
the current derived-binding contract, converts native unsigned entity counts
explicitly for integer arithmetic, and binds its once-only verdict state through
the Rhai method receiver. The unchanged physical topology predicate passes at
tick 2078: 19 to 18 joints/graph edges and 4481 to 4480 entities, with zero pending
joints or detach requests across 180 post-release samples. The qualified mapped
report is in `release-final-qualified/`; earlier no-verdict/error logs are failed
observer iterations, not physical-release qualification.

The complete High / standard-PBR rendered production mission also passes all
16 gates at source revision `8917579474384013968`, using the executable above.
An owned native window input sequence selects Griffin without manual flight
authority, presses U after qualified touchdown, and presses F after measured
ramp settling. FLIP physically drives across the deck, down the ramp onto four
DEM contacts, then completes both survey waypoints and the base-site leg. The
final verdict is at tick 6743 (112.3833 simulation seconds). Readiness is clear,
all connections are resolved, and runtime diagnostics report zero errors and
warnings. The mission and inspected captures are in `surface-window/`. Native
Wayland cursor-warp rejection is retained in the application log; it did not
prevent keyboard delivery or the domain verdict. These are behavior and visual
results, not clean performance or strict-replay qualification.

After that mission verdict, the settled 1280 × 720 High / standard-PBR window
rendered only 15 frames over 24.924 s (0.60 frames/s). The terrain had all
256 requested tiles resident, no pending tiles and its derived map complete.
The camera was unchanged and domain diagnostics were clear. These facts
establish the measurement cohort; they do not attribute the slowdown. The time owner
records 64-cycle catch-up batches and roughly 22–26 ms per fixed cycle, above
the 16.667 ms service budget. Other-worktree compilation and a foreign native
simulator were active. This contention-affected result fails the intended
responsive/realtime experience; no performance improvement is claimed. The
normal artifact remains preserved separately from the diagnostic Tracy build.

The diagnostic Tracy artifact is separate from the normal executable:
`c617e5cc617b700f7133180a9680a1e8c8979eed3727d49025bd8569f3696297`.
Its qualified `profile-coarse/native.tracy` capture has 11,990,142 CPU zones
and 431,698,612 bytes, comprising 431,621,098 compressed payload bytes plus
the native six-byte header and 19,377 four-byte block lengths. All blocks are
complete and native inclusive/self exports succeed, with 13,817 valid rows
in each pipe-delimited export (the default separator conflicts with commas
in Rust generic names). Earlier startup/audit-noisy captures were excluded.
A filtered capture was truncated when the separate `/tmp` filesystem filled;
its framing failure and hashes are retained in
`trace-integrity-initial.json` under the simulator's local evidence directory.
Only this task's unused large debug outputs were removed before recapture.

The diagnostic settled window records fixed cycles around 27–28 ms and
64-cycle batches around two seconds; pending simulation time rises. Across
the capture, CCD solving and repeated native joint projection are the main
physics costs. These inclusive parent/child and worker costs must not be summed
as independent wall time. The capture is owner attribution under instrumentation
and concurrent workload, not a performance result or a completed mission.
The shared time owner now yields between complete cycles after one fixed
timestep of measured wall-clock service, retaining every queued quantum. The
new slow-cycle regression fails before this repair (four cycles drained) and
passes afterward (one cycle per update, all four eventually completed with
exact conservation). All nine selected clock/admission/rate tests pass.

Normal production executable SHA-256
`eba164e94af539c46fde6ca4e25e76ce9a2f409faaea725fc2721156eb70c759`
passes the complete rendered 16-gate mission again at source revision
`8917579474384013968`. The same owned window then passes the unchanged strict
94-sample comparison across two 90-second restarts, including exact thrust,
guidance and touchdown states, cooked rover bounds and the source-owned pose
and velocity tolerances. Readiness, diagnostics and connections remain clear.
`surface-budget/` contains both results and inspected production captures.

After the mission, an unchanged camera with all 256 requested terrain tiles
resident renders 777 frames over 24.000 s (32.37 frames/s), High / standard-PBR
at 1280 × 720. It delivers only 0.5658 simulation seconds per wall second. One
foreign native simulator and browser/compositor activity remain present; the
workload differs from the earlier slow window, so these are separate cohorts,
not a controlled FPS speedup claim. Long 64-cycle batches are removed, but
responsive presentation does not qualify real-time throughput. That performance
requirement remains open. The normal artifact is restored at the default path;
the owned API session is closed after verification. Pure formatting of the time
owner followed the qualified loop without another rebuild.

## Operator handoff review — 2026-10-20

Selecting the lander preserves automatic guidance. Its first accepted flight
input establishes manual authority; returning the input to neutral retains
that authority until explicit release or reconnection. The GNC model's
`inputs:piloted` is wired to the same lander authority output used by the
flight-command mux. HUD callbacks request guidance engagement through a
typed event; the mission's Simulation actor owns the applied Modelica write.

The production GNC gate passes 19 checks, including powered automatic descent
after selection, input takeover, neutral manual retention, actual GNC input
and command-gate values, explicit disconnect/reconnect, and invalid-action
rejection. Its source revision is `3359321482464983365`.
An owned native-window run additionally passed key press/release and the
RECONNECT GNC button: guidance authority changed 1 → 0 → 1, manual authority
changed 0 → 1 → 0, and readiness remained fault-free with no pending inputs.
The screenshots show AUTO, MANUAL and AUTO respectively. Evidence is in
`/tmp/griffin-realism-20261019/gnc-authority-final.log` and `gnc-window/`;
window captures also reside in the simulator's
`.cache/codex-evidence/griffin-review/`. The session exited and released port
4291. This proves application event handling, not physical keyboard hardware.

The shared drive-law gate passes six checks. The physical-rover matrix's
earlier tick-1607 query failure is covered by the contact follow-up above.

The FLIP route observer preserves the route editor's explicit `retryable`
projection status after adding a point. It waits within its existing ten-second
phase deadline; permanent errors fail immediately with the owner diagnostic.
The route completes all three points and passes 25 assertions, including all four gearbox heat inputs at the thermal
participant, nonnegative gear dissipation and a rising drivetrain-bank
temperature.
The shared `GearRatio` model applies efficiency in both power directions,
exports dissipated heat and checks its torque rating. Four `HeatLoad` facets
route gearbox losses into the enabled lumped motor/gear thermal banks. Their
coefficients remain study assumptions. Native wheel/brake/tire forces stay
under their native mechanical owners; their measured losses enter HeatLoad
facets without adding a second mechanical force. Native bearing, brake and tire loss outputs feed the same thermal collection.
A passive contact network conducts into wheel and averaged near-contact ground
masses; actual support opens each ground conductor while airborne. Motor/gear,
hub/brake, wheel and ground lumping and conductances are study assumptions.
The route includes a real brake application and verifies all four bearing/tire
paths, braking heat and wheel/ground thermal response. The maintained shared
mechanical regression has 46 checks including contact energy conservation and
airborne isolation; native mechanics has 13 and drivetrain parity has 20.
Evidence: `/tmp/griffin-native-heat-20261019/route-final.log`.

### Griffin ramp opening — 23 October 2026

The installed unequal-section mechanism passes 30 integration, 22 flight-stow,
10 nominal-toe and 20 production post-landing deployment checks. Both banks
settle after root clearance, middle opening, opposite toe opening and final
terrain-fitted root lowering. See
[the deployment repair contract](griffin-ramp-deployment-2026-10-23.md) and its
portable receipt for exact evidence and executable provenance. This accepts
opening only; rover traversal and the 60 FPS target remain separate gates.

## 28 October compact-ramp shading and manual release correction

The [release receipt](griffin-ramp-release-2026-10-28.md) records six passing
manual-detach and forward-motion checks, the shared open-idle motor contract, twelve hidden but
active contact proxies, and a rendered Sun-only review. Automatic tethered
egress remains unqualified.
