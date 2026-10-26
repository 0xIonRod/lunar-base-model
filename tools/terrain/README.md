# Griffin-1 terrain asset workflow

A complete Griffin Twin ZIP includes the verified source files under
`.cache/sources/nobile03/` and both `heightmap.tif` and `albedo.png` under
`.cache/terrain/nobile03/materials/textures/`. Extract the complete folder,
including `.cache/`, and open it in a compatible LunCoSim installation;
verified bundles need no terrain download or preprocessing step.
LunCoSim resolves `terrain/nobile03` through the Twin's local cache and recognizes
the manifest sources as installed after checking their SHA-256 values.

To check an extracted archive without network access or a machine-global cache:

```sh
python3 /path/to/astrobotic-griffin-1/tools/terrain/verify_griffin_bundle.py \
  /path/to/astrobotic-griffin-1
```

The steps below are for regenerating terrain from a source checkout.

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
  --output "$TWIN/.cache/nobile-terrain-preparation" \
  --center-lat -84.72672255 --center-lon 29.14428685 \
  --window-m 2048 --resolution 513 \
  --vertical-offset -5187.322
cargo run --manifest-path "$LUNCO_ROOT/Cargo.toml" -p lunco-assets -- \
  process --twin "$TWIN/.cache/nobile-terrain-preparation" -a dem
cp "$TWIN/.cache/nobile-terrain-preparation/terrain/materials/textures/heightmap.tif" \
  "$TWIN/.cache/terrain/nobile03/materials/textures/heightmap.tif"
```

The fixed vertical offset is the scene's local simulation datum, recorded in
`research/griffin_1_assumptions.md`. Keep it unchanged when enlarging the crop;
the new perimeter's reported `border_datum` does not redefine the mission frame.
The scene anchor keeps
the source latitude/longitude and body datum provenance; the current runtime
does not yet apply `lunco:anchor:height` as an entity-Y placement, which is why
the local offset is explicit.

The adapter preserves unresolved source voids as NaN. The native DEM processor
owns coverage rejection and bounded neighbour interpolation; this crop requires
658 filled nodes out of 263169 (0.25%). These values are interpolated terrain,
not additional LROC measurements. Use a build with the node-span correction in
the DEM processor (pipeline version 8 or newer): the installed GeoTIFF must have
513 × 513 nodes, 4 m spacing and a 2048 m extent. The bundle verifier checks this.
Install the same TIFF in an authored `terrain/nobile03/` directory if present.

Raw downloads and generated `materials/` bytes are ignored by the repository.
Commit `Assets.toml`, this tool, the command parameters/provenance, and USD
terrain wiring only. Check the boundary before staging:

```sh
git check-ignore -v "$TWIN/.cache/sources/nobile03/NAC_DTM_NOBILE03.TIF" \
  "$TWIN/terrain/nobile03/materials/textures/heightmap.tif"
```

## Nobile material colour

The terrain material binds `terrain/nobile03/materials/textures/albedo.png` at
full weight. Its source is the co-registered LROC
[NAC_DTM_NOBILE03_M1101097181_90CM orthophoto](https://data.lroc.im-ldi.com/lroc/view_rdr_product/NAC_DTM_NOBILE03_M1101097181_90CM),
0.9 m/pixel. `Assets.toml` pins the download SHA-256. The prepared output has
2048 x 2048 texels over the same 2048 m ENU footprint as the DEM. Source zeroes
are unmapped coverage; the native albedo processor gives them neutral material
colour, not a black crater. Small acquisition shadows remain in the image:
local illumination removal is an appearance approximation, not a calibrated
reflectance measurement or new terrain geometry.

Regenerate using the existing polar projection adapter and native albedo owner:

```sh
# Download only the declared orthophoto, using the normal asset CLI.
cargo run --manifest-path "$LUNCO_ROOT/Cargo.toml" -p lunco-assets -- \
  download --twin "$TWIN" -a nobile03_ortho

# Requires Pillow. This creates a disposable preparation Twin, including the
# local float TIFF and manifest; it does no radiometric normalization itself.
python3 tools/terrain/prepare_lroc_polar_ortho.py \
  --source "$TWIN/.cache/sources/nobile03/NAC_DTM_NOBILE03_M1101097181_90CM.TIF" \
  --output "$TWIN/.cache/nobile-albedo-preparation" \
  --center-lat -84.72672255 --center-lon 29.14428685 --window-m 2048
cargo run --manifest-path "$LUNCO_ROOT/Cargo.toml" -p lunco-assets -- \
  process --twin "$TWIN/.cache/nobile-albedo-preparation" -a albedo
cp "$TWIN/.cache/nobile-albedo-preparation/albedo.png" \
  "$TWIN/.cache/terrain/nobile03/materials/textures/albedo.png"
```

Alternatively, open the preparation Twin in an owned LunCoSim session, wait for
`ListDatasets` to list `twin/NobileAlbedoPreparation/albedo`, then issue
`ProcessDataset` with that id and wait for `state.kind = "installed"`.
The generated local-file URL records input provenance; it is not a network
provisioning URL. Recreate this scratch Twin when moving the source checkout.
If an authored `terrain/nobile03/` directory also exists, install the same PNG
there: authored assets take precedence over `.cache/`. Package the generated
albedo alongside the cached DEM. `verify_griffin_bundle.py` requires both maps
and all pinned sources. Keep generated TIFF/PNG files out of Git.
