import "lunco://scripting/tools/sysml_requirements" as sysml_requirements;

// Machine-readable Griffin study policy.
//
// Keep this module free of USD queries and edits. Numeric policy is read from
// the co-located standard SysML source through the compact ValidateSysml query;
// Rhai still owns the executable test policy while contracts/*.md records
// meaning and provenance.

// Keep repeated Griffin lookups on one Rust-owned, revision-pinned SysML
// session. The qualified name is an identifier boundary; the engineering
// value itself remains a native Rust/Rhai value.
fn _sysml_model() {
    sysml_requirements::model()
}

fn _sysml_model_value(name) {
    let model = _sysml_model();
    if model == () || !sysml_model_is(model) { return (); }
    let value = model.value(_qualified_attribute(name));
    if value == () { return (); }
    value
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
        "childNames",
        "assemblyChildNames",
        "rampWheelClearanceM", "rampSurfaceThicknessM", "rampRailHeightM",
        "rampRailWidthM", "rampRailOffsetZM", "rampSurfaceCenterYM", "rampRailCenterYM",
        "rampMaxDeploymentAngleRad",
        "rampPortMountX", "rampStarboardMountX", "rampMountY", "rampMountZ",
        "rampHingeOffsetX", "rampHingeOffsetY", "rampHingeOffsetZ",
        "supportArmCenterXM", "supportArmCenterYM", "supportArmHalfWidthM",
        "supportArmHalfHeightM", "supportArmHalfDepthM", "supportArmPairOffsetZM",
        "supportArmTiltZDeg", "assemblyTreadNamePrefix", "assemblyTreadCount",
        "assemblyTreadWidthM", "assemblyTreadHeightM", "assemblyTreadSpanM",
        "assemblyTreadFirstCenterXM", "assemblyTreadPitchM",
        "assemblyUnderBeamWidthM", "assemblyUnderBeamHeightM",
        "assemblyUnderBeamCenterYM", "assemblyUnderBeamCenterOffsetZM",
        "assemblySidePostCountPerSide", "assemblySidePostWidthM",
        "assemblySidePostHeightM", "assemblySidePostDepthM",
        "assemblySidePostCenterYM", "assemblySidePostFirstCenterXM",
        "assemblySidePostPitchM", "assemblyHingeCollarRadiusM",
        "assemblyHingeCollarLengthM", "assemblyHingeCollarOffsetZM",
        "assemblyHingeGussetWidthM", "assemblyHingeGussetHeightM",
        "assemblyHingeGussetDepthM", "assemblyHingeGussetCenterXM",
        "assemblyHingeGussetCenterYM", "assemblyHingeGussetOffsetZM",
        "rampSocketX", "rampSocketY", "rampSocketZ",
        "rampPortDeploymentAngleRad", "rampStarboardDeploymentAngleRad",
        "rampBehavior", "hingeAxis", "mountDatum", "rampStowedScale",
        "rampStowedPortRotationZDeg", "rampStowedStarboardRotationYDeg",
        "rampStowedStarboardRotationZDeg", "rampGeometryStatus",
        "physicalRampSurfaceLengthM", "physicalRampSurfaceWidthM",
        "physicalRampSurfaceThicknessM", "physicalRampRailHeightM",
        "physicalRampRailWidthM", "physicalRampSurfaceCenterYM",
        "physicalRampRailCenterYM", "physicalRampDeckEdgeXM",
        "physicalRampDeckToHingeClearanceM", "physicalRampDeckTransitionOverlapM",
        "physicalRampTransitionChildName", "physicalRampTransitionContactChildName",
        "physicalRampPortMountX",
        "physicalRampStarboardMountX", "physicalRampMountY",
        "physicalRampMountZ", "physicalRampPortDeploymentAngleRad",
        "physicalRampStarboardDeploymentAngleRad", "physicalRampRouteClearanceM",
        "physicalRampStowedSurfaceCenterXM", "physicalRampStowedSurfaceCenterYM",
        "physicalRampStowedRailCenterYM", "physicalRampStowedAngleRad",
        "physicalRampHingeLimitDeg", "physicalRampDeckTransitionMassKg",
        "physicalRampDeckTransitionInertiaKgM2", "physicalRampTransitionJointNamePrefix",
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
        "rearSteeringAngleDeg", "missionSteeringMode", "chassisWidthM", "chassisLengthM",
        "sensorMastHeightM", "wheelStationX", "wheelStationY",
        "wheelStationZ", "physicalWheelStationX", "physicalWheelStationY",
        "physicalWheelStationZ", "physicalSuspensionRestLengthM",
        "solarArrayMount", "solarArrayTiltDeg",
        "suspensionStrutScale", "suspensionStrutOffset",
        "suspensionArmScale", "suspensionArmOffsetM",
        "suspensionKnuckleRadiusM", "suspensionKnuckleWidthM",
        "componentReference", "missionReference"
    ];
    if rover.contains(name) {
        return "FlipRequirements::FlipRover::" + name;
    }
    let sensor_power = ["mastMountCenterYM", "mastMountCenterZM"];
    if sensor_power.contains(name) {
        return "FlipSensorPowerRequirements::FlipSensorPowerAssembly::" + name;
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
        "componentName"
    ];
    if lander_component.contains(name) {
        return "GriffinLanderRequirements::GriffinLanderComponent::" + name;
    }
    let visual_configuration = [
        "configuration", "bodyProfile", "rampState", "origin", "axisUp", "axisPort", "axisForward",
        "verificationToleranceM", "visualReviewGriffinStation", "visualReviewFlipStation",
        "bodyDimensions", "bodyMount", "bodyGroundClearanceM",
        "lowerSkirtDimensions", "lowerSkirtCenter", "deckDimensions", "deckCenter",
        "avionicsDeckDimensions", "avionicsDeckCenter", "outerBodyProfileCoordinates",
        "frameDisplayColor", "deckDisplayColor", "lowerSkirtDisplayColor",
        "avionicsDeckDisplayColor", "avionicsPodDisplayColor", "railDisplayColor",
        "tankSupportDisplayColor", "tankCollarDisplayColor",
        "frameRingCenterY", "frameRingSectionM",
        "frameRails", "tankInstances", "landingLegInstances", "solarArrayInstances",
        "mainEngineInstances", "railStations", "railDimensions",
        "tankSupportPerimeterRadiusM",
        "tankSupportPerimeterSectionM", "tankSupportPlaneCenterYM",
        "tankSupportOpeningInnerRadiusM", "tankSupportOpeningOuterRadiusM",
        "tankSupportOpeningSegments", "legStations",
        "legStationRotationYDeg", "solarStations", "solarStationRotationXDeg", "solarStationRotationZDeg",
        "solarArrayWidthM", "solarArrayDepthM", "solarStandoffM", "tankStations",
        "tankStationRotationYDeg", "tankScale",
        "engineClusterMountYM", "engineBellDirection", "engineStations"
    ];
    if visual_configuration.contains(name) {
        return "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::" + name;
    }
    let landing_stability = [
        "landingStabilityHorizonS", "landingMinimumUprightAxisY",
        "landingMaxGroundSpeedMps", "landingMaxAngularSpeedRadPerSec",
        "landingMaxHorizontalDriftM"
    ];
    if landing_stability.contains(name) {
        return "GriffinSimulationAccuracyRequirements::GR036_LandingStability::" + name;
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
    let items = sysml_requirements::string_vector(source, qualified);
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

fn _sysml_native_list(name) {
    let value = _sysml_native(name);
    if value == () || !array_is(value) { return []; }
    value
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
fn landing_com_touchdown_y() { _sysml_attribute("landingComTouchdownY") }
fn landing_stability_horizon_s() { _sysml_attribute("landingStabilityHorizonS") }
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
// while speed and arrival tolerance cross the SysML/Rhai bridge as typed lists.
fn surface_route_speed_mps() { _sysml_number_list("surfaceRouteSpeedMps") }
fn surface_route_arrival_radius_m() { _sysml_number_list("surfaceRouteArrivalRadiusM") }
fn egress_apron_name() { _sysml_text("egressApronName") }
fn egress_apron_requirement_id() { _sysml_text("egressApronRequirementId") }
fn egress_apron_center_x_m() { _sysml_attribute("egressApronCenterX") }
fn egress_apron_center_y_m() { _sysml_attribute("egressApronCenterY") }
fn egress_apron_center_z_m() { _sysml_attribute("egressApronCenterZ") }
fn egress_apron_length_m() { _sysml_attribute("egressApronLengthM") }
fn egress_apron_width_m() { _sysml_attribute("egressApronWidthM") }
fn egress_apron_thickness_m() { _sysml_attribute("egressApronThicknessM") }
fn egress_apron_surface_y_m() { _sysml_attribute("egressApronSurfaceY") }
fn egress_apron_source() { _sysml_text("egressApronSource") }
fn egress_apron_rationale() { _sysml_text("egressApronRationale") }
fn visual_requirement_usage_count() { _sysml_integer("visualRequirementUsageCount") }
fn visual_verification_case_name() { _sysml_text("visualVerificationCaseName") }
fn visual_camera_name() { _sysml_text("visualCameraName") }
fn visual_lander_name() { _sysml_text("visualLanderName") }
fn visual_rover_name() { _sysml_text("visualRoverName") }
fn visual_lander_deck_width_m() { _sysml_attribute("visualLanderDeckWidthM") }
fn visual_rover_wheel_radius_m() { _sysml_attribute("visualRoverWheelRadiusM") }
fn visual_rover_wheel_count() { _sysml_integer("visualRoverWheelCount") }
fn visual_rover_wheel_names() { _sysml_list("visualWheelNames") }
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
fn component_engine_stations() { _sysml_native_list("engineStations") }
fn rover_front_steering_angle_deg() { _sysml_attribute("frontSteeringAngleDeg") }
fn rover_rear_steering_angle_deg() { _sysml_attribute("rearSteeringAngleDeg") }
fn visual_ramp_mount_x() { [
    _sysml_attribute("rampPortMountX"),
    _sysml_attribute("rampStarboardMountX")
] }
fn visual_ramp_mount_y() { _sysml_attribute("rampMountY") }
fn visual_ramp_mount_z() { _sysml_attribute("rampMountZ") }
fn visual_ramp_stowed_scale() { _sysml_attribute("rampStowedScale") }
fn visual_ramp_state() { _sysml_native("rampState") }
fn visual_ramp_child_names() { _sysml_list("childNames") }
fn visual_ramp_stowed_rotation(side) {
    if side == "port" {
        [0.0, 0.0, _sysml_attribute("rampStowedPortRotationZDeg")]
    } else {
        [0.0, _sysml_attribute("rampStowedStarboardRotationYDeg"),
            _sysml_attribute("rampStowedStarboardRotationZDeg")]
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
fn visual_tank_support_plane_center_y_m() { _sysml_attribute("tankSupportPlaneCenterYM") }
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
    let sensor_mount = rover_sensor_mast_mount();
    let rover_solar_mount = rover_solar_array_mount();
    let rover_solar_tilt = rover_solar_array_tilt_deg();
    let front_steering = rover_front_steering_angle_deg();
    let rear_steering = rover_rear_steering_angle_deg();
    let wheel_names = visual_rover_wheel_names();
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
    let bad_solar = !_native_positions_match(solar_stations, 2)
        || !_visual_plan_lengths_match(solar_rot_x, 2)
        || !_visual_plan_lengths_match(solar_rot_z, 2) || solar_names.len() != 2;
    let engine_skirt_y = visual_engine_skirt_mount_y();
    let bad_engines = !_native_positions_match(engine_stations, 7) || engine_names.len() != 7
        || engine_skirt_y == ();
    let bad_ramps = ramp_x.len() != 2 || ramp_y == () || ramp_z == () || ramp_scale == ();
    let bad_rover = sensor_mount.len() != 2 || rover_solar_mount.len() != 3
        || rover_solar_tilt == () || front_steering == () || rear_steering == ()
        || wheel_names.len() != 4 || !_visual_plan_lengths_match(wheel_x, 4)
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
        let pose = transform(solar_stations[index],
            quat_from_euler_xyz_deg(vec3(solar_rot_x[index], 0.0, solar_rot_z[index])),
            vec3(1.0, 1.0, 1.0));
        plan.push(_visual_pose_record(solar_names[index], "lander",
            "lander/griffin_solar_panel_visual.usda", pose, false));
    }
    plan.push(_visual_transform_record("EgressRampPort", "lander",
        "lander/griffin_ramp_visual.usda", ramp_x[0], ramp_y, ramp_z, 0.0, 0.0, 0.0,
        ramp_scale));
    plan.push(_visual_transform_record("EgressRampStarboard", "lander",
        "lander/griffin_ramp_visual.usda", ramp_x[1], ramp_y, ramp_z, 0.0, 180.0, 0.0,
        ramp_scale));

    plan.push(_visual_transform_record("Chassis", "rover", "rover/flip_chassis_visual.usda",
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ()));
    plan.push(_visual_transform_record("SensorMast", "rover", "rover/flip_sensor_mast_visual.usda",
        0.0, sensor_mount[0], sensor_mount[1], 0.0, 0.0, 0.0, ()));
    plan.push(_visual_transform_record("SolarArray", "rover", "rover/flip_solar_panel_visual.usda",
        rover_solar_mount[0], rover_solar_mount[1], rover_solar_mount[2],
        rover_solar_tilt, 0.0, 0.0, ()));
    for index in 0..wheel_names.len() {
        let steering = if wheel_names[index].starts_with("F") {
            front_steering
        } else {
            rear_steering
        };
        let record = _visual_transform_record("Wheel_" + wheel_names[index], "wheel",
            "rover/flip_wheel_visual.usda", 0.0, 0.0, 0.0, 0.0, steering, 0.0, ());
        record.station = wheel_names[index];
        plan.push(record);
    }
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
fn physical_rover_wheel_station_x() { _sysml_number_list("physicalWheelStationX") }
fn physical_rover_wheel_station_y() { _sysml_number_list("physicalWheelStationY") }
fn physical_rover_wheel_station_z() { _sysml_number_list("physicalWheelStationZ") }
fn physical_suspension_rest_length_m() { _sysml_attribute("physicalSuspensionRestLengthM") }
fn physical_ramp_deck_transition_overlap_m() { _sysml_attribute("physicalRampDeckTransitionOverlapM") }
fn physical_ramp_transition_child_name() { _sysml_text("physicalRampTransitionChildName") }
fn physical_ramp_transition_contact_child_name() {
    _sysml_text("physicalRampTransitionContactChildName")
}
fn physical_ramp_deck_transition_mass_kg() { _sysml_attribute("physicalRampDeckTransitionMassKg") }
fn physical_ramp_deck_transition_inertia_kg_m2() {
    _sysml_number_list("physicalRampDeckTransitionInertiaKgM2")
}
fn physical_ramp_transition_joint_name_prefix() {
    _sysml_text("physicalRampTransitionJointNamePrefix")
}
fn physical_ramp_port_deployment_angle_rad() { _sysml_attribute("physicalRampPortDeploymentAngleRad") }
fn physical_ramp_starboard_deployment_angle_rad() { _sysml_attribute("physicalRampStarboardDeploymentAngleRad") }
fn suspension_strut_scale() { _sysml_number_list("suspensionStrutScale") }
fn suspension_strut_offset() { _sysml_number_list("suspensionStrutOffset") }
fn suspension_arm_scale() { _sysml_number_list("suspensionArmScale") }
fn suspension_arm_offset_m() { _sysml_attribute("suspensionArmOffsetM") }
fn suspension_knuckle_radius_m() { _sysml_attribute("suspensionKnuckleRadiusM") }
fn suspension_knuckle_width_m() { _sysml_attribute("suspensionKnuckleWidthM") }
fn rover_solar_array_mount() { _sysml_number_list("solarArrayMount") }
fn rover_solar_array_tilt_deg() { _sysml_attribute("solarArrayTiltDeg") }
fn rover_sensor_mast_mount() {
    [_sysml_attribute("mastMountCenterYM"), _sysml_attribute("mastMountCenterZM")]
}
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

fn solar_array_names() { _sysml_enum_names("solarArrayInstances") }
fn landing_leg_names() { _sysml_enum_names("landingLegInstances") }
fn landing_pad_names() { _sysml_list("landingPadNames") }
fn ramp_names() { _sysml_list("rampNames") }
fn ramp_hinge_names() { _sysml_list("rampHingeNames") }
fn ramp_tread_name_prefix() { _sysml_text("assemblyTreadNamePrefix") }
fn ramp_tread_count() { _sysml_integer("assemblyTreadCount") }
fn ramp_tread_width_m() { _sysml_attribute("assemblyTreadWidthM") }
fn ramp_tread_height_m() { _sysml_attribute("assemblyTreadHeightM") }
fn ramp_tread_span_m() { _sysml_attribute("assemblyTreadSpanM") }
fn ramp_tread_first_center_x_m() { _sysml_attribute("assemblyTreadFirstCenterXM") }
fn ramp_tread_pitch_m() { _sysml_attribute("assemblyTreadPitchM") }
fn ramp_under_beam_width_m() { _sysml_attribute("assemblyUnderBeamWidthM") }
fn ramp_under_beam_height_m() { _sysml_attribute("assemblyUnderBeamHeightM") }
fn ramp_under_beam_center_y_m() { _sysml_attribute("assemblyUnderBeamCenterYM") }
fn ramp_under_beam_center_offset_z_m() { _sysml_attribute("assemblyUnderBeamCenterOffsetZM") }
fn ramp_side_post_count_per_side() { _sysml_integer("assemblySidePostCountPerSide") }
fn ramp_side_post_width_m() { _sysml_attribute("assemblySidePostWidthM") }
fn ramp_side_post_height_m() { _sysml_attribute("assemblySidePostHeightM") }
fn ramp_side_post_depth_m() { _sysml_attribute("assemblySidePostDepthM") }
fn ramp_side_post_center_y_m() { _sysml_attribute("assemblySidePostCenterYM") }
fn ramp_side_post_first_center_x_m() { _sysml_attribute("assemblySidePostFirstCenterXM") }
fn ramp_side_post_pitch_m() { _sysml_attribute("assemblySidePostPitchM") }
fn ramp_hinge_collar_radius_m() { _sysml_attribute("assemblyHingeCollarRadiusM") }
fn ramp_hinge_collar_length_m() { _sysml_attribute("assemblyHingeCollarLengthM") }
fn ramp_hinge_collar_offset_z_m() { _sysml_attribute("assemblyHingeCollarOffsetZM") }
fn ramp_hinge_gusset_width_m() { _sysml_attribute("assemblyHingeGussetWidthM") }
fn ramp_hinge_gusset_height_m() { _sysml_attribute("assemblyHingeGussetHeightM") }
fn ramp_hinge_gusset_depth_m() { _sysml_attribute("assemblyHingeGussetDepthM") }
fn ramp_hinge_gusset_center_x_m() { _sysml_attribute("assemblyHingeGussetCenterXM") }
fn ramp_hinge_gusset_center_y_m() { _sysml_attribute("assemblyHingeGussetCenterYM") }
fn ramp_hinge_gusset_offset_z_m() { _sysml_attribute("assemblyHingeGussetOffsetZM") }
fn propellant_tank_names() { _sysml_enum_names("tankInstances") }
fn main_engine_names() { _sysml_enum_names("mainEngineInstances") }

fn catalogued_requirement_checks() {
    _sysml_list("cataloguedRequirementCheckIds")
}

fn requirement_usage_count() { _sysml_integer("requirementUsageCount") }
fn manifest_part_count() { _sysml_integer("manifestPartCount") }
fn verification_case_name() { _sysml_text("verificationCaseName") }
fn planned_rules() { _sysml_list("plannedRequirementIds") }
fn mission_scope_rules() { _sysml_list("missionScopeRequirementIds") }
fn process_gate_rules() { _sysml_list("processGateRequirementIds") }
