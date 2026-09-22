// The bus gate evaluates actual composed geometry against typed SysML
// Positions and Dimensions. No custom label is accepted as proof of shape.

import "lunco://scripting/tools/assembly_audit" as assembly_audit;

fn visual(name) { "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::" + name }
fn package_name() { "GriffinBusRequirements" }
fn verification_name() { "Verify_GriffinBusRequirements" }
// Test scenes mount the vehicle beneath /World/Griffin1 (the document's
// default prim is World), so verification must query the composed namespace.
fn root_path() { "/World/Griffin1/Bus" }
fn _query_ok(record) { record != () && record.ok != false }

fn _native(source, name) {
    let resolved = sysml_requirements::attribute(source, visual(name));
    if resolved.ok != true || resolved.record.typed_value == () { return (); }
    resolved.record.typed_value
}

fn _near(a, b, tolerance) { (a - b).abs() <= tolerance }

fn _mesh_extent(points) {
    if points == () || points.len() == 0 { return (); }
    let low = [points[0][0], points[0][1], points[0][2]];
    let high = [points[0][0], points[0][1], points[0][2]];
    for point in points {
        for axis in 0..3 {
            if point[axis] < low[axis] { low[axis] = point[axis]; }
            if point[axis] > high[axis] { high[axis] = point[axis]; }
        }
    }
    [high[0] - low[0], high[1] - low[1], high[2] - low[2]]
}

fn _mesh_matches_dimensions(points, dimensions) {
    if dimensions == () || type_of(dimensions) != "Vec3" { return false; }
    let extent = _mesh_extent(points);
    extent != () && _near(extent[0], dimensions.x, 0.002)
        && _near(extent[1], dimensions.y, 0.002)
        && _near(extent[2], dimensions.z, 0.002)
}

fn _expected_hex_profile_mesh(dimensions) {
    if dimensions == () || type_of(dimensions) != "Vec3" { return (); }
    let profile_points = griffin_spec::visual_hex_profile_coordinates();
    if profile_points.len() != 6 { return (); }
    let scaled = [];
    for point in profile_points {
        if type_of(point) != "Vec2" || !vec2_is_finite(point) { return (); }
        scaled.push(vec2(point.x * dimensions.x / 2.0,
            point.y * dimensions.z / 2.0));
    }
    extrude_profile(scaled, dimensions.y, profile_plane_xz())
}

fn _mesh_matches_profile(prim, expected) {
    if !_query_ok(prim) || expected == () || prim.type_name != "Mesh"
        || prim.attrs.points == () || prim.attrs.faceVertexCounts == ()
        || prim.attrs.faceVertexIndices == () || prim.attrs.doubleSided != false {
        return false;
    }
    let points = expected.points;
    let counts = expected.face_vertex_counts;
    let indices = expected.face_vertex_indices;
    if prim.attrs.points.len() != points.len()
        || prim.attrs.faceVertexCounts.len() != counts.len()
        || prim.attrs.faceVertexIndices.len() != indices.len() {
        return false;
    }
    for index in 0..counts.len() {
        if prim.attrs.faceVertexCounts[index] != counts[index] { return false; }
    }
    for index in 0..indices.len() {
        if prim.attrs.faceVertexIndices[index] != indices[index] { return false; }
    }
    for index in 0..points.len() {
        for axis in 0..3 {
            if !_near(prim.attrs.points[index][axis],
                if axis == 0 { points[index].x } else if axis == 1 {
                    points[index].y
                } else { points[index].z }, 0.002) {
                return false;
            }
        }
    }
    true
}

fn _transform_matches(prim, position, scale) {
    if prim == () || prim.ok == false || prim.attrs == () { return false; }
    let translation = prim.attrs["xformOp:translate"];
    let actual_scale = prim.attrs["xformOp:scale"];
    translation != () && actual_scale != () && position != () && scale != ()
        && translation.len() == 3 && actual_scale.len() == 3
        && _near(translation[0], position.x, 0.002)
        && _near(translation[1], position.y, 0.002)
        && _near(translation[2], position.z, 0.002)
        && _near(actual_scale[0], scale.x, 0.002)
        && _near(actual_scale[1], scale.y, 0.002)
        && _near(actual_scale[2], scale.z, 0.002)
}

