import "lunco://scripting/tools/assembly_builder" as assembly_builder;
import "component_requirements" as component_requirements;
import "lunco://scripting/tools/sysml_requirements" as sysml_requirements;
// The bus gate evaluates actual composed geometry against typed SysML
// Positions and Dimensions. No custom label is accepted as proof of shape.

import "lunco://scripting/tools/assembly_audit" as assembly_audit;

fn visual(name) { "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::" + name }
fn package_name() { "GriffinBusRequirements" }
fn verification_name() { "Verify_GriffinBusRequirements" }
// Test scenes mount the vehicle beneath /World/Griffin1 (the document's
// default prim is World), so verification must query the composed namespace.
fn default_root_path() { "/World/Griffin1/Bus" }
fn _query_ok(record) { record != () && record.ok != false }

fn _native(source, name) {
    sysml_requirements::native_value(source, visual(name))
}

fn _near(a, b, tolerance) { (a - b).abs() <= tolerance }

fn _display_color_matches(prim, expected) {
    if !_query_ok(prim) || !array_is(expected) || expected.len() != 3 { return false; }
    let actual = prim.attrs["primvars:displayColor"];
    if !array_is(actual) || actual.len() != 1 || !array_is(actual[0]) || actual[0].len() != 3 {
        return false;
    }
    for axis in 0..3 {
        if !_near(actual[0][axis], expected[axis], 0.000001) { return false; }
    }
    true
}

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

