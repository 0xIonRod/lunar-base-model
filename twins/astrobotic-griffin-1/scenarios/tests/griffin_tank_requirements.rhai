// Standalone Griffin propellant-tank visual verification.

const PACKAGE = "GriffinTankRequirements";
const VERIFICATION = "Verify_GriffinTankRequirements";

fn own(name) { PACKAGE + "::GriffinPropellantTankAssembly::" + name }
fn parent(name) { "GriffinLanderRequirements::GriffinLanderComponent::" + name }

fn position_for(id, requirement, path, index, expected) {
    #{id: id, component: "tank", requirement: requirement,
      verification: "Verify_GriffinTankRequirements", kind: "attribute_component", path: path,
      attr: "xformOp:translate", index: index, expected: expected, tolerance: 0.002}
}

fn position(id, path, index, expected) {
    position_for(id, "gpt005", path, index, expected)
}

fn attribute(id, requirement, path, attr, expected) {
    #{id: id, component: "tank", requirement: requirement.split("::")[requirement.split("::").len() - 1],
      verification: "Verify_GriffinTankRequirements", kind: "attribute", path: path,
      attr: attr, expected: expected, tolerance: 0.002}
}

fn source_attribute(id, requirement, path, attr, expected_attr) {
    #{id: id, component: "tank", requirement: requirement.split("::")[requirement.split("::").len() - 1],
      verification: "Verify_GriffinTankRequirements", kind: "attribute_equals", path: path,
      attr: attr, expected_attr: expected_attr}
}

