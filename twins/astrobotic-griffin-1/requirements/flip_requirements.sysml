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
  }

    requirement def FLIPV001_RoverPresentation {
        doc /* FGV-001 [visual] the review shall show FLIP as a four-wheel directional rover with steerable front/rear wheel stations, its sensor mast, and collapsible solar assembly. */
    }

    requirement fvg001 : FLIPV001_RoverPresentation { subject rover : FlipRover; }

    verification def Verify_FLIPVisualRequirements {
        subject rover : FlipRover;
        verify fvg001;
    }
}
