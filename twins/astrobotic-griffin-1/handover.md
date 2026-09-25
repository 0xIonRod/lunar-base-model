# Griffin-1 Twin handover

**Current as of:** 2026-09-25

## Model ownership

- `vehicles/griffin_1.usda` is the integrated Griffin realization. It composes the flight lander, named collision geometry, and replaceable visual components.
- `scenes/griffin_flip_visual.usda` is the review composition. Griffin and FLIP are referenced assets; FLIP is loaded in place and remains independently authored in `vehicles/flip.usda` and `vehicles/flip_visual.usda`.
- SysML under `requirements/` owns requirements, configuration identities, stations, and study dimensions. Rhai builders make dry plans from those typed values and submit typed Editor edits. Composed USD is the realization to inspect. Rust provides shared modeling, authoring, physics, and verification capabilities.
- `scenarios/tests/` contains requirement observers. `tests/` contains their small USD fixtures; fixtures reference the integrated Griffin source.
- Twin-local visual components live under `components/lander/` and `components/rover/`.

## Landing-leg connection

The four leg roots use the ordered `legStations` and radial rotations in `requirements/griffin_visual_configuration.sysml`. `GLL-009` in `requirements/griffin_landing_legs_requirements.sysml` requires each visible `BodyMountArm` to overlap the bus perimeter frame and mount axle, and requires a suspension joint at that same station. The arm dimensions are derived from the bus envelope, frame section, station, and clevis dimensions.

The Editor observation of the composed vehicle returned, for all four legs:

- body-mount overlap with `Bus/PerimeterFrame`: 0.114 m;
- overlap with `MountAxle`: 0.050 m;
- prismatic joint bodies: `/Griffin1` and the matching `/Griffin1/Leg*` root;
- joint anchor: the corresponding typed leg station.

The leg assembly therefore attaches to the bus structure. `Nozzle/MainEngineCluster/EngineSkirt` is a separate render-only engine surround and is not the leg interface. Astrobotic's public lander guide says the four landing legs are fastened to the bus and describes an internal truss tying the shear panels into the central column. The reference image supplied during review is captioned as an earlier Griffin concept, so it is useful for visual comparison but does not establish current flight geometry. Public sources: [Astrobotic Lunar Landers User Guide](https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf), [Space.com's image caption](https://www.space.com/space-exploration/spacex-falcon-heavy-launch-of-private-griffin-moon-lander-now-targeting-mid-2026).

## Current site-time and Editor state

The surface-operations scene owns the reproducible NOBILE03 study anchor and
TDB epoch. The combined visual-review scene now carries that same typed
`LunCoEpochAPI`, anchor, and referenced `SolarSystem`, so its Sun is resolved
from the selected scene time and site. The Editor plan read the values from the
composed surface-operations scene, then applied them in one generation-checked
typed operation batch. Composed readback confirmed latitude
`-84.72672255°`, longitude `29.14428685°` east, normalized height `0 m`, body
`301` (Moon), epoch `2461395.5` TDB, and the referenced Sun/Earth/Moon system.
The saved document is clean after the edit.

JD `2461395.5` is the repeatable study epoch on the 2026-12-21 TDB calendar
date. Public mission material currently gives a late-2026 launch window, not a
surface landing timestamp, so this is not flight-timeline data. The exact
landing site and mission-window Sun envelope remain unresolved.

Completed in the current authoring session:

- The review scene now references `vehicles/griffin_1.usda` and the linked FLIP visual asset.
- The review scene contains no detached sphere placeholders.
- The ramp visual component was rebuilt from the SysML plan at its 12.228605 m surface length and saved through the Editor. Its composed component has rails, support members, posts, tracks, and 12 pairs of treads.
- All Griffin requirement fixtures now reference `/Griffin1` from the integrated vehicle.
- Landing-leg readback returned `ok`, with visual-to-proxy pad geometry matching within 0.001 m and all four bus mount/joint observations available.
- The visual-review scene now shares the surface-operations scene's typed site/epoch and celestial-system reference. Its composed root and solar-system child were queried after projection, visually inspected, and saved.
- The solar configuration now has three typed identities and stations on the forward, beveled forward-starboard, and starboard faces. The panel component was rebuilt through typed Editor operations with paired local brackets and support links; each vehicle instance references that shared asset, uses its own rail-derived width, and was read back at the configured station and orientation. The old port-side proxy was removed.
- The shared solar component now has a lower clearance opening in its frame, backplane, and cell field. Typed study fractions control its width, depth, and lateral position; dividers stop at the opening or split around it. Editor readback confirmed the cell opening is clear and the notched row divider is split. The values are visual-study assumptions guided by the photo, not approved dimensions; the render-only panel has no collision proxy.
- The three-array layout has been visually inspected in the open Editor. Its lower clearance shape is modeled qualitatively, but the released panel contour, installation dimensions, array envelope, and support datums remain replaceable study values pending controlled mission data.

These are Editor and composed-readback observations. They do not establish mission-level landing or egress acceptance. No test suite was run during this authoring pass.

## Next work

1. Run `requirement_quality_audit()` explicitly from the Griffin requirements tool and review its findings. Apply only justified requirement edits; startup remains policy-neutral.
2. Migrate Griffin predicates with real source-owned actual arguments onto explicit constraint-usage feature values as those source features become available. The generic AST/IR now projects and applies supported bindings. The existing GSA-005, GSA-006, and GSA-009 scenario calls the grouped evaluator through the shared adapter, but this work session did not execute it.
3. Replace the solar-panel study fractions and other approximate panel datums with the controlled Griffin-1 panel definition when available; verify cutout clearance, installed transforms, support and hinge interfaces, and electrical behavior against that definition.
4. Compose the saved ramp visual component under the integrated port and starboard physical ramp roots. Preserve the physical track colliders, avoid duplicate visible geometry, and derive both poses from the ramp SysML configuration.
5. Review the leg-to-bus mount appearance in the Editor against current Griffin-1 references. Define any additional visual bracing as a source-backed study requirement derived from the bus and leg interfaces.
6. Use one dry Rhai plan, one generation-checked typed Editor batch, composed readback, and save for each geometry edit. Separate focused requirement observations from full Twin/runtime acceptance.

## Repository integration

The Twin checkout is already on `main`; inspect `git status`, ancestry, and the exact staged diff before each commit. The core `main` worktree already contains the current terrain merge and local render-defaults commit. Report local commits and remote pushes separately; do not push unless requested.

The current prioritized implementation gaps and standards review live in
[`contracts/implementation_gaps.md`](contracts/implementation_gaps.md). Keep
that review as the current status source; this handover records the Twin's
authored ownership and work sequence.
