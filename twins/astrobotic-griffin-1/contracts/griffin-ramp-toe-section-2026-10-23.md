# Lower-axis toe section reconstruction

The [native interference and unequal-fold study](griffin-ramp-interference-2026-10-22.md)
selects the final toe span by subtracting the 2.149084054 m root and
1.449084054 m middle from the retained 5.397252161 m ramp span. The result is
1.799084053 m. Its entry axis shares the middle exit at Y=-0.08 m. The eventual
assembly must unfold this toe physically clockwise from -180 to 0 degrees;
that is the opposite sweep to the upper middle fold. Neither the detached
component nor its named frames qualify that installed motion.

Astrobotic's [Griffin page](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/),
accessed 2026-10-23, confirms optional rover ramps and a payload adapter. The
supplied cleanroom photograph guides the inward-folded open lattice. These
sources provide no released hinge ICD or dimensioned drawing. The selected
lengths, offset, stock and surface finishes remain reconstruction assumptions,
not flight CAD or structural qualification.

The toe owns its paired mitered walking tracks, full-height lattice guides,
brace/post stock, source-count treads, underside beams, silver/dark PBR finishes
and entry hardware. The entry tongue and pins attach to lower-chord stock;
the ground end has no fork cheeks or heel web. Its standard Xform frames are
MiddleFold at (0,-0.08,0) and GroundToe at (length,walkingTop,0), SI metres,
Y-up, +X from hinge to terrain. The shared native bevel relation derives the
track tip from walking thickness and the existing nominal deployment angle.

GriffinRampToeSectionRequirements owns GTS-001 and its separate verification
case. The shared geometry observer checks native physical span, mitered track
vertices, lattice stations, datums, connected entry hardware, material/collision
roles and absence of a free-end fork. A shortened-instance fixture must fail
physical acceptance while keeping its local mesh coordinates unchanged.
The assembly retains body, mass/inertia, installation, joint, latch and command
ownership. Both ramp banks, detailed mating/sweep clearances, terrain-fitted
egress and clean real-time 60 FPS acceptance remain separate gates.

## Saved component and packaging checkpoint

The saved toe passes 131 production checks, the revised middle passes 119,
and the unchanged root passes 119. The toe's shortened physical instance
passes 130 checks and fails its single metric-span constraint, exiting 1 as
required. Five native Twin-scoped USD preflights finish with zero errors or
warnings. SysML revision `18059387422882714778` has zero errors and 153 existing
warnings; provenance covers 225 requirements, 225 evidence records and 74
sources. The [receipt](evidence/griffin-ramp-toe-and-packaging-2026-10-23.json)
pins the assets, observers, source revision and binary SHA.

This uses the qualified production executable built at engine `0cb4d3713`.
USD was subsequently fast-forwarded to `2a4ec5db0`; that source synchronization
does not make this executable a build of the two newer engine commits.

The separate [packaging study](griffin-ramp-packaging-study-2026-10-23.md)
now assembles both banks from these component references. It supplies stronger
payload-clearance evidence while leaving the installed vehicle unchanged.
