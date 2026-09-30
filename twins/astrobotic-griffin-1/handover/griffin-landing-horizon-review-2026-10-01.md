# Current mission replay and runner horizon

Replayed the authored surface mission against model revision
83a0a9deb21e838ff673174808968ad2708193d8 and terrain core a7707995c.
The owned headless runner used one thread, zero jitter, 60 Hz,
seed 6840157149251759617 and a 14,400-tick ceiling. It terminated with
exit 2 and no GRIFFIN_SURFACE_OPS verdict. Engine cutoff occurred at tick
13219 / 220.316667 s, touchdown at tick 13525 / 225.416667 s, and flight
handoff at tick 13531 / 225.516667 s. The mission consumed those events,
confirmed touchdown and commanded middle-section ramp unfolding. The runner
ended before that unfolding phase completed its 20-second settle watchdog.
Geometry/rest-pose preflight passed;
guidance and dynamic joint-island mass both measured 5509.999996185303 kg
at tick 8. Neither preflight establishes landing acceptance.

The important horizon mismatch is in the earlier execution instructions:
14,400/60 = 240 seconds, while the source-owned landing phase watchdog
waits 300 seconds (`Griffin1Lander::landingPhaseTimeoutS`). The runner can
therefore expire before `fail_phase("landing")` collects its coherent control,
attitude, leg contact and physical-ramp snapshots. This run does not provide
those terminal snapshots, so controller tuning from it would be premature.
In this particular replay, touchdown preceded the shortened ceiling; the
immediate missing evidence is the ramp-settlement outcome, not a missing
touchdown event. Source-qualified wait paths need no speculative correction:
the mission's transition proves that its current event branch completed.

README and instructions now use a 120,000-tick / 2,000-second outer mission
ceiling and describe a 20,000-tick / 333.3-second focused landing diagnosis.
These are explicit execution-budget choices, not relaxed physics thresholds.
The focused diagnosis assumes prompt mass readiness, verified at tick 8 in
this replay; a delayed readiness phase can require a larger outer ceiling.
Source phase limits, event predicates and controller values are unchanged.

The log is `/tmp/griffin-current-surface-ops-2026-10-01.log`. BLACKBOX
collision/sensor and mission-authored event lines report sim_secs/sim_tick as
zero even after the epoch advances; those fields are not trustworthy trajectory
timestamps. The Modelica-derived landing events above have nonzero coherent
ticks, and the Rhai mass snapshot carries its own tick. A warning about two scene suns
also needs separate owner investigation: the second composed DistantLight is
the body-owned Earthshine source (authored intensity zero), not a second
authored solar source. It was not disabled to suppress the warning.

Next diagnostic: run beyond the ramp settle watchdog and inspect its typed
outcome before changing guidance or geometry. The fresh 20,000-tick run is
owned by exec session 43403, log `/tmp/griffin-landing-watchdog-2026-10-01.log`.
Touchdown events are now established for the earlier exact replay; full
landing stability, ramp motion, release and rover egress remain unaccepted.
