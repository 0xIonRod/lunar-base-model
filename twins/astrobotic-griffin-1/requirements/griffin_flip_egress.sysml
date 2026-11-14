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
         * the mounted CAD rover. The mesh strips show rest-pose routing;
         * ControlledDescent defines the separate live wheel-wrap study.
         * Attachment strength and flight restrained descent are unqualified.
         * V12 EgressPair experiment adds a passive elastic cylindrical wrap,
         * k=8000 N/m and damping=600 N.s/m (study assumptions, not flight data).
         * Isolated conservation checks pass; the coupled vehicle descent failed
         * safe-attitude acceptance and is excluded from the V12 film. */
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
        attribute maximumParkedRollbackM : Real = 0.025;
        attribute webbingWidthM : Real = 0.045;
        attribute webbingThicknessM : Real = 0.004;
        attribute tetherAnchorXM : Real = 1.16;
        attribute tetherAnchorYM : Real = 2.16;
        attribute rearWheelWrapXM : Real = 0.85;
        attribute rearWheelWrapYM : Real = 3.04;
        // Renderer assumptions only; fiber chemistry, weave and optics unknown.
        attribute webbingColor : Real[3] = (0.30, 0.28, 0.24);
        attribute webbingRoughness : Real = 0.78;
        attribute webbingWeavePitchM : Real = 0.0009;
        attribute webbingNormalStrength : Real = 0.10;
    }
    part def ControlledDescent {
        doc /* Routed cylindrical rear-wheel-wrap and ideal winch study.
         * These values are explicit assumptions, not measured fabric
         * properties or released flight limits. Modelica owns line material
         * velocity, tension, energy, routing and reaction wrenches; the shared
         * Rhai sequence qualifies native motion and ground-transfer gates. */
        attribute stiffnessNPerM : Real = 4000.0;
        // A wrap couples through wheel spin as well as body translation.
        // I/R^2=9 kg for the retained 1.946025 kg m2, 0.465 m wheel;
        // critical axial damping is 2*sqrt(4000*9)=379.5 N s/m.
        // The sampled 60 Hz coupling uses the explicit 300 N s/m study value.
        attribute dampingNsPerM : Real = 300.0;
        // Nominal rest length. Runtime geometry must pass the preload bound
        // before either winch is enabled.
        attribute initialLengthM : Real = 0.70;
        attribute payoutSpeedMps : Real = 0.12;
        attribute payoutExtensionM : Real = 0.03;
        attribute tensionLimitN : Real = 2500.0;
        // Two upper wheel strands resist roughly twice the body travel per
        // wheel. This bounded motor command exceeds their low preload drag;
        // the measured speed governor and native brakes remain authoritative.
        attribute driveThrottleLimit : Real = 0.25;
        attribute exitDistanceM : Real = 6.0;
        attribute waypointRadiusM : Real = 0.10;
        // At the minimum accepted progress (0.05 m / 2 s), 6 m takes
        // 240 s; reserve another 60 s for landing, preload and handoffs.
        attribute testDurationTicks : Real = 18000.0;
        attribute releaseTensionN : Real = 5.0;
        attribute releaseElasticEnergyJ : Real = 0.05;
        // Sequence acceptance assumptions, not Astrolab flight limits.
        attribute minimumPretensionN : Real = 10.0;
        // Native wrench-response probe measured 1-2 fixed steps of latency.
        // Three consecutive unsupported/unloaded samples are a real loss;
        // speed, attitude, overload and imbalance stops remain immediate.
        attribute restraintLossDwellTicks : Real = 3.0;
        attribute targetPretensionN : Real = 50.0;
        // A shallow sling needs more tension than its vertical load share.
        // Near vertical, rear-contact moment balance estimates ~700 N/line;
        // retain 750 N for pose and 1000 N governor authority below the 2 kN gate.
        attribute governorTensionN : Real = 1000.0;
        attribute poseTensionN : Real = 750.0;
        attribute loadingResponseTimeS : Real = 0.15;
        attribute unloadingResponseTimeS : Real = 0.05;
        // Bounded ideal take-up actuator. Saturation is retained while load
        // builds; the commanded tension is not an instantaneous force source.
        // This is a study limit, not a flight winch specification.
        attribute maximumTakeupSpeedMps : Real = 2.50;
        attribute maximumPretensionN : Real = 250.0;
        attribute preloadRateMps : Real = 0.01;
        attribute maximumPretensionDifferenceN : Real = 75.0;
        attribute pretensionDwellTicks : Real = 60.0;
        attribute maximumArmingTicks : Real = 6000.0;
        attribute maximumArmingRadialSpeedMps : Real = 0.05;
        attribute postDetachSettleTicks : Real = 120.0;
        attribute unloadPayoutSpeedMps : Real = 0.02;
        attribute groundedWheelCenterMinM : Real = 0.35;
        attribute groundedWheelCenterMaxM : Real = 0.58;
        attribute minimumUprightCos : Real = 0.90;
        // Egress intentionally pitches toward vertical (LEAG 5034 Fig. 2).
        // Preserve the rail side direction through that pitch; the upright
        // gate above applies only after all wheels reach the ground.
        attribute minimumRailAlignmentCos : Real = 0.98;
        attribute maximumOverCenterPitchDeg : Real = 5.0;
        attribute maximumNoseUpPitchDeg : Real = 10.0;
        attribute groundTransferSpeedMps : Real = 0.10;
        attribute groundTransferRateRadps : Real = 0.05;
        attribute payoutStopAngularSpeedRadps : Real = 0.10;
        attribute groundTransferPayoutSpeedMps : Real = 0.04;
        // Lock wheel rotation before the rear tires lose the toe. The winch
        // lowers the restrained load; do not repeatedly release the brake.
        attribute rearLoweringBrakeMarginM : Real = 0.05;
        attribute rearBrakePitchDeg : Real = 70.0;
        // Rear brakes own restraint. After fixed front-wheel touchdown, allow
        // the full authored motor range to upright the rover; native traction
        // capacity and measured speed/rate governors still bound delivery.
        attribute groundTransferDriveThrottleLimit : Real = 1.0;
        attribute minimumTrackClearanceM : Real = 0.10;
        attribute minimumGroundDwellTicks : Real = 120.0;
        attribute minimumDescentProgressM : Real = 0.05;
        // Braked rear lowering measured 0.015 m/s with sustained preload.
        // Resolve real motion at 10 mm / 2 s; retain the 300 s overall bound.
        attribute minimumGroundTransferProgressM : Real = 0.01;
        attribute descentStallTicks : Real = 120.0;
        attribute maximumDriveDistanceM : Real = 6.0;
        attribute minimumUnlockDriveDistanceM : Real = 0.10;
        attribute maximumLineTensionDifferenceN : Real = 750.0;
        attribute maximumMissionTensionN : Real = 2000.0;
        attribute maximumDescentSpeedMps : Real = 0.35;
        attribute governedDescentSpeedMps : Real = 0.10;
        attribute payoutStopSpeedMps : Real = 0.18;
    }
}
