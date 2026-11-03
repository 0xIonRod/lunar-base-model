package FlipMotionRequirements {
    private import ScalarValues::Real;
    private import FlipRequirements::FlipRover;

    part def MotionStudy {
        doc /* Simulator acceptance envelope for reconstructed FLIP, not
         * supplier braking data. Establish the same entry speed in each
         * direction, then measure a physical stop and stationary dwell.
         * Friction, mass, torque and damping remain owned by composed USD. */
        attribute settleDurationS : Real = 2.0;
        attribute settleTimeoutS : Real = 6.0;
        attribute driveTimeoutS : Real = 6.0;
        attribute brakeEntrySpeedMps : Real = 3.0;
        attribute maximumBrakeEntrySpeedMps : Real = 3.2;
        attribute stoppedSpeedMps : Real = 0.1;
        attribute minimumAverageDecelerationMps2 : Real = 0.4;
        attribute brakeResponseAllowanceS : Real = 0.25;
        attribute maximumStoppingDistanceM : Real = 8.0;
        attribute stoppedDwellS : Real = 0.5;
        attribute maximumStoppedDriftM : Real = 0.1;
        attribute minimumMotionTravelM : Real = 0.05;
        attribute minimumWheelRateRadPerS : Real = 0.1;
        attribute minimumRenderRotationDot : Real = 0.9999;
        attribute minimumUprightAxisY : Real = 0.906307787;
    }

    requirement def FMR001_ControlledStop {
        doc /* FMR-001: native forward and reverse motion must advance, roll
         * all four authored wheel visuals and stay upright. Braking starts
         * at MotionStudy's entry speed within its upper bound. Stop within
         * the distance bound and the time derived from measured entry speed,
         * minimum average deceleration and response allowance. Retain the
         * stopped-speed and drift limits throughout the dwell. A rejected
         * command, missing sample or failed observation emits the terminal
         * failure verdict with measured speed, time, distance and bounds. */
    }
    requirement <'FMR-001'> fmr001 : FMR001_ControlledStop {
        subject rover : FlipRover;
    }
    verification def Verify_FLIPMotion {
        subject rover : FlipRover;
        objective { verify fmr001; }
    }
}
