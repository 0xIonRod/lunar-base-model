import "lunco://scripting/tools/sysml_requirements" as sysml_requirements;
import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;

// Machine-readable Griffin study policy.
//
// Keep this module free of USD queries and edits. Numeric policy comes from
// the Twin's typed SysML model, including structured collections. Rhai owns
// reusable planning policy while contracts/*.md records meaning and provenance.

fn rcs_port_mapping() {
    [
        #{model_name: "RcsPitchPosModel", valve_port: "pitch_pos_a_valve", thrust_port: "pitch_pos_a_thrust_n"},
        #{model_name: "RcsPitchPosBModel", valve_port: "pitch_pos_b_valve", thrust_port: "pitch_pos_b_thrust_n"},
        #{model_name: "RcsPitchNegModel", valve_port: "pitch_neg_a_valve", thrust_port: "pitch_neg_a_thrust_n"},
        #{model_name: "RcsPitchNegBModel", valve_port: "pitch_neg_b_valve", thrust_port: "pitch_neg_b_thrust_n"},
        #{model_name: "RcsRollPosModel", valve_port: "roll_pos_a_valve", thrust_port: "roll_pos_a_thrust_n"},
        #{model_name: "RcsRollPosBModel", valve_port: "roll_pos_b_valve", thrust_port: "roll_pos_b_thrust_n"},
        #{model_name: "RcsRollNegModel", valve_port: "roll_neg_a_valve", thrust_port: "roll_neg_a_thrust_n"},
        #{model_name: "RcsRollNegBModel", valve_port: "roll_neg_b_valve", thrust_port: "roll_neg_b_thrust_n"},
        #{model_name: "RcsYawPosModel", valve_port: "yaw_pos_a_valve", thrust_port: "yaw_pos_a_thrust_n"},
        #{model_name: "RcsYawPosBModel", valve_port: "yaw_pos_b_valve", thrust_port: "yaw_pos_b_thrust_n"},
        #{model_name: "RcsYawNegModel", valve_port: "yaw_neg_a_valve", thrust_port: "yaw_neg_a_thrust_n"},
        #{model_name: "RcsYawNegBModel", valve_port: "yaw_neg_b_valve", thrust_port: "yaw_neg_b_thrust_n"},
    ]
}

// Keep repeated Griffin lookups on one Rust-owned, revision-pinned SysML
// session. The qualified name is an identifier boundary; the engineering
// value itself remains a native Rust/Rhai value.
fn _sysml_model() {
    sysml_requirements::model()
}

fn _sysml_model_value(name) {
    _typed_model_value(_qualified_attribute(name))
}

fn _typed_model_value(qualified) {
    let model = _sysml_model();
    if model == () || !sysml_model_is(model) { return (); }
    let value = model.value(qualified);
    if value == () { return (); }
    value
}

fn _typed_model_number(qualified) {
    let native = _typed_model_value(qualified);
    if native != () {
        if sysml_quantity_is(native) { return f64_from(native.value); }
        let scalar = f64_from(native);
        if scalar != () { return scalar; }
    }
    ()
}

fn _typed_model_text_list(qualified) {
    let value = _typed_model_value(qualified);
    if value == () || !array_is(value) { return []; }
    let items = [];
    for item in value {
        if string_is(item) { items.push(item); }
        else if sysml_enum_is(item) { items.push(item.literal); }
        else { return []; }
    }
    items
}

fn _sysml_attribute(name) {
    let qualified = _qualified_attribute(name);
    let native = _sysml_model_value(name);
    if native != () {
        if sysml_quantity_is(native) { return f64_from(native.value); }
        let scalar = f64_from(native);
        if scalar != () { return scalar; }
    }
    let source = sysml_requirements::source_with_attributes([qualified]);
    if source == () || source.ok != true { return (); }
    sysml_requirements::number(source, qualified)
}

fn _sysml_integer(name) {
    let value = _sysml_attribute(name);
    if value == () { return (); }
    value.to_int()
}

fn _sysml_text(name) {
    let qualified = _qualified_attribute(name);
    let native = _sysml_model_value(name);
    if native != () {
        if string_is(native) { return native; }
        if sysml_enum_is(native) { return native.literal; }
    }
    let source = sysml_requirements::source_with_attributes([qualified]);
    if source == () || source.ok != true { return (); }
    sysml_requirements::text(source, qualified)
}

