// Provisional size reconstruction, 2026-09-30. See griffin-size-evidence.md.
// CAD dimensions are estimates; geometry promotion does not qualify dynamics.
package FlipChassisRequirements {
    private import ScalarValues::String;
    private import VectorValues::CartesianThreeVectorValue;
    private import GriffinRequirementSources::TwinAssetPath;
    private import GriffinRequirementSources::UsdPrimPath;

    enum def FlipChassisMember { LowerFrame; WhiteEquipmentBox; FrontBumper; PayloadDeck; ServicePanel; }

    part def FlipChassisComponent {
        attribute usdPath : UsdPrimPath = "/World/FLIP/Chassis";
        attribute componentAsset : TwinAssetPath = "components/rover/flip_chassis_visual.usda";
        ref part sourceRover : FlipRequirements::FlipRover;
        attribute childNames : FlipChassisMember[5] = ("LowerFrame", "WhiteEquipmentBox", "FrontBumper", "PayloadDeck", "ServicePanel");
        ref attribute lowerFrameWidthM : FlipRequirements::FlipRover::chassisWidthM;
        ref attribute lowerFrameHeightM : FlipRequirements::FlipRover::chassisHeightM;
        ref attribute lowerFrameLengthM : FlipRequirements::FlipRover::chassisLengthM;
        ref attribute equipmentBoxWidthM : FlipRequirements::FlipRover::equipmentBoxWidthM;
        ref attribute equipmentBoxHeightM : FlipRequirements::FlipRover::equipmentBoxHeightM;
        ref attribute equipmentBoxLengthM : FlipRequirements::FlipRover::equipmentBoxDepthM;
        ref attribute equipmentBoxCenterYM : FlipRequirements::FlipRover::equipmentBoxCenterYM;
        ref attribute payloadDeckWidthM : FlipRequirements::FlipRover::payloadDeckWidthM;
        ref attribute payloadDeckThicknessM : FlipRequirements::FlipRover::payloadDeckThicknessM;
        ref attribute payloadDeckLengthM : FlipRequirements::FlipRover::payloadDeckDepthM;
        ref attribute payloadDeckCenterYM : FlipRequirements::FlipRover::payloadDeckCenterYM;
        attribute presentationCollisionPolicy : String = "chassis geometry is both rendered and used by the FLIP rigid body; wheel filtered pairs target these same shapes";
        // Packaging estimates: bumper sits at the front (-X); service panel
        // lies on the equipment-box -Z face. Neither is supplier metrology.
        // See griffin-size-evidence.md for the CAD-to-runtime axis mapping.
        attribute detailDimensions : CartesianThreeVectorValue[2] =
            ((0.12, 0.12, 1.20), (1.12, 0.25, 0.025));
        attribute detailCenters : CartesianThreeVectorValue[2] =
            ((-1.05, 0.06, 0.0), (0.0, 0.258, -0.7425));
    }

    requirement def FCC001_ChassisIdentity {
        doc /* FCC-001 [topology] FLIP exposes a named chassis with lower frame, white equipment box, and payload deck. */
    }
    requirement def FCC002_ChassisEnvelope {
        doc /* FCC-002 [geometry] lower-frame width, height, and length resolve to the owning FlipRequirements values. */
    }
    requirement def FCC003_ChassisOwnership {
        doc /* FCC-003 [physics boundary] the FLIP rigid body uses the referenced chassis geometry for collision; its wheel suspension and contacts remain on the four physical wheel assemblies. */
    }
    requirement def FCC004_ChassisTraceability {
        doc /* FCC-004 [evidence] the chassis path and metric source names resolve from this package. */
    }
    requirement def FCC005_ChassisEnvelope {
        doc /* FCC-005 [geometry] lower frame, equipment box, and payload deck geometry shall match their referenced FlipRequirements dimensions and centers. */
    }

    requirement <'FCC-001'> fcc001 : FCC001_ChassisIdentity { subject chassis : FlipChassisComponent; }
    requirement <'FCC-002'> fcc002 : FCC002_ChassisEnvelope { subject chassis : FlipChassisComponent; }
    requirement <'FCC-003'> fcc003 : FCC003_ChassisOwnership { subject chassis : FlipChassisComponent; }
    requirement <'FCC-004'> fcc004 : FCC004_ChassisTraceability { subject chassis : FlipChassisComponent; }
    requirement <'FCC-005'> fcc005 : FCC005_ChassisEnvelope { subject chassis : FlipChassisComponent; }

    verification def Verify_FLIPChassisRequirements {
        subject chassis : FlipChassisComponent;
        objective {
            verify fcc001;
            verify fcc002;
            verify fcc003;
            verify fcc004;
            verify fcc005;
        }
    }
}
