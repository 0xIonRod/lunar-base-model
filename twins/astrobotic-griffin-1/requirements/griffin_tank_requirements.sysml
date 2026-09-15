package GriffinTankRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::String;

    part def GriffinPropellantTankAssembly {
        attribute usdRootPath : String = "/World/Griffin1";
        attribute sourceComponent : String = "GriffinLanderRequirements::GriffinLanderComponent";
        attribute namesSource : String = "GriffinLanderRequirements::GriffinLanderComponent::tankNames";
        attribute countSource : String = "GriffinLanderRequirements::GriffinLanderComponent::tankCount";
        attribute childNames : String = "TankBandA,TankBandB,TankBandC,TankCradle,TankNeckTop,TankNeckBottom,TankShoulderTop,TankShoulderBottom,TankValveTop,TankValveBottom,TankValveCapTop,TankValveCapBottom,TankTransitionTop,TankTransitionBottom,MliTank";
        attribute endHardwareNames : String = "TankNeckTop,TankNeckBottom";
        attribute serviceHardwareNames : String = "TankShoulderTop,TankShoulderBottom,TankValveTop,TankValveBottom,TankValveCapTop,TankValveCapBottom";
        attribute axialHardwareNames : String = "TankNeckTop,TankNeckBottom,TankShoulderTop,TankShoulderBottom,TankValveTop,TankValveBottom,TankValveCapTop,TankValveCapBottom,TankTransitionTop,TankTransitionBottom";
        attribute tankAxis : String = "Y";
        attribute bodyShape : String = "Capsule";
        attribute status : String = "metric visual study proxy; exact COPV dimensions and placement TBD";
        attribute bodyRadiusM : Real = 0.40;
        // Capsule height is the cylindrical section; the full envelope is
        // bodyHeightM = bodyCylindricalHeightM + 2 * bodyRadiusM.
        attribute bodyHeightM : Real = 1.65;
        attribute bodyCylindricalHeightM : Real = 0.85;
        attribute neckRadiusM : Real = 0.18;
        attribute neckHeightM : Real = 0.14;
        attribute shoulderCollarRadiusM : Real = 0.30;
        attribute shoulderCollarHeightM : Real = 0.10;
        attribute valveRadiusM : Real = 0.09;
        attribute valveHeightM : Real = 0.10;
        attribute valveCapRadiusM : Real = 0.13;
        attribute valveCapHeightM : Real = 0.06;
        attribute transitionShoulderRadiusM : Real = 0.30;
        attribute transitionNeckRadiusM : Real = 0.18;
        attribute transitionHeightM : Real = 0.12;
        attribute transitionRadiusM : Real = 0.30;
        attribute sourceReference : String = "https://www.astrobotic.com/griffin-1-mission-update/";
        attribute sourceFact : String = "Griffin-1 integration includes four propellant tanks and fit checks";
        attribute sourceRationale : String = "Each tank is a repeated, independently inspectable pressure-vessel visual component whose station and retention bands must not drift";
        attribute bandRadiusM : Real = 0.45;
        attribute bandHeightM : Real = 0.08;
        attribute cradleLocalY : Real = -1.23;
        attribute cradleHalfHeightM : Real = 0.05;
        attribute minimumDeckClearanceM : Real = 0.02;
        attribute deckTopSource : String = "GriffinLanderRequirements::GriffinLanderComponent::avionicsDeckTopY";
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
        doc /* GPT-005 [layout] each tank root transform matches the ordered metric station datums owned by GriffinLanderComponent and leaves the lower cradle seated above the avionics deck. */
    }
    requirement def GPT006_TankEndHardware {
        doc /* GPT-006 [visual] each tank body is a compact metric capsule with hemispherical ends, tapered shoulder-to-neck transitions, and coaxial necks, so the pressure-vessel silhouette is not a flat-ended cylinder with floating hardware. */
    }
    requirement def GPT007_TankServiceHardware {
        doc /* GPT-007 [visual] each tank includes the sourced shoulder collars and valve/cap hardware with the metric proxy dimensions defined by the component. */
    }
    requirement def GPT008_TankOrientation {
        doc /* GPT-008 [orientation] the capsule body and all axial tank hardware are Y-up; the authored envelope is centered on the tank datum without hidden rotations or through-geometry. */
    }
    requirement def GPT009_TankDeckSeat {
        doc /* GPT-009 [interface] the lower cradle datum is above the avionics-deck top datum with no tank hardware penetrating the deck. */
    }

    requirement gpt001 : GPT001_TankCount { subject tanks : GriffinPropellantTankAssembly; }
    requirement gpt002 : GPT002_TankRetention { subject tanks : GriffinPropellantTankAssembly; }
    requirement gpt003 : GPT003_TankStatus { subject tanks : GriffinPropellantTankAssembly; }
    requirement gpt004 : GPT004_TankTraceability { subject tanks : GriffinPropellantTankAssembly; }
    requirement gpt005 : GPT005_TankPlacement { subject tanks : GriffinPropellantTankAssembly; }
    requirement gpt006 : GPT006_TankEndHardware { subject tanks : GriffinPropellantTankAssembly; }
    requirement gpt007 : GPT007_TankServiceHardware { subject tanks : GriffinPropellantTankAssembly; }
    requirement gpt008 : GPT008_TankOrientation { subject tanks : GriffinPropellantTankAssembly; }
    requirement gpt009 : GPT009_TankDeckSeat { subject tanks : GriffinPropellantTankAssembly; }

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
        verify gpt009;
    }
}
