# Ramp shading and manual release — 28 October 2026

The compact ramp now has authored normals: smooth across the bent profile,
with hard sheet edges. Its twelve contact boxes are explicitly invisible to
rendering, while retaining PhysicsCollisionAPI and collisionEnabled=true.
Previously their overlapping render geometry produced bright bands on the skin.
Existing materials, shaders, Sun and exposure are unchanged.

F / DETACH ROVER now reaches the actual adapter release path. The compact
mission observes removal at the solver boundary and keeps automatic route
guidance disabled. The production handoff now acquires rover control and
releases the parking brake. The regression performs no separate brake fix: it
observes the actual handoff, then applies the forward semantic input.
The previous compact hold intentionally blocked this action; that block is gone.

Live release also exposed zero-command short-circuit braking in DCMotor. The
shared model now offers an opt-in `coast_at_zero` parameter. At exactly zero
demand the selected open H-bridge carries back-EMF with zero winding current,
torque and heat. Nonzero demand and the default legacy behavior are preserved.
FLIP's four motors select this mode through USD, from the SysML study choice.
No gearbox rating, overload assertion, mass, inertia or body pose was weakened.

## Deployment dependency

Deploy the updated `assets/models/LunCo/Electrical/DCMotor.mo` from LunCoSim
with this Twin. The portable [shared-model patch](../handover/dcmotor-idle-coast.patch)
records the exact asset change, made in the sibling engine checkout. Restart
the simulator after deploying the asset; rebuilding Rust alone is insufficient.
The patch is a deployment artifact, not a second Modelica equation owner.

## Evidence

- `griffin_compact_manual_release.usda`: PASS, exit 0, six checks, seed
  6840157149251759617, 60 Hz, default threads. HUD request tick 1383; actual
  adapter removal tick 1385; verdict tick 1565 / 26.0833 s. One release event,
  thirteen joints and graph edges, no pending detach, live dynamic rover,
  brake and autopilot zero after the production handoff. One second of forward
  input advances FLIP 0.63028 m along its initial forward direction. Possession
  is verified, and no gearbox fault occurs.
- `FlipIdleMotorContract.mo`: native experiment completed, eleven samples from
  0 to 0.1 s. Assertions check coast, legacy braking, powered drive and all
  three power balances. Coasting torque/heat/power are zero; legacy torque
  is -0.9 N.m and powered torque +0.9 N.m at the selected bench conditions.
- Native readback confirms twelve invisible, enabled contact proxies and
  six render meshes with 104 unit normals each. The actual rendered review
  is ready with zero runtime errors or warnings. See
  [review frame](../handover/griffin-ramp-shading-2026-10-28.png).
- Repository structure validation and `git diff --check` pass.

The earlier release attempts reproduced the gearbox assertion with and without
a temporary brake override. A subsequent run passed the physics window but
failed its brake-zero assertion because it had not released the parked brake;
the earlier observer exercised that operator action explicitly. The follow-up
fix moved brake release into the production handoff, acquired rover possession,
and replaced the helper-only check with measured forward travel. An initial
motion-test attempt rejected a targetless semantic input; its apparent pass
was discarded. The corrected run specifies the required input target, checks
signed travel and has no hook errors.
Local command journals, readbacks, motor samples and complete logs are under
`runs/griffin-ramp-shading-release-2026-10-28/`.

This qualifies explicit detachment, two seconds of post-release idle physics
and one second of commanded forward movement.
Tether payout, controlled descent, powered ramp traversal and complete egress
remain unqualified; the rendered tether strips provide no physical restraint.
