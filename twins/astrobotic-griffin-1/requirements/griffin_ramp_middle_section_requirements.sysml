package GriffinRampMiddleSectionRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Boolean;
    private import GriffinRequirementSources::TwinAssetPath;
    private import GriffinRequirementSources::UsdPrimPath;

    enum def MiddleFrameIdentity { RootFold; ToeFold; }

    part def RampMiddleSection {
        doc /* 2026-10-22 unequal-fold reconstruction study. Source:
         * contracts/griffin-ramp-interference-2026-10-22.md and its native
         * collider receipt. Astrobotic confirms a payload adapter and optional
         * egress ramps, not their dimensions. The shorter middle carries the downward-offset toe fold in
         * the unequal-fold reconstruction. Its ends share the root upper
         * axis and the new lower toe axis; no released hardware is claimed. Its geometry is independently qualified. The installed mechanism has
         * a separate post-landing acceptance case.
         * Dimensions are SI metres, Y-up, +X from the root fold to the toe
         * fold. No supplier CAD, stiffness or structural strength is claimed. */
        attribute componentAsset : TwinAssetPath = "components/lander/griffin_ramp_middle_section_visual.usda";
        attribute usdPath : UsdPrimPath = "/World/RampMiddleSection";
        attribute lengthM : Real = 1.449084054;
        attribute hasExitHinge : Boolean = true;
        attribute geometryToleranceM : Real = 0.002;
        attribute entryFrameName : MiddleFrameIdentity = "RootFold";
        attribute exitFrameName : MiddleFrameIdentity = "ToeFold";
        attribute entryAxisYM : Real = GriffinRampRootSectionRequirements::RampRootSection::exitAxisYM;
        /* 2026-10-23 native packaging study: a 120 mm lower offset places
         * toe guides through FLIP's equipment/deck boxes. An 80 mm offset
         * retains 40 mm root/toe stock separation in sampled detailed bounds.
         * The assembly also requires outboard hinge stand-off and root-first
         * unfolding; the component gate alone cannot accept the mechanism. */
        attribute exitAxisYM : Real = -0.08;
        attribute plateAttachmentRunM : Real = GriffinRampRootSectionRequirements::RampRootSection::plateAttachmentRunM;
        attribute forkWebSizeM : Real = GriffinRampRootSectionRequirements::RampRootSection::forkWebSizeM;
        ref part sourceRamp : GriffinRampRequirements::GriffinEgressRamp;
    }

    constraint def GMSC001_PositiveSpan {
        in sourceLengthM : Real;
        in measuredDimensionErrorM : Real;
        in toleranceM : Real;
        in connectedFittings : Boolean;
        sourceLengthM > 0.0 and connectedFittings and toleranceM >= 0.0
            and measuredDimensionErrorM >= 0.0
            and measuredDimensionErrorM <= toleranceM;
    }
    requirement def GMS001_MiddleSectionGeometry {
        doc /* GMS-001 the detached middle section shall contain two rectangular
         * collision-enabled walking tracks of length lengthM, source track
         * width/thickness and FLIP wheel stations. Four level guide trusses,
         * two underside beams and four treads per track shall follow that span.
         * Named root-fold and toe-fold Xform datums shall lie on the source
         * hinge axes at X=0 and X=lengthM respectively.
         * Each entry tongue and paired exit fork cheeks shall connect the
         * hinge axis to the same guide stock; a lower-axis plate shall bridge
         * to the lower chord. Pins remain coaxial, and all fittings retain
         * shared structural material and render-only collision roles.
         * Geometry belongs to this component; the vehicle owns its rigid body,
         * mass/inertia, hinge and installed pose. Native composed geometry and
         * standard attributes supply evidence. Missing or wrong units, types,
         * collision roles or source values shall fail. */
        require GMSC001_PositiveSpan {
            in sourceLengthM = RampMiddleSection::lengthM;
            in toleranceM = RampMiddleSection::geometryToleranceM;
        }
    }
    requirement <'GMS-001'> gms001 : GMS001_MiddleSectionGeometry {
        subject section : RampMiddleSection;
    }
    verification def Verify_GriffinRampMiddleSection {
        subject section : RampMiddleSection;
        verify gms001;
    }
}
