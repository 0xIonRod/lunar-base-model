import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
// Standalone Griffin dual solar-array visual verification.

const PACKAGE = "GriffinSolarRequirements";
const VERIFICATION = "Verify_GriffinSolarRequirements";

fn own(name) { PACKAGE + "::GriffinSolarArrayAssembly::" + name }
fn visual(name) { "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::" + name }

fn position(id, path, index, expected) {
    #{id: id, component: "solar_array", requirement: "gsa005",
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: "xformOp:translate", index: index, expected: expected, tolerance: 0.002}
}

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source();
    let root = sysml_requirements::text(source, own("usdRootPath"));
    let names = sysml_requirement_checks::source_enum_identifiers(source, visual("solarArrayInstances"));
    let stations = sysml_requirement_checks::source_position_list(source, visual("solarStations"));
    let count = "GriffinLanderRequirements::GriffinLanderComponent::solarArrayCount";
    let rotx = sysml_requirement_checks::source_number_list(source, visual("solarStationRotationXDeg"));
    let rotz = sysml_requirement_checks::source_number_list(source, visual("solarStationRotationZDeg"));
    let checks = [];
    checks.push(sysml_requirement_checks::source_list_count("GSA-001-count", "lander_solar", "gsa001", VERIFICATION, visual("solarArrayInstances"), count));
    checks.push(sysml_requirement_checks::source_list_count("GSA-005-stations", "solar_array", "gsa005", VERIFICATION, visual("solarStations"), count));
    checks.push(sysml_requirement_checks::source_list_count("GSA-005-rotation-x", "solar_array", "gsa005", VERIFICATION, visual("solarStationRotationXDeg"), count));
    checks.push(sysml_requirement_checks::source_list_count("GSA-005-rotation-z", "solar_array", "gsa005", VERIFICATION, visual("solarStationRotationZDeg"), count));
    for index in 0..names.len() {
        let name = names[index];
        let path = root + "/" + name;
        checks.push(sysml_requirement_checks::exists("GSA-001-" + name, "solar_array", "gsa001", VERIFICATION, path, "Xform"));
        checks.push(sysml_requirement_checks::children("GSA-002-" + name, "solar_array", "gsa002", VERIFICATION, path,
            [path + "/Frame", path + "/Cells", path + "/CellDividerX", path + "/CellDividerZ", path + "/MountBracket", path + "/HingeBar", path + "/MountLink"]));
        if stations.len() == names.len() {
            checks.push(position("GSA-005-" + name + "-x", path, 0, stations[index].x));
            checks.push(position("GSA-005-" + name + "-y", path, 1, stations[index].y));
            checks.push(position("GSA-005-" + name + "-z", path, 2, stations[index].z));
        }
        if rotx.len() == names.len() && rotz.len() == names.len() {
            checks.push(#{id: "GSA-005-" + name + "-rotx", component: "solar_array",
                requirement: "gsa005", verification: VERIFICATION, kind: "attribute_component",
                path: path, attr: "xformOp:rotateXYZ", index: 0, expected: rotx[index], tolerance: 0.002});
            checks.push(#{id: "GSA-005-" + name + "-rotz", component: "solar_array",
                requirement: "gsa005", verification: VERIFICATION, kind: "attribute_component",
                path: path, attr: "xformOp:rotateXYZ", index: 2, expected: rotz[index], tolerance: 0.002});
        }
        checks.push(sysml_requirement_checks::extent_component("GSA-006-" + name + "-frame-width", "solar_array", "gsa006", VERIFICATION,
            path + "/Frame", 0, own("frameWidthM"), 2.0, 0.002));
        checks.push(sysml_requirement_checks::extent_component("GSA-006-" + name + "-frame-thickness", "solar_array", "gsa006", VERIFICATION,
            path + "/Frame", 1, own("frameThicknessM"), 2.0, 0.002));
        checks.push(sysml_requirement_checks::extent_component("GSA-006-" + name + "-frame-depth", "solar_array", "gsa006", VERIFICATION,
            path + "/Frame", 2, own("frameDepthM"), 2.0, 0.002));
        checks.push(sysml_requirement_checks::extent_component("GSA-006-" + name + "-cell-width", "solar_array", "gsa006", VERIFICATION,
            path + "/Cells", 0, own("cellWidthM"), 2.0, 0.002));
        checks.push(sysml_requirement_checks::extent_component("GSA-006-" + name + "-cell-thickness", "solar_array", "gsa006", VERIFICATION,
            path + "/Cells", 1, own("cellThicknessM"), 2.0, 0.002));
        checks.push(sysml_requirement_checks::extent_component("GSA-006-" + name + "-cell-depth", "solar_array", "gsa006", VERIFICATION,
            path + "/Cells", 2, own("cellDepthM"), 2.0, 0.002));
        checks.push(#{id: "GSA-006-" + name + "-cell-offset", component: "solar_array",
            requirement: "gsa006", verification: VERIFICATION, kind: "attribute_component",
            path: path + "/Cells", attr: "xformOp:translate", index: 1,
            expected_attr: own("cellOffsetYM"), tolerance: 0.002});
        checks.push(sysml_requirement_checks::extent_component("GSA-007-" + name + "-mount-width", "solar_array", "gsa007", VERIFICATION,
            path + "/MountBracket", 0, own("mountBracketWidthM"), 2.0, 0.002));
        checks.push(sysml_requirement_checks::extent_component("GSA-007-" + name + "-mount-thickness", "solar_array", "gsa007", VERIFICATION,
            path + "/MountBracket", 1, own("mountBracketThicknessM"), 2.0, 0.002));
        checks.push(sysml_requirement_checks::extent_component("GSA-007-" + name + "-mount-depth", "solar_array", "gsa007", VERIFICATION,
            path + "/MountBracket", 2, own("mountBracketDepthM"), 2.0, 0.002));
        checks.push(#{id: "GSA-008-" + name + "-hinge-axis", component: "solar_array",
            requirement: "gsa008", verification: VERIFICATION, kind: "attribute",
            path: path + "/HingeBar", attr: "axis", expected: "Z"});
        checks.push(#{id: "GSA-008-" + name + "-hinge-radius", component: "solar_array",
            requirement: "gsa008", verification: VERIFICATION, kind: "attribute",
            path: path + "/HingeBar", attr: "radius", expected_attr: own("hingeBarRadiusM"), tolerance: 0.002});
        checks.push(#{id: "GSA-008-" + name + "-hinge-length", component: "solar_array",
            requirement: "gsa008", verification: VERIFICATION, kind: "attribute",
            path: path + "/HingeBar", attr: "height", expected_attr: own("hingeBarLengthM"), tolerance: 0.002});
        checks.push(#{id: "GSA-008-" + name + "-hinge-y", component: "solar_array",
            requirement: "gsa008", verification: VERIFICATION, kind: "attribute_component",
            path: path + "/HingeBar", attr: "xformOp:translate", index: 1,
            expected_attr: own("hingeBarCenterYM"), tolerance: 0.002});
        checks.push(#{id: "GSA-008-" + name + "-hinge-z", component: "solar_array",
            requirement: "gsa008", verification: VERIFICATION, kind: "attribute_component",
            path: path + "/HingeBar", attr: "xformOp:translate", index: 2,
            expected_attr: own("hingeBarCenterZM"), tolerance: 0.002});
        checks.push(sysml_requirement_checks::extent_component("GSA-008-" + name + "-link-width", "solar_array", "gsa008", VERIFICATION,
            path + "/MountLink", 0, own("mountLinkWidthM"), 2.0, 0.002));
        checks.push(sysml_requirement_checks::extent_component("GSA-008-" + name + "-link-height", "solar_array", "gsa008", VERIFICATION,
            path + "/MountLink", 1, own("mountLinkHeightM"), 2.0, 0.002));
        checks.push(sysml_requirement_checks::extent_component("GSA-008-" + name + "-link-depth", "solar_array", "gsa008", VERIFICATION,
            path + "/MountLink", 2, own("mountLinkDepthM"), 2.0, 0.002));
    }
    checks.push(sysml_requirement_checks::coverage("GSA-003-symmetry", "solar_array", "gsa003", VERIFICATION));
    checks.push(sysml_requirement_checks::coverage("GSA-004-traceability", "solar_array", "gsa004", VERIFICATION));
    sysml_requirement_checks::finish(source, checks, "GRIFFIN SOLAR REQUIREMENTS", "GRIFFIN_SOLAR_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
