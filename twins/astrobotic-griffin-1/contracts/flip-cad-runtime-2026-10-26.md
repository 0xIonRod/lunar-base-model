# CAD FLIP runtime acceptance — 2026-10-26

The active Griffin surface-operations and visual scenes use `vehicles/flip_v5.usda`.
Its CAD meshes and source mechanical topology are preserved. The vehicle selects
the shipped physical drivetrain and finite battery variants, references the
existing FLIP thermal subassembly, and mounts a photovoltaic electrical component
and environment probe on the moving panel body. The component's generic panel
meshes and duplicate equipment mass facets are disabled.

The battery's 28 V bus and the 0.7 m², 35% panel efficiency are inherited study
assumptions. The 222.14285 Ah allocation at that voltage represents Astrolab's
published 6.22 kWh energy; the panel's rounded 270 W rating also follows its
public post. This is simulator integration evidence, not supplier-calibrated
power, mobility or thermal performance. See `flip-public-power-2026-10-27.md`.

## Production evidence

| Gate | Result | Evidence |
|---|---|---|
| Operator route, HUD, manual takeover and drivetrain/tire thermal paths | PASS at tick 1583, 26.38 s on the rebuilt simulator | `runs/flip-update-2026-10-23/cad-route-final-26/` |
| Native wheel forward/reverse motion, four CAD render roots and both stops | PASS at tick 845, 14.08 s | `runs/flip-update-2026-10-23/cad-motion-26b/verdict.json` |
| Native panel stow/deploy, moving-panel solar generation and finite EPS | PASS at tick 1561, 26.02 s; seven assertions | `runs/flip-update-2026-10-23/cad-eps-panel-26/` |
| Native W/S/A/D/Space press/release | PASS; 110 assertions | `runs/flip-cad-fixes-2026-10-26/manual-check.json` |
| Three windowed scene restarts | PASS; 12 wheel assertions each; ready and no runtime fault | `runs/flip-cad-fixes-2026-10-26/window-acceptance.json` |
| Avatar native E/W/D movement | PASS; positions reported in `active_physics`; E moves along terrain Y | `runs/flip-cad-fixes-2026-10-26/avatar-movement.json` |
| Griffin deck seating, adapter frames, panel hinge and four drive stations | PASS; eight assertions; vertical adapter error 1.264e-7 m | `runs/flip-cad-fixes-2026-10-26/mount-check.json` |

Forward travel was 3.6835 m; reverse travel was 2.7790 m. Braking reduced
2.1144 m/s to 0.00691 m/s and 1.5999 m/s to 0.00565 m/s. All four CAD child
rotations matched their native wheel-body rest bases during the motion samples.

The simulator's wheel admission now waits for structural work in the same stage
to finish before binding referenced render identities. A genuinely missing render
root still faults after that boundary. Three accepted window restarts emitted no
`usd-wheel-visual-identity` errors.

`scenes/flip_cad_drive.usda` provides a persistent interactive scene without an
automatic test controlling the rover. The avatar starts at `(8, 5, 10)` and uses
the standard camera look-at target `(0, 0.7, 0)` in the terrain parent frame.
The observed native movement is consistent with that frame; a separate avatar
coordinate conversion defect was not reproduced in the fresh/restarted scene.

## Full mission limitation

The CAD payload is seated 0.70 m above the 2.119999885559082 m deck datum,
with rover adapter anchor `(0, -0.7, 0)`. The full mission was rerun in
`runs/flip-update-2026-10-23/cad-mission-26/`. Its pre-existing Rhai task error,
`Length of string too large`, still prevents a complete mission verdict. That
run was stopped after the task failed. Landing, release and ramp traversal are
therefore not qualified by the CAD subsystem passes above.

All authored USD changes went through `OpenFile`, typed `ApplyUsdOps` and
`SaveDocument`/`SaveAsDocument`. Operation records are in the two CAD run folders.
No CAD visual mesh was edited, and no contact/solver tolerance was weakened.
