# FLIP motion acceptance

The motion observer also samples the native panel angle, relative angular
velocity and controller setpoint on every driving, braking and stopped-dwell
tick. It fails on unavailable/nonfinite samples or the SysML-owned holding
error/rate bounds. Three aggregate checks and peak measurements are retained
in the same terminal verdict/evidence; the complete positive gate now has
45 checks, including source acceptance. See [panel-hold review](flip-panel-hold-2026-11-04.md) for the
drive correction and current execution boundary.

`requirements/flip_motion_requirements.sysml` owns the reconstructed rover's
motion-study envelope and `Verify_FLIPMotion` binding. These are simulator
acceptance values, not supplier braking specifications. USD owns friction,
brake authority, mass and damping; the observer does not tune them.

`scenarios/tests/flip_motion.rhai` establishes the prescribed measured entry
speed in each direction. It checks native wheel roll, render alignment and
upright posture, then applies the physical brake. A stop must satisfy the
distance limit and the deadline derived from its measured entry speed,
minimum average deceleration and response allowance. A stopped dwell checks
speed and drift before reverse motion or completion.

The required `FMR001_DirectionEnvelope` constraint evaluates each direction's
measured travel, minimum wheel rate/render alignment, upright posture, entry
and stopped speeds, stopping time/distance, dwell peaks and panel peaks against
the same `MotionStudy` values. Both directions must complete the native control
procedure. Typed telemetry observations retain the source revision and sampled
tick interval. Missing phase observations remain unavailable to the evaluator;
they cannot become zero-valued passing measurements. Structured requirement
evidence is emitted on `FLIP_MOTION_ACCEPTANCE` before the terminal motion
verdict. The source catalogue links this requirement to this study procedure,
without presenting its envelope as supplier braking data.

The observer acquires the authoritative local embodiment through the shared
possession command so held semantic intents use its native controller binding.
Its helper import is relative to the observer's mounted source. The gate runs
through the production headless scene-test runner as well as an interactive scene.

All observations finish through `FLIP_MOTION_COMPLETE`, including setup,
command, motion, stopping and dwell failures. Failure messages include the
applicable measurements and bounds. `FLIP_MOTION_METRICS` retains
the source-owned configuration and both directions' observations.

The fixture explicitly authors `inputs:apply_brake`. The qualification driver
forks that document and changes this stimulus to false, so it must detect a
real failed physical stop and publish a terminal failure. It does not replace
the physical response or inject a passing verdict. See [test commands](../tests/README.md).

## Manual steering and lateral wheel force