// Lander component counts have one canonical owner in
// GriffinLanderRequirements. Griffin1Requirements owns the integrated
// mission subject and payload-capacity value only. Keep these API aliases
// explicit while the component contract uses concise local names.
fn _qualified_attribute(name) {
    if name == "payloadCapacityKg" {
        return "Griffin1Requirements::Griffin1Lander::" + name;
    }
    if name == "landingLegCount" { return "GriffinLanderRequirements::GriffinLanderComponent::legCount"; }
    if name == "propellantTankCount" { return "GriffinLanderRequirements::GriffinLanderComponent::tankCount"; }
    if name == "mainEngineCount" { return "GriffinLanderRequirements::GriffinLanderComponent::engineCount"; }
    if name == "solarArrayCount" { return "GriffinLanderRequirements::GriffinLanderComponent::solarArrayCount"; }
    let ramp = [
        "rampCount", "rampSurfaceLengthM", "rampSurfaceWidthM",
        "sectionAsset", "sectionInstances", "rootJointInstances", "intermediateJointInstances",
        "treadInstances", "railJointPinInstances", "transitionBody", "transitionContact", "transitionJoints",
        "rampSectionCount", "rampSectionLengthM", "rampSectionGeometryToleranceM",
        "rampWheelClearanceM", "rampSurfaceThicknessM", "rampRailHeightM",
        "rampRailWidthM", "rampRailOffsetZM", "rampCenterRailOffsetZM", "rampRailJointPinRadiusM",
        "rampRailJointPinLengthM", "rampPivotLugWidthM", "rampPivotLugThicknessM", "rampSurfaceCenterYM", "rampRailCenterYM",
        "rampMaxDeploymentAngleRad",
        "rampPortMountX", "rampStarboardMountX", "rampMountY", "rampMountZ",
        "rampHingeOffsetX", "rampHingeOffsetY", "rampHingeOffsetZ",
        "assemblyTreadCount", "assemblyTreadCountPerSection",
        "assemblyTreadWidthM", "assemblyTreadHeightM", "assemblyTrackWidthM",
        "assemblyTreadFirstCenterXM", "assemblyTreadPitchM",
        "assemblyUnderBeamWidthM", "assemblyUnderBeamHeightM",
        "assemblyUnderBeamCenterYM", "assemblyUnderBeamCenterOffsetZM",
        "assemblySidePostCountPerSectionPerSide", "assemblySidePostWidthM",
        "assemblySidePostDepthM", "assemblySidePostEmbeddedDepthM",
        "assemblySidePostFirstCenterXM",
        "assemblySidePostPitchM", "assemblySideTrussChordHeightM",
        "assemblySideTrussLowerChordCenterYM",
        "assemblySideTrussBraceThicknessM", "assemblySideTrussBraceCountPerSide",
        "rampSectionHingeBarrelRadiusM",
        "rampSectionHingeBarrelLengthM", "rampSectionHingeBarrelCenterYM",
        "rampSocketX", "rampSocketY", "rampSocketZ",
        "rampPortDeploymentAngleRad", "rampStarboardDeploymentAngleRad",
        "hingeAxis", "rampStowedScale",
        "rampStowedRotationZDeg", "rampStowedStarboardRotationYDeg",
        "physicalRampDeckTransitionRequiredOverlapM",
        "physicalRampDeckTransitionLengthM",
        "physicalRampDeckTransitionInterfaceToleranceM",
        "physicalRampDeckTransitionOutboardX",
        "physicalRampDeckTransitionCenterY",
        "physicalRampTerrainContactToleranceM",
        "physicalRampPortMountX",
        "physicalRampStarboardMountX", "physicalRampMountY",
        "physicalRampMountZ", "physicalRampPortDeploymentAngleRad",
        "physicalRampStarboardDeploymentAngleRad",
        "physicalRampMassKg", "physicalRampSectionMassKg",
        "physicalRampSectionInertiaXKgM2", "physicalRampSectionInertiaYKgM2",
        "physicalRampSectionInertiaZKgM2", "physicalRampSectionJointLimitRad",
        "physicalRampPortRootJointStowLimitRad", "physicalRampRootStowedAngleRad",
        "physicalRampStarboardRootJointStowLimitRad",
        "physicalRampSectionStowedRelativeAngleRad", "physicalRampSectionJointFrameOffsetRad",
        "physicalRampSectionDeploymentRelativeAngleRad",
        "physicalRampSectionUnfoldWaypointRelativeAngleRad",
        "physicalRampHingeSettleAngleToleranceRad",
        "physicalRampHingeSettleSpeedToleranceRadPerS",
        "physicalRampTraversalSettleDwellS",
        "physicalRampSectionMassPartitionToleranceKg",
        "physicalRampJointDriveStiffnessNmPerDeg",
        "physicalRampRootJointDriveDampingNmPerDegPerSec",
        "physicalRampSectionJointDriveDampingNmPerDegPerSec",
        "physicalRampJointDriveMaxTorqueNm",
        "physicalRampSectionMassPropertiesToleranceKgM2",
        "physicalRampDeckTransitionMassKg",
        "physicalRampDeckTransitionInertiaKgM2",
    ];
    if ramp.contains(name) {
        return "GriffinRampRequirements::GriffinEgressRamp::" + name;
    }
    let rover = [
        "flipMassStudyKg", "flipPayloadCapacityKg", "batteryNominalVoltageV",
        "egressMode", "solarArrayMode", "mobilityStatus",
        "exactVehicleIcdStatus", "wheelRadiusM", "wheelWidthM",
        "wheelStations", "missionSteeringMode", "chassisWidthM", "chassisLengthM",
        "sensorMastHeightM", "forwardYawOffsetRad", "wheelStationX", "wheelStationY",
        "wheelStationZ", "suspensionRestLengthM",
        "suspensionStrutScale", "suspensionStrutOffset",
        "suspensionArmScale", "suspensionArmOffsetM",
        "suspensionKnuckleRadiusM", "suspensionKnuckleWidthM"
    ];
    if rover.contains(name) {
        return "FlipRequirements::FlipRover::" + name;
    }
    let sensor_power = ["mastMountCenterYM", "mastMountCenterZM",
        "batteryEnergyKWh", "solarArrayPeakPowerW"];
    if sensor_power.contains(name) {
        return "FlipSensorPowerRequirements::FlipSensorPowerAssembly::" + name;
    }
    let project = [
        "unitSystem", "lengthUnit", "massUnit", "angleUnit", "timeUnit",
        "frameUpAxis", "metersPerUnit"
    ];
    if project.contains(name) {
        return "MoonBaseProjectRequirements::ProjectSimulationContract::" + name;
    }
    let lander_component = [
        "componentName"
    ];
    if lander_component.contains(name) {
        return "GriffinLanderRequirements::GriffinLanderComponent::" + name;
    }
    let visual_configuration = [
        "configuration", "bodyProfile", "rampState", "origin", "axisUp", "axisPort", "axisForward",
        "reviewCameraName", "reviewLanderName",
        "verificationToleranceM", "geometryVerificationToleranceM",
        "appearanceVerificationTolerance", "doubleSidedFacesMust",
        "renderOnlyCollisionEnabled", "renderPurpose",
        "visualReviewGriffinStation", "visualReviewFlipStation",
        "bodyDimensions", "bodyMount", "bodyGroundClearanceM",
        "lowerSkirtDimensions", "lowerSkirtCenter", "deckDimensions", "deckCenter",
        "avionicsDeckDimensions", "avionicsDeckCenter", "outerBodyProfileCoordinates",
        "frameDisplayColor", "deckDisplayColor", "lowerSkirtDisplayColor",
        "avionicsDeckDisplayColor", "avionicsPodDisplayColor", "railDisplayColor",
        "tankSupportDisplayColor", "tankCollarDisplayColor",
        "frameRingCenterY", "frameRingSectionM",
        "frameRails", "tankInstances", "landingLegInstances", "solarArrayInstances",
        "mainEngineInstances", "rampInstances", "rampHingeInstances",
        "railStations", "railDimensions",
        "tankSupportPerimeterRadiusM",
        "tankSupportPerimeterSectionM", "tankSupportPlanes",
        "tankSupportOpeningInnerRadiusM", "tankSupportOpeningOuterRadiusM",
        "tankSupportOpeningSegments", "centralBucketSegments",
        "centralBucketShellThicknessM", "upperBucketInnerBottomRadiusM",
        "upperBucketOuterBottomRadiusM", "upperBucketInnerTopRadiusM",
        "upperBucketOuterTopRadiusM", "upperBucketBottomCenterYM",
        "upperBucketTopCenterYM", "lowerBucketInnerTopRadiusM",
        "lowerBucketOuterTopRadiusM", "lowerBucketInnerBottomRadiusM",
        "lowerBucketOuterBottomRadiusM", "lowerBucketTopCenterYM",
        "lowerBucketBottomCenterYM", "payloadAdapterDimensions",
        "payloadAdapterCenterYM", "legStations",
        "legStationRotationYDeg", "solarStations", "solarMountRails",
        "solarStationRotationXDeg", "solarStationRotationZDeg",
        "solarArrayEdgeClearanceM", "tankStations",
        "tankStationRotationYDeg", "tankScale",
        "engineClusterMountYM", "engineBellDirection", "engineStations"
    ];
    if visual_configuration.contains(name) {
        return "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::" + name;
    }
    let landing_stability = [
        "landingStabilityHorizonS", "landingStabilitySampleEveryNTicks",
        "landingMinimumUprightAxisY",
        "landingMaxGroundSpeedMps", "landingMaxAngularSpeedRadPerSec",
        "landingMaxHorizontalDriftM"
    ];
    if landing_stability.contains(name) {
        return "GriffinSimulationAccuracyRequirements::GR036_LandingStability::" + name;
    }
    if name == "landingTargetDatumToleranceM" {
        return "GriffinSimulationAccuracyRequirements::GR037_LandingTargetDatum::" + name;
    }
    if name == "landingSurfaceDatumToleranceM" {
        return "GriffinSimulationAccuracyRequirements::GR038_LandingSurfaceDatum::" + name;
    }
    if name == "guidanceAssemblyMassToleranceKg" {
        return "GriffinSimulationAccuracyRequirements::GR039_GuidanceUsesDynamicJointIslandMass::" + name;
    }
    "Griffin1Requirements::PublicMissionContext::" + name
}

