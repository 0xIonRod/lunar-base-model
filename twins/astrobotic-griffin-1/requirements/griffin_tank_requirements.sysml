package GriffinTankRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::String;

    part def GriffinPropellantTankAssembly {
        attribute usdRootPath : String = "/World/Griffin1";
        attribute sourceComponent : String = "GriffinLanderRequirements::GriffinLanderComponent";
        attribute namesSource : String = "GriffinLanderRequirements::GriffinLanderComponent::tankNames";
        attribute countSource : String = "GriffinLanderRequirements::GriffinLanderComponent::tankCount";
        attribute childNames : String = "TankBandA,TankBandB,TankBandC,TankCradle,TankCradlePad,TankNeckTop,TankNeckBottom,TankShoulderTop,TankShoulderBottom,TankValveTop,TankValveBottom,TankValveCapTop,TankValveCapBottom,TankTransitionTop,TankTransitionBottom,MliTank";
        attribute endHardwareNames : String = "TankNeckTop,TankNeckBottom";
        attribute serviceHardwareNames : String = "TankShoulderTop,TankShoulderBottom,TankValveTop,TankValveBottom,TankValveCapTop,TankValveCapBottom";
        attribute axialHardwareNames : String = "TankNeckTop,TankNeckBottom,TankShoulderTop,TankShoulderBottom,TankValveTop,TankValveBottom,TankValveCapTop,TankValveCapBottom,TankTransitionTop,TankTransitionBottom";
        attribute tankAxis : String = "Y";
        attribute bodyShape : String = "Sphere";
        attribute status : String = "metric visual study proxy; exact COPV dimensions and placement TBD";
        attribute bodyRadiusM : Real = 0.50;
        // The Griffin reference shows compact spherical, gold-wrapped vessels.
        // A sphere has no cylindrical section; bodyHeightM is its full envelope.
        attribute bodyHeightM : Real = 1.00;
        attribute bodyCylindricalHeightM : Real = 0.00;
        attribute neckRadiusM : Real = 0.09;
        attribute neckHeightM : Real = 0.10;
        attribute shoulderCollarRadiusM : Real = 0.20;
        attribute shoulderCollarHeightM : Real = 0.08;
        attribute valveRadiusM : Real = 0.045;
        attribute valveHeightM : Real = 0.06;
        attribute valveCapRadiusM : Real = 0.075;
        attribute valveCapHeightM : Real = 0.12;
        attribute transitionShoulderRadiusM : Real = 0.16;
        attribute transitionNeckRadiusM : Real = 0.11;
        attribute transitionHeightM : Real = 0.08;
        attribute transitionRadiusM : Real = 0.16;
        // Axial centers are explicit interface datums.  The verifier mirrors
        // them about the tank datum for the lower train and checks the cradle
        // against the declared deck relationship.
        attribute shoulderCenterYM : Real = 0.50;
        attribute transitionCenterYM : Real = 0.58;
        attribute neckCenterYM : Real = 0.67;
        attribute valveCenterYM : Real = 0.75;
        attribute capCenterYM : Real = 0.84;
        attribute sourceReference : String = "https://www.astrobotic.com/media-kit/images/";
        attribute sourceFact : String = "Griffin reference imagery shows compact gold spherical propellant vessels; Astrobotic confirms four propellant tanks";
        attribute sourceRationale : String = "Each tank is a repeated, independently inspectable spherical pressure-vessel visual component whose station and retention straps must not drift";
        attribute bandRadiusM : Real = 0.49;
        attribute bandHeightM : Real = 0.036;
        attribute bandCenterYM : String = "-0.24,0.0,0.24";
        attribute bandScaleYM : Real = 0.018;
        attribute cradleLocalY : Real = -0.93;
        attribute cradleHalfHeightM : Real = 0.05;
        attribute cradlePadLocalY : Real = -0.86;
        attribute cradlePadWidthM : Real = 0.52;
        attribute cradlePadDepthM : Real = 0.52;
        attribute cradlePadHeightM : Real = 0.08;
        attribute minimumDeckClearanceM : Real = 0.02;
        attribute deckTopSource : String = "GriffinLanderRequirements::GriffinLanderComponent::avionicsDeckTopY";
    }

    requirement def GPT001_TankCount {
        doc /* GPT-001 [topology] exactly four named propellant-tank owners are present and visible. */
    }
    requirement def GPT002_TankRetention {
        doc /* GPT-002 [visual] every tank exposes a body, three retention bands, a lower cradle plate with a seated adapter pad, and the retained end hardware listed by the component. */
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
        doc /* GPT-006 [visual] each tank body is a compact metric sphere with a gold-wrapped pressure-vessel silhouette, seated adapter hardware, and coaxial necks; no floating end hardware or flat-ended cylinder is permitted. */
    }
    requirement def GPT007_TankServiceHardware {
        doc /* GPT-007 [visual] each tank includes three thin retention straps plus the shoulder collars and valve/cap hardware with the metric proxy dimensions defined by the component. */
    }
    requirement def GPT008_TankOrientation {
        doc /* GPT-008 [orientation] the spherical body and all axial tank hardware are Y-up; the authored envelope is centered on the tank datum without hidden rotations or through-geometry. */
    }
    requirement def GPT009_TankDeckSeat {
        doc /* GPT-009 [interface] the lower cradle plate and adapter pad seat the tank above the avionics-deck top datum with no tank hardware penetrating the deck. */
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
