// Runtime dimensions revised 2026-09-30 from the reference-informed CAD study.
// Geometry promotion does not promote CAD kinematics or qualify mission dynamics.
package FlipRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::String;
    private import GriffinRequirementSources::TwinAssetPath;
    private import GriffinRequirementSources::UsdPrimPath;
    private import FlipCadRequirements::CadStudy;

    enum def FlipWheelStation { FL; RL; FR; RR; }
    enum def FlipSteeringMode { ackermann; crab; }

    // CAD-study dimensions are owned by FlipCadRequirements::CadStudy and
    // converted to the SI runtime frame here. Rover-specific simulation policy
    // remains owned by this part definition.
    part def FlipRover {
        doc /* CAD body, wheel, and baseplate dimensions are owned by FlipCadRequirements::CadStudy and converted to SI for the Twin frame (CAD X,Y,Z maps to USD Y,Z,X). The public skid-steer architecture is distinct from this Twin's Ackermann route-control approximation. Lower-frame thickness, equipment position, fixed panel mount, suspension rest length, mass, COM, and inertia remain replaceable simulation-study values. Rationale and confidence: griffin-size-evidence.md. */
        attribute componentAsset : TwinAssetPath = "vehicles/flip.usda";
        attribute usdRootPath : UsdPrimPath = "/World/FLIP";
        attribute localFrame : String = "Y-up SI metres; X longitudinal, Z lateral; CAD (X,Y,Z) maps to USD (Y,Z,X)";
        attribute flipMassStudyKg : Real = FlipCadRequirements::CadStudy::legacyRuntimeMassKg;
        attribute massPropertiesStatus : String = "study proxy; supplier mass properties and wheel loads TBD";
        attribute batteryNominalVoltageV : Real = 28.0;
        attribute centerOfMassM : Real[3] = (0.0, -0.05, 0.0);
        attribute diagonalInertiaKgM2 : Real[3] = (240.0, 337.5, 145.5);
        attribute flipPayloadCapacityKg : Real = FlipCadRequirements::CadStudy::historicalPayloadCapacityKg;
        attribute egressMode : String = "direct top-deck egress is public; ramp path is optional study branch";
        attribute solarArrayMode : String = "collapsible public concept; fixed panel is current visual proxy";
        attribute mobilityStatus : String = "mobility, power, thermal, and wheel parameters are study proxies";
        attribute exactVehicleIcdStatus : String = "TBD";
        attribute wheelRadiusM : Real = FlipCadRequirements::CadStudy::wheelBandRadiusMm / FlipCadRequirements::CadStudy::millimetresPerMetre;
        attribute wheelWidthM : Real = FlipCadRequirements::CadStudy::wheelWidthMm / FlipCadRequirements::CadStudy::millimetresPerMetre;
        attribute wheelStations : FlipWheelStation[4] = ("FL", "RL", "FR", "RR");
        // Ackermann is the current route-control approximation; it is not a
        // claim that the public skid-steer hardware has Ackermann kinematics.
        attribute missionSteeringMode : FlipSteeringMode = "ackermann";
        attribute chassisWidthM : Real = FlipCadRequirements::CadStudy::bodyWidthMm / FlipCadRequirements::CadStudy::millimetresPerMetre;
        attribute chassisLengthM : Real = FlipCadRequirements::CadStudy::bodyLengthMm / FlipCadRequirements::CadStudy::millimetresPerMetre;
        attribute chassisHeightM : Real = .12;
        attribute equipmentBoxWidthM : Real = FlipCadRequirements::CadStudy::baseplateWidthMm / FlipCadRequirements::CadStudy::millimetresPerMetre;
        attribute equipmentBoxHeightM : Real = FlipCadRequirements::CadStudy::bodyHeightMm / FlipCadRequirements::CadStudy::millimetresPerMetre;
        attribute equipmentBoxDepthM : Real = FlipCadRequirements::CadStudy::baseplateLengthMm / FlipCadRequirements::CadStudy::millimetresPerMetre;
        attribute equipmentBoxCenterYM : Real = chassisHeightM / 2.0 + equipmentBoxHeightM / 2.0;
        attribute payloadDeckWidthM : Real = FlipCadRequirements::CadStudy::baseplateWidthMm / FlipCadRequirements::CadStudy::millimetresPerMetre;
        attribute payloadDeckThicknessM : Real = .04;
        attribute payloadDeckDepthM : Real = FlipCadRequirements::CadStudy::baseplateLengthMm / FlipCadRequirements::CadStudy::millimetresPerMetre;
        attribute payloadDeckCenterYM : Real = equipmentBoxCenterYM + equipmentBoxHeightM / 2.0 + payloadDeckThicknessM / 2.0;
        attribute sensorMastHeightM : Real = 0.70;
        // One station definition drives the simulation, Editor projection,
        // requirements, and wheel-contact verification.
        // +X is the study travel direction; FL/FR are the positive-X axle.
        // This is a reconstruction frame choice, not a supplier front datum.
        // Core axle/steering-axis cross product and Modelica heading use this
        // same basis. Egress replay 985b084/24dd835fa exposed the old -Z
        // assumption: GR-004-route-stall at tick 12762, throttle zero.
        attribute forwardYawOffsetRad : Real = -1.5707963267948966;
        attribute wheelStationX : Real[4] = (
            FlipCadRequirements::CadStudy::wheelbaseMm / (2.0 * FlipCadRequirements::CadStudy::millimetresPerMetre),
            -FlipCadRequirements::CadStudy::wheelbaseMm / (2.0 * FlipCadRequirements::CadStudy::millimetresPerMetre),
            FlipCadRequirements::CadStudy::wheelbaseMm / (2.0 * FlipCadRequirements::CadStudy::millimetresPerMetre),
            -FlipCadRequirements::CadStudy::wheelbaseMm / (2.0 * FlipCadRequirements::CadStudy::millimetresPerMetre));
        attribute wheelStationY : Real[4] = (-.05, -.05, -.05, -.05);
        attribute wheelStationZ : Real[4] = (
            -FlipCadRequirements::CadStudy::trackMm / (2.0 * FlipCadRequirements::CadStudy::millimetresPerMetre),
            -FlipCadRequirements::CadStudy::trackMm / (2.0 * FlipCadRequirements::CadStudy::millimetresPerMetre),
             FlipCadRequirements::CadStudy::trackMm / (2.0 * FlipCadRequirements::CadStudy::millimetresPerMetre),
             FlipCadRequirements::CadStudy::trackMm / (2.0 * FlipCadRequirements::CadStudy::millimetresPerMetre));
        // The suspension extension is a Twin simulation assumption shared by
        // the composed vehicle and the independently checked visual module.
        // The core ray length includes wheel radius; 0.30 m is the
        // estimated strut extension, not the whole mount-to-ground ray.
        // At replay-2 tick 28045 the shorter ray started below the apron
        // and front-left contact vanished. No stiffness/torque is increased.
        attribute suspensionExtensionM : Real = .30;
        attribute suspensionRestLengthM : Real = wheelRadiusM + suspensionExtensionM;
        // Assembly-owned suspension connector dimensions are shared by the
        // Editor builder and the component requirement source.
        attribute suspensionStrutScale : Real[3] = (0.14, 0.36, 0.14);
        attribute suspensionStrutOffset : Real[3] = (0.0, 0.20, 0.0);
        // The wheel hubs sit outboard of the lower-frame side datum.  These
        // metric values describe the render-only bridge and its hub knuckle;
        // they are consumed by the typed Editor builder and the Rhai gate.
        attribute suspensionArmScale : Real[3] = (.26, .12, .12);
        attribute suspensionArmOffsetM : Real = .13;
        attribute suspensionKnuckleRadiusM : Real = 0.18;
        attribute suspensionKnuckleWidthM : Real = 0.36;
        // Estimated fixed-panel mount above the reconstructed equipment roof;
        // the real collapsible panel mechanism remains unpromoted.
        attribute solarArrayMount : Real[3] = (0.0, .55, 0.0);
        // The 18 degree tilt is a conservative review-study angle above the
        // local deck; it does not imply a supplier-certified deployment joint.
        attribute solarArrayTiltDeg : Real = 18.0;
    }

    requirement def FLIPV001_RoverPresentation {
        doc /* FGV-001 [integration] the composed FLIP vehicle shall include its four typed wheel stations, chassis, sensor mast, solar array, and physical mobility model. */
    }

    requirement def FLIPV002_ChassisEnvelope {
        doc /* FGV-002 [geometry] the reusable FLIP visual chassis shall use the authored metric width and length envelope. */
    }

    requirement def FLIPV003_WheelStations {
        doc /* FGV-003 [topology] each of the four typed wheel stations shall use one physical wheel cylinder with the authored envelope and a shared tire material. The material supplies tread, hub and rim appearance; no second authored tire surface is permitted. The detailed ownership contract is FWW-002 in FlipWheelRequirements. */
    }

    requirement def FLIPV004_SensorAndPower {
        doc /* FGV-004 [visual] the rover shall expose an inspectable sensor mast and collapsible solar-array subassembly. */
    }

    requirement def FLIPV005_Traceability {
        doc /* FGV-005 [evidence] component dimensions, wheel identities, and steering configuration shall resolve from typed SysML attributes and linked evidence. */
    }
    requirement def FLIPV006_ChassisGeometry {
        doc /* FGV-006 [geometry] the visual chassis, equipment box, and payload deck shall match their single source-owned metric envelopes and centers. */
    }
    requirement def FLIPV007_MassPropertyDatum {
        doc /* FGV-007 [physics boundary] the current rover study shall expose finite mass, center-of-mass, and diagonal-inertia datums with explicit study status; these values are not supplier-certified flight data. */
    }
    requirement def FLIPV008_WheelEnvelope {
        doc /* FGV-008 [geometry] each wheel shall use the single SysML-owned radius and width, and each active wheel station shall use the same station datums in simulation and presentation. */
    }
    requirement def FLIPV009_MissionSteeringMode {
        doc /* FGV-009 [behavior] the authored Griffin surface route shall use the source-owned Twin steering approximation before issuing route torque. This simulation policy does not redefine FLIP's public skid-steer architecture; controller behavior remains a separate validation item. */
    }
    requirement def FLIPV010_PhysicalWheelSupportEnvelope {
        doc /* FGV-010 [simulation] physical wheel stations and the suspension extension shall be driven by the shared vehicle datums and pass the deployed ramp wheel-contact replay. */
    }

    requirement <'FGV-001'> fvg001 : FLIPV001_RoverPresentation { subject rover : FlipRover; }
    requirement <'FGV-002'> fvg002 : FLIPV002_ChassisEnvelope { subject rover : FlipRover; }
    requirement <'FGV-003'> fvg003 : FLIPV003_WheelStations { subject rover : FlipRover; }
    requirement <'FGV-004'> fvg004 : FLIPV004_SensorAndPower { subject rover : FlipRover; }
    requirement <'FGV-005'> fvg005 : FLIPV005_Traceability { subject rover : FlipRover; }
    requirement <'FGV-006'> fvg006 : FLIPV006_ChassisGeometry { subject rover : FlipRover; }
    requirement <'FGV-007'> fvg007 : FLIPV007_MassPropertyDatum { subject rover : FlipRover; }
    requirement <'FGV-008'> fvg008 : FLIPV008_WheelEnvelope { subject rover : FlipRover; }
    requirement <'FGV-009'> fvg009 : FLIPV009_MissionSteeringMode { subject rover : FlipRover; }
    requirement <'FGV-010'> fvg010 : FLIPV010_PhysicalWheelSupportEnvelope { subject rover : FlipRover; }

    verification def Verify_FLIPComponentRequirements {
        subject rover : FlipRover;
        objective {
            verify fvg001;
            verify fvg002;
            verify fvg003;
            verify fvg004;
            verify fvg005;
            verify fvg006;
            verify fvg007;
            verify fvg008;
            verify fvg009;
            verify fvg010;
        }
    }
}
