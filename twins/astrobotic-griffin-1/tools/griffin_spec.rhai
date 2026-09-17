// Machine-readable Griffin study policy.
//
// Keep this module free of USD queries and edits. Numeric policy is read from
// the co-located standard SysML source through the compact ValidateSysml query;
// Rhai still owns the executable test policy while contracts/*.md records
// meaning and provenance.

fn _sysml_source() {
    // The generic helper is the one source-set admission point. It carries
    // qualified attributes, collision diagnostics, and the source revision;
    // this Twin policy must not recreate that lookup or choose a fallback.
    sysml_requirements::source()
}

fn _sysml_attribute(name) {
    let source = _sysml_source();
    if source == () || source.ok != true { return (); }
    sysml_requirements::number(source, _qualified_attribute(name))
}

fn _sysml_integer(name) {
    let value = _sysml_attribute(name);
    if value == () { return (); }
    value.to_int()
}

fn _sysml_text(name) {
    let source = _sysml_source();
    if source == () || source.ok != true { return (); }
    sysml_requirements::text(source, _qualified_attribute(name))
}

// The Twin intentionally composes several SysML packages that reuse local
// names such as `solarArrayCount` and `missionReference`.  Resolve every
// public accessor to its owning package before crossing the generic bridge;
// an ambiguous short-name lookup must never silently select another
// component's value.
fn _qualified_attribute(name) {
    let lander = [
        "payloadCapacityKg", "landingLegCount", "mainEngineCount",
        "propellantTankCount", "solarArrayCount", "geometryStatus",
        "massPropertiesStatus", "rampStatus", "solarArrayStatus"
    ];
    if lander.contains(name) {
        return "Griffin1Requirements::Griffin1Lander::" + name;
    }
    let ramp = [
        "rampCount", "rampSurfaceLengthM", "rampSurfaceWidthM",
        "rampWheelClearanceM", "rampSurfaceThicknessM", "rampRailHeightM",
        "rampRailWidthM", "rampSurfaceCenterYM", "rampRailCenterYM",
        "rampMaxDeploymentAngleRad",
        "rampPortMountX", "rampStarboardMountX", "rampMountY", "rampMountZ",
        "rampHingeOffsetX", "rampHingeOffsetY", "rampHingeOffsetZ",
        "rampSocketX", "rampSocketY", "rampSocketZ",
        "rampPortDeploymentAngleRad", "rampStarboardDeploymentAngleRad",
        "rampBehavior", "hingeAxis", "mountDatum", "rampGeometryStatus",
        "provenanceSource", "referenceImage"
    ];
    if ramp.contains(name) {
        return "GriffinRampRequirements::GriffinEgressRamp::" + name;
    }
    let rover = [
        "flipMassStudyKg", "flipPayloadCapacityKg", "wheelCount",
        "wheelCountStatus", "egressMode", "solarArrayMode", "mobilityStatus",
        "exactVehicleIcdStatus", "visualRoverName", "visualRoverWheelRadiusM",
        "visualRoverWheelCount", "visualWheelNames", "frontSteeringAngleDeg",
        "rearSteeringAngleDeg", "chassisWidthM", "chassisLengthM",
        "sensorMastHeightM", "wheelStationX", "wheelStationY",
        "wheelStationZ", "solarArrayMount", "solarArrayTiltDeg",
        "suspensionStrutScale", "suspensionStrutOffset",
        "suspensionArmScale", "suspensionArmOffsetM",
        "suspensionKnuckleRadiusM", "suspensionKnuckleWidthM",
        "componentReference", "missionReference"
    ];
    if rover.contains(name) {
        return "FlipRequirements::FlipRover::" + name;
    }
    let project = [
        "unitSystem", "lengthUnit", "massUnit", "angleUnit", "timeUnit",
        "frameUpAxis", "metersPerUnit", "moonbaseRequirementUsageCount",
        "moonbaseRequirementIds", "moonbaseVerificationCaseName"
    ];
    if project.contains(name) {
        return "MoonBaseProjectRequirements::ProjectSimulationContract::" + name;
    }
    let lander_component = [
        "componentName", "bodyProfile", "bodyWidthM", "bodyDepthM",
        "bodyHeightM", "busMountY", "tankStationX", "tankStationY",
        "tankStationZ", "legStationX", "legStationY", "legStationZ",
        "solarStationX", "solarStationY", "solarStationZ",
        "engineStationX", "engineStationY", "engineStationZ",
        "engineClusterWidthM", "engineClusterDepthM", "engineSkirtHeightM",
        "engineSkirtRailSectionM", "engineBellClearanceM", "engineMountYM"
    ];
    if lander_component.contains(name) {
        return "GriffinLanderRequirements::GriffinLanderComponent::" + name;
    }
    "Griffin1Requirements::PublicMissionContext::" + name
}

