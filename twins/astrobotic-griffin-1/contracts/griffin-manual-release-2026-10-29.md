# Explicit FLIP release and compact-ramp guidance — 29 October 2026

The Twin's DETACH ROVER callback submits the real adapter `DetachJoint` command
in the event hook. The compact manual task observes solver retirement, transfers
control to FLIP, disables route guidance and holds its normal parking brake.
The first deliberate forward/backward input releases that hold. There is no
ejection impulse, pose overwrite or automatic descent command.

An intermediate implementation queued the click behind `landing_contact`.
That made an explicit manual action wait silently when landing qualification
was false. The gate is removed: manual release authority is independent of
automatic landing acceptance. A paused click submits the request and its HUD
message asks the operator to resume for solver confirmation and handover.
The paused interaction is source-reviewed; the native replay below exercises
the running transport path.

Ramp markers now use the landed CompactEgress instance, whose local -X is the
outboard direction. The former markers retained a reference-world direction
after Griffin landed with a different yaw. Entry distance comes from the
compact-track stations; ground-exit clearance includes the CAD wheelbase.

Both `Bus/RampSharedShaft*` cylinders belonged to the retired folding banks.
They remained active because the original retirement plan only visited direct
vehicle children. Their native document-owner edit sets them inactive; the
plan now includes those nested shafts. Readback: vehicle document generation
2, projected generation 2, projection_ready true, both shafts inactive.
Explicit SaveDocument completed. The compact track assembly remains active.

The compact track curbs now have 24 invisible collision proxies in addition to
the 12 existing walking-plate proxies. These follow the source profile and
reduce lateral departure in the diagnostic trace. They do not qualify full
loaded descent or replace a tether.

## Native evidence

All replays use seed 6840157149251759617, 60 Hz and default thread policy.

- `GRIFFIN_COMPACT_EARLY_RELEASE`: PASS, 4 checks, tick 123 / 2.05 s.
  Click at tick 120 with landing qualification false; real adapter absent,
  one release event, FLIP possessed and parking brake 1.0 by tick 123.
- `GRIFFIN_COMPACT_MANUAL_RELEASE`: the landed replay covers real retirement,
  settled joint topology, dynamic FLIP, a ten-second parking hold, deliberate
  forward input, ramp direction and marker alignment. See the adjacent JSON
  receipt for the final rerun's exact result. PASS, 9 checks, tick 2041 /
  34.0167 s, exit 0. Parked rollback 0.0036386 m; deliberate forward travel
  toward the actual ramp 0.425818 m. Lateral settling 0.066492 m stays inside
  the source-derived 0.075 m track clearance. This is not full descent.

Local logs and authoring journal: `runs/griffin-controlled-descent-2026-10-29/`.
The screenshot `retired-shafts.png` is a rendered assembly observation, not
physics evidence. No Sun, exposure or fill-light edit was made for this fix.

## Open dynamics boundary

The separate `griffin_tether_descent.usda` fixture is experimental. Its reduced
straight-line Modelica payout bench conserves reaction force and dissipates
stored energy, but the native 3D integration exceeds the assumed 2500 N line
limit. It has **not passed** controlled descent and is not installed in the
default Twin. Wheel wrapping, qualified tether properties and complete
upright ground transfer remain open. A completed trace is not descent PASS.
