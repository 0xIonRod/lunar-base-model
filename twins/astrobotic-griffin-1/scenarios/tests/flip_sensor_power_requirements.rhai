import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
import "twin://astrobotic-griffin-1/tools/usd_geometry_inspection.rhai" as usd_geometry_inspection;
// Standalone FLIP sensor mast and solar-power visual verification.

const PACKAGE = "FlipSensorPowerRequirements";
const VERIFICATION = "Verify_FLIPSensorPowerRequirements";

fn simulation_dependencies(me, ctx) {
    let deps = usd_geometry_inspection::dependencies();
    let rover = find_path("/World/FLIP");
    deps.modelica_entities = [rover];
    deps.entity_reads = [rover];
    deps.entity_writes = [rover];
    deps.query_reads.push("ReadPortsBatch");
    deps
}

fn own(name) { PACKAGE + "::FlipSensorPowerAssembly::" + name }

fn required_number(source, name) {
    let value = f64_from(sysml_requirements::number(source, name));
    if value == () || !value.is_finite() {
        throw("FLIP sensor/power source value is unavailable or non-finite: " + name);
    }
    value
}

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
    this.phase = "geometry";
    this.case_index = 0;
    this.rover = find_path("/World/FLIP");
}

fn geometry_checks(source) {
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
            field.path, field.index, own(field.attr), 1.0, 0.002));
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
            field.path, field.index, own(field.attr), 1.0, 0.002));
    }
    checks.push(#{id: "FSP-006-hinge-position", component: "solar_array", requirement: "fsp006",
        verification: VERIFICATION, kind: "attribute_component", path: solar_visual + "/FoldHinge",
        attr: "xformOp:translate", index: 2, expected_attr: own("solarHingeCenterZM"), tolerance: 0.002});
    checks.push(#{id: "FSP-004-traceability", component: "sensor_power",
        requirement: "fsp004", verification: VERIFICATION, kind: "source_reference_available",
        source_owner: source_owner, reference_feature: "solarStatus"});
    checks.push(sysml_requirement_checks::coverage("FSP-004-traceability", "sensor_power", "fsp004", VERIFICATION));
    let battery = "" + sysml_requirements::text(source, own("batteryPath"));
    let battery_record = query("QueryUsdPrim", #{path: battery,
        attrs: ["inputs:capacity", "inputs:voltage_nom"]});
    let battery_attrs = if battery_record != () { battery_record.attrs } else { () };
    let capacity = if battery_attrs != () { battery_attrs["inputs:capacity"] } else { () };
    let nominal_voltage = if battery_attrs != () { battery_attrs["inputs:voltage_nom"] } else { () };
    let source_model = sysml_requirements::model();
    let battery_inputs = [
        ["capacityAh", usd_geometry_inspection::measurement(capacity, battery_record,
            "Battery ampere-hour capacity is unavailable")],
        ["nominalVoltageV", usd_geometry_inspection::measurement(nominal_voltage, battery_record,
            "Battery nominal voltage is unavailable")],
    ];
    for field in [
        ["requiredEnergyKWh", own("batteryEnergyKWh")],
        ["requiredVoltageV", "FlipRequirements::FlipRover::batteryNominalVoltageV"],
        ["capacityToleranceAh", PACKAGE+"::FSP007_BatteryEnergyCapacity::batteryCapacityToleranceAh"],
        ["voltageToleranceV", PACKAGE+"::FSP007_BatteryEnergyCapacity::batteryVoltageToleranceV"],
    ] {
        battery_inputs.push([field[0], source_model.source_literal_observation(
            source_model.attribute(field[1]))]);
    }
    let battery_constraint = PACKAGE+"::FSPC007_BatteryNameplateEnergy";
    let battery_observations = sysml_requirements::required_constraint_input_observations(
        source_model, source_model.requirement(PACKAGE+"::fsp007"),
        battery_constraint, battery_inputs);
    checks.push(sysml_requirements::required_constraints_check(
        "FSP-007-energy-capacity", "battery", "fsp007", VERIFICATION,
        battery_constraint, battery_observations, "typed", 0.0));
    checks.push(solar_configuration_check(source_model, solar));
    checks
}

