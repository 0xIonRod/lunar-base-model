# Griffin blanket completion — 18 November 2026

Saved the eight bus blanket panels and two upper pressurant covers through
LunCoSim's typed USD document owner. The full Griffin Editor preview composes
the saved component assets. The fold pattern and allowances are photo-based
visual estimates owned by `GriffinPhotoWrapping::VisualStudy`.

The selected references and acceptance IDs GVREF-NOV08-01 through -03 are in
[the Voyager photo review](../research/griffin-voyager-photo-review-2026-11-08.md).
Broad folds and gathered ends replace the planar bus panels and smooth upper
capsules. Thirty-two bus tape patches follow the actual mesh triangles and
their normals. Four upper patches follow the cover's longitudinal profile.

## Regeneration

Use `griffin_exterior_blankets::face_plan` separately for indices 0 through 7.
Use `griffin_upper_visuals::cover_plan` separately for indices 0 and 1.
These plans target SourceAsset scope. Apply the separate
`griffin_upper_visuals::cover_material_plan` with InstanceOverride scope because
the local upper-cover material instance references the tank material network.
Inspect the returned generation and wait for matching ready projection after
each change. `patch_plan` refits existing bus patches independently.

## Verified scope

- Pass. All eight source-backed bus checks and both upper-cover checks.
- Pass. All ten meshes have finite coordinates, two oppositely oriented uses
  of every edge and positive enclosed volume. Each bus panel has 72 vertices
  and 140 triangles. Each upper cover has 90 vertices and 176 triangles.
- Pass. Added mesh and tape geometry has render purpose and disabled collision.
- Pass. Saved documents closed and the bus reopened as a clean generation-zero
  document. Composed readback includes the new upper cover with 90 vertices.
- Pass. The complete saved lander preview reached ready projection and composed
  text. Its bus blanket readback has the new 72-vertex mesh.
- Partial. Visual fidelity against the selected photographs. Hidden seams and
  exact blanket profiles remain reconstruction estimates.
- Not evaluated. Full assembly interference, dynamic clearance, physical
  blanket properties and mission simulation.

Intentional visual contacts are tape backs against their blanket surface,
blanket folds around perimeter frame rails and upper covers around their
existing bottle/retention envelopes. The enclosing mesh volumes above describe
render topology and do not supply material volume or mass properties.

Runtime was the existing native Vulkan LunCoSim source build, 0.6.0-dev,
in this task's headful session on port 4188. Local inspection evidence is in
the engine checkout's ignored `logs/` directory, including
`griffin-blankets-reopened-nov18.png` and `griffin-blankets-final-nov18.png`.
The independent geometry readback audit is
`output/blanket-geometry-audit-nov18.json` in this project.

Saved SHA256 values follow.

- `components/lander/griffin_bus_visual.usda` —
  `61EDB6434242E2D5A504CE5EC9B3B3FD532D385666B24E55054A91DDB86E6C97`
- `components/lander/griffin_upper_pressurant_visual.usda` —
  `673EEA31BF512CF8428005E82520CE92D76A657D1EE5194B54E0AD2EDF9688A5`
