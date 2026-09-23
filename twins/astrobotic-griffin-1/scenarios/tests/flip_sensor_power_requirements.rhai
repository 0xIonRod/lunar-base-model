import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
// Standalone FLIP sensor mast and solar-power visual verification.

const PACKAGE = "FlipSensorPowerRequirements";
const VERIFICATION = "Verify_FLIPSensorPowerRequirements";

fn own(name) { PACKAGE + "::FlipSensorPowerAssembly::" + name }

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source();
    let mast = sysml_requirements::text(source, own("mastPath"));
    let solar = sysml_requirements::text(source, own("solarPath"));
    let solar_mount_source = sysml_requirements::text(source, own("solarMountSource"));
    let solar_tilt_source = sysml_requirements::text(source, own("solarTiltSource"));
    let checks = [];
    checks.push(sysml_requirement_checks::exists("FSP-001-mast", "sensor_mast", "fsp001", VERIFICATION, mast, "Xform"));
    checks.push(sysml_requirement_checks::children("FSP-001-mast-parts", "sensor_mast", "fsp001", VERIFICATION, mast,
        [mast + "/MastPost", mast + "/SensorHead", mast + "/SensorAntenna"]));
    checks.push(sysml_requirement_checks::exists("FSP-002-solar", "solar_array", "fsp002", VERIFICATION, solar, "Xform"));
    checks.push(sysml_requirement_checks::children("FSP-002-solar-parts", "solar_array", "fsp002", VERIFICATION, solar,
        [solar + "/WhiteBacksheet", solar + "/BlueCells", solar + "/FoldHinge"]));
    checks.push(#{id: "FSP-003-mast-height", component: "sensor_mast",
        requirement: "fsp003", verification: VERIFICATION,
        kind: "attribute", path: mast + "/MastPost", attr: "height",
        expected_attr: sysml_requirements::text(source, own("mastHeightSource")), tolerance: 0.002});
    let solar_mount = sysml_requirement_checks::source_number_list(source, solar_mount_source);
    if solar_mount.len() == 3 {
        checks.push(#{id: "FSP-004-solar-x", component: "solar_array",
            requirement: "fsp004", verification: VERIFICATION,
            kind: "attribute_component", path: solar, attr: "xformOp:translate", index: 0,
            expected: solar_mount[0], tolerance: 0.002});
        checks.push(#{id: "FSP-004-solar-y", component: "solar_array",
            requirement: "fsp004", verification: VERIFICATION,
            kind: "attribute_component", path: solar, attr: "xformOp:translate", index: 1,
            expected: solar_mount[1], tolerance: 0.002});
        checks.push(#{id: "FSP-004-solar-z", component: "solar_array",
            requirement: "fsp004", verification: VERIFICATION,
            kind: "attribute_component", path: solar, attr: "xformOp:translate", index: 2,
            expected: solar_mount[2], tolerance: 0.002});
        checks.push(#{id: "FSP-004-solar-tilt", component: "solar_array",
            requirement: "fsp004", verification: VERIFICATION,
            kind: "attribute_component", path: solar, attr: "xformOp:rotateXYZ", index: 0,
            expected: sysml_requirements::number(source, solar_tilt_source), tolerance: 0.002});
    }
    checks.push(#{id: "FSP-005-post-radius", component: "sensor_mast", requirement: "fsp005",
        verification: VERIFICATION, kind: "attribute", path: mast + "/MastPost", attr: "radius",
        expected_attr: own("mastPostRadiusM"), tolerance: 0.002});
    checks.push(#{id: "FSP-005-post-y", component: "sensor_mast", requirement: "fsp005",
        verification: VERIFICATION, kind: "attribute_component", path: mast + "/MastPost",
        attr: "xformOp:translate", index: 1, expected_attr: own("mastPostCenterYM"), tolerance: 0.002});
    checks.push(#{id: "FSP-005-post-z", component: "sensor_mast", requirement: "fsp005",
        verification: VERIFICATION, kind: "attribute_component", path: mast + "/MastPost",
        attr: "xformOp:translate", index: 2, expected_attr: own("mastPostCenterZM"), tolerance: 0.002});
    for field in [
        #{id: "FSP-005-head-width", path: mast + "/SensorHead", index: 0, attr: "sensorHeadWidthM"},
        #{id: "FSP-005-head-height", path: mast + "/SensorHead", index: 1, attr: "sensorHeadHeightM"},
        #{id: "FSP-005-head-depth", path: mast + "/SensorHead", index: 2, attr: "sensorHeadDepthM"}
    ] {
        checks.push(sysml_requirement_checks::extent_component(field.id, "sensor_mast", "fsp005", VERIFICATION,
            field.path, field.index, own(field.attr), 2.0, 0.002));
    }
    checks.push(#{id: "FSP-005-antenna-radius", component: "sensor_mast", requirement: "fsp005",
        verification: VERIFICATION, kind: "attribute", path: mast + "/SensorAntenna", attr: "radius",
        expected_attr: own("antennaRadiusM"), tolerance: 0.002});
    checks.push(#{id: "FSP-005-antenna-height", component: "sensor_mast", requirement: "fsp005",
        verification: VERIFICATION, kind: "attribute", path: mast + "/SensorAntenna", attr: "height",
        expected_attr: own("antennaHeightM"), tolerance: 0.002});
    for field in [
        #{id: "FSP-006-backsheet-width", path: solar + "/WhiteBacksheet", index: 0, attr: "solarBacksheetWidthM"},
        #{id: "FSP-006-backsheet-thickness", path: solar + "/WhiteBacksheet", index: 1, attr: "solarBacksheetThicknessM"},
        #{id: "FSP-006-backsheet-depth", path: solar + "/WhiteBacksheet", index: 2, attr: "solarBacksheetDepthM"},
        #{id: "FSP-006-cells-width", path: solar + "/BlueCells", index: 0, attr: "solarCellWidthM"},
        #{id: "FSP-006-cells-thickness", path: solar + "/BlueCells", index: 1, attr: "solarCellThicknessM"},
        #{id: "FSP-006-cells-depth", path: solar + "/BlueCells", index: 2, attr: "solarCellDepthM"},
        #{id: "FSP-006-hinge-width", path: solar + "/FoldHinge", index: 0, attr: "solarHingeWidthM"},
        #{id: "FSP-006-hinge-thickness", path: solar + "/FoldHinge", index: 1, attr: "solarHingeThicknessM"},
        #{id: "FSP-006-hinge-depth", path: solar + "/FoldHinge", index: 2, attr: "solarHingeDepthM"}
    ] {
        checks.push(sysml_requirement_checks::extent_component(field.id, "solar_array", "fsp006", VERIFICATION,
            field.path, field.index, own(field.attr), 2.0, 0.002));
    }
    checks.push(sysml_requirement_checks::coverage("FSP-004-traceability", "sensor_power", "fsp004", VERIFICATION));
    sysml_requirement_checks::finish(source, checks, "FLIP SENSOR/POWER REQUIREMENTS", "FLIP_SENSOR_POWER_REQUIREMENTS", mast, PACKAGE, VERIFICATION);
    this.done = true;
}
