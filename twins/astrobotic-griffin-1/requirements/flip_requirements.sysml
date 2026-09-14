package FlipRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import ScalarValues::String;

    // Rover-owned values stay in this source, while Griffin owns only the
    // integration requirements that reference the rover interface.
    part def FlipRover {
        attribute flipMassStudyKg : Real = 450.0;
        attribute flipPayloadCapacityKg : Real = 30.0;
        attribute wheelCount : Integer = 4;
        attribute wheelCountStatus : String = "four-wheel directional architecture proxy; supplier ICD TBD";
        attribute egressMode : String = "direct top-deck egress is public; ramp path is optional study branch";
        attribute solarArrayMode : String = "collapsible public concept; fixed panel is current visual proxy";
        attribute mobilityStatus : String = "mobility, power, thermal, and wheel parameters are study proxies";
        attribute exactVehicleIcdStatus : String = "TBD";
        attribute visualRoverName : String = "FLIP";
        attribute visualRoverWheelRadiusM : Real = 0.45;
        attribute visualRoverWheelCount : Integer = 4;
        attribute visualWheelNames : String = "FL,RL,FR,RR";
        attribute frontSteeringAngleDeg : Real = -12.0;
        attribute rearSteeringAngleDeg : Real = 8.0;
        attribute chassisWidthM : Real = 4.40;
        attribute chassisLengthM : Real = 2.76;
        attribute sensorMastHeightM : Real = 0.70;
        attribute componentReference : String = "https://www.astrolab.space/flip/";
        attribute missionReference : String = "https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/";
  }

    requirement def FLIPV001_RoverPresentation {
        doc /* FGV-001 [visual] the review shall show FLIP as a four-wheel directional rover with steerable front/rear wheel stations, its sensor mast, and collapsible solar assembly. */
    }

    requirement def FLIPV002_ChassisEnvelope {
        doc /* FGV-002 [geometry] the reusable FLIP visual chassis shall use the authored metric width and length envelope. */
    }

    requirement def FLIPV003_WheelStations {
        doc /* FGV-003 [topology] exactly four named directional wheel stations shall expose tire, hub, and cap geometry with the authored radius. */
    }

    requirement def FLIPV004_SensorAndPower {
        doc /* FGV-004 [visual] the rover shall expose an inspectable sensor mast and collapsible solar-array subassembly. */
    }

    requirement def FLIPV005_Traceability {
        doc /* FGV-005 [evidence] the component dimensions, wheel identities, steering angles, and public references shall be read from this SysML source by a Twin Rhai verifier. */
    }

    requirement fvg001 : FLIPV001_RoverPresentation { subject rover : FlipRover; }
    requirement fvg002 : FLIPV002_ChassisEnvelope { subject rover : FlipRover; }
    requirement fvg003 : FLIPV003_WheelStations { subject rover : FlipRover; }
    requirement fvg004 : FLIPV004_SensorAndPower { subject rover : FlipRover; }
    requirement fvg005 : FLIPV005_Traceability { subject rover : FlipRover; }

    verification def Verify_FLIPVisualRequirements {
        subject rover : FlipRover;
        verify fvg001;
    }

    verification def Verify_FLIPComponentRequirements {
        subject rover : FlipRover;
        verify fvg001;
        verify fvg002;
        verify fvg003;
        verify fvg004;
        verify fvg005;
    }
}
