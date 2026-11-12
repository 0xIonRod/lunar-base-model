# Body-fixed leg inspection cameras

The four `LegPXCamera`, `LegNXCamera`, `LegPZCamera` and `LegNZCamera` prims are
now direct children of the main Griffin rigid body. Their previous attachment
to individual spring bodies was inappropriate for body-mounted inspection.
The mounted-camera adapter retains pose ownership; no tracking or free camera
is substituted. Names remain available in the Camera menu.

The study mounts sit just outside the 2.25 m bus rim, at body height 2.05 m,
with a 0.65 m tangential offset. Each aims down and outward at its corresponding
leg/footpad, with the existing 14 mm wide lens, 3 cm near plane and f/8 aperture.
These are installable study locations, not published flight-camera coordinates.
No mass, collider, joint, propulsion or guidance state was changed.

Native document MovePrim/SetAttribute/SaveDocument operations authored the
change. A fresh native High-quality window rendered all four authored views
without a camera pose override. All four reported active mounted cameras and
clear readiness. A runtime motion check moved LegNX by 5 cm and then the body
by 50 cm: the NX camera retained its position during leg motion and followed
the body translation by exactly 50 cm. Temporary runtime transforms were restored.

The screenshots, camera audits, native log and motion receipt are under
`.cache/perf/plume-completion/leg-cameras-final/` in the simulator checkout.
The powered-descent landing-stability run remains a separate open issue: it
approached the ground, climbed away, and reached its 300 s horizon without a
qualified touchdown. It is not counted as passing camera or flight evidence.
