# Griffin landing annotations

The landing footprint now follows the terrain surface, and route labels offset
along site up. Guidance retains its authored touchdown reference. The engine
change is commit `7adf81263`, fast-forwarded into local engine `main` from
`optimization`. The Twin change is on its existing `main` branch. Engine
publication remains separate from the Griffin push.

## Ownership and behavior

- The shared billboard renderer maps active-scene up through BigSpace and adds
  the offset to the current render position. Vehicle attitude does not rotate
  the label offset.
- `LandingTarget` retains its navigation position. The hidden `Dome` supplies
  the authored footprint radius and material, without a fixed vehicle-height
  offset. The standard `SurfaceMark` curve feeds the existing terrain annotation
  owner. Terrain fragments place the mark across slopes and LOD changes.
- `landing_target_presentation.rhai` runs on the presentation clock and refreshes
  its footprint after target document projection events. Headless execution
  retains navigation without requesting renderer work. Windowed and offscreen
  hosts install the same `UsdCurveViewPlugin`, including scene teardown.
- Griffin fits the reference route to terrain before powered descent. Egress
  applies the frozen landed ramp frame and places the entry on the payload deck.
  SysML owns the 150 m label fade range; the authoring planner consumes it.
- USD edits were made through `OpenFile`, typed operations, `SaveDocument`, and
  readback. Runtime marker placement uses the disposable view layer.

## Verification

Production binary SHA-256:
`63a72a5275568b0945ee9bd5638d9be46501eeef34fd7b21b248829a6bf260ae`.

From the engine checkout:

```sh
cargo test -p lunco-luncosim-edit-ui --lib billboard_overlay::tests::billboard -j 4
python3 scripts/api/test_landing_annotations.py \
  --twin /home/rod/Documents/models/lunar-base-model/twins/astrobotic-griffin-1 \
  --output target/landing-annotations/release-proof --port 4791
```

- Two focused label tests passed, including a rotated scene and overturned body.
- Eleven authored descent checks and twelve landed checks passed. They cover
  surface publication, unchanged guidance height, all five markers, deck entry,
  missing terrain rejection, and invalid width rejection without retiring the
  displayed footprint.
- Three headless checks passed after qualified touchdown. An external API read
  also confirmed healthy presentation-owner state with rendering disabled.
- The flat-ground `lander_ops` scene separately published all 64 footprint
  segments through `authored_curve` in offscreen rendering. Its owner and render
  log were healthy.
- Screenshots were inspected at
  `optimization/target/landing-annotations/release-proof/{descent,landed}.png`
  and `optimization/target/landing-annotations/flat-final/flat.png`.
- Readiness and runtime diagnostics were clear in the accepted Griffin run.
  Owned API ports 4791, 4792 and 4793 were released. Both diffs passed
  `git diff --check`.

This verifies landing annotation presentation and its landed-frame transition;
it does not qualify the complete autonomous rover egress mission.
