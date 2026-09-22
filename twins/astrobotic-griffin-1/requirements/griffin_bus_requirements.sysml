package GriffinBusRequirements {
    private import ScalarValues::Real;
    /* The bus is a real SysML composition, not a String list of child names.
     * Metric design values are owned by GriffinVisualConfiguration. */
    part def GriffinBusFrameStructure;
    part def GriffinPayloadDeck;
    part def GriffinLowerServiceSkirt;
    part def GriffinAvionicsDeck;
    part def GriffinAvionicsPod;

    part def GriffinBusComponent {
        part perimeterFrame : GriffinBusFrameStructure;
        part payloadDeck : GriffinPayloadDeck;
        part lowerServiceSkirt : GriffinLowerServiceSkirt;
        part avionicsDeck : GriffinAvionicsDeck;
        part avionicsPod : GriffinAvionicsPod;
    }

    constraint def GBC010_PositiveDeckSkirtClearance {
        in separationM : Real;
        separationM > 0.0;
    }

    constraint def GBC011_TankBoreClearance {
        in boreRadiusM : Real;
        in maximumBandRadiusM : Real;
        in tankScale : Real;
        in minimumClearanceM : Real;
        boreRadiusM - maximumBandRadiusM * tankScale >= minimumClearanceM;
    }

    constraint def GBC_ObservedCountEquals {
        in observedCount : Real;
        in expectedCount : Real;
        observedCount == expectedCount;
    }

    requirement def GBC001_BusIdentity {
        doc /* GBC-001 [topology] the bus is a named, visible octagonal open-frame visual component with an octagonal lower service skirt and upper deck. */
    }
    requirement def GBC002_BusEnvelope {
        doc /* GBC-002 [geometry] the bus envelope is checked against the lander SysML metric width, depth, and height values. */
    }
    requirement def GBC003_BusPresentationOwnership {
        doc /* GBC-003 [visual ownership] the bus presentation component is render-only and does not replace the flight body or collider owner. */
    }
    requirement def GBC004_BusTraceability {
        doc /* GBC-004 [evidence] each bus assumption and its rationale/source shall resolve from the separate SysML provenance catalog, while geometry is verified from typed requirements and composed mesh data. */
    }
    requirement def GBC005_BusFrameGeometry {
        doc /* GBC-005 [geometry] the open eight-sided frame shall comprise eight upper and eight lower perimeter beams plus eight named corner posts. The rail outside faces define the 4.50 m X/Z plan envelope; the perimeter mesh spans the 2.00 m core-frame height and meets the deck and lower skirt. Source: public Griffin imagery establishes a faceted structural bus, not released CAD. Rationale: a connected, open member layout reveals subsystem placement and removes the visually opaque prism; 0.16 m section stock is a replaceable study assumption shared by ring members and posts. */
    }
    requirement def GBC006_DeckGeometry {
        doc /* GBC-006 [geometry] the active TopDeckOctagon shall use the typed deck width, depth, thickness, and center-Y datums resolved from GriffinVisualConfiguration; the separate avionics deck remains a smaller service platform. These are derived presentation datums inside the 4.50 m x 4.50 m x 2.00 m octagonal bus envelope. */
    }
    requirement def GBC007_AssemblyRailGeometry {
        doc /* GBC-007 [geometry] the composed bus shall expose the eight named Y-axis frame rails, with dimensions and signed X/Y/Z stations resolved from the typed visual configuration; the rails are render-only. */
    }
    requirement def GBC008_OctagonalBodyShape {
        doc /* GBC-008 [geometry] the primary body shall be an eight-sided open frame built from sixteen perimeter members, with outward-wound quad faces and single-sided rendering. Its eight bays shall expose the internal subsystems. Source: GriffinVisualConfigurationRequirements::GriffinVisualConfiguration and OpenUSD UsdGeomMesh topology. Rationale: verify physical mesh topology and normals directly; a scene label cannot prove geometry. */
    }
    requirement def GBC009_OpenSideBays {
        doc /* GBC-009 [configuration] legacy side-bay panel parts shall be removed in the open-frame review configuration so all eight bays expose interior structure and hardware. Legacy panel prims are removed from their owning source layer using typed Editor operations. Rationale: inherited skins otherwise reconstruct an opaque shell around an open primary frame. */
    }
    requirement def GBC010_DeckSkirtSeparation {
        doc /* GBC-010 [assembly geometry] the upper payload deck and lower service skirt shall remain distinct, non-intersecting envelopes in the bus frame. Verification uses the oriented-box separating-axis margin computed from their typed SysML Dimensions and Position values. Rationale: this preserves a real service bay instead of allowing two separately named solids to collapse into an overlapping slab. The spacing is derived from the authored centers and thicknesses, not duplicated as another clearance literal. */
    }
    requirement def GBC011_TankSupportOpenings {
        doc /* GBC-011 [assembly geometry] the bus shall contain a separate octagonal tank-support perimeter using the shared bus profile, with four annular through-opening collars whose centers and bore radii follow the typed tank stations and support dimensions in GriffinVisualConfiguration. Each bore shall clear its scaled retention bands by the shared minimumTankFrameClearanceM datum. The collars shall preserve open bores and remain render-only. These are explicitly replaceable visual-study assumptions because the supplier interface drawing is not public. */
    }
    requirement def GBC012_SourceOwnedAppearance {
        doc /* GBC-012 [appearance] the composed bus display colors shall match the linear values declared once in GriffinVisualConfiguration; scene builders shall not author an independent palette. */
    }

    requirement gbc001 : GBC001_BusIdentity { subject bus : GriffinBusComponent; }
    requirement gbc002 : GBC002_BusEnvelope { subject bus : GriffinBusComponent; }
    requirement gbc003 : GBC003_BusPresentationOwnership { subject bus : GriffinBusComponent; }
    requirement gbc004 : GBC004_BusTraceability { subject bus : GriffinBusComponent; }
    requirement gbc005 : GBC005_BusFrameGeometry { subject bus : GriffinBusComponent; }
    requirement gbc006 : GBC006_DeckGeometry { subject bus : GriffinBusComponent; }
    requirement gbc007 : GBC007_AssemblyRailGeometry { subject bus : GriffinBusComponent; }
    requirement gbc008 : GBC008_OctagonalBodyShape { subject bus : GriffinBusComponent; }
    requirement gbc009 : GBC009_OpenSideBays { subject bus : GriffinBusComponent; }
    requirement gbc010 : GBC010_DeckSkirtSeparation { subject bus : GriffinBusComponent; }
    requirement gbc011 : GBC011_TankSupportOpenings { subject bus : GriffinBusComponent; }
    requirement gbc012 : GBC012_SourceOwnedAppearance { subject bus : GriffinBusComponent; }

    verification def Verify_GriffinBusRequirements {
        subject bus : GriffinBusComponent;
        verify gbc001;
        verify gbc002;
        verify gbc003;
        verify gbc004;
        verify gbc005;
        verify gbc006;
        verify gbc007;
        verify gbc008;
        verify gbc009;
        verify gbc010;
        verify gbc011;
        verify gbc012;
    }
}
