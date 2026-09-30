import "lunco://scripting/tools/assembly_builder" as assembly_builder;
import "griffin_geometry" as griffin_geometry;
import "usd_geometry_inspection" as usd_geometry_inspection;
import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
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

fn _visual_attribute_check(id, requirement, path, attr, source_attr, model) {
    let check = #{id: id, component: "bus", requirement: requirement,
        verification: verification_name(), kind: "attribute", path: path,
        attr: attr, expected_attr: visual(source_attr)};
    if attr == "purpose" {
        check.remove("expected_attr");
        check.expected = usd_geometry_inspection::purpose_token(model.value(visual(source_attr)));
    }
    check
}

fn _model_names(model, name) {
    let result = [];
    for value in model.value(visual(name)) {
        result.push(if sysml_enum_is(value) { value.literal } else { value });
    }
    result
}

fn _native(source, name) {
    sysml_requirements::native_value(source, visual(name))
}

fn _max_number(left, right) { if left > right { left } else { right } }
fn _min_count(left, right) { if left < right { left } else { right } }

fn _point_component(point, axis) {
    if vec3_is_native(point) {
        if axis == 0 { return point.x; }
        if axis == 1 { return point.y; }
        if axis == 2 { return point.z; }
        return ();
    }
    if array_is(point) && point.len() == 3 && axis >= 0 && axis < 3 {
        return point[axis];
    }
    ()
}

fn _display_color_error(prim, expected) {
    if !_query_ok(prim) || !array_is(expected) || expected.len() != 3 { return (); }
    let actual = prim.attrs["primvars:displayColor"];
    if !array_is(actual) || actual.len() != 1 || !array_is(actual[0]) || actual[0].len() != 3 {
        return ();
    }
    let error = 0.0;
    for axis in 0..3 {
        let difference = (actual[0][axis] - expected[axis]).abs();
        if difference > error { error = difference; }
    }
    error
}

fn _mesh_extent(points) {
    if points == () || points.len() == 0 { return (); }
    let low = [_point_component(points[0], 0), _point_component(points[0], 1),
        _point_component(points[0], 2)];
    if low[0] == () || low[1] == () || low[2] == () { return (); }
    let high = [low[0], low[1], low[2]];
    for point in points {
        for axis in 0..3 {
            let value = _point_component(point, axis);
            if value == () { return (); }
            if value < low[axis] { low[axis] = value; }
            if value > high[axis] { high[axis] = value; }
        }
    }
    [high[0] - low[0], high[1] - low[1], high[2] - low[2]]
}

fn _mesh_dimensions_error(points, dimensions) {
    if dimensions == () || !vec3_is_native(dimensions) { return (); }
    let extent = _mesh_extent(points);
    if extent == () { return (); }
    _max_number((extent[0] - dimensions.x).abs(),
        _max_number((extent[1] - dimensions.y).abs(), (extent[2] - dimensions.z).abs()))
}

fn _expected_outer_profile_mesh(dimensions, profile_points, center) {
    if !vec3_is_native(dimensions) || !vec3_is_native(center)
        || !array_is(profile_points) || profile_points.len() != 8 { return (); }
    // Deck and service skirt are open eight-member rings, not solid extrusions.
    return griffin_geometry::tank_support_perimeter_geometry(profile_points,
        dimensions.x / 2.0 - dimensions.y / 2.0, center.y, dimensions.y);
}

fn _mesh_profile_metrics(prim, expected) {
    // The standard profile kernel returns a typed ProfileMesh, not a map with
    // an `ok` flag. Reject absent geometry and inspect its registered typed
    // accessors directly.
    if !_query_ok(prim) || expected == ()
        || expected.points == () || expected.face_vertex_counts == ()
        || expected.face_vertex_indices == () || prim.type_name != "Mesh"
        || prim.attrs.points == () || prim.attrs.faceVertexCounts == ()
        || prim.attrs.faceVertexIndices == () {
        return #{topologyMismatches: (), maximumPointErrorM: ()};
    }
    let points = expected.points;
    let counts = expected.face_vertex_counts;
    let indices = expected.face_vertex_indices;
    let topology_mismatches = (prim.attrs.faceVertexCounts.len() - counts.len()).abs()
        + (prim.attrs.faceVertexIndices.len() - indices.len()).abs();
    for index in 0.._min_count(prim.attrs.faceVertexCounts.len(), counts.len()) {
        if prim.attrs.faceVertexCounts[index] != counts[index] { topology_mismatches += 1; }
    }
    for index in 0.._min_count(prim.attrs.faceVertexIndices.len(), indices.len()) {
        if prim.attrs.faceVertexIndices[index] != indices[index] { topology_mismatches += 1; }
    }
    let maximum_point_error = 0.0;
    for index in 0.._min_count(prim.attrs.points.len(), points.len()) {
        for axis in 0..3 {
            let actual = _point_component(prim.attrs.points[index], axis);
            let expected_component = _point_component(points[index], axis);
            if actual == () || expected_component == () {
                return #{topologyMismatches: (), maximumPointErrorM: ()};
            }
            let error = (actual - expected_component).abs();
            maximum_point_error = _max_number(maximum_point_error, error);
        }
    }
    topology_mismatches += (prim.attrs.points.len() - points.len()).abs();
    #{topologyMismatches: topology_mismatches,
      maximumPointErrorM: maximum_point_error}
}

