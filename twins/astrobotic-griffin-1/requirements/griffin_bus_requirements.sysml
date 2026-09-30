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

    constraint def GBC_SupportClearance {
        in measuredClearanceM : Real;
        in requiredClearanceM : Real;
        measuredClearanceM >= requiredClearanceM;
    }

    constraint def GBC_ObservedCountEquals {
        in observedCount : Real;
        in expectedCount : Real;
        observedCount == expectedCount;
    }

    constraint def GBC_MeasurementWithinTolerance {
        in absoluteError : Real;
        in allowedTolerance : Real;
        absoluteError >= 0.0 and absoluteError <= allowedTolerance;
    }

    constraint def GBC011_AnnularOpeningTopology {
        in observedPointCount : Real;
        in observedFaceCount : Real;
        in observedIndexCount : Real;
        in segmentCount : Real;
        observedPointCount == 4.0 * segmentCount
            and observedFaceCount == 4.0 * segmentCount
            and observedIndexCount == 16.0 * segmentCount;
    }

    constraint def GBC011_OpeningQuadsCoverSurface {
        in quadFaceCount : Real;
        in faceCount : Real;
        quadFaceCount == faceCount;
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
        doc /* GBC-005 [geometry] the internal eight-sided frame shall comprise eight upper and eight lower perimeter beams plus eight named corner posts. Plan span, frame height, and member stock shall resolve from GriffinVisualConfiguration and remain replaceable presentation estimates documented in griffin-size-evidence.md; the older NASA whole-lander envelope is not a current core measurement. */
        require GBC_MeasurementWithinTolerance;
    }
    requirement def GBC006_DeckGeometry {
        doc /* GBC-006 [geometry] the active TopDeckOctagon shall use typed dimensions and center datums from GriffinVisualConfiguration; the separate avionics deck remains a smaller service platform. These are presentation estimates inside the source-owned bus envelope, with rationale in griffin-size-evidence.md. */
        require GBC_ObservedCountEquals;
        require GBC_MeasurementWithinTolerance;
    }
    requirement def GBC007_AssemblyRailGeometry {
        doc /* GBC-007 [geometry] the composed bus shall expose the eight named Y-axis frame rails, with dimensions and signed X/Y/Z stations resolved from the typed visual configuration; the rails are render-only. */
        require GBC_MeasurementWithinTolerance;
    }
    requirement def GBC008_OctagonalBodyShape {
        doc /* GBC-008 [geometry] the internal body frame shall be eight-sided and built from sixteen perimeter members, with outward-wound quad faces and single-sided rendering. The flight exterior is checked separately under GBC-009. Source: typed GriffinVisualConfiguration and OpenUSD UsdGeomMesh topology. Rationale: verify composed mesh topology and normals directly. */
        require GBC_ObservedCountEquals;
    }
    requirement def GBC009_OpenSideBays {
        doc /* GBC-009 [configuration/appearance] obsolete side-bay panels shall remain absent. Eight named ExteriorFacet meshes shall provide the flight exterior over the internal frame. Each shall be a closed six-quad solid with eight points and twelve edges of incidence two, source-owned height, color, render purpose, single-sided faces and disabled collision. Source: ESA Griffin artist impression (2022-09-23), https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander, is the user-selected silhouette reference. Four broad side faces shall approximately match its 3:1 width/height ratio within the source-owned estimate tolerance; clipped corner faces are narrower. Astrobotic product rendering https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ corroborates a shallow belt and an observed 14-column by 5-row cell field. This is a concept reconstruction, not June 2026 as-built metrology. Thickness and edge gaps are explicitly estimated presentation values, not released thermal-blanket construction. */
        require GBC_ObservedCountEquals;
        require GBC_MeasurementWithinTolerance;
    }
    requirement def GBC010_DeckSkirtSeparation {
        doc /* GBC-010 [assembly geometry] the upper payload deck and lower service skirt shall remain distinct, non-intersecting envelopes in the bus frame. Verification uses the oriented-box separating-axis margin computed from their typed SysML Dimensions and Position values. Rationale: this preserves a real service bay instead of allowing two separately named solids to collapse into an overlapping slab. The spacing is derived from the authored centers and thicknesses, not duplicated as another clearance literal. */
        require GBC010_PositiveDeckSkirtClearance;
    }
    requirement def GBC011_TankSupportOpenings {
        doc /* GBC-011 [assembly geometry] the bus shall contain three separate octagonal tank-support rings on the typed upper, middle, and lower support planes, all using the shared bus profile. Each ring shall carry four annular through-opening collars whose centers and bore radii follow the typed tank stations. The upper and lower central bucket profile vertices are authored directly in the bus component frame; their local translation and rotation shall be zero and scale unity, so no instance offset detaches them from these source-defined planes. This identity placement is a coordinate convention, not a measured hardware dimension. All twelve collars shall clear the scaled retention bands by the shared minimumTankFrameClearanceM datum, preserve open bores, and remain render-only. Upper and lower shell ring radii and heights shall match the configuration profile within the geometry tolerance. Their compact diameters preserve tank and peripheral nozzle space instead of sweeping a solid shell through those owners. These are explicitly replaceable visual-study assumptions because the supplier interface drawing is not public. */
        require GBC_ObservedCountEquals;
        require GBC_MeasurementWithinTolerance;
        require GBC011_TankBoreClearance;
        require GBC_SupportClearance;
        require GBC011_AnnularOpeningTopology;
        require GBC011_OpeningQuadsCoverSurface;
    }
    requirement def GBC012_SourceOwnedAppearance {
        doc /* GBC-012 [appearance] the composed bus display colors shall match the linear values declared once in GriffinVisualConfiguration; scene builders shall not author an independent palette. */
        require GBC_MeasurementWithinTolerance;
    }

    requirement <'GBC-001'> gbc001 : GBC001_BusIdentity { subject bus : GriffinBusComponent; }
    requirement <'GBC-002'> gbc002 : GBC002_BusEnvelope { subject bus : GriffinBusComponent; }
    requirement <'GBC-003'> gbc003 : GBC003_BusPresentationOwnership { subject bus : GriffinBusComponent; }
    requirement <'GBC-004'> gbc004 : GBC004_BusTraceability { subject bus : GriffinBusComponent; }
    requirement <'GBC-005'> gbc005 : GBC005_BusFrameGeometry { subject bus : GriffinBusComponent; }
    requirement <'GBC-006'> gbc006 : GBC006_DeckGeometry { subject bus : GriffinBusComponent; }
    requirement <'GBC-007'> gbc007 : GBC007_AssemblyRailGeometry { subject bus : GriffinBusComponent; }
    requirement <'GBC-008'> gbc008 : GBC008_OctagonalBodyShape { subject bus : GriffinBusComponent; }
    requirement <'GBC-009'> gbc009 : GBC009_OpenSideBays { subject bus : GriffinBusComponent; }
    requirement <'GBC-010'> gbc010 : GBC010_DeckSkirtSeparation { subject bus : GriffinBusComponent; }
    requirement <'GBC-011'> gbc011 : GBC011_TankSupportOpenings { subject bus : GriffinBusComponent; }
    requirement <'GBC-012'> gbc012 : GBC012_SourceOwnedAppearance { subject bus : GriffinBusComponent; }

    verification def Verify_GriffinBusRequirements {
        subject bus : GriffinBusComponent;
        objective {
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
}
