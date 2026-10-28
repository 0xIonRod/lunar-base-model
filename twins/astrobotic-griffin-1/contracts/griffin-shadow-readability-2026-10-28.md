# Griffin shadow readability — 2026-10-28

**Superseded later on 28 October:** the user rejected artificial fill and extra
hardware shaders. The DomeLight was removed from both saved scenes, and the
seven components now reuse their existing materials. Solar mount brackets and
links reuse PanelFrame. The experiment below is historical evidence only; its
HDR, generator and authoring tool were removed. See the Sun-only correction
receipt for the current result.

The surface mission now includes a hidden, ground-biased HDR environment light.
It gives shadowed metallic structure a reflection source while retaining the
existing Sun and hard shadows. This is artistic presentation lighting, not a
calibrated lunar irradiance model. No visible skybox is added. Controls belong
to `ShadowReadability` in `requirements/griffin_presentation_study.sysml`.

The seven ramp/bearing/solar component sources now bind explicit lit
UsdPreviewSurface finishes on 31 visible surfaces. Pins use metallic 0.88,
roughness 0.24; housings/brackets/links use metallic 0.65, roughness 0.38.
Solar brackets and links previously lacked explicit material bindings. Existing
physics schemas are preserved; all new finishes have zero emission.

USD edits were applied and saved through the native document authoring API,
using `tools/griffin_shader_readability.rhai` typed plans. The fixed-pose
`scenes/griffin_shader_review.usda` is a separate presentation review fixture.

## Evidence and limits

- All seven native role-binding checks pass (31 surfaces).
- Fresh launch of saved `griffin_1_surface_ops.usda`: ready, no world hold or
  fault, zero runtime diagnostics; the DomeLight is spawned at intensity 4000,
  with its HDR resolved and skybox disabled. Visually inspected mission capture:
  `handover/griffin-shadow-readability-2026-10-28.png`.
- Rhai and SysML validation pass; repository structural validation passes.
- Solar requirement fixture passes (exit 0).
- Ramp root/middle/toe fixtures each fail their native metric-span constraint;
  root bearing fails its open-bore constraint (exit 1). These are unresolved
  geometry gate findings, not shader acceptance passes. Source comparison with
  the pre-edit backups confirms every non-finish line in all seven changed
  component files is unchanged, allowing the native serializer's documentation
  spelling normalization. No geometry, joint constraints or contact data changed.
- Local receipts, logs, pre-edit sources and same-pose review captures are in
  `runs/griffin-lighting-2026-10-28/`; shader review captures are stowed-pose
  comparisons and do not establish deployed mechanism performance.

Regenerate the deterministic HDR from the SysML upper floor (currently 0.0625):

```sh
python tools/rendering/generate_ground_fill.py twins/astrobotic-griffin-1/environments/presentation_ground_fill.hdr --upper-floor 0.0625
```

Reload the saved mission in LunCoSim to see the scene lighting change.
