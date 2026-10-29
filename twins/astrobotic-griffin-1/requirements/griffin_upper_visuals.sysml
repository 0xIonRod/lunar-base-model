package GriffinUpperVisualStudy {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    part def UpperHardware {
        doc /* Visual reconstruction, 28 October 2026. Astrobotic's full-system
         * hot-fire report confirms three helium pressurant tanks in addition
         * to four main propellant tanks. The NASA/Astrobotic FLIP rendering
         * shows two prominent horizontal upper bottles. Only those two are
         * reconstructed here; the third bottle's placement is unresolved.
         * All dimensions, mounting details and optical parameters below are
         * study assumptions. No pressure inventory, mass or load is implied.
         * Frame: SI, Y-up, installed at the existing GriffinBus origin. */
        attribute BottleRadiusM : Real = 0.32;
        attribute BottleBarrelLengthM : Real = 1.35;
        attribute BottleCenterYM : Real = 1.18;
        attribute BottleCentersZM : Real[2] = (-1.72, 1.72);
        attribute BandStationsXM : Real[2] = (-0.45, 0.45);
        attribute BandWidthM : Real = 0.045;
        attribute BandThicknessM : Real = 0.008;
        attribute FootWidthM : Real = 0.11;
        attribute FootHeightM : Real = 0.08;
        attribute FootDepthM : Real = 0.40;
        attribute FootCenterYM : Real = 0.82;
        attribute ValveRadiusM : Real = 0.045;
        attribute ValveLengthM : Real = 0.09;
        attribute DomeStations : Integer = 12;
        attribute AngularSegments : Integer = 64;
        attribute NormalCreaseDeg : Real = 30.0;
        attribute DeckHalfWidthM : Real = 1.50;
        attribute DeckCornerStationM : Real = 0.86;
        attribute DeckThicknessM : Real = 0.016;
        attribute DeckLocalYM : Real = -0.020;
        attribute BoltRadiusM : Real = 0.012;
        attribute BoltHeightM : Real = 0.006;
        attribute BoltRailStationM : Real = 1.56;
        attribute BoltPitchM : Real = 0.36;
        attribute BoltCenterYM : Real = 0.043;
        attribute UpperFoilCrinkle : Real = 34.0;
        attribute UpperFoilFacet : Real = 0.26;
        attribute UpperFoilSheen : Real = 0.62;
        attribute SkirtFoilCrinkle : Real = 26.0;
        attribute SkirtFoilFacet : Real = 0.32;
        attribute SkirtFoilSheen : Real = 0.60;
        attribute SkirtFoilAxialScale : Real = 1.4;
        // Exterior blankets follow measured source-mesh frame bays, not a
        // second octagon size. The following seam/finish details are visual
        // study assumptions informed by NASA/JPL PIA26708 hardware photos.
        attribute BlanketEdgeGapM : Real = 0.008;
        attribute BlanketThicknessM : Real = 0.008;
        attribute BlanketFaceInsetM : Real = 0.004;
        attribute BlanketTapeWidthM : Real = 0.045;
        attribute BlanketTapeHeightM : Real = 0.025;
        attribute BlanketTapeDepthM : Real = 0.002;
        attribute BlanketTapeStationFraction : Real = 0.32;
        attribute BlanketTapeTopInsetM : Real = 0.035;
    }
}
