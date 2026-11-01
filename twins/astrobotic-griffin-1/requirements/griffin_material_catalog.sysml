package GriffinMaterialCatalog {
    private import ScalarValues::Boolean;
    enum def MaterialIdentity {
        AluminumAlloyUnspecified; MetalUnspecified; CompositeOverwrapUnspecified;
        PressureLinerUnspecified; BlanketStackUnspecified; FabricUnspecified;
        SemiconductorStackUnspecified; EnclosureSubstrateUnspecified;
    }
    enum def EvidenceStatus { ManufacturerStatement; PhotoInference; ReconstructionAssumption; Unknown; }
    enum def SourceIdentity { AstroboticGriffinPage; AstroboticOctober2025Update; NasaJplPia26708;
        AstrolabFlipPage; AstrolabLeag2025_5034; VenturiWheelPage; NoReleasedSource; }
    enum def FinishIdentity { ExposedMetal; SilverBlanketOuterFace; GoldTapeOuterFace;
        DarkWovenFabric; DarkCellCover; PaleEnclosure; Unspecified; }
    part def MaterialRecord {
        attribute identity : MaterialIdentity;
        attribute evidence : EvidenceStatus;
        attribute source : SourceIdentity;
        attribute gradeReleased : Boolean = false;
        attribute qualifiedPropertiesAvailable : Boolean = false;
    }
    part def FinishRecord {
        attribute identity : FinishIdentity;
        attribute evidence : EvidenceStatus;
        attribute source : SourceIdentity;
        attribute coatingStackReleased : Boolean = false;
        attribute measuredOpticsAvailable : Boolean = false;
    }
    part griffinFrame : MaterialRecord {
        attribute identity : MaterialIdentity = "AluminumAlloyUnspecified";
        attribute evidence : EvidenceStatus = "ManufacturerStatement";
        attribute source : SourceIdentity = "AstroboticGriffinPage";
    }
    part copvOverwrap : MaterialRecord {
        attribute identity : MaterialIdentity = "CompositeOverwrapUnspecified";
        attribute evidence : EvidenceStatus = "ManufacturerStatement";
        attribute source : SourceIdentity = "AstroboticOctober2025Update";
    }
    part copvLiner : MaterialRecord {
        attribute identity : MaterialIdentity = "PressureLinerUnspecified";
        attribute evidence : EvidenceStatus = "Unknown";
        attribute source : SourceIdentity = "NoReleasedSource";
    }
    part blanket : MaterialRecord {
        attribute identity : MaterialIdentity = "BlanketStackUnspecified";
        attribute evidence : EvidenceStatus = "PhotoInference";
        attribute source : SourceIdentity = "NasaJplPia26708";
    }
    part tetherFabric : MaterialRecord {
        attribute identity : MaterialIdentity = "FabricUnspecified";
        attribute evidence : EvidenceStatus = "ManufacturerStatement";
        attribute source : SourceIdentity = "AstrolabLeag2025_5034";
    }
    part flipEnclosure : MaterialRecord {
        attribute identity : MaterialIdentity = "EnclosureSubstrateUnspecified";
        attribute evidence : EvidenceStatus = "Unknown";
        attribute source : SourceIdentity = "AstrolabFlipPage";
    }
    part exposedHardware : MaterialRecord {
        attribute identity : MaterialIdentity = "MetalUnspecified";
        attribute evidence : EvidenceStatus = "PhotoInference";
        attribute source : SourceIdentity = "NasaJplPia26708";
    }
    part solarCells : MaterialRecord {
        attribute identity : MaterialIdentity = "SemiconductorStackUnspecified";
        attribute evidence : EvidenceStatus = "Unknown";
        attribute source : SourceIdentity = "NoReleasedSource";
    }
    part silverBlanketFinish : FinishRecord {
        attribute identity : FinishIdentity = "SilverBlanketOuterFace";
        attribute evidence : EvidenceStatus = "PhotoInference";
        attribute source : SourceIdentity = "NasaJplPia26708";
    }
    part goldTapeFinish : FinishRecord {
        attribute identity : FinishIdentity = "GoldTapeOuterFace";
        attribute evidence : EvidenceStatus = "PhotoInference";
        attribute source : SourceIdentity = "NasaJplPia26708";
    }
    part fabricFinish : FinishRecord {
        attribute identity : FinishIdentity = "DarkWovenFabric";
        attribute evidence : EvidenceStatus = "ReconstructionAssumption";
        attribute source : SourceIdentity = "AstrolabLeag2025_5034";
    }
    part def CompactTetherAssignment {
        ref substrate = tetherFabric;
        ref finish = fabricFinish;
    }
    part def GriffinFrameAssignment { ref substrate = griffinFrame; }
    part def TankAssignment { ref pressureBoundary = copvLiner; ref overwrap = copvOverwrap;
        ref thermalCover = blanket; ref visibleFinish = silverBlanketFinish; }
    part def ExteriorBlanketAssignment { ref substrate = blanket; ref finish = silverBlanketFinish; }
    part def FlipEnclosureAssignment { ref substrate = flipEnclosure; }
    part def WheelAssignments {
        // Keep the existing component-owned selections as the only wheel source.
        ref treadBlades = FlipAirlessWheelRequirements::treadBladeMaterial;
        ref carrier = FlipAirlessWheelRequirements::elasticCarrierMaterial;
        ref otherMetal = FlipAirlessWheelRequirements::cableAndRimMaterial;
    }
}
