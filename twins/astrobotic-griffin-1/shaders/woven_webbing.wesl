import bevy_pbr::render::forward_io::VertexOutput;
import bevy_pbr::render::mesh_functions;
import lunco::shaders::pbr_lit::lit_n;

//! Rest-routing fabric appearance. Weave is illustrative, not a fiber identity.
//! Object-fixed metric Y/Z coordinates suit the thin-X webbing cubes.
//! No emission, ambient term or added illumination.
//!@ui base_color color "Fabric colour"
//!@default base_color 0.30,0.28,0.24
//!@ui roughness 0 1 "Roughness"
//!@default roughness 0.78
//!@ui weave_pitch 0.0001 0.01 "Weave pitch metres"
//!@default weave_pitch 0.0009
//!@ui normal_strength 0 0.3 "Weave normal strength"
//!@default normal_strength 0.10
struct Material {
    base_color: vec3<f32>,
    roughness: f32,
    weave_pitch: f32,
    normal_strength: f32,
}
@group(constants::MATERIAL_BIND_GROUP) @binding(0)
var<uniform> mat: Material;

@fragment
fn fragment(input: VertexOutput, @builtin(front_facing) is_front: bool) -> @location(0) vec4<f32> {
    let m = mesh_functions::get_world_from_local(input.instance_index);
    let R = mat3x3<f32>(normalize(m[0].xyz), normalize(m[1].xyz), normalize(m[2].xyz));
    let p = transpose(R) * (input.world_position.xyz - m[3].xyz);
    let n = normalize(transpose(R) * normalize(input.world_normal));
    let q = p.yz / max(mat.weave_pitch, 0.0001);
    let footprint = max(length(dpdx(q)), length(dpdy(q)));
    let resolved = 1.0 - smoothstep(0.20, 0.75, footprint);
    let phase = q * 6.28318530718;
    let warp = sin(phase.x) * cos(phase.y);
    let gradient = vec3<f32>(0.0, cos(phase.x) * cos(phase.y), -sin(phase.x) * sin(phase.y));
    let tangent = gradient - n * dot(n, gradient);
    let normal = normalize(R * normalize(n - mat.normal_strength * resolved * tangent));
    let color = mat.base_color * (1.0 + 0.025 * resolved * warp);
    let roughness = clamp(mat.roughness + (1.0 - resolved) * 0.02, 0.05, 0.95);
    return lit_n(input, is_front, normal, color, roughness, 0.0, vec3<f32>(0.0));
}
