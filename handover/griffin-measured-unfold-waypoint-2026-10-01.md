# Measured Griffin ramp unfolding sweep

The direct stowed-to-level intermediate-joint command is antipodal: joint
coordinates +pi/2 to -pi/2. Avian0.7.0 apply_motor wraps target-current to
[-pi,pi); a small positive stow error chooses the opposite opening sweep.
A joint-frame offset does not remove this target-to-current half-turn.
Source inspected locally:
~/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/avian3d-0.7.0/src/dynamics/solver/xpbd/joints/revolute.rs
https://docs.rs/avian3d/0.7.0/src/avian3d/dynamics/solver/xpbd/joints/revolute.rs.html
The web fetch was unavailable; the local versioned implementation is the
actual evidence for the wrap rule, not a successfully fetched webpage.

SysML now derives a halfway relative angle from the existing stowed and
level study poses. Rhai commands the middle pair to that waypoint, verifies
measured angles while holding toes stowed, then commands level. Toe motion
uses the same helper after middle completion. No actuator-strength, hinge,
collision, pose, mass, or timing threshold changes. The existing 0.035 rad
position tolerance remains; it is NOT proof of durable settlement.

The mission now retains event_trace returned by its report helper. Failure
report guards also return their state flag to the scenario. Failure metrics
include the current section observation, expectations and waypoint evidence,
rather than only previously completed phase snapshots. The obsolete
section_angle_expectations helper was removed after checking all callers.

All initial Rhai changes used owned Editor OpenTwinSource/SaveSourceText and
library registration; SysML used ApplySysmlOps/SaveSysmlDocument. Editor
exec57072/PID802061 ended137 during a later save, cause unestablished. Disk
state was rechecked; remaining Rhai compiler-depth/caller edits occurred with
that Editor stopped. No USD authoring was needed for this command policy.

Replay1 (/tmp/griffin-waypoint-unfold-replay.log, exec89344) reached touchdown
then repeatedly failed the new attribute lookup. The new name was absent from
griffin_spec's package map. Explicitly stopped that owned process with SIGINT,
exit130; corrected the mapping, not the core evaluator. This was not a
terminal mission verdict or hinge-motion evidence.

Replay2: private terrain a7707995, exec27191, API49748, scene
scenes/griffin_1_surface_ops.usda, max20000ticks, 60Hz, threads1, jitter0.
Log /tmp/griffin-waypoint-unfold-replay-2.log; decoded native evidence
/tmp/griffin-waypoint-unfold-evidence-2.json. Source revision8717376682321458785.
Live query confirmed waypoint0, level-pi/2, stowed+pi/2 rad. At tick6020 the
middle stow angles were1.57251/1.57219 rad, showing the small positive error
that makes an antipodal direct command select the wrong shortest path.

Observed sequence (mission-retained event trace now populated):
- touchdown8156
- middle commanded8253; measured waypoint8288; level complete8385
- toes commanded8385; measured waypoint8426; level complete8475
- roots commanded8475; position gate complete8535

Middle waypoint errors .01101/.01168 rad; toe waypoint .01314/.01346 rad.
The intermediate level snapshot at8474 and root snapshot at8534 meet the
existing .035rad position criterion. Both assemblies actually unfolded along
the intended command stages. Do not call this stable deployed acceptance:
at8550 root errors are .20268/.19432 rad and intermediate errors range
.17133-.37921 rad. Single position crossings permitted premature release.
Lander descent speed is .09898m/s and angular speed .02240rad/s at failure.

Terminal FAIL exit1, GR-004-phase-rover-engage, tick8550/142.50s,
19136updates. FLIP adapter retirement, possession and ACKERMANN verification
were observed, then brake hold rejected the rover as unavailable. Static
inspection: griffin_controls::resolve calls find(path), the name lookup,
whereas the preceding possession helper uses find_path(fullUSDPath).

Next iteration: fix that exact resolver; add a source/rationale-backed low
hinge-rate and continuous dwell gate, recheck all six hinges before payload
release, and inspect terrain/toe contact under actual landed pose. Use the
existing angular_velocity joint output. Do not raise torque or enlarge angle
limits to make the watchdog green. Full landing repeatability, stable deployed
ramps and physical FLIP egress remain unaccepted.
