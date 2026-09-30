import "twin://astrobotic-griffin-1/tools/griffin_geometry.rhai" as griffin_geometry;
import "twin://astrobotic-griffin-1/tools/usd_geometry_inspection.rhai" as usd_geometry_inspection;
import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
// Positive, source-backed verification of the reusable Griffin tank assembly.
// SysML owns requirements and acceptance constraints; Rhai extracts typed
// source values and composed-USD observations for the generic evaluator.

const PACKAGE = "GriffinTankRequirements";
const VERIFICATION = "Verify_GriffinTankRequirements";

fn own(name) { PACKAGE + "::GriffinPropellantTankAssembly::" + name }
fn parent(name) { "GriffinLanderRequirements::GriffinLanderComponent::" + name }
fn visual(name) { "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::" + name }

fn _enum_name(source, name) {
    let value = sysml_requirements::native_value(source, own(name));
    if sysml_enum_is(value) { value.literal } else { () }
}

fn _enum_names(source, name) {
    let values = sysml_requirements::native_value(source, own(name));
    if values == () || !array_is(values) { return []; }
    let names = [];
    for value in values {
        if !sysml_enum_is(value) { return []; }
        names.push(value.literal);
    }
    names
}

fn _position(id, requirement, path, index, expected) {
    #{id: id, component: "tank", requirement: requirement,
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: "xformOp:translate", index: index, expected: expected, tolerance: 0.002}
}

fn _attribute(id, requirement, path, name, expected) {
    #{id: id, component: "tank", requirement: requirement,
      verification: VERIFICATION, kind: "attribute", path: path,
      attr: name, expected: expected, tolerance: 0.002}
}

fn _constraint(id, requirement, name, bindings) {
    sysml_requirements::constraint_check(id, "tank", requirement,
        VERIFICATION, PACKAGE + "::" + name, bindings, "derived", 0.0)
}

fn _position3(checks, id, requirement, path, value) {
    checks.push(_position(id + "-x", requirement, path, 0, value.x));
    checks.push(_position(id + "-y", requirement, path, 1, value.y));
    checks.push(_position(id + "-z", requirement, path, 2, value.z));
}

fn _point_segment_distance_xz(point, start, end) {
    let dx = end.x - start.x;
    let dz = end.z - start.z;
    let length_squared = dx * dx + dz * dz;
    let projection = ((point.x - start.x) * dx + (point.z - start.z) * dz)
        / length_squared;
    let fraction = if projection < 0.0 { 0.0 }
        else if projection > 1.0 { 1.0 } else { projection };
    let closest_x = start.x + fraction * dx;
    let closest_z = start.z + fraction * dz;
    let offset_x = point.x - closest_x;
    let offset_z = point.z - closest_z;
    (offset_x * offset_x + offset_z * offset_z).sqrt()
}

fn _tank_clearances(stations, perimeter_stations, frame_section, installed_envelope_radius) {
    let min_instance_clearance = 1000000.0;
    let min_frame_centerline_distance = 1000000.0;
    for index in 0..stations.len() {
        for other_index in (index + 1)..stations.len() {
            let dx = stations[index].x - stations[other_index].x;
            let dz = stations[index].z - stations[other_index].z;
            let center_distance = (dx * dx + dz * dz).sqrt();
            let clearance = center_distance - 2.0 * installed_envelope_radius;
            if clearance < min_instance_clearance {
                min_instance_clearance = clearance;
            }
        }
        for edge_index in 0..perimeter_stations.len() {
            let start_index = edge_index;
            let end_index = (edge_index + 1) % perimeter_stations.len();
            let distance = _point_segment_distance_xz(stations[index],
                perimeter_stations[start_index], perimeter_stations[end_index]);
            if distance < min_frame_centerline_distance {
                min_frame_centerline_distance = distance;
            }
        }
    }
    #{instance: min_instance_clearance,
      frame: min_frame_centerline_distance - frame_section / 2.0
          - installed_envelope_radius}
}

