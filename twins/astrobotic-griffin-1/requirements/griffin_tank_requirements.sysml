package GriffinTankRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::String;

    part def GriffinPropellantTankAssembly {
        attribute usdRootPath : String = "/World/Griffin1";
        attribute sourceComponent : String = "GriffinLanderRequirements::GriffinLanderComponent";
        attribute namesSource : String = "GriffinLanderRequirements::GriffinLanderComponent::tankNames";
        attribute countSource : String = "GriffinLanderRequirements::GriffinLanderComponent::tankCount";
        attribute childNames : String = "MliTank,TankBandA,TankBandB,TankBandC,TankCradle,TankDomeTopProfile,TankDomeBottomProfile,TankNeckTop,TankNeckBottom,TankShoulderTop,TankShoulderBottom,TankValveTop,TankValveBottom,TankValveCapTop,TankValveCapBottom";
        attribute endHardwareNames : String = "TankDomeTopProfile,TankDomeBottomProfile,TankNeckTop,TankNeckBottom";
        attribute serviceHardwareNames : String = "TankShoulderTop,TankShoulderBottom,TankValveTop,TankValveBottom,TankValveCapTop,TankValveCapBottom";
        attribute axialHardwareNames : String = "TankNeckTop,TankNeckBottom,TankShoulderTop,TankShoulderBottom,TankValveTop,TankValveBottom,TankValveCapTop,TankValveCapBottom";
        attribute tankAxis : String = "Y";
        attribute domeShape : String = "Sphere";
        attribute domeScaleYM : Real = 0.73;
        attribute domeCenterOffsetM : Real = 1.125;
        attribute status : String = "metric visual study proxy; exact COPV dimensions and placement TBD";
        attribute bodyRadiusM : Real = 0.48;
        attribute bodyHeightM : Real = 2.25;
        attribute domeRadiusM : Real = 0.48;
        attribute domeHeightM : Real = 0.35;
        attribute domeNeckRadiusM : Real = 0.18;
        attribute neckRadiusM : Real = 0.18;
        attribute neckHeightM : Real = 0.18;
        attribute shoulderCollarRadiusM : Real = 0.30;
        attribute shoulderCollarHeightM : Real = 0.10;
        attribute valveRadiusM : Real = 0.09;
        attribute valveHeightM : Real = 0.14;
        attribute valveCapRadiusM : Real = 0.13;
        attribute valveCapHeightM : Real = 0.06;
        attribute sourceReference : String = "https://www.astrobotic.com/griffin-1-mission-update/";
        attribute sourceFact : String = "Griffin-1 integration includes four propellant tanks and fit checks";
        attribute sourceRationale : String = "Each tank is a repeated, independently inspectable pressure-vessel visual component whose station and retention bands must not drift";
    }

    requirement def GPT001_TankCount {
        doc /* GPT-001 [topology] exactly four named propellant-tank owners are present and visible. */
    }
    requirement def GPT002_TankRetention {
        doc /* GPT-002 [visual] every tank exposes a body, three retention bands, a lower cradle, and the retained end hardware listed by the component. */
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
    requirement def GPT006_TankEndHardware {
        doc /* GPT-006 [visual] each tank includes two retained rounded ellipsoidal end domes and coaxial necks so the pressure-vessel silhouette is not a bare cylinder. */
    }
    requirement def GPT007_TankServiceHardware {
        doc /* GPT-007 [visual] each tank includes the sourced shoulder collars and valve/cap hardware with the metric proxy dimensions defined by the component. */
    }
    requirement def GPT008_TankOrientation {
        doc /* GPT-008 [orientation] all axial tank hardware is Y-up and each dome is centered on the body end datum without a hidden rotation or through-geometry. */
    }

    requirement gpt001 : GPT001_TankCount { subject tanks : GriffinPropellantTankAssembly; }
    requirement gpt002 : GPT002_TankRetention { subject tanks : GriffinPropellantTankAssembly; }
    requirement gpt003 : GPT003_TankStatus { subject tanks : GriffinPropellantTankAssembly; }
    requirement gpt004 : GPT004_TankTraceability { subject tanks : GriffinPropellantTankAssembly; }
    requirement gpt005 : GPT005_TankPlacement { subject tanks : GriffinPropellantTankAssembly; }
    requirement gpt006 : GPT006_TankEndHardware { subject tanks : GriffinPropellantTankAssembly; }
    requirement gpt007 : GPT007_TankServiceHardware { subject tanks : GriffinPropellantTankAssembly; }
    requirement gpt008 : GPT008_TankOrientation { subject tanks : GriffinPropellantTankAssembly; }

    verification def Verify_GriffinTankRequirements {
        subject tanks : GriffinPropellantTankAssembly;
        verify gpt001;
        verify gpt002;
        verify gpt003;
        verify gpt004;
        verify gpt005;
        verify gpt006;
        verify gpt007;
        verify gpt008;
    }
}
