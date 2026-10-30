import bevy_pbr::render::forward_io::VertexOutput;
import bevy_pbr::render::mesh_functions;
import lunco::shaders::pbr_lit::lit;

//! CAD already supplies individual cells and gaps. Add only fine electrodes.
//! No UV dependency: supplier CAD meshes have no primvars:st.
//!@ui cell_color color "Cell face colour"
//!@default cell_color 0.018,0.035,0.075
//!@ui electrode_color color "Electrode colour"
//!@default electrode_color 0.32,0.36,0.42
//!@ui roughness 0 1 "Coverglass roughness"
//!@default roughness 0.24
//!@ui metallic 0 1 "Reflectance study"
//!@default metallic 0.28
//!@ui pitch 0.001 0.02 "Electrode pitch metres"
//!@default pitch 0.006
//!@ui width 0.00001 0.001 "Electrode width metres"
//!@default width 0.00012
struct Material {
    cell_color: vec3<f32>,
    roughness: f32,
    electrode_color: vec3<f32>,
    metallic: f32,
    pitch: f32,
    width: f32,
}
@group(constants::MATERIAL_BIND_GROUP) @binding(0)
var<uniform> mat: Material;

// Integral of a unit-period rectangular electrode. Subtracting two samples
// gives its exact coverage over the pixel's derivative-estimated box footprint.
// Thin lines keep their area as they become subpixel instead of fattening or
// disappearing through an arbitrary smoothstep transition.
fn electrode_integral(u: f32, duty: f32) -> f32 {
    return floor(u) * duty + min(fract(u), duty);
}
@fragment
fn fragment(input: VertexOutput, @builtin(front_facing) is_front: bool) -> @location(0) vec4<f32> {
    let m = mesh_functions::get_world_from_local(input.instance_index);
    let R = mat3x3<f32>(normalize(m[0].xyz), normalize(m[1].xyz), normalize(m[2].xyz));
    let p = transpose(R) * (input.world_position.xyz - m[3].xyz);
    let pitch = max(mat.pitch, 0.0001);
    let duty = clamp(mat.width / pitch, 0.0, 1.0);
    let u = p.z / pitch + duty * 0.5;
    let footprint = max(fwidth(u), 0.0001);
    let coverage = clamp((electrode_integral(u + footprint * 0.5, duty)
        - electrode_integral(u - footprint * 0.5, duty)) / footprint, 0.0, 1.0);
    let color = mix(mat.cell_color, mat.electrode_color, coverage);
    return lit(input, is_front, color, mat.roughness, mat.metallic, vec3<f32>(0.0));
}