fn source_component(id, requirement, path, attr, index, expected_attr) {
    #{id: id, component: "tank", requirement: requirement.split("::")[requirement.split("::").len() - 1],
      verification: "Verify_GriffinTankRequirements", kind: "attribute_component", path: path,
      attr: attr, index: index, expected_attr: expected_attr, tolerance: 0.002}
}

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source();
    let root = sysml_requirements::text(source, own("usdRootPath"));
    let names_source = sysml_requirements::text(source, own("namesSource"));
    let count_source = sysml_requirements::text(source, own("countSource"));
    let names = component_requirements::source_text_list(source, names_source);
    let child_names = component_requirements::source_text_list(source, own("childNames"));
    let end_hardware_names = component_requirements::source_text_list(source, own("endHardwareNames"));
    let service_hardware_names = component_requirements::source_text_list(source, own("serviceHardwareNames"));
    let axial_hardware_names = component_requirements::source_text_list(source, own("axialHardwareNames"));
    let xs = component_requirements::source_number_list(source, parent("tankStationX"));
    let ys = component_requirements::source_number_list(source, parent("tankStationY"));
    let zs = component_requirements::source_number_list(source, parent("tankStationZ"));
    let body_radius = sysml_requirements::number(source, own("bodyRadiusM"));
    let body_height = sysml_requirements::number(source, own("bodyHeightM"));
    let body_shape = sysml_requirements::text(source, own("bodyShape"));
    let body_cylindrical_height = sysml_requirements::number(source, own("bodyCylindricalHeightM"));
    let neck_radius = sysml_requirements::number(source, own("neckRadiusM"));
    let neck_height = sysml_requirements::number(source, own("neckHeightM"));
    let shoulder_radius = sysml_requirements::number(source, own("shoulderCollarRadiusM"));
    let shoulder_height = sysml_requirements::number(source, own("shoulderCollarHeightM"));
    let valve_radius = sysml_requirements::number(source, own("valveRadiusM"));
    let valve_height = sysml_requirements::number(source, own("valveHeightM"));
    let valve_cap_radius = sysml_requirements::number(source, own("valveCapRadiusM"));
    let valve_cap_height = sysml_requirements::number(source, own("valveCapHeightM"));
    let transition_shoulder_radius = sysml_requirements::number(source, own("transitionShoulderRadiusM"));
    let transition_neck_radius = sysml_requirements::number(source, own("transitionNeckRadiusM"));
    let transition_height = sysml_requirements::number(source, own("transitionHeightM"));
    let transition_radius = sysml_requirements::number(source, own("transitionRadiusM"));
    let shoulder_center_y = sysml_requirements::number(source, own("shoulderCenterYM"));
    let transition_center_y = sysml_requirements::number(source, own("transitionCenterYM"));
    let neck_center_y = sysml_requirements::number(source, own("neckCenterYM"));
    let valve_center_y = sysml_requirements::number(source, own("valveCenterYM"));
    let cap_center_y = sysml_requirements::number(source, own("capCenterYM"));
    let band_height = sysml_requirements::number(source, own("bandHeightM"));
    let tank_axis = sysml_requirements::text(source, own("tankAxis"));
    let band_centers = component_requirements::source_number_list(source, own("bandCenterYM"));
    let band_radii = component_requirements::source_number_list(source, own("bandRadiusByCenterM"));
    let band_transform_order_text = sysml_requirements::text(source, own("bandTransformOrder"));
    let band_transform_order = [];
    if band_transform_order_text != () && band_transform_order_text != "" {
        for token in band_transform_order_text.split(",") {
            token.trim();
            if token != "" { band_transform_order.push(token); }
        }
    }
    let cradle_local_y = sysml_requirements::number(source, own("cradleLocalY"));
    let cradle_shape = sysml_requirements::text(source, own("cradleShape"));
    let cradle_radius = sysml_requirements::number(source, own("cradleRadiusM"));
    let cradle_half_height = sysml_requirements::number(source, own("cradleHalfHeightM"));
    let cradle_height = sysml_requirements::number(source, own("cradleHeightM"));
    let cradle_pad_local_y = sysml_requirements::number(source, own("cradlePadLocalY"));
    let cradle_pad_width = sysml_requirements::number(source, own("cradlePadWidthM"));
    let cradle_pad_depth = sysml_requirements::number(source, own("cradlePadDepthM"));
    let cradle_pad_height = sysml_requirements::number(source, own("cradlePadHeightM"));
    let support_name = sysml_requirements::text(source, own("supportName"));
    let support_radius = sysml_requirements::number(source, own("supportRadiusM"));
    let support_height = sysml_requirements::number(source, own("supportHeightM"));
    let support_center_y = sysml_requirements::number(source, own("supportCenterYM"));
    let minimum_deck_clearance = sysml_requirements::number(source, own("minimumDeckClearanceM"));
    let deck_top_source = sysml_requirements::text(source, own("deckTopSource"));
    let deck_top = sysml_requirements::number(source, deck_top_source);
    let bracket_group_name = sysml_requirements::text(source, own("bracketGroupName"));
    let bracket_names = component_requirements::source_text_list(source, own("bracketNames"));
    let bracket_length = sysml_requirements::number(source, own("bracketLengthM"));
    let bracket_width = sysml_requirements::number(source, own("bracketWidthM"));
    let bracket_depth = sysml_requirements::number(source, own("bracketDepthM"));
    let bracket_offset = sysml_requirements::number(source, own("bracketCenterOffsetM"));
    let bracket_center_y = sysml_requirements::number(source, own("bracketCenterYM"));
    let bracket_tilt = sysml_requirements::number(source, own("bracketTiltDeg"));
    let missing_shape = body_radius == () || body_height == () || body_shape == ()
        || body_shape != "Cylinder" || body_cylindrical_height == ();
    let missing_end = neck_radius == () || neck_height == ()
        || transition_shoulder_radius == () || transition_neck_radius == ()
        || transition_height == () || transition_radius == ()
        || shoulder_center_y == () || transition_center_y == ()
        || neck_center_y == () || valve_center_y == () || cap_center_y == ();
    let missing_service = shoulder_radius == () || shoulder_height == ()
        || valve_radius == () || valve_height == () || valve_cap_radius == ()
        || valve_cap_height == () || band_height == ()
        || band_centers.len() != 3 || tank_axis == () || tank_axis == ""
        || band_radii.len() != 3
        || band_transform_order.len() != 1;
    let missing_interface = cradle_local_y == () || cradle_shape == () || cradle_shape == ""
        || cradle_radius == () || cradle_half_height == () || cradle_height == ()
        || cradle_pad_local_y == () || cradle_pad_width == ()
        || cradle_pad_depth == () || cradle_pad_height == ()
        || support_name == () || support_name == "" || support_radius == ()
        || support_height == () || support_center_y == ()
        || minimum_deck_clearance == () || deck_top_source == ()
        || deck_top_source == "" || deck_top == ();
    let missing_brackets = bracket_group_name == () || bracket_group_name == ""
        || bracket_names.len() != 4 || bracket_length == () || bracket_width == ()
        || bracket_depth == () || bracket_offset == () || bracket_center_y == ()
        || bracket_tilt == ();
    let missing_topology = child_names.len() == 0 || end_hardware_names.len() != 2
        || service_hardware_names.len() != 6 || axial_hardware_names.len() != 11;
    if missing_shape || missing_end || missing_service || missing_interface || missing_brackets || missing_topology {
        component_requirements::finish(source, [component_requirements::coverage("GPT-006-source", "tank", "gpt006", VERIFICATION)], "GRIFFIN TANK REQUIREMENTS", "GRIFFIN_TANK_REQUIREMENTS", root, PACKAGE, VERIFICATION);
        this.done = true;
        return;
    }
    let checks = [];
    checks.push(component_requirements::source_list_count("GPT-001-count", "propellant_tank", "gpt001", VERIFICATION, names_source, count_source));
    for axis in ["tankStationX", "tankStationY", "tankStationZ"] {
        checks.push(component_requirements::source_list_count("GPT-005-" + axis,
            "tank", "gpt005", VERIFICATION,
            parent(axis), count_source));
    }
    for index in 0..names.len() {
        let name = names[index];
        let path = root + "/" + name;
        let child_paths = [];
        for child_name in child_names { child_paths.push(path + "/" + child_name); }
        let end_hardware_paths = [];
        for child_name in end_hardware_names { end_hardware_paths.push(path + "/" + child_name); }
        let service_hardware_paths = [];
        for child_name in service_hardware_names { service_hardware_paths.push(path + "/" + child_name); }
        checks.push(component_requirements::exists("GPT-001-" + name, "tank", "gpt001", VERIFICATION, path, "Xform"));
        checks.push(component_requirements::children("GPT-002-" + name, "tank", "gpt002", VERIFICATION, path,
            child_paths));
        checks.push(component_requirements::exists("GPT-002-" + name + "-cradle", "tank", "gpt002", VERIFICATION, path + "/TankCradle", cradle_shape));
        checks.push(component_requirements::exists("GPT-002-" + name + "-cradle-pad", "tank", "gpt002", VERIFICATION, path + "/TankCradlePad", "Cube"));
        checks.push(component_requirements::exists("GPT-009-" + name + "-support", "tank", "gpt009", VERIFICATION, path + "/" + support_name, "Cylinder"));
        checks.push(component_requirements::children("GPT-006-" + name, "tank", "gpt006", VERIFICATION, path,
            end_hardware_paths));
        checks.push(component_requirements::exists("GPT-006-" + name + "-neck-top", "tank", "gpt006", VERIFICATION, path + "/TankNeckTop", "Cylinder"));
        checks.push(component_requirements::exists("GPT-006-" + name + "-neck-bottom", "tank", "gpt006", VERIFICATION, path + "/TankNeckBottom", "Cylinder"));
        checks.push(component_requirements::exists("GPT-006-" + name + "-transition-top", "tank", "gpt006", VERIFICATION, path + "/TankTransitionTop", "Cone"));
        checks.push(component_requirements::exists("GPT-006-" + name + "-transition-bottom", "tank", "gpt006", VERIFICATION, path + "/TankTransitionBottom", "Cone"));
        checks.push(component_requirements::exists("GPT-006-" + name + "-body", "tank", "gpt006", VERIFICATION, path + "/MliTank", body_shape));
        checks.push(attribute("GPT-006-" + name + "-body-radius", "gpt006", path + "/MliTank", "radius", body_radius));
        if body_shape == "Cylinder" {
            checks.push(attribute("GPT-006-" + name + "-body-height", "gpt006", path + "/MliTank", "height", body_cylindrical_height));
        }
        // QueryUsdPrim reports half-extents.  The explicit factor of two
        // converts the geometric half-height back to the full SysML envelope.
        checks.push(component_requirements::bounds_component("GPT-006-" + name + "-body-envelope", "tank", "gpt006", VERIFICATION, path + "/MliTank", 1, own("bodyHeightM"), 2.0, 0.002));
        checks.push(attribute("GPT-006-" + name + "-neck-radius", "gpt006", path + "/TankNeckTop", "radius", neck_radius));
        checks.push(attribute("GPT-006-" + name + "-transition-top-shoulder", "gpt006", path + "/TankTransitionTop", "radius1", transition_shoulder_radius));
        checks.push(attribute("GPT-006-" + name + "-transition-top-neck", "gpt006", path + "/TankTransitionTop", "radius2", transition_neck_radius));
        checks.push(attribute("GPT-006-" + name + "-transition-top-height", "gpt006", path + "/TankTransitionTop", "height", transition_height));
        checks.push(attribute("GPT-006-" + name + "-transition-top-radius", "gpt006", path + "/TankTransitionTop", "radius", transition_radius));
        checks.push(attribute("GPT-006-" + name + "-transition-bottom-neck", "gpt006", path + "/TankTransitionBottom", "radius1", transition_neck_radius));
        checks.push(attribute("GPT-006-" + name + "-transition-bottom-shoulder", "gpt006", path + "/TankTransitionBottom", "radius2", transition_shoulder_radius));
        checks.push(attribute("GPT-006-" + name + "-transition-bottom-height", "gpt006", path + "/TankTransitionBottom", "height", transition_height));
        checks.push(attribute("GPT-006-" + name + "-transition-bottom-radius", "gpt006", path + "/TankTransitionBottom", "radius", transition_radius));
        checks.push(position("GPT-006-" + name + "-shoulder-top-center", path + "/TankShoulderTop", 1, shoulder_center_y));
        checks.push(position("GPT-006-" + name + "-shoulder-bottom-center", path + "/TankShoulderBottom", 1, -shoulder_center_y));
        checks.push(position("GPT-006-" + name + "-transition-top-center", path + "/TankTransitionTop", 1, transition_center_y));
        checks.push(position("GPT-006-" + name + "-transition-bottom-center", path + "/TankTransitionBottom", 1, -transition_center_y));
        checks.push(position("GPT-006-" + name + "-neck-top-center", path + "/TankNeckTop", 1, neck_center_y));
        checks.push(position("GPT-006-" + name + "-neck-bottom-center", path + "/TankNeckBottom", 1, -neck_center_y));
        checks.push(position("GPT-006-" + name + "-valve-top-center", path + "/TankValveTop", 1, valve_center_y));
        checks.push(position("GPT-006-" + name + "-valve-bottom-center", path + "/TankValveBottom", 1, -valve_center_y));
        checks.push(position("GPT-006-" + name + "-cap-top-center", path + "/TankValveCapTop", 1, cap_center_y));
        checks.push(position("GPT-006-" + name + "-cap-bottom-center", path + "/TankValveCapBottom", 1, -cap_center_y));
        checks.push(component_requirements::children("GPT-007-" + name, "tank", "gpt007", VERIFICATION, path,
            service_hardware_paths));
        checks.push(component_requirements::exists("GPT-007-" + name + "-shoulder-top", "tank", "gpt007", VERIFICATION, path + "/TankShoulderTop", "Cylinder"));
        checks.push(component_requirements::exists("GPT-007-" + name + "-shoulder-bottom", "tank", "gpt007", VERIFICATION, path + "/TankShoulderBottom", "Cylinder"));
        checks.push(component_requirements::exists("GPT-007-" + name + "-valve-top", "tank", "gpt007", VERIFICATION, path + "/TankValveTop", "Cylinder"));
        checks.push(component_requirements::exists("GPT-007-" + name + "-valve-bottom", "tank", "gpt007", VERIFICATION, path + "/TankValveBottom", "Cylinder"));
        checks.push(component_requirements::exists("GPT-007-" + name + "-cap-top", "tank", "gpt007", VERIFICATION, path + "/TankValveCapTop", "Cylinder"));
        checks.push(component_requirements::exists("GPT-007-" + name + "-cap-bottom", "tank", "gpt007", VERIFICATION, path + "/TankValveCapBottom", "Cylinder"));
        checks.push(attribute("GPT-007-" + name + "-shoulder-radius", "gpt007", path + "/TankShoulderTop", "radius", shoulder_radius));
        checks.push(attribute("GPT-007-" + name + "-shoulder-height", "gpt007", path + "/TankShoulderTop", "height", shoulder_height));
        checks.push(attribute("GPT-007-" + name + "-valve-radius", "gpt007", path + "/TankValveTop", "radius", valve_radius));
        checks.push(attribute("GPT-007-" + name + "-valve-height", "gpt007", path + "/TankValveTop", "height", valve_height));
        checks.push(attribute("GPT-007-" + name + "-cap-radius", "gpt007", path + "/TankValveCapTop", "radius", valve_cap_radius));
        checks.push(attribute("GPT-007-" + name + "-cap-height", "gpt007", path + "/TankValveCapTop", "height", valve_cap_height));
        checks.push(attribute("GPT-002-" + name + "-band-a-height", "gpt002", path + "/TankBandA", "height", band_height));
        for band_index in 0..band_centers.len() {
            let band_name = ["TankBandA", "TankBandB", "TankBandC"][band_index];
            checks.push(attribute("GPT-002-" + name + "-" + band_name + "-radius", "gpt002", path + "/" + band_name, "radius", band_radii[band_index]));
            checks.push(source_attribute("GPT-008-" + name + "-" + band_name + "-axis", "gpt008", path + "/" + band_name, "axis", own("tankAxis")));
            checks.push(position("GPT-002-" + name + "-" + band_name + "-center", path + "/" + band_name, 1, band_centers[band_index]));
            checks.push(component_requirements::attribute_equals("GPT-008-" + name + "-" + band_name + "-transform-order", "tank", "gpt008", VERIFICATION, path + "/" + band_name, "xformOpOrder", band_transform_order));
        }
        checks.push(position("GPT-009-" + name + "-cradle", path + "/TankCradle", 1, cradle_local_y));
        checks.push(position("GPT-009-" + name + "-cradle-pad", path + "/TankCradlePad", 1, cradle_pad_local_y));
        checks.push(position("GPT-009-" + name + "-support", path + "/" + support_name, 1, support_center_y));
        checks.push(attribute("GPT-009-" + name + "-cradle-radius", "gpt009", path + "/TankCradle", "radius", cradle_radius));
        checks.push(attribute("GPT-009-" + name + "-cradle-height", "gpt009", path + "/TankCradle", "height", cradle_height));
        checks.push(attribute("GPT-009-" + name + "-support-radius", "gpt009", path + "/" + support_name, "radius", support_radius));
        checks.push(attribute("GPT-009-" + name + "-support-height", "gpt009", path + "/" + support_name, "height", support_height));
        // TankCradlePad is a unit Cube, so USD xformOp:scale stores half of
        // each declared full physical dimension. Keep the SysML dimensions
        // authoritative while making the representation conversion explicit.
        checks.push(#{id: "GPT-009-" + name + "-cradle-pad-scale-x", component: "tank", requirement: "gpt009", verification: "Verify_GriffinTankRequirements", kind: "attribute_component", path: path + "/TankCradlePad", attr: "xformOp:scale", index: 0, expected: cradle_pad_width / 2.0, tolerance: 0.002});
        checks.push(#{id: "GPT-009-" + name + "-cradle-pad-scale-y", component: "tank", requirement: "gpt009", verification: "Verify_GriffinTankRequirements", kind: "attribute_component", path: path + "/TankCradlePad", attr: "xformOp:scale", index: 1, expected: cradle_pad_height / 2.0, tolerance: 0.002});
        checks.push(#{id: "GPT-009-" + name + "-cradle-pad-scale-z", component: "tank", requirement: "gpt009", verification: "Verify_GriffinTankRequirements", kind: "attribute_component", path: path + "/TankCradlePad", attr: "xformOp:scale", index: 2, expected: cradle_pad_depth / 2.0, tolerance: 0.002});
        let bracket_group_path = path + "/" + bracket_group_name;
        let bracket_paths = [];
        for bracket_name in bracket_names { bracket_paths.push(bracket_group_path + "/" + bracket_name); }
        checks.push(component_requirements::exists("GPT-010-" + name + "-group", "tank", "gpt010", VERIFICATION, bracket_group_path, "Xform"));
        checks.push(component_requirements::children("GPT-010-" + name + "-children", "tank", "gpt010", VERIFICATION, bracket_group_path, bracket_paths));
        let bracket_x = [bracket_offset, -bracket_offset, bracket_offset, -bracket_offset];
        let bracket_z = [bracket_offset, bracket_offset, -bracket_offset, -bracket_offset];
        let bracket_rx = [-bracket_tilt, -bracket_tilt, bracket_tilt, bracket_tilt];
        let bracket_rz = [bracket_tilt, -bracket_tilt, bracket_tilt, -bracket_tilt];
        let bracket_index = 0;
        let bracket_path = bracket_paths[bracket_index];
        let bracket_name = bracket_names[bracket_index];
        checks.push(component_requirements::exists("GPT-010-" + name + "-" + bracket_name, "tank", "gpt010", VERIFICATION, bracket_path, "Cube"));
        checks.push(position_for("GPT-010-" + name + "-" + bracket_name + "-x", "gpt010", bracket_path, 0, bracket_x[bracket_index]));
        checks.push(position_for("GPT-010-" + name + "-" + bracket_name + "-y", "gpt010", bracket_path, 1, bracket_center_y));
        checks.push(position_for("GPT-010-" + name + "-" + bracket_name + "-z", "gpt010", bracket_path, 2, bracket_z[bracket_index]));
        checks.push(#{id: "GPT-010-" + name + "-" + bracket_name + "-rotate-x", component: "tank", requirement: "gpt010", verification: "Verify_GriffinTankRequirements", kind: "attribute_component", path: bracket_path, attr: "xformOp:rotateXYZ", index: 0, expected: bracket_rx[bracket_index], tolerance: 0.002});
        checks.push(#{id: "GPT-010-" + name + "-" + bracket_name + "-rotate-z", component: "tank", requirement: "gpt010", verification: "Verify_GriffinTankRequirements", kind: "attribute_component", path: bracket_path, attr: "xformOp:rotateXYZ", index: 2, expected: bracket_rz[bracket_index], tolerance: 0.002});
        checks.push(#{id: "GPT-010-" + name + "-" + bracket_name + "-scale-x", component: "tank", requirement: "gpt010", verification: "Verify_GriffinTankRequirements", kind: "attribute_component", path: bracket_path, attr: "xformOp:scale", index: 0, expected: bracket_width / 2.0, tolerance: 0.002});
        checks.push(#{id: "GPT-010-" + name + "-" + bracket_name + "-scale-y", component: "tank", requirement: "gpt010", verification: "Verify_GriffinTankRequirements", kind: "attribute_component", path: bracket_path, attr: "xformOp:scale", index: 1, expected: bracket_length / 2.0, tolerance: 0.002});
        checks.push(#{id: "GPT-010-" + name + "-" + bracket_name + "-scale-z", component: "tank", requirement: "gpt010", verification: "Verify_GriffinTankRequirements", kind: "attribute_component", path: bracket_path, attr: "xformOp:scale", index: 2, expected: bracket_depth / 2.0, tolerance: 0.002});
        if ys.len() == names.len() {
            // Derive the authored local cradle datum from the shared deck
            // datum. This verifies the physical interface, not just a copied
            // local coordinate.
            let expected_cradle_local = deck_top - ys[index] - cradle_half_height + minimum_deck_clearance;
            checks.push(position("GPT-009-" + name + "-deck-clearance", path + "/TankCradle", 1, expected_cradle_local));
        }
        for hardware_name in axial_hardware_names {
            checks.push(source_attribute("GPT-008-" + name + "-" + hardware_name + "-axis",
                "gpt008", path + "/" + hardware_name,
                "axis", "tankAxis"));
        }
        checks.push(source_attribute("GPT-008-" + name + "-body-axis",
            "gpt008", path + "/MliTank",
            "axis", "tankAxis"));
        if xs.len() == names.len() && ys.len() == names.len() && zs.len() == names.len() {
            checks.push(position("GPT-005-" + name + "-x", path, 0, xs[index]));
            checks.push(position("GPT-005-" + name + "-y", path, 1, ys[index]));
            checks.push(position("GPT-005-" + name + "-z", path, 2, zs[index]));
        }
    }
    checks.push(component_requirements::coverage("GPT-003-status", "tank", "gpt003", VERIFICATION));
    checks.push(component_requirements::coverage("GPT-004-traceability", "tank", "gpt004", VERIFICATION));
    checks.push(component_requirements::coverage("GPT-009-deck-seat", "tank", "gpt009", VERIFICATION));
    checks.push(component_requirements::coverage("GPT-010-mounting", "tank", "gpt010", VERIFICATION));
    component_requirements::finish(source, checks, "GRIFFIN TANK REQUIREMENTS", "GRIFFIN_TANK_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
