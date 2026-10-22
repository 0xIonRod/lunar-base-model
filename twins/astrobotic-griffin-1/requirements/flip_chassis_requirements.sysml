// Provisional size reconstruction, 2026-09-30. See griffin-size-evidence.md.
// CAD dimensions are estimates; geometry promotion does not qualify dynamics.
package FlipChassisRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Boolean;
    private import ScalarValues::String;
    private import VectorValues::CartesianThreeVectorValue;
    private import GriffinRequirementSources::TwinAssetPath;
    private import GriffinRequirementSources::UsdPrimPath;

    enum def FlipChassisMember { LowerFrame; WhiteEquipmentBox; FrontBumper; PayloadDeck; ServicePanel; }
    enum def FlipChassisFinishRole { Metal; Enclosure; }
    enum def FlipChassisMaterial { ExposedMetal; PaleEnclosure; }

    part def FlipChassisComponent {
        attribute usdPath : UsdPrimPath = "/World/FLIP/Chassis";
        attribute componentAsset : TwinAssetPath = "components/rover/flip_chassis_visual.usda";
        ref part sourceRover : FlipRequirements::FlipRover;
        attribute childNames : FlipChassisMember[5] = ("LowerFrame", "WhiteEquipmentBox", "FrontBumper", "PayloadDeck", "ServicePanel");
        attribute appearanceRoles : FlipChassisFinishRole[5] = ("Metal", "Enclosure", "Metal", "Metal", "Metal");
        attribute metalMaterialName : FlipChassisMaterial = "ExposedMetal";
        attribute enclosureMaterialName : FlipChassisMaterial = "PaleEnclosure";
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
        // Reference-informed display finishes, not an alloy, coating stack or
        // measured optical data. Astrolab's FLIP render shows a pale enclosure
        // and exposed silver structure: https://www.astrolab.space/flip-rover/ .
        // Reuse the lander's silver palette rather than invent a second one.
        ref attribute metalDisplayColor : GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::silverDisplayColor;
        attribute metalMetallic : Real = GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::silverMetallic;
        attribute metalRoughness : Real = GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::silverRoughness;
        attribute enclosureDisplayColor : Real[3] = (0.83, 0.84, 0.84);
        attribute enclosureMetallic : Real = 0.0;
        attribute enclosureRoughness : Real = 0.50;
        // Packaging estimates: bumper sits at the front (-X); service panel
        // lies on the equipment-box -Z face. Neither is supplier metrology.
        // See griffin-size-evidence.md for the CAD-to-runtime axis mapping.
        attribute detailDimensions : CartesianThreeVectorValue[2] =
            ((0.12, 0.12, 1.20), (1.12, 0.25, 0.025));
        attribute detailCenters : CartesianThreeVectorValue[2] =
            ((0.892, 0.06, 0.0), (0.0, 0.258, -0.7425));
    }

    requirement def FCC001_ChassisIdentity {
        doc /* FCC-001 [topology] FLIP exposes a named chassis with lower frame, white equipment box, and payload deck. */
    }
    requirement def FCC002_ChassisEnvelope {
        doc /* FCC-002 [geometry] lower-frame width, height, and length resolve to the owning FlipRequirements values. */
    }
    requirement def FCC003_ChassisOwnership {
        doc /* FCC-003 [physics boundary] the FLIP rigid body uses the lower frame, equipment box, bumper and payload deck for collision; the decorative service panel explicitly disables collision. Wheel suspension and contacts remain on the four physical wheel assemblies. */
    }
    requirement def FCC004_ChassisTraceability {
        doc /* FCC-004 [evidence] the chassis path and metric source names resolve from this package. */
    }
    requirement def FCC005_ChassisEnvelope {
        doc /* FCC-005 [geometry] lower frame, equipment box, and payload deck geometry shall match their referenced FlipRequirements dimensions and centers. */
    }

    constraint def FCCC006_NormalizedPreviewSurface {
        in red : Real;
        in green : Real;
        in blue : Real;
        in metallic : Real;
        in roughness : Real;
        in surfaceConnected : Boolean;
        surfaceConnected and red >= 0.0 and red <= 1.0 and green >= 0.0 and green <= 1.0
            and blue >= 0.0 and blue <= 1.0 and metallic >= 0.0 and metallic <= 1.0
            and roughness >= 0.0 and roughness <= 1.0;
    }
    requirement def FCC006_ChassisFinish {
        doc /* FCC-006 [appearance] all five chassis shapes shall bind one of two reusable UsdPreviewSurface materials: the equipment enclosure uses the source-owned pale dielectric finish; the lower frame, bumper, payload deck and service panel use the shared silver presentation palette. Each material surface connection and all five shader controls shall be explicit and inspectable. The normalized shader predicate applies to each profile. Display parameters narrow only at the USD color3f/float rendering boundary; projectionTolerance allows that serialization rounding. These finishes convey reference appearance without claiming measured reflectance or physical material qualification. */
        attribute projectionTolerance : Real = 1.0e-6;
        require FCCC006_NormalizedPreviewSurface;
    }

    requirement <'FCC-001'> fcc001 : FCC001_ChassisIdentity { subject chassis : FlipChassisComponent; }
    requirement <'FCC-002'> fcc002 : FCC002_ChassisEnvelope { subject chassis : FlipChassisComponent; }
    requirement <'FCC-003'> fcc003 : FCC003_ChassisOwnership { subject chassis : FlipChassisComponent; }
    requirement <'FCC-004'> fcc004 : FCC004_ChassisTraceability { subject chassis : FlipChassisComponent; }
    requirement <'FCC-005'> fcc005 : FCC005_ChassisEnvelope { subject chassis : FlipChassisComponent; }
    requirement <'FCC-006'> fcc006 : FCC006_ChassisFinish { subject chassis : FlipChassisComponent; }

    verification def Verify_FLIPChassisRequirements {
        subject chassis : FlipChassisComponent;
        objective {
            verify fcc001;
            verify fcc002;
            verify fcc003;
            verify fcc004;
            verify fcc005;
            verify fcc006;
        }
    }
}
