package GriffinVoyagerRevision {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    part def VisualStudy {
        doc /* Voyager acceptance-test video, published November 2026, reviewed
         * 18 November. https://www.linkedin.com/posts/voyg-acceleratingtheadvantage-missionready-ugcPost-7527007400839774208-Ottj/
         * At 22.5 s: dark clipped cells, warm substrate, silver perimeter and
         * small retaining/tape stations. At 57.5 s: silver gathered lower
         * insulation. All dimensions below are visual study assumptions.
         * Retainers seat on frame edges; blanket folds remain outside the
         * existing skirt shell and below the apron. NASA Photojournal
         * PIA26708 figure D guides the foil folds and lip. No collision, mass or thermal properties are
         * introduced. Preserve the seven-engine aperture and physical owners. */
        attribute RetainerRadiusM : Real = 0.006;
        attribute RetainerHeightM : Real = 0.003;
        attribute RetainerFraction : Real = 0.18;
        attribute TapeWidthM : Real = 0.009;
        attribute TapeLengthM : Real = 0.024;
        attribute TapeThicknessM : Real = 0.0006;
        attribute SkirtColumns : Integer = 6;
        attribute SkirtRows : Integer = 3;
        attribute SkirtFoldDepthM : Real = 0.072;
        // Relief envelope and exposed rim for the skirt appearance study.
        attribute SkirtApronFoldDepthM : Real = 0.028;
        attribute SkirtApronTrimFraction : Real = 0.12;
        attribute SkirtFoilColor : Real[3] = (0.58, 0.62, 0.67);
        attribute SkirtApronFoilColor : Real[3] = (0.42, 0.46, 0.51);
        attribute SkirtFoilTapeColor : Real[3] = (0.49, 0.29, 0.10);
        attribute SkirtCoverThicknessM : Real = 0.002;
        attribute SkirtLipMarginM : Real = 0.002;
        attribute RetainerColor : Real[3] = (0.24, 0.26, 0.28);
        attribute TapeColor : Real[3] = (0.38, 0.25, 0.07);
        // Small bright junctions visible between rows at 22.5 s. Illustrative
        // foil bridges only; flight string routing and circuit topology unknown.
        attribute InterconnectWidthM : Real = 0.006;
        attribute InterconnectOverlapM : Real = 0.001;
        attribute InterconnectThicknessM : Real = 0.0005;
        // Bounded render/authoring groups; not an electrical string partition.
        attribute InterconnectRowsPerMesh : Integer = 1;
    }
}
