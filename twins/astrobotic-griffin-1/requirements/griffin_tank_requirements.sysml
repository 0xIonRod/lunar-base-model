package GriffinTankRequirements {
    private import ScalarValues::String;

    part def GriffinPropellantTankAssembly {
        attribute usdRootPath : String = "/World/Griffin1";
        attribute sourceComponent : String = "GriffinLanderRequirements::GriffinLanderComponent";
        attribute namesSource : String = "GriffinLanderRequirements::GriffinLanderComponent::tankNames";
        attribute countSource : String = "GriffinLanderRequirements::GriffinLanderComponent::tankCount";
        attribute childNames : String = "MliTank,TankBandA,TankBandB,TankBandC";
        attribute status : String = "visual study proxy; exact COPV dimensions and placement TBD";
        attribute sourceReference : String = "https://www.astrobotic.com/griffin-1-mission-update/";
        attribute sourceFact : String = "Griffin-1 integration includes four propellant tanks and fit checks";
        attribute sourceRationale : String = "Each tank is a repeated, independently inspectable pressure-vessel visual component whose station and retention bands must not drift";
    }

    requirement def GPT001_TankCount {
        doc /* GPT-001 [topology] exactly four named propellant-tank owners are present and visible. */
    }
    requirement def GPT002_TankRetention {
        doc /* GPT-002 [visual] every tank exposes a body and three retention bands with a lower cradle. */
    }
    requirement def GPT003_TankStatus {
        doc /* GPT-003 [traceability] tank geometry is labelled as a metric visual proxy until the mechanical ICD is available. */
    }
    requirement def GPT004_TankTraceability {
        doc /* GPT-004 [evidence] tank identities and count resolve from the lander SysML source and are checked individually. */
    }
    requirement def GPT005_TankPlacement {
        doc /* GPT-005 [layout] each tank root transform matches the ordered metric station datums owned by GriffinLanderComponent. */
    }

    requirement gpt001 : GPT001_TankCount { subject tanks : GriffinPropellantTankAssembly; }
    requirement gpt002 : GPT002_TankRetention { subject tanks : GriffinPropellantTankAssembly; }
    requirement gpt003 : GPT003_TankStatus { subject tanks : GriffinPropellantTankAssembly; }
    requirement gpt004 : GPT004_TankTraceability { subject tanks : GriffinPropellantTankAssembly; }
    requirement gpt005 : GPT005_TankPlacement { subject tanks : GriffinPropellantTankAssembly; }

    verification def Verify_GriffinTankRequirements {
        subject tanks : GriffinPropellantTankAssembly;
        verify gpt001;
        verify gpt002;
        verify gpt003;
        verify gpt004;
        verify gpt005;
    }
}