fn _solar_limit(name) { PACKAGE + "::FSP008_SolarArrayPeakPower::" + name }
fn _solar_probe(name) { PACKAGE + "::FlipSolarVerificationInputs::" + name }

fn sensor_power_source() {
    let attributes = [];
    for name in ["mastPath", "solarPath", "batteryPath", "mastChildNames", "solarChildNames",
        "mastPostRadiusM", "mastPostHeightM", "mastPostCenterYM", "mastPostCenterZM",
        "sensorHeadWidthM", "sensorHeadHeightM", "sensorHeadDepthM",
        "antennaRadiusM", "antennaHeightM", "solarBacksheetWidthM",
        "solarBacksheetThicknessM", "solarBacksheetDepthM", "solarCellWidthM",
        "solarCellThicknessM", "solarCellDepthM", "solarHingeWidthM",
        "solarHingeThicknessM", "solarHingeDepthM", "solarHingeCenterZM",
        "solarArrayEfficiency", "solarArrayPeakPowerW", "batteryEnergyKWh",
        "solarReferenceTemperatureK", "solarPowerTemperatureCoefficientPerK", "solarAbsorptivity"] {
        attributes.push(own(name));
    }
    for name in ["areaToleranceM2", "efficiencyTolerance", "powerToleranceW", "temperatureFactorTolerance"] {
        attributes.push(_solar_limit(name));
    }
    for name in ["brightIrradianceWm2", "dimIrradianceWm2", "visibleSunFraction",
        "occludedSunFraction", "frontDirection", "backDirection", "frontCosine",
        "backCosine", "observationDwellS", "observationTimeoutS",
        "counterexampleAreaOffsetM2", "counterexampleEfficiencyOffset",
        "counterexamplePowerOffsetW", "temperatureProbeDeltaK"] { attributes.push(_solar_probe(name)); }
    let requirements = [];
    for name in ["fsp001", "fsp002", "fsp003", "fsp004", "fsp005", "fsp006", "fsp007", "fsp008"] {
        requirements.push(PACKAGE + "::" + name);
    }
    sysml_requirements::source_with_selection(attributes, requirements,
        [PACKAGE + "::" + VERIFICATION])
}

fn _solar_source_inputs(model) {
    let inputs = [];
    for field in [
        ["cellWidthM", own("solarCellWidthM")],
        ["cellDepthM", own("solarCellDepthM")],
        ["requiredEfficiency", own("solarArrayEfficiency")],
        ["requiredPeakPowerW", own("solarArrayPeakPowerW")],
        ["powerToleranceW", _solar_limit("powerToleranceW")],
    ] {
        inputs.push([field[0], model.source_literal_observation(model.attribute(field[1]))]);
    }
    inputs
}

fn _solar_check(model, id, constraint, inputs) {
    let name = PACKAGE + "::" + constraint;
    let observations = sysml_requirements::required_constraint_input_observations(
        model, model.requirement(PACKAGE + "::fsp008"), name, inputs);
    sysml_requirements::required_constraint_check(id, "solar_array", "fsp008",
        VERIFICATION, name, observations, "typed", 0.0)
}

fn _solar_temperature_inputs(model) {
    let inputs=[];
    for field in [["referenceTemperatureK",own("solarReferenceTemperatureK")],
        ["powerTemperatureCoefficientPerK",own("solarPowerTemperatureCoefficientPerK")],
        ["solarAbsorptivity",own("solarAbsorptivity")],
        ["temperatureFactorTolerance",_solar_limit("temperatureFactorTolerance")]] {
        inputs.push([field[0],model.source_literal_observation(model.attribute(field[1]))]);
    }
    inputs
}

