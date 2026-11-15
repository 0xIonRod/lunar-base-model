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