Astrolab identifies FLIP as a four-wheel skid-steer rover. Turning requires a
difference between the left and right wheel speeds. During a pivot the front
and rear wheels must scrub sideways in opposite directions relative to the
ground. The chassis centre can translate much less than an individual wheel
contact. A turn therefore gives no reason to require zero wheel slip or to
accept sustained sideways chassis motion after the driver releases steering.
[Walker, Randell & Shar, LPSC 2026, abstract 1874](https://www.hou.usra.edu/meetings/lpsc2026/pdf/1874.pdf)
and [Yi et al., IEEE Transactions on Robotics, 2009, §§I–II](https://jingangyi.rutgers.edu/pdfs/IEEETRO_2009.pdf)

### Required behavior on Griffin terrain

The limits below apply to the manual steering fixture on the NOBILE03 terrain,
on a starting grade of about 4.6°. They are engineering acceptance values for
this Twin. The mass model uses Venturi’s 450 kg rover specification. Astrolab’s
480 kg figure describes the launch allocation. [Venturi FLIP specifications](https://venturi.space/en/rovers/)
and [Astrolab mission paper](https://www.hou.usra.edu/meetings/lpsc2026/pdf/1874.pdf)

| Requirement | Input and expected response |
| --- | --- |
| FMR-002 · Wheel loading and grip | Brake for 3 s. Over the last second, the mean sum of the four wheel normal reactions shall be within 5% of 729 N. Each wheel shall develop lateral force during rolling, oppose lateral slip in a pivot under drive torque, and show positive modelled sinkage. Individual wheel loads may differ on a grade or during a turn. |
| FMR-003 · Pivot, cancellation and release | With throttle released, hold A+D together for 1 s. Peak absolute yaw rate shall stay below 0.02 rad/s. Hold D or A separately for 3 s. The nose shall turn toward that key, exceed 0.12 rad/s in the commanded direction at the endpoint, and stay below 0.35 rad/s peak yaw and 0.15 m/s peak chassis lateral speed. At 2 s after key release, absolute yaw rate shall be below 0.025 rad/s. |
| FMR-004 · Moving turn and recovery | After 4 s of W or S, enter a 3 s W+D or S+A turn above 3 m/s with absolute entry yaw below 0.035 rad/s. Exit above 3 m/s in the same travel direction and above 0.015 rad/s yaw in the commanded nose direction. During the arc, peak absolute yaw shall stay below 0.13 rad/s and peak chassis lateral speed below 0.50 m/s. Two seconds after D release with W held, absolute yaw shall be below 0.03 rad/s and lateral speed below 0.15 m/s. After braking for 8 s, both longitudinal and lateral speed components shall be below 0.05 m/s in magnitude. |
| FMR-005 · Physical validation, open | Before claiming FLIP-specific handling accuracy, compare independent representative wheel-force and vehicle-motion data with predictions under matched conditions and predeclared error bands. The measurements needed are listed below. |

Steering release commands zero yaw and allows the rover to coast. Space brakes
the wheels. In reverse, A still commands the nose to turn left. The manual
controller requests at most 0.30 rad/s at low speed and 0.30 m/s² divided by
speed above 1 m/s. At 4 m/s this gives 0.075 rad/s, or a nominal 53 m turn
radius if the rover tracks the command in steady motion with negligible
sideslip. The motors and ground reactions determine the achieved turn.

### Wheel force on regolith

The Twin authors a rolling side-force/load curve on each wheel and soil
properties on the NOBILE03 surface. The two rolling knots are 0.24496 at 5°
and 0.37195 at 10°. They are the mean measured side-force/load ratios at each
angle from the three load groups below. At 182.25 N normal load and negligible
drive slip, rolling predictions are **44.6 N at 5°** and **67.8 N at 10°**. At
277 N and 5°, the prediction is **67.9 N**, compared with **71.4 N measured**.
The wheels share longitudinal and lateral tread traction. A wheel contacting
a rigid ramp uses the ordinary rigid-tire curve. [Green, Table 2](https://ntrs.nasa.gov/api/citations/19750021903/downloads/19750021903.pdf#page=41)

At low longitudinal speed the soil model estimates a shallow footprint from
wheel load, radius, width and an effective linear pressure gradient. Available
soil shear depends on cohesion and internal friction. Lateral slip over the
estimated contact residence time mobilizes that shear and the passive resistance
of soil displaced by the side face. The two total force laws blend continuously
with speed. The low-speed residence time is regularized using the 1.07 m/s
lower rolling-speed bound. Above the last measured 10° knot the rolling branch transitions to the soil law
by 90°. High-angle forces and turns above the calibration speeds are extrapolations.
The geometric sinkage estimate supplies force
parameters while Avian carries the normal load. The ground mesh stays rigid.

The WES soil values are 0.98 MN/m³ penetration-resistance gradient, 760 Pa
cohesion, 38.5° internal friction angle and 1,524 kg/m³ dry bulk density.
Using the penetration gradient for wheel pressure, scaling unit weight by
1.62 m/s², and choosing 0.025 m as the shear-displacement scale are **study
assumptions**. The empirical rolling force already includes displaced soil,
so only the mechanistic branch adds a separate passive side force.
[Green, soil description](https://ntrs.nasa.gov/api/citations/19750021903/downloads/19750021903.pdf)
and [Ishigami et al., wheel-soil side force](https://doi.org/10.1002/rob.20187)

### Baseline calibration and diagnosis

The following calculations describe the earlier rigid wheel on regolith.
They document the discrepancy that motivated the current model.

Green’s WES experiment towed a yawed Apollo LRV wheel through terrestrial lunar
soil simulant. Two runs close to the Twin’s nominal wheel load give a direct
small-angle comparison. A least-squares line through zero fit to the reported
side-force/load ratios of 0.219 and 0.335 gives 2.0374 per radian. At the
nominal load of 450 × 1.62 / 4 = 182.25 N, that rounds to 371 N/rad. The two fitted points also
show the error incurred by using one slope. [Green, WES Technical Report M-71-7, Table 2, PDF page 41](https://ntrs.nasa.gov/api/citations/19750021903/downloads/19750021903.pdf#page=41)

| WES test | Yaw | Tow speed | Measured load | Measured side force | Measured force scaled to 182.25 N | Twin prediction at 182.25 N | Difference from scaled measurement |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 31 | 5° | 1.32 m/s | 189 N | 41.5 N | 40.0 N | 32.4 N | −19% |
| 32 | 10° | 1.33 m/s | 190 N | 63.7 N | 61.1 N | 64.8 N | +6% |

For a rolling wheel, the model’s lateral force opposes lateral slip. At
negligible longitudinal slip its magnitude before saturation is
`371 × min(Fz / 182.25, 1) × |slip angle in radians|` newtons. At zero normal
load both traction components vanish. Drive and cornering share one limit,
`sqrt(Fx² + Fy²) ≤ 0.60 × Fz`, or 109.35 N at nominal load. The coefficient
0.60 and the stiffness plateau above nominal load are model assumptions.
The slip-angle calculation floors its reference rolling speed at 1.07 m/s.
The fitted points provide no direct measurement of a near-stationary pivot.

An isolated numerical check of the LunCoSim tire-force function at 1.32 m/s
returned −32.38 N and −64.75 N for positive 5° and 10° slip, reversed sign for
negative angles, halved the force at half load and returned zero at zero load.
With simultaneous drive slip, the resultant saturated at 109.35 N. These are
force-law outputs. The vehicle measurements below come from the terrain run.

#### Why the baseline underpredicted the WES load sweep

The table compares the original measurements at their **actual** loads with
two evaluations of the native tire-force function. Both use one loaded contact,
the recorded yaw as the slip angle and zero longitudinal slip. The last column
extends the existing linear stiffness-versus-load slope through the tested load
range as a diagnostic. All six tow speeds were between 1.31 and 1.35 m/s.
[Green, Table 2, tests 25, 27, 31, 32, 35 and 36](https://ntrs.nasa.gov/api/citations/19750021903/downloads/19750021903.pdf#page=41)

| WES test | Yaw | Wheel load | Measured side force | Baseline one-contact prediction | With stiffness proportional to load |
| --- | ---: | ---: | ---: | ---: | ---: |
| 31 | 5° | 189 N | 41.5 N | 32.4 N | 33.6 N |
| 25 | 5° | 277 N | 71.4 N | 32.4 N | 49.2 N |
| 36 | 5° | 365 N | 94.0 N | 32.4 N | 64.8 N |
| 32 | 10° | 190 N | 63.7 N | 64.8 N | 67.5 N |
| 27 | 10° | 276 N | 113.0 N | 64.8 N | 98.1 N |
| 35 | 10° | 364 N | 135.1 N | 64.8 N | 129.3 N |

At 277 N, the stiffness has already reached its 371 N/rad ceiling at
182.25 N. Multiplying by 5° in radians gives 32.38 N. The friction ceiling
is 166.2 N at this load. Doubling the friction coefficient leaves all six
predictions unchanged. Extending the load slope recovers 16.8 N of the
39.0 N shortfall in test 25.

The remaining 22.2 N has two observable components. The angle fit uses one
straight line through zero. It requires doubling the angle to double the force.
At roughly 190 N, WES measured a factor of only 1.53 from 5° to 10°. Using
the 5° measurement alone and scaling by load gives 41.5 × 277 / 189 = 60.8 N,
11.6 N more than the load-scaled linear fit. The last 10.6 N reflects the
difference between the measured 5° force/load ratios in the two runs (0.219
and 0.258 as tabulated). Green found no consistent trend of that ratio with
load. The data do not identify a unique physical cause for this residual.
[Green, §29 and Fig. 9](https://ntrs.nasa.gov/api/citations/19750021903/downloads/19750021903.pdf#page=30)

The earlier jointed-wheel solver evaluated this nonlinear stiffness graph at each
contact point’s normal load. At an identical 5° slip angle on one plane,
one 277 N contact produces 32.4 N, while two contacts of 138.5 N each produce
49.2 N in total. Both represent the same wheel load. The original terrain regression checked mounted parameters, wheel support and chassis motion. Both contact layouts could pass it.

At 85°, a separate limitation applies. Test 47 measured side force equal to
1.266 times wheel load, beyond the Twin’s 0.60 limit. Soil displacement can
contribute substantially to turning resistance. Parabolic-flight experiments on another rover wheel also found
that changing soil gravity at fixed wheel load changed traction and sinkage.
Those results provide no FLIP-specific lateral correction factor.
[Green, Table 2 and results](https://ntrs.nasa.gov/api/citations/19750021903/downloads/19750021903.pdf#page=41)
and [Niksirat, Daca & Skonieczny, IJRR, 2020](https://doi.org/10.1177/0278364920913945)

Closing FMR-005 requires representative FLIP wheel tests at positive and
negative slip angles, multiple normal loads, and combined drive and cornering,
with the wheel construction, soil preparation, gravity and uncertainty recorded.
Vehicle trials must also supply pivot, release and rolling-turn yaw and lateral
velocity time histories. Establish the allowed prediction error for the intended
use before comparing held-out trials. Surface-test or flight telemetry with a
known initial state would support that comparison.

### Measured response on Griffin terrain

The production steering fixture sampled chassis motion at 60 Hz. These are
the measured results on the same maneuver sequence. The middle column records
the earlier controller revision on the rigid tire. The soil model uses the
same controller and acceptance limits.

| Maneuver | Original rover | Revised controller, rigid tire | Revised controller, soil | Study limit |
| --- | ---: | ---: | ---: | ---: |
| A+D together, peak absolute yaw | — | — | 0.00016 rad/s | < 0.02 rad/s |
| D from low speed, peak yaw over 3 s | 2.698 rad/s | 0.226 rad/s | 0.213 rad/s | < 0.35 rad/s |
| Absolute yaw 2 s after D release | 0.351 rad/s | 0.00013 rad/s | 0.00017 rad/s | < 0.025 rad/s |
| W+D, peak chassis lateral speed over 3 s | 3.95 m/s | 0.231 m/s | 0.167 m/s | < 0.50 m/s |

The W+D entry speeds were 4.33, 4.16 and 4.14 m/s, respectively. In the soil
run, lateral speed fell to 0.0073 m/s two seconds after releasing D with W
held. A from low speed reached 0.228 rad/s peak yaw magnitude in the opposite
direction. Mean settled wheel support was 729.6 N.

The 10 Hz trace contains 1,524 wheel observations. In the last sampled instant
of the right pivot, front left and right contacts slipped laterally at +0.099 m/s
and exerted −70.9 and −67.6 N. Rear left and right contacts slipped at −0.225 m/s
and exerted +88.7 and +80.5 N. Each reaction opposed the corresponding wheel’s
lateral motion. The chassis reached 0.063 m/s peak lateral speed during that pivot.

The [SysML requirements](../requirements/flip_motion_requirements.sysml),
[evidence catalogue](../requirements/griffin_requirement_sources.sysml) and
[steering test instructions](../tests/README.md#manual-steering) specify and
reproduce this run. All eight wheel and maneuver evaluations passed.

### Wheel-force model and acceptance tests

The native mobility suite exercises the force law used in the wheel spin solve
and the applied contact forces. At 277 N wheel load, it splits a prescribed
contact into one, two and four points with the same load centroid, surface
normal and slip. The total force and moment must agree within 1e-10 N and
1e-10 N·m, including when drive demand saturates the tread. Separate cases
cover unloading, zero lateral slip and both slip directions.

The load-transfer check refits the rolling curve while withholding one WES
load group, then predicts both observations in that group. Across the six
predictions the mean absolute error is 7.6 N and the largest relative error
is 17.3%. The original one-contact law gave 38.2 N mean absolute error on
the same six observations. Intermediate angles, driven wheels, pivots and
FLIP hardware still need independent measurements.
[Green, Table 2](https://ntrs.nasa.gov/api/citations/19750021903/downloads/19750021903.pdf#page=41)

The steering fixture reads the mounted wheel calibration and collects the
native load, drive torque, longitudinal and lateral force, lateral slip speed,
slip angle, estimated sinkage and lateral dissipation for each wheel at 10 Hz.
The trace includes chassis yaw rate and velocity from the same observation.
FMR-002 checks support and contact response. FMR-003 and FMR-004 check chassis
motion under the manual controller. FMR-005 tracks validation against independent
measurements on hardware.
