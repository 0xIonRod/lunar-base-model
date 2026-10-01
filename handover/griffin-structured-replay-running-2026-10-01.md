# Owned mission replay: terminal ramp failure

Model source checkpoint: 664db08. Simulator: private
/tmp/griffin-terrain-a770-luncosim, reports a7707995, built from clean terrain
a7707995c. Owned exec session17319, PID773329; completed with exit 1.
Log: /tmp/griffin-current-mission-structured-replay.log.

Command from terrain:
/tmp/griffin-terrain-a770-luncosim test --scene
/home/rod/Documents/models/lunar-base-model/twins/astrobotic-griffin-1/scenes/griffin_1_surface_ops.usda
--max-ticks 20000 --verdict-channel GRIFFIN_SURFACE_OPS
--tick-hz 60 --threads 1 --jitter 0

Landing geometry/four-leg rest-pose and guidance assembly-mass preflights
passed. The replay reached touchdown and commanded middle-section unfolding,
then emitted terminal FAIL: GR-004-phase-ramp-middle-unfold-settle at tick
5822, 97.03 simulation seconds (12800 updates). The structured reporter worked.

At failure, middle hinge targets were -1.570796327 rad; measured angles were
1.841475010 rad (port) and 1.840436578 rad (starboard), giving wrapped errors
2.870913970 and 2.871952402 rad. Root targets remained +/-pi/4 and toes stayed
near +pi/2. These observations do not identify a confirmed cause; inspect
joint frames, drive convention and effective collision interaction before
changing actuator strength or widening acceptance tolerances.

The lander was quiet at this snapshot: four-leg contact=1, upright=.99709,
horizontal speed=.000927 m/s, descent=.000502 m/s, angular speed=.000891 rad/s.
This snapshot does not establish repeatable landing acceptance: touchdown
occurred substantially earlier than in previous same-settings replays.

The event trace was empty despite emitted mission events. The shared
trace_event function mutates a passed map without returning its changes;
this likely loses the trace under Rhai value semantics. Also, failure metrics
currently expose the prior middle-settle field rather than the current failed
section-settle observation. These are follow-up evidence defects, not proof
of a hinge cause. The full native BLACKBOX payload is in the log; a decoded
local copy is /tmp/griffin-current-mission-evidence.json. No accepted ramp
unfolding, payload release or FLIP egress result exists.

Known adjacent issue: combined Editor framing disagrees with canonical USD;
pausing/reopening did not resolve it. Isolated ramp section review was useful.
All owned Editor review processes ended137 this turn, cause unestablished.
No Editor API49746 remains live. Do not interpret the component gate/screenshot
as accepted combined runtime rendering or successful landing.
