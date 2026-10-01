# Current owned mission replay

Model source checkpoint: 664db08. Simulator: private
/tmp/griffin-terrain-a770-luncosim, reports a7707995, built from clean terrain
a7707995c. Owned exec session17319, PID773329, confirmed live after startup.
Log: /tmp/griffin-current-mission-structured-replay.log.

Command from terrain:
/tmp/griffin-terrain-a770-luncosim test --scene
/home/rod/Documents/models/lunar-base-model/twins/astrobotic-griffin-1/scenes/griffin_1_surface_ops.usda
--max-ticks 20000 --verdict-channel GRIFFIN_SURFACE_OPS
--tick-hz 60 --threads 1 --jitter 0

Landing geometry/four-leg rest-pose and dynamic guidance assembly-mass
preflights have passed. Touchdown, ramp settling, release and egress have no
current verdict yet. Poll this same session/process; a wait timeout is not a
terminal result. Do not restart or edit this fixture merely because it takes
wall time. The repaired reporter should preserve typed hinge/pose evidence if
a phase fails. Capture the actual first failure before changing drive values.

Known adjacent issue: combined Editor framing disagrees with canonical USD;
pausing/reopening did not resolve it. Isolated ramp section review was useful.
All owned Editor review processes ended137 this turn, cause unestablished.
No Editor API49746 remains live. Do not interpret the component gate/screenshot
as accepted combined runtime rendering or successful landing.
