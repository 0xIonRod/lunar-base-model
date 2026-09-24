import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
// Standalone Griffin landing-leg verification. Typed identities and stations
// come from GriffinVisualConfigurationRequirements; the lander owns the count.

const PACKAGE = "GriffinLandingLegRequirements";
const VERIFICATION = "Verify_GriffinLandingLegRequirements";

fn own(name) { PACKAGE + "::GriffinLandingLegAssembly::" + name }
fn parent(name) { "GriffinLanderRequirements::GriffinLanderComponent::" + name }
fn visual(name) { "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::" + name }

fn position(id, path, index, expected) {
    #{id: id, component: "landing_leg", requirement: "gll005",
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: "xformOp:translate", index: index, expected: expected, tolerance: 0.002}
}

fn usd_axis(direction) {
    if type_of(direction) != "Vec3" { return (); }
    if direction.x == 1.0 && direction.y == 0.0 && direction.z == 0.0 { return "X"; }
    if direction.x == 0.0 && direction.y == 1.0 && direction.z == 0.0 { return "Y"; }
    if direction.x == 0.0 && direction.y == 0.0 && direction.z == 1.0 { return "Z"; }
    ()
}

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source();
    let root = sysml_requirements::text(source, own("usdRootPath"));
    let names = sysml_requirement_checks::source_enum_identifiers(source, visual("landingLegInstances"));
    let part_names = sysml_requirement_checks::source_enum_identifiers(source, own("childNames"));
    let stations = sysml_requirement_checks::source_position_list(source, visual("legStations"));
    let strut_axis = usd_axis(sysml_requirements::native_value(source, own("strutAxis")));
    let count = parent("legCount");
    let checks = [];
    checks.push(sysml_requirement_checks::source_list_count("GLL-001-count", "landing_legs", "gll001", VERIFICATION, visual("landingLegInstances"), count));
    checks.push(sysml_requirement_checks::source_list_count("GLL-005-stations", "landing_leg", "gll005", VERIFICATION, visual("legStations"), count));
    for index in 0..names.len() {
        let name = names[index];
        let path = root + "/" + name;
        let visual_path = path + "/LandingLegVisual";
        checks.push(sysml_requirement_checks::exists("GLL-001-" + name, "landing_leg", "gll001", VERIFICATION, path, "Xform"));
        let required_children = [];
        for part_name in part_names { required_children.push(visual_path + "/" + part_name); }
        checks.push(sysml_requirement_checks::children("GLL-002-" + name, "landing_leg", "gll002", VERIFICATION, visual_path, required_children));
        for strut in ["StrutOuter", "StrutInner"] {
            let strut_path = visual_path + "/" + strut;
            checks.push(sysml_requirement_checks::exists("GLL-006-" + name + "-" + strut + "-type", "landing_leg", "gll006", VERIFICATION, strut_path, "Cylinder"));
            checks.push(sysml_requirement_checks::attribute_check("GLL-006-" + name + "-" + strut + "-radius", "landing_leg", "gll006", VERIFICATION,
                strut_path, "radius", own("strutRadiusM"), 0.002));
            checks.push(sysml_requirement_checks::attribute_check("GLL-006-" + name + "-" + strut + "-height", "landing_leg", "gll006", VERIFICATION,
                strut_path, "height", own("strutHeightM"), 0.002));
            checks.push(sysml_requirement_checks::attribute_equals("GLL-006-" + name + "-" + strut + "-axis", "landing_leg", "gll006", VERIFICATION,
                strut_path, "axis", strut_axis));
        }
        checks.push(#{id: "GLL-006-" + name + "-outer-center", component: "landing_leg",
            requirement: "gll006", verification: VERIFICATION, kind: "attribute_component",
            path: visual_path + "/StrutOuter", attr: "xformOp:translate", index: 0,
            expected_attr: own("strutOuterCenterXM"), tolerance: 0.002});
        checks.push(#{id: "GLL-006-" + name + "-outer-tilt", component: "landing_leg",
            requirement: "gll006", verification: VERIFICATION, kind: "attribute_component",
            path: visual_path + "/StrutOuter", attr: "xformOp:rotateXYZ", index: 2,
            expected_attr: own("strutOuterTiltZDeg"), tolerance: 0.002});
        checks.push(#{id: "GLL-006-" + name + "-inner-center", component: "landing_leg",
            requirement: "gll006", verification: VERIFICATION, kind: "attribute_component",
            path: visual_path + "/StrutInner", attr: "xformOp:translate", index: 0,
            expected_attr: own("strutInnerCenterXM"), tolerance: 0.002});
        checks.push(#{id: "GLL-006-" + name + "-inner-tilt", component: "landing_leg",
            requirement: "gll006", verification: VERIFICATION, kind: "attribute_component",
            path: visual_path + "/StrutInner", attr: "xformOp:rotateXYZ", index: 2,
            expected_attr: own("strutInnerTiltZDeg"), tolerance: 0.002});
        checks.push(#{id: "GLL-007-" + name + "-radius", component: "landing_leg",
            requirement: "gll007", verification: VERIFICATION, kind: "attribute",
            path: visual_path + "/ShockPiston", attr: "radius", expected_attr: own("shockPistonRadiusM"), tolerance: 0.002});
        checks.push(#{id: "GLL-007-" + name + "-height", component: "landing_leg",
            requirement: "gll007", verification: VERIFICATION, kind: "attribute",
            path: visual_path + "/ShockPiston", attr: "height", expected_attr: own("shockPistonHeightM"), tolerance: 0.002});
        checks.push(#{id: "GLL-008-" + name + "-radius", component: "landing_leg",
            requirement: "gll008", verification: VERIFICATION, kind: "attribute",
            path: visual_path + "/FootPad", attr: "radius", expected_attr: own("footPadRadiusM"), tolerance: 0.002});
        checks.push(#{id: "GLL-008-" + name + "-height", component: "landing_leg",
            requirement: "gll008", verification: VERIFICATION, kind: "attribute",
            path: visual_path + "/FootPad", attr: "height", expected_attr: own("footPadHeightM"), tolerance: 0.002});
        if stations.len() == names.len() {
            checks.push(position("GLL-005-" + name + "-x", path, 0, stations[index].x));
            checks.push(position("GLL-005-" + name + "-y", path, 1, stations[index].y));
            checks.push(position("GLL-005-" + name + "-z", path, 2, stations[index].z));
        }
    }
    checks.push(sysml_requirement_checks::coverage("GLL-003-frame", "landing_leg", "gll003", VERIFICATION));
    checks.push(sysml_requirement_checks::coverage("GLL-004-traceability", "landing_leg", "gll004", VERIFICATION));
    sysml_requirement_checks::finish(source, checks, "GRIFFIN LANDING LEG REQUIREMENTS", "GRIFFIN_LANDING_LEG_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
