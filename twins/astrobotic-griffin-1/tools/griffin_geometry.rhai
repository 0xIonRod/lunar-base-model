// Shared Griffin parametric mesh construction used by both the Editor
// builder and the read-only requirement observer. The source datums are
// inputs; this module supplies the deterministic geometric realization.

fn scalar_is_finite(value) {
    let scalar = f64_from(value);
    if scalar == () { return false; }
    scalar == scalar && scalar < 1.7976931348623157e308
        && scalar > -1.7976931348623157e308
}

// Build a watertight centered box as a Mesh using native f64 profile
// extrusion. The caller may position it by supplying a component-local centre.
fn rectangular_prism_geometry(center, dimensions) {
    if !vec3_is_native(center) || !vec3_is_finite(center)
        || !vec3_is_native(dimensions) || !vec3_is_finite(dimensions)
        || dimensions.x <= 0.0 || dimensions.y <= 0.0 || dimensions.z <= 0.0 {
        return #{ok: false, error: "rectangular prism requires finite center and positive dimensions"};
    }
    let half_x = dimensions.x / 2.0;
    let half_z = dimensions.z / 2.0;
    let profile = [vec2(-half_x, -half_z), vec2(half_x, -half_z),
        vec2(half_x, half_z), vec2(-half_x, half_z)];
    let mesh = extrude_profile(profile, dimensions.y, profile_plane_xz());
    let points = [];
    for point in mesh.points {
        points.push([point.x + center.x, point.y + center.y, point.z + center.z]);
    }
    #{ok: true, points: points, face_counts: mesh.face_vertex_counts,
      face_indices: mesh.face_vertex_indices}
}

// Join independently generated closed meshes into one USD Mesh without
// changing their local geometry or storing mesh values as numeric strings.
fn merge_mesh_geometries(parts) {
    if !array_is(parts) || parts.is_empty() {
        return #{ok: false, error: "mesh merge requires at least one geometry"};
    }
    let points = [];
    let face_counts = [];
    let face_indices = [];
    for part in parts {
        if part == () || part.ok != true || part.points == ()
            || part.face_counts == () || part.face_indices == () {
            return #{ok: false, error: "mesh merge input is incomplete"};
        }
        let base = points.len();
        for point in part.points { points.push(point); }
        for count in part.face_counts { face_counts.push(count); }
        for index in part.face_indices { face_indices.push(index + base); }
    }
    #{ok: true, points: points, face_counts: face_counts,
      face_indices: face_indices}
}

fn perimeter_beam_geometry(stations, ring_y, section) {
    if !array_is(stations) || stations.len() < 3
        || !array_is(ring_y) || ring_y.len() == 0
        || section == () || section <= 0.0 {
        return #{ok: false, error: "perimeter mesh requires stations, ring planes, and positive section"};
    }
    for station in stations {
        if !vec3_is_native(station) || !vec3_is_finite(station) {
            return #{ok: false, error: "perimeter stations must be finite typed Vec3 values"};
        }
    }
    for center_y in ring_y {
        if !scalar_is_finite(center_y) {
            return #{ok: false, error: "perimeter ring planes must be finite values"};
        }
    }

    let points = [];
    let face_counts = [];
    let face_indices = [];
    let half_section = section / 2.0;
    for ring_index in 0..ring_y.len() {
        for edge in 0..stations.len() {
            let start_index = edge;
            let end_index = (edge + 1) % stations.len();
            let ax = stations[start_index].x;
            let az = stations[start_index].z;
            let bx = stations[end_index].x;
            let bz = stations[end_index].z;
            let dx = bx - ax;
            let dz = bz - az;
            let length = (dx * dx + dz * dz).sqrt();
            if length <= 0.0 {
                return #{ok: false, error: "perimeter contains a zero-length edge"};
            }
            let tx = dx / length;
            let tz = dz / length;
            let nx = -tz;
            let nz = tx;
            let mx = (ax + bx) / 2.0;
            let mz = (az + bz) / 2.0;
            let half_length = length / 2.0;
            let cy = ring_y[ring_index];
            let base = points.len();
            for vertex in [
                [-tx * half_length - nx * half_section, cy - half_section, -tz * half_length - nz * half_section],
                [ tx * half_length - nx * half_section, cy - half_section,  tz * half_length - nz * half_section],
                [ tx * half_length - nx * half_section, cy + half_section,  tz * half_length - nz * half_section],
                [-tx * half_length - nx * half_section, cy + half_section, -tz * half_length - nz * half_section],
                [-tx * half_length + nx * half_section, cy - half_section, -tz * half_length + nz * half_section],
                [ tx * half_length + nx * half_section, cy - half_section,  tz * half_length + nz * half_section],
                [ tx * half_length + nx * half_section, cy + half_section,  tz * half_length + nz * half_section],
                [-tx * half_length + nx * half_section, cy + half_section, -tz * half_length + nz * half_section]
            ] {
                points.push([mx + vertex[0], vertex[1], mz + vertex[2]]);
            }
            for face in 0..6 { face_counts.push(4); }
            for index in [0, 4, 7, 3, 1, 2, 6, 5, 0, 3, 2, 1,
                4, 5, 6, 7, 0, 1, 5, 4, 3, 7, 6, 2] {
                face_indices.push(base + index);
            }
        }
    }
    #{ok: true, points: points, face_counts: face_counts,
      face_indices: face_indices, face_vertex_counts: face_counts,
      face_vertex_indices: face_indices}
}

fn tank_support_perimeter_geometry(profile, radius, center_y, section) {
    if !array_is(profile) || profile.len() < 3
        || radius == () || radius <= 0.0 || center_y == ()
        || section == () || section <= 0.0 {
        return #{ok: false, error: "tank-support profile requires typed points and positive radius/section"};
    }
    let stations = [];
    for point in profile {
        if !vec2_is_native(point) || !vec2_is_finite(point) {
            return #{ok: false, error: "tank-support profile requires finite typed Vec2 values"};
        }
        stations.push(vec3(point.x * radius, 0.0, point.y * radius));
    }
    let levels = if array_is(center_y) { center_y } else { [center_y] };
    perimeter_beam_geometry(stations, levels, section)
}
