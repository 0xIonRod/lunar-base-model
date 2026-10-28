# Raised presentation detail — 28 October 2026

This pass adds actual surface geometry to make the vehicles easier to read at
the wide framing used for social video. It follows the material-only pass and
keeps its finishes. The added forms are presentation study assumptions, not
supplier CAD or confirmed flight seam/hatch layouts.

Griffin receives eight vertical blanket seams and two eight-segment circumferential
bands on the existing tapered engine skirt. The seam tape is 35 mm wide and
9 mm deep, embedded 2 mm into the original surface. Its mount and taper come
from the eight outer faces of the source-owned finite-wall mesh. The June 2026
integration reference informs the silver-blanket assembly language; the regular
seam routing and dimensions are artistic assumptions.

FLIP receives 20 chassis details: raised upper/lower side rails, corner strips,
two divisions on each long side, front/rear edge rails, and layered service hatch
seals and covers. Eight moving solar-panel details add four 45 mm edge caps and
four dark corner protectors. The existing CAD points and extents determine all
mounts. The panel additions live below the moving SolarMechanism CAD reference,
so the existing hinge carries them through stow/deploy.

`GriffinPresentationStudy::GeometryDetail` owns the illustrative sizes and
fractions. `tools/social_geometry_detail.rhai` creates dry typed plans using the
existing generic shape planner and checks the resulting translations, sizes,
materials, render purpose and disabled collision values. Each detail has only
MaterialBindingAPI; the generic planner's disabled PhysicsCollisionAPI is removed.
No mass, rigid body, joint, physical material or active collider was added.

The vehicle and skirt diffs are additive relative to the saved material-pass
baseline: no pre-existing source line was removed or rewritten. The five imported
FLIP CAD visual layers remain unchanged. The skirt's three original finite-wall
meshes retain zero boundary edges, zero nonmanifold edges, consistent winding and
their original approximately 8 mm wall allowance.

## Review

- [Wide view before](../handover/social-geometry-wide-before-2026-10-28.png)
- [Wide view after](../handover/social-geometry-wide-after-2026-10-28.png)
- [FLIP close-up](../handover/flip-geometry-detail-2026-10-28.png)
- [Blanket seams close-up](../handover/griffin-blanket-seams-2026-10-28.png)

The wide comparison uses the same low-angle camera, neutral Editor lighting,
vehicle positions and capture region. Only the three new detail groups are hidden
for the before capture, then restored for the after capture. It approximates the
requested wide viewing scale; it does not reproduce the screenshot's mission
lighting, deployed ramps or live vehicle poses. It is visual evidence, not a final
moving-camera export.

`scenes/social_geometry_review.usda` is an **Editor inspection assembly**, with
both reusable vehicle references, not an operational mission. Open it in Editor
for inspection. It has no authored mission camera, terrain or observer. Its three
visibility overrides are restored to `inherited`; the reusable vehicle/component
files never received the comparison toggles.

## Verification

Fresh production tests passed:

- Griffin propulsion requirements: 104 checks, exit 0.
- FLIP CAD capabilities: 7 checks, exit 0; physical panel stow/deploy and finite
  power behavior remain intact.
- Detail-placement/readback checks: 24 blanket, 20 chassis, 8 moving-panel shapes.
- Existing skirt finite-wall measurements remain valid.
- Repository structural validation, Rhai/SysML syntax validation and diff
  whitespace checks passed.

The authoring session's automatic mission reload briefly faulted its terrain
visual-continuation owner while component files were saved. The disposable live
scene was cleared before the stable Editor captures; the final diagnostic and
readiness snapshots were clear. No simulator engine or operational mission source
was changed to work around it. Full mission hot-reload and video export remain
separate checks.

See [machine-readable receipt](evidence/social-geometry-2026-10-28.json).
