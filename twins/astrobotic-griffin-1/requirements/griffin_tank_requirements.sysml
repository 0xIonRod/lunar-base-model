package GriffinTankRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::String;
    private import VectorValues::CartesianThreeVectorValue;

    enum def GriffinTankGeometryShape { Sphere; Cylinder; Cone; Cube; }
    enum def GriffinTankAxis { Y; }
    enum def GriffinTankPartName {
        MliTank;
        TankBandA; TankBandB; TankBandC; TankCradle; TankCradlePad;
        TankSupportPost; TankNeckTop; TankNeckBottom;
        TankShoulderTop; TankShoulderBottom; TankValveTop; TankValveBottom;
        TankValveCapTop; TankValveCapBottom; TankTransitionTop; TankTransitionBottom;
        TankMountBrackets; TankMountBracketPX; TankMountBracketNX;
        TankMountBracketPZ; TankMountBracketNZ;
    }

    part def GriffinPropellantTankAssembly {
        attribute usdRootPath : String = "/World/Griffin1";
        attribute componentAsset : String = "components/lander/griffin_tank_visual.usda";
        attribute bodyName : GriffinTankPartName = "MliTank";
        attribute retentionBandNames : GriffinTankPartName[3] =
            ("TankBandA", "TankBandB", "TankBandC");
        attribute retentionBandShape : GriffinTankGeometryShape = "Cylinder";
        attribute axialHardwareShape : GriffinTankGeometryShape = "Cylinder";
        attribute transitionShape : GriffinTankGeometryShape = "Cone";
        attribute cradleName : GriffinTankPartName = "TankCradle";
        attribute cradlePadName : GriffinTankPartName = "TankCradlePad";
        attribute childNames : GriffinTankPartName[17] =
            ("TankBandA", "TankBandB", "TankBandC", "TankCradle", "TankCradlePad",
             "TankSupportPost", "TankNeckTop", "TankNeckBottom", "TankShoulderTop",
             "TankShoulderBottom", "TankValveTop", "TankValveBottom", "TankValveCapTop",
             "TankValveCapBottom", "TankTransitionTop", "TankTransitionBottom", "MliTank");
        attribute endHardwareNames : GriffinTankPartName[2] = ("TankNeckTop", "TankNeckBottom");
        attribute serviceHardwareNames : GriffinTankPartName[6] =
            ("TankShoulderTop", "TankShoulderBottom", "TankValveTop", "TankValveBottom",
             "TankValveCapTop", "TankValveCapBottom");
        attribute axialHardwareNames : GriffinTankPartName[11] =
            ("TankNeckTop", "TankNeckBottom", "TankShoulderTop", "TankShoulderBottom",
             "TankValveTop", "TankValveBottom", "TankValveCapTop", "TankValveCapBottom",
             "TankTransitionTop", "TankTransitionBottom", "TankSupportPost");
        attribute tankAxis : GriffinTankAxis = "Y";
        attribute bodyShape : GriffinTankGeometryShape = "Sphere";
        attribute bodyCenter : CartesianThreeVectorValue = (0.0, 0.0, 0.0);
        attribute bodyRadiusM : Real = 0.84;
        attribute minimumInstalledBodyDiameterM : Real = 1.51;
        attribute neckRadiusM : Real = 0.14;
        attribute neckHeightM : Real = 0.12;
        attribute shoulderCollarRadiusM : Real = 0.54;
        attribute shoulderCollarHeightM : Real = 0.12;
        attribute valveRadiusM : Real = 0.055;
        attribute valveHeightM : Real = 0.06;
        attribute valveCapRadiusM : Real = 0.09;
        attribute valveCapHeightM : Real = 0.12;
        attribute transitionShoulderRadiusM : Real = 0.54;
        attribute transitionNeckRadiusM : Real = 0.14;
        attribute transitionHeightM : Real = 0.18;
        attribute transitionRadiusM : Real = 0.54;
        // Axial centers are explicit interface datums.  The verifier mirrors
        // them about the tank datum for the lower train and checks the cradle
        // against the lower service-skirt top in the shared assembly frame.
        attribute shoulderCenterYM : Real = 0.40;
        attribute transitionCenterYM : Real = 0.47;
        attribute neckCenterYM : Real = 0.62;
        attribute valveCenterYM : Real = 0.71;
        attribute capCenterYM : Real = 0.80;
        // Source evidence is held once per requirement in
        // GriffinRequirementSources::evidence_gpt_*; these are replaceable
        // visual-study dimensions, not a released pressure-vessel ICD.
        // Each band radius follows the shell cross-section at its Y station,
        // plus a small radial allowance for the retaining strap.
        attribute bandRadiusByCenterM : Real[3] = (0.82, 0.86, 0.82);
        attribute bandHeightM : Real = 0.045;
        attribute bandCenterYM : Real[3] = (-0.24, 0.0, 0.24);
        // The cradle is a round seating ring, not a square placeholder plate.
        // Its radius/height are authored directly on a unit Cylinder, while
        // its position is derived in Rhai from the shared lower-skirt datum,
        // the tank station/scale, and the minimum physical clearance.
        attribute cradleShape : GriffinTankGeometryShape = "Cylinder";
        attribute cradleRadiusM : Real = 0.74;
        attribute cradleHeightM : Real = 0.16;
        attribute cradlePadShape : GriffinTankGeometryShape = "Cube";
        attribute cradlePadWidthM : Real = 1.08;
        attribute cradlePadDepthM : Real = 1.08;
        attribute cradlePadHeightM : Real = 0.13;
        attribute supportName : GriffinTankPartName = "TankSupportPost";
        attribute supportShape : GriffinTankGeometryShape = "Cylinder";
        attribute supportRadiusM : Real = 0.14;
        attribute minimumSkirtClearanceM : Real = 0.02;
        // Component-local mount sizes are matched to the 0.84 m shell and the
        // 1.08 m square pad. The Editor builder derives each brace endpoint
        // from the shared pad datum and 12 degree inward tilt.
        attribute bracketGroupName : GriffinTankPartName = "TankMountBrackets";
        attribute bracketNames : GriffinTankPartName[4] =
            ("TankMountBracketPX", "TankMountBracketNX", "TankMountBracketPZ", "TankMountBracketNZ");
        attribute bracketShape : GriffinTankGeometryShape = "Cube";
        attribute bracketLengthM : Real = 0.18;
        attribute bracketWidthM : Real = 0.10;
        attribute bracketDepthM : Real = 0.10;
        attribute bracketCenterOffsetM : Real = 0.46;
        attribute bracketTiltDeg : Real = 12.0;
        attribute bracketOrientationConvention : String = "radial: each brace top slopes inward toward the tank datum; PX/NX/PZ/NZ use X rotation signs (-,-,+,+) and Z rotation signs (-,+,-,+) degrees";
    }

    requirement def GPT001_TankCount {
        doc /* GPT-001 [topology] exactly four named propellant-tank owners are present and visible. */
    }
    requirement def GPT002_TankRetention {
        doc /* GPT-002 [visual] every tank exposes a body, three retention bands, a lower circular cradle ring with a seated adapter pad, and the retained end hardware listed by the component. */
    }
    requirement def GPT003_TankStatus {
        doc /* GPT-003 [traceability] tank geometry is labelled as a metric visual proxy until the mechanical ICD is available. */
    }
    requirement def GPT004_TankTraceability {
        doc /* GPT-004 [evidence] tank identities resolve from GriffinVisualConfigurationRequirements, their cardinality agrees with the typed lander count, and each instance is checked individually. */
    }
    requirement def GPT005_TankPlacement {
        doc /* GPT-005 [layout] each tank root transform matches its ordered typed cardinal-axis Position datum; all four tanks share the bus-origin plane and provide at least 0.06 m inter-instance and frame-envelope clearance while fitting within the published 4.5 m Griffin footprint. Station coordinates and installed envelope are replaceable study assumptions, not a flight ICD. */
    }
    requirement def GPT006_TankEndHardware {
        doc /* GPT-006 [visual] each tank body is a near-spherical 0.84 m nominal-radius metric proxy with three shell-conforming retention bands, tapered polar transitions, seated adapter hardware, and coaxial necks. Its 0.90 assembly scale gives a 1.512 m installed body diameter, satisfying the typed 1.51 m minimum. Astrobotic identifies four Griffin-1 COPV propellant tanks, but does not publish their vessel geometry; the vessel size, assembly scale, and interface details are explicit replaceable study assumptions, not flight data. */
    }
    requirement def GPT007_TankServiceHardware {
        doc /* GPT-007 [visual] each tank includes three thin cylindrical retention bands plus the shoulder collars and valve/cap hardware with the metric proxy dimensions defined by the component. */
    }
    requirement def GPT008_TankOrientation {
        doc /* GPT-008 [orientation] the spherical body is centered on the tank datum and all axial service hardware follows the declared local Y axis; no hidden rotations or through-geometry are permitted. */
    }
    requirement def GPT009_TankDeckSeat {
        doc /* GPT-009 [interface] the component-local lower cradle is a 0.74 m radius x 0.16 m high Cylinder and its 1.08 m x 1.08 m x 0.13 m adapter pad seats above the lower service-skirt datum; the assembly scale is applied once to this local envelope. A coaxial support post bridges the pad to the lower neck, preserving the typed skirt gap. These mount sizes are study assumptions because the attachment ICD is unpublished. */
    }
    requirement def GPT010_TankMounting {
        doc /* GPT-010 [interface/visual] four 0.10 m square-section, 0.18 m component-local braces bridge the adapter pad to the 0.84 m nominal-radius spherical shell. Their four signed X/Z rotations are mirrored and slope inward by 12 degrees; each endpoint closes to the spherical envelope from the typed pad top and 0.46 m radial offset. The local sizes are scaled once at assembly and remain replaceable study assumptions, since exact flight attachment details are unpublished. */
    }
    requirement def GPT011_ComponentIdentity {
        doc /* GPT-011 [configuration] each tank instance shall use the declared replaceable tank asset, the Y-axis local frame, and the complete named child list from this component contract. */
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
    requirement gpt010 : GPT010_TankMounting { subject tanks : GriffinPropellantTankAssembly; }
    requirement gpt011 : GPT011_ComponentIdentity { subject tanks : GriffinPropellantTankAssembly; }

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
        verify gpt010;
        verify gpt011;
    }
}
