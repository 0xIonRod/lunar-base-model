# FLIP motion acceptance

The motion observer also samples the native panel angle, relative angular
velocity and controller setpoint on every driving, braking and stopped-dwell
tick. It fails on unavailable/nonfinite samples or the SysML-owned holding
error/rate bounds. Three aggregate checks and peak measurements are retained
in the same terminal verdict/evidence; the complete positive gate now has
44 checks. See [panel-hold review](flip-panel-hold-2026-11-04.md) for the
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

All observations finish through `FLIP_MOTION_COMPLETE`, including setup,
command, motion, stopping and dwell failures. Failure messages include the
applicable measurements and bounds. `FLIP_MOTION_EVIDENCE_RESULT` retains
the source-owned configuration and both directions' observations.

The fixture explicitly authors `inputs:apply_brake`. The qualification driver
forks that document and changes this stimulus to false, so it must detect a
real failed physical stop and publish a terminal failure. It does not replace
the physical response or inject a passing verdict. See [test commands](../tests/README.md).
