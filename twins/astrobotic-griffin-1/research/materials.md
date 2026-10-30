# Griffin and FLIP material register

The [30 October texture refinement](../contracts/texture-refinement-2026-10-30.md)
adds a Twin-owned two-scale blanket shader, directional hardware grain and
area-preserving photovoltaic electrode filtering. It supersedes the appearance
mapping below for the bus/tank/skirt covers: those now use
`thermal_blanket.wesl`, with the original component palettes and coarse-fold
controls retained. Engineering identities and confidence remain unchanged.

Reviewed 29 October 2026. This register separates manufacturer statements,
photographic appearance and renderer assumptions. A material's appearance does
not establish its composition or qualified mechanical/thermal properties.

The typed catalogue is `requirements/griffin_material_catalog.sysml`. Existing
wheel selections remain in `flip_airless_wheel_requirements.sysml` and are
referenced by the catalogue. Grade and qualified-property availability flags
remain false where the public sources do not release those data. No density,
strength, temperature-dependent modulus, solar absorptance or IR emittance is
invented for this visual pass. Units and operating ranges belong beside such
properties when released data become available.

## Source register

| Typed source identity | Primary source and revision | What it supports |
| --- | --- | --- |
| AstroboticGriffinPage | [Griffin lander](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/), accessed 29 October 2026 | Aluminum frame, isogrid deck, triple-junction solar cells. No alloy/temper, surface treatment or cell layer stack. |
| AstroboticOctober2025Update | [Griffin-1 mission update](https://www.astrobotic.com/griffin-1-mission-update/), 24 October 2025 | Four main COPVs and pressure-system integration. Composite overwrap is distinct from the unreleased liner material. |
| NasaJplPia26708 | [NASA/JPL environmental testing photographs](https://science.nasa.gov/photojournal/voyager-technologies-griffin-1-completes-environmental-testing-at-nasa-jpl/), published 13 October 2026, July/August imagery | Visible silver/pale covers, limited gold-colored tape and exposed hardware. Finish appearance only; test covers may differ from flight surfaces. |
| AstrolabFlipPage | [FLIP rover](https://www.astrolab.space/flip-rover/), accessed 29 October 2026 | Shared full-size FLEX wheels and bespoke Venturi battery enclosure. Does not identify enclosure alloy or coating. |
| VenturiWheelPage | [Hyper-deformable wheel](https://venturi.space/en/wheel/), accessed 29 October 2026 | Stainless-steel and composite tread blades, proprietary superelastic carrier, cables and springs. Does not release alloy grades or proprietary composition. |
| AstrolabLeag2025_5034 | [FLIP Mission Overview, Luke Walker / Astrolab](https://www.hou.usra.edu/meetings/leag2025/pdf/5034.pdf), October 2025 | Fabric-tether steep-ramp egress and test imagery. Fiber, weave, coating and strength are unpublished. |

The [2021 Astrobotic payload guide](https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf)
is historical configuration context. It does not override later FLIP hardware
photographs. Public mission dates on older pages are not treated as current
schedule evidence.

## Component assignments and renderer mapping

| Surface/role | Engineering identity and confidence | Current appearance mapping | Limits |
| --- | --- | --- | --- |
| Griffin frame and deck | Aluminum alloy, manufacturer statement | `hardware_finish.wesl`, exposed neutral metal and fine filtered grain | Alloy, temper, machining direction and anodizing unconfirmed; brushing is illustrative. |
| COPV pressure boundary | Liner unknown; composite overwrap confirmed at family level | Visible cover uses existing `mli_foil.wesl`; fittings use hardware finish | A cover shader is not a carbon-fiber or pressure-wall model. Do not call the entire tank aluminum, steel or Kapton. |
| Two upper pressurant bottles | Geometry reconstructed from imagery; final outer cover uncertain | Existing silver blanket reconstruction retained | Count/location of these two visible bottles does not establish the third tank location or blanket chemistry. Do not replace the covers with exposed woven composite solely because a separate fit-check image shows bare overwrap. |
| Bus exterior and skirt | Blanket construction/stack unknown, silver outer appearance inferred | Existing foil shader, seams and limited gold tape | No claim of specific polymer, metalization thickness, thermal emittance or gold metal. |
| Landing joints, pistons, pads, fittings | Visible metal; specific grades/coatings unknown | Existing hardware finish with separate piston/joint/pad roughness | Shader metallic is a rendering control, not a structural material identity. |
| Compact tracks | Dark walking surface and metallic curbs reconstructed | Existing dark plate and metal material networks | Substrate/coating unconfirmed. Geometry/contact proxies own physical contact; the shader adds no traction. |
| Egress tether strips | Fabric confirmed; fiber and construction unknown | `woven_webbing.wesl`, nonmetallic, rough, object-fixed filtered weave | Color, 0.9 mm weave pitch and normal amplitude are explicit visual assumptions. Rest routing remains static; this shader adds no tether physics. |
| FLIP chassis/enclosure | Substrate and finish unreleased | Existing pale chassis/dark housing hardware presets | Pale appearance does not establish aluminum, paint or a particular thermal coating. |
| FLIP tread blades | Stainless-steel/composite architecture confirmed | Existing Blade metal and dark Carrier networks distinguish roles | Exact steel and composite regions remain a reconstruction; no rubber or NiTi claim. |
| Wheel carrier | Proprietary superelastic material confirmed | Existing dark Carrier finish | Dark dielectric appearance is a visual selection, not identification as elastomer. |
| Cables, springs, rim and hub | Metal visually inferred; grades unknown | Existing Cable and Metal networks | Do not reuse tread stainless identity for every wheel part without evidence. |
| Solar cells | Griffin triple-junction technology confirmed; detailed stack and FLIP chemistry unknown | `photovoltaic_finish.wesl`, dark face, filtered fine electrodes | UI now says cell-face color, avoiding an unsupported silicon identity. Pattern spacing is illustrative. |

## Shader changes and review boundary

The new woven-webbing shader binds only the two compact rest-routing strips.
It replaces their inherited ramp-plate appearance with a rough, nonmetallic
fabric surface. Its analytic weave fades below pixel resolution; unresolved
detail increases roughness slightly. Emission is zero. Existing mission Sun,
lights, camera exposure, geometry, masses and contact materials are unchanged.

The photovoltaic shader's electrode filtering now blends the resolved line
coverage into its area average once. Previously the line mask was attenuated
twice during the transition. The correction retains the source pitch/width
and avoids an unnecessary dark transition as detail becomes subpixel.

All PBR color, roughness and grain values remain visual estimates. They do not
drive Modelica thermal behavior. The generic typed cross-domain material/finish
binding adapter remains a tooling gap; this catalogue is a source record, not
an automatic engineering-material resolver. The existing static review scene
has historical review-fill settings; use the operational Twin to assess its
authored lunar illumination.

Native material readback: compact component generation 13, projected generation
13, projection_ready true, both strips bound to the Webbing network and explicit
SaveDocument completed. Both shader files pass WESL validation. The opened Twin
source set includes the catalogue and resolves with no SysML errors/warnings;
standalone catalogue validation requires that source set for its wheel references.
RuntimeDiagnostics reports zero errors/warnings in the assembly review.

The isolated Editor preview remained blank with no image rectangle after
OpenUsdPreview renewal and a layout reset. The assembly renders, but its rest
strips are occluded or in deep shadow from the inspected cameras. Fine weave
appearance and a moving-camera anti-aliasing check remain unverified. This is
a saved shader draft with typed readback, not a completed close-up visual gate.
No light was added to make the dark-side fabric readable.