fn outward_quad_face_count(points, counts, indices) {
    if points.len() != 96 || counts.len() != 72 || indices.len() != 288 { return 0; }
    let outward = 0;
    for face in 0..counts.len() {
        if counts[face] != 4 { continue; }
        let offset = face * 4;
        let a = points[indices[offset]];
        let b = points[indices[offset + 1]];
        let c = points[indices[offset + 2]];
        let d = points[indices[offset + 3]];
        let ux = b[0] - a[0]; let uy = b[1] - a[1]; let uz = b[2] - a[2];
        let vx = c[0] - a[0]; let vy = c[1] - a[1]; let vz = c[2] - a[2];
        let nx = uy * vz - uz * vy;
        let ny = uz * vx - ux * vz;
        let nz = ux * vy - uy * vx;
        let fx = (a[0] + b[0] + c[0] + d[0]) / 4.0;
        let fy = (a[1] + b[1] + c[1] + d[1]) / 4.0;
        let fz = (a[2] + b[2] + c[2] + d[2]) / 4.0;
        let beam = (face / 6).to_int() * 8;
        let cx = 0.0; let cy = 0.0; let cz = 0.0;
        for vertex in 0..8 {
            cx += points[beam + vertex][0] / 8.0;
            cy += points[beam + vertex][1] / 8.0;
            cz += points[beam + vertex][2] / 8.0;
        }
        if nx * (fx - cx) + ny * (fy - cy) + nz * (fz - cz) > 0.0 { outward += 1; }
    }
    outward
}

fn outward_hex_prism_face_count(points, counts, indices) {
    if points.len() != 12 || counts.len() != 8 || indices.len() != 36 { return 0; }
    let centroid = [0.0, 0.0, 0.0];
    for point in points {
        for axis in 0..3 { centroid[axis] += point[axis] / points.len(); }
    }
    let outward = 0;
    let offset = 0;
    for face in 0..counts.len() {
        let count = counts[face].to_int();
        if count < 3 { return 0; }
        let a = points[indices[offset]];
        let b = points[indices[offset + 1]];
        let c = points[indices[offset + 2]];
        let ux = b[0] - a[0]; let uy = b[1] - a[1]; let uz = b[2] - a[2];
        let vx = c[0] - a[0]; let vy = c[1] - a[1]; let vz = c[2] - a[2];
        let nx = uy * vz - uz * vy;
        let ny = uz * vx - ux * vz;
        let nz = ux * vy - uy * vx;
        let face_center = [0.0, 0.0, 0.0];
        for vertex in 0..count {
            let point = points[indices[offset + vertex]];
            for axis in 0..3 { face_center[axis] += point[axis] / count; }
        }
        if nx * (face_center[0] - centroid[0])
            + ny * (face_center[1] - centroid[1])
            + nz * (face_center[2] - centroid[2]) > 0.0 { outward += 1; }
        offset += count;
    }
    outward
}

