import bevy_pbr::render::forward_io::VertexOutput;
import bevy_pbr::render::mesh_functions;
import lunco::shaders::pbr_lit::lit_n;
import lunco::shaders::lunco_noise::{fbm_rot_gradient, noise_footprint_weight};

//! Object-fixed spacecraft finishes. Appearance only; no thermal coefficients.
//! Fine grain is filtered into roughness when it becomes subpixel in video.
//!@ui base_color color "Surface colour"
//!@default base_color 0.55,0.58,0.62
//!@ui metallic 0 1 "Metallic"
//!@default metallic 0.8
//!@ui roughness 0 1 "Roughness"
//!@default roughness 0.32
//!@ui grain_scale 1 500 "Grain per metre"
//!@default grain_scale 160
//!@ui grain_strength 0 0.2 "Grain strength"
//!@default grain_strength 0.035
//!@ui brush_ratio 1 16 "Brushing ratio"
//!@default brush_ratio 6
struct Material {
    base_color: vec3<f32>,
    metallic: f32,
    roughness: f32,
    grain_scale: f32,
    grain_strength: f32,
    brush_ratio: f32,
}
@group(constants::MATERIAL_BIND_GROUP) @binding(0)
var<uniform> mat: Material;

@fragment
fn fragment(input: VertexOutput, @builtin(front_facing) is_front: bool) -> @location(0) vec4<f32> {
    let m = mesh_functions::get_world_from_local(input.instance_index);
    let R = mat3x3<f32>(normalize(m[0].xyz), normalize(m[1].xyz), normalize(m[2].xyz));
    let p = transpose(R) * (input.world_position.xyz - m[3].xyz);
    let n = normalize(transpose(R) * normalize(input.world_normal));
    let stretch = vec3<f32>(1.0, 1.0 / max(mat.brush_ratio, 1.0), 1.0);
    let q = p * mat.grain_scale * stretch;
    let footprint = max(length(dpdx(q)), length(dpdy(q)));
    let grain = fbm_rot_gradient(q, 2, 0.5, footprint, vec2<f32>(1.0, 2.0));
    let gradient = grain.yzw * stretch;
    let tangent = gradient - n * dot(n, gradient);
    let normal = normalize(R * normalize(n - mat.grain_strength * tangent));
    let resolved = noise_footprint_weight(footprint, vec2<f32>(1.0, 2.0));
    let roughness = clamp(mat.roughness + mat.grain_strength * (grain.x - 0.5)
        + (1.0 - resolved) * mat.grain_strength * 0.5, 0.08, 0.95);
    let color = mat.base_color * (1.0 + (grain.x - 0.5) * mat.grain_strength);
    return lit_n(input, is_front, normal, color, roughness, mat.metallic, vec3<f32>(0.0));
}
