# Nobile terrain reconstruction

The NOBILE03 processed maps require native processing pipeline version 10 or
newer. The DEM processor continues curvature through bounded missing coverage
with measured postings fixed. The albedo processor excludes unmapped zero
radiance before resampling, avoiding a false dark outline at coverage edges.
The polar adapter preserves unresolved elevations for the native processor.
See the repository's [terrain workflow](../../../tools/terrain/README.md) for
source provenance and regeneration.

The 513 by 513 DEM retains 4 m node spacing, a 2048 m footprint and its existing
vertical datum. All 261,442 measured postings remain bitwise unchanged; only
1,727 missing postings are reconstructed. Those heights are interpolated
estimates, not additional lunar measurements. Missing orthophoto coverage stays
neutral rather than acquiring fabricated photographic detail.

Installed generated-map SHA-256 values:

| Map | SHA-256 |
| --- | --- |
| `heightmap.tif` | `1a5412b72324fc5a5bfabebef5366b92ca61e3b629a28604a6864d2f2e3533b0` |
| `albedo.png` | `ce6fd32acdf8b3412ff27e0d5f7292630e238d67bc0b7df8ecf82b144cfee7c9` |

The authored `terrain/nobile03/materials/textures/` and corresponding `.cache`
locations contain the same files. Generated rasters remain outside Git;
portable delivery must include them as described in the terrain workflow.
