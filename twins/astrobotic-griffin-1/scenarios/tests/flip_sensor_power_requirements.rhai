// Standalone FLIP sensor mast and solar-power visual verification.

const PACKAGE = "FlipSensorPowerRequirements";
const VERIFICATION = "FlipSensorPowerRequirements::Verify_FLIPSensorPowerRequirements";

fn own(name) { PACKAGE + "::FlipSensorPowerAssembly::" + name }

fn on_start(me) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source();
    let mast = sysml_requirements::text(source, own("mastPath"));
    let solar = sysml_requirements::text(source, own("solarPath"));
    let checks = [];
    checks.push(component_requirements::exists("FSP-001-mast", "sensor_mast", "FlipSensorPowerRequirements::fsp001", VERIFICATION, mast, "Xform"));
    checks.push(component_requirements::children("FSP-001-mast-parts", "sensor_mast", "FlipSensorPowerRequirements::fsp001", VERIFICATION, mast,
        [mast + "/MastPost", mast + "/SensorHead", mast + "/SensorAntenna"]));
    checks.push(component_requirements::exists("FSP-002-solar", "solar_array", "FlipSensorPowerRequirements::fsp002", VERIFICATION, solar, "Xform"));
    checks.push(component_requirements::children("FSP-002-solar-parts", "solar_array", "FlipSensorPowerRequirements::fsp002", VERIFICATION, solar,
        [solar + "/WhiteBacksheet", solar + "/BlueCells", solar + "/FoldHinge"]));
    checks.push(#{id: "FSP-003-mast-height", component: "sensor_mast",
        requirement: "FlipSensorPowerRequirements::fsp003", verification: VERIFICATION,
        kind: "attribute", path: mast + "/MastPost", attr: "height",
        expected_attr: sysml_requirements::text(source, own("mastHeightSource")), tolerance: 0.002});
    checks.push(component_requirements::coverage("FSP-004-traceability", "sensor_power", "FlipSensorPowerRequirements::fsp004", VERIFICATION));
    component_requirements::finish(source, checks, "FLIP SENSOR/POWER REQUIREMENTS", "FLIP_SENSOR_POWER_REQUIREMENTS", mast, PACKAGE, VERIFICATION);
    this.done = true;
}
