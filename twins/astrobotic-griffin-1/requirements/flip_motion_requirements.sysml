package FlipMotionRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Boolean;
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
        // Driving/stopping with the panel held at its deployment request.
        // Simulator study acceptance, not a flight actuator specification.
        attribute maximumPanelAngleErrorDeg : Real = 3.0;
        attribute maximumPanelRateDegPerS : Real = 15.0;
    }

    constraint def FMR001_DirectionEnvelope {
        in signedTravelM : Real;
        in minimumWheelRateRadPerS : Real;
        in minimumRenderRotationDot : Real;
        in minimumUprightAxisY : Real;
        in entrySpeedMps : Real;
        in stoppedSpeedMps : Real;
        in stopDurationS : Real;
        in stopDistanceM : Real;
        in maximumHoldSpeedMps : Real;
        in maximumHoldDriftM : Real;
        in panelSamples : Real;
        in maximumPanelAngleErrorDeg : Real;
        in maximumPanelRateDegPerS : Real;
        in nativeSequenceComplete : Boolean;
        nativeSequenceComplete == true
            and signedTravelM > MotionStudy::minimumMotionTravelM
            and minimumWheelRateRadPerS > MotionStudy::minimumWheelRateRadPerS
            and minimumRenderRotationDot > MotionStudy::minimumRenderRotationDot
            and minimumUprightAxisY >= MotionStudy::minimumUprightAxisY
            and entrySpeedMps >= MotionStudy::brakeEntrySpeedMps
            and entrySpeedMps <= MotionStudy::maximumBrakeEntrySpeedMps
            and stoppedSpeedMps <= MotionStudy::stoppedSpeedMps
            and stopDurationS > 0.0
            and stopDurationS <= (entrySpeedMps - MotionStudy::stoppedSpeedMps)
                / MotionStudy::minimumAverageDecelerationMps2 + MotionStudy::brakeResponseAllowanceS
            and stopDistanceM <= MotionStudy::maximumStoppingDistanceM
            and maximumHoldSpeedMps <= MotionStudy::stoppedSpeedMps
            and maximumHoldDriftM <= MotionStudy::maximumStoppedDriftM
            and panelSamples > 0.0
            and maximumPanelAngleErrorDeg <= MotionStudy::maximumPanelAngleErrorDeg
            and maximumPanelRateDegPerS <= MotionStudy::maximumPanelRateDegPerS;
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
        require FMR001_DirectionEnvelope;
    }
    requirement <'FMR-001'> fmr001 : FMR001_ControlledStop {
        subject rover : FlipRover;
    }
    verification def Verify_FLIPMotion {
        subject rover : FlipRover;
        objective { verify fmr001; }
    }
}
