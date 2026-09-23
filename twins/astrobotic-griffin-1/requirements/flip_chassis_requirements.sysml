package FlipChassisRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::String;

    part def FlipChassisComponent {
        attribute usdPath : String = "/World/FLIP/Chassis";
        attribute componentAsset : String = "components/rover/flip_chassis_visual.usda";
        ref part sourceRover : FlipRequirements::FlipRover;
        ref attribute chassisWidth : FlipRequirements::FlipRover::chassisWidthM;
        ref attribute chassisLength : FlipRequirements::FlipRover::chassisLengthM;
        attribute childNames : String[5] = ("LowerFrame", "WhiteEquipmentBox", "FrontBumper", "PayloadDeck", "ServicePanel");
        attribute lowerFrameWidthM : Real = 4.40;
        attribute lowerFrameHeightM : Real = 0.76;
        attribute lowerFrameLengthM : Real = 2.76;
        attribute equipmentBoxWidthM : Real = 3.90;
        attribute equipmentBoxHeightM : Real = 1.44;
        attribute equipmentBoxLengthM : Real = 2.44;
        attribute equipmentBoxCenterYM : Real = 0.45;
        attribute payloadDeckWidthM : Real = 3.44;
        attribute payloadDeckThicknessM : Real = 0.20;
        attribute payloadDeckLengthM : Real = 2.16;
        attribute payloadDeckCenterYM : Real = 0.92;
        attribute presentationCollisionPolicy : String = "chassis component is render-only; dynamic rover body owns collision";
    }

    requirement def FCC001_ChassisIdentity {
        doc /* FCC-001 [topology] FLIP exposes a named chassis with lower frame, white equipment box, and payload deck. */
    }
    requirement def FCC002_ChassisEnvelope {
        doc /* FCC-002 [geometry] the chassis width and length are checked against FlipRequirements metric values. */
    }
    requirement def FCC003_ChassisOwnership {
        doc /* FCC-003 [boundary] the render-only chassis component does not replace FLIP's dynamic body or wheel physics. */
    }
    requirement def FCC004_ChassisTraceability {
        doc /* FCC-004 [evidence] the chassis path and metric source names resolve from this package. */
    }
    requirement def FCC005_ChassisEnvelope {
        doc /* FCC-005 [geometry] the lower frame shall be 4.40 m by 0.76 m by 2.76 m, the equipment box 3.90 m by 1.44 m by 2.44 m at Y = 0.45 m, and the payload deck 3.44 m by 0.20 m by 2.16 m at Y = 0.92 m. */
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
