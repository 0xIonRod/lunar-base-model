# Griffin ramp visual analysis — 22 October 2026

Status: current ramp appearance rejected in user review. The current requirement
checks establish agreement with authored study geometry, not photographic
fidelity. No ramp geometry or body scaling has been changed in this analysis.

## Main finding

The supplied photograph shows folded ramp bundles leaning inward above the
lander deck. The current model's first sections lean outward. Its bus looks
undersized in that silhouette even before changing any body dimensions.

Current authored/composed facts:

| Datum | Current value |
| --- | ---: |
| Bus span across its X/Z envelope | 3.60 m |
| Root hinge X stations | ±1.907114731507 m |
| Distance between root hinges | 3.814229463014 m |
| Length of one folding section | 1.799084054 m |
| Section count per egress assembly | 3 |
| Port stow local +X direction | (0.707106774, 0.707106788, 0) |
| Starboard stow local +X direction | (-0.707106774, 0.707106788, approximately 0) |
| Root-section outer-end span, excluding rail stock | approximately 6.3585 m |

The two runtime directions were read through `world_right` in the static review,
and agree with the composed root rotations: port (0,0,+45°), starboard
(0,180°,-45°). For both roots, the horizontal section direction has the same
sign as the hinge X station. Each first section projects approximately 1.272 m
farther outside the body. The outer-end span is 1.77 times the bus span.
This is an orientation error relative to the supplied stow photograph; changing
body scale would preserve it.

The current 4.50 m X/Z foot envelope is a separate study datum. A 4.5 m overall
vehicle dimension in an older concept image cannot independently establish a
4.5 m bus width. The supplied image and 2021 mock-ups are useful mechanism
references, while the June 2026 hardware photographs govern the current external
bus/panel layout. Their configurations must not be treated as identical.

## What the references support

- The user's photograph resolves stacked folded channels, triangular
  lightening openings, substantial continuous upper/lower chords, discrete
  hinge plates and a visible load path into the deck. The lattice pattern has
  a real reference; removing it wholesale would lose that evidence.
- [Astrobotic's 2021 concept image](https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png)
  also depicts compact inward-leaning folded bundles above the deck. It is a
  concept rendering with an overall size annotation, not released mechanical CAD.
- [NASA's 2021 egress test](https://www.nasa.gov/image-article/off-ramps-moon/)
  shows separated wheel channels, smooth tire corridors, lightweight guide
  walls with triangular openings and articulated seams. The article discusses
  tested surface treatments; it does not identify one final flight coating.
- [NASA's 2023 egress test](https://www.nasa.gov/centers-and-facilities/ames/nasas-moon-rover-prototype-conquers-steep-scary-lander-exit-test/)
  demonstrates terrain-dependent ramp pitch/roll and emphasizes clearance at
  the rover/lander interface. These are VIPER-era prototypes, not proof of
  FLIP's as-built 2026 ramp dimensions.
- [NASA's draft VIPER technical information](https://assets.science.nasa.gov/content/dam/science/psd/lunar-science/documents/VIPER_Technical_Information_AFPP.pdf)
  section 5.4.5.4 requires compatible engagement features, smooth inside walls
  and chamfered upper edges; section 5.2 limits the loaded egress slope to 30°.
  These inform an engineering review but are not automatically FLIP acceptance
  requirements. Several dimensions remain TBD and two separation statements
  require clarification, so they must not be copied as calibrated ramp sizing.
- [NASA/JPL's October 2026 photographs](https://science.nasa.gov/photojournal/voyager-technologies-griffin-1-completes-environmental-testing-at-nasa-jpl/)
  show flight hardware during environmental testing, with a payload simulator.
  Wrapped or omitted mechanisms in that configuration do not resolve the full
  stow/deployment geometry.

All web references above were accessed on 22 October 2026. Reference downloads
and composed direction readback are retained locally in the USD worktree under
`.cache/codex-evidence/griffin-ramp-analysis-20261022/`. The uploaded photograph
is not copied into the public repository.

## Required correction and verification

1. Reconstruct an inward stowed package at each real deck interface. Use
   the photo to constrain orientation and nesting; fit an uncertain angle only
   after camera perspective and clearances have been considered.
2. Resolve the actual folded stack: walking plates, guide walls, hinge offsets,
   stock thickness and end fittings must occupy distinct volumes. The current
   180° section folds alone are not proof of a valid nested package.
3. Preserve uninterrupted wheel channels and the open centre. Verify the
   channel spacing from FLIP's wheel datums, then inspect smooth inward faces,
   seams, root transition and a thin ground toe.
4. Prove the complete unfolding sweep clears the rover, tanks, panels, leg
   structure and the opposite bundle. A correct final screenshot is not enough.
5. Update the source-owned hinge travel and latch frames together with the
   authored stow pose. An inward first section may require a root sweep beyond
   the current ±50/60° limits; a visual rotation alone would invalidate the
   native mechanism. Keep the physics-engine repair with optimization.
6. Add explicit source-backed inward-direction and stowed-envelope acceptance.
   Existing flight-stow checks currently accept the wrong authored silhouette.
   Inspect stowed, intermediate and deployed views before calling it realistic.

Retain the present body scale until the corrected package and current hardware
references demonstrate a dimensional mismatch. The existing ramp contract also
contains stale 12.228605 m / 5.19 m values; the current source is 5.397252161 m
long at a 2.106794675483 m hinge height. That prose must not guide the rebuild.