// Public for Twin-local policy modules that need to validate the same
// cross-package source without duplicating ownership tables.
fn qualified_attribute_name(name) { _qualified_attribute(name) }

fn _sysml_list(name) {
    let native = _sysml_model_value(name);
    if native != () && array_is(native) {
        let items = [];
        for value in native {
        if sysml_enum_is(value) { items.push(value.literal); }
            else if string_is(value) { items.push(value); }
            else { return []; }
        }
        return items;
    }
    let qualified = _qualified_attribute(name);
    let source = sysml_requirements::source_with_attributes([qualified]);
    if source == () || source.ok != true { return []; }
    let items = sysml_requirement_checks::source_enum_identifiers(source, qualified);
    if items == () { return []; }
    items
}

// Parse a comma-separated numeric datum list owned by SysML.  Returning an
// empty list for a missing/empty source is intentional: callers must validate
// the expected cardinality before indexing, so malformed station data fails
// loudly instead of silently inventing a placement.
fn _sysml_number_list(name) {
    let native = _sysml_model_value(name);
    if native != () && array_is(native) {
        let values = [];
        for value in native {
            let scalar = f64_from(value);
            if scalar == () { return []; }
            values.push(scalar);
        }
        return values;
    }
    let qualified = _qualified_attribute(name);
    let source = sysml_requirements::source_with_attributes([qualified]);
    if source == () || source.ok != true { return []; }
    let typed = sysml_requirements::vector(source, qualified);
    if typed == () { return []; }
    typed
}

// Return the Rust-native value produced by ValidateSysml's typed projection.
// Structured vectors remain DVec3, quaternions DQuat, transforms DTransform,
// and enumeration values remain their SysmlEnumValue wrapper in Rhai.
fn _sysml_native(name) {
    let native = _sysml_model_value(name);
    if native != () { return native; }
    let qualified = _qualified_attribute(name);
    let source = sysml_requirements::source_with_attributes([qualified]);
    if source == () || source.ok != true { return (); }
    sysml_requirements::native_value(source, qualified)
}

fn _sysml_enum_name(name) {
    let value = _sysml_native(name);
    if sysml_enum_is(value) { return value.literal; }
    ()
}

fn _sysml_native_list(name) {
    let value = _sysml_model_value(name);
    if value != () && array_is(value) { return value; }
    []
}

fn _sysml_enum_names(name) {
    let values = _sysml_native_list(name);
    let labels = [];
    for value in values {
        if !sysml_enum_is(value) { return []; }
        labels.push(value.literal);
    }
    labels
}

fn _position_axis(name, axis) {
    let positions = _sysml_native_list(name);
    let values = [];
    for position in positions {
        if !vec3_is_native(position) { return []; }
        values.push(if axis == "x" { position.x } else if axis == "y" {
            position.y
        } else { position.z });
    }
    values
}

