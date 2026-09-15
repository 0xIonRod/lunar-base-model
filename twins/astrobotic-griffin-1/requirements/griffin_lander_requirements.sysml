package GriffinLanderRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import ScalarValues::String;

    // This package owns the standalone lander visual-component contract. The
    // Griffin integration package owns mission sequencing; the ramp package
    // owns the optional deployable ramp; this file owns the reusable bus,
    // tanks, legs, engines, and solar component assembly.
    part def GriffinLanderComponent {
        attribute componentName : String = "Griffin1";
        attribute bodyProfile : String = "hexagonal-prism";
        attribute bodyWidthM : Real = 5.20;
        attribute bodyDepthM : Real = 5.30;
        attribute bodyHeightM : Real = 2.90;
        // Upper avionics-deck top datum used by tank seating checks.
        attribute avionicsDeckTopY : Real = 5.00;
        // Presentation station datums.  These are the single source of truth
        // for the component roots in both the isolated Editor assembly and
        // the component verifiers; the values are metre/Y-up study values,
        // not hidden CAD dimensions.
        attribute busMountY : Real = 3.20;
        attribute tankStationX : String = "1.30,-1.30,1.30,-1.30";
        // The tank datum is above the avionics deck.  The value includes the
        // component-local cradle/end-fitting envelope, so no tank hardware
        // intersects the deck in the composed stage.
        attribute tankStationY : String = "6.25,6.25,6.25,6.25";
        attribute tankStationZ : String = "-1.15,-1.15,1.15,1.15";
        attribute legStationX : String = "1.75,-1.75,1.75,-1.75";
        attribute legStationY : String = "2.35,2.35,2.35,2.35";
        attribute legStationZ : String = "-1.25,-1.25,1.25,1.25";
        attribute solarStationX : String = "2.70,-2.70";
        attribute solarStationY : String = "3.35,3.35";
        attribute solarStationZ : String = "0.0,0.0";
        attribute engineStationX : String = "0.0,1.0,-1.0,0.0,0.0,0.9,-0.9";
        attribute engineStationY : String = "1.75,1.75,1.75,1.75,1.75,1.75,1.75";
        attribute engineStationZ : String = "0.0,0.0,0.0,1.0,-1.0,0.9,-0.9";
        attribute engineClusterWidthM : Real = 3.20;
        attribute engineClusterDepthM : Real = 3.20;
        attribute engineSkirtHeightM : Real = 0.20;
        attribute engineSkirtRailSectionM : Real = 0.20;
        attribute engineBellClearanceM : Real = 0.10;
        attribute engineMountYM : Real = 1.75;
        attribute legCount : Integer = 4;
        attribute tankCount : Integer = 4;
        attribute engineCount : Integer = 7;
        attribute solarArrayCount : Integer = 2;
        attribute legNames : String = "LegPX,LegNX,LegPZ,LegNZ";
        attribute tankNames : String = "TankPX,TankNX,TankPZ,TankNZ";
        attribute engineNames : String = "Engine01,Engine02,Engine03,Engine04,Engine05,Engine06,Engine07";
        attribute solarArrayNames : String = "SolarPanelPort,SolarPanelStarboard";
        attribute geometryStatus : String = "metric visual study proxy; flight CAD/ICD TBD";
        attribute productReference : String = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute missionReference : String = "https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/";
        attribute dataSheetReference : String = "https://science.nasa.gov/wp-content/uploads/2023/11/astrobotic-lunar-landers-pug.pdf";
        attribute sourceFact : String = "Griffin is a medium-class, flexible-payload lander with four shock-absorbing legs, seven main engines and optional rover egress ramps";
        attribute sourceRationale : String = "This package is the shared source for the reusable lander datum and ordered component station lists; subsystem contracts reference it rather than copying coordinates";
    }

    requirement def GLR001_BusTopology {
        doc /* GLR-001 [visual] the reusable lander shall expose a named hexagonal bus with a white equipment body and inspectable perimeter frame. */
    }
    requirement def GLR002_LandingLegs {
        doc /* GLR-002 [visual] exactly four named landing-leg components shall expose struts and a visible foot pad. */
    }
    requirement def GLR003_PropellantTanks {
        doc /* GLR-003 [visual] exactly four named propellant-tank components shall expose a tank body and retention bands/cradle. */
    }
    requirement def GLR004_EngineCluster {
        doc /* GLR-004 [visual] exactly seven named main-engine components shall expose a visible bell and throat. */
    }
    requirement def GLR005_SolarArrays {
        doc /* GLR-005 [visual] two named solar-array components shall expose frame and cell geometry. */
    }
    requirement def GLR006_MetricEnvelope {
        doc /* GLR-006 [geometry] the bus visual envelope shall match the authored metric width, depth, and height study datums. */
    }
    requirement def GLR007_Traceability {
        doc /* GLR-007 [evidence] component names, counts, status, and public references shall come from this SysML package and be checked by a Twin Rhai observer. */
    }
    requirement def GLR008_StationPlacement {
        doc /* GLR-008 [layout] every replaceable lander component root uses the ordered metric station datums in this package; no verifier or builder owns a second placement table. */
    }

    requirement glr001 : GLR001_BusTopology { subject lander : GriffinLanderComponent; }
    requirement glr002 : GLR002_LandingLegs { subject lander : GriffinLanderComponent; }
    requirement glr003 : GLR003_PropellantTanks { subject lander : GriffinLanderComponent; }
    requirement glr004 : GLR004_EngineCluster { subject lander : GriffinLanderComponent; }
    requirement glr005 : GLR005_SolarArrays { subject lander : GriffinLanderComponent; }
    requirement glr006 : GLR006_MetricEnvelope { subject lander : GriffinLanderComponent; }
    requirement glr007 : GLR007_Traceability { subject lander : GriffinLanderComponent; }
    requirement glr008 : GLR008_StationPlacement { subject lander : GriffinLanderComponent; }

    verification def Verify_GriffinLanderRequirements {
        subject lander : GriffinLanderComponent;
        verify glr001;
        verify glr002;
        verify glr003;
        verify glr004;
        verify glr005;
        verify glr006;
        verify glr007;
        verify glr008;
    }
}
