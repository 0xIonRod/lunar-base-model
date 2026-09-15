package GriffinPropulsionRequirements {
    private import ScalarValues::String;

    part def GriffinMainPropulsionAssembly {
        attribute usdRootPath : String = "/World/Griffin1/Nozzle/MainEngineCluster";
        attribute sourceComponent : String = "GriffinLanderRequirements::GriffinLanderComponent";
        attribute namesSource : String = "GriffinLanderRequirements::GriffinLanderComponent::engineNames";
        attribute countSource : String = "GriffinLanderRequirements::GriffinLanderComponent::engineCount";
        attribute childNames : String = "Bell,Throat";
        attribute colliderPolicy : String = "render-only bell and throat; thrust/collision stay with flight model";
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

    requirement gpp001 : GPP001_EngineCount { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement gpp002 : GPP002_BellGeometry { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement gpp003 : GPP003_ThrustOwnership { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement gpp004 : GPP004_PropulsionTraceability { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement gpp005 : GPP005_EnginePlacement { subject propulsion : GriffinMainPropulsionAssembly; }

    verification def Verify_GriffinPropulsionRequirements {
        subject propulsion : GriffinMainPropulsionAssembly;
        verify gpp001;
        verify gpp002;
        verify gpp003;
        verify gpp004;
        verify gpp005;
    }
}
