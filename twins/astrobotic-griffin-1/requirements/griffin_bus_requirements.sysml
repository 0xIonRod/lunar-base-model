package GriffinBusRequirements {
    /* The bus is a real SysML composition, not a String list of child names.
     * Metric design values are owned by GriffinVisualConfiguration. */
    part def GriffinBusFrameStructure;
    part def GriffinPayloadDeck;
    part def GriffinLowerServiceSkirt;
    part def GriffinAvionicsDeck;
    part def GriffinAvionicsPod;
    part def GriffinServiceBay;

    part def GriffinBusComponent {
        part perimeterFrame : GriffinBusFrameStructure;
        part payloadDeck : GriffinPayloadDeck;
        part lowerServiceSkirt : GriffinLowerServiceSkirt;
        part avionicsDeck : GriffinAvionicsDeck;
        part avionicsPod : GriffinAvionicsPod;
        part serviceBayPort : GriffinServiceBay;
        part serviceBayStarboard : GriffinServiceBay;
    }

    requirement def GBC001_BusIdentity {
        doc /* GBC-001 [topology] the bus is a named, visible hexagonal visual component with a primary six-sided airframe, lower hexagonal service skirt, and upper hexagonal isogrid deck. */
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
        doc /* GBC-005 [geometry] the open six-sided frame shall comprise six upper and six lower outward-wound perimeter beams plus six named corner rails. The rail outside faces define the 4.50 m X/Z plan envelope; the perimeter mesh spans the 2.00 m core-frame height and meets the deck and lower skirt. Source: public Griffin imagery establishes a faceted structural bus, not released CAD. Rationale: a connected, open member layout reveals subsystem placement and removes the visually opaque prism; 0.16 m section stock is a replaceable study assumption shared by the ring members and rails. */
    }
    requirement def GBC006_DeckGeometry {
        doc /* GBC-006 [geometry] the active TopDeckHex shall use the typed deck width, depth, thickness, and center-Y datums resolved from GriffinVisualConfiguration; the separate avionics deck remains a smaller service platform. These are derived presentation datums inside the 4.50 m x 4.50 m x 2.00 m hexagonal bus envelope. */
    }
    requirement def GBC007_AssemblyRailGeometry {
        doc /* GBC-007 [geometry] the composed bus shall expose the six named Y-axis frame rails, with dimensions and signed X/Y/Z stations resolved from the typed visual configuration; the rails are render-only. */
    }
    requirement def GBC008_HexagonalBodyShape {
        doc /* GBC-008 [geometry] the primary body shall be a six-sided open frame built from twelve perimeter members, with outward-wound quad faces and single-sided rendering. Its six bays shall expose the internal subsystems. Source: GriffinVisualConfigurationRequirements::GriffinVisualConfiguration and OpenUSD UsdGeomMesh topology. Rationale: verify physical mesh topology and normals directly; a scene label cannot prove geometry. */
    }
    requirement def GBC009_OpenSideBays {
        doc /* GBC-009 [configuration] the six identified side-bay panel parts shall be inactive in the open-frame review configuration so all six bays expose interior structure and hardware. The panel identities are a typed enumeration and the reversible visibility opinion is authored by the Editor. Rationale: inherited skins otherwise reconstruct an opaque shell around an open primary frame. */
    }
    requirement def GBC010_DeckSkirtSeparation {
        doc /* GBC-010 [assembly geometry] the upper payload deck and lower service skirt shall remain distinct, non-intersecting envelopes in the bus frame. Verification uses the oriented-box separating-axis margin computed from their typed SysML Dimensions and Position values. Rationale: this preserves a real service bay instead of allowing two separately named solids to collapse into an overlapping slab. The spacing is derived from the authored centers and thicknesses, not duplicated as another clearance literal. */
    }

    requirement gbc001 : GBC001_BusIdentity { subject bus : GriffinBusComponent; }
    requirement gbc002 : GBC002_BusEnvelope { subject bus : GriffinBusComponent; }
    requirement gbc003 : GBC003_BusPresentationOwnership { subject bus : GriffinBusComponent; }
    requirement gbc004 : GBC004_BusTraceability { subject bus : GriffinBusComponent; }
    requirement gbc005 : GBC005_BusFrameGeometry { subject bus : GriffinBusComponent; }
    requirement gbc006 : GBC006_DeckGeometry { subject bus : GriffinBusComponent; }
    requirement gbc007 : GBC007_AssemblyRailGeometry { subject bus : GriffinBusComponent; }
    requirement gbc008 : GBC008_HexagonalBodyShape { subject bus : GriffinBusComponent; }
    requirement gbc009 : GBC009_OpenSideBays { subject bus : GriffinBusComponent; }
    requirement gbc010 : GBC010_DeckSkirtSeparation { subject bus : GriffinBusComponent; }

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
    }
}