fn verify_bus(doc, source) {
    let checks = [];
    checks.push(component_requirements::exists("GBC-001-root", "bus", "gbc001",
        verification_name(), root_path(), "Xform"));
    checks.push(component_requirements::exists("GBC-001-frame", "bus", "gbc001",
        verification_name(), root_path() + "/PerimeterFrame", "Mesh"));
    checks.push(component_requirements::exists("GBC-001-deck", "bus", "gbc001",
        verification_name(), root_path() + "/TopDeckHex", "Mesh"));
    checks.push(component_requirements::exists("GBC-001-skirt", "bus", "gbc001",
        verification_name(), root_path() + "/LowerServiceSkirtHex", "Mesh"));
    checks.push(component_requirements::coverage("GBC-003-ownership", "bus", "gbc003", verification_name()));
    checks.push(component_requirements::coverage("GBC-004-traceability", "bus", "gbc004", verification_name()));

    let frame = assembly_builder::composed_query(doc,
        #{path: root_path() + "/PerimeterFrame", children: false});
    let frame_points = if _query_ok(frame) { frame.attrs.points } else { [] };
    let frame_counts = if _query_ok(frame) { frame.attrs.faceVertexCounts } else { [] };
    let frame_indices = if _query_ok(frame) { frame.attrs.faceVertexIndices } else { [] };
    let body_dimensions = _native(source, "bodyDimensions");
    let frame_topology_ok = frame_points.len() == 96 && frame_counts.len() == 72
        && frame_indices.len() == 288;
    if frame_topology_ok {
        for count in frame_counts { if count != 4 { frame_topology_ok = false; } }
    }
    checks.push(component_requirements::assertion("GBC-008-open-hex-frame", "bus",
        "gbc008", verification_name(), frame_topology_ok,
        "frame mesh shall contain twelve closed beam solids with quad faces",
        #{points: frame_points.len(), faces: frame_counts.len(), indices: frame_indices.len()},
        #{points: 96, faces: 72, indices: 288}));
    let outward_faces = outward_quad_face_count(frame_points, frame_counts, frame_indices);
    checks.push(component_requirements::assertion("GBC-008-outward-faces", "bus",
        "gbc008", verification_name(), outward_faces == 72,
        "every authored frame face normal shall point out of its beam solid",
        outward_faces, 72));
    checks.push(component_requirements::assertion("GBC-005-frame-envelope", "bus",
        "gbc005", verification_name(), _mesh_matches_dimensions(frame_points, body_dimensions),
        "measured frame mesh extents shall match typed SysML body Dimensions",
        _mesh_extent(frame_points), body_dimensions));
    let single_sided = _query_ok(frame) && frame.attrs.doubleSided == false;
    checks.push(component_requirements::assertion("GBC-008-single-sided", "bus",
        "gbc008", verification_name(), single_sided,
        "frame mesh shall render single-sided with its authored outward winding",
        if _query_ok(frame) { frame.attrs.doubleSided } else { () }, false));

    let rails = griffin_spec::visual_rail_station_plan();
    let rail_names = griffin_spec::visual_rail_names();
    let rail_dimensions = _native(source, "railDimensions");
    let rail_layout_ok = rails.len() == 6 && rail_names.len() == 6
        && rail_dimensions != () && type_of(rail_dimensions) == "Vec3";
    checks.push(component_requirements::assertion("GBC-007-typed-rail-layout", "bus",
        "gbc007", verification_name(), rail_layout_ok,
        "six typed SysML rail identities, Position values, and Dimensions shall resolve",
        #{rail_count: rail_names.len(), station_count: rails.len(), dimensions: rail_dimensions},
        #{rail_count: 6, station_count: 6, dimensions: "Vec3"}));
    let rail_geometry_ok = rail_layout_ok;
    let rail_evidence = [];
    if rail_layout_ok {
        for index in 0..rail_names.len() {
            let path = root_path() + "/" + rail_names[index];
            let prim = assembly_builder::composed_query(doc,
                #{path: path, children: false});
            let plan = rails[index];
            let ok = _query_ok(prim) && prim.type_name == "Cube"
                && _transform_matches(prim, plan.translation, plan.scale)
                && prim.attrs.purpose == "render"
                && prim.attrs["physics:collisionEnabled"] == false;
            rail_geometry_ok = rail_geometry_ok && ok;
            rail_evidence.push(#{name: rail_names[index], type_name: prim.type_name,
                translation: if _query_ok(prim) { prim.attrs["xformOp:translate"] } else { () },
                scale: if _query_ok(prim) { prim.attrs["xformOp:scale"] } else { () },
                expected_pose: plan.pose, ok: ok});
        }
    }
    checks.push(component_requirements::assertion("GBC-007-rail-geometry", "bus",
        "gbc007", verification_name(), rail_geometry_ok,
        "each rail Cube transform shall match its typed Position and Dimensions plan",
        rail_evidence, #{rail_count: 6, dimensions: rail_dimensions}));

    let deck = assembly_builder::composed_query(doc,
        #{path: root_path() + "/TopDeckHex", children: false});
    let deck_dims = _native(source, "deckDimensions");
    let deck_center = _native(source, "deckCenter");
    let expected_deck = _expected_hex_profile_mesh(deck_dims);
    let deck_faces = if _query_ok(deck) { outward_hex_prism_face_count(deck.attrs.points,
        deck.attrs.faceVertexCounts, deck.attrs.faceVertexIndices) } else { 0 };
    let deck_ok = _mesh_matches_profile(deck, expected_deck) && deck_faces == 8
        && _mesh_matches_dimensions(deck.attrs.points, deck_dims)
        && _near(deck.attrs["xformOp:translate"][1], deck_center.y, 0.002)
        && deck.attrs.doubleSided == false;
    checks.push(component_requirements::assertion("GBC-006-deck-geometry", "bus",
        "gbc006", verification_name(), deck_ok,
        "deck mesh extents, elevation, winding, and sidedness shall match typed SysML values",
        #{extent: if _query_ok(deck) { _mesh_extent(deck.attrs.points) } else { () },
          center: if _query_ok(deck) { deck.attrs["xformOp:translate"] } else { () },
          outward_faces: deck_faces},
        #{dimensions: deck_dims, center: deck_center, outward_faces: 8}));

    let skirt = assembly_builder::composed_query(doc,
        #{path: root_path() + "/LowerServiceSkirtHex", children: false});
    let skirt_dims = _native(source, "lowerSkirtDimensions");
    let skirt_center = _native(source, "lowerSkirtCenter");
    let expected_skirt = _expected_hex_profile_mesh(skirt_dims);
    let skirt_faces = if _query_ok(skirt) { outward_hex_prism_face_count(skirt.attrs.points,
        skirt.attrs.faceVertexCounts, skirt.attrs.faceVertexIndices) } else { 0 };
    let skirt_ok = _mesh_matches_profile(skirt, expected_skirt) && skirt_faces == 8
        && _mesh_matches_dimensions(skirt.attrs.points, skirt_dims)
        && _near(skirt.attrs["xformOp:translate"][1], skirt_center.y, 0.002)
        && skirt.attrs.doubleSided == false;
    checks.push(component_requirements::assertion("GBC-006-skirt-geometry", "bus",
        "gbc006", verification_name(), skirt_ok,
        "skirt mesh extents, elevation, winding, and sidedness shall match typed SysML values",
        #{extent: if _query_ok(skirt) { _mesh_extent(skirt.attrs.points) } else { () },
          center: if _query_ok(skirt) { skirt.attrs["xformOp:translate"] } else { () },
          outward_faces: skirt_faces},
        #{dimensions: skirt_dims, center: skirt_center, outward_faces: 8}));

    let deck_skirt_clearance = assembly_audit::oriented_box_clearance(
        "TopDeckHex-to-LowerServiceSkirtHex",
        deck_center, deck_dims, quat_identity(),
        skirt_center, skirt_dims, quat_identity(), 0.0);
    checks.push(component_requirements::assertion("GBC-010-deck-skirt-clearance", "bus",
        "gbc010", verification_name(), deck_skirt_clearance.ok == true,
        "typed deck and service-skirt envelopes shall have a positive SAT separation",
        deck_skirt_clearance,
        #{minimum_clearance_m: 0.0, deck_center: deck_center,
          skirt_center: skirt_center}));

    let panel_names = griffin_spec::visual_frame_open_bay_panel_names();
    let open_bays = panel_names.len() == 6;
    let bay_evidence = [];
    if panel_names.len() == 6 {
        for panel_name in panel_names {
            let panel = assembly_builder::composed_query(doc,
                #{path: root_path() + "/" + panel_name, children: false});
            let clear = _query_ok(panel) && panel.active == false;
            open_bays = open_bays && clear;
            bay_evidence.push(#{panel: panel_name, active: if _query_ok(panel) { panel.active } else { () },
                clear: clear});
        }
    }
    checks.push(component_requirements::assertion("GBC-009-open-bays", "bus",
        "gbc009", verification_name(), open_bays,
        "all six typed side-panel parts shall be inactive in the open-frame review configuration",
        bay_evidence, #{panel_count: 6, active: false}));

    let result = component_requirements::finish(source, checks,
        "GRIFFIN BUS REQUIREMENTS", "GRIFFIN_BUS_REQUIREMENTS", root_path(),
        package_name(), verification_name());
    result
}
