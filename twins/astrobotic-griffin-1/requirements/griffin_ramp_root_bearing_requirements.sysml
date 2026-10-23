package GriffinRampRootBearingRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Boolean;
    private import GriffinRequirementSources::TwinAssetPath;
    private import GriffinRequirementSources::UsdPrimPath;
    part def RampRootBearing {
        doc /* Y-up, Z-axis bore, origin at hinge centre, SI metres. Render-only
         * housing carried by the bus. Pin radius and axial stock reuse the
         * existing root fitting. The 0.5 mm radial clearance and 0.4 mm minimum
         * faceted aperture are explicit reconstruction assumptions, not a flight
         * ICD, manufacturing fit, qualified bearing or structural allowable.
         * The existing RampStructure UsdShade appearance is reused; engineering
         * grade, lubricant, contact, stiffness and strength remain unqualified.
         * Basis: contracts/griffin-root-bearing-2026-10-23.md. */
        attribute componentAsset : TwinAssetPath = "components/lander/griffin_ramp_root_bearing_visual.usda";
        attribute usdPath : UsdPrimPath = "/World/RampRootBearing";
        attribute pinRadiusM : Real = GriffinRampRequirements::GriffinEgressRamp::rampRailJointPinRadiusM;
        attribute radialClearanceM : Real = 0.0005;
        attribute innerRadiusM : Real = RampRootBearing::pinRadiusM + RampRootBearing::radialClearanceM;
        attribute outerRadiusM : Real = GriffinRampRequirements::GriffinEgressRamp::rampPivotLugWidthM / 2.0;
        attribute pinLengthM : Real = GriffinRampRequirements::GriffinEgressRamp::rampRailJointPinLengthM;
        attribute tongueThicknessM : Real = GriffinRampRequirements::GriffinEgressRamp::rampPivotLugThicknessM;
        attribute axialClearanceM : Real = RampRootBearing::radialClearanceM;
        attribute axialLengthM : Real = (RampRootBearing::pinLengthM - RampRootBearing::tongueThicknessM
            - 2.0 * RampRootBearing::axialClearanceM) / 2.0;
        attribute inboardOffsetM : Real = (RampRootBearing::tongueThicknessM + RampRootBearing::axialLengthM) / 2.0
            + RampRootBearing::axialClearanceM;
        attribute minimumRadialClearanceM : Real = 0.0004;
        attribute geometryToleranceM : Real = 0.000002;
        ref part sourceRoot : GriffinRampRootSectionRequirements::RampRootSection;
    }
    constraint def GRBC001_OpenBore {
        in measuredMinimumClearanceM : Real;
        in measuredDimensionErrorM : Real;
        in topologyAndRoles : Boolean;
        in minimumClearanceM : Real;
        in toleranceM : Real;
        topologyAndRoles and minimumClearanceM > 0.0 and toleranceM > 0.0
            and measuredMinimumClearanceM >= minimumClearanceM
            and measuredDimensionErrorM >= 0.0 and measuredDimensionErrorM <= toleranceM;
    }
    requirement def GRB001_RootBearingBore {
        doc /* GRB-001 the reusable housing shall have a closed annular mesh
         * around the Z-axis HingeAxis datum. All inner-wall facets shall clear
         * the source pin by minimumRadialClearanceM; the mesh envelope shall
         * match source outer radius/axial stock within geometryToleranceM.
         * Shared structural appearance and render-only collision role are
         * mandatory. The assembly separately qualifies pin-axis coincidence,
         * stem connection and clearance over the complete rotation path. */
        require GRBC001_OpenBore {
            in minimumClearanceM = RampRootBearing::minimumRadialClearanceM;
            in toleranceM = RampRootBearing::geometryToleranceM;
        }
    }
    requirement <'GRB-001'> grb001 : GRB001_RootBearingBore { subject bearing : RampRootBearing; }
    verification def Verify_GriffinRampRootBearing { subject bearing : RampRootBearing; verify grb001; }
}
