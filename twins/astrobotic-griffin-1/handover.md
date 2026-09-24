# Griffin-1 Twin handover

**Current as of:** 2026-09-24

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

## Current Editor state

The prior headful Editor endpoint at `http://127.0.0.1:43117` was not running
or reachable during the 2026-09-24 requirements review, and no Editor surface
was available to this session. Do not assume its earlier document IDs or
generations are still valid. Reopen the Griffin Editor scene and query current
documents/generations before the next geometry edit. This review changed
SysML requirements, reports, and Rhai verification/tool policy only; it did
not author or save geometry.

Completed in the current authoring session:

- The review scene now references `vehicles/griffin_1.usda` and the linked FLIP visual asset.
- The review scene contains no detached sphere placeholders.
- The ramp visual component was rebuilt from the SysML plan at its 12.228605 m surface length and saved through the Editor. Its composed component has rails, support members, posts, tracks, and 12 pairs of treads.
- All Griffin requirement fixtures now reference `/Griffin1` from the integrated vehicle.
- Landing-leg readback returned `ok`, with visual-to-proxy pad geometry matching within 0.001 m and all four bus mount/joint observations available.

These are Editor and composed-readback observations. They do not establish mission-level landing or egress acceptance. No test suite was run during this authoring pass.

## Next work

1. Rebuild the nonconforming solar-array proxy as three upright panel assemblies across adjacent lander sides, with visible structural support members and the lower clearance-shaped outlines shown in current Astrobotic integration imagery. Use explicitly replaceable photo-derived visual dimensions for this presentation study, and keep exact stations, panel contours, mounts, hinges, and power behavior marked unknown until the controlled mission package is available. Apply through the Editor, then read back all three composed assemblies and support paths.
2. Compose the saved ramp visual component under the integrated port and starboard physical ramp roots. Preserve the physical track colliders, avoid duplicate visible geometry, and derive both poses from the ramp SysML configuration.
3. Review the leg-to-bus mount appearance in the Editor against current Griffin-1 references. Define any additional visual bracing as a source-backed study requirement derived from the bus and leg interfaces.
4. Continue checking the complete Griffin source against the functional, visual, mechanical, power, propulsion, and simulation-accuracy requirements. Record unresolved implementation limits in the owning requirement or gap report, not in duplicated scene metadata.
5. Use one dry Rhai plan, one generation-checked typed Editor batch, composed readback, and save for each geometry edit. Separate focused requirement observations from full Twin/runtime acceptance.

## Repository integration

The Twin checkout is already on `main`; inspect `git status`, ancestry, and the exact staged diff before each commit. The core `main` worktree already contains the current terrain merge and local render-defaults commit. Report local commits and remote pushes separately; do not push unless requested.
