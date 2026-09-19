package FlipRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import ScalarValues::String;

    // Rover-owned values stay in this source, while Griffin owns only the
    // integration requirements that reference the rover interface.
    part def FlipRover {
        attribute componentAsset : String = "vehicles/flip_visual.usda";
        attribute usdRootPath : String = "/World/FLIP";
        attribute localFrame : String = "Y-up, right-handed, SI metres; X is lateral and Z is longitudinal";
        attribute visualChildNames : String[7] = ("Chassis", "SensorMast", "SolarArray", "Suspension_FL", "Suspension_RL", "Suspension_FR", "Suspension_RR");
        attribute visualConfiguration : String = "four directional wheels, white equipment box, sensor mast, fixed solar-array proxy";
        attribute flipMassStudyKg : Real = 450.0;
        attribute massPropertiesStatus : String = "study proxy; supplier mass properties and wheel loads TBD";
        attribute centerOfMassM : Real[3] = (0.0, -0.05, 0.0);
        attribute diagonalInertiaKgM2 : Real[3] = (240.0, 337.5, 145.5);
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
        attribute visualWheelNames : String[4] = ("FL", "RL", "FR", "RR");
        attribute frontSteeringAngleDeg : Real = -12.0;
        attribute rearSteeringAngleDeg : Real = 8.0;
        // Mission route policy uses the finite-turn mode; the parallel/crab
        // mode remains available as an operator experiment through the
        // Twin-local control helper.
        attribute missionSteeringMode : String = "ackermann";
        attribute chassisWidthM : Real = 4.40;
        attribute chassisLengthM : Real = 2.76;
        attribute chassisHeightM : Real = 0.76;
        attribute equipmentBoxWidthM : Real = 3.90;
        attribute equipmentBoxHeightM : Real = 1.44;
        attribute equipmentBoxDepthM : Real = 2.44;
        attribute equipmentBoxCenterYM : Real = 0.45;
        attribute payloadDeckWidthM : Real = 3.44;
        attribute payloadDeckThicknessM : Real = 0.20;
        attribute payloadDeckDepthM : Real = 2.16;
        attribute payloadDeckCenterYM : Real = 0.92;
        attribute sensorMastHeightM : Real = 0.70;
        // Four-wheel station datums are ordered exactly as visualWheelNames.
        // They are shared by the Editor builder and the wheel verifier.
        attribute wheelStationX : Real[4] = (-1.75, -1.75, 1.75, 1.75);
        attribute wheelStationY : Real[4] = (-0.42, -0.42, -0.42, -0.42);
        attribute wheelStationZ : Real[4] = (-1.15, 1.15, -1.15, 1.15);
        // Physical suspension stations are a separate contract from the
        // render-only station datums above.  The order is FL,RL,FR,RR, just
        // like visualWheelNames.  These are current simulation-study values:
        // The body/chassis and wheel are a study proxy, not an as-built FLIP
        // ICD.  The -0.75 m station is the authored ramp-compatible study
        // datum for the 0.45 m wheel.  The deployed physical ramp is a
        // 45.7457 degree study slope; a 0.70 m ray could not reach its first
        // downhill contact from the released deck envelope, so the physical
        // realization uses the explicitly separate 1.20 m ramp-transition
        // suspension envelope below.  This is a Twin study assumption, not
        // an as-built FLIP datum.
        attribute physicalWheelStationX : Real[4] = (-0.95, -0.95, 0.95, 0.95);
        attribute physicalWheelStationY : Real[4] = (-0.75, -0.75, -0.75, -0.75);
        attribute physicalWheelStationZ : Real[4] = (-1.05, 1.05, -1.05, 1.05);
        attribute physicalSuspensionRestLengthM : Real = 1.20;
        // Assembly-owned visual connector dimensions, ordered by wheel
        // station.  The replaceable wheel asset remains responsible for tire
        // geometry; these values describe the authored station-to-chassis
        // suspension proxy in the visual vehicle layer.
        attribute suspensionStrutScale : Real[3] = (0.14, 0.36, 0.14);
        attribute suspensionStrutOffset : Real[3] = (0.0, 0.20, 0.0);
        // The wheel hubs sit outboard of the lower-frame side datum.  These
        // metric values describe the render-only bridge and its hub knuckle;
        // they are consumed by the typed Editor builder and the Rhai gate.
        attribute suspensionArmScale : Real[3] = (0.65, 0.16, 0.16);
        attribute suspensionArmOffsetM : Real = 0.325;
        attribute suspensionKnuckleRadiusM : Real = 0.18;
        attribute suspensionKnuckleWidthM : Real = 0.36;
        attribute visualWheelWidthM : Real = 0.30;
        attribute wheelAxis : String = "Z";
                        // The solar array is centered over the equipment-box roof at 1.30 m above datum so the 3.30 x 2.10 m visual panel fits inside the 4.40 x 2.76 m rover envelope; this is a geometry study assumption because supplier deck coordinates are not public.
                        attribute solarArrayMount : Real[3] = (0.0, 1.30, 0.00);
                // The 18 degree tilt is a conservative review-study angle above the local deck: it keeps a fixed panel readable to a high solar-elevation camera without implying a supplier-certified deployment joint; optimize it when the vehicle ICD is available.
        attribute solarArrayTiltDeg : Real = 18.0;
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
    requirement def FLIPV006_ChassisGeometry {
        doc /* FGV-006 [geometry] the visual chassis shall be 4.40 m wide, 2.76 m long, and 0.76 m high; its equipment box and payload deck shall use the declared metric envelopes and centers. */
    }
    requirement def FLIPV007_MassPropertyDatum {
        doc /* FGV-007 [physics boundary] the current rover study shall expose finite mass, center-of-mass, and diagonal-inertia datums with explicit study status; these values are not supplier-certified flight data. */
    }
    requirement def FLIPV008_WheelEnvelope {
        doc /* FGV-008 [geometry] each directional wheel shall use the Z-axis visual wheel envelope with radius 0.45 m and width 0.30 m, while the active wheel station remains owned by the rover assembly. */
    }
    requirement def FLIPV009_MissionSteeringMode {
        doc /* FGV-009 [behavior] the authored Griffin surface route shall select the finite-turn Ackermann steering mode before issuing route torque; parallel/crab steering remains an explicit operator experiment. */
    }
    requirement def FLIPV010_PhysicalWheelSupportEnvelope {
        doc /* FGV-010 [physics boundary] the four physical FLIP suspension station datums shall be explicit and separate from visual presentation stations; the ramp-transition study realization shall use a 1.20 m support-ray envelope so the front axle can acquire the authored 45.7457 degree, 8.00 m deck-to-terrain ramp before the chassis falls through the suspension envelope. Source: the composed Griffin physical-ramp and FLIP wheel geometry in this Twin. Rationale: the 0.70 m baseline ray was observed to end above the first downhill ramp contact; 1.20 m is the smallest rounded study value that covers the measured deck-to-ramp transition without changing the wheel station, while supplier suspension data remains unknown. */
    }

    requirement fvg001 : FLIPV001_RoverPresentation { subject rover : FlipRover; }
    requirement fvg002 : FLIPV002_ChassisEnvelope { subject rover : FlipRover; }
    requirement fvg003 : FLIPV003_WheelStations { subject rover : FlipRover; }
    requirement fvg004 : FLIPV004_SensorAndPower { subject rover : FlipRover; }
    requirement fvg005 : FLIPV005_Traceability { subject rover : FlipRover; }
    requirement fvg006 : FLIPV006_ChassisGeometry { subject rover : FlipRover; }
    requirement fvg007 : FLIPV007_MassPropertyDatum { subject rover : FlipRover; }
    requirement fvg008 : FLIPV008_WheelEnvelope { subject rover : FlipRover; }
    requirement fvg009 : FLIPV009_MissionSteeringMode { subject rover : FlipRover; }
    requirement fvg010 : FLIPV010_PhysicalWheelSupportEnvelope { subject rover : FlipRover; }

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
        verify fvg006;
        verify fvg007;
        verify fvg008;
        verify fvg009;
        verify fvg010;
    }
}
