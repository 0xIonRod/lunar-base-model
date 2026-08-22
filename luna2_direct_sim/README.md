# Luna 2 direct LunCoSim test

This workspace intentionally does not use `surfacegenerator`.

- Source: fresh NASA LOLA `LDEM_4.JP2` download in `raw/`
- Conversion: `direct_luna2_dem.py`
- Native simulator scene: `lunco://scenes/terrain_only.usda`
- Runtime command: `SpawnDemTerrain`
- DEM input: `site/luna2/materials/textures/heightmap.tif`
- Active simulator API: `http://127.0.0.1:4107`

The direct diagnostic uses a 1 km window, 16 visual samples per side, streamed\nLOD disabled, and collider-ring generation disabled. LunCoSim realizes the\nwindow at native 5 m terrain detail, so large windows are intentionally avoided\nuntil the direct path is verified.