// Public for Twin-local policy modules that need to validate the same
// cross-package source without duplicating ownership tables.
fn qualified_attribute_name(name) { _qualified_attribute(name) }

fn _sysml_list(name) {
    let value = _sysml_text(name);
    if value == () || value == "" { return []; }
    let items = [];
    for item in value.split(",") {
        // Rhai's trim mutates the string and returns unit, so retain the
        // split item after trimming instead of pushing the unit result.
        item.trim();
        if item != "" { items.push(item); }
    }
    items
}

// Parse a comma-separated numeric datum list owned by SysML.  Returning an
// empty list for a missing/empty source is intentional: callers must validate
// the expected cardinality before indexing, so malformed station data fails
// loudly instead of silently inventing a placement.
fn _sysml_number_list(name) {
    let text = _sysml_text(name);
    if text == () || text == "" { return []; }
    let values = [];
    for item in text.split(",") {
        item.trim();
        if item == "" { return []; }
        values.push(parse_float(item));
    }
    values
}

// One canonical payload datum lives on Griffin1Lander.  Requirement GR-009
// consumes that datum instead of declaring a second 625 kg literal.
fn max_payload_kg() { _sysml_attribute("payloadCapacityKg") }
// Ramp limits are owned by the dedicated ramp requirement package. Keep this
// compatibility accessor for lander mission helpers without duplicating the
// numeric datum in the Griffin package.
fn max_ramp_command_rad() { _sysml_attribute("rampMaxDeploymentAngleRad") }
fn main_engine_count() { _sysml_integer("mainEngineCount") }
fn propellant_tank_count() { _sysml_integer("propellantTankCount") }
fn landing_leg_count() { _sysml_integer("landingLegCount") }
fn ramp_count() { _sysml_integer("rampCount") }
fn solar_array_count() { _sysml_integer("solarArrayCount") }
fn landing_com_touchdown_y() { _sysml_attribute("landingComTouchdownY") }
fn landing_stability_horizon_s() { _sysml_attribute("landingStabilityHorizonS") }
fn landing_max_tilt_rad() { _sysml_attribute("landingMaxTiltRad") }
fn landing_max_ground_speed_mps() { _sysml_attribute("landingMaxGroundSpeedMps") }
fn landing_max_angular_speed_rad_per_sec() { _sysml_attribute("landingMaxAngularSpeedRadPerSec") }
fn landing_max_horizontal_drift_m() { _sysml_attribute("landingMaxHorizontalDriftM") }
fn landing_divergence_tolerance_m() { _sysml_attribute("landingDivergenceToleranceM") }
fn landing_divergence_tolerance_upright() { _sysml_attribute("landingDivergenceToleranceUpright") }
fn landing_divergence_tolerance_speed_mps() { _sysml_attribute("landingDivergenceToleranceSpeedMps") }
fn landing_replay_tolerance_m() { _sysml_attribute("landingReplayToleranceM") }
fn landing_replay_tolerance_upright() { _sysml_attribute("landingReplayToleranceUpright") }
fn landing_replay_tolerance_speed_mps() { _sysml_attribute("landingReplayToleranceSpeedMps") }
fn landing_replay_tolerance_time_s() { _sysml_attribute("landingReplayToleranceTimeS") }
fn landing_phase_timeout_s() { _sysml_attribute("landingPhaseTimeoutS") }
fn rover_settle_timeout_s() { _sysml_attribute("roverSettleTimeoutS") }
fn rover_settle_height_limit_m() { _sysml_attribute("roverSettleHeightLimitM") }
fn rover_settle_speed_limit_mps() { _sysml_attribute("roverSettleSpeedLimitMps") }
fn surface_route_timeout_s() { _sysml_attribute("surfaceRouteTimeoutS") }
fn surface_route_stall_timeout_s() { _sysml_attribute("surfaceRouteStallTimeoutS") }
fn visual_requirement_usage_count() { _sysml_integer("visualRequirementUsageCount") }
fn visual_verification_case_name() { _sysml_text("visualVerificationCaseName") }
fn visual_camera_name() { _sysml_text("visualCameraName") }
fn visual_lander_name() { _sysml_text("visualLanderName") }
fn visual_rover_name() { _sysml_text("visualRoverName") }
fn visual_lander_deck_width_m() { _sysml_attribute("visualLanderDeckWidthM") }
fn visual_rover_wheel_radius_m() { _sysml_attribute("visualRoverWheelRadiusM") }
fn visual_rover_wheel_count() { _sysml_integer("visualRoverWheelCount") }
fn visual_rover_wheel_names() { _sysml_list("visualWheelNames") }
fn component_bus_mount_y() { _sysml_attribute("busMountY") }
fn component_tank_station_x() { _sysml_number_list("tankStationX") }
fn component_tank_station_y() { _sysml_number_list("tankStationY") }
fn component_tank_station_z() { _sysml_number_list("tankStationZ") }
fn component_leg_station_x() { _sysml_number_list("legStationX") }
fn component_leg_station_y() { _sysml_number_list("legStationY") }
fn component_leg_station_z() { _sysml_number_list("legStationZ") }
fn component_solar_station_x() { _sysml_number_list("solarStationX") }
fn component_solar_station_y() { _sysml_number_list("solarStationY") }
fn component_solar_station_z() { _sysml_number_list("solarStationZ") }
fn component_engine_station_x() { _sysml_number_list("engineStationX") }
fn component_engine_station_y() { _sysml_number_list("engineStationY") }
fn component_engine_station_z() { _sysml_number_list("engineStationZ") }
fn rover_wheel_station_x() { _sysml_number_list("wheelStationX") }
fn rover_wheel_station_y() { _sysml_number_list("wheelStationY") }
fn rover_wheel_station_z() { _sysml_number_list("wheelStationZ") }
fn suspension_strut_scale() { _sysml_number_list("suspensionStrutScale") }
fn suspension_strut_offset() { _sysml_number_list("suspensionStrutOffset") }
fn suspension_arm_scale() { _sysml_number_list("suspensionArmScale") }
fn suspension_arm_offset_m() { _sysml_attribute("suspensionArmOffsetM") }
fn suspension_knuckle_radius_m() { _sysml_attribute("suspensionKnuckleRadiusM") }
fn suspension_knuckle_width_m() { _sysml_attribute("suspensionKnuckleWidthM") }
fn rover_solar_array_mount() { _sysml_number_list("solarArrayMount") }
fn rover_solar_array_tilt_deg() { _sysml_attribute("solarArrayTiltDeg") }
fn visual_landing_pad_radius_m() { _sysml_attribute("visualLandingPadRadiusM") }
fn visual_review_ground_width_m() { _sysml_attribute("visualReviewGroundWidthM") }
fn visual_terrain_asset() { _sysml_text("visualTerrainAsset") }
fn visual_terrain_shader_asset() { _sysml_text("visualTerrainShaderAsset") }
fn visual_render_ownership() { _sysml_text("visualRenderOwnership") }
fn pi_value() { 3.141592653589793 }

fn frame() {
    #{ units: _sysml_text("frameUnits"), up_axis: _sysml_text("frameUpAxis"),
       root_datum: _sysml_text("frameRootDatum") }
}

fn canonical_parts() {
    _sysml_list("canonicalPartNames")
}

fn solar_array_names() { _sysml_list("solarArrayNames") }
fn landing_leg_names() { _sysml_list("landingLegNames") }
fn landing_pad_names() { _sysml_list("landingPadNames") }
fn ramp_names() { _sysml_list("rampNames") }
fn ramp_hinge_names() { _sysml_list("rampHingeNames") }
fn propellant_tank_names() { _sysml_list("propellantTankNames") }
fn main_engine_names() { _sysml_list("mainEngineNames") }

fn check_catalog() {
    _sysml_list("executableRequirementIds")
}

fn requirement_usage_count() { _sysml_integer("requirementUsageCount") }
fn manifest_part_count() { _sysml_integer("manifestPartCount") }
fn verification_case_name() { _sysml_text("verificationCaseName") }
fn planned_rules() { _sysml_list("plannedRequirementIds") }
fn mission_scope_rules() { _sysml_list("missionScopeRequirementIds") }
fn process_gate_rules() { _sysml_list("processGateRequirementIds") }
