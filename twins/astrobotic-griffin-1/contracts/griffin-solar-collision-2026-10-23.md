# Griffin solar-panel collision

The three panel components now carry **59 hidden stock colliders**: 25 on the
forward panel and 17 on each chamfer panel. Their frame and backplane meshes
previously had collision explicitly disabled. Each new analytic Cube matches
one connected closed stock member of the actual composed visual mesh. Native
cooked corners are checked in the same document/stage snapshot within the
source-owned 2 micrometre observation allowance. A whole-panel convex hull is
not used because it would fill the leg opening and equipment recesses.

These are child colliders of Griffin's existing body. They introduce no rigid
body or mass declaration into the component or vehicle. Existing authored
mass, centre of mass and inertia remain unchanged. The stocks retain their
documented reconstruction status; contact does not qualify panel strength,
laminate properties or collision damage.

The production `Verify_GriffinSolarCollision` case passes **15 checks**: native
moving probes are stopped on both sides of all three panel surfaces, and
three further probes pass through the intended openings. The deliberate
disabled-surface fixture fails exactly the two opposing-face obstruction
checks, with signed centre gaps of -0.441667 m. The fixture attaches the panels
to stationary kinematic carrier bodies, matching the compound-collider
ownership used by the lander. The small spheres are test probes, confined to
these test fixtures; they are not added to Griffin's components or vehicle.

The existing solar geometry case passes **170 checks**. Its observer now
requests only its 30 source attributes, ten requirements and one verification
case, and omits mesh arrays from its bounds-only query. The former whole-Twin
source request exceeded the shared interpreter string bound. No interpreter
limit or acceptance criterion was relaxed. Provenance still covers all 229
requirement usages and their 229 evidence records.

Run the mapped `GriffinSolarRequirements::Verify_GriffinSolarCollision` case
with channel `GRIFFIN_SOLAR_COLLISION`, 60 Hz, eight standard substeps,
`--max-ticks 300 --threads 1 --jitter 0`. Run the negative directly from
`tests/griffin_solar_collision_disabled.usda` without the positive verification
selector. The [receipt](evidence/griffin-solar-collision-2026-10-23.json)
records the executable, exact source hashes and verdicts. The normal executable
is `eca1a3a9-dirty`, launched from the USD worktree; this is not clean
latest-main qualification. Full local logs are under
`usd/.cache/codex-evidence/griffin-ramp-solar-repair-20261023/`.

An earlier unattached-static fixture did not reject its disabled collider and
therefore provides no accepted contact evidence. Its exact snapshot and native
physics observations are handed off locally in the optimization worktree's
`docs/reviews/griffin-physics-handoff-2026-10-22.md`. No solver or dependency
change was made here. Complete landed rover interaction, ramp deployment and
the mission's 60 FPS acceptance remain separate runtime gates.
