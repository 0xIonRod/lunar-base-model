# Griffin-1 terrain asset workflow

The Twin uses the official LROC NAC DTM `NOBILE03`, a 4 m/pixel product whose
PDS3 label declares a south-polar stereographic projection. The native
`lunco-assets` cropper currently accepts equirectangular products only, so the
polar reprojection is an explicit, reproducible preprocessing step:

```sh
LUNCO_ROOT=/path/to/luncosim-workspace/main
TWIN=$PWD/twins/astrobotic-griffin-1

cargo run --manifest-path "$LUNCO_ROOT/Cargo.toml" -p lunco-assets -- \
  download --twin "$TWIN" -a nobile03_dem
cargo run --manifest-path "$LUNCO_ROOT/Cargo.toml" -p lunco-assets -- \
  download --twin "$TWIN" -a nobile03_label

python3 tools/terrain/reproject_lroc_polar_dem.py \
  --source "$TWIN/.cache/sources/nobile03/NAC_DTM_NOBILE03.TIF" \
  --label "$TWIN/.cache/sources/nobile03/NAC_DTM_NOBILE03.LBL" \
  --output "$TWIN/terrain/nobile03/materials/textures/heightmap.tif" \
  --center-lat -84.72672255 --center-lon 29.14428685 \
  --window-m 512 --resolution 129 \
  --vertical-offset -5187.322
```

The final offset must be measured from the tool's reported `border_datum` and
then recorded in `research/griffin_1_assumptions.md`. It is a local simulation
datum offset, not a change to the LROC source elevations. The scene anchor keeps
the source latitude/longitude and body datum provenance; the current runtime
does not yet apply `lunco:anchor:height` as an entity-Y placement, which is why
the local offset is explicit.

Raw downloads and generated `materials/` bytes are ignored by the repository.
Commit `Assets.toml`, this tool, the command parameters/provenance, and USD
terrain wiring only. Check the boundary before staging:

```sh
git check-ignore -v "$TWIN/.cache/sources/nobile03/NAC_DTM_NOBILE03.TIF" \
  "$TWIN/terrain/nobile03/materials/textures/heightmap.tif"
```
