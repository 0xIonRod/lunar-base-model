# FLIP and Griffin finish review — 4 November 2026

Presentation study, authored in the headful LunCoSim Editor, version
0.6.0-dev (`8cc192e5-dirty`), against Twin baseline `6772628`.

The active `vehicles/flip_v5.usda` now uses the selected yellow outer tread
finish, RGB (1, 0.72, 0.015), with metallic 0. The earlier yellow change in
`flip_airless_wheel_visual.usda` did not affect this active CAD vehicle.
Spokes, cables, hubs, chassis and cells keep their existing finishes.

Griffin's reusable tank-retention bands and bus tank-support frame now use
RGB (0.20, 0.24, 0.29), roughness 0.42, for a darker satin separation from
the silver insulation. These are artistic appearance coefficients, not
measured engineering material properties. Their source remains
`GriffinPresentationStudy::HardwareFinish`; FLIP's source remains `SocialFinish`.

Three generation-checked SourceAsset proposals were committed through the
document owner and explicitly saved. Each changed only three shader attributes:
base color, diffuse color, and metallic (FLIP) or roughness (Griffin).
The saved USD diff contains no geometry, transform, binding, physics, mass,
joint, controller or imported CAD-layer changes.

## Evidence and limits

- [Active FLIP tread review](../handover/flip-yellow-v5-2026-11-04.png).
- [Focused Griffin retention review](../handover/griffin-retention-2026-11-04.png).
- FLIP document 121879285727486, tank 121879800748979, bus 121879879350909:
  each reached projected generation 3 with projection ready.
- Typed FLIP shader readback matches both yellow color channels and metallic 0.
- Tank and bus document lint completed with zero errors and zero warnings.
- FLIP document lint reports seven unavailable runtime output ports in this
  Editor context: position X/Z, velocity X/Z, yaw, angular velocity Y and piloted.
  These connections were not changed. This is not a full-runtime lint PASS.
- `git diff --check` passed. Only material attributes changed in authored USD.
- Rhai execution did not return in the held operational scene, so no live
  Rhai/SysML or mission verification PASS is claimed. The operational scene
  also lacks its local NOBILE03 terrain cache. Visual projection was inspected
  independently; no terrain, engine or mission workaround was authored.

The complete-lander view does not expose every retention surface. The focused
reusable tank review supports this finish change, not a full-vehicle fidelity
or physics qualification. The commit includes only these finishes, their source
parameters and review evidence; unrelated local CAD/export work is excluded.
