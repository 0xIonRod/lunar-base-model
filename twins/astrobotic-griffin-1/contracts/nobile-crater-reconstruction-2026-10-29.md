# Nobile terrain reconstruction

The NOBILE03 recipe requires LunCoSim artifact processing pipeline version 12
or newer. Native spherical GeoTIFF sampling preserves unresolved coverage for
the DEM processor, which continues curvature through bounded missing regions
with measured samples as constraints. The albedo processor excludes unmapped
zero radiance before resampling. See the [terrain workflow](../docs/terrain-assets.md)
for source provenance and regeneration.

The 513 by 513 float64 DEM uses 4 m node spacing over a 2048 m footprint and
preserves the authored vertical datum. Reconstructed heights are interpolated
estimates, not additional lunar measurements. Missing orthophoto coverage stays
neutral rather than acquiring fabricated photographic detail.

The sole generated bundle lives under `.cache/terrain/nobile03/`. Its
`.pipeline.toml` receipt records the admitted input hashes, executed settings
and delivered artifact hashes. `lunco-assets verify` validates that receipt
against the current manifest and files. Generated rasters remain outside Git;
portable delivery includes the cache as described in the terrain workflow.
