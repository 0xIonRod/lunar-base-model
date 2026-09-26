package GriffinPropulsionRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::String;
    private import ScalarValues::Boolean;
    private import ScalarValues::Integer;
    private import VectorValues::CartesianThreeVectorValue;
    private import GriffinRequirementSources::TwinAssetPath;
    private import GriffinRequirementSources::UsdPrimPath;

    attribute def Direction :> CartesianThreeVectorValue;
    enum def GriffinEngineVisualMember { Bell; Throat; Flame; FlameCore; }

    part def GriffinMainPropulsionAssembly {
        attribute usdRootPath : UsdPrimPath = "/World/Griffin1/Nozzle/MainEngineCluster";
        attribute componentAsset : TwinAssetPath = "components/lander/griffin_engine_bell_visual.usda";
        attribute childNames : GriffinEngineVisualMember[4] =
            ("Bell", "Throat", "Flame", "FlameCore");
        attribute bellRadiusM : Real = 0.34;
        attribute bellHeightM : Real = 0.52;
        attribute throatRadiusM : Real = 0.12;
        attribute throatHeightM : Real = 0.16;
        attribute throatCenterYM : Real = 0.28;
        attribute bellAxis : Direction = (0.0, 1.0, 0.0);
        attribute minimumBellClearanceM : Real = 0.20;
    }

    // The skirt is a visual/structural presentation component around the
    // engine adapter plate.  It is deliberately specified independently from
    // the bells: the flight model owns thrust and collision, while this frame
    // makes the seven-bell cluster legible and provides a stable placement
    // datum for the Editor.
    part def GriffinEngineSkirtComponent {
        attribute usdRootPath : String = "/World/Griffin1/Nozzle/MainEngineCluster";
        attribute componentRootName : String = "EngineSkirt";
        attribute componentMemberNames : String[4] = ("RailFront", "RailRear", "RailPort", "RailStarboard");
        attribute railFrontCenterZM : Real = 1.50;
        attribute railRearCenterZM : Real = -1.50;
        attribute railPortCenterXM : Real = 1.50;
        attribute railStarboardCenterXM : Real = -1.50;
        attribute railLengthM : Real = 3.20;
        attribute railWidthM : Real = 0.20;
        attribute railHeightM : Real = 0.20;
        attribute shellName : String = "EngineSkirtShell";
        attribute adapterPlateName : String = "EngineAdapterPlate";
        attribute adapterPlateWidthM : Real = 2.84;
        attribute adapterPlateDepthM : Real = 2.84;
        attribute adapterPlateHeightM : Real = 0.12;
        attribute shellDepthM : Real = 0.50;
        attribute shellBottomInsetM : Real = 0.30;
        attribute shellUpperYM : Real = 0.10;
        attribute shellLowerYM : Real = -0.40;
        attribute componentLocalCenterYM : Real = 0.00;
        attribute clearance : String = "minimum 0.10 m radial clearance to every bell outer radius";
        attribute colliderPolicy : String = "render-only frame; no physics collision or thrust authority";
        attribute transformOrder : String[2] = ("xformOp:translate", "xformOp:scale");
    }

    requirement def GPP001_EngineCount {
        doc /* GPP-001 [topology] exactly seven named main-engine visual owners are present in the cluster. */
    }
    requirement def GPP002_BellGeometry {
        doc /* GPP-002 [visual] each engine includes its modeled bell and throat, with no placeholder circle or duplicate collider geometry. */
    }
    requirement def GPP003_ThrustOwnership {
        doc /* GPP-003 [physics boundary] bells and plumes are render-only. The Modelica propulsion and nozzle models remain the sole authority for thrust, propellant flow, nozzle design outputs, and plume photometry. */
    }
    requirement def GPP004_PropulsionTraceability {
        doc /* GPP-004 [evidence] engine identities resolve from GriffinVisualConfigurationRequirements, their cardinality agrees with the typed lander count, and each instance is checked individually. */
    }
    requirement def GPP005_EnginePlacement {
        doc /* GPP-005 [layout] each bell owner uses the ordered native Position datum owned by GriffinVisualConfigurationRequirements. */
    }
    requirement def GPP006_BellAndThroatEnvelope {
        doc /* GPP-006 [geometry] each engine shall expose a Y-axis bell with 0.16 m base radius, 0.34 m exit radius, and 0.52 m height plus a 0.12 m radius by 0.16 m throat centered at local Y = 0.28 m. */
    }
    constraint def GPPC007_BellSeparation {
        in measuredMinimumClearanceM : Real;
        in requiredMinimumClearanceM : Real;
        in maximumRadialExtentM : Real;
        in bucketOuterRadiusM : Real;
        in typedStationsMatch : Boolean;
        measuredMinimumClearanceM >= requiredMinimumClearanceM
            and maximumRadialExtentM <= bucketOuterRadiusM
            and typedStationsMatch;
    }
    requirement def GPP007_BellSeparation {
        require GPPC007_BellSeparation;
        doc /* GPP-007 [layout] the seven bell exit envelopes shall have at least minimumBellClearanceM pairwise clearance, be arranged as one centered engine and six equally spaced perimeter engines, and remain inside the lower central bucket envelope. The layout is derived from the typed engineStations; the bell radius is owned by this propulsion component. */
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
        require GPPC008_EnginePlumeDataflow;
        doc /* GPP-008 [simulation presentation] each main-engine nozzle shall have a render-only outer plume and hot core with the corresponding plume materials, plus a local light. The shader inputs and light intensity/size shall follow shared photometry outputs driven by live propulsion state and modeled nozzle geometry. Zero delivered thrust shall produce neither visible exhaust nor light. */
    }
    requirement def GES001_SkirtTopology {
        doc /* GES-001 [topology] exactly four named skirt rails form one closed frame around the seven-engine cluster. */
    }
    requirement def GES002_SkirtEnvelope {
        doc /* GES-002 [geometry] the rail envelope is 3.20 m by 3.20 m with a 0.20 m rail section; the tapered open-ended shell extends 0.50 m below the adapter and a 2.84 m x 2.84 m x 0.12 m plate seats the cluster, all metric. */
    }
    requirement def GES003_SkirtDatum {
        doc /* GES-003 [placement] the skirt is centered on the engine adapter datum immediately below the bus. */
    }
    requirement def GES004_BellClearance {
        doc /* GES-004 [clearance] every rail leaves at least 0.10 m radial clearance to the visible bell envelope. */
    }
    requirement def GES005_SkirtOwnership {
        doc /* GES-005 [ownership] skirt geometry is render-only and cannot introduce thrust, collider, or physics authority. */
    }
    requirement def GES006_RailGeometry {
        doc /* GES-006 [geometry] the four named skirt rails shall each be 3.20 m long, 0.20 m wide, and 0.20 m high, with signed centers at X = +/-1.50 m or Z = +/-1.50 m. */
    }
    requirement def GES007_ShellAndAdapterEnvelope {
        doc /* GES-007 [geometry] the tapered shell shall span local Y = -0.40 m to +0.10 m, and the adapter plate shall be 2.84 m by 2.84 m by 0.12 m at its declared adapter datum. */
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
