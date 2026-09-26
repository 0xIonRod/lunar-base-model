// Legacy runtime visual-study contract; not the corrected FreeCAD v3 geometry.
// See flip_cad_requirements.sysml for current CAD behavior and dimensions.
// Runtime promotion remains OPEN; these builder-consumed values are unchanged.
package FlipChassisRequirements {
    private import ScalarValues::String;

    part def FlipChassisComponent {
        attribute usdPath : String = "/World/FLIP/Chassis";
        attribute sourceComponent : String = "FlipRequirements::FlipRover";
        attribute widthSource : String = "FlipRequirements::FlipRover::chassisWidthM";
        attribute lengthSource : String = "FlipRequirements::FlipRover::chassisLengthM";
        attribute childNames : String = "LowerFrame,WhiteEquipmentBox,PayloadDeck";
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

    requirement fcc001 : FCC001_ChassisIdentity { subject chassis : FlipChassisComponent; }
    requirement fcc002 : FCC002_ChassisEnvelope { subject chassis : FlipChassisComponent; }
    requirement fcc003 : FCC003_ChassisOwnership { subject chassis : FlipChassisComponent; }
    requirement fcc004 : FCC004_ChassisTraceability { subject chassis : FlipChassisComponent; }

    verification def Verify_FLIPChassisRequirements {
        subject chassis : FlipChassisComponent;
        verify fcc001;
        verify fcc002;
        verify fcc003;
        verify fcc004;
    }
}
