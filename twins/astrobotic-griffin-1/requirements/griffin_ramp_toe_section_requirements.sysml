package GriffinRampToeSectionRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Boolean;
    private import GriffinRequirementSources::TwinAssetPath;
    private import GriffinRequirementSources::UsdPrimPath;

    enum def ToeFrameIdentity { MiddleFold; GroundToe; }

    part def RampToeSection {
        doc /* 2026-10-23 unequal-fold reconstruction. Astrobotic confirms
         * optional egress ramps; the supplied cleanroom image guides the
         * slender inward-folded lattice. No released hinge or dimension ICD
         * is available in these sources. contracts/griffin-ramp-interference-
         * 2026-10-22.md records why this toe folds clockwise from -180 to 0
         * degrees around the lower middle/toe axis. The retained total span
         * determines its length after the longer root and shorter middle.
         * SI metres, Y-up, +X from middle fold toward the ground-contact toe.
         * This detached study component is not installed mechanism acceptance. */
        attribute componentAsset : TwinAssetPath = "components/lander/griffin_ramp_toe_visual.usda";
        attribute usdPath : UsdPrimPath = "/World/RampToeSection";
        attribute lengthM : Real = GriffinRampRequirements::GriffinEgressRamp::rampSurfaceLengthM
            - GriffinRampRootSectionRequirements::RampRootSection::lengthM
            - GriffinRampMiddleSectionRequirements::RampMiddleSection::lengthM;
        attribute deploymentAngleRad : Real = GriffinRampRequirements::GriffinEgressRamp::physicalRampPortDeploymentAngleRad;
        attribute hasExitHinge : Boolean = false;
        attribute geometryToleranceM : Real = 0.002;
        attribute entryFrameName : ToeFrameIdentity = "MiddleFold";
        attribute exitFrameName : ToeFrameIdentity = "GroundToe";
        attribute entryAxisYM : Real = GriffinRampMiddleSectionRequirements::RampMiddleSection::exitAxisYM;
        attribute exitAxisYM : Real = GriffinRampRequirements::GriffinEgressRamp::rampSurfaceCenterYM
            + GriffinRampRequirements::GriffinEgressRamp::rampSurfaceThicknessM / 2.0;
        attribute plateAttachmentRunM : Real = GriffinRampRootSectionRequirements::RampRootSection::plateAttachmentRunM;
        attribute forkWebSizeM : Real = GriffinRampRootSectionRequirements::RampRootSection::forkWebSizeM;
        ref part sourceRamp : GriffinRampRequirements::GriffinEgressRamp;
    }

    constraint def GTSC001_PositiveSpan {
        in sourceLengthM : Real;
        in measuredDimensionErrorM : Real;
        in toleranceM : Real;
        in connectedFittings : Boolean;
        sourceLengthM > 0.0 and connectedFittings and toleranceM >= 0.0
            and measuredDimensionErrorM >= 0.0
            and measuredDimensionErrorM <= toleranceM;
    }
    requirement def GTS001_ToeSectionGeometry {
        doc /* GTS-001 the detached toe shall have paired collision-enabled
         * tracks with a terrain-plane miter derived from source thickness and
         * nominal deployment angle; four level guide trusses, braces, two
         * underside beams and source-count treads shall follow its span.
         * Entry tongues, shaft and local pins shall share the lower middle/toe
         * axis and connect to lower chord stock. No exit fork is allowed at
         * the free ground toe. The two named Xform datums identify the entry
         * axis and the top toe edge. Standard shared silver/dark PBR bindings
         * and collision roles apply. The assembly owns bodies, masses, inertia,
         * joints, installation and terrain-fitted commands; no supplier
         * stiffness, strength or hardware fit is claimed by this component. */
        require GTSC001_PositiveSpan {
            in sourceLengthM = RampToeSection::lengthM;
            in toleranceM = RampToeSection::geometryToleranceM;
        }
    }
    requirement <'GTS-001'> gts001 : GTS001_ToeSectionGeometry {
        subject section : RampToeSection;
    }
    verification def Verify_GriffinRampToeSection {
        subject section : RampToeSection;
        verify gts001;
    }
}
