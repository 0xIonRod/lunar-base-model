import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
// Standalone Griffin dual solar-array visual verification.

const PACKAGE = "GriffinSolarRequirements";
const VERIFICATION = "Verify_GriffinSolarRequirements";

fn own(name) { PACKAGE + "::GriffinSolarArrayAssembly::" + name }
fn visual(name) { "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::" + name }

fn position(id, path, index, expected, tolerance) {
    #{id: id, component: "solar_array", requirement: "gsa005",
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: "xformOp:translate", index: index, expected: expected, tolerance: tolerance}
}

fn component_position(id, requirement, path, index, expected, tolerance) {
    #{id: id, component: "solar_array", requirement: requirement,
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: "xformOp:translate", index: index, expected: expected, tolerance: tolerance}
}

fn bounds_overlap_depth(left, right) {
    if left == () || right == () || left.min == () || right.min == ()
        || left.max == () || right.max == () { return (); }
    let depth = [];
    for axis in 0..3 {
        let lower = if left.min[axis] > right.min[axis] { left.min[axis] } else { right.min[axis] };
        let upper = if left.max[axis] < right.max[axis] { left.max[axis] } else { right.max[axis] };
        if upper < lower { return 0.0; }
        depth.push(upper - lower);
    }
    let result = depth[0];
    if depth[1] < result { result = depth[1]; }
    if depth[2] < result { result = depth[2]; }
    result
}

