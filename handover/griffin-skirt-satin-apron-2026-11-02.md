# Griffin engine-skirt finish review — 2026-11-02

The broad engine-bay apron now uses a separate satin-grey UsdPreviewSurface,
so it no longer inherits the coarse crinkle shader from the outer blanket.
The outer walls retain their silver palette with softer folds. Appearance
parameters are owned by `GriffinPresentationStudy::EngineBayFinish` and applied
through `griffin_bus_detail::skirt_finish_plan` using typed Editor operations.
These are visual study assumptions, not flight material or thermal properties.

The model change is based on `43595df`. Mesh points, face topology, collision
flags and single-sided settings are identical to that baseline. No mass,
joint, thrust or exhaust-clearance geometry changed. The document was saved
through `SaveDocument` and reopened; the underside inspection rotation stayed
in the disposable view layer. The exporter also normalized two existing prim
metadata keys from `doc` to `documentation`, retaining their text.

## Verification and limits

- Pass: the seven-check finish observer on the edited and reopened component
  in production build `23fb53c4-dirty`; the saved finish is unchanged since.
- Pass: native Editor underside review in production build `8942a7d5-dirty`.
  This is an isolated component review; final mission lighting remains Partial.
- Pass: same-generation `QueryUsdPrims` readback in the current build. All three
  meshes are finite, closed, consistently outward-wound, single-sided and
  render-only, with positive volume. The six scalar controls match SysML, and
  the apron binds its separate satin material. Minimum measured wall allowance
  is 0.0080000162 m. Geometry/physics definitions match the baseline exactly.
- Pass: `git diff --check`; generated terrain files are ignored by Git.
- Not passed: current-build scripted integration validation. REPL and UI-hook
  calls did not return, including `1+1`. The production propulsion fixture
  ended `NO-VERDICT`, at zero ticks after 3840 updates. This is a runtime
  initialization limitation, not a successful simulation or landing test.

Focused integration invocation from the LunCoSim checkout (use the absolute
Twin fixture path when the model repository is elsewhere):

```text
luncosim test --scene <twin>/tests/griffin_propulsion_requirements.usda --max-ticks 120 --tick-hz 60 --threads 1 --jitter 0
```

Saved component SHA-256:
`0C70F1FB022546BBA079A99FEF52289A9914E55F533DF484EC9402075FDA515C`.

## Python terrain workaround

The three NOBILE03 sources were downloaded and verified against the pinned
SHA-256 values in `Assets.toml`. Both existing Python polar adapters ran, then
LunCoSim's native `ProcessDataset` completed with state `installed`. The maps
were installed in the Twin's ignored `.cache/terrain/nobile03/` payload.
Python verified 513 × 513 finite DEM nodes, 4 m spacing, a 2048 m extent, and
2048 × 2048 albedo pixels. The 1727 unresolved source nodes were left for the
native DEM processor; Python did not fabricate measurements.

See `tools/terrain/README.md` for Windows commands and the API processing path.
Raw sources and generated maps are local runtime assets and are not included
in the source commit. Regenerate them or distribute a complete verified Twin
bundle when moving the model to another machine.
