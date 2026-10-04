package GriffinPropulsionRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::String;
    private import ScalarValues::Boolean;
    private import ScalarValues::Integer;
    private import VectorValues::CartesianThreeVectorValue;
    private import GriffinRequirementSources::TwinAssetPath;
    private import GriffinRequirementSources::UsdPrimPath;
    private import GriffinLanderRequirements::GriffinLanderComponent;
    private import GriffinVisualConfigurationRequirements::GriffinVisualConfiguration;

    attribute def Direction :> CartesianThreeVectorValue;
    enum def GriffinEngineVisualMember { Bell; Throat; }

    part def GriffinEngineControlStudy {
        doc /* Integration study, not current flight performance. The existing
         * chamber uses 2940 m/s effective exhaust velocity and 0.96 combustion
         * efficiency; the feed models admit 8 + 21 kg/s at 2.5 MPa tank pressure,
         * rising to sqrt(3.0/2.5) times that flow at the authored 3.0 MPa maximum.
         * The resulting 31.7685 kg/s bound is rounded upward to 32 kg/s for the
         * scalar actuator contract. This accepts the entire modeled feed range
         * without rejecting full pilot demand. No manufacturer rating is
         * inferred: current seven-engine unit ratings are unpublished here.
         * Architecture/fuel reference: Astrobotic August 2021 PUG v5.02 p.26,
         * https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf.
         * Equation sources: lunco://models/LunCo/Propulsion/Turbopump.mo and
         * CombustionChamber.mo. Those pump equations are an acknowledged
         * integration approximation for the publicly pressure-fed architecture.
         */
        attribute exhaustVelocityMps : Real = 2940.0;
        attribute combustionEfficiency : Real = .96;
        attribute actuatorFlowEnvelopeKgs : Real = 32.0;
        attribute actuatorForceEnvelopeN : Real = actuatorFlowEnvelopeKgs * exhaustVelocityMps * combustionEfficiency;
        // One input edge held for 5 s must still be climbing at the end,
        // rather than merely reaching a transient hop peak. 2 m clearance
        // and 2 m/s upward speed are study acceptance thresholds for this
        // initial lunar surface fixture, not a flight qualification criterion.
        attribute burnDurationS : Real = 5.0;
        attribute releaseDurationS : Real = 3.0;
        attribute minimumSustainedLiftM : Real = 2.0;
        attribute minimumEndVerticalSpeedMps : Real = 2.0;
        attribute extinguishedThrustThresholdN : Real = 100.0;
        attribute touchdownTimeoutS : Real = 150.0;
    }

    part def GriffinMainPropulsionAssembly {
        attribute usdRootPath : UsdPrimPath = "/World/Griffin1/Nozzle/MainEngineCluster";
        attribute componentAsset : TwinAssetPath = "components/lander/griffin_engine_bell_visual.usda";
        attribute childNames : GriffinEngineVisualMember[2] =
            ("Bell", "Throat");
        attribute bellRadiusM : Real = 0.34;
        attribute bellHeightM : Real = 0.52;
        attribute throatRadiusM : Real = 0.12;
        attribute throatHeightM : Real = 0.16;
        // Neck starts at the bell throat plane and extends upwards; the old
        // solid cylinder started inside the expanding bore and capped it.
        // Radius/height and the shared 6 mm visual wall remain reconstruction
        // estimates. Topology follows the throat-to-diverging-exit flow path:
        // https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/nozzle-design/
        attribute throatCenterYM : Real = GriffinMainPropulsionAssembly::bellHeightM / 2.0 + GriffinMainPropulsionAssembly::throatHeightM / 2.0;
        attribute bellAxis : Direction = (0.0, 1.0, 0.0);
        // Estimated bell contour, using LunCo.Propulsion.BellNozzle's law:
        // r(s)=throatRadiusM+(bellRadiusM-throatRadiusM)*s^bellContourExponent.
        // s=0 at the throat, s=1 at the downward-facing open exit.
        // .55 is the library approximation, not a supplier-qualified Rao design.
        // 16 axial intervals resolve the curve; 6 mm is a visual shell estimate.
        attribute bellContourExponent : Real = .55;
        attribute bellAxialSegments : Integer = 16;
        attribute bellVisualWallThicknessM : Real = .006;
        attribute bellAngularSegments : Integer = 48;
        // Estimated shading crease; keeps the physical rim sharp.
        attribute bellNormalCreaseAngleDeg : Real = 35.0;
        /* Dark gray nozzle appearance is an artistic estimate from the
         * selected Astrobotic rendering, not a material grade, emissivity or
         * temperature-dependent optical property. This prim displayColor
         * serves inspection; normal shading on both hollow shells reuses
         * Nozzle_Mat from lunco://components/propulsion/rocket_engine_visual.usda.
         * No duplicate nozzle shader or engineering optical data is authored.
         * https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png */
        attribute bellDisplayColor : Real[3] = (.20, .22, .25);

        // Hypergolic family from PUG p.26 (M20 / MON3). Palette is heuristic;
        // 2.0 reference O/F is a provisional chemistry estimate, not flight data.
        attribute plumeFuelFamily : Real = 3;
        attribute plumeStoichiometricMixtureRatio : Real = 2.0;
        attribute minimumBellClearanceM : Real = 0.20;
        // Conservative reconstruction allowance to all named tank shapes,
        // including cradle/pad, lower fittings and mounting brackets. A 20 mm
        // gap is a study packaging allowance, not a thermal/flight margin.
        attribute minimumTankHardwareClearanceM : Real = 0.02;
        // The skirt bounds the engine cluster; the central adapter is an
        // internal structural shell and must not be treated as its boundary.
        attribute clusterOuterRadiusM : Real = GriffinEngineSkirtComponent::railLengthM / 2.0;
    }

    // The skirt is a visual/structural presentation component around the
    // engine adapter plate.  It is deliberately specified independently from
    // the bells: the flight model owns thrust and collision, while this frame
    // makes the seven-bell cluster legible and provides a stable placement
    // datum for the Editor.
    part def GriffinEngineSkirtComponent {
        attribute usdRootPath : String = "/World/Griffin1/Nozzle/MainEngineCluster";
        attribute componentRootName : String = "EngineSkirt";
        attribute perimeterRailName : String = "PerimeterRail";
        // Continuous mitered octagon, sharing the normalized outerBodyProfileCoordinates
        // of GriffinVisualConfiguration. The 3.44 m across-flats envelope is
        // inset 80 mm from the estimated 3.60 m bus on each cardinal side.
        // This avoids a square frame extending outside the bus chamfers.
        // PGH photo: https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png
        // ESA depiction: https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander
        // Both establish the clipped footprint qualitatively; 80 mm stock,
        // envelope and taper remain packaging estimates, not measured hardware.
        attribute railLengthM : Real = 3.44;
        attribute railWidthM : Real = 0.08;
        attribute railHeightM : Real = 0.08;
        attribute shellName : String = "EngineSkirtShell";
        attribute adapterPlateName : String = "EngineAdapterPlate";
        attribute adapterPlateWidthM : Real = 2.84;
        attribute adapterPlateDepthM : Real = 2.84;
        attribute adapterPlateHeightM : Real = 0.12;
        // The PGH hardware photograph shows an open underside, rather than
        // a deep opaque shroud: https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png.
        // 80 mm frame stock, a 120 mm shallow fairing, and 60 mm taper are
        // explicit visualization estimates, not calibrated stock dimensions.
        attribute shellDepthM : Real = 0.12;
        attribute shellBottomInsetM : Real = 0.06;
        attribute shellUpperYM : Real = componentLocalCenterYM + railHeightM / 2.0;
        attribute shellLowerYM : Real = shellUpperYM - shellDepthM;
        // Rail tops seat against the lower bus skirt at the estimated
        // adapter plane; do not surround the expanding nozzle exits.
        attribute componentLocalCenterYM : Real = adapterPlateCenterYM;
        attribute minimumSkirtBellClearanceM : Real = 0.10;
        // Seat the plate's lower face at the upper throat end. A plate
        // centered on the rail plane would intersect all bell walls.
        attribute adapterPlateCenterYM : Real = GriffinMainPropulsionAssembly::throatCenterYM + GriffinMainPropulsionAssembly::throatHeightM / 2.0 + adapterPlateHeightM / 2.0;
        // Estimated minimum exposure below the shroud, to reject geometry
        // that encloses the bell exits while passing simple dimension checks.
        attribute minimumVisibleBellHeightFraction : Real = 0.30;
        attribute colliderPolicy : String = "render-only frame; no physics collision or thrust authority";
    }

    part def GriffinAttitudeEngineAssembly {
        doc /* Pending RCS integration requirements, deferred by the user:
         * retain twelve existing force-actuator identities, command connections
         * and force axes; render one hollow nozzle per physics actuator, with
         * exhaust opposite thrust. No additional Twin-authored flame geometry.
         * Reference the shared LunCoSim engine visual and bind its geometry,
         * colour and light inputs to RCSJet outputs. Connect RCSJet fuel and
         * oxidizer availability to the owning Griffin tank mass outputs; test
         * positive firing, fuel starvation and oxidizer starvation while valve
         * demand remains open. Group the nozzles three per corner, deriving
         * mounts from the bus chamfer faces and top datum. Verify clearances
         * and actuator torque capacity after changing poses/force ratings.
         * None of these vehicle changes is implemented by this source entry.
         */
        // Astrobotic PUG August 2021 v5.02 p.26: twelve 25 lbf ACS
        // engines, arranged in groups of three. SI force uses exact
        // standard lbf conversion; detailed vendor envelopes are unavailable.
        attribute nominalForceN : Real = 111.2055403815125;
        // Envelope estimates from small attitude-nozzle silhouettes in the
        // supplied PGH Tech photo: 80 mm exit, 120 mm bell, 24 mm throat.
        // Reuse the curved main-bell mesh with separate geometry transforms;
        // exhaust geometry has no inherited scaling from those mesh transforms.
        attribute exitRadiusM : Real = .04;
        attribute throatRadiusM : Real = .012;
        attribute bellHeightM : Real = .12;
        attribute collarHeightM : Real = .03;
        // Packaging estimates relative to the bus top and diagonal faces.
        // 60 mm outward standoff clears the skin; +/-120 mm tangent offsets
        // separate the three retained actuator identities at each corner.
        attribute mountBelowBusTopM : Real = .04;
        attribute mountStandoffM : Real = .06;
        attribute memberTangentOffsetM : Real = .12;
    }

    requirement def GPP001_EngineCount {
        doc /* GPP-001 [topology] exactly seven named main-engine visual owners are present in the cluster. Source: current Astrobotic product page https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ accessed 2026-10-03. Five in the August 2021 PUG is a historical configuration. Current unit performance is unavailable; this topology change must not rescale aggregate Modelica thrust. */
    }
    requirement def GPP002_BellGeometry {
        doc /* GPP-002 [visual] each engine includes its modeled bell and throat, with no placeholder circle or duplicate collider geometry. */
    }
    requirement def GPP003_ThrustOwnership {
        doc /* GPP-003 [physics boundary] bells and plumes are render-only. The Modelica propulsion and nozzle models remain the sole authority for thrust, propellant flow, nozzle design outputs, and plume photometry. Fuel starvation shall stop useful combustion and thrust through the feed/chamber equations; zero delivered jet momentum shall yield zero visible plume and light with the engine command still on. The griffin_fuel_exhaustion production fixture verifies this chain. */
    }
    requirement def GPP004_PropulsionTraceability {
        doc /* GPP-004 [evidence] engine identities resolve from GriffinVisualConfigurationRequirements, their cardinality agrees with the typed lander count, and each instance is checked individually. */
    }
    requirement def GPP005_EnginePlacement {
        doc /* GPP-005 [layout] each bell owner uses the ordered native Position datum owned by GriffinVisualConfigurationRequirements. */
    }
    constraint def GPPC006_OpenBellEnvelope {
        in measuredExitRadiusM : Real;
        in measuredHeightM : Real;
        in measuredMinimumRadiusM : Real;
        in measuredThroatOuterRadiusM : Real;
        in measuredThroatHeightM : Real;
        in measuredThroatCenterYM : Real;
        in measuredThroatBoreOpen : Boolean;
        in boreOpen : Boolean;
        in exitRadiusM : Real;
        in heightM : Real;
        in throatRadiusM : Real;
        in throatHeightM : Real;
        in throatCenterYM : Real;
        in wallThicknessM : Real;
        in toleranceM : Real;
        measuredExitRadiusM - exitRadiusM <= toleranceM
            and measuredExitRadiusM - exitRadiusM >= -toleranceM
            and measuredHeightM - heightM <= toleranceM
            and measuredHeightM - heightM >= -toleranceM
            and measuredMinimumRadiusM >= throatRadiusM - wallThicknessM - toleranceM
            and boreOpen
            and measuredThroatOuterRadiusM - throatRadiusM <= toleranceM
            and measuredThroatOuterRadiusM - throatRadiusM >= -toleranceM
            and measuredThroatHeightM - throatHeightM <= toleranceM
            and measuredThroatHeightM - throatHeightM >= -toleranceM
            and measuredThroatCenterYM - throatCenterYM <= toleranceM
            and measuredThroatCenterYM - throatCenterYM >= -toleranceM
            and measuredThroatBoreOpen
    }
    requirement def GPP006_BellAndThroatEnvelope {
        require GPPC006_OpenBellEnvelope {
            in exitRadiusM = GriffinMainPropulsionAssembly::bellRadiusM;
            in heightM = GriffinMainPropulsionAssembly::bellHeightM;
            in throatRadiusM = GriffinMainPropulsionAssembly::throatRadiusM;
            in throatHeightM = GriffinMainPropulsionAssembly::throatHeightM;
            in throatCenterYM = GriffinMainPropulsionAssembly::throatCenterYM;
            in wallThicknessM = GriffinMainPropulsionAssembly::bellVisualWallThicknessM;
            in toleranceM = GriffinVisualConfiguration::geometryVerificationToleranceM;
        }
        doc /* GPP-006 [geometry] each engine exposes an open Y-axis hollow bell Mesh and an uncapped hollow throat Mesh using the source-owned radius/height datums. Mesh vertices and faces shall establish the exit envelope, height, positive flow-bore radius and absence of a closing face in both parts. The throat lower rim shall meet the bell throat plane, and the upper rim seats against the adapter plate. bellContourExponent relates the reconstruction contour to those datums using the library BellNozzle law; the exponent and bellVisualWallThicknessM are explicit visual estimates, not flight nozzle design or wall sizing. See griffin-size-evidence.md. */
    }
    constraint def GPPC007_BellSeparation {
        in measuredMinimumClearanceM : Real;
        in requiredMinimumClearanceM : Real;
        in maximumRadialExtentM : Real;
        in skirtOuterRadiusM : Real;
        in typedStationsMatch : Boolean;
        measuredMinimumClearanceM >= requiredMinimumClearanceM
            and maximumRadialExtentM <= skirtOuterRadiusM
            and typedStationsMatch;
    }
    requirement def GPP007_BellSeparation {
        require GPPC007_BellSeparation {
            in requiredMinimumClearanceM = GriffinMainPropulsionAssembly::minimumBellClearanceM;
            in skirtOuterRadiusM = GriffinMainPropulsionAssembly::clusterOuterRadiusM;
        }
        doc /* GPP-007 [layout] the seven bell exit envelopes shall have at least minimumBellClearanceM pairwise clearance, be arranged as one centered engine and six equally spaced perimeter engines, and remain inside the engine-skirt envelope while clearing the central adapter shell. The layout is derived from the typed engineStations; the bell radius is owned by this propulsion component. */
    }
    constraint def GPPC008_EnginePlumeDataflow {
        in engineCount : Integer;
        in plumeEngineCount : Integer;
        in photometryConsumesEngineState : Boolean;
        in everyNozzleUsesPhotometry : Boolean;
        in everyNozzleHasBoundPlumeMaterials : Boolean;
        in plumeGeometryIsRenderOnly : Boolean;
        engineCount > 0
            and plumeEngineCount == engineCount
            and photometryConsumesEngineState
            and everyNozzleUsesPhotometry
            and everyNozzleHasBoundPlumeMaterials
            and plumeGeometryIsRenderOnly;
    }
    requirement def GPP008_EnginePlumeDataflow {
        require GPPC008_EnginePlumeDataflow {
            in engineCount = GriffinLanderComponent::engineCount;
        }
        doc /* GPP-008 [simulation presentation] each main-engine owner shall inherit its render-only outer plume from the LunCoSim rocket_engine_visual library component, without Twin-authored flame geometry or materials. The library helper connects physics to geometry envelope scale, shader colour and light colour. Nozzle radius and nominal thrust shall determine the envelope; fuel family and mixture richness shall determine a documented heuristic palette. Each nozzle shall have a render-only outer plume and hot core with the corresponding plume materials, plus a local light. The shader inputs and light intensity/size shall follow shared photometry outputs driven by live propulsion state and modeled nozzle geometry. Zero delivered thrust shall produce neither visible exhaust nor light. */
    }
    constraint def GPPC009_TankHardwareSeparation {
        in measuredVerticalGapM : Real;
        in requiredClearanceM : Real;
        measuredVerticalGapM >= requiredClearanceM;
    }
    requirement def GPP009_TankHardwareClearance {
        require GPPC009_TankHardwareSeparation {
            in requiredClearanceM = GriffinMainPropulsionAssembly::minimumTankHardwareClearanceM;
        }
        doc /* GPP-009 [interface] all bell and throat envelopes shall remain below the complete named tank vessel, cradle/pad, fittings and mounting brackets by at least minimumTankHardwareClearanceM. Observe composed geometry bounds in the same canonical frame, including assembly scale and transforms. This deliberately conservative vertical separation is a study packaging rule: Astrobotic publishes no current engine/tank mounting ICD. It prevents spacing-only checks from accepting a nozzle collar through lower tank hardware. Source architecture: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ and https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png ; envelope sizes and clearance are explicit estimates. Structural tank-seat/adapter contacts are separate mount interfaces. */
    }

    requirement def GES001_SkirtTopology {
        doc /* GES-001 [topology] one named continuous mitered octagonal skirt rail forms a closed frame around the seven-engine cluster. */
    }
    requirement def GES002_SkirtEnvelope {
        doc /* GES-002 [geometry] the rail envelope, rail section, open-ended shell, and adapter plate shall use their typed dimensions and station datums in GriffinEngineSkirtComponent. */
    }
    requirement def GES003_SkirtDatum {
        doc /* GES-003 [placement] the skirt is centered on the engine adapter datum immediately below the bus. */
    }
    constraint def GESC004_SkirtAndBellFit {
        in minimumRadialClearanceM : Real;
        in requiredRadialClearanceM : Real;
        in visibleBellHeightFraction : Real;
        in requiredVisibleBellHeightFraction : Real;
        in adapterThroatSeparationM : Real;
        in toleranceM : Real;
        minimumRadialClearanceM >= requiredRadialClearanceM
            and visibleBellHeightFraction >= requiredVisibleBellHeightFraction
            and adapterThroatSeparationM >= -toleranceM;
    }
    requirement def GES004_BellClearance {
        require GESC004_SkirtAndBellFit {
            in requiredRadialClearanceM = GriffinEngineSkirtComponent::minimumSkirtBellClearanceM;
            in requiredVisibleBellHeightFraction = GriffinEngineSkirtComponent::minimumVisibleBellHeightFraction;
            in toleranceM = GriffinVisualConfiguration::geometryVerificationToleranceM;
        }
        doc /* GES-004 [clearance] the rails and lower shroud contour leave at least minimumSkirtBellClearanceM clearance to the full bell envelopes. At least minimumVisibleBellHeightFraction of bell height remains below the shroud edge, and the adapter plate lower face is at or above the upper throat ends. These conservative packaging checks must use composed geometry; a named shroud is not evidence of clearance. */
    }
    requirement def GES005_SkirtOwnership {
        doc /* GES-005 [ownership] skirt geometry is render-only and cannot introduce thrust, collider, or physics authority. */
    }
    constraint def GESC006_OctagonalProfile {
        in topologyMismatches : Integer;
        in maximumRailPointErrorM : Real;
        in maximumShellPointErrorM : Real;
        in maximumBusOverhangM : Real;
        in toleranceM : Real;
        topologyMismatches == 0
            and maximumRailPointErrorM <= toleranceM
            and maximumShellPointErrorM <= toleranceM
            and maximumBusOverhangM <= toleranceM;
    }
    requirement def GES006_RailGeometry {
        require GESC006_OctagonalProfile {
            in toleranceM = GriffinVisualConfiguration::geometryVerificationToleranceM;
        }
        doc /* GES-006 [geometry] the continuous skirt rail shall match railLengthM across flats, railWidthM normal to each edge, railHeightM and componentLocalCenterYM. Both rail and shell shall follow GriffinVisualConfiguration::outerBodyProfileCoordinates; all of their vertices shall remain inside the bus footprint. The bottom inset tapers the shell; it shall not define the plan-view corner clip. */
    }
    requirement def GES007_ShellAndAdapterEnvelope {
        doc /* GES-007 [geometry] the tapered shell shall use its typed upper/lower Y limits, and the adapter plate shall match its typed dimensions and declared datum. The plate center derives from the throat upper end and its own thickness, not from the skirt rail plane. */
    }

    requirement <'GPP-001'> gpp001 : GPP001_EngineCount { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement <'GPP-002'> gpp002 : GPP002_BellGeometry { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement <'GPP-003'> gpp003 : GPP003_ThrustOwnership { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement <'GPP-004'> gpp004 : GPP004_PropulsionTraceability { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement <'GPP-005'> gpp005 : GPP005_EnginePlacement { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement <'GPP-006'> gpp006 : GPP006_BellAndThroatEnvelope { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement <'GPP-007'> gpp007 : GPP007_BellSeparation { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement <'GPP-008'> gpp008 : GPP008_EnginePlumeDataflow { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement <'GPP-009'> gpp009 : GPP009_TankHardwareClearance { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement <'GES-001'> ges001 : GES001_SkirtTopology { subject skirt : GriffinEngineSkirtComponent; }
    requirement <'GES-002'> ges002 : GES002_SkirtEnvelope { subject skirt : GriffinEngineSkirtComponent; }
    requirement <'GES-003'> ges003 : GES003_SkirtDatum { subject skirt : GriffinEngineSkirtComponent; }
    requirement <'GES-004'> ges004 : GES004_BellClearance { subject skirt : GriffinEngineSkirtComponent; }
    requirement <'GES-005'> ges005 : GES005_SkirtOwnership { subject skirt : GriffinEngineSkirtComponent; }
    requirement <'GES-006'> ges006 : GES006_RailGeometry { subject skirt : GriffinEngineSkirtComponent; }
    requirement <'GES-007'> ges007 : GES007_ShellAndAdapterEnvelope { subject skirt : GriffinEngineSkirtComponent; }

    verification def Verify_GriffinPropulsionRequirements {
        subject propulsion : GriffinMainPropulsionAssembly;
        subject skirt : GriffinEngineSkirtComponent;
        objective {
            verify gpp001;
            verify gpp002;
            verify gpp003;
            verify gpp004;
            verify gpp005;
            verify gpp006;
            verify gpp007;
            verify gpp008;
            verify gpp009;
            verify ges001;
            verify ges002;
            verify ges003;
            verify ges004;
            verify ges005;
            verify ges006;
            verify ges007;
        }
    }
    requirement def GPP010_SustainedPilotThrust {
        doc /* GPP-010 [runtime integration] after qualified touchdown, one
         * semantic thrust input held for burnDurationS shall lift the vehicle
         * by minimumSustainedLiftM and retain at least minimumEndVerticalSpeedMps
         * upward velocity at the end of the burn. Releasing the input shall
         * reduce delivered chamber thrust below extinguishedThrustThresholdN
         * after releaseDurationS. Fuel must decrease during the burn. The
         * force actuator input envelope shall accept the modeled feed range
         * derived in GriffinEngineControlStudy. Verify through the production
         * pilot/controller/Modelica/physics path in
         * scenarios/tests/griffin_engine_commands.rhai. This is integration
         * acceptance with explicit study thresholds, not flight qualification.
         */
    }
    requirement <'GPP-010'> gpp010 : GPP010_SustainedPilotThrust {
        subject control : GriffinEngineControlStudy;
    }

}
