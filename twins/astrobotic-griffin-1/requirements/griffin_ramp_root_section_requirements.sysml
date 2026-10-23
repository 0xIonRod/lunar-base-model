package GriffinRampRootSectionRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Boolean;
    private import GriffinRequirementSources::TwinAssetPath;
    private import GriffinRequirementSources::UsdPrimPath;

    enum def RootFrameIdentity { DeckHinge; MiddleFold; }

    part def RampRootSection {
        doc /* 2026-10-22 unequal-fold reconstruction study. Source:
         * contracts/griffin-ramp-interference-2026-10-22.md and its native
         * collider receipt. Astrobotic confirms a payload adapter and optional
         * egress ramps, not their dimensions. The longer root lifts the folded
         * middle/toe stack away from the fixed deck transitions while retaining
         * the inward silhouette. Its geometry is independently qualified. The installed mechanism has
         * a separate post-landing acceptance case.
         * Dimensions are SI metres, Y-up, +X from the deck hinge to the first
         * fold. No supplier CAD, stiffness or structural strength is claimed. */
        attribute componentAsset : TwinAssetPath = "components/lander/griffin_ramp_root_section_visual.usda";
        attribute usdPath : UsdPrimPath = "/World/RampRootSection";
        attribute lengthM : Real = 2.149084054;
        attribute hasExitHinge : Boolean = true;
        attribute geometryToleranceM : Real = 0.002;
        attribute entryFrameName : RootFrameIdentity = "DeckHinge";
        attribute exitFrameName : RootFrameIdentity = "MiddleFold";
        // Raised-axis reconstruction: one existing lug width above the track
        // centre. The nominal entrance face is vertical and its lower edge is
        // mitered from source thickness/angle; underside beams start at that
        // same run. The assembly solves the bearing position from the deck
        // corner and this datum, rather than moving the deck or rover.
        attribute deploymentAngleRad : Real = GriffinRampRequirements::GriffinEgressRamp::physicalRampPortDeploymentAngleRad;
        attribute entryShaftRadiusM : Real = GriffinRampRequirements::GriffinEgressRamp::rampRailJointPinRadiusM;
        attribute entryAxisYM : Real = GriffinRampRequirements::GriffinEgressRamp::rampPivotLugWidthM;
        attribute exitAxisYM : Real = GriffinRampRequirements::GriffinEgressRamp::rampRailCenterYM
            + GriffinRampRequirements::GriffinEgressRamp::rampRailHeightM / 2.0;
        attribute plateAttachmentRunM : Real = 1.5 * GriffinRampRequirements::GriffinEgressRamp::rampPivotLugWidthM;
        attribute forkWebSizeM : Real = GriffinRampRequirements::GriffinEgressRamp::rampPivotLugWidthM / 2.0;
        ref part sourceRamp : GriffinRampRequirements::GriffinEgressRamp;
    }

    constraint def GRSC001_PositiveSpan {
        in sourceLengthM : Real;
        in measuredDimensionErrorM : Real;
        in toleranceM : Real;
        in connectedFittings : Boolean;
        sourceLengthM > 0.0 and connectedFittings and toleranceM >= 0.0
            and measuredDimensionErrorM >= 0.0
            and measuredDimensionErrorM <= toleranceM;
    }
    requirement def GRS001_RootSectionGeometry {
        doc /* GRS-001 the detached root section shall contain two entrance-mitered
         * collision-enabled walking tracks of length lengthM, source track
         * width/thickness and FLIP wheel stations. Four rising guide trusses,
         * two underside beams and four treads per track shall follow that span.
         * The entrance lower corners shall be relieved so the entrance face
         * is vertical at deploymentAngleRad. Beams shall start at the same
         * native thickness/angle-derived run. DeckHinge is raised by the
         * source entryAxisYM; connected tongues and coaxial pins shall follow
         * it. The assembly separately qualifies running clearance and wheel
         * crossing from the fixed deck to this nominal walking face.
         * Named deck and middle-fold Xform datums shall lie on the source
         * hinge axes at X=0 and X=lengthM respectively.
         * Each entry tongue and paired exit fork cheeks shall connect the
         * hinge axis to the same guide stock; a lower-axis plate shall bridge
         * to the lower chord. Pins remain coaxial, and all fittings retain
         * shared structural material and render-only collision roles. The root entry
         * shaft shall use entryShaftRadiusM, matching its coaxial pins so the
         * shaft can pass through the assembly bearing bore.
         * Geometry belongs to this component; the vehicle owns its rigid body,
         * mass/inertia, hinge and installed pose. Native composed geometry and
         * standard attributes supply evidence. Missing or wrong units, types,
         * collision roles or source values shall fail. */
        require GRSC001_PositiveSpan {
            in sourceLengthM = RampRootSection::lengthM;
            in toleranceM = RampRootSection::geometryToleranceM;
        }
    }
    requirement <'GRS-001'> grs001 : GRS001_RootSectionGeometry {
        subject section : RampRootSection;
    }
    verification def Verify_GriffinRampRootSection {
        subject section : RampRootSection;
        verify grs001;
    }
}
