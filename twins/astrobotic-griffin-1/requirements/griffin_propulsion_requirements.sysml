package GriffinPropulsionRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::String;

    part def GriffinMainPropulsionAssembly {
        attribute usdRootPath : String = "/World/Griffin1/Nozzle/MainEngineCluster";
        attribute sourceComponent : String = "GriffinLanderRequirements::GriffinLanderComponent";
        attribute namesSource : String = "GriffinLanderRequirements::GriffinLanderComponent::engineNames";
        attribute countSource : String = "GriffinLanderRequirements::GriffinLanderComponent::engineCount";
        attribute childNames : String = "Bell,Throat";
        attribute colliderPolicy : String = "render-only bell and throat; thrust/collision stay with flight model";
        attribute bellRadiusM : Real = 0.34;
        attribute bellHeightM : Real = 0.52;
        attribute throatRadiusM : Real = 0.12;
        attribute throatHeightM : Real = 0.16;
        attribute sourceReference : String = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute sourceFact : String = "Seven main engines perform the lander's major maneuvers";
        attribute sourceRationale : String = "The engine cluster is a separately replaceable visual subassembly; Modelica/physics remains the sole thrust owner";
        attribute geometryStatus : String = "metric visual study proxy; engine ICD and bell profile are not public";
    }

    // The skirt is a visual/structural presentation component around the
    // engine adapter plate.  It is deliberately specified independently from
    // the bells: the flight model owns thrust and collision, while this frame
    // makes the seven-bell cluster legible and provides a stable placement
    // datum for the Editor.
    part def GriffinEngineSkirtComponent {
        attribute usdRootPath : String = "/World/Griffin1/Nozzle/MainEngineCluster";
        attribute memberNames : String = "EngineSkirtFront,EngineSkirtRear,EngineSkirtPort,EngineSkirtStarboard";
        attribute componentRootName : String = "EngineSkirt";
        attribute componentMemberNames : String = "RailFront,RailRear,RailPort,RailStarboard";
        attribute shellName : String = "EngineSkirtShell";
        attribute adapterPlateName : String = "EngineAdapterPlate";
        attribute adapterPlateWidthM : Real = 2.84;
        attribute adapterPlateDepthM : Real = 2.84;
        attribute adapterPlateHeightM : Real = 0.12;
        attribute shellDepthM : Real = 0.50;
        attribute shellBottomInsetM : Real = 0.30;
        attribute componentLocalCenterYM : Real = 0.00;
        attribute assemblyMountYM : Real = 1.68;
        attribute sourceComponent : String = "GriffinLanderRequirements::GriffinLanderComponent";
        attribute dimensionSource : String = "engineClusterWidthM,engineClusterDepthM,engineSkirtHeightM,shellDepthM";
        attribute metricEnvelope : String = "3.20 m x 3.20 m rail envelope; 0.50 m tapered shell depth; 0.20 m rail section";
        attribute railSection : String = "0.20 m wide x 0.20 m tall nominal square rail";
        attribute datum : String = "engine adapter plate at y = engineMountYM; skirt center y = engineMountYM - 0.07 m";
        attribute clearance : String = "minimum 0.10 m radial clearance to every bell outer radius";
        attribute colliderPolicy : String = "render-only frame; no physics collision or thrust authority";
        attribute transformOrder : String = "xformOp:translate,xformOp:scale";
        attribute shellTopology : String = "beveled octagonal tapered open-ended mesh shroud";
        attribute sourceReference : String = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute sourceFact : String = "the public Griffin material identifies a clustered propulsion system but does not publish an engine-skirt ICD";
        attribute sourceRationale : String = "the frame is a transparent study-level interpretation, kept separate so an ICD can replace it without changing the engine owners";
        attribute geometryStatus : String = "metric visual study proxy; confirm against released propulsion ICD when available";
    }

    requirement def GPP001_EngineCount {
        doc /* GPP-001 [topology] exactly seven named main-engine visual owners are present in the cluster. */
    }
    requirement def GPP002_BellGeometry {
        doc /* GPP-002 [visual] every engine exposes a visible bell and throat, with no placeholder circle or duplicate collider geometry. */
    }
    requirement def GPP003_ThrustOwnership {
        doc /* GPP-003 [physics boundary] visual nozzle geometry is not a second thrust or collision implementation; the Modelica/physics owner remains authoritative. */
    }
    requirement def GPP004_PropulsionTraceability {
        doc /* GPP-004 [evidence] engine identities and count resolve from the lander SysML source and are checked individually. */
    }
    requirement def GPP005_EnginePlacement {
        doc /* GPP-005 [layout] each bell owner uses the ordered metric engine station datum owned by GriffinLanderComponent. */
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

    requirement gpp001 : GPP001_EngineCount { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement gpp002 : GPP002_BellGeometry { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement gpp003 : GPP003_ThrustOwnership { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement gpp004 : GPP004_PropulsionTraceability { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement gpp005 : GPP005_EnginePlacement { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement ges001 : GES001_SkirtTopology { subject skirt : GriffinEngineSkirtComponent; }
    requirement ges002 : GES002_SkirtEnvelope { subject skirt : GriffinEngineSkirtComponent; }
    requirement ges003 : GES003_SkirtDatum { subject skirt : GriffinEngineSkirtComponent; }
    requirement ges004 : GES004_BellClearance { subject skirt : GriffinEngineSkirtComponent; }
    requirement ges005 : GES005_SkirtOwnership { subject skirt : GriffinEngineSkirtComponent; }

    verification def Verify_GriffinPropulsionRequirements {
        subject propulsion : GriffinMainPropulsionAssembly;
        subject skirt : GriffinEngineSkirtComponent;
        verify gpp001;
        verify gpp002;
        verify gpp003;
        verify gpp004;
        verify gpp005;
        verify ges001;
        verify ges002;
        verify ges003;
        verify ges004;
        verify ges005;
    }
}
