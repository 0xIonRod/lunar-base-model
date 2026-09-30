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

    part def GriffinMainPropulsionAssembly {
        attribute usdRootPath : UsdPrimPath = "/World/Griffin1/Nozzle/MainEngineCluster";
        attribute componentAsset : TwinAssetPath = "components/lander/griffin_engine_bell_visual.usda";
        attribute childNames : GriffinEngineVisualMember[2] =
            ("Bell", "Throat");
        attribute bellRadiusM : Real = 0.34;
        attribute bellHeightM : Real = 0.52;
        attribute throatRadiusM : Real = 0.12;
        attribute throatHeightM : Real = 0.16;
        attribute throatCenterYM : Real = 0.28;
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

        // Hypergolic family from PUG p.26 (M20 / MON3). Palette is heuristic;
        // 2.0 reference O/F is a provisional chemistry estimate, not flight data.
        attribute plumeFuelFamily : Real = 3;
        attribute plumeStoichiometricMixtureRatio : Real = 2.0;
        attribute minimumBellClearanceM : Real = 0.20;
        // The skirt bounds the engine cluster; the central adapter is an
        // internal structural shell and must not be treated as its boundary.
        attribute clusterOuterRadiusM : Real = GriffinEngineSkirtComponent::railLengthM / 2.0;
    }

    // The skirt is a visual/structural presentation component around the
    // engine adapter plate.  It is deliberately specified independently from
    // the bells: the flight model owns thrust and collision, while this frame
    // makes the five-bell cluster legible and provides a stable placement
    // datum for the Editor.
    part def GriffinEngineSkirtComponent {
        attribute usdRootPath : String = "/World/Griffin1/Nozzle/MainEngineCluster";
        attribute componentRootName : String = "EngineSkirt";
        attribute componentMemberNames : String[4] = ("RailFront", "RailRear", "RailPort", "RailStarboard");
        attribute railFrontCenterZM : Real = railLengthM / 2.0 - railWidthM / 2.0;
        attribute railRearCenterZM : Real = -railFrontCenterZM;
        attribute railPortCenterXM : Real = railFrontCenterZM;
        attribute railStarboardCenterXM : Real = -railPortCenterXM;
        attribute railLengthM : Real = 3.20;
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
        attribute componentLocalCenterYM : Real = 0.00;
        attribute minimumSkirtBellClearanceM : Real = 0.10;
        // Seat the plate's lower face at the upper throat end. A plate
        // centered on the rail plane would intersect all five bell walls.
        attribute adapterPlateCenterYM : Real = GriffinMainPropulsionAssembly::throatCenterYM + GriffinMainPropulsionAssembly::throatHeightM / 2.0 + adapterPlateHeightM / 2.0;
        // Estimated minimum exposure below the shroud, to reject geometry
        // that encloses the bell exits while passing simple dimension checks.
        attribute minimumVisibleBellHeightFraction : Real = 0.30;
        attribute colliderPolicy : String = "render-only frame; no physics collision or thrust authority";
        attribute transformOrder : String[2] = ("xformOp:translate", "xformOp:scale");
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
        doc /* GPP-001 [topology] exactly five named main-engine visual owners are present in the cluster. */
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
        in boreOpen : Boolean;
        in exitRadiusM : Real;
        in heightM : Real;
        in throatRadiusM : Real;
        in wallThicknessM : Real;
        in toleranceM : Real;
        measuredExitRadiusM - exitRadiusM <= toleranceM
            and measuredExitRadiusM - exitRadiusM >= -toleranceM
            and measuredHeightM - heightM <= toleranceM
            and measuredHeightM - heightM >= -toleranceM
            and measuredMinimumRadiusM >= throatRadiusM - wallThicknessM - toleranceM
            and boreOpen
    }
    requirement def GPP006_BellAndThroatEnvelope {
        require GPPC006_OpenBellEnvelope {
            in exitRadiusM = GriffinMainPropulsionAssembly::bellRadiusM;
            in heightM = GriffinMainPropulsionAssembly::bellHeightM;
            in throatRadiusM = GriffinMainPropulsionAssembly::throatRadiusM;
            in wallThicknessM = GriffinMainPropulsionAssembly::bellVisualWallThicknessM;
            in toleranceM = GriffinVisualConfiguration::geometryVerificationToleranceM;
        }
        doc /* GPP-006 [geometry] each engine exposes an open Y-axis hollow bell Mesh and a throat using the source-owned radius/height datums. Mesh vertices and faces shall establish the exit envelope, height, positive flow-bore radius and absence of a closing face. bellContourExponent relates the reconstruction contour to those datums using the library BellNozzle law; the exponent and bellVisualWallThicknessM are explicit visual estimates, not flight nozzle design or wall sizing. See griffin-size-evidence.md. */
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
        doc /* GPP-007 [layout] the five bell exit envelopes shall have at least minimumBellClearanceM pairwise clearance, be arranged as one centered engine and four equally spaced perimeter engines, and remain inside the engine-skirt envelope while clearing the central adapter shell. The layout is derived from the typed engineStations; the bell radius is owned by this propulsion component. */
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
    requirement def GES001_SkirtTopology {
        doc /* GES-001 [topology] exactly four named skirt rails form one closed frame around the five-engine cluster. */
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
    requirement def GES006_RailGeometry {
        doc /* GES-006 [geometry] the four named skirt rails shall match railLengthM, railWidthM, railHeightM, and the signed center stations in GriffinEngineSkirtComponent. */
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
            verify ges001;
            verify ges002;
            verify ges003;
            verify ges004;
            verify ges005;
            verify ges006;
            verify ges007;
        }
    }
}
