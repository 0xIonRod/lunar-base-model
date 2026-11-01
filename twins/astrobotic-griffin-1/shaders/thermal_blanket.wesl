import bevy_pbr::render::forward_io::VertexOutput;
import bevy_pbr::render::mesh_functions;
import lunco::shaders::pbr_lit::lit_n;
import lunco::shaders::lunco_noise::{fbm_rot_gradient, noise_footprint_weight};

//! Silver-cover appearance, not identification of a flight insulation stack.
//! Coarse handling folds and fine crinkles share an object-fixed metric frame.
//! Each octave is derivative filtered. Unresolved normal variance contributes
//! to roughness; no baked light, emission or shadow-lifting term is added.
//!@ui foil_color color "Bright cover colour"
//!@default foil_color 0.76,0.79,0.82
//!@ui shade_color color "Fold colour"
//!@default shade_color 0.24,0.27,0.30
//!@ui crinkle 0 64 "Coarse folds per metre"
//!@default crinkle 26
//!@ui facet_depth 0 1 "Coarse fold slope"
//!@default facet_depth 0.32
//!@ui sheen 0 1 "Reflective sheen"
//!@default sheen 0.60
//!@ui v_scale 0.01 4 "Axial fold scale"
//!@default v_scale 1.4
//!@ui micro_scale 64 1000 "Fine crinkles per metre"
//!@default micro_scale 240
//!@ui micro_strength 0 0.2 "Fine crinkle slope"
//!@default micro_strength 0.045
struct Material {
    foil_color: vec3<f32>,
    crinkle: f32,
    shade_color: vec3<f32>,
    facet_depth: f32,
    sheen: f32,
    v_scale: f32,
    micro_scale: f32,
    micro_strength: f32,
}
@group(constants::MATERIAL_BIND_GROUP) @binding(0)
var<uniform> mat: Material;

@fragment
fn fragment(input: VertexOutput, @builtin(front_facing) is_front: bool) -> @location(0) vec4<f32> {
    let m = mesh_functions::get_world_from_local(input.instance_index);
    let R = mat3x3<f32>(normalize(m[0].xyz), normalize(m[1].xyz), normalize(m[2].xyz));
    let p = transpose(R) * (input.world_position.xyz - m[3].xyz);
    let n = normalize(transpose(R) * normalize(input.world_normal));
    let scale = vec3<f32>(1.0, mat.v_scale, 1.0);
    let q = p * mat.crinkle * scale;
    let footprint = max(length(dpdx(q)), length(dpdy(q)));
    let coarse = fbm_rot_gradient(q, 3, 0.55, footprint, vec2<f32>(2.0, 2.0));
    let fine_q = p * mat.micro_scale;
    let fine_footprint = max(length(dpdx(fine_q)), length(dpdy(fine_q)));
    let fine = fbm_rot_gradient(fine_q, 2, 0.5, fine_footprint, vec2<f32>(2.0, 2.0));
    let slope = mat.facet_depth * coarse.yzw * scale + mat.micro_strength * fine.yzw;
    let tangent = slope - n * dot(n, slope);
    let normal = normalize(R * normalize(n - tangent));
    let facet = clamp(0.5 + (coarse.x - 0.5) * mat.facet_depth, 0.0, 1.0);
    let color = mix(mat.shade_color, mat.foil_color, 0.65 + 0.35 * facet);
    let resolved = noise_footprint_weight(footprint, vec2<f32>(2.0, 2.0));
    let fine_resolved = noise_footprint_weight(fine_footprint, vec2<f32>(2.0, 2.0));
    let base_roughness = 0.32 - mat.sheen * 0.20 + (1.0 - facet) * 0.18;
    let variance = (1.0 - resolved) * mat.facet_depth * mat.facet_depth
        + (1.0 - fine_resolved) * mat.micro_strength * mat.micro_strength;
    let roughness = clamp(sqrt(base_roughness * base_roughness + variance), 0.08, 0.85);
    let metallic = clamp(0.55 + mat.sheen * 0.4, 0.0, 1.0);
    return lit_n(input, is_front, normal, color, roughness, metallic, vec3<f32>(0.0));
}