fn simulation_dependencies(me, ctx) { usd_geometry_inspection::dependencies() }

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }

    // A full Twin requirement source exceeds the Rhai value-size limit in the
    // live runner. Select exactly the typed literals this verifier consumes;
    // requirement/verification identity and evidence are still resolved by
    // the shared helper from the mounted Twin source set.
    let source = sysml_requirements::source_with_selection([
        parent("tankCount"), visual("tankInstances"), visual("tankStations"),
        visual("tankScale"), visual("bodyMount"), visual("lowerSkirtCenter"),
        visual("lowerSkirtDimensions"), visual("railStations"),
        visual("frameRingSectionM"),
        visual("minimumTankInstanceClearanceM"), visual("minimumTankFrameClearanceM"),
        visual("minimumTankPayloadClearanceM"), visual("payloadAdapterCenterYM"), visual("payloadAdapterDimensions"),
        own("usdRootPath"), own("bodyName"), own("bodyShape"), own("bodyCenter"),
        own("bodyRadiusM"), own("minimumInstalledBodyDiameterM"), own("tankAxis"),
        own("retentionBandNames"), own("retentionBandShape"), own("childNames"),
        own("endHardwareNames"), own("serviceHardwareNames"), own("axialHardwareNames"),
        own("transitionShape"), own("bandCenterYM"), own("bandRadiusByCenterM"),
        own("bandHeightM"), own("neckRadiusM"), own("neckHeightM"),
        own("shoulderCollarRadiusM"), own("shoulderCollarHeightM"), own("valveRadiusM"),
        own("valveHeightM"), own("valveCapRadiusM"), own("valveCapHeightM"),
        own("transitionShoulderRadiusM"), own("transitionNeckRadiusM"),
        own("transitionHeightM"), own("transitionRadiusM"), own("shoulderCenterYM"),
        own("transitionCenterYM"), own("neckCenterYM"), own("valveCenterYM"),
        own("capCenterYM"), own("cradleName"), own("cradleShape"), own("cradleRadiusM"),
        own("cradleHeightM"), own("cradlePadName"), own("cradlePadShape"),
        own("cradlePadWidthM"), own("cradlePadDepthM"), own("cradlePadHeightM"),
        own("supportName"), own("supportShape"), own("supportRadiusM"),
        own("minimumSkirtClearanceM"), own("bracketGroupName"), own("bracketNames"),
        own("bracketShape"), own("bracketLengthM"), own("bracketWidthM"),
        own("bracketDepthM"), own("bracketCenterOffsetM"), own("bracketTiltDeg"),
        own("bracketShellContactToleranceM"), visual("verificationToleranceM")
    ], [PACKAGE + "::gpt001", PACKAGE + "::gpt002", PACKAGE + "::gpt003",
        PACKAGE + "::gpt004", PACKAGE + "::gpt005", PACKAGE + "::gpt006",
        PACKAGE + "::gpt007", PACKAGE + "::gpt008", PACKAGE + "::gpt009",
        PACKAGE + "::gpt010", PACKAGE + "::gpt011"],
        [PACKAGE + "::" + VERIFICATION]);
    let root = sysml_requirements::text(source, own("usdRootPath"));
    let tank_names = sysml_requirement_checks::source_enum_identifiers(source, visual("tankInstances"));
    let tank_stations = sysml_requirement_checks::source_position_list(source, visual("tankStations"));
    let tank_scales = sysml_requirement_checks::source_number_list(source, visual("tankScale"));
    let perimeter_stations = sysml_requirement_checks::source_position_list(source, visual("railStations"));
    let frame_section = sysml_requirements::number(source, visual("frameRingSectionM"));
    let minimum_instance_clearance = sysml_requirements::number(source, visual("minimumTankInstanceClearanceM"));
    let minimum_frame_clearance = sysml_requirements::number(source, visual("minimumTankFrameClearanceM"));
    let child_names = sysml_requirement_checks::source_enum_identifiers(source, own("childNames"));
    let band_names = sysml_requirement_checks::source_enum_identifiers(source, own("retentionBandNames"));
    let end_names = sysml_requirement_checks::source_enum_identifiers(source, own("endHardwareNames"));
    let service_names = sysml_requirement_checks::source_enum_identifiers(source, own("serviceHardwareNames"));
    let axial_names = sysml_requirement_checks::source_enum_identifiers(source, own("axialHardwareNames"));
    let bracket_names = sysml_requirement_checks::source_enum_identifiers(source, own("bracketNames"));

    let body_name = _enum_name(source, "bodyName");
    let body_shape = _enum_name(source, "bodyShape");
    let body_center = sysml_requirements::native_value(source, own("bodyCenter"));
    let body_radius = sysml_requirements::number(source, own("bodyRadiusM"));
    let minimum_installed_diameter = sysml_requirements::number(source, own("minimumInstalledBodyDiameterM"));
    let tank_axis = _enum_name(source, "tankAxis");
    let band_shape = _enum_name(source, "retentionBandShape");
    let axial_shape = _enum_name(source, "axialHardwareShape");
    let transition_shape = _enum_name(source, "transitionShape");
    let band_centers = sysml_requirement_checks::source_number_list(source, own("bandCenterYM"));
    let band_radii = sysml_requirement_checks::source_number_list(source, own("bandRadiusByCenterM"));
    let band_height = sysml_requirements::number(source, own("bandHeightM"));

    let neck_radius = sysml_requirements::number(source, own("neckRadiusM"));
    let neck_height = sysml_requirements::number(source, own("neckHeightM"));
    let shoulder_radius = sysml_requirements::number(source, own("shoulderCollarRadiusM"));
    let shoulder_height = sysml_requirements::number(source, own("shoulderCollarHeightM"));
    let valve_radius = sysml_requirements::number(source, own("valveRadiusM"));
    let valve_height = sysml_requirements::number(source, own("valveHeightM"));
    let cap_radius = sysml_requirements::number(source, own("valveCapRadiusM"));
    let cap_height = sysml_requirements::number(source, own("valveCapHeightM"));
    let transition_shoulder_radius = sysml_requirements::number(source, own("transitionShoulderRadiusM"));
    let transition_neck_radius = sysml_requirements::number(source, own("transitionNeckRadiusM"));
    let transition_height = sysml_requirements::number(source, own("transitionHeightM"));
    let transition_radius = sysml_requirements::number(source, own("transitionRadiusM"));
    let shoulder_center_y = sysml_requirements::number(source, own("shoulderCenterYM"));
    let transition_center_y = sysml_requirements::number(source, own("transitionCenterYM"));
    let neck_center_y = sysml_requirements::number(source, own("neckCenterYM"));
    let valve_center_y = sysml_requirements::number(source, own("valveCenterYM"));
    let cap_center_y = sysml_requirements::number(source, own("capCenterYM"));

    let cradle_name = _enum_name(source, "cradleName");
    let cradle_shape = _enum_name(source, "cradleShape");
    let cradle_radius = sysml_requirements::number(source, own("cradleRadiusM"));
    let cradle_height = sysml_requirements::number(source, own("cradleHeightM"));
    let pad_name = _enum_name(source, "cradlePadName");
    let pad_shape = _enum_name(source, "cradlePadShape");
    let pad_width = sysml_requirements::number(source, own("cradlePadWidthM"));
    let pad_depth = sysml_requirements::number(source, own("cradlePadDepthM"));
    let pad_height = sysml_requirements::number(source, own("cradlePadHeightM"));
    let support_name = _enum_name(source, "supportName");
    let support_shape = _enum_name(source, "supportShape");
    let support_radius = sysml_requirements::number(source, own("supportRadiusM"));
    let minimum_skirt_clearance = sysml_requirements::number(source, own("minimumSkirtClearanceM"));

    let body_mount = sysml_requirements::native_value(source, visual("bodyMount"));
    let skirt_center = sysml_requirements::native_value(source, visual("lowerSkirtCenter"));
    let skirt_dimensions = sysml_requirements::native_value(source, visual("lowerSkirtDimensions"));
    let bracket_group_name = _enum_name(source, "bracketGroupName");
    let bracket_shape = _enum_name(source, "bracketShape");
    let bracket_length = sysml_requirements::number(source, own("bracketLengthM"));
    let bracket_width = sysml_requirements::number(source, own("bracketWidthM"));
    let bracket_depth = sysml_requirements::number(source, own("bracketDepthM"));
    let bracket_offset = sysml_requirements::number(source, own("bracketCenterOffsetM"));
    let bracket_tilt = sysml_requirements::number(source, own("bracketTiltDeg"));
    let shell_contact_tolerance = sysml_requirements::number(source,
        own("bracketShellContactToleranceM"));
    let verification_tolerance = sysml_requirements::number(source,
        visual("verificationToleranceM"));

    let source_ready = source != () && source.ok == true && root != ();
    let identities_ready = tank_names.len() == 4 && tank_stations.len() == 4
        && tank_scales.len() == 4 && child_names.len() == 17
        && band_names.len() == 3 && end_names.len() == 2
        && service_names.len() == 6 && axial_names.len() == 11
        && bracket_names.len() == 4;
    let body_ready = body_name != () && body_shape == "Sphere"
        && vec3_is_native(body_center) && body_radius != ()
        && minimum_installed_diameter != ()
        && tank_axis == "Y" && band_shape == "Cylinder"
        && axial_shape == "Cylinder" && transition_shape == "Cone";
    let band_ready = band_centers.len() == 3 && band_radii.len() == 3
        && band_height != ();
    let hardware_ready = neck_radius != () && neck_height != ()
        && shoulder_radius != () && shoulder_height != ()
        && valve_radius != () && valve_height != ()
        && cap_radius != () && cap_height != ();
    let transition_ready = transition_shoulder_radius != ()
        && transition_neck_radius != () && transition_height != ()
        && transition_radius != () && shoulder_center_y != ()
        && transition_center_y != () && neck_center_y != ()
        && valve_center_y != () && cap_center_y != ();
    let cradle_ready = cradle_name != () && cradle_shape == "Cylinder"
        && cradle_radius != () && cradle_height != ();
    let pad_ready = pad_name != () && pad_shape == "Cube"
        && pad_width != () && pad_depth != () && pad_height != ();
    let support_ready = support_name != () && support_shape == "Cylinder"
        && support_radius != () && minimum_skirt_clearance != ();
    let skirt_ready = vec3_is_native(body_mount)
        && vec3_is_native(skirt_center) && vec3_is_native(skirt_dimensions);
    let brackets_ready = bracket_group_name != () && bracket_shape == "Cube"
        && bracket_length != () && bracket_width != () && bracket_depth != ()
        && bracket_offset != () && bracket_tilt != ();
    let clearance_contract_ready = perimeter_stations.len() == 8 && frame_section != ()
        && minimum_instance_clearance != () && minimum_frame_clearance != ()
        && shell_contact_tolerance != () && verification_tolerance != ();
    let complete = source_ready && identities_ready && body_ready && band_ready
        && hardware_ready && transition_ready && cradle_ready && pad_ready
        && support_ready && skirt_ready && brackets_ready && clearance_contract_ready;
    if !complete {
        let checks = [sysml_requirement_checks::preflight("GPT-source", false,
            "typed tank source facts are incomplete or have the wrong shape",
            #{tank_count: tank_names.len(), station_count: tank_stations.len(),
              body_shape: body_shape, source_ready: source_ready, identities_ready: identities_ready, body_ready: body_ready, band_ready: band_ready, hardware_ready: hardware_ready, transition_ready: transition_ready, cradle_ready: cradle_ready, pad_ready: pad_ready, support_ready: support_ready, skirt_ready: skirt_ready, brackets_ready: brackets_ready, clearance_contract_ready: clearance_contract_ready},
            #{tank_count: 4, station_count: 4, body_shape: "Sphere"})];
        sysml_requirement_checks::finish_preflight(checks, "GRIFFIN TANK REQUIREMENTS",
            "GRIFFIN_TANK_REQUIREMENTS", root, PACKAGE);
        this.done = true;
        return;
    }

    let tank_count = parent("tankCount");
    let bracket_group_name_text = bracket_group_name;
    let tank_channels = [];
    let tank_results = [];
    let aggregate_requirement_names = [];
    let aggregate_requirement_summary = #{};
    let aggregate_check_count = 0;
    let aggregate_failure_count = 0;
    let aggregate_ok = true;
    let aggregate_verification = VERIFICATION;

    let maximum_band_radius = band_radii[0];
    for radius in band_radii {
        if radius > maximum_band_radius { maximum_band_radius = radius; }
    }
    let pad_corner_radius = (pad_width * pad_width + pad_depth * pad_depth).sqrt() / 2.0;
    let bracket_angle = bracket_tilt * 3.141592653589793 / 180.0;
    let brace_tilt_extension = bracket_length * bracket_angle.sin() * (2.0).sqrt();
    let brace_corner_radius = ((bracket_offset + bracket_width / 2.0
            + brace_tilt_extension) * (bracket_offset + bracket_width / 2.0
            + brace_tilt_extension)
        + (bracket_offset + bracket_depth / 2.0 + brace_tilt_extension)
            * (bracket_offset + bracket_depth / 2.0 + brace_tilt_extension)).sqrt();
    let local_envelope_radius = body_radius;
    if maximum_band_radius > local_envelope_radius { local_envelope_radius = maximum_band_radius; }
    if cradle_radius > local_envelope_radius { local_envelope_radius = cradle_radius; }
    if pad_corner_radius > local_envelope_radius { local_envelope_radius = pad_corner_radius; }
    if brace_corner_radius > local_envelope_radius { local_envelope_radius = brace_corner_radius; }
    let tank_clearances = _tank_clearances(tank_stations, perimeter_stations,
        frame_section,
        local_envelope_radius * tank_scales[0]);

    for tank_index in 0..tank_names.len() {
        let checks = [];
        let tank_name = tank_names[tank_index];
        let tank_path = root + "/" + tank_name;
        let station = tank_stations[tank_index];
        let tank_scale = tank_scales[tank_index];
        let payload_dimensions = sysml_requirements::native_value(source, visual("payloadAdapterDimensions"));
        let payload_bottom = sysml_requirements::number(source, visual("payloadAdapterCenterYM")) - payload_dimensions.y / 2.0;
        let upper_envelope = body_radius;
        if cap_center_y + cap_height / 2.0 > upper_envelope {upper_envelope=cap_center_y+cap_height/2.0;}
        checks.push(_constraint("GPT-005-"+tank_name+"-payload-clearance", "gpt005", "GPT005_MinimumClearance",
            #{actualClearanceM:payload_bottom-station.y-upper_envelope*tank_scale,
              requiredClearanceM:sysml_requirements::number(source,visual("minimumTankPayloadClearanceM"))}));

        if tank_index == 0 {
            checks.push(sysml_requirement_checks::source_list_count("GPT-001-count", "tank", "gpt001",
                VERIFICATION, visual("tankInstances"), tank_count));
            checks.push(sysml_requirement_checks::source_list_count("GPT-005-stations", "tank", "gpt005",
                VERIFICATION, visual("tankStations"), tank_count));
            checks.push(_constraint("GPT-005-instance-clearance", "gpt005",
                "GPT005_MinimumClearance",
                #{actualClearanceM: tank_clearances.instance,
                  requiredClearanceM: minimum_instance_clearance}));
            checks.push(_constraint("GPT-005-frame-clearance", "gpt005",
                "GPT005_MinimumClearance",
                #{actualClearanceM: tank_clearances.frame,
                  requiredClearanceM: minimum_frame_clearance}));
            checks.push(_constraint("GPT-006-installed-diameter", "gpt006",
                "GPT006_MinimumInstalledDiameter",
                #{installedDiameterM: 2.0 * body_radius * tank_scale,
                  requiredDiameterM: minimum_installed_diameter}));
        }
        let direct_children = [];
        for child_name in child_names { direct_children.push(tank_path + "/" + child_name); }
        direct_children.push(tank_path + "/" + bracket_group_name_text);
        checks.push(sysml_requirement_checks::exists("GPT-001-" + tank_name, "tank", "gpt001",
            VERIFICATION, tank_path, "Xform"));
        checks.push(sysml_requirement_checks::children("GPT-002-" + tank_name, "tank", "gpt002",
            VERIFICATION, tank_path, direct_children));
        checks.push(_position("GPT-005-" + tank_name + "-x", "gpt005", tank_path, 0, station.x));
        checks.push(_position("GPT-005-" + tank_name + "-y", "gpt005", tank_path, 1, station.y));
        checks.push(_position("GPT-005-" + tank_name + "-z", "gpt005", tank_path, 2, station.z));
        checks.push(#{id: "GPT-005-" + tank_name + "-scale-x", component: "tank",
            requirement: "gpt005", verification: VERIFICATION, kind: "attribute_component",
            path: tank_path, attr: "xformOp:scale", index: 0, expected: tank_scale, tolerance: 0.002});
        checks.push(#{id: "GPT-005-" + tank_name + "-scale-y", component: "tank",
            requirement: "gpt005", verification: VERIFICATION, kind: "attribute_component",
            path: tank_path, attr: "xformOp:scale", index: 1, expected: tank_scale, tolerance: 0.002});
        checks.push(#{id: "GPT-005-" + tank_name + "-scale-z", component: "tank",
            requirement: "gpt005", verification: VERIFICATION, kind: "attribute_component",
            path: tank_path, attr: "xformOp:scale", index: 2, expected: tank_scale, tolerance: 0.002});

        let body_path = tank_path + "/" + body_name;
        checks.push(sysml_requirement_checks::exists("GPT-006-" + tank_name + "-spherical-body",
            "tank", "gpt006", VERIFICATION, body_path, "Sphere"));
        checks.push(_attribute("GPT-006-" + tank_name + "-radius", "gpt006",
            body_path, "radius", body_radius));
        _position3(checks, "GPT-008-" + tank_name + "-body-center", "gpt008",
            body_path, body_center);

        for band_index in 0..band_names.len() {
            let band_name = band_names[band_index];
            let band_path = tank_path + "/" + band_name;
            checks.push(sysml_requirement_checks::exists("GPT-002-" + tank_name + "-" + band_name,
                "tank", "gpt002", VERIFICATION, band_path, band_shape));
            checks.push(_attribute("GPT-002-" + tank_name + "-" + band_name + "-radius",
                "gpt002", band_path, "radius", band_radii[band_index]));
            checks.push(_attribute("GPT-002-" + tank_name + "-" + band_name + "-height",
                "gpt002", band_path, "height", band_height));
            checks.push(_position("GPT-002-" + tank_name + "-" + band_name + "-y",
                "gpt002", band_path, 1, band_centers[band_index]));
            checks.push(sysml_requirement_checks::attribute_equals(
                "GPT-008-" + tank_name + "-" + band_name + "-axis", "tank", "gpt008",
                VERIFICATION, band_path, "axis", tank_axis));
        }

        let symmetric_hardware = [
            #{name: end_names[0], shape: axial_shape, radius: neck_radius, height: neck_height, y: neck_center_y},
            #{name: end_names[1], shape: axial_shape, radius: neck_radius, height: neck_height, y: -neck_center_y},
            #{name: service_names[0], shape: axial_shape, radius: shoulder_radius, height: shoulder_height, y: shoulder_center_y},
            #{name: service_names[1], shape: axial_shape, radius: shoulder_radius, height: shoulder_height, y: -shoulder_center_y},
            #{name: service_names[2], shape: axial_shape, radius: valve_radius, height: valve_height, y: valve_center_y},
            #{name: service_names[3], shape: axial_shape, radius: valve_radius, height: valve_height, y: -valve_center_y},
            #{name: service_names[4], shape: axial_shape, radius: cap_radius, height: cap_height, y: cap_center_y},
            #{name: service_names[5], shape: axial_shape, radius: cap_radius, height: cap_height, y: -cap_center_y},
        ];
        for hardware in symmetric_hardware {
            let hardware_path = tank_path + "/" + hardware.name;
            checks.push(sysml_requirement_checks::exists("GPT-006-" + tank_name + "-" + hardware.name,
                "tank", "gpt006", VERIFICATION, hardware_path, hardware.shape));
            checks.push(_attribute("GPT-006-" + tank_name + "-" + hardware.name + "-radius",
                "gpt006", hardware_path, "radius", hardware.radius));
            checks.push(_attribute("GPT-006-" + tank_name + "-" + hardware.name + "-height",
                "gpt006", hardware_path, "height", hardware.height));
            checks.push(_position("GPT-006-" + tank_name + "-" + hardware.name + "-y",
                "gpt006", hardware_path, 1, hardware.y));
            checks.push(sysml_requirement_checks::attribute_equals(
                "GPT-008-" + tank_name + "-" + hardware.name + "-axis", "tank", "gpt008",
                VERIFICATION, hardware_path, "axis", tank_axis));
        }

        for transition_index in 0..2 {
            let transition_name = axial_names[8 + transition_index];
            let transition_path = tank_path + "/" + transition_name;
            let top = transition_index == 0;
            checks.push(sysml_requirement_checks::exists("GPT-006-" + tank_name + "-" + transition_name,
                "tank", "gpt006", VERIFICATION, transition_path, transition_shape));
            checks.push(_attribute("GPT-006-" + tank_name + "-" + transition_name + "-radius1",
                "gpt006", transition_path, "radius1",
                if top { transition_shoulder_radius } else { transition_neck_radius }));
            checks.push(_attribute("GPT-006-" + tank_name + "-" + transition_name + "-radius2",
                "gpt006", transition_path, "radius2",
                if top { transition_neck_radius } else { transition_shoulder_radius }));
            checks.push(_attribute("GPT-006-" + tank_name + "-" + transition_name + "-height",
                "gpt006", transition_path, "height", transition_height));
            checks.push(_position("GPT-006-" + tank_name + "-" + transition_name + "-y",
                "gpt006", transition_path, 1, if top { transition_center_y } else { -transition_center_y }));
            checks.push(sysml_requirement_checks::attribute_equals(
                "GPT-008-" + tank_name + "-" + transition_name + "-axis", "tank", "gpt008",
                VERIFICATION, transition_path, "axis", tank_axis));
        }

        let skirt_seat_world_y = body_mount.y + skirt_center.y - skirt_dimensions.y / 2.0;
        let cradle_top_world_y = skirt_seat_world_y + minimum_skirt_clearance;
        let cradle_top_local_y = (cradle_top_world_y - station.y) / tank_scale;
        let cradle_center_local_y = cradle_top_local_y - cradle_height / 2.0;
        let pad_center_local_y = cradle_top_local_y + pad_height / 2.0;
        let pad_top_local_y = cradle_top_local_y + pad_height;
        let support_bottom_local_y = pad_top_local_y;
        let support_top_local_y = -neck_center_y - neck_height / 2.0;
        let support_height = support_top_local_y - support_bottom_local_y;
        let support_center_local_y = (support_top_local_y + support_bottom_local_y) / 2.0;
        let brace = griffin_geometry::tank_brace_datum(pad_top_local_y, bracket_offset, bracket_length, bracket_tilt);
        let bracket_center_x = brace.center[0];
        let bracket_center_local_y = brace.center[1];
        let bracket_center_z = brace.center[2];

        let cradle_path = tank_path + "/" + cradle_name;
        checks.push(sysml_requirement_checks::exists("GPT-009-" + tank_name + "-cradle",
            "tank", "gpt009", VERIFICATION, cradle_path, "Cylinder"));
        checks.push(_attribute("GPT-009-" + tank_name + "-cradle-radius", "gpt009",
            cradle_path, "radius", cradle_radius));
        checks.push(_attribute("GPT-009-" + tank_name + "-cradle-height", "gpt009",
            cradle_path, "height", cradle_height));
        checks.push(_position("GPT-009-" + tank_name + "-cradle-y", "gpt009",
            cradle_path, 1, cradle_center_local_y));

        let pad_path = tank_path + "/" + pad_name;
        checks.push(sysml_requirement_checks::exists("GPT-009-" + tank_name + "-pad",
            "tank", "gpt009", VERIFICATION, pad_path, "Cube"));
        checks.push(_position("GPT-009-" + tank_name + "-pad-y", "gpt009",
            pad_path, 1, pad_center_local_y));
        checks.push(#{id: "GPT-009-" + tank_name + "-pad-scale-x", component: "tank",
            requirement: "gpt009", verification: VERIFICATION, kind: "attribute_component",
            path: pad_path, attr: "xformOp:scale", index: 0, expected: pad_width, tolerance: 0.002});
        checks.push(#{id: "GPT-009-" + tank_name + "-pad-scale-y", component: "tank",
            requirement: "gpt009", verification: VERIFICATION, kind: "attribute_component",
            path: pad_path, attr: "xformOp:scale", index: 1, expected: pad_height, tolerance: 0.002});
        checks.push(#{id: "GPT-009-" + tank_name + "-pad-scale-z", component: "tank",
            requirement: "gpt009", verification: VERIFICATION, kind: "attribute_component",
            path: pad_path, attr: "xformOp:scale", index: 2, expected: pad_depth, tolerance: 0.002});

        let support_path = tank_path + "/" + support_name;
        checks.push(sysml_requirement_checks::exists("GPT-009-" + tank_name + "-support",
            "tank", "gpt009", VERIFICATION, support_path, "Cylinder"));
        checks.push(_attribute("GPT-009-" + tank_name + "-support-radius", "gpt009",
            support_path, "radius", support_radius));
        checks.push(_attribute("GPT-009-" + tank_name + "-support-height", "gpt009",
            support_path, "height", support_height));
        checks.push(_position("GPT-009-" + tank_name + "-support-y", "gpt009",
            support_path, 1, support_center_local_y));

        let bracket_group_path = tank_path + "/" + bracket_group_name_text;
        let bracket_paths = [];
        for bracket_name in bracket_names { bracket_paths.push(bracket_group_path + "/" + bracket_name); }
        checks.push(sysml_requirement_checks::exists("GPT-010-" + tank_name + "-group", "tank",
            "gpt010", VERIFICATION, bracket_group_path, "Xform"));
        checks.push(sysml_requirement_checks::children("GPT-010-" + tank_name + "-brackets", "tank",
            "gpt010", VERIFICATION, bracket_group_path, bracket_paths));
        let bracket_x = [bracket_center_x, -bracket_center_x, bracket_center_x, -bracket_center_x];
        let bracket_z = [bracket_center_z, bracket_center_z, -bracket_center_z, -bracket_center_z];
        let bracket_rx = [-bracket_tilt, -bracket_tilt, bracket_tilt, bracket_tilt];
        let bracket_rz = [-bracket_tilt, bracket_tilt, -bracket_tilt, bracket_tilt];
        for bracket_index in 0..bracket_names.len() {
            let bracket_name = bracket_names[bracket_index];
            let bracket_path = bracket_paths[bracket_index];
            checks.push(sysml_requirement_checks::exists("GPT-010-" + tank_name + "-" + bracket_name,
                "tank", "gpt010", VERIFICATION, bracket_path, "Cube"));
            checks.push(_position("GPT-010-" + tank_name + "-" + bracket_name + "-x", "gpt010",
                bracket_path, 0, bracket_x[bracket_index]));
            checks.push(_position("GPT-010-" + tank_name + "-" + bracket_name + "-y", "gpt010",
                bracket_path, 1, bracket_center_local_y));
            checks.push(_position("GPT-010-" + tank_name + "-" + bracket_name + "-z", "gpt010",
                bracket_path, 2, bracket_z[bracket_index]));
            checks.push(#{id: "GPT-010-" + tank_name + "-" + bracket_name + "-rotate-x",
                component: "tank", requirement: "gpt010", verification: VERIFICATION,
                kind: "attribute_component", path: bracket_path, attr: "xformOp:rotateXYZ",
                index: 0, expected: bracket_rx[bracket_index], tolerance: 0.002});
            checks.push(#{id: "GPT-010-" + tank_name + "-" + bracket_name + "-rotate-z",
                component: "tank", requirement: "gpt010", verification: VERIFICATION,
                kind: "attribute_component", path: bracket_path, attr: "xformOp:rotateXYZ",
                index: 2, expected: bracket_rz[bracket_index], tolerance: 0.002});
            checks.push(#{id: "GPT-010-" + tank_name + "-" + bracket_name + "-scale-x",
                component: "tank", requirement: "gpt010", verification: VERIFICATION,
                kind: "attribute_component", path: bracket_path, attr: "xformOp:scale",
                index: 0, expected: bracket_width, tolerance: 0.002});
            checks.push(#{id: "GPT-010-" + tank_name + "-" + bracket_name + "-scale-y",
                component: "tank", requirement: "gpt010", verification: VERIFICATION,
                kind: "attribute_component", path: bracket_path, attr: "xformOp:scale",
                index: 1, expected: bracket_length, tolerance: 0.002});
            checks.push(#{id: "GPT-010-" + tank_name + "-" + bracket_name + "-scale-z",
                component: "tank", requirement: "gpt010", verification: VERIFICATION,
                kind: "attribute_component", path: bracket_path, attr: "xformOp:scale",
                index: 2, expected: bracket_depth, tolerance: 0.002});
        }

        let skirt_clearance = station.y + tank_scale * (cradle_center_local_y + cradle_height / 2.0)
            - skirt_seat_world_y;
        checks.push(_constraint("GPT-009-" + tank_name + "-skirt-clearance",
            "gpt009", "GPT009_SkirtClearanceMatchesDatum",
            #{actualClearanceM: skirt_clearance,
              requiredClearanceM: minimum_skirt_clearance,
              toleranceM: verification_tolerance}));
        checks.push(_constraint("GPT-009-" + tank_name + "-support-span",
            "gpt009", "GPT009_SupportPostSpansSeat",
            #{lowerSeatYM: support_bottom_local_y,
              upperContactYM: support_top_local_y,
              supportHeightM: support_height,
              toleranceM: verification_tolerance}));
        let shell_tip_radius = (brace.tip[0] * brace.tip[0] + brace.tip[1] * brace.tip[1] + brace.tip[2] * brace.tip[2]).sqrt();
        checks.push(_constraint("GPT-010-" + tank_name + "-shell-contact",
            "gpt010", "GPT010_BraceContactsVesselEnvelope",
            #{radialErrorM: shell_tip_radius - body_radius,
              toleranceM: shell_contact_tolerance}));

        if tank_index + 1 == tank_names.len() {
            checks.push(sysml_requirement_checks::coverage("GPT-003-status", "tank", "gpt003", VERIFICATION));
            checks.push(sysml_requirement_checks::coverage("GPT-004-traceability", "tank", "gpt004", VERIFICATION));
            checks.push(sysml_requirement_checks::coverage("GPT-011-component-identity", "tank", "gpt011", VERIFICATION));
        }
        let tank_channel = "GRIFFIN_TANK_REQUIREMENTS_" + tank_name;
        tank_channels.push(tank_channel);
        let tank_result = sysml_requirement_checks::finish(source, checks,
            "GRIFFIN TANK REQUIREMENTS " + tank_name, tank_channel,
            root + "/" + tank_name, PACKAGE, VERIFICATION);
        aggregate_ok = aggregate_ok && tank_result.ok == true;
        aggregate_check_count += tank_result.check_count;
        aggregate_failure_count += tank_result.failure_count;
        aggregate_verification = tank_result.verification;
        tank_results.push(#{component: tank_name, channel: tank_channel,
            ok: tank_result.ok, check_count: tank_result.check_count,
            failure_count: tank_result.failure_count});
        for requirement in tank_result.requirement_names {
            if aggregate_requirement_summary[requirement] == () {
                aggregate_requirement_summary[requirement] = #{checks: 0, failures: 0};
                aggregate_requirement_names.push(requirement);
            }
            aggregate_requirement_summary[requirement].checks +=
                tank_result.requirement_summary[requirement].checks;
            aggregate_requirement_summary[requirement].failures +=
                tank_result.requirement_summary[requirement].failures;
        }
    }

    let aggregate = #{ok: aggregate_ok, results: [], failures: [], result_chunks: [],
        failure_chunks: [], streamed: true, check_count: aggregate_check_count,
        requirement_count: aggregate_requirement_names.len(),
        requirement_names: aggregate_requirement_names,
        requirement_summary: aggregate_requirement_summary,
        failure_count: aggregate_failure_count, verification: aggregate_verification,
        source_revision: source.source_revision, source_files: source.source_files,
        evidence_result_events: 0, evidence_channels: tank_channels,
        metrics: #{root: root, component_package: PACKAGE,
            verification: aggregate_verification, components: tank_results,
            separate_component_document: true}};
    report_structured_verdict(aggregate, "GRIFFIN TANK REQUIREMENTS",
        "GRIFFIN_TANK_REQUIREMENTS");
    this.done = true;
}
