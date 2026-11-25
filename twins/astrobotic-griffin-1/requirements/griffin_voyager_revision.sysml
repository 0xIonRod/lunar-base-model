package GriffinVoyagerRevision {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    part def VisualStudy {
        doc /* NASA Photojournal PIA26708 Figure D and Voyager's
         * acceptance-test footage guide the folded foil and apron.
         * The dimensions are visual estimates on the installed skirt. */
        /* Voyager's Griffin acceptance-test LinkedIn image and Nov 13 X
         * footage show two rimmed openings and a divided rectangular plate
         * on the unpanelled belt. Positions and depths in the blanket's
         * local frame (+Z outward) are visual estimates in metres. */
        attribute AftOpeningCentersM : Real[2] = (-0.66, 0.47);
        attribute AftOpeningRadiiM : Real[2] = (0.115, 0.092);
        attribute AftOpeningHeightM : Real = 0.22;
        attribute AftPlateSizeM : Real[3] = (0.49, 0.43, 0.085);
        attribute SolarContactWidthM : Real = 0.010;
        attribute SolarContactLengthM : Real = 0.006;
        // Appearance estimates for the recessed adapter and the A110 optics.
        attribute SkirtAdapterInsetFraction : Real = .61;
        attribute SkirtAdapterColor : Real[3] = (.16, .18, .20);
        attribute RcsCoreTint : Real[3] = (1.0, .94, .88);
        attribute RcsEdgeTint : Real[3] = (.80, .44, .39);
        attribute RcsCoreFraction : Real = .52;
        attribute RcsCoreWidth : Real = .36;
        attribute RcsFlicker : Real = .33;
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
