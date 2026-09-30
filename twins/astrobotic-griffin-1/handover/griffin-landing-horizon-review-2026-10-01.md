# Current mission replay and runner horizon

Replayed the authored surface mission against model revision
83a0a9deb21e838ff673174808968ad2708193d8 and terrain core a7707995c.
The owned headless runner used one thread, zero jitter, 60 Hz,
seed 6840157149251759617 and a 14,400-tick ceiling. It terminated with
exit 2 and no GRIFFIN_SURFACE_OPS verdict. No touchdown, engine-cutoff or
flight-handoff event was observed. Geometry/rest-pose preflight passed;
guidance and dynamic joint-island mass both measured 5509.999996185303 kg
at tick 8. Neither preflight establishes landing acceptance.

The important horizon mismatch is in the earlier execution instructions:
14,400/60 = 240 seconds, while the source-owned landing phase watchdog
waits 300 seconds (`Griffin1Lander::landingPhaseTimeoutS`). The runner can
therefore expire before `fail_phase("landing")` collects its coherent control,
attitude, leg contact and physical-ramp snapshots. This run does not provide
those terminal snapshots, so controller tuning from it would be premature.

README and instructions now use a 120,000-tick / 2,000-second outer mission
ceiling and describe a 20,000-tick / 333.3-second focused landing diagnosis.
These are explicit execution-budget choices, not relaxed physics thresholds.
The focused diagnosis assumes prompt mass readiness, verified at tick 8 in
this replay; a delayed readiness phase can require a larger outer ceiling.
Source phase limits, event predicates and controller values are unchanged.

The log is `/tmp/griffin-current-surface-ops-2026-10-01.log`. Its BLACKBOX
event lines report sim_secs/sim_tick as zero even after the epoch advances;
do not treat those fields as trustworthy trajectory timestamps. The Rhai
mass snapshot carries its own coherent tick. A warning about two scene suns
also needs separate owner investigation: the second composed DistantLight is
the body-owned Earthshine source (authored intensity zero), not a second
authored solar source. It was not disabled to suppress the warning.

Next diagnostic: let the landing watchdog finish at its actual bound and
inspect the typed failure snapshot before changing guidance or geometry.
Full touchdown, ramp motion, release and rover egress remain unaccepted.