fn _dimensions_component(name, axis) {
    let dimensions = _sysml_native(name);
    if dimensions == () || !vec3_is_native(dimensions) { return (); }
    if axis == "x" { return dimensions.x; }
    if axis == "y" { return dimensions.y; }
    dimensions.z
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
fn route_steering_mode() { _sysml_text("missionSteeringMode") }
fn landing_stability_horizon_s() { _sysml_attribute("landingStabilityHorizonS") }
fn guidance_assembly_mass_tolerance_kg() { _sysml_attribute("guidanceAssemblyMassToleranceKg") }
fn landing_stability_sample_every_n_ticks() {
    _sysml_integer("landingStabilitySampleEveryNTicks")
}
fn landing_minimum_upright_axis_y() { _sysml_attribute("landingMinimumUprightAxisY") }
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
fn surface_route_marker_names() { _sysml_list("surfaceRouteMarkerNames") }
fn surface_route_marker_x() { _sysml_number_list("surfaceRouteMarkerX") }
fn surface_route_marker_y() { _sysml_number_list("surfaceRouteMarkerY") }
fn surface_route_marker_z() { _sysml_number_list("surfaceRouteMarkerZ") }
// Route command limits are source data alongside the marker table.  Keep the
// ordered event labels in the mission tool because they are verdict vocabulary,
// while normalized throttle and arrival tolerance cross the SysML/Rhai bridge as typed lists.
fn surface_route_throttle_limits() { _sysml_number_list("surfaceRouteThrottleLimit") }
fn surface_route_arrival_radius_m() { _sysml_number_list("surfaceRouteArrivalRadiusM") }
fn egress_apron_name() { _sysml_text("egressApronName") }
fn egress_apron_center_x_m() { _sysml_attribute("egressApronCenterX") }
fn egress_apron_center_z_m() { _sysml_attribute("egressApronCenterZ") }
fn egress_apron_length_m() { _sysml_attribute("egressApronLengthM") }
fn egress_apron_width_m() { _sysml_attribute("egressApronWidthM") }
fn egress_apron_thickness_m() { _sysml_attribute("egressApronThicknessM") }
fn site_surface_y_m() { _sysml_attribute("siteSurfaceY") }
fn landing_site_pad_name() { _sysml_text("landingSitePadName") }
fn landing_site_pad_extent_m() { _sysml_attribute("landingSitePadExtentM") }
fn landing_site_pad_thickness_m() { _sysml_attribute("landingSitePadThicknessM") }
fn visual_camera_name() { _sysml_text("reviewCameraName") }
fn visual_lander_name() { _sysml_text("reviewLanderName") }
fn visual_lander_deck_width_m() { _sysml_attribute("visualLanderDeckWidthM") }
fn rover_wheel_radius_m() { _sysml_attribute("wheelRadiusM") }
fn rover_wheel_width_m() { _sysml_attribute("wheelWidthM") }
fn rover_battery_energy_kwh() { _sysml_attribute("batteryEnergyKWh") }
fn rover_battery_nominal_voltage_v() { _sysml_attribute("batteryNominalVoltageV") }
fn rover_battery_capacity_ah() {
    let energy_kwh = rover_battery_energy_kwh();
    let voltage_v = rover_battery_nominal_voltage_v();
    if energy_kwh == () || voltage_v == () || voltage_v <= 0.0 { return (); }
    energy_kwh * 1000.0 / voltage_v
}
fn rover_solar_peak_power_w() { _sysml_attribute("solarArrayPeakPowerW") }
fn rover_wheel_station_names() { _sysml_list("wheelStations") }
fn component_bus_mount() { _sysml_native("bodyMount") }
fn component_bus_mount_y() { component_bus_mount().y }
fn component_tank_stations() { _sysml_native_list("tankStations") }
fn component_tank_station_rotation_y_deg() { _sysml_number_list("tankStationRotationYDeg") }
fn component_tank_scale() { _sysml_number_list("tankScale") }
fn component_leg_stations() { _sysml_native_list("legStations") }
fn component_leg_station_rotation_y_deg() { _sysml_number_list("legStationRotationYDeg") }
fn component_solar_stations() { _sysml_native_list("solarStations") }
fn component_solar_station_rotation_x_deg() { _sysml_number_list("solarStationRotationXDeg") }
fn component_solar_station_rotation_z_deg() { _sysml_number_list("solarStationRotationZDeg") }

// Tilt about local X, then orient the face normal around vehicle Y. Keep
// this composition explicit; USD Euler and native Euler adapters have differed.
fn component_solar_orientation(index) {
    let tilt = component_solar_station_rotation_x_deg();
    let bearing = component_solar_station_rotation_z_deg();
    if index < 0 || index >= tilt.len() || index >= bearing.len() { return (); }
    let hx = tilt[index] * pi_value() / 360.0;
    let hy = -bearing[index] * pi_value() / 360.0;
    quat(0.0, sin(hy), 0.0, cos(hy)) * quat(sin(hx), 0.0, 0.0, cos(hx))
}

fn component_solar_orientation_components(index) {
    let q = component_solar_orientation(index);
    if !quat_is_valid(q) { return []; }
    [q.w, q.x, q.y, q.z]
}
fn solar_component_number(name) {
    let fields = ["frameWidthM", "frameThicknessM", "frameDepthM",
        "lowerClearanceWidthFraction", "lowerClearanceDepthFraction",
        "lowerClearanceCenterXFraction",
        "cellWidthM", "cellThicknessM", "cellDepthM", "cellOffsetYM",
        "arrayBackplaneThicknessM", "arrayBackplaneCenterYM",
        "gridColumnCount", "gridRowCount", "dividerXWidthM",
        "dividerXThicknessM", "dividerZWidthM", "dividerZThicknessM",
        "mountBracketWidthM", "mountBracketThicknessM", "mountBracketDepthM",
        "hingeBarRadiusM", "hingeBarLengthM", "hingeBarCenterYM",
        "hingeBarCenterZM", "mountLinkHeightM", "mountLinkDepthM",
        "mountLinkCenterYM", "mountLinkCenterZM", "minimumMountOverlapM", "orientationTolerance"];
    if !fields.contains(name) { return (); }
    _typed_model_number("GriffinSolarRequirements::GriffinSolarArrayAssembly::" + name)
}
fn solar_component_child_names() {
    _typed_model_text_list("GriffinSolarRequirements::GriffinSolarArrayAssembly::childNames")
}
fn main_engine_component_child_names() {
    _typed_model_text_list("GriffinPropulsionRequirements::GriffinMainPropulsionAssembly::childNames")
}
fn engine_skirt_component_root_name() {
    _typed_model_value("GriffinPropulsionRequirements::GriffinEngineSkirtComponent::componentRootName")
}
fn engine_skirt_component_member_names() {
    _typed_model_text_list("GriffinPropulsionRequirements::GriffinEngineSkirtComponent::componentMemberNames")
}
fn engine_skirt_component_shell_name() {
    _typed_model_value("GriffinPropulsionRequirements::GriffinEngineSkirtComponent::shellName")
}
fn engine_skirt_component_adapter_name() {
    _typed_model_value("GriffinPropulsionRequirements::GriffinEngineSkirtComponent::adapterPlateName")
}
fn solar_mount_rail_names() { _sysml_enum_names("solarMountRails") }
fn solar_panel_frame_width_m() { solar_component_number("frameWidthM") }
fn component_solar_array_widths_m() {
    let count = solar_array_count();
    let mounts = solar_mount_rail_names();
    let rail_names = _sysml_enum_names("frameRails");
    let rail_stations = _sysml_native_list("railStations");
    let clearance = _sysml_attribute("solarArrayEdgeClearanceM");
    if count <= 0 || mounts.len() != count * 2 || rail_names.len() != rail_stations.len()
        || clearance == () || clearance < 0.0 {
        return [];
    }
    let widths = [];
    for index in 0..count {
        let endpoints = [];
        for endpoint in 0..2 {
            let target = mounts[index * 2 + endpoint];
            let found = false;
            for rail_index in 0..rail_names.len() {
                if rail_names[rail_index] == target {
                    endpoints.push(rail_stations[rail_index]);
                    found = true;
                    break;
                }
            }
            if !found { return []; }
        }
        let dx = endpoints[1].x - endpoints[0].x;
        let dz = endpoints[1].z - endpoints[0].z;
        let width = min(sqrt(dx * dx + dz * dz) - clearance, solar_panel_frame_width_m());
        if width <= 0.0 { return []; }
        widths.push(width);
    }
    widths
}
// Keep metric cell pitch across fitted faces. The nominal 14x5 module is
// observed in the 2021 concept image; narrower-face counts are estimates.
fn solar_installed_cell_layout(index) {
    let widths=component_solar_array_widths_m();
    let frame=solar_panel_frame_width_m();
    let cells=solar_component_number("cellWidthM");
    let columns=solar_component_number("gridColumnCount");
    if index<0 || index>=widths.len() || frame==() || cells==() || columns==()
        || cells<=0.0 || frame<=cells || columns<2.0 {return ();}
    let pitch=cells/columns;
    let available=widths[index]-(frame-cells);
    let count=min(columns,(available/pitch).floor()).to_int();
    if count<2 {return ();}
    let scale=widths[index]/frame;
    #{columns:count,pitch_m:pitch,scale_x:scale,local_cell_width_m:count*pitch/scale}
}
// Filter the nominal module topology for the fitted panel's cell count.
fn solar_installed_visible_members(index, members) {
    let layout=solar_installed_cell_layout(index);
    if layout==() {throw("solar installed cell layout unavailable");}
    let hidden=[];
    for column in layout.columns..solar_component_number("gridColumnCount").to_int() {
        hidden.push("CellDividerX"+column.to_string());
    }
    let visible=[];
    for member in members {if !hidden.contains(member) {visible.push(member);}}
    visible
}
fn component_engine_stations() { _sysml_native_list("engineStations") }
fn visual_ramp_mount_x() { [
    _sysml_attribute("rampPortMountX"),
    _sysml_attribute("rampStarboardMountX")
] }
fn visual_ramp_mount_y() { _sysml_attribute("rampMountY") }
fn visual_ramp_mount_z() { _sysml_attribute("rampMountZ") }
fn visual_ramp_stowed_scale() { _sysml_attribute("rampStowedScale") }
fn visual_ramp_state() { _sysml_native("rampState") }
fn visual_ramp_child_names() { _sysml_enum_names("sectionInstances") }
fn visual_ramp_stowed_rotation(side) {
    if side == "port" {
        [0.0, 0.0, _sysml_attribute("rampStowedRotationZDeg")]
    } else {
        [0.0, _sysml_attribute("rampStowedStarboardRotationYDeg"),
            _sysml_attribute("rampStowedRotationZDeg")]
    }
}
fn visual_body_profile() { _sysml_native("bodyProfile") }
fn visual_outer_body_profile_coordinates() { _sysml_native_list("outerBodyProfileCoordinates") }
fn visual_body_dimensions() { _sysml_native("bodyDimensions") }
fn visual_body_mount() { _sysml_native("bodyMount") }
fn visual_body_width_m() { _dimensions_component("bodyDimensions", "x") }
fn visual_body_depth_m() { _dimensions_component("bodyDimensions", "z") }
fn visual_body_height_m() { _dimensions_component("bodyDimensions", "y") }
fn visual_deck_width_m() { _dimensions_component("deckDimensions", "x") }
fn visual_deck_depth_m() { _dimensions_component("deckDimensions", "z") }
fn visual_deck_thickness_m() { _dimensions_component("deckDimensions", "y") }
fn visual_deck_center_y_m() { _sysml_native("deckCenter").y }
fn visual_payload_adapter_width_m() { _dimensions_component("payloadAdapterDimensions", "x") }
fn visual_payload_adapter_depth_m() { _dimensions_component("payloadAdapterDimensions", "z") }
fn visual_payload_adapter_thickness_m() { _dimensions_component("payloadAdapterDimensions", "y") }
fn visual_payload_adapter_center_y_m() { _sysml_attribute("payloadAdapterCenterYM") }
fn visual_avionics_deck_width_m() { _dimensions_component("avionicsDeckDimensions", "x") }
fn visual_avionics_deck_depth_m() { _dimensions_component("avionicsDeckDimensions", "z") }
fn visual_avionics_deck_thickness_m() { _dimensions_component("avionicsDeckDimensions", "y") }
fn visual_avionics_deck_center_y_m() { _sysml_native("avionicsDeckCenter").y }
fn visual_lower_skirt_width_m() { _dimensions_component("lowerSkirtDimensions", "x") }
fn visual_lower_skirt_depth_m() { _dimensions_component("lowerSkirtDimensions", "z") }
fn visual_lower_skirt_height_m() { _dimensions_component("lowerSkirtDimensions", "y") }
fn visual_lower_skirt_center_y_m() { _sysml_native("lowerSkirtCenter").y }
fn visual_rail_names() { _sysml_enum_names("frameRails") }
fn visual_rail_count() { visual_rail_names().len() }
fn visual_rail_station_positions() { _sysml_native_list("railStations") }
fn visual_rail_station_x() { _position_axis("railStations", "x") }
fn visual_rail_station_y() { _position_axis("railStations", "y") }
fn visual_rail_station_z() { _position_axis("railStations", "z") }
fn visual_rail_width_m() { _dimensions_component("railDimensions", "x") }
fn visual_rail_length_m() { _dimensions_component("railDimensions", "y") }
fn visual_rail_depth_m() { _dimensions_component("railDimensions", "z") }
fn visual_frame_ring_center_y_m() { _sysml_number_list("frameRingCenterY") }
fn visual_frame_ring_section_m() { _sysml_attribute("frameRingSectionM") }
fn visual_frame_display_color() { _sysml_number_list("frameDisplayColor") }
fn visual_deck_display_color() { _sysml_number_list("deckDisplayColor") }
fn visual_lower_skirt_display_color() { _sysml_number_list("lowerSkirtDisplayColor") }
fn visual_avionics_deck_display_color() { _sysml_number_list("avionicsDeckDisplayColor") }
fn visual_avionics_pod_display_color() { _sysml_number_list("avionicsPodDisplayColor") }
fn visual_rail_display_color() { _sysml_number_list("railDisplayColor") }
fn visual_tank_support_display_color() { _sysml_number_list("tankSupportDisplayColor") }
fn visual_tank_collar_display_color() { _sysml_number_list("tankCollarDisplayColor") }
fn visual_tank_support_perimeter_radius_m() { _sysml_attribute("tankSupportPerimeterRadiusM") }
fn visual_tank_support_perimeter_section_m() { _sysml_attribute("tankSupportPerimeterSectionM") }
fn visual_tank_support_planes_m() { _sysml_number_list("tankSupportPlanes") }
fn visual_tank_support_plane_center_y_m() {
    let planes = visual_tank_support_planes_m();
    if planes.len() == 3 { planes[1] } else { () }
}
fn visual_tank_opening_inner_radius_m() { _sysml_attribute("tankSupportOpeningInnerRadiusM") }
fn visual_tank_opening_outer_radius_m() { _sysml_attribute("tankSupportOpeningOuterRadiusM") }
fn visual_tank_opening_segments() { _sysml_integer("tankSupportOpeningSegments") }
fn legacy_bus_prim_names() {
    ["BoxyAirframe", "LowerServiceSkirtBox", "IsogridDeck", "WhiteEquipmentBox",
     "TopDeck", "LowerServiceSkirt", "TopDeckHex", "LowerServiceSkirtHex",
     "HexPanelFrontRight", "HexPanelRightRear", "HexPanelRearRight",
     "HexPanelRearLeft", "HexPanelLeftFront", "HexPanelFrontLeft",
     "FrameRailFront", "FrameRailRear"]
}


// Structured, native geometry plan consumed by the visual builder.  The
// source attributes remain SysML-owned. Typed Position collections are used
// directly here; no XYZ CSV or parallel coordinate arrays cross this seam.
fn _visual_pose_record(name, parent_role, asset, pose, scale_enabled) {
    #{name: name, parent_role: parent_role, asset: asset,
      pose: pose, scale_enabled: scale_enabled,
      translation: pose.translation, rotation: pose.rotation, scale: pose.scale}
}

