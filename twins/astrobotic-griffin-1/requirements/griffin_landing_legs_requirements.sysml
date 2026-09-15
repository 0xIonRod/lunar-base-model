package GriffinLandingLegRequirements {
    private import ScalarValues::String;

    part def GriffinLandingLegAssembly {
        attribute usdRootPath : String = "/World/Griffin1";
        attribute sourceComponent : String = "GriffinLanderRequirements::GriffinLanderComponent";
        attribute namesSource : String = "GriffinLanderRequirements::GriffinLanderComponent::legNames";
        attribute countSource : String = "GriffinLanderRequirements::GriffinLanderComponent::legCount";
        attribute childNames : String = "StrutOuter,StrutInner,ShockPiston,FootPad";
        attribute placementFrame : String = "signed X/Z body axes; local Y is vertical";
        attribute sourceReference : String = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute sourceFact : String = "Griffin has four legs that absorb shock and stabilize the lander during touchdown";
        attribute sourceRationale : String = "Legs are a repeated load-bearing subassembly with an independent visual/collision contract and a mount datum at each bus corner";
        attribute geometryStatus : String = "metric visual study proxy; shock absorber dimensions are not public";
    }

    requirement def GLL001_LegCount {
        doc /* GLL-001 [topology] exactly the four named landing legs from the lander source are present and visible. */
    }
    requirement def GLL002_LegStructure {
        doc /* GLL-002 [visual] every landing leg exposes two struts, a shock piston, and a foot pad. */
    }
    requirement def GLL003_LegFrame {
        doc /* GLL-003 [layout] leg stations use the documented signed X/Z body frame and remain separate replaceable components. */
    }
    requirement def GLL004_LegTraceability {
        doc /* GLL-004 [evidence] the leg identity list and count are resolved from the lander SysML source without a second list in Rhai. */
    }
    requirement def GLL005_LegPlacement {
        doc /* GLL-005 [layout] each leg root transform matches the ordered X/Y/Z station datums owned by GriffinLanderComponent. */
    }

    requirement gll001 : GLL001_LegCount { subject legs : GriffinLandingLegAssembly; }
    requirement gll002 : GLL002_LegStructure { subject legs : GriffinLandingLegAssembly; }
    requirement gll003 : GLL003_LegFrame { subject legs : GriffinLandingLegAssembly; }
    requirement gll004 : GLL004_LegTraceability { subject legs : GriffinLandingLegAssembly; }
    requirement gll005 : GLL005_LegPlacement { subject legs : GriffinLandingLegAssembly; }

    verification def Verify_GriffinLandingLegRequirements {
        subject legs : GriffinLandingLegAssembly;
        verify gll001;
        verify gll002;
        verify gll003;
        verify gll004;
        verify gll005;
    }
}
