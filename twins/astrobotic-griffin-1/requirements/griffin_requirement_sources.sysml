package GriffinRequirementSources {
    private import ScalarValues::String;

    attribute def SourceLocator :> String;
    attribute def TwinAssetPath :> String;
    attribute def UsdPrimPath :> String;
    enum def EvidenceSourceRole { Reference; VisualAsset; ShaderAsset; }

    part def EvidenceSource {
        attribute role : EvidenceSourceRole;
        attribute locator : SourceLocator;
    }

    part def RequirementEvidence {
        ref targetRequirement : SysML::RequirementUsage;
        ref part sources : EvidenceSource[0..*];
    }

    /*
     * Evidence links directly to the normative SysML requirement usage.
     * Each source link resolves to one typed SourceLocator value. Requirement
     * identifiers are the standard SysML short names on those usages.
     */
    part source_astrobotic_griffin_propulsion_pug_2022 : EvidenceSource {
        doc /* August 2021 v5.02, printed p.26. URL dated January 2022 is the hosting/upload path, not the guide edition. Five main engines, twelve ACS engines in groups of three, two fuel and two oxidizer tanks; detailed dimensions remain estimates. */
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf";
    }

    part source_astrobotic_griffin_1_lander_griffin_bus_visual_usda : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/components/lander/griffin_bus_visual.usda";
    }

    part source_astrobotic_griffin_1_requirements_flip_requirements_sysml : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/requirements/flip_requirements.sysml";
    }

    part source_astrobotic_griffin_1_requirements_flip_suspension_requirements_sysml : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/requirements/flip_suspension_requirements.sysml";
    }

    part source_astrobotic_griffin_1_requirements_griffin_bus_requirements_sysml : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/requirements/griffin_bus_requirements.sysml";
    }

    part source_astrobotic_griffin_1_requirements_griffin_ramp_requirements_sysml : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/requirements/griffin_ramp_requirements.sysml";
    }

    part source_astrobotic_griffin_1_components_lander_griffin_ramp_section_visual_usda : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/components/lander/griffin_ramp_section_visual.usda";
    }

    part source_astrobotic_griffin_1_requirements_griffin_requirement_sources_sysml : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/requirements/griffin_requirement_sources.sysml";
    }

    part source_astrobotic_griffin_1_requirements_griffin_requirements_sysml : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/requirements/griffin_requirements.sysml";
    }

    part source_astrobotic_griffin_1_requirements_griffin_assurance_requirements_sysml : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/requirements/griffin_assurance_requirements.sysml";
    }

    part source_lunco_sysml_requirements_tool : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "lunco://scripting/tools/sysml_requirements.rhai";
    }

    part source_astrobotic_griffin_1_requirements_griffin_lander_requirements_sysml : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/requirements/griffin_lander_requirements.sysml";
    }

    part source_astrobotic_griffin_1_requirements_griffin_simulation_accuracy_requiremen : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/requirements/griffin_simulation_accuracy_requirements.sysml";
    }

    part source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/requirements/griffin_visual_configuration.sysml";
    }

    part source_astrobotic_griffin_1_research_griffin_1_assumptions_md : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/research/griffin_1_assumptions.md";
    }

    part source_astrobotic_griffin_1_scenarios_griffin_1_surface_ops_rhai : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/scenarios/griffin_1_surface_ops.rhai";
    }

    part source_astrobotic_griffin_1_scenes_griffin_1_surface_ops_usda : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/scenes/griffin_1_surface_ops.usda";
    }

    part source_astrobotic_griffin_1_tests_griffin_bus_requirements_rhai : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/scenarios/tests/griffin_bus_requirements.rhai";
    }

    part source_astrobotic_griffin_1_tests_griffin_lander_requirements_rhai : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/scenarios/tests/griffin_lander_requirements.rhai";
    }

    part source_astrobotic_griffin_1_tests_griffin_ramp_requirements_rhai : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/scenarios/tests/griffin_ramp_requirements.rhai";
    }

    part source_astrobotic_griffin_1_tests_griffin_propulsion_requirements_rhai : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/scenarios/tests/griffin_propulsion_requirements.rhai";
    }

    part source_astrobotic_griffin_1_tools_griffin_visual_builder_rhai : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/tools/griffin_visual_builder.rhai";
    }

    part source_astrobotic_griffin_1_twin_toml : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/twin.toml";
    }

    part source_astrobotic_griffin_1_vehicles_flip_usda : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/vehicles/flip.usda";
    }

    part source_astrobotic_griffin_1_vehicles_griffin_1_usda : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/vehicles/griffin_1.usda";
    }

    part source_openusd_org_class_usd_geom_mesh_html : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "https://openusd.org/release/api/class_usd_geom_mesh.html";
    }

    part source_science_nasa_gov_astrobotic_lunar_landers_pug_pdf : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "https://science.nasa.gov/wp-content/uploads/2023/11/astrobotic-lunar-landers-pug.pdf";
    }

    part source_venturi_space_rovers : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "https://venturi.space/rovers/";
    }

    part source_www_astrobotic_com_griffin_1_lunar_lander_unveiled_ahead_of_environmenta : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/";
    }

    part source_www_astrobotic_com_griffin_1_mission_update : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "https://www.astrobotic.com/griffin-1-mission-update/";
    }

    part source_astrobotic_griffin_rendering_2021 : EvidenceSource {
        doc /* Selected Griffin artist rendering hosted in the February 2021
         * image directory. Used for paired lattice-track topology and visual
         * proportions; no member dimensions or structural rating are given.
         * Detailed stock sizes and bay count are explicit reconstruction estimates. */
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png";
    }

    part source_www_astrobotic_com_griffin_lander : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
    }

    part source_astrobotic_griffin_1_integration_photo_2026_06_15 : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "https://www.astrobotic.com/wp-content/uploads/2026/06/26.06.15_Griffin-1_PressConference_1348_Edit-scaled.jpg";
    }

    part source_linkedin_astrobotic_griffin_solar_setup : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "https://www.linkedin.com/posts/astrobotic_two-solar-panels-integrated-to-griffin-just-activity-7450595533745975296-qBEA";
    }

    part source_www_astrobotic_com_images : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "https://www.astrobotic.com/media-kit/images/";
    }

    part source_www_astrolab_space_flip : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "https://www.astrolab.space/flip/";
    }

    part source_www_astrolab_space_flip_rover : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "https://www.astrolab.space/flip-rover/";
    }

    part source_linkedin_astrolab_flip_power_post : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "https://www.linkedin.com/posts/astrolabspace_our-flip-rover-is-equipped-with-a-622-kwh-activity-7508563602279309312-W5Le";
    }

    part source_www_nasa_gov_astrobotics_griffin_1 : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "https://www.nasa.gov/gallery/astrobotics-griffin-1/";
    }

    part source_www_nasa_gov_clps_flight_astrobotics_griffin_mission_one : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/";
    }

    part source_astrobotic_griffin_1_south_pole_surrogate : EvidenceSource {
        attribute role : EvidenceSourceRole = "VisualAsset";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/environments/south_pole_surrogate.usda";
    }

    part source_lunco_terrain_layered_shader : EvidenceSource {
        attribute role : EvidenceSourceRole = "ShaderAsset";
        attribute locator : SourceLocator = "lunco://shaders/terrain_layered.wgsl";
    }

    part source_griffin_solar_panel_visual_asset : EvidenceSource {
        attribute role : EvidenceSourceRole = "VisualAsset";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/components/lander/griffin_solar_panel_visual.usda";
    }

    part evidence_fcc_001 : RequirementEvidence {
        ref targetRequirement = FlipChassisRequirements::fcc001;
        ref sources = (source_www_astrolab_space_flip);
    }

    part evidence_fcc_002 : RequirementEvidence {
        ref targetRequirement = FlipChassisRequirements::fcc002;
        ref sources = (source_www_astrolab_space_flip);
    }

    part evidence_fcc_003 : RequirementEvidence {
        ref targetRequirement = FlipChassisRequirements::fcc003;
        ref sources = (source_www_astrolab_space_flip);
    }

    part evidence_fcc_004 : RequirementEvidence {
        ref targetRequirement = FlipChassisRequirements::fcc004;
        ref sources = (source_www_astrolab_space_flip);
    }

    part evidence_fcc_005 : RequirementEvidence {
        ref targetRequirement = FlipChassisRequirements::fcc005;
        ref sources = (source_www_astrolab_space_flip);
    }

    part evidence_fgv_001 : RequirementEvidence {
        ref targetRequirement = FlipRequirements::fvg001;
        ref sources = (source_www_astrolab_space_flip, source_www_nasa_gov_clps_flight_astrobotics_griffin_mission_one);
    }

    part evidence_fgv_002 : RequirementEvidence {
        ref targetRequirement = FlipRequirements::fvg002;
        ref sources = (source_www_astrolab_space_flip, source_www_nasa_gov_clps_flight_astrobotics_griffin_mission_one);
    }

    part evidence_fgv_003 : RequirementEvidence {
        ref targetRequirement = FlipRequirements::fvg003;
        ref sources = (source_www_astrolab_space_flip, source_www_nasa_gov_clps_flight_astrobotics_griffin_mission_one);
    }

    part evidence_fgv_004 : RequirementEvidence {
        ref targetRequirement = FlipRequirements::fvg004;
        ref sources = (source_www_astrolab_space_flip, source_www_nasa_gov_clps_flight_astrobotics_griffin_mission_one);
    }

    part evidence_fgv_005 : RequirementEvidence {
        ref targetRequirement = FlipRequirements::fvg005;
        ref sources = (source_www_astrolab_space_flip, source_www_nasa_gov_clps_flight_astrobotics_griffin_mission_one);
    }

    part evidence_fgv_006 : RequirementEvidence {
        ref targetRequirement = FlipRequirements::fvg006;
        ref sources = (source_www_astrolab_space_flip, source_www_nasa_gov_clps_flight_astrobotics_griffin_mission_one);
    }

    part evidence_fgv_007 : RequirementEvidence {
        ref targetRequirement = FlipRequirements::fvg007;
        ref sources = (source_www_astrolab_space_flip, source_www_nasa_gov_clps_flight_astrobotics_griffin_mission_one);
    }

    part evidence_fgv_008 : RequirementEvidence {
        ref targetRequirement = FlipRequirements::fvg008;
        ref sources = (source_www_astrolab_space_flip, source_www_nasa_gov_clps_flight_astrobotics_griffin_mission_one);
    }

    part evidence_fgv_009 : RequirementEvidence {
        ref targetRequirement = FlipRequirements::fvg009;
        ref sources = (source_www_astrolab_space_flip, source_www_nasa_gov_clps_flight_astrobotics_griffin_mission_one, source_astrobotic_griffin_1_scenarios_griffin_1_surface_ops_rhai);
    }

    part evidence_fgv_010 : RequirementEvidence {
        ref targetRequirement = FlipRequirements::fvg010;
        ref sources = (source_www_astrolab_space_flip, source_astrobotic_griffin_1_vehicles_flip_usda, source_astrobotic_griffin_1_requirements_flip_suspension_requirements_sysml, source_astrobotic_griffin_1_scenarios_griffin_1_surface_ops_rhai);
    }

    part evidence_fsp_001 : RequirementEvidence {
        ref targetRequirement = FlipSensorPowerRequirements::fsp001;
        ref sources = (source_www_astrolab_space_flip);
    }

    part evidence_fsp_002 : RequirementEvidence {
        ref targetRequirement = FlipSensorPowerRequirements::fsp002;
        ref sources = (source_www_astrolab_space_flip);
    }

    part evidence_fsp_003 : RequirementEvidence {
        ref targetRequirement = FlipSensorPowerRequirements::fsp003;
        ref sources = (source_www_astrolab_space_flip);
    }

    part evidence_fsp_004 : RequirementEvidence {
        ref targetRequirement = FlipSensorPowerRequirements::fsp004;
        ref sources = (source_www_astrolab_space_flip);
    }

    part evidence_fsp_005 : RequirementEvidence {
        ref targetRequirement = FlipSensorPowerRequirements::fsp005;
        ref sources = (source_www_astrolab_space_flip);
    }

    part evidence_fsp_006 : RequirementEvidence {
        ref targetRequirement = FlipSensorPowerRequirements::fsp006;
        ref sources = (source_www_astrolab_space_flip);
    }

    part evidence_fsp_007 : RequirementEvidence {
        ref targetRequirement = FlipSensorPowerRequirements::fsp007;
        ref sources = (source_linkedin_astrolab_flip_power_post);
    }

    part evidence_fsp_008 : RequirementEvidence {
        ref targetRequirement = FlipSensorPowerRequirements::fsp008;
        ref sources = (source_linkedin_astrolab_flip_power_post);
    }

    part evidence_fsr_001 : RequirementEvidence {
        ref targetRequirement = FlipSuspensionRequirements::fsr001;
        ref sources = (source_www_astrolab_space_flip_rover, source_venturi_space_rovers);
    }

    part evidence_fsr_002 : RequirementEvidence {
        ref targetRequirement = FlipSuspensionRequirements::fsr002;
        ref sources = (source_www_astrolab_space_flip_rover, source_venturi_space_rovers);
    }

    part evidence_fsr_003 : RequirementEvidence {
        ref targetRequirement = FlipSuspensionRequirements::fsr003;
        ref sources = (source_www_astrolab_space_flip_rover, source_venturi_space_rovers);
    }

    part evidence_fsr_004 : RequirementEvidence {
        ref targetRequirement = FlipSuspensionRequirements::fsr004;
        ref sources = (source_www_astrolab_space_flip_rover, source_venturi_space_rovers);
    }

    part evidence_fsr_005 : RequirementEvidence {
        ref targetRequirement = FlipSuspensionRequirements::fsr005;
        ref sources = (source_www_astrolab_space_flip_rover, source_venturi_space_rovers);
    }

    part evidence_fsr_006 : RequirementEvidence {
        ref targetRequirement = FlipSuspensionRequirements::fsr006;
        ref sources = (source_www_astrolab_space_flip_rover, source_venturi_space_rovers);
    }

    part evidence_fsr_007 : RequirementEvidence {
        ref targetRequirement = FlipSuspensionRequirements::fsr007;
        ref sources = (source_www_astrolab_space_flip_rover, source_venturi_space_rovers);
    }

    part evidence_fsr_008 : RequirementEvidence {
        ref targetRequirement = FlipSuspensionRequirements::fsr008;
        ref sources = (source_astrobotic_griffin_1_requirements_flip_requirements_sysml, source_astrobotic_griffin_1_requirements_flip_suspension_requirements_sysml, source_astrobotic_griffin_1_vehicles_flip_usda, source_astrobotic_griffin_1_scenes_griffin_1_surface_ops_usda);
    }

    part source_lunco_mobility_wheel_usda : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "lunco://components/mobility/wheel.usda";
    }
    part source_lunco_mobility_regolith_tire_usda : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "lunco://components/mobility/tires/regolith.usda";
    }

    part evidence_fww_001 : RequirementEvidence {
        ref targetRequirement = FlipWheelRequirements::fww001;
        ref sources = (source_www_astrolab_space_flip);
    }

    part evidence_fww_002 : RequirementEvidence {
        ref targetRequirement = FlipWheelRequirements::fww002;
        ref sources = (source_www_astrolab_space_flip, source_astrobotic_griffin_1_requirements_flip_requirements_sysml, source_astrobotic_griffin_1_vehicles_flip_usda, source_lunco_mobility_wheel_usda, source_lunco_mobility_regolith_tire_usda);
    }

    part evidence_fww_003 : RequirementEvidence {
        ref targetRequirement = FlipWheelRequirements::fww003;
        ref sources = (source_www_astrolab_space_flip);
    }

    part evidence_fww_004 : RequirementEvidence {
        ref targetRequirement = FlipWheelRequirements::fww004;
        ref sources = (source_www_astrolab_space_flip);
    }

    part evidence_fww_005 : RequirementEvidence {
        ref targetRequirement = FlipWheelRequirements::fww005;
        ref sources = (source_www_astrolab_space_flip);
    }

    part evidence_fww_006 : RequirementEvidence {
        ref targetRequirement = FlipWheelRequirements::fww006;
        ref sources = (source_www_astrolab_space_flip);
    }

    part evidence_fww_007 : RequirementEvidence {
        ref targetRequirement = FlipWheelRequirements::fww007;
        ref sources = (source_www_astrolab_space_flip, source_astrobotic_griffin_1_requirements_flip_requirements_sysml, source_astrobotic_griffin_1_vehicles_flip_usda, source_lunco_mobility_wheel_usda, source_lunco_mobility_regolith_tire_usda);
    }

    part evidence_gbc_001 : RequirementEvidence {
        ref targetRequirement = GriffinBusRequirements::gbc001;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gbc_002 : RequirementEvidence {
        ref targetRequirement = GriffinBusRequirements::gbc002;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gbc_003 : RequirementEvidence {
        ref targetRequirement = GriffinBusRequirements::gbc003;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gbc_004 : RequirementEvidence {
        ref targetRequirement = GriffinBusRequirements::gbc004;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gbc_005 : RequirementEvidence {
        ref targetRequirement = GriffinBusRequirements::gbc005;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gbc_006 : RequirementEvidence {
        ref targetRequirement = GriffinBusRequirements::gbc006;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gbc_007 : RequirementEvidence {
        ref targetRequirement = GriffinBusRequirements::gbc007;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gbc_008 : RequirementEvidence {
        ref targetRequirement = GriffinBusRequirements::gbc008;
        ref sources = (source_openusd_org_class_usd_geom_mesh_html, source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml);
    }

    part evidence_gbc_009 : RequirementEvidence {
        ref targetRequirement = GriffinBusRequirements::gbc009;
        ref sources = (source_astrobotic_griffin_1_lander_griffin_bus_visual_usda, source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml);
    }

    part evidence_glr_001 : RequirementEvidence {
        ref targetRequirement = GriffinLanderRequirements::glr001;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_glr_002 : RequirementEvidence {
        ref targetRequirement = GriffinLanderRequirements::glr002;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_glr_003 : RequirementEvidence {
        ref targetRequirement = GriffinLanderRequirements::glr003;
        ref sources = (source_astrobotic_griffin_1_requirements_griffin_lander_requirements_sysml, source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml);
    }

    part evidence_glr_004 : RequirementEvidence {
        ref targetRequirement = GriffinLanderRequirements::glr004;
        ref sources = (source_astrobotic_griffin_propulsion_pug_2022, source_www_astrobotic_com_griffin_lander);
    }

    part evidence_glr_005 : RequirementEvidence {
        ref targetRequirement = GriffinLanderRequirements::glr005;
        ref sources = (source_astrobotic_griffin_1_integration_photo_2026_06_15, source_linkedin_astrobotic_griffin_solar_setup);
    }

    part evidence_glr_006 : RequirementEvidence {
        ref targetRequirement = GriffinLanderRequirements::glr006;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_glr_007 : RequirementEvidence {
        ref targetRequirement = GriffinLanderRequirements::glr007;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_glr_008 : RequirementEvidence {
        ref targetRequirement = GriffinLanderRequirements::glr008;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_glr_009 : RequirementEvidence {
        ref targetRequirement = GriffinLanderRequirements::glr009;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_glr_010 : RequirementEvidence {
        ref targetRequirement = GriffinLanderRequirements::glr010;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_glr_011 : RequirementEvidence {
        ref targetRequirement = GriffinLanderRequirements::glr011;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml);
    }

    part evidence_gll_001 : RequirementEvidence {
        ref targetRequirement = GriffinLandingLegRequirements::gll001;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gll_002 : RequirementEvidence {
        ref targetRequirement = GriffinLandingLegRequirements::gll002;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_pghtech_griffin_hardware_photo);
    }

    part evidence_gll_003 : RequirementEvidence {
        ref targetRequirement = GriffinLandingLegRequirements::gll003;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gll_004 : RequirementEvidence {
        ref targetRequirement = GriffinLandingLegRequirements::gll004;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gll_005 : RequirementEvidence {
        ref targetRequirement = GriffinLandingLegRequirements::gll005;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gll_006 : RequirementEvidence {
        ref targetRequirement = GriffinLandingLegRequirements::gll006;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_science_nasa_gov_astrobotic_lunar_landers_pug_pdf, source_pghtech_griffin_hardware_photo);
    }

    part evidence_gll_007 : RequirementEvidence {
        ref targetRequirement = GriffinLandingLegRequirements::gll007;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_pghtech_griffin_hardware_photo);
    }

    part evidence_gll_008 : RequirementEvidence {
        ref targetRequirement = GriffinLandingLegRequirements::gll008;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gll_009 : RequirementEvidence {
        ref targetRequirement = GriffinLandingLegRequirements::gll009;
        ref sources = (source_www_astrobotic_com_griffin_lander,
            source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml);
    }

    part evidence_gpp_001 : RequirementEvidence {
        ref targetRequirement = GriffinPropulsionRequirements::gpp001;
        ref sources = (source_astrobotic_griffin_propulsion_pug_2022, source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gpp_002 : RequirementEvidence {
        ref targetRequirement = GriffinPropulsionRequirements::gpp002;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gpp_003 : RequirementEvidence {
        ref targetRequirement = GriffinPropulsionRequirements::gpp003;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gpp_004 : RequirementEvidence {
        ref targetRequirement = GriffinPropulsionRequirements::gpp004;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gpp_005 : RequirementEvidence {
        ref targetRequirement = GriffinPropulsionRequirements::gpp005;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gpp_006 : RequirementEvidence {
        ref targetRequirement = GriffinPropulsionRequirements::gpp006;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gpp_007 : RequirementEvidence {
        ref targetRequirement = GriffinPropulsionRequirements::gpp007;
        ref sources = (source_astrobotic_griffin_propulsion_pug_2022, source_www_astrobotic_com_griffin_lander,
            source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml);
    }

    part evidence_gpp_008 : RequirementEvidence {
        ref targetRequirement = GriffinPropulsionRequirements::gpp008;
        ref sources = (source_astrobotic_griffin_propulsion_pug_2022, source_astrobotic_griffin_1_tests_griffin_propulsion_requirements_rhai,
            source_astrobotic_griffin_1_vehicles_griffin_1_usda);
    }

    part evidence_ges_001 : RequirementEvidence {
        ref targetRequirement = GriffinPropulsionRequirements::ges001;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_ges_002 : RequirementEvidence {
        ref targetRequirement = GriffinPropulsionRequirements::ges002;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_ges_003 : RequirementEvidence {
        ref targetRequirement = GriffinPropulsionRequirements::ges003;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_ges_004 : RequirementEvidence {
        ref targetRequirement = GriffinPropulsionRequirements::ges004;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_ges_005 : RequirementEvidence {
        ref targetRequirement = GriffinPropulsionRequirements::ges005;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_ges_006 : RequirementEvidence {
        ref targetRequirement = GriffinPropulsionRequirements::ges006;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_ges_007 : RequirementEvidence {
        ref targetRequirement = GriffinPropulsionRequirements::ges007;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_grr_001 : RequirementEvidence {
        ref targetRequirement = GriffinRampRequirements::grr001;
        ref sources = (source_astrobotic_griffin_rendering_2021, source_www_astrobotic_com_griffin_lander, source_astrobotic_griffin_1_requirements_griffin_ramp_requirements_sysml);
    }

    part evidence_grr_002 : RequirementEvidence {
        ref targetRequirement = GriffinRampRequirements::grr002;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_astrobotic_griffin_1_requirements_griffin_ramp_requirements_sysml);
    }

    part evidence_grr_003 : RequirementEvidence {
        ref targetRequirement = GriffinRampRequirements::grr003;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_astrobotic_griffin_1_requirements_griffin_ramp_requirements_sysml, source_astrobotic_griffin_1_requirements_flip_requirements_sysml);
    }

    part evidence_grr_004 : RequirementEvidence {
        ref targetRequirement = GriffinRampRequirements::grr004;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_astrobotic_griffin_1_requirements_griffin_bus_requirements_sysml, source_astrobotic_griffin_1_requirements_griffin_ramp_requirements_sysml);
    }

    part evidence_grr_005 : RequirementEvidence {
        ref targetRequirement = GriffinRampRequirements::grr005;
        ref sources = (source_astrobotic_griffin_1_requirements_griffin_ramp_requirements_sysml);
    }

    part evidence_grr_006 : RequirementEvidence {
        ref targetRequirement = GriffinRampRequirements::grr006;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_astrobotic_griffin_1_requirements_griffin_ramp_requirements_sysml);
    }

    part evidence_grr_007 : RequirementEvidence {
        ref targetRequirement = GriffinRampRequirements::grr007;
        ref sources = (source_astrobotic_griffin_rendering_2021, source_astrobotic_griffin_1_tools_griffin_visual_builder_rhai, source_astrobotic_griffin_1_tests_griffin_ramp_requirements_rhai);
    }

    part evidence_grr_008 : RequirementEvidence {
        ref targetRequirement = GriffinRampRequirements::grr008;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_astrobotic_griffin_1_requirements_griffin_ramp_requirements_sysml);
    }

    part evidence_grr_009 : RequirementEvidence {
        ref targetRequirement = GriffinRampRequirements::grr009;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_astrobotic_griffin_1_requirements_griffin_ramp_requirements_sysml);
    }

    part evidence_grr_010 : RequirementEvidence {
        ref targetRequirement = GriffinRampRequirements::grr010;
        ref sources = (source_www_astrobotic_com_griffin_1_lunar_lander_unveiled_ahead_of_environmenta, source_www_astrobotic_com_griffin_lander, source_astrobotic_griffin_1_research_griffin_1_assumptions_md);
    }

    part evidence_grr_011 : RequirementEvidence {
        ref targetRequirement = GriffinRampRequirements::grr011;
        ref sources = (source_astrobotic_griffin_1_requirements_griffin_ramp_requirements_sysml);
    }

    part evidence_grr_012 : RequirementEvidence {
        ref targetRequirement = GriffinRampRequirements::grr012;
        ref sources = (source_www_astrobotic_com_griffin_1_lunar_lander_unveiled_ahead_of_environmenta, source_www_astrobotic_com_griffin_lander, source_astrobotic_griffin_1_research_griffin_1_assumptions_md, source_astrobotic_griffin_1_vehicles_griffin_1_usda);
    }

    part evidence_grr_013 : RequirementEvidence {
        ref targetRequirement = GriffinRampRequirements::grr013;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_astrobotic_griffin_1_requirements_griffin_ramp_requirements_sysml);
    }

    part evidence_grr_014 : RequirementEvidence {
        ref targetRequirement = GriffinRampRequirements::grr014;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_astrobotic_griffin_1_requirements_griffin_ramp_requirements_sysml, source_astrobotic_griffin_1_tools_griffin_visual_builder_rhai);
    }

    part evidence_grr_015 : RequirementEvidence {
        ref targetRequirement = GriffinRampRequirements::grr015;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_astrobotic_griffin_1_requirements_griffin_ramp_requirements_sysml, source_astrobotic_griffin_1_tools_griffin_visual_builder_rhai);
    }

    part evidence_grr_016 : RequirementEvidence {
        ref targetRequirement = GriffinRampRequirements::grr016;
        ref sources = (source_astrobotic_griffin_1_requirements_griffin_ramp_requirements_sysml,
            source_astrobotic_griffin_1_vehicles_griffin_1_usda,
            source_astrobotic_griffin_1_tests_griffin_ramp_requirements_rhai);
    }

    part evidence_grr_017 : RequirementEvidence {
        ref targetRequirement = GriffinRampRequirements::grr017;
        ref sources = (source_astrobotic_griffin_1_requirements_griffin_ramp_requirements_sysml,
            source_astrobotic_griffin_1_vehicles_griffin_1_usda,
            source_astrobotic_griffin_1_scenarios_griffin_1_surface_ops_rhai);
    }

    part evidence_grr_018 : RequirementEvidence {
        ref targetRequirement = GriffinRampRequirements::grr018;
        ref sources = (source_astrobotic_griffin_rendering_2021, source_astrobotic_griffin_1_requirements_griffin_ramp_requirements_sysml,
            source_astrobotic_griffin_1_components_lander_griffin_ramp_section_visual_usda);
    }

    part evidence_grr_019 : RequirementEvidence {
        ref targetRequirement = GriffinRampRequirements::grr019;
        ref sources = (source_astrobotic_griffin_rendering_2021, source_astrobotic_griffin_1_requirements_griffin_ramp_requirements_sysml,
            source_astrobotic_griffin_1_components_lander_griffin_ramp_section_visual_usda,
            source_astrobotic_griffin_1_tools_griffin_visual_builder_rhai,
            source_astrobotic_griffin_1_research_griffin_1_assumptions_md);
    }

    part evidence_gr_001 : RequirementEvidence {
        ref targetRequirement = GriffinFunctionalRequirements::gr001;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gr_002 : RequirementEvidence {
        ref targetRequirement = GriffinFunctionalRequirements::gr002;
        ref sources = (source_www_astrolab_space_flip);
    }

    part evidence_gr_003 : RequirementEvidence {
        ref targetRequirement = GriffinFunctionalRequirements::gr003;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gr_004 : RequirementEvidence {
        ref targetRequirement = GriffinFunctionalRequirements::gr004;
    }

    part evidence_gr_005 : RequirementEvidence {
        ref targetRequirement = GriffinAssuranceRequirements::gr005;
        ref sources = (source_astrobotic_griffin_1_requirements_griffin_assurance_requirements_sysml, source_lunco_sysml_requirements_tool);
    }

    part evidence_gr_006 : RequirementEvidence {
        ref targetRequirement = GriffinFunctionalRequirements::gr006;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_www_astrolab_space_flip);
    }

    part evidence_gr_007 : RequirementEvidence {
        ref targetRequirement = GriffinFunctionalRequirements::gr007;
    }

    part evidence_gr_008 : RequirementEvidence {
        ref targetRequirement = GriffinSimulationAccuracyRequirements::gr008;
    }

    part evidence_gr_009 : RequirementEvidence {
        ref targetRequirement = GriffinFunctionalRequirements::gr009;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gr_010 : RequirementEvidence {
        ref targetRequirement = GriffinMechanicalRequirements::gr010;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gr_011 : RequirementEvidence {
        ref targetRequirement = GriffinMechanicalRequirements::gr011;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gr_012 : RequirementEvidence {
        ref targetRequirement = GriffinMechanicalRequirements::gr012;
    }

    part evidence_gr_013 : RequirementEvidence {
        ref targetRequirement = GriffinAssuranceRequirements::gr013;
    }

    part evidence_gr_014 : RequirementEvidence {
        ref targetRequirement = GriffinAssuranceRequirements::gr014;
    }

    part evidence_gr_015 : RequirementEvidence {
        ref targetRequirement = GriffinVisualRequirements::gr015;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gr_016 : RequirementEvidence {
        ref targetRequirement = GriffinVisualRequirements::gr016;
        ref sources = (source_astrobotic_griffin_1_integration_photo_2026_06_15, source_linkedin_astrobotic_griffin_solar_setup);
    }

    part evidence_gr_017 : RequirementEvidence {
        ref targetRequirement = GriffinMechanicalRequirements::gr017;
    }

    part evidence_gr_018 : RequirementEvidence {
        ref targetRequirement = GriffinMechanicalRequirements::gr018;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gr_019 : RequirementEvidence {
        ref targetRequirement = GriffinMechanicalRequirements::gr019;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gr_020 : RequirementEvidence {
        ref targetRequirement = GriffinVisualRequirements::gr020;
    }

    part evidence_gr_021 : RequirementEvidence {
        ref targetRequirement = GriffinSimulationAccuracyRequirements::gr021;
    }

    part evidence_gr_022 : RequirementEvidence {
        ref targetRequirement = GriffinSimulationAccuracyRequirements::gr022;
    }

    part evidence_gr_023 : RequirementEvidence {
        ref targetRequirement = GriffinSimulationAccuracyRequirements::gr023;
    }

    part evidence_gr_024 : RequirementEvidence {
        ref targetRequirement = GriffinMechanicalRequirements::gr024;
    }

    part evidence_gr_025 : RequirementEvidence {
        ref targetRequirement = GriffinMechanicalRequirements::gr025;
    }

    part evidence_gr_026 : RequirementEvidence {
        ref targetRequirement = GriffinFunctionalRequirements::gr026;
    }

    part evidence_gr_027 : RequirementEvidence {
        ref targetRequirement = GriffinSimulationAccuracyRequirements::gr027;
    }

    part evidence_gr_028 : RequirementEvidence {
        ref targetRequirement = GriffinFunctionalRequirements::gr028;
    }

    part evidence_gr_029 : RequirementEvidence {
        ref targetRequirement = GriffinAssuranceRequirements::gr029;
    }

    part evidence_gr_030 : RequirementEvidence {
        ref targetRequirement = GriffinAssuranceRequirements::gr030;
    }

    part evidence_gr_031 : RequirementEvidence {
        ref targetRequirement = GriffinSimulationAccuracyRequirements::gr031;
    }

    part evidence_gr_032 : RequirementEvidence {
        ref targetRequirement = GriffinVisualRequirements::gr032;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gr_033 : RequirementEvidence {
        ref targetRequirement = GriffinVisualRequirements::gr033;
        ref sources = (source_www_astrobotic_com_griffin_1_mission_update);
    }

    part evidence_gr_034 : RequirementEvidence {
        ref targetRequirement = GriffinFunctionalRequirements::gr034;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_astrobotic_griffin_1_requirements_griffin_ramp_requirements_sysml, source_astrobotic_griffin_1_requirements_griffin_requirements_sysml);
    }

    part evidence_gr_035 : RequirementEvidence {
        ref targetRequirement = GriffinFunctionalRequirements::gr035;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_www_nasa_gov_clps_flight_astrobotics_griffin_mission_one, source_astrobotic_griffin_1_scenes_griffin_1_surface_ops_usda, source_astrobotic_griffin_1_tools_griffin_visual_builder_rhai);
    }

    part evidence_gr_036 : RequirementEvidence {
        ref targetRequirement = GriffinSimulationAccuracyRequirements::gr036;
        ref sources = (source_astrobotic_griffin_1_requirements_griffin_simulation_accuracy_requiremen);
    }

    part evidence_gv_001 : RequirementEvidence {
        ref targetRequirement = GriffinVisualRequirements::gv001;
    }

    part evidence_gv_002 : RequirementEvidence {
        ref targetRequirement = GriffinVisualRequirements::gv002;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gv_003 : RequirementEvidence {
        ref targetRequirement = GriffinVisualRequirements::gv003;
        ref sources = (source_astrobotic_griffin_1_integration_photo_2026_06_15, source_linkedin_astrobotic_griffin_solar_setup);
    }

    part evidence_gv_004 : RequirementEvidence {
        ref targetRequirement = GriffinVisualRequirements::gv004;
    }

    part evidence_gv_005 : RequirementEvidence {
        ref targetRequirement = GriffinVisualRequirements::gv005;
    }

    part evidence_gv_006 : RequirementEvidence {
        ref targetRequirement = GriffinVisualRequirements::gv006;
        ref sources = (source_www_nasa_gov_clps_flight_astrobotics_griffin_mission_one, source_astrobotic_griffin_1_south_pole_surrogate, source_lunco_terrain_layered_shader);
    }

    part evidence_gv_007 : RequirementEvidence {
        ref targetRequirement = GriffinVisualRequirements::gv007;
    }

    part evidence_gsa_001 : RequirementEvidence {
        ref targetRequirement = GriffinSolarRequirements::gsa001;
        ref sources = (source_astrobotic_griffin_1_integration_photo_2026_06_15, source_linkedin_astrobotic_griffin_solar_setup);
    }

    part evidence_gsa_002 : RequirementEvidence {
        ref targetRequirement = GriffinSolarRequirements::gsa002;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gsa_003 : RequirementEvidence {
        ref targetRequirement = GriffinSolarRequirements::gsa003;
        ref sources = (source_astrobotic_griffin_1_integration_photo_2026_06_15, source_linkedin_astrobotic_griffin_solar_setup);
    }

    part evidence_gsa_004 : RequirementEvidence {
        ref targetRequirement = GriffinSolarRequirements::gsa004;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gsa_005 : RequirementEvidence {
        ref targetRequirement = GriffinSolarRequirements::gsa005;
        ref sources = (source_astrobotic_griffin_1_integration_photo_2026_06_15, source_linkedin_astrobotic_griffin_solar_setup, source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml);
    }

    part evidence_gsa_006 : RequirementEvidence {
        ref targetRequirement = GriffinSolarRequirements::gsa006;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gsa_007 : RequirementEvidence {
        ref targetRequirement = GriffinSolarRequirements::gsa007;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gsa_008 : RequirementEvidence {
        ref targetRequirement = GriffinSolarRequirements::gsa008;
        ref sources = (source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gsa_009 : RequirementEvidence {
        ref targetRequirement = GriffinSolarRequirements::gsa009;
        ref sources = (source_www_astrobotic_com_griffin_lander,
            source_griffin_solar_panel_visual_asset);
    }

    part evidence_gsa_010 : RequirementEvidence {
        ref targetRequirement = GriffinSolarRequirements::gsa010;
        ref sources = (source_linkedin_astrobotic_griffin_solar_setup,
            source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gpt_001 : RequirementEvidence {
        ref targetRequirement = GriffinTankRequirements::gpt001;
        ref sources = (source_www_astrobotic_com_images, source_www_nasa_gov_astrobotics_griffin_1);
    }

    part evidence_gpt_002 : RequirementEvidence {
        ref targetRequirement = GriffinTankRequirements::gpt002;
        ref sources = (source_www_astrobotic_com_images, source_www_nasa_gov_astrobotics_griffin_1);
    }

    part evidence_gpt_003 : RequirementEvidence {
        ref targetRequirement = GriffinTankRequirements::gpt003;
        ref sources = (source_www_astrobotic_com_images, source_www_nasa_gov_astrobotics_griffin_1);
    }

    part evidence_gpt_004 : RequirementEvidence {
        ref targetRequirement = GriffinTankRequirements::gpt004;
        ref sources = (source_www_astrobotic_com_images, source_www_nasa_gov_astrobotics_griffin_1);
    }

    part evidence_gpt_005 : RequirementEvidence {
        ref targetRequirement = GriffinTankRequirements::gpt005;
        ref sources = (source_www_astrobotic_com_griffin_1_mission_update, source_www_astrobotic_com_griffin_lander);
    }

    part evidence_gpt_006 : RequirementEvidence {
        ref targetRequirement = GriffinTankRequirements::gpt006;
        ref sources = (source_www_astrobotic_com_griffin_1_mission_update, source_www_astrobotic_com_images);
    }

    part evidence_gpt_007 : RequirementEvidence {
        ref targetRequirement = GriffinTankRequirements::gpt007;
        ref sources = (source_www_astrobotic_com_images, source_www_nasa_gov_astrobotics_griffin_1);
    }

    part evidence_gpt_008 : RequirementEvidence {
        ref targetRequirement = GriffinTankRequirements::gpt008;
        ref sources = (source_www_astrobotic_com_images, source_www_nasa_gov_astrobotics_griffin_1);
    }

    part evidence_gpt_009 : RequirementEvidence {
        ref targetRequirement = GriffinTankRequirements::gpt009;
        ref sources = (source_www_astrobotic_com_images, source_www_nasa_gov_astrobotics_griffin_1);
    }

    part evidence_gpt_010 : RequirementEvidence {
        ref targetRequirement = GriffinTankRequirements::gpt010;
        ref sources = (source_www_astrobotic_com_images, source_www_nasa_gov_astrobotics_griffin_1);
    }

    part evidence_gpt_011 : RequirementEvidence {
        ref targetRequirement = GriffinTankRequirements::gpt011;
        ref sources = (source_www_astrobotic_com_images, source_www_nasa_gov_astrobotics_griffin_1);
    }

    part evidence_gvc_001 : RequirementEvidence {
        ref targetRequirement = GriffinVisualConfigurationRequirements::gvc001;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_science_nasa_gov_astrobotic_lunar_landers_pug_pdf);
    }

    part evidence_gvc_002 : RequirementEvidence {
        ref targetRequirement = GriffinVisualConfigurationRequirements::gvc002;
        ref sources = (source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml);
    }

    part evidence_gvc_003 : RequirementEvidence {
        ref targetRequirement = GriffinVisualConfigurationRequirements::gvc003;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml);
    }

    part evidence_gvc_004 : RequirementEvidence {
        ref targetRequirement = GriffinVisualConfigurationRequirements::gvc004;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml);
    }

    part evidence_gvc_005 : RequirementEvidence {
        ref targetRequirement = GriffinVisualConfigurationRequirements::gvc005;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml);
    }

    part evidence_gvc_006 : RequirementEvidence {
        ref targetRequirement = GriffinVisualConfigurationRequirements::gvc006;
        ref sources = (source_astrobotic_griffin_1_integration_photo_2026_06_15, source_linkedin_astrobotic_griffin_solar_setup, source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml);
    }

    part evidence_gvc_007 : RequirementEvidence {
        ref targetRequirement = GriffinVisualConfigurationRequirements::gvc007;
        ref sources = (source_www_astrobotic_com_images, source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml);
    }

    part evidence_gvc_008 : RequirementEvidence {
        ref targetRequirement = GriffinVisualConfigurationRequirements::gvc008;
        ref sources = (source_astrobotic_griffin_propulsion_pug_2022, source_www_astrobotic_com_griffin_lander, source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml);
    }

    part evidence_gvc_009 : RequirementEvidence {
        ref targetRequirement = GriffinVisualConfigurationRequirements::gvc009;
        ref sources = (source_www_astrobotic_com_griffin_lander, source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml);
    }

    part evidence_gvc_010 : RequirementEvidence {
        ref targetRequirement = GriffinVisualConfigurationRequirements::gvc010;
        ref sources = (source_astrobotic_griffin_1_tests_griffin_bus_requirements_rhai, source_astrobotic_griffin_1_tests_griffin_lander_requirements_rhai);
    }

    part evidence_gvc_011 : RequirementEvidence {
        ref targetRequirement = GriffinVisualConfigurationRequirements::gvc011;
        ref sources = (source_astrobotic_griffin_1_requirements_griffin_requirement_sources_sysml, source_astrobotic_griffin_1_twin_toml);
    }

    part evidence_gvc_012 : RequirementEvidence {
        ref targetRequirement = GriffinVisualConfigurationRequirements::gvc012;
        ref sources = (source_www_astrobotic_com_images, source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml);
    }

    part evidence_gvc_013 : RequirementEvidence {
        ref targetRequirement = GriffinVisualConfigurationRequirements::gvc013;
        ref sources = (source_openusd_org_class_usd_geom_mesh_html, source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml);
    }

    part evidence_gvc_014 : RequirementEvidence {
        ref targetRequirement = GriffinVisualConfigurationRequirements::gvc014;
        ref sources = (source_openusd_org_class_usd_geom_mesh_html, source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml);
    }

    part evidence_gvc_015 : RequirementEvidence {
        ref targetRequirement = GriffinVisualConfigurationRequirements::gvc015;
        ref sources = (source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml);
    }

    part evidence_gbc_010 : RequirementEvidence {
        ref targetRequirement = GriffinBusRequirements::gbc010;
        ref sources = (source_astrobotic_griffin_1_requirements_griffin_bus_requirements_sysml, source_astrobotic_griffin_1_tests_griffin_bus_requirements_rhai);
    }

    part evidence_gbc_011 : RequirementEvidence {
        ref targetRequirement = GriffinBusRequirements::gbc011;
        ref sources = (source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml, source_astrobotic_griffin_1_tests_griffin_bus_requirements_rhai);
    }

    part evidence_gbc_012 : RequirementEvidence {
        ref targetRequirement = GriffinBusRequirements::gbc012;
        ref sources = (source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml, source_astrobotic_griffin_1_tests_griffin_bus_requirements_rhai);
    }

    part evidence_mb_001 : RequirementEvidence {
        ref targetRequirement = MoonBaseProjectRequirements::mb001;
    }

    part evidence_mb_002 : RequirementEvidence {
        ref targetRequirement = MoonBaseProjectRequirements::mb002;
    }

    part evidence_mb_003 : RequirementEvidence {
        ref targetRequirement = MoonBaseProjectRequirements::mb003;
    }

    part evidence_mb_004 : RequirementEvidence {
        ref targetRequirement = MoonBaseProjectRequirements::mb004;
    }

    part evidence_gr_037 : RequirementEvidence {
        ref targetRequirement = GriffinSimulationAccuracyRequirements::gr037;
        ref sources = (source_astrobotic_griffin_1_requirements_griffin_simulation_accuracy_requiremen, source_astrobotic_griffin_1_requirements_griffin_requirements_sysml);
    }

    part evidence_gr_038 : RequirementEvidence {
        ref targetRequirement = GriffinSimulationAccuracyRequirements::gr038;
        ref sources = (source_astrobotic_griffin_1_requirements_griffin_simulation_accuracy_requiremen, source_astrobotic_griffin_1_scenes_griffin_1_surface_ops_usda, source_astrobotic_griffin_1_scenarios_griffin_1_surface_ops_rhai);
    }


    part source_flip_cad_study : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "twin://astrobotic-griffin-1/requirements/flip_cad_requirements.sysml";
    }

    part evidence_fr_001 : RequirementEvidence {
        ref targetRequirement = FlipCadRequirements::fr001;
        ref sources = (source_flip_cad_study);
    }

    part evidence_fr_002 : RequirementEvidence {
        ref targetRequirement = FlipCadRequirements::fr002;
        ref sources = (source_flip_cad_study);
    }

    part evidence_fr_003 : RequirementEvidence {
        ref targetRequirement = FlipCadRequirements::fr003;
        ref sources = (source_flip_cad_study);
    }

    part evidence_fr_004 : RequirementEvidence {
        ref targetRequirement = FlipCadRequirements::fr004;
        ref sources = (source_flip_cad_study);
    }

    part evidence_fr_005 : RequirementEvidence {
        ref targetRequirement = FlipCadRequirements::fr005;
        ref sources = (source_flip_cad_study);
    }

    part evidence_fr_006 : RequirementEvidence {
        ref targetRequirement = FlipCadRequirements::fr006;
        ref sources = (source_flip_cad_study);
    }

    part evidence_fr_007 : RequirementEvidence {
        ref targetRequirement = FlipCadRequirements::fr007;
        ref sources = (source_flip_cad_study);
    }

    part evidence_fr_008 : RequirementEvidence {
        ref targetRequirement = FlipCadRequirements::fr008;
        ref sources = (source_flip_cad_study);
    }

    part evidence_fr_009 : RequirementEvidence {
        ref targetRequirement = FlipCadRequirements::fr009;
        ref sources = (source_flip_cad_study);
    }

    part evidence_fr_010 : RequirementEvidence {
        ref targetRequirement = FlipCadRequirements::fr010;
        ref sources = (source_flip_cad_study);
    }

    part evidence_fr_011 : RequirementEvidence {
        ref targetRequirement = FlipCadRequirements::fr011;
        ref sources = (source_flip_cad_study);
    }

    part evidence_fr_012 : RequirementEvidence {
        ref targetRequirement = FlipCadRequirements::fr012;
        ref sources = (source_flip_cad_study);
    }

    part evidence_fr_013 : RequirementEvidence {
        ref targetRequirement = FlipCadRequirements::fr013;
        ref sources = (source_flip_cad_study);
    }

    part evidence_fr_014 : RequirementEvidence {
        ref targetRequirement = FlipCadRequirements::fr014;
        ref sources = (source_flip_cad_study);
    }

    part evidence_fr_015 : RequirementEvidence {
        ref targetRequirement = FlipCadRequirements::fr015;
        ref sources = (source_flip_cad_study);
    }

    part evidence_fr_016 : RequirementEvidence {
        ref targetRequirement = FlipCadRequirements::fr016;
        ref sources = (source_flip_cad_study);
    }

    part evidence_gll_010 : RequirementEvidence {
        ref targetRequirement = GriffinLandingLegRequirements::gll010;
        ref sources = (source_astrobotic_griffin_1_requirements_griffin_visual_configuration_sysml);
    }

    part evidence_gr_039 : RequirementEvidence {
        ref targetRequirement = GriffinSimulationAccuracyRequirements::gr039;
        ref sources = (source_astrobotic_griffin_1_requirements_griffin_simulation_accuracy_requiremen);
    }
    part source_pghtech_griffin_hardware_photo : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png";
    }
}
