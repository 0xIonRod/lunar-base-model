# Griffin landed ramp contact checkpoint

The authorized optimization Cargo cache clean removed 32.1 GiB without source
changes. The terrain default build now succeeds; core `24dd835fa` is the
current owned runtime, not the removed optimization binary.

Core `5079c4b58` preserves USD-authored joint motor models and limits during
position commands. Core `24dd835fa` maps native unbounded limit sentinels to
absent port bounds. Both boundary unit tests passed. Production revolute and
prismatic fixtures passed respectively 6 and 5 checks over 600 ticks. These
are component checks, not Griffin or rendered acceptance.

The current core / Twin `fec3026` replay terminated FAIL at tick 19196 in
`ramp-root-deployment-settle`. Touchdown was tick 17102; middle and toe stages
settled at 17277 and 17397. Thrust reached zero. At final root settlement,
port/starboard toe rates were −0.0593704 / −0.0358057 rad/s, above the retained
0.02 rad/s limit; release correctly remained blocked. Logs and native decoded
evidence are `/tmp/griffin-preserved-drive-replay.log` and
`/tmp/griffin-preserved-drive-evidence.json`.

The recorded lander tilt and toe corners agree with different elevations in
the retained DEM outside the 12 m pad. Fixed nominal targets therefore cannot
be treated as general terrain-contact targets. See the explicit geometry,
assumption and source notes in `griffin-size-evidence.md` and the SysML ramp
requirement comments. The new Rhai planner reads landed root frames and the
existing track/miter datums, solves each target within its source travel, and
records eight terrain clearances per ramp. It reserves half the source 20 mm
contact tolerance as a study allowance. It retains all angle/rate/dwell gates.

The generic GroundHeight query returned origin-distance-zero anonymous hits
for these probes; those results were not used as surface heights. Retained
TerrainHeight samples were used instead, with the authored pad footprint/top.
This does not resolve the generic raycast diagnostic or prove all contact
colliders match the DEM.

The fresh terrain-derived replay passed middle/toe deployment and the final
all-six-hinge dwell gate, then released FLIP. Planned port/starboard targets
were −0.4312765551 / +0.4273772443 rad. At tick 16704 all six instantaneous
rates were below 0.007 rad/s. This is current component/phase evidence, not
full mission acceptance. Log: `/tmp/griffin-landed-ramp-replay.log`.

The replay ended NO-VERDICT exit2 at 20000 ticks because route diagnostics
read WheelRaycast tire forces without declaring the four wheel entities as
read dependencies. The declaration is now corrected without changing the
physics or acceptance policy. A fresh replay follows. Egress, repeatable
landing, and owned rendered acceptance remain open.

## Second replay: usable route failure

The dependency-corrected `985b084` replay ended FAIL exit1 at tick 12762 with
`GR-004-route-stall`. It passed touchdown, ordered section unfolding, root
settlement and FLIP release again. No missing wheel read dependency blocked
this run. Log `/tmp/griffin-landed-ramp-replay-2.log`; decoded native packet
`/tmp/griffin-landed-ramp-evidence-2.json`.

The rover stalled at (0.518135,2.665903,-1.208461) m before its scene-fixed
(2,0,0) m approach target. The native forward vector was approximately
(0.031,-0.277,-0.960), guidance heading error 2.222700 rad, steer1 and throttle0.
This is an inconsistent frame, not evidence that stronger torque is needed:
`flip_wheel_requirements.sysml` specifies an X-forward reconstruction with Z
axles, while `VehicleFrame::FORWARD_LOCAL`, `wheel_heading`, and the shared
`RoverAutopilotGuidance` use −Z forward. `WheelParams` reads the authored axle
axis, but `WheelRaycast` does not retain that axis for its traction basis.
Thus both navigation and tire-force direction need a consistent authored
frame. Do not mask this with a throttle exception or extra visual wheels.
The first two route datums are also fixed scene markers, so their relation to
the actual landed ramp centerline must be reconsidered once the physical
frame is consistent. No correction to those mechanisms is claimed here.

## Egress correction checkpoint

Core commits `abdcbf909` and `4fd526f35` derive wheel travel from authored
axle/steering axes, add the generic drivetrain heading offset, and align HUD
manifest namespaces. Two focused wheel-basis unit tests and the production
build passed. An owned screenshot showed the restored panel after manifest
reload; `/tmp/griffin-hud-panel-fixed.png`. The flat review foot collider has
center Y=0.01999994, height 0.04, so its bottom lies at the flat datum.

Replay-2 reached x=13.17 m before a stall at tick 28045. Native evidence
`/tmp/griffin-egress-frame-evidence.json` showed FL ray origin below the apron
and no hit. The 0.30 m extension was incorrectly used as total ray length;
SysML now defines radius + extension = 0.75 m, preserving spring stiffness,
wheel size and torque. Replay-3 `/tmp/griffin-egress-frame-replay-3.log` passed
ordered ramp settlement, release and `griffin_ramp_exit_reached_confirmed`.
It crossed the exit with four supported wheels and continued through survey
transit gates, then failed a later survey route stall at tick 20293. This is
egress phase evidence, not complete mission acceptance.

Owned fresh-load keyboard ReadPorts showed Space throttle1, W pitch-1,
A roll1, Q yaw1 and piloted1. F now reaches the existing safe-release gate;
the unsigned target-ID comparison was removed because the emitter-scoped
subscription already establishes identity. U exposed an event-trace bug:
`sim_tick()` cannot run in lifecycle key events. Trace now preserves the
native event's `evt.sim_tick` rather than querying the simulation clock.
A fresh operator reload is required to validate that final correction.

Final fresh-load operator check (`/tmp/griffin-operator-final-validation.log`):
U emitted `griffin_ramp_unfold_requested`, accepted post-touchdown; F reached
the release gate and correctly warned that ramps must settle first. No
on_event failure occurred. The revised visual builder compiled through the
production RegisterToolLibrary command with no diagnostics. Review checks
now require the flat ground to be visible and retain shader/light provenance;
they no longer require the deliberately disabled DEM to be spawned.
