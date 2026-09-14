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
        "rampSurfaceThicknessM", "rampMaxDeploymentAngleRad",
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
        "sensorMastHeightM", "componentReference", "missionReference"
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
fn visual_requirement_usage_count() { _sysml_integer("visualRequirementUsageCount") }
fn visual_verification_case_name() { _sysml_text("visualVerificationCaseName") }
fn visual_camera_name() { _sysml_text("visualCameraName") }
fn visual_lander_name() { _sysml_text("visualLanderName") }
fn visual_rover_name() { _sysml_text("visualRoverName") }
fn visual_lander_deck_width_m() { _sysml_attribute("visualLanderDeckWidthM") }
fn visual_rover_wheel_radius_m() { _sysml_attribute("visualRoverWheelRadiusM") }
fn visual_rover_wheel_count() { _sysml_integer("visualRoverWheelCount") }
fn visual_rover_wheel_names() { _sysml_list("visualWheelNames") }
fn visual_landing_pad_radius_m() { _sysml_attribute("visualLandingPadRadiusM") }
fn visual_review_ground_width_m() { _sysml_attribute("visualReviewGroundWidthM") }
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
