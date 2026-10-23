# Griffin ramp deployment repair — 23 October 2026

The former equal-span mechanism reproduced a middle-hinge jam near 102.7°.
Its fixed transition stock also intersected the planned fold. The installed
vehicle now references the independently qualified unequal root, middle and
toe components. Their named datums own the raised root and opposite toe fold;
all revolute and flight-latch frames, section centres of mass and per-span
inertias follow those datums. Each bank retains its 95 kg mass proxy. The fixed
15 kg transition now carries two tire-aligned contact tracks with an open
centre. Its source inertia includes the tracks' transverse offsets.

Deployment releases and clears the still-folded roots outward to 90°, measures
settlement, unfolds the middles, opens the toes in the opposite direction,
then lowers the roots to measured terrain-fitted targets. Every waypoint and
the final sampled dwell retain the existing native angle/speed limits.
Motor gains, torque caps, solver, substeps and dependency pins are unchanged.
Event chronology uses emission simulation ticks, allowing a settled event and
the next command to share a tick while requiring each motion to settle later
than its own command.

The component-aware authoring tool replaces the retired equal-span writer.
The three static integration observers reuse the production composition and
compare every geometry member against its component, in bounded query groups.
They measure authored geometry independently of Editor tab focus. Dedicated
component cases remain responsible for detailed stock geometry; the new
post-landing case observes the real mission without commanding or overriding
poses. Its program has a separate owner from the production mission.

| Final production case | Checks | Result |
| --- | ---: | --- |
| Installed references, mass properties, hinge/latch frames and transition tracks | 30 | Pass |
| Flight stow, mirrored axes and rail/leg clearance | 22 | Pass |
| Nominal mitered toe geometry | 10 | Pass |
| Descent and measured complete deployment | 20 | Pass |

The final deployment verdict arrived at tick 3538 (58.97 simulation seconds),
after physical touchdown and settlement of both banks. Fresh CLI processes
used 60 Hz, eight substeps, one compute thread and zero jitter. A separate
headful High-quality run also reached RAMPS SETTLED with all six native hinge
angles and speeds captured. That run used MaxSpeed for observation, then was
restored to Realtime and paused. It is not a 60 FPS measurement.

The earlier geometry-equivalent candidate passed 737 continuous swept-envelope
checks: independent cross-bank separation was at least 1.16517 m and the
certified own-bank root/toe gap was at least 20.385 mm against a 20 mm study
margin. A deliberately overlapping stock witness was rejected. These geometry
certificates are distinct from the final loaded-motion verdict.

[Portable receipt](evidence/griffin-ramp-deployment-2026-10-23.json) records
source hashes, exact final verdicts, executable provenance and limitations.
[Headful deployed view](evidence/griffin-ramp-deployed-2026-10-23.png) shows the
saved vehicle after opening. The normal executable is the compatible
`eca1a3a9-dirty` tutorials artifact, not a clean latest-main build qualification.

This iteration accepts ramp opening, not rover traversal, structural hardware
or flight fidelity. Dimensions and mass properties remain explicit
reconstruction estimates. Solar obstruction was qualified and pushed separately
in `4f34f1b`; its visible spheres belong only to collision-test fixtures.
