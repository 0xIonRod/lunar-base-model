# Compact FLIP egress reconstruction — 28 October 2026

## Evidence and correction

Astrolab's [LEAG October 2025 FLIP Mission Overview](https://www.hou.usra.edu/meetings/leag2025/pdf/5034.pdf)
describes fabric-tether descent down Griffin's steep ramps. Its Figure 1 is the
same compact-track rendering supplied by the user. Figure 2 shows hardware
egress testing. Venturi's [21 January 2026 NASA workshop presentation, slide 25](https://www.nasa.gov/wp-content/uploads/2024/01/scalable-battery-pack-designed-for-lunar-terrain-vehicles-abw-2025.pdf)
shows the test vehicle on steep tracks with curved transitions. These sources
establish the architecture, not flight dimensions, stiffness, payout or strength.

The former two-bank, twelve-hinge installation was a legacy reconstruction.
Forty-four of its bodies, joints, latches, transitions and supports are now
inactive in the vehicle. Their component files remain for historical fixtures.
The current vehicle instead references
`components/lander/griffin_flip_egress_visual.usda`.

## Installed component

SysML owns the replacement study dimensions in `griffin_flip_egress.sysml`.
Two 0.48 m-wide tracks follow seven stations, with flat approaches, curved
piecewise transitions and steep lips. Their centers match the existing mounted
CAD wheel tracks at +/-1 m. The lip reaches 2.84 m outboard, beyond the 2.25 m
bus half-width. Its local height is 0.63 m, leaving a transfer to the surface;
the tracks do not form a shallow continuous roadway to the ground.

The component's 180-degree installed yaw selects lander +X, retaining the
existing mission payload yaw and adapter frames. The separate static review
now uses the same relative payload heading. No mission payload pose, mass,
inertia or gearbox rating was altered. The subsequent manual-release correction
selects an explicit open-circuit idle mode in the shared motor model.

The render surface is a closed rectangular sweep. Twelve independent box
proxies follow the two profiles; a whole-profile convex hull would incorrectly
fill the undercut. The proxies attach to the existing lander body. No separate
rigid ramp bodies or folding actuators are introduced. Existing walking-plate
and structural material networks are referenced; no new visual shader or
mission light is added.

Two fabric strips and deck anchor blocks illustrate mounted rest routing near
the rear wheels. They are non-colliding render geometry, not simulated cables.
The existing lander mass owner includes the fixed geometry as a study boundary;
individual hardware masses and structural qualification remain open.

USD authoring used the native document owner and typed plans in
`tools/griffin_compact_egress.rhai`, with per-track readback and explicit saves.
The built-in preview inspected the component and assembly separately.

## Operational boundary

The real descent/GNC, measured island-mass admission and touchdown gates still
run. The compact branch does not execute the former twelve-hinge sequence,
automatically detach the payload or command the old drive-off route. F and the
DETACH ROVER HUD action explicitly retire the physical adapter and leave route
guidance disabled. Manual release and open-circuit idle are covered by the
[subsequent release receipt](griffin-ramp-release-2026-10-28.md).

Tether payout, rear-wheel wrapping/unwrapping, contact transfer, restraint loads,
release at the surface and complete egress remain unqualified. Rest routing
and a rendered frame do not qualify those dynamics. Do not animate a free drop
or claim controlled descent from this revision.

## Checks

Both track readbacks pass seven source stations and six active contact proxies.
The focused runtime test checks measured landing, compact assembly presence,
adapter retention, absence of the legacy mechanism, twelve contact proxies and
settled native topology. Its five grouped checks qualify landing and hold only.
The first event-based observer returned NO-VERDICT despite the hold event;
the repaired observer samples the authoritative landing port instead.

```sh
luncosim test --scene twins/astrobotic-griffin-1/tests/griffin_compact_egress.usda --verdict-channel GRIFFIN_COMPACT_EGRESS --max-ticks 2500 --threads 0
```

Source validation and repository checks are recorded with exact runtime results
in `contracts/evidence/griffin-compact-egress-2026-10-28.json`. Local journals,
source PDFs, screenshots and run logs are in
`runs/griffin-compact-egress-2026-10-28/`.
