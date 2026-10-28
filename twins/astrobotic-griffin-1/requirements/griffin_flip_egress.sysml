package GriffinFlipEgressStudy {
    private import ScalarValues::Real;
    private import ScalarValues::Boolean;
    part def CompactEgress {
        doc /* Architecture: Astrolab FLIP Mission Overview, LEAG October 2025,
         * abstract 5034, and Venturi NASA Battery Workshop 21 January 2026,
         * slide 25: steep tracks, curved transitions and fabric rear-wheel
         * tethers. Dimensions below are reconstruction assumptions in the
         * existing SI/Y-up lander frame, not released flight geometry.
         * Component +X is inboard and its lip points toward -X. The installed
         * 180-degree yaw selects lander +X, matching the retained payload yaw.
         * Track spacing follows
         * the mounted CAD rover. Tethers are rest-pose visual routing only:
         * payout, attachment strength and restrained descent are unqualified. */
        attribute stationsXM : Real[7] = (0.95, -1.95, -2.20, -2.42, -2.60, -2.74, -2.84);
        attribute installationYawDeg : Real = 180.0;
        // Operator drive selection: zero command coasts the H-bridge instead
        // of shorting its windings. A study control mode, not a flight claim.
        attribute idleMotorCoast : Boolean = true;
        attribute heightsYM : Real[7] = (2.12, 2.12, 2.08, 1.91, 1.62, 1.19, 0.63);
        attribute trackCentersZM : Real[2] = (-1.0, 1.0);
        attribute trackWidthM : Real = 0.48;
        attribute plateThicknessM : Real = 0.024;
        attribute curbWidthM : Real = 0.025;
        attribute curbHeightM : Real = 0.035;
        attribute webbingWidthM : Real = 0.045;
        attribute webbingThicknessM : Real = 0.004;
        attribute tetherAnchorXM : Real = 1.16;
        attribute tetherAnchorYM : Real = 2.16;
        attribute rearWheelWrapXM : Real = 0.85;
        attribute rearWheelWrapYM : Real = 3.04;
    }
}
