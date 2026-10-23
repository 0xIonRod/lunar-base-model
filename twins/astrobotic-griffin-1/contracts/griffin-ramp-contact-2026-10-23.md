# Griffin landed ramp contact gate — 23 October 2026

The landed deployment task now requires actual toe/terrain proximity and
continuity between the fixed deck transitions and the root treads before it
announces readiness or permits automatic payload release. The existing twelve
hinge angle/rate checks and one-second sampled dwell remain mandatory. Any
failed contact or continuity sample resets that same dwell.

`tools/griffin_ramp_contact.rhai` reads native cooked convex-hull vertices,
recovers their cooking-local coordinates, checks those bounds against the
installed physics collider, and follows the live rigid-body poses. It checks
collider admission, body ownership, fixed local frames, active document identity,
document/stage generations and SysML revision. It never substitutes authored
stow positions or planned hinge angles for the observed geometry. The geometry
cache is captured after section unfolding; live probes run only during final
deployment settlement.

For each independent track, the lowest of the four distal miter vertices must
lie within the existing ±20 mm terrain-contact study allowance. The deck check
samples the centre and both sides of the source-owned 280 mm tire corridor
against the closest actual fixed-transition outer edge. Its new explicit SysML
runtime allowance derives from the same 20 mm study budget. The separate 2 mm
source assembly-fit tolerance is unchanged. These are reconstruction study
limits, without supplier qualification. A single lowest corner establishes this
geometric contact condition; the check does not claim full-width support force
or structural capacity.

The normal windowed scene completed descent and operator-commanded opening at
High quality. Fresh native observations measured toe minima from −0.39 to
−1.03 mm and deck-entry gaps from 1.83 to 2.22 mm. The saved screenshot shows
the deployed tracks, lander and attached payload. The owned API 4391 session was
left paused in real-time execution mode. This observation does not establish
60 FPS during running physics.

Three production replays exercise the gate without pose overrides:

| Case | Checks | Required result |
| --- | ---: | --- |
| Normal descent, ordered unfolding and waypoint presentation | 52 | Ready after geometric contact and hinge settlement |
| Toe contact stock shortened by 10% in X | 13 | Settled hinges; floating toe stock blocks readiness and release |
| Fixed transition contact stock lowered 50 mm | 13 | Settled hinges; deck discontinuity blocks readiness and release |

The fault scenes are native document forks of the production composition. They
retain both the vehicle and GNC references and run the normal mission. Their
observer issues no motion commands. It requires the specific final-deployment
rejection, valid native geometry evidence, all hinges settled, no readiness or
route-start event, and a still-present enabled payload attachment. Generic
startup errors and unrelated timeouts cannot pass these cases.

The rejection replays also exposed an oversized full-Twin SysML projection in
`fail_phase`. That report now requests only its two requirement identities and
one verification identity. Bounded traversal diagnostics preserve the actual
contact gaps and policy limits, and the failure event reaches the observer.

The [receipt](../handover/griffin-ramp-contact-2026-10-23.json) records the exact
binary, source hashes, fixed 60 Hz/one-thread/zero-jitter profile, structured
verdicts and native observations. The [windowed screenshot](../handover/griffin-ramp-contact-2026-10-23.png)
records visual inspection. SysML validation has zero errors and retains its
153 existing warnings. The earlier [199-check fidelity review](griffin-fidelity-review-2026-10-23.md)
remains scoped to its recorded revision. Complete loaded rover traversal,
flight-dimensional qualification and clean 60 FPS real-time acceptance remain
open. Airborne manual opening remains a pose-only operation, and forced manual
payload detachment retains its independent operator command.