fn _expected_outer_profile_mesh(dimensions) {
    if dimensions == () || type_of(dimensions) != "Vec3" { return (); }
    let profile_points = griffin_spec::visual_outer_body_profile_coordinates();
    if profile_points.len() != 8 { return (); }
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

fn outward_quad_face_count(points, counts, indices, beam_count) {
    if points.len() != beam_count * 8 || counts.len() != beam_count * 6
        || indices.len() != beam_count * 24 { return 0; }
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

fn outward_profile_prism_face_count(points, counts, indices, profile_count) {
    if points.len() != profile_count * 2 || counts.len() != profile_count + 2
        || indices.len() != profile_count * 6 { return 0; }
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

fn verify_bus(doc, source, bus_root) {
    let checks = [];
    let root = bus_root;
    let root_prim = assembly_builder::composed_query(doc, #{path: root, children: false});
    let frame_prim = assembly_builder::composed_query(doc, #{path: root + "/PerimeterFrame", children: false});
    let deck_prim = assembly_builder::composed_query(doc, #{path: root + "/TopDeckOctagon", children: false});
    let skirt_prim = assembly_builder::composed_query(doc, #{path: root + "/LowerServiceSkirtOctagon", children: false});
    checks.push(component_requirements::assertion("GBC-001-root", "bus", "gbc001",
        verification_name(), _query_ok(root_prim) && root_prim.type_name == "Xform",
        "named Griffin bus root shall resolve as an Xform", root_prim.type_name, "Xform"));
    checks.push(component_requirements::assertion("GBC-001-frame", "bus", "gbc001",
        verification_name(), _query_ok(frame_prim) && frame_prim.type_name == "Mesh",
        "primary octagonal frame shall resolve as a Mesh", frame_prim.type_name, "Mesh"));
    checks.push(component_requirements::assertion("GBC-001-deck", "bus", "gbc001",
        verification_name(), _query_ok(deck_prim) && deck_prim.type_name == "Mesh",
        "outer octagonal deck shall resolve as a Mesh", deck_prim.type_name, "Mesh"));
    checks.push(component_requirements::assertion("GBC-001-skirt", "bus", "gbc001",
        verification_name(), _query_ok(skirt_prim) && skirt_prim.type_name == "Mesh",
        "outer octagonal skirt shall resolve as a Mesh", skirt_prim.type_name, "Mesh"));
    checks.push(component_requirements::coverage("GBC-003-ownership", "bus", "gbc003", verification_name()));
    checks.push(component_requirements::coverage("GBC-004-traceability", "bus", "gbc004", verification_name()));

    let frame = assembly_builder::composed_query(doc,
        #{path: root + "/PerimeterFrame", children: false});
    let frame_points = if _query_ok(frame) { frame.attrs.points } else { [] };
    let frame_counts = if _query_ok(frame) { frame.attrs.faceVertexCounts } else { [] };
    let frame_indices = if _query_ok(frame) { frame.attrs.faceVertexIndices } else { [] };
    let body_dimensions = _native(source, "bodyDimensions");
    let rail_names = griffin_spec::visual_rail_names();
    let ring_y = griffin_spec::visual_frame_ring_center_y_m();
    let beam_count = rail_names.len() * ring_y.len();
    let frame_topology_ok = rail_names.len() == 8 && ring_y.len() == 2
        && frame_points.len() == beam_count * 8 && frame_counts.len() == beam_count * 6
        && frame_indices.len() == beam_count * 24;
    if frame_topology_ok {
        for count in frame_counts { if count != 4 { frame_topology_ok = false; } }
    }
    checks.push(component_requirements::assertion("GBC-008-open-octagonal-frame", "bus",
        "gbc008", verification_name(), frame_topology_ok,
        "frame mesh shall contain two octagonal rings of closed beam solids with quad faces",
        #{points: frame_points.len(), faces: frame_counts.len(), indices: frame_indices.len()},
        #{points: beam_count * 8, faces: beam_count * 6, indices: beam_count * 24}));
    let outward_faces = outward_quad_face_count(frame_points, frame_counts, frame_indices, beam_count);
    checks.push(component_requirements::assertion("GBC-008-outward-faces", "bus",
        "gbc008", verification_name(), outward_faces == beam_count * 6,
        "every authored frame face normal shall point out of its beam solid",
        outward_faces, beam_count * 6));
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
    let rail_dimensions = _native(source, "railDimensions");
    let rail_layout_ok = rails.len() == 8 && rail_names.len() == 8
        && rail_dimensions != () && type_of(rail_dimensions) == "Vec3";
    checks.push(component_requirements::assertion("GBC-007-typed-rail-layout", "bus",
        "gbc007", verification_name(), rail_layout_ok,
        "eight typed SysML rail identities, Position values, and Dimensions shall resolve",
        #{rail_count: rail_names.len(), station_count: rails.len(), dimensions: rail_dimensions},
        #{rail_count: 8, station_count: 8, dimensions: "Vec3"}));
    let rail_geometry_ok = rail_layout_ok;
    let rail_evidence = [];
    if rail_layout_ok {
        for index in 0..rail_names.len() {
            let path = root + "/" + rail_names[index];
            let prim = assembly_builder::composed_query(doc,
                #{path: path, children: false});
            let plan = rails[index];
            let ok = _query_ok(prim) && prim.type_name == "Cube"
                && _transform_matches(prim, plan.translation, plan.scale)
                && prim.attrs.purpose == "render"
                && prim.attrs["physics:collisionEnabled"] == false
                && _display_color_matches(prim, griffin_spec::visual_rail_display_color());
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
        rail_evidence, #{rail_count: 8, dimensions: rail_dimensions}));

    let deck = assembly_builder::composed_query(doc,
        #{path: root + "/TopDeckOctagon", children: false});
    let deck_dims = _native(source, "deckDimensions");
    let deck_center = _native(source, "deckCenter");
    let expected_deck = _expected_outer_profile_mesh(deck_dims);
    let deck_faces = if _query_ok(deck) { outward_profile_prism_face_count(deck.attrs.points,
        deck.attrs.faceVertexCounts, deck.attrs.faceVertexIndices, 8) } else { 0 };
    let deck_ok = _mesh_matches_profile(deck, expected_deck) && deck_faces == 10
        && _mesh_matches_dimensions(deck.attrs.points, deck_dims)
        && _near(deck.attrs["xformOp:translate"][1], deck_center.y, 0.002)
        && deck.attrs.doubleSided == false;
    checks.push(component_requirements::assertion("GBC-006-deck-geometry", "bus",
        "gbc006", verification_name(), deck_ok,
        "deck mesh extents, elevation, winding, and sidedness shall match typed SysML values",
        #{extent: if _query_ok(deck) { _mesh_extent(deck.attrs.points) } else { () },
          center: if _query_ok(deck) { deck.attrs["xformOp:translate"] } else { () },
          outward_faces: deck_faces},
        #{dimensions: deck_dims, center: deck_center, outward_faces: 10}));

    let skirt = assembly_builder::composed_query(doc,
        #{path: root + "/LowerServiceSkirtOctagon", children: false});
    let skirt_dims = _native(source, "lowerSkirtDimensions");
    let skirt_center = _native(source, "lowerSkirtCenter");
    let expected_skirt = _expected_outer_profile_mesh(skirt_dims);
    let skirt_faces = if _query_ok(skirt) { outward_profile_prism_face_count(skirt.attrs.points,
        skirt.attrs.faceVertexCounts, skirt.attrs.faceVertexIndices, 8) } else { 0 };
    let skirt_ok = _mesh_matches_profile(skirt, expected_skirt) && skirt_faces == 10
        && _mesh_matches_dimensions(skirt.attrs.points, skirt_dims)
        && _near(skirt.attrs["xformOp:translate"][1], skirt_center.y, 0.002)
        && skirt.attrs.doubleSided == false;
    checks.push(component_requirements::assertion("GBC-006-skirt-geometry", "bus",
        "gbc006", verification_name(), skirt_ok,
        "skirt mesh extents, elevation, winding, and sidedness shall match typed SysML values",
        #{extent: if _query_ok(skirt) { _mesh_extent(skirt.attrs.points) } else { () },
          center: if _query_ok(skirt) { skirt.attrs["xformOp:translate"] } else { () },
          outward_faces: skirt_faces},
        #{dimensions: skirt_dims, center: skirt_center, outward_faces: 10}));

    let deck_skirt_clearance = assembly_audit::oriented_box_clearance(
        "TopDeckOctagon-to-LowerServiceSkirtOctagon",
        deck_center, deck_dims, quat_identity(),
        skirt_center, skirt_dims, quat_identity(), 0.0);
    checks.push(component_requirements::assertion("GBC-010-deck-skirt-clearance", "bus",
        "gbc010", verification_name(), deck_skirt_clearance.ok == true,
        "typed deck and service-skirt envelopes shall have a positive SAT separation",
        deck_skirt_clearance,
        #{minimum_clearance_m: 0.0, deck_center: deck_center,
          skirt_center: skirt_center}));

    let support = assembly_builder::composed_query(doc,
        #{path: root + "/TankSupportPlate", children: false});
    let support_frame = assembly_builder::composed_query(doc,
        #{path: root + "/TankSupportPlate/TankSupportPerimeter", children: false});
    let tanks = griffin_spec::component_tank_stations();
    let tank_names = griffin_spec::propellant_tank_names();
    let segments = griffin_spec::visual_tank_opening_segments();
    let inner_radius = griffin_spec::visual_tank_opening_inner_radius_m();
    let outer_radius = griffin_spec::visual_tank_opening_outer_radius_m();
    let support_profile = griffin_spec::visual_tank_support_profile_coordinates();
    let support_radius = griffin_spec::visual_tank_support_perimeter_radius_m();
    let support_section = griffin_spec::visual_tank_support_perimeter_section_m();
    let support_center_y = griffin_spec::visual_tank_support_plane_center_y_m();
    let support_points = if _query_ok(support_frame) { support_frame.attrs.points } else { [] };
    let support_counts = if _query_ok(support_frame) { support_frame.attrs.faceVertexCounts } else { [] };
    let support_indices = if _query_ok(support_frame) { support_frame.attrs.faceVertexIndices } else { [] };
    let support_topology_ok = support_profile.len() == 6 && support_radius > 0.0
        && support_section > 0.0 && support_center_y != ()
        && support_points.len() == 48 && support_counts.len() == 36
        && support_indices.len() == 144 && _query_ok(support_frame)
        && support_frame.type_name == "Mesh" && support_frame.attrs.doubleSided == false
        && support_frame.attrs.purpose == "render"
        && support_frame.attrs["physics:collisionEnabled"] == false;
    if support_topology_ok {
        for count in support_counts { if count != 4 { support_topology_ok = false; } }
        for point in support_points {
            if !_near(point[1], support_center_y, support_section / 2.0 + 0.002)
                || point[1] < support_center_y - support_section / 2.0 - 0.002
                || point[1] > support_center_y + support_section / 2.0 + 0.002 {
                support_topology_ok = false;
            }
        }
    }
    let support_outward = if support_topology_ok {
        outward_quad_face_count(support_points, support_counts, support_indices, 6)
    } else { 0 };
    support_topology_ok = support_topology_ok && support_outward == 36
        && _display_color_matches(support_frame, griffin_spec::visual_tank_support_display_color());
    checks.push(component_requirements::assertion("GBC-011-six-sided-support-frame", "bus",
        "gbc011", verification_name(), support_topology_ok,
        "six-sided tank support shall be six outward-wound quad beam solids at the typed plane and section, render-only and source-colored",
        #{points: support_points.len(), faces: support_counts.len(), indices: support_indices.len(),
          outward_faces: support_outward, color: if _query_ok(support_frame) { support_frame.attrs["primvars:displayColor"] } else { () }},
        #{points: 48, faces: 36, indices: 144, outward_faces: 36,
          center_y_m: support_center_y, section_m: support_section,
          color: griffin_spec::visual_tank_support_display_color()}));
    let opening_evidence = [];
    let openings_ok = _query_ok(support) && support.type_name == "Xform"
        && support_topology_ok
        && tanks.len() == 4 && tank_names.len() == 4 && segments >= 8
        && inner_radius > 0.0 && outer_radius > inner_radius;
    let mut_openings_ok = openings_ok;
    if openings_ok {
        for index in 0..tanks.len() {
            let path = root + "/TankSupportPlate/Opening" + tank_names[index];
            let opening = assembly_builder::composed_query(doc,
                #{path: path, children: false});
            let points = if _query_ok(opening) { opening.attrs.points } else { [] };
            let face_counts = if _query_ok(opening) { opening.attrs.faceVertexCounts } else { [] };
            let face_indices = if _query_ok(opening) { opening.attrs.faceVertexIndices } else { [] };
            let expected_topology = _query_ok(opening) && opening.type_name == "Mesh"
                && points.len() == 4 * segments && face_counts.len() == 4 * segments
                && face_indices.len() == 16 * segments;
            let bore_matches_station = expected_topology
                && _near(points[2 * segments][0], tanks[index].x + inner_radius, 0.002)
                && _near(points[2 * segments][2], tanks[index].z, 0.002);
            let radial_envelope_matches = expected_topology;
            if radial_envelope_matches {
                for point_index in 0..points.len() {
                    let dx = points[point_index][0] - tanks[index].x;
                    let dz = points[point_index][2] - tanks[index].z;
                    let radius = sqrt(dx * dx + dz * dz);
                    let expected_radius = if point_index < 2 * segments { outer_radius } else { inner_radius };
                    if !_near(radius, expected_radius, 0.002) { radial_envelope_matches = false; }
                }
            }
            let quad_faces = expected_topology;
            if quad_faces { for count in face_counts { if count != 4 { quad_faces = false; } } }
            let valid = expected_topology && bore_matches_station && radial_envelope_matches && quad_faces
                && opening.attrs["physics:collisionEnabled"] == false;
            mut_openings_ok = mut_openings_ok && valid;
            opening_evidence.push(#{tank: tank_names[index], path: path,
                points: points.len(), faces: face_counts.len(), indices: face_indices.len(),
                bore_matches_station: bore_matches_station, radial_envelope_matches: radial_envelope_matches,
                quad_faces: quad_faces, ok: valid});
        }
    }
    checks.push(component_requirements::assertion("GBC-011-four-tank-openings", "bus",
        "gbc011", verification_name(), mut_openings_ok,
        "four render-only annular meshes shall match typed inner and outer radii and remain concentric with tank stations",
        opening_evidence,
        #{count: 4, segments_per_bore: segments, inner_radius_m: inner_radius,
          outer_radius_m: outer_radius, all_bores_open: true}));

    let source_colors_match = _display_color_matches(frame, griffin_spec::visual_frame_display_color())
        && _display_color_matches(deck, griffin_spec::visual_deck_display_color())
        && _display_color_matches(skirt, griffin_spec::visual_lower_skirt_display_color())
        && _display_color_matches(support_frame, griffin_spec::visual_tank_support_display_color());
    checks.push(component_requirements::assertion("GBC-012-source-owned-colors", "bus",
        "gbc012", verification_name(), source_colors_match,
        "frame, deck, and skirt displayColor shall match the single SysML palette",
        #{frame: if _query_ok(frame) { frame.attrs["primvars:displayColor"] } else { () },
          deck: if _query_ok(deck) { deck.attrs["primvars:displayColor"] } else { () },
          skirt: if _query_ok(skirt) { skirt.attrs["primvars:displayColor"] } else { () }},
        #{frame: griffin_spec::visual_frame_display_color(),
          deck: griffin_spec::visual_deck_display_color(),
          skirt: griffin_spec::visual_lower_skirt_display_color()}));

    let legacy_names = griffin_spec::legacy_bus_prim_names();
    let legacy_absent = true;
    let legacy_evidence = [];
    for legacy_name in legacy_names {
        let legacy = assembly_builder::composed_query(doc,
            #{path: root + "/" + legacy_name, children: false});
        let absent = legacy == () || legacy.ok == false;
        legacy_absent = legacy_absent && absent;
        legacy_evidence.push(#{name: legacy_name, absent: absent,
            type_name: if _query_ok(legacy) { legacy.type_name } else { () }});
    }
    checks.push(component_requirements::assertion("GBC-009-legacy-geometry-removed", "bus",
        "gbc009", verification_name(), legacy_absent,
        "legacy hex panels, rails, and duplicate solids shall be absent from the composed bus",
        legacy_evidence, #{legacy_names: legacy_names, all_absent: true}));

    let result = component_requirements::finish(source, checks,
        "GRIFFIN BUS REQUIREMENTS", "GRIFFIN_BUS_REQUIREMENTS", root,
        package_name(), verification_name());
    result
}