fn minimum(left, right) { if left < right { left } else { right } }

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source();
    let root = sysml_requirements::text(source, own("usdRootPath"));
    let geometry_tolerance = sysml_requirements::number(source, visual("geometryVerificationToleranceM"));
    let names = sysml_requirement_checks::source_enum_identifiers(source, visual("solarArrayInstances"));
    let stations = sysml_requirement_checks::source_position_list(source, visual("solarStations"));
    let members = sysml_requirement_checks::source_enum_identifiers(source, own("childNames"));
    let count = "GriffinLanderRequirements::GriffinLanderComponent::solarArrayCount";
    let rotx = sysml_requirement_checks::source_number_list(source, visual("solarStationRotationXDeg"));
    let rotz = sysml_requirement_checks::source_number_list(source, visual("solarStationRotationZDeg"));
    let rail_names = sysml_requirement_checks::source_enum_identifiers(source, visual("frameRails"));
    let rail_stations = sysml_requirement_checks::source_position_list(source, visual("railStations"));
    let mount_rails = sysml_requirement_checks::source_enum_identifiers(source, visual("solarMountRails"));
    let mount_rail_x = [];
    let mount_rail_z = [];
    if rail_names.len() == rail_stations.len() {
        for mount_rail in mount_rails {
            for index in 0..rail_names.len() {
                if rail_names[index] == mount_rail {
                    mount_rail_x.push(rail_stations[index].x);
                    mount_rail_z.push(rail_stations[index].z);
                }
            }
        }
    }
    let mount_overlap = sysml_requirements::number(source, own("minimumMountOverlapM"));
    let checks = [];
    checks.push(sysml_requirement_checks::source_list_count("GSA-001-count", "lander_solar", "gsa001", VERIFICATION, visual("solarArrayInstances"), count));
    checks.push(sysml_requirement_checks::source_list_count("GSA-005-stations", "solar_array", "gsa005", VERIFICATION, visual("solarStations"), count));
    checks.push(sysml_requirement_checks::source_list_count("GSA-005-rotation-x", "solar_array", "gsa005", VERIFICATION, visual("solarStationRotationXDeg"), count));
    checks.push(sysml_requirement_checks::source_list_count("GSA-005-rotation-z", "solar_array", "gsa005", VERIFICATION, visual("solarStationRotationZDeg"), count));
    for index in 0..names.len() {
        let name = names[index];
        let path = root + "/" + name;
        checks.push(sysml_requirement_checks::exists("GSA-001-" + name, "solar_array", "gsa001", VERIFICATION, path, "Xform"));
        let required_children = [];
        for member in members { required_children.push(path + "/" + member); }
        checks.push(sysml_requirement_checks::children("GSA-002-" + name, "solar_array", "gsa002", VERIFICATION, path,
            required_children));
        if stations.len() == names.len() {
            checks.push(position("GSA-005-" + name + "-x", path, 0, stations[index].x, geometry_tolerance));
            checks.push(position("GSA-005-" + name + "-y", path, 1, stations[index].y, geometry_tolerance));
            checks.push(position("GSA-005-" + name + "-z", path, 2, stations[index].z, geometry_tolerance));
        }
        if rotx.len() == names.len() && rotz.len() == names.len() {
            checks.push(#{id: "GSA-005-" + name + "-rotx", component: "solar_array",
                requirement: "gsa005", verification: VERIFICATION, kind: "attribute_component",
                path: path, attr: "xformOp:rotateXYZ", index: 0, expected: rotx[index], tolerance: geometry_tolerance});
            checks.push(#{id: "GSA-005-" + name + "-rotz", component: "solar_array",
                requirement: "gsa005", verification: VERIFICATION, kind: "attribute_component",
                path: path, attr: "xformOp:rotateXYZ", index: 2, expected: rotz[index], tolerance: geometry_tolerance});
        }
        checks.push(sysml_requirement_checks::bounds_component("GSA-006-" + name + "-frame-width", "solar_array", "gsa006", VERIFICATION,
            path + "/Frame", 0, own("frameWidthM"), 2.0, geometry_tolerance));
        checks.push(sysml_requirement_checks::bounds_component("GSA-006-" + name + "-frame-thickness", "solar_array", "gsa006", VERIFICATION,
            path + "/Frame", 1, own("frameThicknessM"), 2.0, geometry_tolerance));
        checks.push(sysml_requirement_checks::bounds_component("GSA-006-" + name + "-frame-depth", "solar_array", "gsa006", VERIFICATION,
            path + "/Frame", 2, own("frameDepthM"), 2.0, geometry_tolerance));
        checks.push(sysml_requirement_checks::extent_component("GSA-006-" + name + "-cell-width", "solar_array", "gsa006", VERIFICATION,
            path + "/Cells", 0, own("cellWidthM"), 1.0, geometry_tolerance));
        checks.push(sysml_requirement_checks::extent_component("GSA-006-" + name + "-cell-thickness", "solar_array", "gsa006", VERIFICATION,
            path + "/Cells", 1, own("cellThicknessM"), 1.0, geometry_tolerance));
        checks.push(sysml_requirement_checks::extent_component("GSA-006-" + name + "-cell-depth", "solar_array", "gsa006", VERIFICATION,
            path + "/Cells", 2, own("cellDepthM"), 1.0, geometry_tolerance));
        checks.push(#{id: "GSA-006-" + name + "-cell-offset", component: "solar_array",
            requirement: "gsa006", verification: VERIFICATION, kind: "attribute_component",
            path: path + "/Cells", attr: "xformOp:translate", index: 1,
            expected_attr: own("cellOffsetYM"), tolerance: geometry_tolerance});
        for side in ["Port", "Starboard"] {
            let bracket_path = path + "/MountBracket" + side;
            checks.push(sysml_requirement_checks::extent_component("GSA-007-" + name + "-" + side + "-mount-width", "solar_array", "gsa007", VERIFICATION,
                bracket_path, 0, own("mountBracketWidthM"), 1.0, geometry_tolerance));
            checks.push(sysml_requirement_checks::extent_component("GSA-007-" + name + "-" + side + "-mount-thickness", "solar_array", "gsa007", VERIFICATION,
                bracket_path, 1, own("mountBracketThicknessM"), 1.0, geometry_tolerance));
            checks.push(sysml_requirement_checks::extent_component("GSA-007-" + name + "-" + side + "-mount-depth", "solar_array", "gsa007", VERIFICATION,
                bracket_path, 2, own("mountBracketDepthM"), 1.0, geometry_tolerance));
            if mount_rail_x.len() == 4 && mount_rail_z.len() == 4 {
                let mount_index = if side == "Port" { 0 } else { 1 };
                let rail_index = index * 2 + mount_index;
                let expected_x = mount_rail_x[rail_index];
                let rotation_sign = if rotx[index] > 0.0 { 1.0 } else { -1.0 };
                let expected_y = (mount_rail_z[rail_index] - stations[index].z) / rotation_sign;
                checks.push(component_position("GSA-007-" + name + "-" + side + "-bracket-station",
                    "gsa007", bracket_path, 0, expected_x, geometry_tolerance));
                checks.push(component_position("GSA-007-" + name + "-" + side + "-bracket-rail-z",
                    "gsa007", bracket_path, 1, expected_y, geometry_tolerance));
            }
        }
        checks.push(#{id: "GSA-008-" + name + "-hinge-axis", component: "solar_array",
            requirement: "gsa008", verification: VERIFICATION, kind: "attribute",
            path: path + "/HingeBar", attr: "axis", expected: "X"});
        checks.push(#{id: "GSA-008-" + name + "-hinge-radius", component: "solar_array",
            requirement: "gsa008", verification: VERIFICATION, kind: "attribute",
            path: path + "/HingeBar", attr: "radius", expected_attr: own("hingeBarRadiusM"), tolerance: geometry_tolerance});
        checks.push(#{id: "GSA-008-" + name + "-hinge-length", component: "solar_array",
            requirement: "gsa008", verification: VERIFICATION, kind: "attribute",
            path: path + "/HingeBar", attr: "height", expected_attr: own("hingeBarLengthM"), tolerance: geometry_tolerance});
        checks.push(#{id: "GSA-008-" + name + "-hinge-y", component: "solar_array",
            requirement: "gsa008", verification: VERIFICATION, kind: "attribute_component",
            path: path + "/HingeBar", attr: "xformOp:translate", index: 1,
            expected_attr: own("hingeBarCenterYM"), tolerance: geometry_tolerance});
        checks.push(#{id: "GSA-008-" + name + "-hinge-z", component: "solar_array",
            requirement: "gsa008", verification: VERIFICATION, kind: "attribute_component",
            path: path + "/HingeBar", attr: "xformOp:translate", index: 2,
            expected_attr: own("hingeBarCenterZM"), tolerance: geometry_tolerance});
        for side in ["Port", "Starboard"] {
            let link_path = path + "/MountLink" + side;
            checks.push(sysml_requirement_checks::extent_component("GSA-008-" + name + "-" + side + "-link-height", "solar_array", "gsa008", VERIFICATION,
                link_path, 1, own("mountLinkHeightM"), 1.0, geometry_tolerance));
            checks.push(sysml_requirement_checks::extent_component("GSA-008-" + name + "-" + side + "-link-depth", "solar_array", "gsa008", VERIFICATION,
                link_path, 2, own("mountLinkDepthM"), 1.0, geometry_tolerance));
            if mount_rail_x.len() == 4 {
                let mount_index = if side == "Port" { 0 } else { 1 };
                let rail_index = index * 2 + mount_index;
                let rail_x = mount_rail_x[rail_index];
                let half_width = sysml_requirements::number(source, own("frameWidthM")) / 2.0;
                let overlap_extension = mount_overlap * 2.0;
                let magnitude = rail_x.abs();
                let link_width = half_width - magnitude + overlap_extension;
                let link_center = (half_width + magnitude - overlap_extension) / 2.0;
                checks.push(#{id: "GSA-008-" + name + "-" + side + "-link-width", component: "solar_array",
                    requirement: "gsa008", verification: VERIFICATION, kind: "extent_component",
                    path: link_path, index: 0, expected: link_width, multiplier: 1.0, tolerance: geometry_tolerance});
                checks.push(component_position("GSA-008-" + name + "-" + side + "-link-station",
                    "gsa008", link_path, 0,
                    if rail_x < 0.0 { -link_center } else { link_center }, geometry_tolerance));
            }
        }
    }
    if mount_overlap != () && mount_rail_x.len() == 4
        && mount_rail_z.len() == 4 && names.len() == 2 {
        let bus_rails = [];
        for mount_rail in mount_rails {
            bus_rails.push(root + "/Bus/" + mount_rail);
        }
        let paths = [bus_rails[0], bus_rails[1], bus_rails[2], bus_rails[3]];
        for name in names {
            for side in ["Port", "Starboard"] {
                paths.push(root + "/" + name + "/MountBracket" + side);
                paths.push(root + "/" + name + "/MountLink" + side);
                paths.push(root + "/" + name + "/Frame");
            }
        }
        let batch = query("QueryUsdPrims", #{paths: paths, geometry_bounds: true});
        let bounds = #{};
        if batch.records != () {
            for record in batch.records { bounds[record.path] = record.geometry_bounds; }
        }
        let bus_to_bracket = 1.0e30;
        let bracket_to_link = 1.0e30;
        let link_to_frame = 1.0e30;
        let available = batch.records != () && batch.records.len() == paths.len();
        if available {
            for array_index in 0..names.len() {
                let name = names[array_index];
                for mount_index in 0..2 {
                    let side = if mount_index == 0 { "Port" } else { "Starboard" };
                    let rail_index = array_index * 2 + mount_index;
                    let bus_rail = bus_rails[rail_index];
                    let bracket = root + "/" + name + "/MountBracket" + side;
                    let link = root + "/" + name + "/MountLink" + side;
                    let frame = root + "/" + name + "/Frame";
                    let overlap_bus = bounds_overlap_depth(bounds[bus_rail], bounds[bracket]);
                    let overlap_arm = bounds_overlap_depth(bounds[bracket], bounds[link]);
                    let overlap_panel = bounds_overlap_depth(bounds[link], bounds[frame]);
                    if overlap_bus == () || overlap_arm == () || overlap_panel == () {
                        available = false;
                    } else {
                        bus_to_bracket = minimum(bus_to_bracket, overlap_bus);
                        bracket_to_link = minimum(bracket_to_link, overlap_arm);
                        link_to_frame = minimum(link_to_frame, overlap_panel);
                    }
                }
            }
        }
        checks.push(sysml_requirements::constraint_check("GSA-009-mount-path-overlap", "solar_array",
            "gsa009", VERIFICATION, "GriffinSolarRequirements::GSAC009_MountPathOverlap",
            #{busToBracketOverlapM: if available { #{provider: "usd", state: "value", value: bus_to_bracket} } else { #{provider: "usd", state: "unavailable", detail: "composed corner-post/bracket bounds unavailable"} },
              bracketToLinkOverlapM: if available { #{provider: "usd", state: "value", value: bracket_to_link} } else { #{provider: "usd", state: "unavailable", detail: "composed bracket/link bounds unavailable"} },
              linkToFrameOverlapM: if available { #{provider: "usd", state: "value", value: link_to_frame} } else { #{provider: "usd", state: "unavailable", detail: "composed link/frame bounds unavailable"} },
              requiredOverlapM: #{provider: "sysml", state: "value", value: mount_overlap}}, "usd", 0.0));
    }
    checks.push(sysml_requirement_checks::coverage("GSA-003-symmetry", "solar_array", "gsa003", VERIFICATION));
    checks.push(sysml_requirement_checks::coverage("GSA-004-traceability", "solar_array", "gsa004", VERIFICATION));
    sysml_requirement_checks::finish(source, checks, "GRIFFIN SOLAR REQUIREMENTS", "GRIFFIN_SOLAR_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
