# FLIP controlled egress study — 13 November 2026

## References and scope

Astrolab's [FLIP Mission Overview, LEAG 2025, Fig. 2](https://www.hou.usra.edu/meetings/leag2025/pdf/5034.pdf)
describes fabric tethers and shows the steep, near-vertical dismount. The
[Venturi NASA Battery Workshop presentation, slide 25](https://www.nasa.gov/wp-content/uploads/2024/01/scalable-battery-pack-designed-for-lunar-terrain-vehicles-abw-2025.pdf)
shows the curved tracks and rear-wheel straps. Astrolab's
[public egress-test description](https://www.linkedin.com/in/adrian-lujan-180b48108)
explicitly describes straps wrapped around the rear wheels. Its
[May 2026 mission release](https://www.astrolab.space/2026/05/18/astrolab-announces-nasa-payloads-for-upcoming-mission-to-the-moon/)
describes direct egress without a deployable ramp.

These sources establish the concept, not flight rigging dimensions, allowable
loads, strap properties, actuator design or an operating procedure. This Twin
is an engineering study. In particular, the powered payout/take-up actuators
are explicit study assumptions; no public source establishes that FLIP has
these winches. Fabric/soil deformation, attachment strength, snagging, finite
wrap capacity, line failure and winch inertia are not modeled. The rigid wheel
and track dimensions remain the existing reconstruction.

## Ownership and sequence

USD owns the bodies, adapter, native wheels, track geometry, source assets and
parameters. `requirements/griffin_flip_egress.sysml` records study settings.
Modelica owns tension-only elasticity/damping, frictionless routing over the
convex exit, independent ideal payout/take-up, finite load-command response,
speed/pitch governors, energy and reaction wrenches. Production uses a reduced
balanced bridle around each rear wheel: its resultant passes through the axle
and wheel spin creates no shaft work. This is an explicit assumption because
the public references do not disclose end attachments or strand tensions. The
single-strand cylindrical-wrap mode remains an isolated study option; applying
its upper-strand couple throughout the final rear drop assisted that drop.
The shared `scenarios/griffin_tether_egress.rhai` behavior-tree task
owns sequencing and evaluates measured safety gates. Its normal mode waits for
DEPLOY FLIP; the test fixture explicitly enables verification mode.

1. Wait for qualified landed state, establish parking hold and inspect both
   mounted spans with the restraint disabled.
2. Take up balanced preload and dwell before requesting adapter release. The
   mission authenticates the controller and rechecks live loads before detach.
3. Confirm solver retirement, settle braked, release both actors' brake holds,
   and retire manual possession/neutral input holds before program drive.
4. Descend straight along the rails. Refresh actual wheel/lander kinematics and
   apply Modelica wheel wrenches plus opposite lander reactions. Bound line
   loads, imbalance, speed, attitude, travel, progress and elapsed time. A low
   line load is acceptable while both rear tires have measured support; an
   unsupported rear axle must retain both loaded lines. Hold unloaded front
   wheel spin to avoid dumping its angular momentum into chassis pitch when
   braking. Qualify front traction at the loaded toe before terrain touchdown;
   that handoff does not authorize final drive unlock.
5. Require stable four-wheel terrain contact, upright attitude, low speed and
   angular rate, and clearance beyond the track toe. Brake, unload both lines,
   dwell and announce **DISCONNECT TETHERS**. Production remains parked with
   restraint enabled until that explicit command. It rechecks ground support,
   clearance, both loads (at most 5 N) and stored energy (at most 0.05 J), then
   disables restraint and clears/releases its native wrench holds. The test
   fixture automatically requests this last step after the same gates pass.
6. The mission authenticates the release event and independently rechecks live
   ground/clearance and unloaded/cut telemetry. Only then restore operator
   control and announce drive unlock. Verification additionally commands and
   checks a forward manual-drive proof, then parks.

The inclined egress intentionally pitches close to vertical; the final upright
criterion applies at ground transfer. A separate rail attitude gate limits
sideways departure and over-center pitch. The Modelica pitch governor acts
before that hard limit; it does not enlarge the acceptance envelope.

## LunCoSim defects found

- Direct USD wiring from Modelica to body-root force/torque did not reach the
  native sink when the generated Modelica assembly claimed those root inputs.
  The shared controller uses the tested native-port command bridge. Its
  measured delay is about one to two fixed steps, so this is a sampled
  co-simulation study, not a qualified stiff-contact coupling.
- The compact release wrote `enabled=0` to a Rhai route program without that
  typed runtime port. Rejection stopped execution before adapter detach.
- Semantic brake releases are actor scoped. The mission must release its own
  hold; the observer cannot release it on the mission's behalf.
- Automatic manual possession after adapter release kept writing neutral
  controller inputs over the deployment program's throttle. The mission now
  explicitly hands authority to the egress program and returns it after the
  qualified restraint release. Operator takeover during deployment stops it.
- A direct straight line cut through the curved exit. The current reduced
  bridle routes over its convex profile. A one-sided, indefinitely wrapped
  strand also introduced a shaft couple which assisted the final rear drop;
  that configuration is excluded from the production balanced-sling assumption.
- The native tire axle solver could reject a finite rolling-contact torque
  balance when bisection reached adjacent representable angular speeds. The
  engine fix admits roundoff at that exact boundary using the physical traction
  torque scale, while retaining strict residual checks and rejection of a
  genuinely discontinuous contact law.
- Per-tick SysML reads dominated execution. The controller caches configuration
  at startup and retains the 60 Hz physics cadence.
- Chassis-heading projection reverses the native tire's traction direction as
  the chassis pitches through vertical. Collider-backed tires now derive the
  rolling tangent from the signed physical axle crossed with the contact
  normal. Tread speed includes housing rotation, while the motor/brake retains
  its relative shaft coordinate. The focused test crosses 90 degrees with both
  motor-coordinate signs and checks zero contact slip for exact rolling.
- A duplicate sampled preload relay qualified viscous tension before elastic
  preload settled. The sequence now uses Modelica's continuous take-up law,
  requires 90% of target preload through the dwell, and holds both spool
  coordinates during adapter/contact settling.
- A speed-magnitude winch governor pulled harder during upward rebound. The
  restraint target now follows outgoing material motion; the ideal actuator
  can relieve stored load on return. Front ground support changes the control
  role: front traction catches nose-down motion and the angular governor
  bounds uprighting rather than parking that axle during the catch.
- The normal HUD request can arrive on a lifecycle event route, where fixed
  simulation time is unavailable. Event handlers now latch requests and the
  behavior-tree step timestamps them.
- Tire contact on the dynamic lander is not terrain support. Native wheel
  `fixed_contact` telemetry distinguishes the two, and all four fixed supports
  are required before unload. Native per-wheel `brake` inputs are bounded
  0–1 and OR with the vehicle brake, so they cannot cancel a global hold.
- A delayed operator request exposed a one-sample wheel-down acceptance followed
  by immediate abort on unloading rebound. Unloading now holds all four brakes,
  stops payout and resets both continuous qualification dwells when support or
  stability flickers. Recovery is bounded by the authored ground dwell (120
  ticks); persistent instability stops the deployment with restraint retained.
  Load, unsupported-axle pretension, attitude and takeover gates still apply.
- `contact` also names Avian's touching-pair output. The new `loaded_contact`
  explicitly names the tire force owner's positive normal-load output;
  `fixed_contact` is its fixed-world subset. Neither safety nor unloaded-wheel
  braking depends on the ordering of duplicate port names.

The balanced-sling mode leaves rear wheels free to roll under the speed governor.
The single-strand study can retain rear brakes; normal stops hold all four.
The shallow-angle pose target is 750 N per line with a 1000 N governor ceiling,
inside the unchanged 2000 N operating gate. The 0.15 s loading and 0.05 s
unloading responses are explicit actuator assumptions. Pitch position inhibits
drive without disabling the independent vertical-payout channel. The pose hold
persists through a small pitch-rate reversal and retires only at measured front
terrain contact. Loaded outboard-track traction separately enables the forward
catch; it does not retire the pose restraint. Winch work is reported; winch electrics, inertia, fabric
deformation and finite inventory remain outside this model. Live ribbon meshes
follow the actual Modelica routing selection. The closed slings are authored
in each native rear wheel frame, so wheel motion does not wait for curve mesh
publication. They
preserve physical height and the lander-local frame, and disappear on disconnect.
They depict the reduced bridle geometry; they do not solve fabric deformation.
The old rest-pose strips are hidden to avoid displaying two conflicting paths.

Operator takeover or any failed gate retains restraint, requests all four wheel
brakes and stops transport. Actuator holds are attempted before stopping the
clock, and a rejected hold cannot prevent the transport/body pause fallback. The rover and lander also receive native coupled
object pauses. The independent sampled Modelica bridge is covered by the
transport stop; a Modelica Scope is not a rigid-body pause target. Reset the
scene before retrying.

## Validation

The final production binary passed the complete deterministic scene test
repeatedly, including a final 7/7 replay after the unloading requalification fix.
Local receipts are retained under `runs/griffin-controlled-egress-2026-11-14`
(generated evidence is not committed):
**7/7 checks, tick 8806, 146.77 simulated seconds**, 60 Hz, one thread, no jitter.
This is a coupled native-physics run, not just a Modelica compile.

| Measured acceptance | Final replay |
| --- | ---: |
| Maximum controlled-descent body speed | 0.13396 m/s (gate 0.35) |
| Maximum line tension | 790.09 N (gate 2000) |
| Maximum line imbalance | 363.35 N (gate 750) |
| Closest approach to vertical | 88.44 degrees from upright |
| Loaded fixed-world supports at finish | 4 of 4 wheels |
| Final line tensions | 0 N, 0 N |
| Final track clearance | 0.37424 m |
| Forward manual-drive proof | 0.10257 m |

The speed bound applies during controlled descent. The separate maximum over
all phases is 0.48952 m/s, including the subsequent free manual-drive proof.
The fixture also checks rejection of an invalid per-wheel brake and observes
loaded contact on the dynamic lander without accepting it as terrain support.
The local evidence folder includes the sampled trajectory and telemetry plot.

The normal desktop DEPLOY path also passed in the complete surface-operations
scene, including a delayed request at scene time **118.85 s**. Descent, four-wheel
transfer, line unloading and manual unlock completed at **239.53 s**. Peak descent
speed was **0.13295 m/s** and peak line load **801.79 N**. The
local desktop receipt
retains the live stable-ground/unloaded-line unlock event. Native manual throttle
then moved FLIP **1.17591 m**, and the native brake reduced speed to
**0.00581 m/s**. All verifier inputs were released and transport paused, leaving
manual possession available. Saved final velocity is 0.17085 m/s after brake
release; transport is paused, so this is not a claim of a stationary unbraked
rover on sloped terrain. Four loaded fixed-world supports remain present.
Both final positive runs recorded zero ground requalifications; the new bounded
hold path was not separately forced in those accepted runs.
No simulation fault occurred during this accepted deployment. The earlier
unloading-stop diagnostic is retained separately in the desktop history.

The operator-takeover negative test
passed: all four brake requests were 1, rover and lander were paused, the tick
remained 5998 over a one-second observation, and the physical pose stayed fixed.

Focused checks:

- Native mobility suite: **56/56**; per-wheel brake admission contract: **1/1**.
  Includes near-rolling axle balance at ordinary and tiny scales, discontinuity
  rejection, signed rolling tangent through vertical, and housing angular speed.
- Native force/torque sink: **4/4**. Sampled Modelica/native bridge: **6/6**,
  tick 14, 120 N and 30 N m pulse; delta vx 0.00906 m/s and delta omega y
  0.00275 rad/s.
- Compact adapter-only fixture: **9/9**, tick 1993. Adapter retired at tick 1333;
  drive stayed inhibited and the rover remained parked.
- OpenModelica contracts: **pass**, using `python3 tools/check_tether_model.py`.
  Covers slack/hold, independent payout, take-up limit, reduced energy balance,
  cylindrical rolling, force/torque power balance and convex guide selection.
- Shader-policy contract: **pass**, tick 27. Native USD lint policies compile.
- Full production build after the final native formatting: **pass**.

Reproduce from the engine checkout, with `TWIN` set to this Twin's absolute path:

```sh
target/debug/luncosim test --scene "$TWIN/tests/griffin_tether_descent.usda" \
  --max-ticks 19000 --tick-hz 60 --threads 1 --jitter 0 \
  --readiness-timeout 240 --api 4190
python3 "$TWIN/tools/check_tether_model.py"
```

The engine change is isolated in `fix/griffin-tether-axle` at `9a36186b3`, based on
`b90207f60`, at `/home/rod/Documents/luncosim-workspace/griffin-tether-axle`.
The evidence folder includes the native source patch and build receipt because
this Twin requires those native fixes; an older installed LunCoSim is not a
validated substitute. The engine feature branch and Twin main branch are the
publication targets authorized by the user.

## Visual corrections and operation

The bright orange panel backs were caused by launching the earlier physics
check with `--render-profile fast`. That profile sets standard materials to
`unlit`; the custom hardware shaders retain their own lighting. Use
`--render-profile standard --render-quality balanced` to inspect shading.
The physical solar probe and renderer Sun agree; the measured back-face dot
product was -0.0513. No Sun, emission or fill light was changed for this fix.

The three tank-support frame levels contained 192 same-facing coplanar face
intersections between distinct opening rings. Shared coverage was clipped from
the six Z-facing ring meshes through native document operations. Outer bounds,
materials, transforms, physics and the remaining frame coverage are preserved.
The native composed-geometry check now finds zero overlaps on all twelve rings:

```sh
python3 "$TWIN/tools/check_frame_coplanarity.py" --port 4189
```

`griffin_surface_ops::disconnect_tethers()` is the scripting equivalent of the
HUD command. It returns a rejection without cutting if the adapter is attached,
lines remain loaded, energy is stored or native ground transfer is unstable.
`DEPLOY FLIP` lowers and parks; `DISCONNECT TETHERS` completes the operator
handoff. Selecting FLIP during automatic descent is an operator takeover and
stops the sequence safely.

The interactive disconnect acceptance also exercised the explicit command:
rejection while attached, stable parked waiting with `enabled=1` and both loads
zero, an enabled HUD button, and clearing all four curves after the command.
Native manual input moved FLIP **0.10695 m**; braking reduced body speed to
**0.00289 m/s**. Readiness remained ready with no hold or fault, and runtime
diagnostics reported zero errors and warnings. The later wheel-local visual
refinement changes presentation ownership, not those physical gates.

The final Standard-rendered scene passed the wheel-local view check: both
64-point periodic slings composed inside their native wheel render roots, all
four curve views cleared successfully, and document generation and the paused
physical rover pose stayed unchanged. The final mounted frame audit passed on
all twelve meshes with zero coplanar overlaps. Runtime diagnostics were clean.