fn _visual_transform_record(name, parent_role, asset, x, y, z, rx, ry, rz, uniform_scale) {
    let scale_enabled = uniform_scale != ();
    let scale = if scale_enabled {
        vec3(uniform_scale, uniform_scale, uniform_scale)
    } else {
        vec3(1.0, 1.0, 1.0)
    };
    let pose = transform(vec3(x, y, z),
        quat_from_euler_xyz_deg(vec3(rx, ry, rz)), scale);
    _visual_pose_record(name, parent_role, asset, pose, scale_enabled)
}

fn visual_engine_skirt_mount_y() { _sysml_attribute("engineClusterMountYM") }
fn visual_review_griffin_station() { _sysml_native("visualReviewGriffinStation") }
fn visual_review_flip_station() { _sysml_native("visualReviewFlipStation") }

fn _visual_plan_lengths_match(values, expected) {
    values != () && values.len() == expected
}

fn _native_positions_match(values, expected) {
    if values == () || values.len() != expected { return false; }
    for position in values {
        if !vec3_is_native(position) || !vec3_is_finite(position) { return false; }
    }
    true
}

fn visual_component_transform_plan() {
    let tank_stations = component_tank_stations();
    let tank_rot_y = component_tank_station_rotation_y_deg();
    let tank_scale = component_tank_scale();
    let leg_stations = component_leg_stations();
    let leg_rot_y = component_leg_station_rotation_y_deg();
    let solar_stations = component_solar_stations();
    let solar_rot_x = component_solar_station_rotation_x_deg();
    let solar_rot_z = component_solar_station_rotation_z_deg();
    let engine_stations = component_engine_stations();
    let ramp_x = visual_ramp_mount_x();
    let ramp_y = visual_ramp_mount_y();
    let ramp_z = visual_ramp_mount_z();
    let ramp_scale = visual_ramp_stowed_scale();
    let wheel_names = rover_wheel_station_names();
    let wheel_x = rover_wheel_station_x();
    let wheel_y = rover_wheel_station_y();
    let wheel_z = rover_wheel_station_z();
    let tank_names = propellant_tank_names();
    let leg_names = landing_leg_names();
    let solar_names = solar_array_names();
    let engine_names = main_engine_names();

    let bad_tanks = !_native_positions_match(tank_stations, 4)
        || !_visual_plan_lengths_match(tank_rot_y, 4)
        || !_visual_plan_lengths_match(tank_scale, 4) || tank_names.len() != 4;
    let bad_legs = !_native_positions_match(leg_stations, 4)
        || !_visual_plan_lengths_match(leg_rot_y, 4) || leg_names.len() != 4;
    let solar_count = solar_array_count();
    let solar_widths = component_solar_array_widths_m();
    let bad_solar = solar_count <= 0
        || !_native_positions_match(solar_stations, solar_count)
        || !_visual_plan_lengths_match(solar_rot_x, solar_count)
        || !_visual_plan_lengths_match(solar_rot_z, solar_count)
        || solar_names.len() != solar_count || solar_widths.len() != solar_count;
    let engine_skirt_y = visual_engine_skirt_mount_y();
    let bad_engines = !_native_positions_match(engine_stations, 7) || engine_names.len() != 7
        || engine_skirt_y == ();
    let bad_ramps = ramp_x.len() != 2 || ramp_y == () || ramp_z == () || ramp_scale == ();
    let bad_rover = wheel_names.len() != 4 || !_visual_plan_lengths_match(wheel_x, 4)
        || !_visual_plan_lengths_match(wheel_y, 4) || !_visual_plan_lengths_match(wheel_z, 4);
    let bus_mount = component_bus_mount();
    let bad_core = bus_mount == () || !vec3_is_native(bus_mount);
    if bad_core || bad_tanks || bad_legs || bad_solar || bad_engines || bad_ramps || bad_rover {
        return [];
    }

    let plan = [];
    plan.push(_visual_pose_record("Bus", "lander", "lander/griffin_bus_visual.usda",
        transform(bus_mount, quat_identity(), vec3(1.0, 1.0, 1.0)), false));
    for index in 0..tank_names.len() {
        let scale = vec3(tank_scale[index], tank_scale[index], tank_scale[index]);
        let pose = transform(tank_stations[index],
            quat_from_euler_xyz_deg(vec3(0.0, tank_rot_y[index], 0.0)), scale);
        plan.push(_visual_pose_record(tank_names[index], "lander",
            "lander/griffin_tank_visual.usda", pose, true));
    }
    for index in 0..leg_names.len() {
        let pose = transform(leg_stations[index],
            quat_from_euler_xyz_deg(vec3(0.0, leg_rot_y[index], 0.0)),
            vec3(1.0, 1.0, 1.0));
        plan.push(_visual_pose_record(leg_names[index], "lander",
            "lander/griffin_landing_leg_visual.usda", pose, false));
    }
    for index in 0..solar_names.len() {
        let scale = vec3(solar_widths[index] / solar_panel_frame_width_m(), 1.0, 1.0);
        let pose = transform(solar_stations[index],
            component_solar_orientation(index),
            scale);
        plan.push(_visual_pose_record(solar_names[index], "lander",
            "lander/griffin_solar_panel_visual.usda", pose, false));
    }
    plan.push(_visual_transform_record("EgressRampPort", "lander",
        "lander/griffin_ramp_visual.usda", ramp_x[0], ramp_y, ramp_z, 0.0, 0.0, 0.0,
        ramp_scale));
    plan.push(_visual_transform_record("EgressRampStarboard", "lander",
        "lander/griffin_ramp_visual.usda", ramp_x[1], ramp_y, ramp_z, 0.0, 180.0, 0.0,
        ramp_scale));

    for index in 0..engine_names.len() {
        let pose = transform(engine_stations[index], quat_identity(), vec3(1.0, 1.0, 1.0));
        let record = _visual_pose_record(engine_names[index], "engine_cluster",
            "lander/griffin_engine_bell_visual.usda", pose, false);
        plan.push(record);
    }
    plan.push(_visual_transform_record("EngineSkirt", "engine_cluster",
        "lander/griffin_engine_skirt_visual.usda", 0.0, engine_skirt_y, 0.0,
        0.0, 0.0, 0.0, ()));
    plan
}

