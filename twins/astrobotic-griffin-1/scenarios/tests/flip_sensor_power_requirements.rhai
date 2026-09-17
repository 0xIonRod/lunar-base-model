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
    checks.push(component_requirements::exists("FSP-001-mast", "sensor_mast", "fsp001", VERIFICATION, mast, "Xform"));
    checks.push(component_requirements::children("FSP-001-mast-parts", "sensor_mast", "fsp001", VERIFICATION, mast,
        [mast + "/MastPost", mast + "/SensorHead", mast + "/SensorAntenna"]));
    checks.push(component_requirements::exists("FSP-002-solar", "solar_array", "fsp002", VERIFICATION, solar, "Xform"));
    checks.push(component_requirements::children("FSP-002-solar-parts", "solar_array", "fsp002", VERIFICATION, solar,
        [solar + "/WhiteBacksheet", solar + "/BlueCells", solar + "/FoldHinge"]));
    checks.push(#{id: "FSP-003-mast-height", component: "sensor_mast",
        requirement: "fsp003", verification: VERIFICATION,
        kind: "attribute", path: mast + "/MastPost", attr: "height",
        expected_attr: sysml_requirements::text(source, own("mastHeightSource")), tolerance: 0.002});
    let solar_mount = component_requirements::source_number_list(source, solar_mount_source);
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
    checks.push(component_requirements::coverage("FSP-004-traceability", "sensor_power", "fsp004", VERIFICATION));
    component_requirements::finish(source, checks, "FLIP SENSOR/POWER REQUIREMENTS", "FLIP_SENSOR_POWER_REQUIREMENTS", mast, PACKAGE, VERIFICATION);
    this.done = true;
}
