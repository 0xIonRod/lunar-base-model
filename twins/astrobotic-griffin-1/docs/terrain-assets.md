# Griffin terrain artifacts

The canonical preparation recipe is
`twins/astrobotic-griffin-1/Assets.toml`, under `nobile03_dem.process`.
It uses LunCoSim's native spherical raster sampling and existing DEM/albedo
processors. Site parameters and material policy live in that recipe.

Published Twin ZIPs contain the preparation recipe and source provenance.
Generated `.cache/` data is excluded. On first open, LunCoSim requests the
declared dataset and prepares its float64 heightmap, albedo, coverage mask and
integrity receipt. Network access is required until those artifacts are installed.

For a source checkout, build the asset manager from the same engine revision
used to run the Twin:

```sh
cargo build --manifest-path /path/to/luncosim/Cargo.toml -p lunco-assets --bin lunco-assets -j 4
/path/to/luncosim/target/debug/lunco-assets download --twin /path/to/astrobotic-griffin-1 -a nobile03_dem
/path/to/luncosim/target/debug/lunco-assets process --twin /path/to/astrobotic-griffin-1 -a nobile03_dem
/path/to/luncosim/target/debug/lunco-assets verify --twin /path/to/astrobotic-griffin-1 -a nobile03_dem
```

The application performs the same declared preparation when this dataset is
requested. The prepared artifact lives at
`.cache/terrain/nobile03/materials/textures/heightmap.tif`; its matching
`albedo.png` and `coverage.png` are published in the same transaction.
Coverage 255 denotes source-supported samples; 0 denotes missing source
coverage, where the native DEM processor may have interpolated a bounded gap.
Filled samples are estimates, not new LROC measurements.

The scene references the logical asset `terrain/nobile03`; the asset owner
resolves it to the generated bundle under `.cache/`.
Raw downloads, generated outputs, receipts and bake stamps stay ignored.
Commit the manifest, source provenance, scene references and custom code only.

The fixed vertical offset defines the Twin's local simulation datum. Changing
crop size does not redefine that frame. The native output georeferencing
records the centre, sphere/frame, node spacing and full sample span.
Crater, overzoom and rock layers remain at their USD/runtime owners.

The packaging workflow builds the native asset manager at the engine revision
pinned in the repository's `tools/qualification.toml`, prepares this recipe in
the staged Twin and requires runtime qualification before publication. Its
`QUALIFICATION.json` identifies that engine and the individual gates. The ZIP
excludes downloaded/generated data; qualification is not an offline-install claim.