// Detail rails use the same native station representation as replaceable
// component instances.  Their render primitive is chosen by the builder, but
// their identity, datum, and metric envelope remain source-backed here.
fn visual_rail_station_plan() {
    let names = visual_rail_names();
    let stations = visual_rail_station_positions();
    let dimensions = _sysml_native("railDimensions");
    if names.len() == 0 || !_native_positions_match(stations, names.len())
        || dimensions == () || !vec3_is_native(dimensions) {
        return [];
    }
    let result = [];
    for index in 0..names.len() {
        let pose = transform(stations[index], quat_identity(), dimensions);
        result.push(_visual_pose_record(names[index], "lander", "", pose, true));
    }
    result
}
fn rover_wheel_station_x() { _sysml_number_list("wheelStationX") }
fn rover_wheel_station_y() { _sysml_number_list("wheelStationY") }
fn rover_wheel_station_z() { _sysml_number_list("wheelStationZ") }
fn physical_ramp_deck_transition_length_m() { _sysml_attribute("physicalRampDeckTransitionLengthM") }
fn physical_ramp_deck_transition_required_overlap_m() {
    _sysml_attribute("physicalRampDeckTransitionRequiredOverlapM")
}
fn physical_ramp_deck_transition_interface_tolerance_m() {
    _sysml_attribute("physicalRampDeckTransitionInterfaceToleranceM")
}
fn physical_ramp_transition_child_name() { _sysml_enum_name("transitionBody") }
fn physical_ramp_transition_body_name(side) {
    let base = physical_ramp_transition_child_name();
    let suffix = if side == "port" { "Port" }
        else if side == "starboard" { "Starboard" } else { return (); };
    if base == () || base == "" { return (); }
    base + suffix
}
fn physical_ramp_transition_contact_child_name() {
    _sysml_enum_name("transitionContact")
}
fn physical_ramp_deck_transition_mass_kg() { _sysml_attribute("physicalRampDeckTransitionMassKg") }
fn physical_ramp_deck_transition_inertia_kg_m2() {
    _sysml_number_list("physicalRampDeckTransitionInertiaKgM2")
}
fn physical_ramp_transition_joint_name(side) {
    let names = ramp_transition_joint_names();
    let index = if side == "port" { 0 } else if side == "starboard" { 1 } else { -1 };
    if index < 0 || names.len() != 2 { return (); }
    names[index]
}
fn physical_ramp_port_deployment_angle_rad() { _sysml_attribute("physicalRampPortDeploymentAngleRad") }
fn physical_ramp_terrain_contact_tolerance_m() { _sysml_attribute("physicalRampTerrainContactToleranceM") }
fn ramp_surface_thickness_m() { _sysml_attribute("rampSurfaceThicknessM") }
fn physical_ramp_starboard_deployment_angle_rad() { _sysml_attribute("physicalRampStarboardDeploymentAngleRad") }
fn physical_ramp_port_root_stowed_angle_rad() { _sysml_attribute("physicalRampRootStowedAngleRad") }
fn physical_ramp_starboard_root_stowed_angle_rad() { _sysml_attribute("physicalRampRootStowedAngleRad") }
fn physical_ramp_port_root_stow_limit_rad() { _sysml_attribute("physicalRampPortRootJointStowLimitRad") }
fn physical_ramp_starboard_root_stow_limit_rad() { _sysml_attribute("physicalRampStarboardRootJointStowLimitRad") }
fn physical_ramp_section_stowed_relative_angle_rad() {
    _sysml_attribute("physicalRampSectionStowedRelativeAngleRad")
}
fn physical_ramp_section_deployment_relative_angle_rad() {
    _sysml_attribute("physicalRampSectionDeploymentRelativeAngleRad")
}
fn physical_ramp_section_joint_frame_offset_rad() {
    _sysml_attribute("physicalRampSectionJointFrameOffsetRad")
}
fn physical_ramp_section_joint_coordinate_angle(relative_angle_rad) {
    let offset = physical_ramp_section_joint_frame_offset_rad();
    if relative_angle_rad == () || offset == ()
        || !relative_angle_rad.is_finite() || !offset.is_finite() {
        return ();
    }
    relative_angle_rad + offset
}
fn physical_ramp_section_stowed_joint_angle_rad() {
    physical_ramp_section_joint_coordinate_angle(
        physical_ramp_section_stowed_relative_angle_rad())
}
fn physical_ramp_hinge_settle_angle_tolerance_rad() {
    _sysml_attribute("physicalRampHingeSettleAngleToleranceRad")
}
fn physical_ramp_hinge_settle_speed_tolerance_rad_per_s() {
    _sysml_attribute("physicalRampHingeSettleSpeedToleranceRadPerS")
}
fn physical_ramp_traversal_settle_dwell_s() {
    _sysml_attribute("physicalRampTraversalSettleDwellS")
}
fn physical_ramp_section_unfold_waypoint_joint_angle_rad() {
    physical_ramp_section_joint_coordinate_angle(
        _sysml_attribute("physicalRampSectionUnfoldWaypointRelativeAngleRad"))
}
fn physical_ramp_section_deployment_joint_angle_rad() {
    physical_ramp_section_joint_coordinate_angle(
        physical_ramp_section_deployment_relative_angle_rad())
}
fn suspension_strut_scale() { _sysml_number_list("suspensionStrutScale") }
fn suspension_strut_offset() { _sysml_number_list("suspensionStrutOffset") }
fn suspension_arm_scale() { _sysml_number_list("suspensionArmScale") }
fn suspension_arm_offset_m() { _sysml_attribute("suspensionArmOffsetM") }
fn suspension_knuckle_radius_m() { _sysml_attribute("suspensionKnuckleRadiusM") }
fn suspension_knuckle_width_m() { _sysml_attribute("suspensionKnuckleWidthM") }
fn visual_review_ground_width_m() { _sysml_attribute("visualReviewGroundWidthM") }

