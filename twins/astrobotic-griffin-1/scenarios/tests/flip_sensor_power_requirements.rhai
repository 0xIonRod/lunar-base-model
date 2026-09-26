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
    let solar_visual = solar + "/SolarArrayVisual";
    let mast_members = sysml_requirement_checks::source_enum_identifiers(source, own("mastChildNames"));
    let solar_members = sysml_requirement_checks::source_enum_identifiers(source, own("solarChildNames"));
    let source_owner = sysml_requirements::attribute(source, own("mastPath")).record.owner_handle;
    let mast_height = sysml_requirements::number_from_reference(source,
        source_owner, "mastHeight");
    let solar_mount = sysml_requirements::vector_from_reference(source,
        source_owner, "solarMount");
    let solar_tilt = sysml_requirements::number_from_reference(source,
        source_owner, "solarTilt");
    let battery_energy = sysml_requirements::number(source, own("batteryEnergyKWh"));
    let battery_voltage = sysml_requirements::number(source,
        "FlipRequirements::FlipRover::batteryNominalVoltageV");
    let solar_peak_power = sysml_requirements::number(source, own("solarArrayPeakPowerW"));
    let solar_cell_width = sysml_requirements::number(source, own("solarCellWidthM"));
    let solar_cell_depth = sysml_requirements::number(source, own("solarCellDepthM"));
    let checks = [];
    checks.push(sysml_requirement_checks::exists("FSP-001-mast", "sensor_mast", "fsp001", VERIFICATION, mast, "Xform"));
    let mast_paths = [];
    for member in mast_members { mast_paths.push(mast + "/" + member); }
    checks.push(sysml_requirement_checks::children("FSP-001-mast-parts", "sensor_mast", "fsp001", VERIFICATION, mast, mast_paths));
    checks.push(sysml_requirement_checks::exists("FSP-002-solar", "solar_array", "fsp002", VERIFICATION, solar, "Xform"));
    checks.push(sysml_requirement_checks::exists("FSP-002-solar-visual", "solar_array", "fsp002", VERIFICATION, solar_visual, "Xform"));
    let solar_paths = [];
    for member in solar_members { solar_paths.push(solar_visual + "/" + member); }
    checks.push(sysml_requirement_checks::children("FSP-002-solar-parts", "solar_array", "fsp002", VERIFICATION, solar_visual, solar_paths));
    checks.push(#{id: "FSP-003-mast-height", component: "sensor_mast",
        requirement: "fsp003", verification: VERIFICATION,
        kind: "attribute", path: mast + "/MastPost", attr: "height",
        expected: mast_height.value, tolerance: 0.002});
    if solar_mount.ok == true && solar_tilt.ok == true && solar_mount.value.len() == 3 {
        checks.push(#{id: "FSP-004-solar-x", component: "solar_array",
            requirement: "fsp004", verification: VERIFICATION,
            kind: "attribute_component", path: solar, attr: "xformOp:translate", index: 0,
            expected: solar_mount.value[0], tolerance: 0.002});
        checks.push(#{id: "FSP-004-solar-y", component: "solar_array",
            requirement: "fsp004", verification: VERIFICATION,
            kind: "attribute_component", path: solar, attr: "xformOp:translate", index: 1,
            expected: solar_mount.value[1], tolerance: 0.002});
        checks.push(#{id: "FSP-004-solar-z", component: "solar_array",
            requirement: "fsp004", verification: VERIFICATION,
            kind: "attribute_component", path: solar, attr: "xformOp:translate", index: 2,
            expected: solar_mount.value[2], tolerance: 0.002});
        checks.push(#{id: "FSP-004-solar-tilt", component: "solar_array",
            requirement: "fsp004", verification: VERIFICATION,
            kind: "attribute_component", path: solar, attr: "xformOp:rotateXYZ", index: 0,
            expected: solar_tilt.value, tolerance: 0.002});
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
        #{id: "FSP-006-backsheet-width", path: solar_visual + "/WhiteBacksheet", index: 0, attr: "solarBacksheetWidthM"},
        #{id: "FSP-006-backsheet-thickness", path: solar_visual + "/WhiteBacksheet", index: 1, attr: "solarBacksheetThicknessM"},
        #{id: "FSP-006-backsheet-depth", path: solar_visual + "/WhiteBacksheet", index: 2, attr: "solarBacksheetDepthM"},
        #{id: "FSP-006-cells-width", path: solar_visual + "/BlueCells", index: 0, attr: "solarCellWidthM"},
        #{id: "FSP-006-cells-thickness", path: solar_visual + "/BlueCells", index: 1, attr: "solarCellThicknessM"},
        #{id: "FSP-006-cells-depth", path: solar_visual + "/BlueCells", index: 2, attr: "solarCellDepthM"},
        #{id: "FSP-006-hinge-width", path: solar_visual + "/FoldHinge", index: 0, attr: "solarHingeWidthM"},
        #{id: "FSP-006-hinge-thickness", path: solar_visual + "/FoldHinge", index: 1, attr: "solarHingeThicknessM"},
        #{id: "FSP-006-hinge-depth", path: solar_visual + "/FoldHinge", index: 2, attr: "solarHingeDepthM"}
    ] {
        checks.push(sysml_requirement_checks::extent_component(field.id, "solar_array", "fsp006", VERIFICATION,
            field.path, field.index, own(field.attr), 2.0, 0.002));
    }
    checks.push(#{id: "FSP-006-hinge-position", component: "solar_array", requirement: "fsp006",
        verification: VERIFICATION, kind: "attribute_component", path: solar_visual + "/FoldHinge",
        attr: "xformOp:translate", index: 2, expected_attr: own("solarHingeCenterZM"), tolerance: 0.002});
    checks.push(#{id: "FSP-004-traceability", component: "sensor_power",
        requirement: "fsp004", verification: VERIFICATION, kind: "source_reference_available",
        source_owner: source_owner, reference_feature: "solarStatus"});
    checks.push(sysml_requirement_checks::coverage("FSP-004-traceability", "sensor_power", "fsp004", VERIFICATION));
    let battery = "" + sysml_requirements::text(source, own("batteryPath"));
    if battery_energy.ok == true && battery_voltage.ok == true && battery_voltage.value > 0.0 {
        checks.push(#{id: "FSP-007-energy-capacity", component: "battery",
            requirement: "fsp007", verification: VERIFICATION, kind: "attribute",
            path: battery + "/Battery", attr: "inputs:capacity",
            expected: battery_energy.value * 1000.0 / battery_voltage.value,
            tolerance: 0.02});
        checks.push(#{id: "FSP-007-nominal-voltage", component: "battery",
            requirement: "fsp007", verification: VERIFICATION, kind: "attribute",
            path: battery + "/Battery", attr: "inputs:voltage_nom",
            expected: battery_voltage.value, tolerance: 0.002});
    }
    if solar_peak_power.ok == true && solar_cell_width.ok == true && solar_cell_depth.ok == true {
        checks.push(#{id: "FSP-008-array-area", component: "solar_array",
            requirement: "fsp008", verification: VERIFICATION, kind: "attribute",
            path: solar, attr: "parameters:area",
            expected: solar_cell_width.value * solar_cell_depth.value, tolerance: 0.002});
        checks.push(#{id: "FSP-008-array-efficiency", component: "solar_array",
            requirement: "fsp008", verification: VERIFICATION, kind: "attribute",
            path: solar, attr: "parameters:efficiency",
            expected_attr: own("solarArrayEfficiency"), tolerance: 0.002});
        checks.push(#{id: "FSP-008-peak-power", component: "solar_array",
            requirement: "fsp008", verification: VERIFICATION, kind: "attribute",
            path: solar, attr: "parameters:peak_power_rating_w",
            expected: solar_peak_power.value, tolerance: 0.01});
    }
    sysml_requirement_checks::finish(source, checks, "FLIP SENSOR/POWER REQUIREMENTS", "FLIP_SENSOR_POWER_REQUIREMENTS", mast, PACKAGE, VERIFICATION);
    this.done = true;
}
