# Tank blanket appearance checkpoint

The front review after the rail pass showed smooth gold tank domes. Reused the
existing `lunco://shaders/mli_foil.wgsl` material; no new shader, texture asset,
Rust mechanism or tank geometry was introduced. Its two colors and four scalar
controls now come from GriffinVisualConfiguration, with the illustrated wraps
in the user-supplied Pittsburgh Technology Council image and ESA rendering as
qualitative references. Pattern density, contrast, color and sheen are artistic
estimates, explicitly separate from engineering blanket properties.

The existing surface-finish plan validates the source values and writes the
shader's declared color3f/float GPU inputs through the Editor document owner.
A malformed color tuple was rejected atomically on the first apply attempt;
the corrected plan reuses the shared tuple encoder. The accepted plan had 14
operations and the owner saved the vehicle.

Fresh composed review: document 115595161969253, view 14, generation 0, stage
generation 32. Shader readback: crinkle 32, facet_depth 1, v_scale 1,
shade_color (.18,.13,.04), with expected float rendering precision.
The close view is `griffin-tank-foil-2026-10-01.png`. Pattern is more visible,
but the shader currently models fold color/roughness rather than displaced
blanket geometry or perturbed fold normals. Realistic foil highlights remain
a rendering limitation; do not claim calibrated material appearance.

GRIFFIN_FLIP_VISUAL passed 121 checks in 8 ticks, one thread, zero jitter,
60 Hz, seed 6840157149251759617. Four existing generic attribute observations
verify the scalar controls against SysML. Source catalogue validation passed
207 targets/records, 47 sources, three roles. These are visual/provenance
checks, not landing, powered deployment or FLIP egress acceptance.