// GV-006 links each visual asset as a typed EvidenceSource with an enum role.
// Resolve the source through the same revision-scoped requirement/evidence API
// used by generic verifiers; the URI remains only the locator leaf.
fn _visual_asset_locator(role_literal) {
    let report = sysml_requirements::source_with_selection([],
        ["GriffinVisualRequirements::gv006"],
        ["GriffinVisualRequirements::Verify_GriffinVisualRequirements"]);
    if report == () || report.ok != true { return (); }
    let requirement = sysml_requirements::requirement_handle_by_short_name(report, "GV-006");
    if requirement.ok != true { return (); }
    let evidence = sysml_requirements::provenance(report, requirement.handle);
    if evidence.ok != true { return (); }
    for source in evidence.evidence.sources {
        if source.role.type == "GriffinRequirementSources::EvidenceSourceRole"
            && source.role.literal == role_literal
            && source.locator_type == "GriffinRequirementSources::SourceLocator" {
            return source.locator;
        }
    }
    ()
}

fn visual_terrain_asset() { _visual_asset_locator("VisualAsset") }
fn visual_terrain_shader_asset() { _visual_asset_locator("ShaderAsset") }
fn pi_value() { 3.141592653589793 }

fn frame() {
    #{ units: _sysml_text("lengthUnit"), up_axis: _sysml_text("frameUpAxis"),
       root_datum: _sysml_text("reviewLanderName") }
}

