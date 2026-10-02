# Griffin-1 Twin handover

**Latest update:** 2026-10-03 (older sections retain their original evidence scope)


## Latest landing-gear state

The canonical vehicle uses one inclined bus-to-foot prismatic joint per leg;
barrel and piston are visuals owned by the bus and foot respectively. The
previous V-brace hinge and independent shock bodies are removed. The three
visible members and their attachment datums follow the PGH hardware reference;
secondary brace compliance and the lumped 180 kg/leg mass are documented
approximations. See `requirements/griffin_landing_legs_requirements.sysml` and
the latest section of `requirements/griffin-size-evidence.md` for calculations.
The nominal joint anchor is the foot hub in the bus frame, not the leg root.

The geometry gate passes. Settled live samples show axial compression with
transverse error around 12 micrometres or less. Both 60 s landing runs remain
finite and upright, but four-pad contact briefly drops and fresh-process
trajectories differ, so stability and determinism gates remain FAIL. Same-app
contact replay and mounted topology refresh safety are also unresolved. Do not
merge the pending core changes to main as a deterministic-reload fix yet.

The route has five milestones and matching five completion events. Model
commit `9cd5a72` is pushed. Artificial landing/egress slabs remain until their
pad-dependent acceptance contracts are replaced with terrain observations.

## Model ownership

- `vehicles/griffin_1.usda` is the canonical integrated Griffin lander. It composes the lander, collision geometry, and replaceable component references.
- `vehicles/flip.usda` is the canonical integrated FLIP study vehicle. It composes the physical mobility model, chassis collision geometry, and reusable wheel, suspension, mast, and solar visual components.
- `scenes/griffin_flip_visual.usda` is the review composition; mission and verification scenes reference the same `griffin_1.usda` and `flip.usda` vehicle sources.
- The combined visual review has one manifest verification binding. Its SysML objective covers Griffin's visual requirements and FLIP's hosted-rover presentation requirement; the independent FLIP component verification owns the full rover contract.
- SysML under `requirements/` owns requirements, typed configuration identities, station datums, and study dimensions. Rhai builders make dry plans from those values and submit typed Editor edits. Composed USD is the realization to inspect. Rust provides shared modeling, authoring, physics, and verification capabilities.
- `scenarios/tests/` contains requirement observers. `tests/` contains their small USD fixtures; fixtures reference the integrated Griffin source.
- Twin-local reusable component assets live under `components/lander/` and `components/rover/`, including Griffin's body collision geometry and physical landing-leg module.

## Landing-leg connection

The four leg roots use the ordered `legStations` and radial rotations in `requirements/griffin_visual_configuration.sysml`. `GLL-009` in `requirements/griffin_landing_legs_requirements.sysml` requires each visible `BodyMountArm` to overlap the bus perimeter frame and mount axle, and requires a suspension joint at that same station. The arm dimensions are derived from the bus envelope, frame section, station, and clevis dimensions.

The Editor observation of the composed vehicle returned, for all four legs:

- body-mount overlap with `Bus/PerimeterFrame`: 0.114 m;
- overlap with `MountAxle`: 0.050 m;
- prismatic joint bodies: `/Griffin1` and the matching `/Griffin1/Leg*` root;
- historical joint anchor: the corresponding typed leg station (superseded by the current foot-hub anchor above).

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

Current authoring state:

- Every review, mission, and FLIP verification scene references `vehicles/griffin_1.usda` or `vehicles/flip.usda` directly.
- FLIP's storage capacity is projected from its source-owned energy and nominal-voltage requirements into the battery model's Ah interface. Its solar panel reads the live Sun vector through a local EnvironmentProbe and the FLIP system boundary; the source-owned peak rating sets the generic output limit. The Editor-applied inputs and direction wiring were read back from the composed vehicle.
- The review scene contains no detached sphere placeholders.
- The ramp visual component was rebuilt from the SysML plan at its 12.228605 m surface length and saved through the Editor. Its composed component has rails, support members, posts, tracks, and 12 pairs of treads.
- All Griffin requirement fixtures now reference `/Griffin1` from the integrated vehicle.
- Landing-leg readback returned `ok`, with visual-to-proxy pad geometry matching within 0.001 m and all four bus mount/joint observations available.
- The visual-review scene now shares the surface-operations scene's typed site/epoch and celestial-system reference. Its composed root and solar-system child were queried after projection, visually inspected, and saved.
- The solar configuration has three typed identities and stations on the forward, beveled forward-starboard, and starboard faces. The panel component uses paired local brackets and support links; each vehicle instance references that shared asset, uses its rail-derived width, and is checked at the configured station and orientation.
- The shared solar component now has a lower clearance opening in its frame, backplane, and cell field. Typed study fractions control its width, depth, and lateral position; dividers stop at the opening or split around it. Editor readback confirmed the cell opening is clear and the notched row divider is split. The values are visual-study assumptions guided by the photo, not approved dimensions; the render-only panel has no collision proxy.
- The three-array layout has been visually inspected in the open Editor. Its lower clearance shape is modeled qualitatively, but the released panel contour, installation dimensions, array envelope, and support datums remain replaceable study values pending controlled mission data.

These are Editor and composed-readback observations. They do not establish mission-level landing or egress acceptance. The Editor-loaded review scenario emitted a failing visual packet; the current counts and physics blockers are recorded in `contracts/implementation_gaps.md`. No headless test suite was started during this authoring pass.

## Next work

1. Run `requirement_quality_audit()` explicitly from the Griffin requirements tool and review its findings. Apply only justified requirement edits; startup remains policy-neutral.
2. Migrate remaining Griffin parameter maps to typed feature-path observations. GSA-005, GSA-006, and GSA-009 now author source-owned expected values and tolerances through standard constraint-usage feature bindings; `SysmlModel.required_constraint_irs()` exposes the effective dependency paths and `source_literal_observation()` supplies resolved source literals. No Editor/runtime execution was made for this update.
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