fn solar_configuration_check(model, solar) {
    let record = query("QueryUsdPrim", #{path: solar,
        attrs: ["parameters:area", "parameters:efficiency", "parameters:peak_power_rating_w"]});
    let attrs = if record != () { record.attrs } else { () };
    let inputs = _solar_source_inputs(model);
    for field in [["areaM2", "parameters:area"], ["efficiency", "parameters:efficiency"],
                  ["peakPowerW", "parameters:peak_power_rating_w"]] {
        inputs.push([field[0], usd_geometry_inspection::measurement(
            if attrs == () { () } else { attrs[field[1]] }, record,
            "Solar configuration value is unavailable: " + field[1])]);
    }
    for field in [["areaToleranceM2", _solar_limit("areaToleranceM2")],
                  ["efficiencyTolerance", _solar_limit("efficiencyTolerance")]] {
        inputs.push([field[0], model.source_literal_observation(model.attribute(field[1]))]);
    }
    _solar_check(model, "FSP-008-configuration", "FSPC008_SolarConfiguration", inputs)
}

fn solar_cases(source) {
    let front = sysml_requirements::native_value(source, _solar_probe("frontDirection"));
    let back = sysml_requirements::native_value(source, _solar_probe("backDirection"));
    if !vec3_is_native(front) || !vec3_is_native(back) { throw("Solar probe direction is unavailable"); }
    let bright = required_number(source, _solar_probe("brightIrradianceWm2"));
    let dim = required_number(source, _solar_probe("dimIrradianceWm2"));
    let visible = required_number(source, _solar_probe("visibleSunFraction"));
    let occluded = required_number(source, _solar_probe("occludedSunFraction"));
    let front_cosine = _solar_probe("frontCosine");
    let back_cosine = _solar_probe("backCosine");
    let probes=[#{id: "bright", irradiance: bright, visibility: visible, direction: front, cosine: front_cosine},
     #{id: "dim", irradiance: dim, visibility: visible, direction: front, cosine: front_cosine},
     #{id: "occluded", irradiance: bright, visibility: occluded, direction: front, cosine: front_cosine},
     #{id: "back-facing", irradiance: bright, visibility: visible, direction: back, cosine: back_cosine}];
    let reference=required_number(source,own("solarReferenceTemperatureK"));
    for i in 0..probes.len() { probes[i].temperature=reference; }
    let delta=required_number(source,_solar_probe("temperatureProbeDeltaK"));
    let hot=probes[0];hot.id="hot";hot.temperature=reference+delta;
    let cold=probes[0];cold.id="cold";cold.temperature=reference-delta;
    probes.push(hot);probes.push(cold);probes
}

fn _solar_writes(probe) {
    [["irradiance", probe.irradiance], ["sun_visibility", probe.visibility],
     ["target_mount_x", probe.direction.x], ["target_mount_y", probe.direction.y],
     ["target_mount_z", probe.direction.z], ["solar_cell_temperature_k",probe.temperature]]
}

fn _solar_port(record, name, direction) {
    let matches = [];
    for port in record.ports {
        if port.name == name && port.direction == direction { matches.push(port); }
    }
    if matches.len() != 1 || matches[0].value == () || !matches[0].value.is_finite() {
        throw("Solar observation requires one finite native port: " + name);
    }
    matches[0].value
}

fn solar_power_check(model, rover, probe, first_tick) {
    let names = ["solar_available_power", "solar_power", "irradiance", "sun_visibility",
        "target_mount_x", "target_mount_y", "target_mount_z", "solar_cell_temperature_k",
        "solar_temperature_k", "solar_temperature_factor"];
    let batch = query("ReadPortsBatch", #{targets: [#{api_id: rover, port_names: names}]});
    if batch == () || batch.sim_tick == () || batch.sim_tick.to_int() != sim_tick()
        || batch.entities == () || batch.entities.len() != 1
        || batch.entities[0].api_id.to_int() != rover {
        throw("Solar runtime snapshot is unavailable or from another tick/owner");
    }
    let ports = batch.entities[0];
    for write in _solar_writes(probe) {
        if _solar_port(ports, write[0], "in") != write[1] {
            throw("Synthetic solar input has not reached its native owner: " + write[0]);
        }
    }
    let inputs = _solar_source_inputs(model);
    inputs += _solar_temperature_inputs(model);
    let cosine = model.source_literal_observation(model.attribute(probe.cosine));
    if cosine.state != "value" { throw("Synthetic solar incidence is unavailable"); }
    inputs.push(["incidenceCosine", #{provider: "derived", state: "value",
        value: cosine.value, source_revision: model.source_revision,
        provider_generation: model.source_revision, document_id: (), document_generation: (),
        detail: "Expected incidence for the source-defined synthetic probe: " + probe.cosine}]);
    for field in [["availablePowerW", "solar_available_power", "out"],
                  ["deliveredPowerW", "solar_power", "out"],
                  ["irradianceWm2", "irradiance", "in"],
                  ["sunVisibility", "sun_visibility", "in"],
                  ["cellTemperatureK", "solar_temperature_k", "out"],
                  ["temperatureFactor", "solar_temperature_factor", "out"]] {
        inputs.push([field[0], #{provider: "telemetry", state: "value",
            value: _solar_port(ports, field[1], field[2]),
            provider_generation: batch.sim_tick, source_revision: model.source_revision,
            document_id: (), document_generation: (),
            sample_interval: #{clock: "simulation", start_tick: first_tick, end_tick: batch.sim_tick}}]);
    }
    print("FLIP_SOLAR_PROBE " + #{probe: probe.id, sim_tick: batch.sim_tick,
        available_w: _solar_port(ports, "solar_available_power", "out"),
        delivered_w: _solar_port(ports, "solar_power", "out"),
        cell_temperature_k: _solar_port(ports,"solar_temperature_k","out"),
        temperature_factor: _solar_port(ports,"solar_temperature_factor","out"),
        irradiance_w_m2: probe.irradiance, visibility: probe.visibility});
    _solar_check(model, "FSP-008-" + probe.id, "FSPC008_SolarAvailablePower", inputs)
}

fn _solar_diagnostic(source, model, id, constraint, values, expected) {
    let inputs = _solar_source_inputs(model);
    if constraint == "FSPC008_SolarAvailablePower" { inputs += _solar_temperature_inputs(model); }
    if constraint == "FSPC008_SolarConfiguration" {
        for field in [["areaToleranceM2", _solar_limit("areaToleranceM2")],
                      ["efficiencyTolerance", _solar_limit("efficiencyTolerance")]] {
            inputs.push([field[0], model.source_literal_observation(model.attribute(field[1]))]);
        }
    }
    for name in values.keys() {
        inputs.push([name, #{provider: "derived", state: "value", value: values[name],
            source_revision: model.source_revision, provider_generation: model.source_revision,
            document_id: (), document_generation: (),
            detail: "Synthetic formal-criterion diagnostic; not a model observation"}]);
    }
    let result = sysml_requirements::evaluate(source,
        [_solar_check(model, id, constraint, inputs)]);
    sysml_requirement_checks::preflight(id, result.verdict == expected,
        "Solar criterion diagnostic expected " + expected + ", received " + result.verdict,
        result.verdict, expected)
}

fn solar_criterion_diagnostics(source, model) {
    let width = required_number(source, own("solarCellWidthM"));
    let depth = required_number(source, own("solarCellDepthM"));
    let efficiency = required_number(source, own("solarArrayEfficiency"));
    let peak = required_number(source, own("solarArrayPeakPowerW"));
    let area_offset = required_number(source, _solar_probe("counterexampleAreaOffsetM2"));
    let efficiency_offset = required_number(source, _solar_probe("counterexampleEfficiencyOffset"));
    let power_offset = required_number(source, _solar_probe("counterexamplePowerOffsetW"));
    if area_offset <= required_number(source, _solar_limit("areaToleranceM2"))
        || efficiency_offset <= required_number(source, _solar_limit("efficiencyTolerance"))
        || power_offset <= required_number(source, _solar_limit("powerToleranceW")) {
        throw("Solar counterexample offsets must exceed their acceptance allowances");
    }
    let diagnostics = [];
    let configuration = #{areaM2: width * depth, efficiency: efficiency, peakPowerW: peak};
    diagnostics.push(_solar_diagnostic(source, model, "solar-config-nominal",
        "FSPC008_SolarConfiguration", configuration, "pass"));
    for field in [#{name: "areaM2", offset: area_offset},
                  #{name: "efficiency", offset: efficiency_offset},
                  #{name: "peakPowerW", offset: power_offset}] {
        let invalid = configuration;
        invalid[field.name] += field.offset;
        diagnostics.push(_solar_diagnostic(source, model, "solar-config-reject-" + field.name,
            "FSPC008_SolarConfiguration", invalid, "fail"));
    }
    let bright = #{availablePowerW: peak, deliveredPowerW: peak,
        cellTemperatureK: required_number(source,own("solarReferenceTemperatureK")),
        temperatureFactor: 1.0,
        irradianceWm2: required_number(source, _solar_probe("brightIrradianceWm2")),
        sunVisibility: required_number(source, _solar_probe("visibleSunFraction")),
        incidenceCosine: required_number(source, _solar_probe("frontCosine"))};
    let dim = bright;
    dim.irradianceWm2 = required_number(source, _solar_probe("dimIrradianceWm2"));
    dim.availablePowerW = width * depth * efficiency * dim.irradianceWm2;
    dim.deliveredPowerW = dim.availablePowerW;
    let occluded = bright;
    occluded.sunVisibility = required_number(source, _solar_probe("occludedSunFraction"));
    occluded.availablePowerW = 0.0; occluded.deliveredPowerW = 0.0;
    let back = bright;
    back.incidenceCosine = required_number(source, _solar_probe("backCosine"));
    back.availablePowerW = 0.0; back.deliveredPowerW = 0.0;
    for probe in [#{id: "bright", values: bright}, #{id: "dim", values: dim},
                  #{id: "occluded", values: occluded}, #{id: "back", values: back}] {
        diagnostics.push(_solar_diagnostic(source, model, "solar-law-nominal-" + probe.id,
            "FSPC008_SolarAvailablePower", probe.values, "pass"));
        let invalid = probe.values;
        invalid.availablePowerW = if probe.id == "dim" { peak }
            else { invalid.availablePowerW + power_offset };
        diagnostics.push(_solar_diagnostic(source, model, "solar-law-reject-" + probe.id,
            "FSPC008_SolarAvailablePower", invalid, "fail"));
    }
    for invalid_power in [-power_offset, peak + power_offset, 0.0] {
        let invalid = bright; invalid.deliveredPowerW = invalid_power;
        diagnostics.push(_solar_diagnostic(source, model, "solar-delivery-reject-" + invalid_power,
            "FSPC008_SolarAvailablePower", invalid, "fail"));
    }
    for probe in [#{id: "dim", values: dim}, #{id: "occluded", values: occluded},
                  #{id: "back", values: back}] {
        let invalid = probe.values;
        invalid.deliveredPowerW = if probe.id == "dim" { peak } else { power_offset };
        diagnostics.push(_solar_diagnostic(source, model, "solar-reject-created-power-" + probe.id,
            "FSPC008_SolarAvailablePower", invalid, "fail"));
    }
    let incomplete = bright; incomplete.remove("availablePowerW");
    let coefficient=required_number(source,own("solarPowerTemperatureCoefficientPerK"));
    let delta=required_number(source,_solar_probe("temperatureProbeDeltaK"));
    for offset in [delta,-delta] {
        let thermal=bright;thermal.cellTemperatureK+=offset;
        thermal.temperatureFactor=max(0.0,1.0+coefficient*offset);
        thermal.availablePowerW=peak*thermal.temperatureFactor;
        thermal.deliveredPowerW=thermal.availablePowerW;
        diagnostics.push(_solar_diagnostic(source,model,"solar-temperature-nominal-"+offset,
            "FSPC008_SolarAvailablePower",thermal,"pass"));
        let invalid=thermal;invalid.availablePowerW=peak;
        diagnostics.push(_solar_diagnostic(source,model,"solar-temperature-reject-flat-rating-"+offset,
            "FSPC008_SolarAvailablePower",invalid,"fail"));
    }
    let wrong_factor=bright;wrong_factor.temperatureFactor=1.1;
    diagnostics.push(_solar_diagnostic(source,model,"solar-temperature-reject-wrong-factor",
        "FSPC008_SolarAvailablePower",wrong_factor,"fail"));
    let invalid_temperature=bright;invalid_temperature.cellTemperatureK=0.0;
    diagnostics.push(_solar_diagnostic(source,model,"solar-temperature-reject-zero-kelvin",
        "FSPC008_SolarAvailablePower",invalid_temperature,"fail"));
    diagnostics.push(_solar_diagnostic(source, model, "solar-missing-observation",
        "FSPC008_SolarAvailablePower", incomplete, "inconclusive"));
    let malformed = bright; malformed.unknownParameter = 1.0;
    diagnostics.push(_solar_diagnostic(source, model, "solar-unknown-observation",
        "FSPC008_SolarAvailablePower", malformed, "error"));
    let result = sysml_requirement_checks::preflight_report(diagnostics, "/World/FLIP", PACKAGE);
    // This is an observation event, not an earlier terminal PASS. The mapped
    // gate accepts only after all real configuration and power checks finish.
    emit("FLIP_SOLAR_CRITERIA_DIAGNOSTICS", #{source_revision: model.source_revision,
        check_count: result.check_count, pass_count: result.pass_count,
        error_count: result.error_count, results: diagnostics});
    print("FLIP_SOLAR_CRITERIA_DIAGNOSTICS " + #{checks: result.check_count,
        passes: result.pass_count, errors: result.error_count});
    result
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let model = sysml_requirements::model();
    if model == () || !sysml_model_is(model) { throw("Solar requirement source is unavailable"); }
    if this.phase == "geometry" {
        let source = sensor_power_source();
        this.source = source;
        this.source_revision = source.source_revision;
        this.checks = geometry_checks(source);
        this.cases = solar_cases(source);
        this.dwell = required_number(source, _solar_probe("observationDwellS"));
        this.timeout = required_number(source, _solar_probe("observationTimeoutS"));
        this.phase = "command";
    }
    if model.source_revision != this.source_revision { throw("Solar verification source changed during the case"); }
    if elapsed_seconds() - this.started > this.timeout {
        throw("Solar qualification did not complete within its source timeout");
    }
    if this.phase == "command" {
        let ack = cmd("SetPorts", #{target: this.rover, writes: _solar_writes(this.cases[this.case_index])});
        if ack == () || ack.ok != true { throw("Solar probe input was rejected: " + ack); }
        this.command_time = elapsed_seconds();
        this.command_tick = sim_tick();
        this.phase = "observe";
        return;
    }
    if elapsed_seconds() - this.command_time < this.dwell { return; }
    this.checks.push(solar_power_check(model, this.rover, this.cases[this.case_index], this.command_tick));
    this.case_index += 1;
    if this.case_index < this.cases.len() { this.phase = "command"; return; }
    for name in ["irradiance", "sun_visibility", "target_mount_x", "target_mount_y", "target_mount_z", "solar_cell_temperature_k"] {
        let ack = cmd("ReleasePort", #{target: this.rover, name: name});
        if ack == () || ack.ok != true { throw("Solar probe input release was rejected: " + ack); }
    }
    let diagnostics = solar_criterion_diagnostics(this.source, model);
    if diagnostics.ok != true {
        report_structured_verdict(diagnostics, "FLIP SENSOR/POWER REQUIREMENTS", "FLIP_SENSOR_POWER_REQUIREMENTS");
        this.done = true;
        return;
    }
    sysml_requirement_checks::finish(this.source, this.checks, "FLIP SENSOR/POWER REQUIREMENTS",
        "FLIP_SENSOR_POWER_REQUIREMENTS", sysml_requirements::text(this.source, own("mastPath")), PACKAGE, VERIFICATION);
    this.done = true;
}