fn solar_array_names() { _sysml_enum_names("solarArrayInstances") }
fn landing_leg_names() { _sysml_enum_names("landingLegInstances") }
fn ramp_names() { _sysml_list("rampInstances") }
fn ramp_hinge_names() { _sysml_list("rampHingeInstances") }
fn ramp_tread_count() { _sysml_integer("assemblyTreadCount") }
fn ramp_tread_width_m() { _sysml_attribute("assemblyTreadWidthM") }
fn ramp_tread_height_m() { _sysml_attribute("assemblyTreadHeightM") }
fn ramp_contact_track_width_m() { _sysml_attribute("assemblyTrackWidthM") }
fn ramp_tread_first_center_x_m() { _sysml_attribute("assemblyTreadFirstCenterXM") }
fn ramp_tread_pitch_m() { _sysml_attribute("assemblyTreadPitchM") }
fn ramp_under_beam_width_m() { _sysml_attribute("assemblyUnderBeamWidthM") }
fn ramp_under_beam_height_m() { _sysml_attribute("assemblyUnderBeamHeightM") }
fn ramp_under_beam_center_y_m() { _sysml_attribute("assemblyUnderBeamCenterYM") }
fn ramp_under_beam_center_offset_z_m() { _sysml_attribute("assemblyUnderBeamCenterOffsetZM") }
fn ramp_section_count() { _sysml_integer("rampSectionCount") }
fn ramp_section_length_m() { _sysml_attribute("rampSectionLengthM") }
fn ramp_section_names() { _sysml_enum_names("sectionInstances") }
fn ramp_root_joint_names() { _sysml_enum_names("rootJointInstances") }
fn ramp_intermediate_joint_names() { _sysml_enum_names("intermediateJointInstances") }
fn ramp_tread_names() { _sysml_enum_names("treadInstances") }
fn ramp_rail_joint_pin_names() { _sysml_enum_names("railJointPinInstances") }
// Stable guide identities pair each inherited rail with its coaxial fitting.
fn ramp_guide_stations() {
    let pins=ramp_rail_joint_pin_names();
    if pins.len()!=4 {throw("ramp guide stations require four sourced pin identities");}
    let outer=_sysml_attribute("rampRailOffsetZM");
    let inner=_sysml_attribute("rampCenterRailOffsetZM");
    [#{name:"OuterRail",side:"Port",pin:pins[0],z:outer},
     #{name:"InnerRail",side:"Starboard",pin:pins[1],z:-outer},
     #{name:"CenterRailPort",side:"PortCenter",pin:pins[2],z:inner},
     #{name:"CenterRailStarboard",side:"StarboardCenter",pin:pins[3],z:-inner}]
}
fn ramp_transition_joint_names() { _sysml_enum_names("transitionJoints") }
fn ramp_tread_count_per_section() { _sysml_integer("assemblyTreadCountPerSection") }
fn ramp_side_post_count_per_section_per_side() { _sysml_integer("assemblySidePostCountPerSectionPerSide") }
fn ramp_side_post_width_m() { _sysml_attribute("assemblySidePostWidthM") }
fn ramp_side_post_depth_m() { _sysml_attribute("assemblySidePostDepthM") }
fn ramp_side_post_embedded_depth_m() { _sysml_attribute("assemblySidePostEmbeddedDepthM") }
fn ramp_side_post_first_center_x_m() { _sysml_attribute("assemblySidePostFirstCenterXM") }
fn ramp_side_post_pitch_m() { _sysml_attribute("assemblySidePostPitchM") }
fn ramp_side_truss_chord_height_m() { _sysml_attribute("assemblySideTrussChordHeightM") }
fn ramp_side_truss_lower_chord_center_y_m() { _sysml_attribute("assemblySideTrussLowerChordCenterYM") }
fn ramp_side_truss_brace_thickness_m() { _sysml_attribute("assemblySideTrussBraceThicknessM") }
fn ramp_side_truss_brace_count_per_side() { _sysml_integer("assemblySideTrussBraceCountPerSide") }
fn ramp_section_hinge_barrel_radius_m() { _sysml_attribute("rampSectionHingeBarrelRadiusM") }
fn ramp_section_hinge_barrel_length_m() { _sysml_attribute("rampSectionHingeBarrelLengthM") }
fn ramp_section_hinge_barrel_center_y_m() { _sysml_attribute("rampSectionHingeBarrelCenterYM") }
fn ramp_section_hinge_axis_y_m(index) {
    if index==0 {return ramp_section_hinge_barrel_center_y_m();}
    if index==1 {return _sysml_attribute("rampRailCenterYM")+_sysml_attribute("rampRailHeightM")/2.0;}
    if index==2 {return -_sysml_attribute("rampSurfaceThicknessM")/2.0;}
    throw("ramp section index is outside the three-section assembly");
}
fn ramp_rail_joint_pin_radius_m() { _sysml_attribute("rampRailJointPinRadiusM") }
fn ramp_rail_joint_pin_length_m() { _sysml_attribute("rampRailJointPinLengthM") }
fn propellant_tank_names() { _sysml_enum_names("tankInstances") }
fn main_engine_names() { _sysml_enum_names("mainEngineInstances") }

fn lander_camera_focus_height_m() {
    let dimensions=_sysml_model_value("payloadAdapterDimensions");
    if dimensions==() {throw("payload adapter dimensions unavailable");}
    visual_payload_adapter_center_y_m() + dimensions.y / 2.0
}
