# Social video material pass — 28 October 2026

FLIP now separates pale chassis panels, brushed structural metal, dark electronics,
wheel tread, machined spiders, spring webs, fasteners and camera lenses. Nine shared
material networks live on the vehicle and bind 339 active CAD surfaces. The supplier's
five visual layers and panel equations are unchanged; material overrides follow the
moving wheels and panel through the existing assembly references.

Griffin retains the silver insulation reconstruction. Its source-owned foil density
changes from 24 to 12 cells per metre, fold strength from 0.45 to 0.62 and sheen
from 0.72 to 0.80. The tank, bus and engine-skirt blanket owners now agree.
Existing tank fittings and landing-gear finishes gain fine brushed grain while
retaining their source-owned colors, metallic and roughness values.

`shaders/hardware_finish.wesl` uses object-fixed, derivative-filtered grain and a
small shading-normal perturbation. `shaders/photovoltaic_finish.wesl` adds filtered
electrodes to the already modeled individual cells, without requiring missing CAD
UVs. Unresolved detail fades into a surface average rather than retaining an
unfiltered high-frequency pattern. This filtering has been inspected in stills;
a final moving-camera social export remains a separate visual check.

The artistic controls live in `GriffinPresentationStudy::SocialFinish`. The pure
typed plans in `tools/social_surface_finish.rhai` read those controls and reject
unclassified CAD surfaces. USD edits and saves went through the live document
owner. No mesh points, transforms, collisions, masses, joints, power equations or
physical thermal properties were changed by these plans. The clean baseline has
no baked lunar dust, so touchdown/egress shots can receive a consistent dust state.

Only the static `scenes/griffin_flip_visual.usda` review camera receives -0.6 stops
of exposure compensation and an increase of ReviewFill intensity from 300 to 1000.
The operational mission lighting and calibrated Sun are unchanged. The review
scene's existing `vec3_array(map)` observer error remains outside this material
pass; a rendered frame is not a passing verdict from that observer.

## Review images

- [FLIP assembly](../handover/flip-social-materials-2026-10-28.png)
- [Griffin assembly](../handover/griffin-social-materials-2026-10-28.png)
- [Griffin insulation close-up](../handover/griffin-foil-social-2026-10-28.png)
- [Assembled review scene](../handover/griffin-social-scene-2026-10-28.png)

## Verification

Fresh production component runs passed: tank 536/536, landing legs 189/189,
bus 254/254, totaling 979 checks. FLIP's live material-binding gate passed
339/339 surfaces across chassis, solar panel and four wheel stations. Existing
focused source/readback gates passed for tank dimensions/bindings (10), landing
gear (6), and bus service geometry (16). The repository structural check passed.
Both WESL files, the Rhai authoring tool, and the presentation SysML file passed
their standalone syntax checks. Renderer logs contain no shader-pipeline or GPU
validation failures from this pass; settled RuntimeDiagnostics was clear.

Standalone `--validate` of the vehicle cannot resolve the Twin URI namespace
without an open Twin, and standalone visual-configuration analysis lacks its
solar-requirements source set. These attempts are retained in the local run log;
the opened-Twin readbacks and production component runs provide the composed
checks above. The CAD preview also retains its existing composed-text export
diagnostic at `Wheel_FL.lunco:suspension:restLength`; it renders the assembly.

See [machine-readable receipt](evidence/social-materials-2026-10-28.json).
