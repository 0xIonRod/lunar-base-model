# FLIP model handoff to Rod — 2026-10-05

## Delivered package

Entry point: `twin.toml` -> `FLIP_simulation.usda`.
Register this directory as Twin `flip_rover_v5` in LunCoSim. The scene depends
on bundled `lunco://vessels/rovers/skid_rover.usda` and
`lunco://scenes/base/lunar_surface.usda`; those are engine-owned assets.

The package includes the saved simulation FreeCAD file, main scene, eight test
fixtures, five CAD visual layers, panel Modelica controller, Rhai acceptance
scripts, physics requirements and mechanism/test documentation. Existing tracked
visual CAD/USDC history is retained unchanged by this delivery commit.

CAD geometry remains visual-only. Hidden rigid-body proxies own collisions,
mass, inertia and joints. Wheel visual meshes retain their topology; wheel
collision cylinders are intentionally simpler than the visible wheel lattice.
The panel is a physical joint-driven body, not mesh-only animation. Study values
are not flight-qualified mass properties, friction or actuator specifications.

`simulation_meshes.json` is deliberately included as the frozen CAD tessellation
baseline needed by the read-only `verify_visuals.py` audit. It is evidence, not
a runtime dependency or a claim that the excluded rebuild helpers are qualified.

## Verification and evidence boundaries

Fresh checks on 2026-10-05:

- OpenUSD writer round trips: 37 passed; Windows asset-path tests: 6 passed.
  These fixes reside in separate local engine/dependency repositories.
- Pixar Sdf opened the main and all eight test layers (9/9).
- Visual audit: all 195 components and 761,656 triangles preserved; maximum
  coordinate error 5.913e-8 m; visual text layers total 43,307,009 bytes.

Native physics results are prior 2026-10-01 runs, not a fresh runtime run today:
panel cycle, repeat and obstacle fixtures passed; missing-drive, missing-joint,
blocked-panel, wrong-mass and visible-proxy fixtures failed as expected. Eight
expected outcomes matched. Selected `test-export-fix-*.log` files accompany this
delivery as dated raw evidence; they may contain original local paths.

Limitations: live editor reload can duplicate projected wheel identities.
Use a fresh process for the evidenced acceptance workflow; this does not fix
hot reload. The local LunCoSim dependency override points to `../openusd` and is
not portable. The serializer fix must be published and pinned separately before
claiming a reproducible engine integration. Neither engine fix is pushed here.

## Scratch files excluded, not deleted

- `FLIP_rover_v5.usda`: large intermediate text conversion.
- `FLIP_rover_v5_optimized.obj` and `FLIP_rover_v5_optimized.usda`: superseded
  decimated exports, not the preserved-wheel delivery.
- `FLIP_rover_v5_physics.FCStd`: intermediate CAD study.
- `*.FCBak` and sibling `flip_rover_v5-export-backup-before-writer-fix/`: backups.
- `FLIP_*.png` runtime captures and other `test-*.log` files: superseded local
  inspection/debug evidence; only the eight selected export-fix logs are shipped.
- The working-tree modification to original `FLIP_rover_v5.FCStd` is excluded:
  its ownership is uncertain. The delivery uses `FLIP_rover_v5_simulation.FCStd`.
- Unrelated Griffin Twin deletions and other worktree changes are excluded.

## Blocked helpers excluded, not deleted

| Helper | Reason / next gate |
| --- | --- |
| `author_simulation.py` | Transform rewriting can replace existing xformOpOrder; save polling checks existence rather than completion. Preserve ordered transforms and test deferred saves before shipping. |
| `author_panel.py` | Part of the unqualified authoring chain; review against corrected document/save semantics before delivering a supported rebuild workflow. |
| `repair_usd_exports.py` | Migration-only camera-edit workaround to force reserialization. Fix belongs in generic OpenUSD TextWriter, not a permanent Twin repair script. |
| `obj_to_usda.py`, `export_flip_mesh.py` | Superseded direct-writing/decimating path; unsuitable for canonical typed-document authoring and preserved wheel geometry. |
| `prepare_simulation_cad.py`, `add_physics_requirements.py`, `read_panel_parameters.py`, `update_panel_cad_parameters.py` | CAD preparation chain not qualified as an end-to-end rebuild. Initial preparation contains pre-panel mass assumptions; reconcile with the final 343 kg chassis / 15 kg panel / 450 kg total contract. |
| `test_solar_panel_cad.py`, `test_solar_panel_sim.py`, `verify_live_physics.py` | Local runner workflows not qualified for portable invocation; saved test fixtures and dated results are delivered instead. |

These files remain locally recoverable. Exclusion is not a claim that every
helper is defective: it marks the boundary between reviewed saved artifacts and
an authoring/runner workflow still requiring qualification.
