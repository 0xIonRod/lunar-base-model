package GriffinVoyagerRevision {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    part def VisualStudy {
        doc /* NASA Photojournal PIA26708 Figure D and Voyager's
         * acceptance-test footage guide the folded foil and apron.
         * The dimensions are visual estimates on the installed skirt. */
        attribute SkirtColumns : Integer = 6;
        attribute SkirtRows : Integer = 3;
        attribute SkirtFoldDepthM : Real = 0.072;
        attribute SkirtApronFoldDepthM : Real = 0.028;
        attribute SkirtApronTrimFraction : Real = 0.12;
        attribute SkirtFoilColor : Real[3] = (0.58, 0.62, 0.67);
        attribute SkirtApronFoilColor : Real[3] = (0.42, 0.46, 0.51);
        attribute SkirtFoilTapeColor : Real[3] = (0.49, 0.29, 0.10);
        attribute SkirtCoverThicknessM : Real = 0.002;
        attribute SkirtLipMarginM : Real = 0.002;
    }
}
