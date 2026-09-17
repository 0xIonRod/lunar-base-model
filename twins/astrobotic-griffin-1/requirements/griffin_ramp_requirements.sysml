package GriffinRampRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import ScalarValues::String;

    // The ramp is a separately verifiable Griffin subsystem.  Dimensions are
    // the current metre-scale visual study envelope; they are not presented as
    // an as-built ICD until Astrobotic publishes the mechanical data.
    part def GriffinEgressRamp {
        attribute rampCount : Integer = 2;
        attribute rampSurfaceLengthM : Real = 3.70;
        // The operational width is derived in the Rhai verifier from the
        // independent FLIP wheel-station and tyre datums:
        // 2 * (maxAbs(FlipRover.wheelStationZ)
        //      + FlipRover.visualRoverWheelRadiusM
        //      + rampWheelClearanceM).
        // Keep this package's value equal to that derived interface datum;
        // it is still a visual study value, not a supplier mechanical ICD.
        attribute rampSurfaceWidthM : Real = 3.50;
        attribute rampWheelClearanceM : Real = 0.15;
        attribute rampSurfaceThicknessM : Real = 0.18;
        attribute rampRailHeightM : Real = 0.28;
        attribute rampRailWidthM : Real = 0.14;
        attribute rampSurfaceCenterYM : Real = -1.15;
        attribute rampRailCenterYM : Real = -0.92;
        attribute rampMaxDeploymentAngleRad : Real = 0.58;
        attribute rampPortMountX : Real = 1.00;
        attribute rampStarboardMountX : Real = -1.00;
        attribute rampMountY : Real = 2.10;
        attribute rampMountZ : Real = 0.0;
        attribute rampHingeOffsetX : Real = 1.60;
        attribute rampHingeOffsetY : Real = 0.0;
        attribute rampHingeOffsetZ : Real = 0.0;
        attribute rampSocketX : Real = 2.60;
        attribute rampSocketY : Real = -1.10;
        attribute rampSocketZ : Real = 0.0;
        attribute rampPortDeploymentAngleRad : Real = -0.2094395102;
        attribute rampStarboardDeploymentAngleRad : Real = 0.2094395102;
        attribute rampBehavior : String = "revolute about Z; command in radians; USD rotateXYZ in degrees";
        attribute hingeAxis : String = "Z";
        attribute mountDatum : String = "Bus/RampSocket";
        attribute rampGeometryStatus : String = "metric visual study envelope; mechanical ICD TBD";
        attribute provenanceSource : String = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute missionReference : String = "https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/";
        attribute productReference : String = "https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/";
        attribute referenceImage : String = "https://aviationweek.com/gallery-look-nasas-commercial-lunar-payload-services-deliveries";
        attribute sourceFact : String = "Griffin provides optional egress ramps so a rover can drive off the lander";
        attribute sourceRationale : String = "A ramp has its own hinge, actuator-limit and contact geometry, so it is detached and verified independently from the bus";
    }

    requirement def GRR001_RampTopology {
        doc /* GRR-001 [visual] each side ramp shall be a named replaceable component with a surface, two edge rails, and an inspectable support arm. */
    }

    requirement def GRR002_RampHinge {
        doc /* GRR-002 [integration] each ramp shall expose a Z-axis hinge datum related to the matching Griffin bus socket; numeric placement is authored through the Editor assembly tools. */
    }

    requirement def GRR003_RampEnvelope {
        doc /* GRR-003 [study] the visual ramp envelope shall use the metric length/width and deployment limit in this package; its width shall clear the four FLIP wheel stations by the authored wheel-clearance datum. These values remain study proxies until the mechanical ICD is available. */
    }

    requirement def GRR004_RampPlacement {
        doc /* GRR-004 [integration] each ramp root, hinge frame, and matching bus socket shall use the authored metric mount datums and mirrored side placement. */
    }

    requirement def GRR005_RampBehavior {
        doc /* GRR-005 [behavior] each ramp shall expose a revolute Z hinge, publish its commanded angle in radians, mirror port/starboard signs, and reject commands outside the authored limit. */
    }

    requirement def GRR006_RampGeometry {
        doc /* GRR-006 [geometry] the composed ramp surface shall match the authored metric length, width, and thickness envelope; the width must be sufficient for the FLIP track plus two tyre envelopes and the wheel-clearance datum. Rails and support arm remain separately inspectable. */
    }

    requirement def GRR007_RampEvidence {
        doc /* GRR-007 [process] port and starboard ramps shall be edited and reviewed independently in Editor Perspective, with a composed USD readback and fresh screenshot. */
    }

    requirement grr001 : GRR001_RampTopology { subject ramp : GriffinEgressRamp; }
    requirement grr002 : GRR002_RampHinge { subject ramp : GriffinEgressRamp; }
    requirement grr003 : GRR003_RampEnvelope { subject ramp : GriffinEgressRamp; }
    requirement grr004 : GRR004_RampPlacement { subject ramp : GriffinEgressRamp; }
    requirement grr005 : GRR005_RampBehavior { subject ramp : GriffinEgressRamp; }
    requirement grr006 : GRR006_RampGeometry { subject ramp : GriffinEgressRamp; }
    requirement grr007 : GRR007_RampEvidence { subject ramp : GriffinEgressRamp; }

    verification def Verify_GriffinRampRequirements {
        subject ramp : GriffinEgressRamp;
        verify grr001;
        verify grr002;
        verify grr003;
        verify grr004;
        verify grr005;
        verify grr006;
        verify grr007;
    }
}