fn _constraint(id, requirement, constraint_name, bindings, provider) {
    sysml_requirements::constraint_check(id, "bus", requirement,
        verification_name(), "GriffinBusRequirements::" + constraint_name,
        bindings, provider, 0.0)
}

fn _count_constraint(id, requirement, observed, expected) {
    _constraint(id, requirement, "GBC_ObservedCountEquals",
        #{observedCount: observed, expectedCount: expected}, "derived")
}

fn _tolerance_constraint(id, requirement, error, tolerance) {
    _constraint(id, requirement, "GBC_MeasurementWithinTolerance",
        #{absoluteError: error, allowedTolerance: tolerance}, "derived")
}

fn _quad_face_count(counts) {
    let result = 0;
    for count in counts { if count == 4 { result += 1; } }
    result
}

fn _max_vertical_band_error(points, center_y, half_section) {
    if points == () || points.len() == 0 { return (); }
    let lower = center_y - half_section;
    let upper = center_y + half_section;
    let maximum = 0.0;
    for point in points {
        let y = _point_component(point, 1);
        if y == () { return (); }
        let error = if y < lower { lower - y }
            else if y > upper { y - upper } else { 0.0 };
        maximum = _max_number(maximum, error);
    }
    maximum
}

fn _opening_radial_error(points, station, inner_radius, outer_radius, segments) {
    if points == () || points.len() != 4 * segments || segments < 1 { return (); }
    let maximum = 0.0;
    for point_index in 0..points.len() {
        let dx = _point_component(points[point_index], 0) - station.x;
        let dz = _point_component(points[point_index], 2) - station.z;
        let radius = sqrt(dx * dx + dz * dz);
        let expected_radius = if point_index < 2 * segments { outer_radius } else { inner_radius };
        maximum = _max_number(maximum, (radius - expected_radius).abs());
    }
    maximum
}

fn _tank_support_ring_checks(doc, root, name, center_y, profile, radius,
    section, geometry_tolerance, appearance_tolerance, model) {
    let path = root + "/TankSupportPlate/" + name;
    let ring = assembly_builder::composed_query(doc,
        #{path: path, children: false});
    let points = if _query_ok(ring) { ring.attrs.points } else { [] };
    let counts = if _query_ok(ring) { ring.attrs.faceVertexCounts } else { [] };
    let indices = if _query_ok(ring) { ring.attrs.faceVertexIndices } else { [] };
    let expected = griffin_geometry::tank_support_perimeter_geometry(
        profile, radius, center_y, section);
    let metrics = _mesh_profile_metrics(ring, expected);
    let checks = [];
    checks.push(sysml_requirement_checks::exists("GBC-011-" + name,
        "bus", "gbc011", verification_name(), path, "Mesh"));
    checks.push(_count_constraint("GBC-011-" + name + "-points", "gbc011",
        points.len(), profile.len() * 8));
    checks.push(_count_constraint("GBC-011-" + name + "-faces", "gbc011",
        counts.len(), profile.len() * 6));
    checks.push(_count_constraint("GBC-011-" + name + "-indices", "gbc011",
        indices.len(), profile.len() * 24));
    checks.push(_count_constraint("GBC-011-" + name + "-outward", "gbc011",
        outward_quad_face_count(points, counts, indices, profile.len()), profile.len() * 6));
    checks.push(_count_constraint("GBC-011-" + name + "-topology", "gbc011",
        metrics.topologyMismatches, 0));
    checks.push(_tolerance_constraint("GBC-011-" + name + "-profile", "gbc011",
        metrics.maximumPointErrorM, geometry_tolerance));
    checks.push(_tolerance_constraint("GBC-011-" + name + "-plane", "gbc011",
        _max_vertical_band_error(points, center_y, section / 2.0), geometry_tolerance));
    for pair in [
        ["doubleSided", "doubleSidedFacesMustBe"],
        ["physics:collisionEnabled", "renderOnlyCollisionEnabled"],
        ["purpose", "renderPurpose"]
    ] {
        checks.push(_visual_attribute_check("GBC-011-" + name + "-" + pair[0],
            "gbc011", path, pair[0], pair[1], model));
    }
    checks.push(_tolerance_constraint("GBC-011-" + name + "-appearance", "gbc011",
        _display_color_error(ring, model.value(visual("tankSupportDisplayColor"))),
        appearance_tolerance));
    #{checks: checks, path: path}
}

fn _maximum_error(values) {
    let maximum = 0.0;
    for value in values {
        if value == () { return (); }
        maximum = _max_number(maximum, value);
    }
    maximum
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
        let ax = _point_component(a, 0); let ay = _point_component(a, 1); let az = _point_component(a, 2);
        let bx = _point_component(b, 0); let by = _point_component(b, 1); let bz = _point_component(b, 2);
        let vcx = _point_component(c, 0); let vcy = _point_component(c, 1); let vcz = _point_component(c, 2);
        let dx = _point_component(d, 0); let dy = _point_component(d, 1); let dz = _point_component(d, 2);
        let ux = bx - ax; let uy = by - ay; let uz = bz - az;
        let vx = vcx - ax; let vy = vcy - ay; let vz = vcz - az;
        let nx = uy * vz - uz * vy;
        let ny = uz * vx - ux * vz;
        let nz = ux * vy - uy * vx;
        let fx = (ax + bx + vcx + dx) / 4.0;
        let fy = (ay + by + vcy + dy) / 4.0;
        let fz = (az + bz + vcz + dz) / 4.0;
        let beam = (face / 6).to_int() * 8;
        let cx = 0.0; let cy = 0.0; let cz = 0.0;
        for vertex in 0..8 {
            cx += _point_component(points[beam + vertex], 0) / 8.0;
            cy += _point_component(points[beam + vertex], 1) / 8.0;
            cz += _point_component(points[beam + vertex], 2) / 8.0;
        }
        if nx * (fx - cx) + ny * (fy - cy) + nz * (fz - cz) > 0.0 { outward += 1; }
    }
    outward
}


fn bus_checks(doc, source, bus_root) {
    let checks = [];
    // Bucket vertices are already in the bus component frame; extra instance
    // transforms would detach the support from its source-defined datums.
    for name in ["UpperCentralBucket", "LowerCentralBucket"] {
        let prim = assembly_builder::composed_query(doc, #{path: bus_root + "/" + name, children: false});
        let error = if _query_ok(prim) { 0.0 } else { () };
        if error != () {
            for attr in ["xformOp:translate", "xformOp:rotateXYZ", "xformOp:scale"] {
                let actual = prim.attrs[attr];
                if actual == () { continue; }
                for axis in 0..3 {
                    let expected = if attr == "xformOp:scale" { 1.0 } else { 0.0 };
                    error = _max_number(error, (_point_component(actual, axis) - expected).abs());
                }
            }
        }
        checks.push(_tolerance_constraint("GBC-011-" + name + "-component-datum", "gbc011", error, 0.000001));
    }

    let root = bus_root;
    let model = sysml_model("twin://astrobotic-griffin-1");
    // Check all four profile rings, not only an artist-selected silhouette.
    let segments = model.value(visual("centralBucketSegments"));
    let shell_tolerance = model.value(visual("geometryVerificationToleranceM"));
    for spec in [
        #{name:"UpperCentralBucket", radii:["upperBucketInnerBottomRadiusM", "upperBucketOuterBottomRadiusM", "upperBucketOuterTopRadiusM", "upperBucketInnerTopRadiusM"], ys:["upperBucketBottomCenterYM", "upperBucketBottomCenterYM", "upperBucketTopCenterYM", "upperBucketTopCenterYM"]},
        #{name:"LowerCentralBucket", radii:["lowerBucketInnerTopRadiusM", "lowerBucketOuterTopRadiusM", "lowerBucketOuterBottomRadiusM", "lowerBucketInnerBottomRadiusM"], ys:["lowerBucketTopCenterYM", "lowerBucketTopCenterYM", "lowerBucketBottomCenterYM", "lowerBucketBottomCenterYM"]}
    ] {
        let prim = assembly_builder::composed_query(doc, #{path:root+"/"+spec.name, children:false});
        let points = if _query_ok(prim) && prim.attrs.points != () {prim.attrs.points} else {[]};
        let error = if points.len()==4*segments {0.0} else {()};
        if error != () {
            // The revolve kernel normalizes clockwise profiles, so ring
            // storage order is not a geometry contract. Match radius/height
            // pairs and require one complete angular ring at each datum.
            let bins=[0,0,0,0];
            for point in points {
                let x=_point_component(point,0);let z=_point_component(point,2);
                let radial=(x*x+z*z).sqrt();let y=_point_component(point,1);
                let best=1.0e30;let matched=0;
                for ring in 0..4 {
                    let radius=model.value(visual(spec.radii[ring]));
                    let expected_y=model.value(visual(spec.ys[ring]));
                    let deviation=_max_number((radial-radius).abs(),(y-expected_y).abs());
                    if deviation<best {best=deviation;matched=ring;}
                }
                bins[matched]+=1;error=_max_number(error,best);
            }
            for ring in 0..4 {
                checks.push(_count_constraint("GBC-011-"+spec.name+"-ring-"+ring.to_string(),"gbc011",bins[ring],segments));
            }
        }
        checks.push(_tolerance_constraint("GBC-011-"+spec.name+"-profile", "gbc011", error, shell_tolerance));
    }

    let upper_outer = _max_number(model.value(visual("upperBucketOuterBottomRadiusM")), model.value(visual("upperBucketOuterTopRadiusM")));
    let lower_outer = _max_number(model.value(visual("lowerBucketOuterBottomRadiusM")), model.value(visual("lowerBucketOuterTopRadiusM")));
    let lower_inner = if model.value(visual("lowerBucketInnerBottomRadiusM")) < model.value(visual("lowerBucketInnerTopRadiusM")) {model.value(visual("lowerBucketInnerBottomRadiusM"))} else {model.value(visual("lowerBucketInnerTopRadiusM"))};
    let maximum_band = 0.0;
    for radius in model.value("GriffinTankRequirements::GriffinPropellantTankAssembly::bandRadiusByCenterM") {maximum_band=_max_number(maximum_band,radius);}
    let stations = model.value(visual("tankStations"));
    let scales = model.value(visual("tankScale"));
    let clearance = 1.0e30;
    for i in 0..stations.len() {
        let p=stations[i];let gap=(p.x*p.x+p.z*p.z).sqrt()-maximum_band*scales[i]-upper_outer;
        if gap<clearance {clearance=gap;}
    }
    checks.push(_constraint("GBC-011-upper-adapter-tank-clearance", "gbc011", "GBC_SupportClearance",
        #{measuredClearanceM:clearance,requiredClearanceM:model.value(visual("minimumTankFrameClearanceM"))},"derived"));
    let bell_radius=model.value("GriffinPropulsionRequirements::GriffinMainPropulsionAssembly::bellRadiusM");
    let engine_gap=lower_inner-bell_radius;
    for p in model.value(visual("engineStations")) {
        let radial=(p.x*p.x+p.z*p.z).sqrt();
        if radial>0.0 {let gap=radial-bell_radius-lower_outer;if gap<engine_gap {engine_gap=gap;}}
    }
    checks.push(_constraint("GBC-011-lower-adapter-engine-clearance", "gbc011", "GBC_SupportClearance",
        #{measuredClearanceM:engine_gap,requiredClearanceM:model.value(visual("minimumTankFrameClearanceM"))},"derived"));
    let source_tolerance = sysml_requirements::number(source,
        visual("verificationToleranceM"));
    let geometry_tolerance = sysml_requirements::number(source,
        visual("geometryVerificationToleranceM"));
    let appearance_tolerance = sysml_requirements::number(source,
        visual("appearanceVerificationTolerance"));
    let root_prim = assembly_builder::composed_query(doc, #{path: root, children: false});
    let frame_prim = assembly_builder::composed_query(doc, #{path: root + "/PerimeterFrame", children: false});
    let deck_prim = assembly_builder::composed_query(doc, #{path: root + "/TopDeckOctagon", children: false});
    let skirt_prim = assembly_builder::composed_query(doc, #{path: root + "/LowerServiceSkirtOctagon", children: false});
    checks.push(sysml_requirement_checks::exists("GBC-001-root", "bus", "gbc001",
        verification_name(), root, "Xform"));
    checks.push(sysml_requirement_checks::exists("GBC-001-frame", "bus", "gbc001",
        verification_name(), root + "/PerimeterFrame", "Mesh"));
    checks.push(sysml_requirement_checks::exists("GBC-001-deck", "bus", "gbc001",
        verification_name(), root + "/TopDeckOctagon", "Mesh"));
    checks.push(sysml_requirement_checks::exists("GBC-001-skirt", "bus", "gbc001",
        verification_name(), root + "/LowerServiceSkirtOctagon", "Mesh"));
    checks.push(sysml_requirement_checks::coverage("GBC-003-ownership", "bus", "gbc003", verification_name()));
    checks.push(sysml_requirement_checks::coverage("GBC-004-traceability", "bus", "gbc004", verification_name()));

    let frame = assembly_builder::composed_query(doc,
        #{path: root + "/PerimeterFrame", children: false});
    let frame_points = if _query_ok(frame) { frame.attrs.points } else { [] };
    let frame_counts = if _query_ok(frame) { frame.attrs.faceVertexCounts } else { [] };
    let frame_indices = if _query_ok(frame) { frame.attrs.faceVertexIndices } else { [] };
    let body_dimensions = _native(source, "bodyDimensions");
    let rail_names = _model_names(model, "frameRails");
    let ring_y = model.value(visual("frameRingCenterY"));
    let beam_count = rail_names.len() * ring_y.len();
    checks.push(_count_constraint("GBC-008-frame-points", "gbc008",
        frame_points.len(), beam_count * 8));
    checks.push(_count_constraint("GBC-008-frame-faces", "gbc008",
        frame_counts.len(), beam_count * 6));
    checks.push(_count_constraint("GBC-008-frame-indices", "gbc008",
        frame_indices.len(), beam_count * 24));
    checks.push(_count_constraint("GBC-008-frame-quad-faces", "gbc008",
        _quad_face_count(frame_counts), beam_count * 6));
    let outward_faces = outward_quad_face_count(frame_points, frame_counts, frame_indices, beam_count);
    checks.push(_count_constraint("GBC-008-outward-faces", "gbc008",
        outward_faces, beam_count * 6));
    checks.push(_tolerance_constraint("GBC-005-frame-envelope", "gbc005",
        _mesh_dimensions_error(frame_points, body_dimensions), geometry_tolerance));
    checks.push(#{id: "GBC-008-single-sided", component: "bus",
        requirement: "gbc008", verification: verification_name(), kind: "attribute",
        path: root + "/PerimeterFrame", attr: "doubleSided",
        expected_attr: visual("doubleSidedFacesMustBe")});


    let rail_color_error = 0.0;
    for index in 0..rail_names.len() {
        let path = root + "/" + rail_names[index];
        let prim = assembly_builder::composed_query(doc,
            #{path: path, children: false});
        checks.push(sysml_requirement_checks::exists("GBC-007-" + rail_names[index],
            "bus", "gbc007", verification_name(), path, "Cube"));
        for axis in 0..3 {
            checks.push(#{id: "GBC-007-" + rail_names[index] + "-position-" + axis,
                component: "bus", requirement: "gbc007", verification: verification_name(),
                kind: "attribute_component", path: path, attr: "xformOp:translate",
                index: axis, expected_attr: visual("railStations"),
                expected_index: [index, axis], tolerance: geometry_tolerance});
            checks.push(#{id: "GBC-007-" + rail_names[index] + "-dimensions-" + axis,
                component: "bus", requirement: "gbc007", verification: verification_name(),
                kind: "attribute_component", path: path, attr: "xformOp:scale",
                index: axis, expected_attr: visual("railDimensions"),
                expected_index: axis, tolerance: geometry_tolerance});
        }
        checks.push(#{id: "GBC-007-" + rail_names[index] + "-purpose",
            component: "bus", requirement: "gbc007", verification: verification_name(),
            kind: "attribute", path: path, attr: "purpose",
            expected: usd_geometry_inspection::purpose_token(model.value(visual("renderPurpose")))});
        checks.push(#{id: "GBC-007-" + rail_names[index] + "-collision",
            component: "bus", requirement: "gbc007", verification: verification_name(),
            kind: "attribute", path: path, attr: "physics:collisionEnabled",
            expected_attr: visual("renderOnlyCollisionEnabled")});
        let color_error = _display_color_error(prim,
            model.value(visual("railDisplayColor")));
        if color_error == () { rail_color_error = (); }
        else if rail_color_error != () { rail_color_error = _max_number(rail_color_error, color_error); }
    }
    checks.push(_tolerance_constraint("GBC-007-rail-appearance", "gbc007",
        rail_color_error, appearance_tolerance));

    let deck = assembly_builder::composed_query(doc,
        #{path: root + "/TopDeckOctagon", children: false});
    let deck_dims = _native(source, "deckDimensions");
    let deck_center = _native(source, "deckCenter");
    let expected_deck = _expected_outer_profile_mesh(deck_dims, model.value(visual("outerBodyProfileCoordinates")), deck_center);
    let deck_profile = _mesh_profile_metrics(deck, expected_deck);
    let deck_faces = if _query_ok(deck) { outward_quad_face_count(deck.attrs.points,
        deck.attrs.faceVertexCounts, deck.attrs.faceVertexIndices, 8) } else { 0 };
    checks.push(_count_constraint("GBC-006-deck-profile-topology", "gbc006",
        deck_profile.topologyMismatches, 0));
    checks.push(_tolerance_constraint("GBC-006-deck-profile-points", "gbc006",
        deck_profile.maximumPointErrorM, geometry_tolerance));
    checks.push(_count_constraint("GBC-006-deck-outward-faces", "gbc006",
        deck_faces, if expected_deck == () { () } else { expected_deck.face_vertex_counts.len() }));
    checks.push(_tolerance_constraint("GBC-006-deck-envelope", "gbc006",
        _mesh_dimensions_error(if _query_ok(deck) { deck.attrs.points } else { () }, deck_dims),
        geometry_tolerance));
    checks.push(_tolerance_constraint("GBC-006-deck-elevation", "gbc006",
        _max_vertical_band_error(if _query_ok(deck) { deck.attrs.points } else { [] },
            deck_center.y, deck_dims.y / 2.0), geometry_tolerance));
    checks.push(#{id: "GBC-006-deck-sidedness", component: "bus",
        requirement: "gbc006", verification: verification_name(), kind: "attribute",
        path: root + "/TopDeckOctagon", attr: "doubleSided",
        expected_attr: visual("doubleSidedFacesMustBe")});

    let skirt = assembly_builder::composed_query(doc,
        #{path: root + "/LowerServiceSkirtOctagon", children: false});
    let skirt_dims = _native(source, "lowerSkirtDimensions");
    let skirt_center = _native(source, "lowerSkirtCenter");
    let expected_skirt = _expected_outer_profile_mesh(skirt_dims, model.value(visual("outerBodyProfileCoordinates")), skirt_center);
    let skirt_profile = _mesh_profile_metrics(skirt, expected_skirt);
    let skirt_faces = if _query_ok(skirt) { outward_quad_face_count(skirt.attrs.points,
        skirt.attrs.faceVertexCounts, skirt.attrs.faceVertexIndices, 8) } else { 0 };
    checks.push(_count_constraint("GBC-006-skirt-profile-topology", "gbc006",
        skirt_profile.topologyMismatches, 0));
    checks.push(_tolerance_constraint("GBC-006-skirt-profile-points", "gbc006",
        skirt_profile.maximumPointErrorM, geometry_tolerance));
    checks.push(_count_constraint("GBC-006-skirt-outward-faces", "gbc006",
        skirt_faces, if expected_skirt == () { () } else { expected_skirt.face_vertex_counts.len() }));
    checks.push(_tolerance_constraint("GBC-006-skirt-envelope", "gbc006",
        _mesh_dimensions_error(if _query_ok(skirt) { skirt.attrs.points } else { () }, skirt_dims),
        geometry_tolerance));
    checks.push(_tolerance_constraint("GBC-006-skirt-elevation", "gbc006",
        _max_vertical_band_error(if _query_ok(skirt) { skirt.attrs.points } else { [] },
            skirt_center.y, skirt_dims.y / 2.0), geometry_tolerance));
    checks.push(#{id: "GBC-006-skirt-sidedness", component: "bus",
        requirement: "gbc006", verification: verification_name(), kind: "attribute",
        path: root + "/LowerServiceSkirtOctagon", attr: "doubleSided",
        expected_attr: visual("doubleSidedFacesMustBe")});

    let deck_skirt_clearance = assembly_audit::oriented_box_clearance(
        "TopDeckOctagon-to-LowerServiceSkirtOctagon",
        deck_center, deck_dims, quat_identity(),
        skirt_center, skirt_dims, quat_identity(), 0.0);
    checks.push(sysml_requirements::constraint_check(
        "GBC-010-deck-skirt-clearance", "bus", "gbc010", verification_name(),
        "GriffinBusRequirements::GBC010_PositiveDeckSkirtClearance",
        #{separationM: deck_skirt_clearance.signed_axis_margin_m},
        "derived", source_tolerance));

    let support = assembly_builder::composed_query(doc,
        #{path: root + "/TankSupportPlate", children: false});
    let tanks = model.value(visual("tankStations"));
    let tank_names = _model_names(model, "tankInstances");
    let support_planes = model.value(visual("tankSupportPlanes"));
    let segments = model.value(visual("tankSupportOpeningSegments"));
    let inner_radius = model.value(visual("tankSupportOpeningInnerRadiusM"));
    let outer_radius = model.value(visual("tankSupportOpeningOuterRadiusM"));
    let support_profile = model.value(visual("outerBodyProfileCoordinates"));
    let support_radius = model.value(visual("tankSupportPerimeterRadiusM"));
    let support_section = model.value(visual("tankSupportPerimeterSectionM"));
    checks.push(sysml_requirement_checks::exists("GBC-011-support-root", "bus",
        "gbc011", verification_name(), root + "/TankSupportPlate", "Xform"));
    let ring_names = ["TankSupportPerimeterUpper", "TankSupportPerimeter",
        "TankSupportPerimeterLower"];
    checks.push(_count_constraint("GBC-011-support-ring-count", "gbc011",
        ring_names.len(), support_planes.len()));
    if !array_is(support_planes) || support_planes.len() != ring_names.len()
        || !array_is(tanks) || tanks.len() != tank_names.len() {
        throw("Bus source must contain three support planes and one station per tank");
    }
    let support_color_errors = [];
    for index in 0..ring_names.len() {
        let ring = _tank_support_ring_checks(doc, root, ring_names[index],
            support_planes[index], support_profile, support_radius,
            support_section, geometry_tolerance, appearance_tolerance, model);
        for check in ring.checks { checks.push(check); }
        support_color_errors.push(_display_color_error(
            assembly_builder::composed_query(doc, #{path: ring.path, children: false}),
            model.value(visual("tankSupportDisplayColor"))));
    }

    checks.push(_count_constraint("GBC-011-opening-count", "gbc011",
        tank_names.len() * support_planes.len(), tanks.len() * support_planes.len()));
    let opening_color_errors = [];
    for index in 0..tank_names.len() {
        for plane_index in 0..support_planes.len() {
            let suffix = if plane_index == 0 { "Upper" }
                else if plane_index == 1 { "" } else { "Lower" };
            let label = tank_names[index] + suffix;
            let path = root + "/TankSupportPlate/Opening" + label;
            let opening = assembly_builder::composed_query(doc,
                #{path: path, children: false});
            checks.push(sysml_requirement_checks::exists("GBC-011-opening-" + label,
                "bus", "gbc011", verification_name(), path, "Mesh"));
            let points = if _query_ok(opening) { opening.attrs.points } else { [] };
            let face_counts = if _query_ok(opening) { opening.attrs.faceVertexCounts } else { [] };
            let face_indices = if _query_ok(opening) { opening.attrs.faceVertexIndices } else { [] };
            checks.push(_constraint("GBC-011-opening-topology-" + label,
                "gbc011", "GBC011_AnnularOpeningTopology",
                #{observedPointCount: points.len(), observedFaceCount: face_counts.len(),
                  observedIndexCount: face_indices.len(), segmentCount: segments}, "derived"));
            checks.push(_constraint("GBC-011-opening-quads-" + label,
                "gbc011", "GBC011_OpeningQuadsCoverSurface",
                #{quadFaceCount: _quad_face_count(face_counts), faceCount: face_counts.len()}, "derived"));
            let bore_error = if points.len() > 2 * segments {
                let point = points[2 * segments];
                let dx = point[0] - (tanks[index].x + inner_radius);
                let dz = point[2] - tanks[index].z;
                sqrt(dx * dx + dz * dz)
            } else { () };
            checks.push(_tolerance_constraint("GBC-011-opening-center-" + label,
                "gbc011", bore_error, geometry_tolerance));
            checks.push(_tolerance_constraint("GBC-011-opening-radii-" + label,
                "gbc011", _opening_radial_error(points, tanks[index], inner_radius,
                    outer_radius, segments), geometry_tolerance));
            checks.push(#{id: "GBC-011-opening-collision-" + label,
                component: "bus", requirement: "gbc011", verification: verification_name(),
                kind: "attribute", path: path, attr: "physics:collisionEnabled",
                expected_attr: visual("renderOnlyCollisionEnabled")});
            checks.push(#{id: "GBC-011-opening-sidedness-" + label,
                component: "bus", requirement: "gbc011", verification: verification_name(),
                kind: "attribute", path: path, attr: "doubleSided",
                expected_attr: visual("doubleSidedFacesMustBe")});
            opening_color_errors.push(_display_color_error(opening,
                model.value(visual("tankCollarDisplayColor"))));
            checks.push(#{id: "GBC-011-opening-purpose-" + label,
                component: "bus", requirement: "gbc011", verification: verification_name(),
                kind: "attribute", path: path, attr: "purpose",
                expected: usd_geometry_inspection::purpose_token(model.value(visual("renderPurpose")))});
        }
    }

    let band_radii = sysml_requirement_checks::source_number_list(source,
        "GriffinTankRequirements::GriffinPropellantTankAssembly::bandRadiusByCenterM");
    let tank_scales = model.value(visual("tankScale"));
    let minimum_bore_clearance = sysml_requirements::number(source,
        visual("minimumTankFrameClearanceM"));
    let maximum_band_radius = 0.0;
    for radius in band_radii {
        if radius > maximum_band_radius { maximum_band_radius = radius; }
    }
    for index in 0..tank_names.len() {
        checks.push(sysml_requirements::constraint_check(
            "GBC-011-bore-clearance-" + tank_names[index], "bus", "gbc011",
            verification_name(),
            "GriffinBusRequirements::GBC011_TankBoreClearance",
            #{boreRadiusM: inner_radius, maximumBandRadiusM: maximum_band_radius,
              tankScale: tank_scales[index], minimumClearanceM: minimum_bore_clearance},
            "derived",
            source_tolerance));
    }

    let source_color_error = _maximum_error([
        _display_color_error(frame, model.value(visual("frameDisplayColor"))),
        _display_color_error(deck, model.value(visual("deckDisplayColor"))),
        _display_color_error(skirt, model.value(visual("lowerSkirtDisplayColor"))),
        _maximum_error(support_color_errors),
        rail_color_error, _maximum_error(opening_color_errors)]);
    checks.push(_tolerance_constraint("GBC-012-source-owned-colors", "gbc012",
        source_color_error, appearance_tolerance));

    let legacy_names = griffin_spec::legacy_bus_prim_names();
    for legacy_name in legacy_names {
        checks.push(sysml_requirement_checks::not_exists("GBC-009-legacy-" + legacy_name,
            "bus", "gbc009", verification_name(), root + "/" + legacy_name));
    }

    // Flight exterior is distinct from the internal open frame. Inspect the
    // actual mesh, so a name or source parameter cannot stand in for a skin.
    let skin_thickness = sysml_requirements::number(source, visual("bodySkinThicknessM"));
    let skin_margin = sysml_requirements::number(source, visual("bodySkinEdgeMarginM"));
    let skin_color = sysml_requirements::native_value(source, visual("bodySkinDisplayColor"));
    for index in 1..9 {
        let label = "ExteriorFacet" + index.to_string();
        let path = root + "/" + label;
        let prim = assembly_builder::composed_query(doc, #{path: path, children: false});
        checks.push(sysml_requirement_checks::exists("GBC-009-" + label,
            "bus", "gbc009", verification_name(), path, "Mesh"));
        let points = if _query_ok(prim) { prim.attrs.points } else { [] };
        let counts = if _query_ok(prim) { prim.attrs.faceVertexCounts } else { [] };
        let indices = if _query_ok(prim) { prim.attrs.faceVertexIndices } else { [] };
        checks.push(_count_constraint("GBC-009-points-" + label, "gbc009", points.len(), 8));
        checks.push(_count_constraint("GBC-009-quads-" + label, "gbc009", _quad_face_count(counts), 6));
        checks.push(_count_constraint("GBC-009-indices-" + label, "gbc009", indices.len(), 24));
        // Every undirected edge must have two incident faces, with valid
        // indices; duplicated faces or an open back cannot satisfy closure.
        let edges = #{}; let valid = true; let offset = 0;
        for count in counts {
            if count != 4 || offset + count > indices.len() { valid = false; break; }
            for edge in 0..count {
                let a = indices[offset + edge];
                let b = indices[offset + (edge + 1) % count];
                if a < 0 || b < 0 || a >= points.len() || b >= points.len() || a == b {
                    valid = false; continue;
                }
                let key = if a < b { a.to_string() + ":" + b.to_string() }
                    else { b.to_string() + ":" + a.to_string() };
                edges[key] = if edges[key] == () { 1 } else { edges[key] + 1 };
            }
            offset += count;
        }
        for incidence in edges.values() { if incidence != 2 { valid = false; } }
        checks.push(_count_constraint("GBC-009-closed-" + label, "gbc009",
            if valid && edges.len() == 12 && offset == indices.len() { 1 } else { 0 }, 1));
        let extent = _mesh_extent(points);
        let error = ();
        if extent != () && skin_thickness != () && skin_margin != () {
            error = (extent[1] - (body_dimensions.y - 2.0 * skin_margin)).abs();
            error = _max_number(error, _max_number(0.0, extent[0] - body_dimensions.x - 2.0 * skin_thickness));
            error = _max_number(error, _max_number(0.0, extent[2] - body_dimensions.z - 2.0 * skin_thickness));
        }
        checks.push(_tolerance_constraint("GBC-009-envelope-" + label, "gbc009", error, geometry_tolerance));
        // Only the four broad axial faces correspond to the user's marked
        // face. Applying that ratio to the clipped corners would distort the
        // octagon. Measure actual mesh edges instead of dividing source sizes.
        if index % 2 == 1 {
            let ratio_error = ();
            if points.len() == 8 {
                let dx = points[3][0] - points[0][0];
                let dz = points[3][2] - points[0][2];
                let height = (points[1][1] - points[0][1]).abs();
                if height > 0.0 {
                    let ratio = sqrt(dx * dx + dz * dz) / height;
                    ratio_error = (ratio - sysml_requirements::number(source,
                        visual("bodySideFaceAspectRatio"))).abs();
                }
            }
            checks.push(_tolerance_constraint("GBC-009-face-ratio-" + label, "gbc009",
                ratio_error, sysml_requirements::number(source, visual("bodySideFaceAspectRatioTolerance"))));
        }
        checks.push(_tolerance_constraint("GBC-009-color-" + label, "gbc009",
            _display_color_error(prim, skin_color), appearance_tolerance));
        for attr in ["physics:collisionEnabled", "purpose", "doubleSided"] {
            let expected = if attr == "purpose" { "renderPurpose" }
                else if attr == "doubleSided" { "doubleSidedFacesMustBe" }
                else { "renderOnlyCollisionEnabled" };
            checks.push(_visual_attribute_check("GBC-009-" + label + "-" + attr,
                "gbc009", path, attr, expected, model));
        }
    }

    checks
}

fn verify_bus(doc, source, bus_root) {
    sysml_requirement_checks::finish(source, bus_checks(doc, source, bus_root),
        "GRIFFIN BUS REQUIREMENTS", "GRIFFIN_BUS_REQUIREMENTS", bus_root,
        package_name(), verification_name())
}
