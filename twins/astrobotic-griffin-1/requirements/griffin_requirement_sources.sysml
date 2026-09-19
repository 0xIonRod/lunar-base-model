package GriffinRequirementSources {
    private import ScalarValues::String;

    /*
     * Provenance is a separate standard-SysML catalog. Requirement
     * definitions stay lean; each typed part usage below carries only
     * requirementId, qualifiedRequirement, sourceReference, and rationale.
     * The compact ValidateSysml projection can select these qualified values
     * without shipping the complete Twin collision table. Normative text stays
     * in the owning requirement definition, and verification membership stays
     * in the owning verification definition and Twin manifest.
     */
    part def RequirementEvidence {
        attribute requirementId : String;
        attribute qualifiedRequirement : String;
        attribute sourceReference : String;
        attribute rationale : String;
    }

    part evidence_fcc_001 : RequirementEvidence {
        attribute requirementId = "FCC-001";
        attribute qualifiedRequirement = "FlipChassisRequirements::FCC001_ChassisIdentity";
        attribute sourceReference = "https://www.astrolab.space/flip/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_fcc_002 : RequirementEvidence {
        attribute requirementId = "FCC-002";
        attribute qualifiedRequirement = "FlipChassisRequirements::FCC002_ChassisEnvelope";
        attribute sourceReference = "https://www.astrolab.space/flip/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_fcc_003 : RequirementEvidence {
        attribute requirementId = "FCC-003";
        attribute qualifiedRequirement = "FlipChassisRequirements::FCC003_ChassisOwnership";
        attribute sourceReference = "https://www.astrolab.space/flip/";
        attribute rationale = "Prevents duplicate dynamics by keeping render and physics ownership explicit.";
    }

    part evidence_fcc_004 : RequirementEvidence {
        attribute requirementId = "FCC-004";
        attribute qualifiedRequirement = "FlipChassisRequirements::FCC004_ChassisTraceability";
        attribute sourceReference = "https://www.astrolab.space/flip/";
        attribute rationale = "Makes count, identity, and provenance inspectable and replaceable.";
    }

    part evidence_fcc_005 : RequirementEvidence {
        attribute requirementId = "FCC-005";
        attribute qualifiedRequirement = "FlipChassisRequirements::FCC005_ChassisEnvelope";
        attribute sourceReference = "https://www.astrolab.space/flip/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_fgv_001 : RequirementEvidence {
        attribute requirementId = "FGV-001";
        attribute qualifiedRequirement = "FlipRequirements::FLIPV001_RoverPresentation";
        attribute sourceReference = "https://www.astrolab.space/flip/; https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_fgv_002 : RequirementEvidence {
        attribute requirementId = "FGV-002";
        attribute qualifiedRequirement = "FlipRequirements::FLIPV002_ChassisEnvelope";
        attribute sourceReference = "https://www.astrolab.space/flip/; https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_fgv_003 : RequirementEvidence {
        attribute requirementId = "FGV-003";
        attribute qualifiedRequirement = "FlipRequirements::FLIPV003_WheelStations";
        attribute sourceReference = "https://www.astrolab.space/flip/; https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_fgv_004 : RequirementEvidence {
        attribute requirementId = "FGV-004";
        attribute qualifiedRequirement = "FlipRequirements::FLIPV004_SensorAndPower";
        attribute sourceReference = "https://www.astrolab.space/flip/; https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_fgv_005 : RequirementEvidence {
        attribute requirementId = "FGV-005";
        attribute qualifiedRequirement = "FlipRequirements::FLIPV005_Traceability";
        attribute sourceReference = "https://www.astrolab.space/flip/; https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_fgv_006 : RequirementEvidence {
        attribute requirementId = "FGV-006";
        attribute qualifiedRequirement = "FlipRequirements::FLIPV006_ChassisGeometry";
        attribute sourceReference = "https://www.astrolab.space/flip/; https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_fgv_007 : RequirementEvidence {
        attribute requirementId = "FGV-007";
        attribute qualifiedRequirement = "FlipRequirements::FLIPV007_MassPropertyDatum";
        attribute sourceReference = "https://www.astrolab.space/flip/; https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/";
        attribute rationale = "Prevents duplicate dynamics by keeping render and physics ownership explicit.";
    }

    part evidence_fgv_008 : RequirementEvidence {
        attribute requirementId = "FGV-008";
        attribute qualifiedRequirement = "FlipRequirements::FLIPV008_WheelEnvelope";
        attribute sourceReference = "https://www.astrolab.space/flip/; https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_fgv_009 : RequirementEvidence {
        attribute requirementId = "FGV-009";
        attribute qualifiedRequirement = "FlipRequirements::FLIPV009_MissionSteeringMode";
        attribute sourceReference = "https://www.astrolab.space/flip/; https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/; twin://astrobotic-griffin-1/scenarios/griffin_1_surface_ops.rhai";
        attribute rationale = "The route contains finite-radius turns; selecting Ackermann from SysML makes that operational assumption explicit and keeps it out of duplicated scenario literals.";
    }

    part evidence_fgv_010 : RequirementEvidence {
        attribute requirementId = "FGV-010";
        attribute qualifiedRequirement = "FlipRequirements::FLIPV010_PhysicalWheelSupportEnvelope";
        attribute sourceReference = "https://www.astrolab.space/flip/; twin://astrobotic-griffin-1/vehicles/flip.usda; twin://astrobotic-griffin-1/requirements/flip_suspension_requirements.sysml; twin://astrobotic-griffin-1/scenarios/griffin_1_surface_ops.rhai";
        attribute rationale = "The public FLIP material establishes the rover concept but not an as-built suspension ICD. The physical station arrays are therefore explicit, auditable study assumptions. The -0.75 m station is retained, while the physical suspension rest length is raised from the generic 0.70 m to the separate 1.20 m ramp-transition datum because the corrected 45.7457 degree ramp replay showed the shorter ray ending above the first downhill contact. Separating station and transition-envelope assumptions from visual geometry keeps the repair verifiable and replaceable when supplier data arrives.";
    }

    part evidence_fsp_001 : RequirementEvidence {
        attribute requirementId = "FSP-001";
        attribute qualifiedRequirement = "FlipSensorPowerRequirements::FSP001_MastStructure";
        attribute sourceReference = "https://www.astrolab.space/flip/";
        attribute rationale = "Makes review repeatable and distinguishes facts from study proxies.";
    }

    part evidence_fsp_002 : RequirementEvidence {
        attribute requirementId = "FSP-002";
        attribute qualifiedRequirement = "FlipSensorPowerRequirements::FSP002_SolarStructure";
        attribute sourceReference = "https://www.astrolab.space/flip/";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_fsp_003 : RequirementEvidence {
        attribute requirementId = "FSP-003";
        attribute qualifiedRequirement = "FlipSensorPowerRequirements::FSP003_MastDatum";
        attribute sourceReference = "https://www.astrolab.space/flip/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_fsp_004 : RequirementEvidence {
        attribute requirementId = "FSP-004";
        attribute qualifiedRequirement = "FlipSensorPowerRequirements::FSP004_SensorPowerTraceability";
        attribute sourceReference = "https://www.astrolab.space/flip/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_fsp_005 : RequirementEvidence {
        attribute requirementId = "FSP-005";
        attribute qualifiedRequirement = "FlipSensorPowerRequirements::FSP005_MastGeometry";
        attribute sourceReference = "https://www.astrolab.space/flip/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_fsp_006 : RequirementEvidence {
        attribute requirementId = "FSP-006";
        attribute qualifiedRequirement = "FlipSensorPowerRequirements::FSP006_SolarPanelGeometry";
        attribute sourceReference = "https://www.astrolab.space/flip/";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_fsr_001 : RequirementEvidence {
        attribute requirementId = "FSR-001";
        attribute qualifiedRequirement = "FlipSuspensionRequirements::FSR001_SourceTraceability";
        attribute sourceReference = "https://www.astrolab.space/flip-rover/; https://venturi.space/rovers/";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_fsr_002 : RequirementEvidence {
        attribute requirementId = "FSR-002";
        attribute qualifiedRequirement = "FlipSuspensionRequirements::FSR002_LocalFrame";
        attribute sourceReference = "https://www.astrolab.space/flip-rover/; https://venturi.space/rovers/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_fsr_003 : RequirementEvidence {
        attribute requirementId = "FSR-003";
        attribute qualifiedRequirement = "FlipSuspensionRequirements::FSR003_Topology";
        attribute sourceReference = "https://www.astrolab.space/flip-rover/; https://venturi.space/rovers/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_fsr_004 : RequirementEvidence {
        attribute requirementId = "FSR-004";
        attribute qualifiedRequirement = "FlipSuspensionRequirements::FSR004_Dimensions";
        attribute sourceReference = "https://www.astrolab.space/flip-rover/; https://venturi.space/rovers/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_fsr_005 : RequirementEvidence {
        attribute requirementId = "FSR-005";
        attribute qualifiedRequirement = "FlipSuspensionRequirements::FSR005_RenderOnlyCollision";
        attribute sourceReference = "https://www.astrolab.space/flip-rover/; https://venturi.space/rovers/";
        attribute rationale = "Prevents duplicate dynamics by keeping render and physics ownership explicit.";
    }

    part evidence_fsr_006 : RequirementEvidence {
        attribute requirementId = "FSR-006";
        attribute qualifiedRequirement = "FlipSuspensionRequirements::FSR006_TransformOrder";
        attribute sourceReference = "https://www.astrolab.space/flip-rover/; https://venturi.space/rovers/";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_fsr_007 : RequirementEvidence {
        attribute requirementId = "FSR-007";
        attribute qualifiedRequirement = "FlipSuspensionRequirements::FSR007_EnvelopeAndAxis";
        attribute sourceReference = "https://www.astrolab.space/flip-rover/; https://venturi.space/rovers/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_fsr_008 : RequirementEvidence {
        attribute requirementId = "FSR-008";
        attribute qualifiedRequirement = "FlipSuspensionRequirements::FSR008_PhysicalTransitionEnvelope";
        attribute sourceReference = "twin://astrobotic-griffin-1/requirements/flip_requirements.sysml; twin://astrobotic-griffin-1/requirements/flip_suspension_requirements.sysml; twin://astrobotic-griffin-1/vehicles/flip.usda; twin://astrobotic-griffin-1/scenes/griffin_1_surface_ops.usda";
        attribute rationale = "The 1.20 m value is an explicitly replaceable Twin simulation assumption derived from the corrected 45.7457 degree ramp replay: the generic 0.70 m support ray ended above the first downhill contact. The separate catalog entry keeps that evidence and rationale typed, discoverable, and distinct from public FLIP facts.";
    }

    part evidence_fww_001 : RequirementEvidence {
        attribute requirementId = "FWW-001";
        attribute qualifiedRequirement = "FlipWheelRequirements::FWW001_WheelCount";
        attribute sourceReference = "https://www.astrolab.space/flip/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_fww_002 : RequirementEvidence {
        attribute requirementId = "FWW-002";
        attribute qualifiedRequirement = "FlipWheelRequirements::FWW002_WheelGeometry";
        attribute sourceReference = "https://www.astrolab.space/flip/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_fww_003 : RequirementEvidence {
        attribute requirementId = "FWW-003";
        attribute qualifiedRequirement = "FlipWheelRequirements::FWW003_AllWheelSteering";
        attribute sourceReference = "https://www.astrolab.space/flip/";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_fww_004 : RequirementEvidence {
        attribute requirementId = "FWW-004";
        attribute qualifiedRequirement = "FlipWheelRequirements::FWW004_WheelTraceability";
        attribute sourceReference = "https://www.astrolab.space/flip/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_fww_005 : RequirementEvidence {
        attribute requirementId = "FWW-005";
        attribute qualifiedRequirement = "FlipWheelRequirements::FWW005_WheelPlacement";
        attribute sourceReference = "https://www.astrolab.space/flip/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_fww_006 : RequirementEvidence {
        attribute requirementId = "FWW-006";
        attribute qualifiedRequirement = "FlipWheelRequirements::FWW006_SuspensionVisual";
        attribute sourceReference = "https://www.astrolab.space/flip/";
        attribute rationale = "Prevents duplicate dynamics by keeping render and physics ownership explicit.";
    }

    part evidence_fww_007 : RequirementEvidence {
        attribute requirementId = "FWW-007";
        attribute qualifiedRequirement = "FlipWheelRequirements::FWW007_WheelEnvelope";
        attribute sourceReference = "https://www.astrolab.space/flip/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gbc_001 : RequirementEvidence {
        attribute requirementId = "GBC-001";
        attribute qualifiedRequirement = "GriffinBusRequirements::GBC001_BusIdentity";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gbc_002 : RequirementEvidence {
        attribute requirementId = "GBC-002";
        attribute qualifiedRequirement = "GriffinBusRequirements::GBC002_BusEnvelope";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gbc_003 : RequirementEvidence {
        attribute requirementId = "GBC-003";
        attribute qualifiedRequirement = "GriffinBusRequirements::GBC003_BusPresentationOwnership";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Prevents duplicate dynamics by keeping render and physics ownership explicit.";
    }

    part evidence_gbc_004 : RequirementEvidence {
        attribute requirementId = "GBC-004";
        attribute qualifiedRequirement = "GriffinBusRequirements::GBC004_BusTraceability";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gbc_005 : RequirementEvidence {
        attribute requirementId = "GBC-005";
        attribute qualifiedRequirement = "GriffinBusRequirements::GBC005_BusFrameGeometry";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gbc_006 : RequirementEvidence {
        attribute requirementId = "GBC-006";
        attribute qualifiedRequirement = "GriffinBusRequirements::GBC006_DeckGeometry";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gbc_007 : RequirementEvidence {
        attribute requirementId = "GBC-007";
        attribute qualifiedRequirement = "GriffinBusRequirements::GBC007_AssemblyRailGeometry";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; composed Griffin visual assembly";
        attribute rationale = "The active assembly replaces the legacy perimeter frame with six explicit rail envelopes; one source-owned length and station set prevents drift in the composed bus.";
    }

    part evidence_gbc_008 : RequirementEvidence {
        attribute requirementId = "GBC-008";
        attribute qualifiedRequirement = "GriffinBusRequirements::GBC008_HexagonalBodyShape";
        attribute sourceReference = "https://openusd.org/release/api/class_usd_geom_mesh.html; twin://astrobotic-griffin-1/requirements/griffin_visual_configuration.sysml";
        attribute rationale = "The body gate positively verifies the open six-sided member topology, face winding, and metric frame rather than relying on silhouette alone.";
    }

    part evidence_gbc_009 : RequirementEvidence {
        attribute requirementId = "GBC-009";
        attribute qualifiedRequirement = "GriffinBusRequirements::GBC009_OpenSideBays";
        attribute sourceReference = "twin://astrobotic-griffin-1/components/lander/griffin_bus_visual.usda; twin://astrobotic-griffin-1/requirements/griffin_visual_configuration.sysml";
        attribute rationale = "The open-frame configuration explicitly identifies the inherited side skins and requires clear bays so the separately modeled payload, tanks, avionics, and structure remain visible; exact thermal-blanket configuration is an unpublished study assumption.";
    }

    part evidence_glr_001 : RequirementEvidence {
        attribute requirementId = "GLR-001";
        attribute qualifiedRequirement = "GriffinLanderRequirements::GLR001_BusTopology";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_glr_002 : RequirementEvidence {
        attribute requirementId = "GLR-002";
        attribute qualifiedRequirement = "GriffinLanderRequirements::GLR002_LandingLegs";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_glr_003 : RequirementEvidence {
        attribute requirementId = "GLR-003";
        attribute qualifiedRequirement = "GriffinLanderRequirements::GLR003_PropellantTanks";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_glr_004 : RequirementEvidence {
        attribute requirementId = "GLR-004";
        attribute qualifiedRequirement = "GriffinLanderRequirements::GLR004_EngineCluster";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_glr_005 : RequirementEvidence {
        attribute requirementId = "GLR-005";
        attribute qualifiedRequirement = "GriffinLanderRequirements::GLR005_SolarArrays";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_glr_006 : RequirementEvidence {
        attribute requirementId = "GLR-006";
        attribute qualifiedRequirement = "GriffinLanderRequirements::GLR006_MetricEnvelope";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_glr_007 : RequirementEvidence {
        attribute requirementId = "GLR-007";
        attribute qualifiedRequirement = "GriffinLanderRequirements::GLR007_Traceability";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Makes count, identity, and provenance inspectable and replaceable.";
    }

    part evidence_glr_008 : RequirementEvidence {
        attribute requirementId = "GLR-008";
        attribute qualifiedRequirement = "GriffinLanderRequirements::GLR008_StationPlacement";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_glr_009 : RequirementEvidence {
        attribute requirementId = "GLR-009";
        attribute qualifiedRequirement = "GriffinLanderRequirements::GLR009_ComponentIdentity";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Makes count, identity, and provenance inspectable and replaceable.";
    }

    part evidence_glr_010 : RequirementEvidence {
        attribute requirementId = "GLR-010";
        attribute qualifiedRequirement = "GriffinLanderRequirements::GLR010_LocalFrameAndOwnership";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Prevents duplicate dynamics by keeping render and physics ownership explicit.";
    }

    part evidence_glr_011 : RequirementEvidence {
        attribute requirementId = "GLR-011";
        attribute qualifiedRequirement = "GriffinLanderRequirements::GLR011_SolarOrientation";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; twin://astrobotic-griffin-1/requirements/griffin_visual_configuration.sysml";
        attribute rationale = "The public source supports the side-array concept; the Twin-owned +90/-90 X rotations are explicit signed-frame study datums that map the panel +Y cell face outward onto +Z/-Z.";
    }

    part evidence_gll_001 : RequirementEvidence {
        attribute requirementId = "GLL-001";
        attribute qualifiedRequirement = "GriffinLandingLegRequirements::GLL001_LegCount";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Makes count, identity, and provenance inspectable and replaceable.";
    }

    part evidence_gll_002 : RequirementEvidence {
        attribute requirementId = "GLL-002";
        attribute qualifiedRequirement = "GriffinLandingLegRequirements::GLL002_LegStructure";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "The public Griffin description identifies four shock-absorbing legs; the Twin makes their repeated load-path members, joints, and contact foot separately inspectable while keeping this visual component out of collision ownership.";
    }

    part evidence_gll_003 : RequirementEvidence {
        attribute requirementId = "GLL-003";
        attribute qualifiedRequirement = "GriffinLandingLegRequirements::GLL003_LegFrame";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gll_004 : RequirementEvidence {
        attribute requirementId = "GLL-004";
        attribute qualifiedRequirement = "GriffinLandingLegRequirements::GLL004_LegTraceability";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Makes count, identity, and provenance inspectable and replaceable.";
    }

    part evidence_gll_005 : RequirementEvidence {
        attribute requirementId = "GLL-005";
        attribute qualifiedRequirement = "GriffinLandingLegRequirements::GLL005_LegPlacement";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gll_006 : RequirementEvidence {
        attribute requirementId = "GLL-006";
        attribute qualifiedRequirement = "GriffinLandingLegRequirements::GLL006_StrutGeometry";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; https://science.nasa.gov/wp-content/uploads/2023/11/astrobotic-lunar-landers-pug.pdf";
        attribute rationale = "Astrobotic's public product page and NASA-hosted user guide confirm four shock-absorbing legs but do not publish the strut section. The prior 0.28 m square members read as solid slabs at this 2.60 m visual-study scale. A 0.08 m radius (0.16 m outside diameter) is a replaceable tubular-member assumption: it preserves the canted load-path length while reducing member width by about 43 percent. Replace it with released supplier CAD before any structural claim.";
    }

    part evidence_gll_007 : RequirementEvidence {
        attribute requirementId = "GLL-007";
        attribute qualifiedRequirement = "GriffinLandingLegRequirements::GLL007_ShockPistonGeometry";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gll_008 : RequirementEvidence {
        attribute requirementId = "GLL-008";
        attribute qualifiedRequirement = "GriffinLandingLegRequirements::GLL008_FootPadGeometry";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Prevents duplicate dynamics by keeping render and physics ownership explicit.";
    }

    part evidence_gpp_001 : RequirementEvidence {
        attribute requirementId = "GPP-001";
        attribute qualifiedRequirement = "GriffinPropulsionRequirements::GPP001_EngineCount";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Makes count, identity, and provenance inspectable and replaceable.";
    }

    part evidence_gpp_002 : RequirementEvidence {
        attribute requirementId = "GPP-002";
        attribute qualifiedRequirement = "GriffinPropulsionRequirements::GPP002_BellGeometry";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gpp_003 : RequirementEvidence {
        attribute requirementId = "GPP-003";
        attribute qualifiedRequirement = "GriffinPropulsionRequirements::GPP003_ThrustOwnership";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Prevents duplicate dynamics by keeping render and physics ownership explicit.";
    }

    part evidence_gpp_004 : RequirementEvidence {
        attribute requirementId = "GPP-004";
        attribute qualifiedRequirement = "GriffinPropulsionRequirements::GPP004_PropulsionTraceability";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Makes count, identity, and provenance inspectable and replaceable.";
    }

    part evidence_gpp_005 : RequirementEvidence {
        attribute requirementId = "GPP-005";
        attribute qualifiedRequirement = "GriffinPropulsionRequirements::GPP005_EnginePlacement";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gpp_006 : RequirementEvidence {
        attribute requirementId = "GPP-006";
        attribute qualifiedRequirement = "GriffinPropulsionRequirements::GPP006_BellAndThroatEnvelope";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_ges_001 : RequirementEvidence {
        attribute requirementId = "GES-001";
        attribute qualifiedRequirement = "GriffinPropulsionRequirements::GES001_SkirtTopology";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_ges_002 : RequirementEvidence {
        attribute requirementId = "GES-002";
        attribute qualifiedRequirement = "GriffinPropulsionRequirements::GES002_SkirtEnvelope";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_ges_003 : RequirementEvidence {
        attribute requirementId = "GES-003";
        attribute qualifiedRequirement = "GriffinPropulsionRequirements::GES003_SkirtDatum";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_ges_004 : RequirementEvidence {
        attribute requirementId = "GES-004";
        attribute qualifiedRequirement = "GriffinPropulsionRequirements::GES004_BellClearance";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_ges_005 : RequirementEvidence {
        attribute requirementId = "GES-005";
        attribute qualifiedRequirement = "GriffinPropulsionRequirements::GES005_SkirtOwnership";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Prevents duplicate dynamics by keeping render and physics ownership explicit.";
    }

    part evidence_ges_006 : RequirementEvidence {
        attribute requirementId = "GES-006";
        attribute qualifiedRequirement = "GriffinPropulsionRequirements::GES006_RailGeometry";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_ges_007 : RequirementEvidence {
        attribute requirementId = "GES-007";
        attribute qualifiedRequirement = "GriffinPropulsionRequirements::GES007_ShellAndAdapterEnvelope";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_grr_001 : RequirementEvidence {
        attribute requirementId = "GRR-001";
        attribute qualifiedRequirement = "GriffinRampRequirements::GRR001_RampTopology";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; twin://astrobotic-griffin-1/requirements/griffin_ramp_requirements.sysml";
        attribute rationale = "Astrobotic establishes optional rover egress, but not a released ramp assembly tree. The named surface, rails, hinge hardware, supports, and render-only traction bars are therefore explicit Twin-owned members so the Editor can inspect and replace each load-path element independently.";
    }

    part evidence_grr_002 : RequirementEvidence {
        attribute requirementId = "GRR-002";
        attribute qualifiedRequirement = "GriffinRampRequirements::GRR002_RampHinge";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; twin://astrobotic-griffin-1/requirements/griffin_ramp_requirements.sysml";
        attribute rationale = "A rover egress ramp must transfer load through a repeatable hinge rather than a floating visual slab. The Z-axis mount frame and socket relation are explicit study assumptions because the public Griffin material does not publish the hinge ICD.";
    }

    part evidence_grr_003 : RequirementEvidence {
        attribute requirementId = "GRR-003";
        attribute qualifiedRequirement = "GriffinRampRequirements::GRR003_RampEnvelope";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; twin://astrobotic-griffin-1/requirements/griffin_ramp_requirements.sysml; twin://astrobotic-griffin-1/requirements/flip_requirements.sysml";
        attribute rationale = "The 8.00 m length and 3.50 m clear width are replaceable study values. Width is derived from the current FLIP lateral wheel station, conservative tyre envelope, and 0.15 m route clearance on each side, so the interface is wider than the rover without retaining the old oversized 5.50 m placeholder.";
    }

    part evidence_grr_004 : RequirementEvidence {
        attribute requirementId = "GRR-004";
        attribute qualifiedRequirement = "GriffinRampRequirements::GRR004_RampPlacement";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; twin://astrobotic-griffin-1/requirements/griffin_bus_requirements.sysml; twin://astrobotic-griffin-1/requirements/griffin_ramp_requirements.sysml";
        attribute rationale = "The visual bus deck top is 3.20 + 1.55 + 0.12 = 4.87 m; placing the 0.18 m ramp centre at 4.78 m makes its top face meet that deck. The bus-local socket is 1.58 m so it composes to the same root, while the physical mission frame remains separately COM-relative.";
    }

    part evidence_grr_005 : RequirementEvidence {
        attribute requirementId = "GRR-005";
        attribute qualifiedRequirement = "GriffinRampRequirements::GRR005_RampBehavior";
        attribute sourceReference = "twin://astrobotic-griffin-1/requirements/griffin_ramp_requirements.sysml; LunCoSim PhysicsRevoluteJoint angle-port contract";
        attribute rationale = "The Editor stores the visual angle in USD degrees while the mission command port uses radians; keeping the hinge axis, signed side angles, and limit in SysML lets the generic Rhai observer test the conversion and boundary without duplicating command literals.";
    }

    part evidence_grr_006 : RequirementEvidence {
        attribute requirementId = "GRR-006";
        attribute qualifiedRequirement = "GriffinRampRequirements::GRR006_RampGeometry";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; twin://astrobotic-griffin-1/requirements/griffin_ramp_requirements.sysml";
        attribute rationale = "Public material does not publish ramp CAD, so the composed surface extent is checked directly against the typed 8.00 m x 3.50 m x 0.18 m study envelope; rails, supports, and treads remain separately inspectable geometry.";
    }

    part evidence_grr_007 : RequirementEvidence {
        attribute requirementId = "GRR-007";
        attribute qualifiedRequirement = "GriffinRampRequirements::GRR007_RampEvidence";
        attribute sourceReference = "twin://astrobotic-griffin-1/tools/griffin_visual_builder.rhai; twin://astrobotic-griffin-1/scenarios/tests/griffin_ramp_requirements.rhai";
        attribute rationale = "The port and starboard ramps are authored as separate typed Editor changes and read back through the composed stage; the structured verdict therefore records the actual side, paths, dimensions, and source-backed verification identity.";
    }

    part evidence_grr_008 : RequirementEvidence {
        attribute requirementId = "GRR-008";
        attribute qualifiedRequirement = "GriffinRampRequirements::GRR008_RailGeometry";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; twin://astrobotic-griffin-1/requirements/griffin_ramp_requirements.sysml";
        attribute rationale = "A 0.28 m raised rail with 0.14 m width at +/-1.68 m leaves the FLIP wheel-clear span inside the 3.50 m surface. These are explicit visibility and route-containment assumptions, not claimed supplier dimensions.";
    }

    part evidence_grr_009 : RequirementEvidence {
        attribute requirementId = "GRR-009";
        attribute qualifiedRequirement = "GriffinRampRequirements::GRR009_SupportArmGeometry";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; twin://astrobotic-griffin-1/requirements/griffin_ramp_requirements.sysml";
        attribute rationale = "The centre support and +/-1.05 m pair make the visual hinge-to-deck load path readable at the 8 m ramp scale. Their 0.16 m x 1.90 m x 0.24 m envelopes and -18 degree tilt are replaceable study assumptions because the Griffin structural ICD is not public.";
    }

    part evidence_grr_010 : RequirementEvidence {
        attribute requirementId = "GRR-010";
        attribute qualifiedRequirement = "GriffinRampRequirements::GRR010_PhysicalEgressEnvelope";
        attribute sourceReference = "https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/; https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; twin://astrobotic-griffin-1/research/griffin_1_assumptions.md";
        attribute rationale = "Astrobotic confirms the egress concept but does not publish an as-built ramp ICD. The 8 m length and 3.5 m physical clear width are explicit Twin study assumptions: the width clears the FLIP wheel envelope (1.15 m station plus 0.45 m conservative tyre radius and 0.15 m route clearance on each side). The ramp is hinged at its inboard edge, so its surface centre is 4.00 m in the ramp body frame and its contact span is 0.00..8.00 m; asin((3.98 + 1.75)/8.00) = 45.7457 degrees then reaches the normalized terrain datum at the tip. The hinge is placed at the 3.16 m composed deck edge plus 0.04 m clearance. The deck transition is a separate GRR-012 plate, not a duplicated overlap in the main ramp surface. The visual and physical study envelopes now share the same 3.5 m width so Editor review and collision review cannot silently diverge.";
    }

    part evidence_grr_011 : RequirementEvidence {
        attribute requirementId = "GRR-011";
        attribute qualifiedRequirement = "GriffinRampRequirements::GRR011_PhysicalDeploymentLifecycle";
        attribute sourceReference = "LunCoSim PhysicsRevoluteJoint angle-port contract; twin://astrobotic-griffin-1/requirements/griffin_ramp_requirements.sysml";
        attribute rationale = "The full-length physical ramp must remain horizontal during descent so it cannot reach terrain before the lander legs. After touchdown, the existing revolute joint receives the SysML-owned +/-0.7984136958 rad geometry-derived command; the native joint retains a +/-50 degree travel limit. This preserves a real hinge transition and makes the deployment gate auditable despite the lack of a released Griffin ramp ICD.";
    }

    part evidence_grr_012 : RequirementEvidence {
        attribute requirementId = "GRR-012";
        attribute qualifiedRequirement = "GriffinRampRequirements::GRR012_PhysicalDeckTransition";
        attribute sourceReference = "https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/; https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; twin://astrobotic-griffin-1/research/griffin_1_assumptions.md; twin://astrobotic-griffin-1/vehicles/griffin_1.usda";
        attribute rationale = "The public sources establish optional rover egress but not the as-built interface. In the current Twin, TopDeckCollisionProxy tapers to x = +/-3.16 m at the FLIP wheel lateral plane and the physical ramp hinges are at x = +/-3.20 m. Interpolating the hex edge at the FLIP lateral station |x| = 0.95 m gives x = 2.6115 m, so the hinge gap is 0.5885 m. Adding the 0.25 m route margin and projecting through the 45.7457 degree ramp slope requires 1.2015 m along the ramp; the SysML datum rounds up to 1.21 m. The TransitionPlate is an unscaled Xform rigid-body child with a ContactSurface collider, fixed to the Griffin deck root, so it remains horizontal while the 8.00 m ramp rotates. The 15.0 kg mass is an explicit replaceable simulator assumption; 15.35/17.14/1.87 kg m^2 is the rectangular-prism inertia derived from that mass and the typed 1.21 x 0.18 x 3.50 m dimensions. The collision/API schemas, fixed-joint endpoints, mass, inertia, and authored dimensions are checked by the full Griffin lint and authored through the typed Editor builder.";
    }

    part evidence_grr_013 : RequirementEvidence {
        attribute requirementId = "GRR-013";
        attribute qualifiedRequirement = "GriffinRampRequirements::GRR013_TractionTreadGeometry";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; twin://astrobotic-griffin-1/requirements/griffin_ramp_requirements.sysml";
        attribute rationale = "Public Griffin material identifies optional rover egress but does not publish tread count, spacing, or ramp surface CAD. Eight 0.12 m wide by 0.05 m high transverse bars at 1.00 m pitch are therefore explicit render-only study datums, sized to remain inside the 3.50 m wheel-clear span; they make the ramp readable without adding a second collision owner.";
    }

    part evidence_grr_014 : RequirementEvidence {
        attribute requirementId = "GRR-014";
        attribute qualifiedRequirement = "GriffinRampRequirements::GRR014_RampLoadPathGeometry";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; twin://astrobotic-griffin-1/requirements/griffin_ramp_requirements.sysml; twin://astrobotic-griffin-1/tools/griffin_visual_builder.rhai";
        attribute rationale = "The public egress concept does not publish a ramp structural ICD. Two 0.18 m x 0.16 m underside beams, four 0.12 m x 0.50 m x 0.12 m upright posts per edge, and two 0.18 m-radius hinge collars are therefore explicit render-only study datums. They expose the load path and revolute hardware in the Editor while keeping collision and mechanism ownership in the physical ramp model.";
    }

    part evidence_grr_015 : RequirementEvidence {
        attribute requirementId = "GRR-015";
        attribute qualifiedRequirement = "GriffinRampRequirements::GRR015_RampHingeGussetGeometry";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; twin://astrobotic-griffin-1/requirements/griffin_ramp_requirements.sysml; twin://astrobotic-griffin-1/tools/griffin_visual_builder.rhai";
        attribute rationale = "The public material establishes rover egress but does not publish the hinge-to-rail structural detail. Two 0.70 m x 0.24 m x 0.18 m render-only inboard gussets at the signed rail stations are explicit study assumptions added to close the visible hinge/load-path gap; their dimensions remain replaceable when an ICD is available and they do not create a second collision or dynamics owner.";
    }

    part evidence_gr_001 : RequirementEvidence {
        attribute requirementId = "GR-001";
        attribute qualifiedRequirement = "Griffin1Requirements::GR001_LanderArchitecture";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gr_002 : RequirementEvidence {
        attribute requirementId = "GR-002";
        attribute qualifiedRequirement = "Griffin1Requirements::GR002_PayloadAdapter";
        attribute sourceReference = "Twin adapter/release contract and https://www.astrolab.space/flip/";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_gr_003 : RequirementEvidence {
        attribute requirementId = "GR-003";
        attribute qualifiedRequirement = "Griffin1Requirements::GR003_DeployableRamps";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_gr_004 : RequirementEvidence {
        attribute requirementId = "GR-004";
        attribute qualifiedRequirement = "Griffin1Requirements::GR004_SurfaceSequence";
        attribute sourceReference = "Twin mission scenario contract";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_gr_005 : RequirementEvidence {
        attribute requirementId = "GR-005";
        attribute qualifiedRequirement = "Griffin1Requirements::GR005_TraceableValues";
        attribute sourceReference = "SysML/Rhai verification policy";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gr_006 : RequirementEvidence {
        attribute requirementId = "GR-006";
        attribute qualifiedRequirement = "Griffin1Requirements::GR006_SolarAssemblies";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ and https://www.astrolab.space/flip/";
        attribute rationale = "Prevents duplicate dynamics by keeping render and physics ownership explicit.";
    }

    part evidence_gr_007 : RequirementEvidence {
        attribute requirementId = "GR-007";
        attribute qualifiedRequirement = "Griffin1Requirements::GR007_GatedEgress";
        attribute sourceReference = "Twin egress runtime contract";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_gr_008 : RequirementEvidence {
        attribute requirementId = "GR-008";
        attribute qualifiedRequirement = "Griffin1Requirements::GR008_AttitudeCases";
        attribute sourceReference = "Twin mission verification plan";
        attribute rationale = "Makes count, identity, and provenance inspectable and replaceable.";
    }

    part evidence_gr_009 : RequirementEvidence {
        attribute requirementId = "GR-009";
        attribute qualifiedRequirement = "Griffin1Requirements::GR009_PayloadCapacity";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gr_010 : RequirementEvidence {
        attribute requirementId = "GR-010";
        attribute qualifiedRequirement = "Griffin1Requirements::GR010_FunctionalLegs";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_gr_011 : RequirementEvidence {
        attribute requirementId = "GR-011";
        attribute qualifiedRequirement = "Griffin1Requirements::GR011_RampBodies";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_gr_012 : RequirementEvidence {
        attribute requirementId = "GR-012";
        attribute qualifiedRequirement = "Griffin1Requirements::GR012_LoadBearingMass";
        attribute sourceReference = "LunCoSim physics admission contract";
        attribute rationale = "Prevents duplicate dynamics by keeping render and physics ownership explicit.";
    }

    part evidence_gr_013 : RequirementEvidence {
        attribute requirementId = "GR-013";
        attribute qualifiedRequirement = "Griffin1Requirements::GR013_ParameterProvenance";
        attribute sourceReference = "SysML/Rhai provenance policy";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gr_014 : RequirementEvidence {
        attribute requirementId = "GR-014";
        attribute qualifiedRequirement = "Griffin1Requirements::GR014_TypedAuthoring";
        attribute sourceReference = "LunCoSim typed Editor authoring contract";
        attribute rationale = "Makes count, identity, and provenance inspectable and replaceable.";
    }

    part evidence_gr_015 : RequirementEvidence {
        attribute requirementId = "GR-015";
        attribute qualifiedRequirement = "Griffin1Requirements::GR015_NozzleGeometry";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ and the Twin visual ownership contract";
        attribute rationale = "Prevents duplicate dynamics by keeping render and physics ownership explicit.";
    }

    part evidence_gr_016 : RequirementEvidence {
        attribute requirementId = "GR-016";
        attribute qualifiedRequirement = "Griffin1Requirements::GR016_SolarSymmetry";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gr_017 : RequirementEvidence {
        attribute requirementId = "GR-017";
        attribute qualifiedRequirement = "Griffin1Requirements::GR017_RampSymmetry";
        attribute sourceReference = "Twin ramp component contract";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_gr_018 : RequirementEvidence {
        attribute requirementId = "GR-018";
        attribute qualifiedRequirement = "Griffin1Requirements::GR018_HullAndDeck";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_gr_019 : RequirementEvidence {
        attribute requirementId = "GR-019";
        attribute qualifiedRequirement = "Griffin1Requirements::GR019_LegPlacement";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gr_020 : RequirementEvidence {
        attribute requirementId = "GR-020";
        attribute qualifiedRequirement = "Griffin1Requirements::GR020_ProxySuppression";
        attribute sourceReference = "Twin component ownership policy";
        attribute rationale = "Prevents duplicate dynamics by keeping render and physics ownership explicit.";
    }

    part evidence_gr_021 : RequirementEvidence {
        attribute requirementId = "GR-021";
        attribute qualifiedRequirement = "Griffin1Requirements::GR021_MassProperties";
        attribute sourceReference = "rigid-body physics contract";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gr_022 : RequirementEvidence {
        attribute requirementId = "GR-022";
        attribute qualifiedRequirement = "Griffin1Requirements::GR022_SupportPolygon";
        attribute sourceReference = "rigid-body stability criterion";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gr_023 : RequirementEvidence {
        attribute requirementId = "GR-023";
        attribute qualifiedRequirement = "Griffin1Requirements::GR023_ContactContinuity";
        attribute sourceReference = "contact/terrain acceptance contract";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gr_024 : RequirementEvidence {
        attribute requirementId = "GR-024";
        attribute qualifiedRequirement = "Griffin1Requirements::GR024_HingeFrames";
        attribute sourceReference = "Twin mount-socket and revolute-joint contract";
        attribute rationale = "Prevents duplicate dynamics by keeping render and physics ownership explicit.";
    }

    part evidence_gr_025 : RequirementEvidence {
        attribute requirementId = "GR-025";
        attribute qualifiedRequirement = "Griffin1Requirements::GR025_SolarClearance";
        attribute sourceReference = "spacecraft deployable-clearance practice";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_gr_026 : RequirementEvidence {
        attribute requirementId = "GR-026";
        attribute qualifiedRequirement = "Griffin1Requirements::GR026_AdapterRelease";
        attribute sourceReference = "Twin adapter-release runtime contract";
        attribute rationale = "Prevents duplicate dynamics by keeping render and physics ownership explicit.";
    }

    part evidence_gr_027 : RequirementEvidence {
        attribute requirementId = "GR-027";
        attribute qualifiedRequirement = "Griffin1Requirements::GR027_PropulsionAlignment";
        attribute sourceReference = "propulsion presentation/flight-model boundary";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gr_028 : RequirementEvidence {
        attribute requirementId = "GR-028";
        attribute qualifiedRequirement = "Griffin1Requirements::GR028_InterfaceResolution";
        attribute sourceReference = "Twin subsystem interface registry";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_gr_029 : RequirementEvidence {
        attribute requirementId = "GR-029";
        attribute qualifiedRequirement = "Griffin1Requirements::GR029_PartProvenance";
        attribute sourceReference = "SysML provenance policy and the public Griffin/FLIP references listed on the parts";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gr_030 : RequirementEvidence {
        attribute requirementId = "GR-030";
        attribute qualifiedRequirement = "Griffin1Requirements::GR030_EvidenceGate";
        attribute sourceReference = "Twin evidence gate";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gr_031 : RequirementEvidence {
        attribute requirementId = "GR-031";
        attribute qualifiedRequirement = "Griffin1Requirements::GR031_DeterministicVerdict";
        attribute sourceReference = "LunCoSim deterministic test runner contract";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_gr_032 : RequirementEvidence {
        attribute requirementId = "GR-032";
        attribute qualifiedRequirement = "Griffin1Requirements::GR032_MainEngineBells";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gr_033 : RequirementEvidence {
        attribute requirementId = "GR-033";
        attribute qualifiedRequirement = "Griffin1Requirements::GR033_PropellantTanks";
        attribute sourceReference = "https://www.astrobotic.com/griffin-1-mission-update/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gr_034 : RequirementEvidence {
        attribute requirementId = "GR-034";
        attribute qualifiedRequirement = "Griffin1Requirements::GR034_SurfaceRouteDatums";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; twin://astrobotic-griffin-1/requirements/griffin_ramp_requirements.sysml; twin://astrobotic-griffin-1/requirements/griffin_requirements.sysml";
        attribute rationale = "Keeps marker names, speeds, and arrival radii in one ordered SysML interface table. The 0.35 m approach-lane radius requires FLIP's front wheels to reach the separately modeled 1.21 m transition while accepting the measured low-speed steering drift. The 0.30 m exit radius remains tight, but the exit datum is placed at (12.00,0.00) m on the ramp centreline: the corrected headful replay observed the released rover near (11.15,-0.13) m with two front contacts, so the forward centreline gate lets the trailing axle clear the ramp without commanding Ackermann guidance into a lateral reversal. RoverTarget2 uses a 1.20 m gate because the deterministic replay crossed its centerline at 1.05 m with all four wheel contacts valid; the later 0.22..0.14 m/s corner speeds are conservative study-vehicle limits selected from the observed Ackermann overshoot at the diagonal survey sequence. This prevents stale coordinates, excessive corner speed, or an oversized tolerance from declaring egress complete while FLIP remains on the deck.";
    }

    part evidence_gr_035 : RequirementEvidence {
        attribute requirementId = "GR-035";
        attribute qualifiedRequirement = "Griffin1Requirements::GR035_EgressApronContact";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/; twin://astrobotic-griffin-1/scenes/griffin_1_surface_ops.usda; twin://astrobotic-griffin-1/tools/griffin_visual_builder.rhai";
        attribute rationale = "The public Griffin and mission sources establish the vehicle and egress context but do not publish an as-built site-apron ICD. The 10.00 m x 8.00 m x 0.10 m EgressApron at (13.50,-0.05,-1.00) is therefore an explicit, replaceable Twin study component: its top y=0.00 m matches the normalized ramp-tip datum, it overlaps the 8.00 m ramp tip near x=11.20 m, extends beyond the (12.00,0.00) centreline exit gate, and avoids introducing a second raised site datum while FLIP clears the ramp. The typed Editor operation and composed wheel-contact evidence make the assumption visible instead of hiding it in a route literal or comment-only verdict.";
    }

    part evidence_gv_001 : RequirementEvidence {
        attribute requirementId = "GV-001";
        attribute qualifiedRequirement = "Griffin1Requirements::GRV001_PresentationFrame";
        attribute sourceReference = "LunCoSim visual review contract";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gv_002 : RequirementEvidence {
        attribute requirementId = "GV-002";
        attribute qualifiedRequirement = "Griffin1Requirements::GRV002_LanderPresentation";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gv_003 : RequirementEvidence {
        attribute requirementId = "GV-003";
        attribute qualifiedRequirement = "Griffin1Requirements::GRV003_GriffinSolarAssemblies";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gv_004 : RequirementEvidence {
        attribute requirementId = "GV-004";
        attribute qualifiedRequirement = "Griffin1Requirements::GRV004_ScaleDatums";
        attribute sourceReference = "Moon Base SI/Y-up project contract";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gv_005 : RequirementEvidence {
        attribute requirementId = "GV-005";
        attribute qualifiedRequirement = "Griffin1Requirements::GRV005_RenderOwnership";
        attribute sourceReference = "LunCoSim visual/physics ownership policy";
        attribute rationale = "Prevents duplicate dynamics by keeping render and physics ownership explicit.";
    }

    part evidence_gv_006 : RequirementEvidence {
        attribute requirementId = "GV-006";
        attribute qualifiedRequirement = "Griffin1Requirements::GRV006_LunarContext";
        attribute sourceReference = "https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/ and the Twin terrain asset manifest";
        attribute rationale = "Makes count, identity, and provenance inspectable and replaceable.";
    }

    part evidence_gv_007 : RequirementEvidence {
        attribute requirementId = "GV-007";
        attribute qualifiedRequirement = "Griffin1Requirements::GRV007_VisualEvidence";
        attribute sourceReference = "Twin visual evidence gate";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gsa_001 : RequirementEvidence {
        attribute requirementId = "GSA-001";
        attribute qualifiedRequirement = "GriffinSolarRequirements::GSA001_ArrayCount";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gsa_002 : RequirementEvidence {
        attribute requirementId = "GSA-002";
        attribute qualifiedRequirement = "GriffinSolarRequirements::GSA002_ArrayStructure";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gsa_003 : RequirementEvidence {
        attribute requirementId = "GSA-003";
        attribute qualifiedRequirement = "GriffinSolarRequirements::GSA003_ArraySymmetry";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gsa_004 : RequirementEvidence {
        attribute requirementId = "GSA-004";
        attribute qualifiedRequirement = "GriffinSolarRequirements::GSA004_ArrayTraceability";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Makes count, identity, and provenance inspectable and replaceable.";
    }

    part evidence_gsa_005 : RequirementEvidence {
        attribute requirementId = "GSA-005";
        attribute qualifiedRequirement = "GriffinSolarRequirements::GSA005_ArrayPlacement";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gsa_006 : RequirementEvidence {
        attribute requirementId = "GSA-006";
        attribute qualifiedRequirement = "GriffinSolarRequirements::GSA006_PanelEnvelope";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gsa_007 : RequirementEvidence {
        attribute requirementId = "GSA-007";
        attribute qualifiedRequirement = "GriffinSolarRequirements::GSA007_CellGridAndMount";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gsa_008 : RequirementEvidence {
        attribute requirementId = "GSA-008";
        attribute qualifiedRequirement = "GriffinSolarRequirements::GSA008_HingeAndStandoff";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; Twin visual study assumption";
        attribute rationale = "The public source establishes Griffin solar arrays but not their hinge ICD; explicit render-only hinge and link datums keep the panel attachment inspectable and replaceable instead of floating geometry.";
    }

    part evidence_gpt_001 : RequirementEvidence {
        attribute requirementId = "GPT-001";
        attribute qualifiedRequirement = "GriffinTankRequirements::GPT001_TankCount";
        attribute sourceReference = "https://www.astrobotic.com/media-kit/images/; https://www.nasa.gov/gallery/astrobotics-griffin-1/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gpt_002 : RequirementEvidence {
        attribute requirementId = "GPT-002";
        attribute qualifiedRequirement = "GriffinTankRequirements::GPT002_TankRetention";
        attribute sourceReference = "https://www.astrobotic.com/media-kit/images/; https://www.nasa.gov/gallery/astrobotics-griffin-1/";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_gpt_003 : RequirementEvidence {
        attribute requirementId = "GPT-003";
        attribute qualifiedRequirement = "GriffinTankRequirements::GPT003_TankStatus";
        attribute sourceReference = "https://www.astrobotic.com/media-kit/images/; https://www.nasa.gov/gallery/astrobotics-griffin-1/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gpt_004 : RequirementEvidence {
        attribute requirementId = "GPT-004";
        attribute qualifiedRequirement = "GriffinTankRequirements::GPT004_TankTraceability";
        attribute sourceReference = "https://www.astrobotic.com/media-kit/images/; https://www.nasa.gov/gallery/astrobotics-griffin-1/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gpt_005 : RequirementEvidence {
        attribute requirementId = "GPT-005";
        attribute qualifiedRequirement = "GriffinTankRequirements::GPT005_TankPlacement";
        attribute sourceReference = "https://www.astrobotic.com/media-kit/images/; https://www.nasa.gov/gallery/astrobotics-griffin-1/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gpt_006 : RequirementEvidence {
        attribute requirementId = "GPT-006";
        attribute qualifiedRequirement = "GriffinTankRequirements::GPT006_TankEndHardware";
        attribute sourceReference = "https://www.astrobotic.com/media-kit/images/; https://www.nasa.gov/gallery/astrobotics-griffin-1/";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_gpt_007 : RequirementEvidence {
        attribute requirementId = "GPT-007";
        attribute qualifiedRequirement = "GriffinTankRequirements::GPT007_TankServiceHardware";
        attribute sourceReference = "https://www.astrobotic.com/media-kit/images/; https://www.nasa.gov/gallery/astrobotics-griffin-1/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gpt_008 : RequirementEvidence {
        attribute requirementId = "GPT-008";
        attribute qualifiedRequirement = "GriffinTankRequirements::GPT008_TankOrientation";
        attribute sourceReference = "https://www.astrobotic.com/media-kit/images/; https://www.nasa.gov/gallery/astrobotics-griffin-1/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gpt_009 : RequirementEvidence {
        attribute requirementId = "GPT-009";
        attribute qualifiedRequirement = "GriffinTankRequirements::GPT009_TankDeckSeat";
        attribute sourceReference = "https://www.astrobotic.com/media-kit/images/; https://www.nasa.gov/gallery/astrobotics-griffin-1/";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_gpt_010 : RequirementEvidence {
        attribute requirementId = "GPT-010";
        attribute qualifiedRequirement = "GriffinTankRequirements::GPT010_TankMounting";
        attribute sourceReference = "https://www.astrobotic.com/media-kit/images/; https://www.nasa.gov/gallery/astrobotics-griffin-1/";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_gpt_011 : RequirementEvidence {
        attribute requirementId = "GPT-011";
        attribute qualifiedRequirement = "GriffinTankRequirements::GPT011_ComponentIdentity";
        attribute sourceReference = "https://www.astrobotic.com/media-kit/images/; https://www.nasa.gov/gallery/astrobotics-griffin-1/";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_gvc_001 : RequirementEvidence {
        attribute requirementId = "GVC-001";
        attribute qualifiedRequirement = "GriffinVisualConfigurationRequirements::GVC001_ConfigurationSelection";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; https://science.nasa.gov/wp-content/uploads/2023/11/astrobotic-lunar-landers-pug.pdf";
        attribute rationale = "Separates the selected landed polar side-array review configuration from other public Griffin concepts.";
    }

    part evidence_gvc_002 : RequirementEvidence {
        attribute requirementId = "GVC-002";
        attribute qualifiedRequirement = "GriffinVisualConfigurationRequirements::GVC002_FrameAndOrigin";
        attribute sourceReference = "twin://astrobotic-griffin-1/requirements/griffin_visual_configuration.sysml";
        attribute rationale = "A single typed Y-up assembly frame makes station symmetry and Editor readback deterministic.";
    }

    part evidence_gvc_003 : RequirementEvidence {
        attribute requirementId = "GVC-003";
        attribute qualifiedRequirement = "GriffinVisualConfigurationRequirements::GVC003_HexagonalAirframe";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; twin://astrobotic-griffin-1/requirements/griffin_visual_configuration.sysml";
        attribute rationale = "Public Griffin imagery supplies the faceted silhouette anchor; the six-sided planform and exact 4.50 m study envelope are explicit replaceable assumptions because the structural ICD is not public.";
    }

    part evidence_gvc_004 : RequirementEvidence {
        attribute requirementId = "GVC-004";
        attribute qualifiedRequirement = "GriffinVisualConfigurationRequirements::GVC004_IsogridDeck";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; twin://astrobotic-griffin-1/requirements/griffin_visual_configuration.sysml";
        attribute rationale = "The payload deck is a public Griffin architectural cue; thickness and exact dimensions are marked study assumptions in the typed source.";
    }

    part evidence_gvc_005 : RequirementEvidence {
        attribute requirementId = "GVC-005";
        attribute qualifiedRequirement = "GriffinVisualConfigurationRequirements::GVC005_LegStations";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; twin://astrobotic-griffin-1/requirements/griffin_visual_configuration.sysml";
        attribute rationale = "Four legs are public product information; axial stations and clearance are explicit visual-study datums rather than guessed Rhai literals.";
    }

    part evidence_gvc_006 : RequirementEvidence {
        attribute requirementId = "GVC-006";
        attribute qualifiedRequirement = "GriffinVisualConfigurationRequirements::GVC006_SolarStations";
        attribute sourceReference = "https://science.nasa.gov/wp-content/uploads/2023/11/astrobotic-lunar-landers-pug.pdf; twin://astrobotic-griffin-1/requirements/griffin_visual_configuration.sysml";
        attribute rationale = "The NASA/Astrobotic guide supports a polar side-array option; station offsets and outward rotations are typed study assumptions.";
    }

    part evidence_gvc_007 : RequirementEvidence {
        attribute requirementId = "GVC-007";
        attribute qualifiedRequirement = "GriffinVisualConfigurationRequirements::GVC007_TankPlacement";
        attribute sourceReference = "https://www.astrobotic.com/media-kit/images/; twin://astrobotic-griffin-1/requirements/griffin_visual_configuration.sysml";
        attribute rationale = "Public imagery supports four deck-mounted vessel proxies, while vessel dimensions and stations remain explicit replaceable assumptions.";
    }

    part evidence_gvc_008 : RequirementEvidence {
        attribute requirementId = "GVC-008";
        attribute qualifiedRequirement = "GriffinVisualConfigurationRequirements::GVC008_EngineAndSkirtDatum";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; twin://astrobotic-griffin-1/requirements/griffin_visual_configuration.sysml";
        attribute rationale = "Seven engines are a public Griffin datum; the skirt and engine station arrangement are isolated visual-study geometry.";
    }

    part evidence_gvc_009 : RequirementEvidence {
        attribute requirementId = "GVC-009";
        attribute qualifiedRequirement = "GriffinVisualConfigurationRequirements::GVC009_RampState";
        attribute sourceReference = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; twin://astrobotic-griffin-1/requirements/griffin_visual_configuration.sysml";
        attribute rationale = "The review silhouette stays stowed; the mission scene can deploy the optional ramps after touchdown without mixing states.";
    }

    part evidence_gvc_010 : RequirementEvidence {
        attribute requirementId = "GVC-010";
        attribute qualifiedRequirement = "GriffinVisualConfigurationRequirements::GVC010_ClearanceAndSymmetry";
        attribute sourceReference = "twin://astrobotic-griffin-1/scenarios/tests/griffin_bus_requirements.rhai; twin://astrobotic-griffin-1/scenarios/tests/griffin_lander_requirements.rhai";
        attribute rationale = "Cross-component checks catch the station and envelope contradictions that isolated part checks cannot detect.";
    }

    part evidence_gvc_011 : RequirementEvidence {
        attribute requirementId = "GVC-011";
        attribute qualifiedRequirement = "GriffinVisualConfigurationRequirements::GVC011_Traceability";
        attribute sourceReference = "twin://astrobotic-griffin-1/requirements/griffin_requirement_sources.sysml; twin://astrobotic-griffin-1/twin.toml";
        attribute rationale = "The typed provenance catalog and Twin manifest make the configuration source and verification case discoverable.";
    }

    part evidence_gvc_012 : RequirementEvidence {
        attribute requirementId = "GVC-012";
        attribute qualifiedRequirement = "GriffinVisualConfigurationRequirements::GVC012_FrameRails";
        attribute sourceReference = "https://www.astrobotic.com/media-kit/images/; twin://astrobotic-griffin-1/requirements/griffin_visual_configuration.sysml";
        attribute rationale = "Repeated perimeter members are visible in the reference imagery; the rail dimensions are a typed, geometry-derived study assumption kept inside the bus envelope.";
    }

    part evidence_gvc_013 : RequirementEvidence {
        attribute requirementId = "GVC-013";
        attribute qualifiedRequirement = "GriffinVisualConfigurationRequirements::GVC013_SurfaceOrientation";
        attribute sourceReference = "https://openusd.org/release/api/class_usd_geom_mesh.html; twin://astrobotic-griffin-1/requirements/griffin_visual_configuration.sysml";
        attribute rationale = "Outward winding is the geometry source of truth; doubleSided is an explicit temporary presentation safeguard for the known surface-orientation failure mode.";
    }

    part evidence_gvc_014 : RequirementEvidence {
        attribute requirementId = "GVC-014";
        attribute qualifiedRequirement = "GriffinVisualConfigurationRequirements::GVC014_ParametricProfile";
        attribute sourceReference = "https://openusd.org/release/api/class_usd_geom_mesh.html; twin://astrobotic-griffin-1/requirements/griffin_visual_configuration.sysml";
        attribute rationale = "A single standard Cartesian vector profile is scaled by the independently required deck/skirt dimensions, then extruded by the shared f64 geometry kernel; the six normalized points remain replaceable source-owned assumptions.";
    }

    part evidence_gbc_010 : RequirementEvidence {
        attribute requirementId = "GBC-010";
        attribute qualifiedRequirement = "GriffinBusRequirements::GBC010_DeckSkirtSeparation";
        attribute sourceReference = "twin://astrobotic-griffin-1/requirements/griffin_bus_requirements.sysml; twin://astrobotic-griffin-1/scenarios/tests/griffin_bus_requirements.rhai";
        attribute rationale = "The service-bay gap is derived from the deck/skirt centers and dimensions and checked by the shared oriented-box SAT calculation; no second clearance dimension is invented.";
    }

    part evidence_mb_001 : RequirementEvidence {
        attribute requirementId = "MB-001";
        attribute qualifiedRequirement = "MoonBaseProjectRequirements::MB001_MetricSystem";
        attribute sourceReference = "Twin project contract; external mission sources are recorded on the owning vehicle parts.";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_mb_002 : RequirementEvidence {
        attribute requirementId = "MB-002";
        attribute qualifiedRequirement = "MoonBaseProjectRequirements::MB002_YUpFrame";
        attribute sourceReference = "Twin project contract; external mission sources are recorded on the owning vehicle parts.";
        attribute rationale = "Provides one measurable datum for composed-USD geometry inspection.";
    }

    part evidence_mb_003 : RequirementEvidence {
        attribute requirementId = "MB-003";
        attribute qualifiedRequirement = "MoonBaseProjectRequirements::MB003_DeterministicRhai";
        attribute sourceReference = "Twin project contract; external mission sources are recorded on the owning vehicle parts.";
        attribute rationale = "Makes control, contact, or state transfer observable in the mission test.";
    }

    part evidence_mb_004 : RequirementEvidence {
        attribute requirementId = "MB-004";
        attribute qualifiedRequirement = "MoonBaseProjectRequirements::MB004_VisualEvidence";
        attribute sourceReference = "Twin project contract; external mission sources are recorded on the owning vehicle parts.";
        attribute rationale = "Makes count, identity, and provenance inspectable and replaceable.";
    }

}
