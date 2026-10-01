# Griffin ramp settlement checkpoint

The ramp observer now uses coherent native angle and angular-velocity samples.
Waypoints and final targets require angle error <=0.035 rad and absolute hinge
rate <=0.02 rad/s. Before rover release, all six hinges must satisfy these
limits over a 1 s sampled dwell; any failing sample resets it. SysML records
the source and rationale for these unqualified study choices. This is an
observation policy, not supplier actuator or deployed-lock certification.

The owned terrain a7707995 replay used the surface-ops scene, 60 Hz, one
Compute thread, zero jitter and a 20000-tick bound. It terminated FAIL at
tick9452 during middle-section settlement. Both middle hinges reached their
measured waypoint, but final angle errors were 0.06327/0.06553 rad and rates
0.02668/0.01513 rad/s. The policy correctly withheld further deployment and
payload release. Log: /tmp/griffin-rate-dwell-replay.log; decoded native
evidence: /tmp/griffin-rate-dwell-evidence.json.

Inspection found that lunco-cosim's angle and displacement writers replaced
the configured motor model on every command. A separate generic terrain core
fix preserves the motor model and force/torque limits. The replay above used
the old core; it does not validate that fix. No geometry, drive gains, force
caps or acceptance limits were relaxed to pass the replay.

The FLIP control resolver now uses find_path for its full USD path, matching
the possession helper. Owned API readback resolved the expected FLIP identity.
Production registration compiled all four modified tool libraries without
diagnostics after final edits; repository and whitespace checks passed.
The final root-timeout evidence retains the dwell observation. Requirements
were saved through ApplySysmlOps/SaveSysmlDocument. USD was unchanged.

Next: rebuild the corrected core, replay deployment, then inspect the exact
landed ramp/toe contact and FLIP egress. Stable deployed acceptance and a
correct complete landing/egress remain open.
