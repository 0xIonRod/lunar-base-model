# Luna 2 LunCoSim Terrain Handover Report

**Status:** Terrain bake blocked; handover ready  
**Date:** 2026-08-22  
**Audience:** Technical simulator / terrain-runtime maintainer

## Technical summary

The Luna 2 terrain asset and Twin package are present and readable, but LunCoSim does not complete the runtime terrain bake. The UI remains at approximately 10% with a `Baking terrain — luna2` modal and no visible terrain scene.

The active simulator is the `4106` instance. It is responsive and its API reports `ready: true`, `faulted: false`, and zero pending commands. That readiness signal covers the simulator core; it does not prove that the asynchronous terrain bake has completed. A final activity sample showed only **0.41 seconds of CPU time over 8 seconds**, which is consistent with the bake being stalled or waiting on an unreported render/terrain task.

The Twin manifest, USD scene, DEM, and supporting analysis are all present. The failure is therefore more likely in the runtime terrain import/bake path, renderer synchronization, or an unreported asset-stage wait than in Twin discovery.

## Current runtime state

| Item | Observed state |
|---|---|
| Active process | `LunCoSim — Listening on 4106` |
| Active PID | `23128` |
| API health | Online; version `0.1.0-dev` |
| Core readiness | `ready: true`, `faulted: false`, `pending_count: 0` |
| UI state | Terrain bake remains around 10%; user reports no movement |
| CPU activity | 0.41 seconds gained over an 8-second sample |
| stderr | No new errors in `luncosim-4106.err.log` |
| Older instances | Ports 4103, 4104, and 4105 are offline |

## Terrain and data scope

The model is a regional visualization around the Luna 2 commemorative region near Sinus Lunicus:

- Center: approximately 32.4°N, 1.9°W
- Source: NASA LOLA GDR `LDEM_4.JP2`
- Source sampling: 0.25° per pixel, approximately 7–8 km per source pixel
- Processed grid: 32 × 32 samples
- Footprint: approximately 204.8 km × 242.6 km
- Elevation range: −9,249 m to −1,209 m; range 8,040 m
- Mean slope: 3.42°
- 95th-percentile slope: 15.83°

This is suitable for regional topographic context, not landing-scale hazard analysis. The source resolution cannot represent small boulders, small craters, or detailed landing-site hazards.

## Attempt history and result

| Attempt | Configuration | Result |
|---|---|---|
| Baseline Twin | Layered terrain; 200 km window; streamed LOD and collider ring enabled | UI reached the preparation/bake phase and did not complete |
| Lit scene correction | Added a minimal `DistantLight`; removed invalid USDA light syntax and unsupported transform-array syntax | Scene parsing issues were removed, but the terrain bake still did not complete |
| 4105 fast path | 50 km window; streamed LOD enabled; collider ring disabled; horizon shadows disabled | Initially consumed CPU, then became effectively idle while the user still saw 10% |
| 4106 static path | 50 km window; `lodViz = false`; collider ring disabled; horizon shadows disabled | Current handover state: responsive process, no new errors, bake still reported stuck at 10% |

## Evidence and artifacts

- Twin manifest: [twin.toml](C:/Users/salek/OneDrive/Desktop/NASA-lunar-base-model/luna2_twin/twin.toml)
- Current static scene: [luna2_static.usda](C:/Users/salek/OneDrive/Desktop/NASA-lunar-base-model/luna2_twin/sim/scenes/luna2_static.usda)
- Twin-local DEM: [heightmap.tif](C:/Users/salek/OneDrive/Desktop/NASA-lunar-base-model/luna2_twin/.cache/terrain/luna2/materials/textures/heightmap.tif)
- Terrain metadata: [metadata.yaml](C:/Users/salek/OneDrive/Desktop/NASA-lunar-base-model/luna2_twin/.cache/terrain/luna2/metadata.yaml)
- Source terrain analysis: [luna2_sinus_lunicus_analysis.md](C:/Users/salek/OneDrive/Desktop/surfacegenerator/artemis_mission_simulator/lunar_terrain_exporter/models/luna2_sinus_lunicus_analysis.md)
- Generated preview: [luna2_sinus_lunicus_preview.png](C:/Users/salek/OneDrive/Desktop/NASA-lunar-base-model/luna2_twin/.cache/terrain/luna2/luna2_sinus_lunicus_preview.png)
- Active simulator stderr: [luncosim-4106.err.log](C:/Users/salek/OneDrive/Desktop/NASA-lunar-base-model/logs/luncosim-4106.err.log)
- Active simulator stdout: [luncosim-4106.out.log](C:/Users/salek/OneDrive/Desktop/NASA-lunar-base-model/logs/luncosim-4106.out.log)

## Recommended next debugging steps

1. **Instrument the terrain bake stages.** Add or enable progress logging for GeoTIFF decode, georeference validation, heightfield creation, static mesh creation, collider creation, GPU upload, and first-frame completion. The current UI percentage and `GetReadiness` response do not identify the waiting stage.

2. **Test the same Twin with a tiny synthetic DEM.** Use a square 4×4 or 8×8 GeoTIFF with simple elevations. If the tiny DEM also stops at 10%, the defect is likely in the runtime terrain path or renderer synchronization. If it completes, compare GeoTIFF tags, CRS, dimensions, and elevation encoding against `heightmap.tif`.

3. **Test the direct command path independently.** Load a known-good scene, then issue `SpawnDemTerrain` with the Luna 2 site directory, `lod_viz: false`, `collider_ring: false`, a small `window_m`, and a low `target_res`. This separates Twin/USD composition from the runtime DEM builder.

4. **Validate the GeoTIFF at runtime resolution.** Confirm the reader accepts the file’s CRS/geotransform and signed elevation type. The file is square, but the runtime may still reject or wait on a projection, tag, or nodata convention without surfacing an error.

5. **Check the render thread and GPU synchronization.** A previous instance logged `Couldn't get swap chain texture: Timeout`. The current 4106 log is clean, so this is not proven as the root cause, but the terrain bake may be waiting on a render resource without reporting it to the command API.

6. **Add a bake timeout and failure state.** A terrain job that makes no measurable progress for a defined interval should expose a fault and stage name instead of leaving the user at an ambiguous percentage.

## Handoff questions

- Is the expected target a regional 200 km visualization or a landing-scale Luna 2 site? The current DEM resolution only supports the former.
- Is physics/collider support required for the first milestone? It is disabled in the current diagnostic scene to isolate visual terrain generation.
- Which LunCoSim build and terrain-runtime revision should own the next test? The active binary reports `0.1.0-dev` / `0.6.0-nightly.54.1`.
- Can the terrain runtime expose a per-stage progress/error endpoint? The present `GetReadiness` result is insufficient to diagnose this bake.
