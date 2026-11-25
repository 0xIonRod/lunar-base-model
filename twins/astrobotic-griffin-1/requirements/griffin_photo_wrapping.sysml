package GriffinPhotoWrapping {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;

    part def VisualStudy {
        doc /* Visual reconstruction from Voyager's exposed Griffin photograph
         * in post 7521194558664134656 and NASA/JPL PIA26708 Figure D.
         * Broad folded silver covers, gathered ends and localized tape are
         * visible. The following dimensions and pattern controls are artistic
         * study estimates. They define render geometry in SI, Y-up, relative
         * to the existing bus and upper-bottle datums. They carry no pressure,
         * mass, collision, structural or thermal authority.
         * GVREF-NOV08-01, -02 and -03 in the photo review define acceptance. */
        attribute BusColumns : Integer = 8;
        attribute BusRows : Integer = 3;
        attribute BusOutsetM : Real = 0.018;
        attribute BusLowerOverhangM : Real = 0.12;
        attribute BusFoldDepthM : Real = 0.070;
        /* Voyager's November 13 acceptance film shows a loose lower hem
         * pulled into diagonal folds between the aft frame attachments. */
        attribute AftHemDropM : Real = 0.16;
        attribute AftPleatDepthM : Real = 0.095;
        attribute BusEdgeGatherM : Real = 0.018;
        attribute ShellThicknessM : Real = 0.003;
        attribute UpperCoverAllowanceM : Real = 0.035;
        attribute UpperCoverEndAllowanceM : Real = 0.025;
        attribute UpperCoverSegments : Integer = 8;
        attribute UpperCoverFoldDepthM : Real = 0.012;
        attribute FoilCrinklePerM : Real = 12.0;
        attribute FoilFacetSlope : Real = 0.16;
        attribute FoilSheen : Real = 0.62;
        attribute FoilMicroSlope : Real = 0.025;
        attribute TapeStations : Real[4] = (-0.38, -0.12, 0.19, 0.40);
        attribute TapeRows : Real[4] = (0.87, 0.20, 0.77, 0.31);
    }
}
