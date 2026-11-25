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

    constraint def FMR002_WheelCalibration {
        in totalSupportN : Real;
        in settledPlanarComponentMps : Real;
        in towAtFiveN : Real;
        in towAtTenN : Real;
        in peakPivotSideN : Real;
        in peakPivotTorqueNm : Real;
        in peakMovingSideN : Real;
        in peakSoilSinkageM : Real;
        in peakOpposingPowerW : Real;
        in minOpposingPowerW : Real;
        totalSupportN > 0.95 * 729.0 and totalSupportN < 1.05 * 729.0
            and settledPlanarComponentMps < 0.05
            and towAtFiveN >= 0.82 * 71.4 and towAtFiveN <= 1.18 * 71.4
            and towAtTenN >= 0.82 * 113.0 and towAtTenN <= 1.18 * 113.0
            and peakPivotSideN > 0.0 and peakPivotTorqueNm > 0.0 and peakMovingSideN > 0.0
            and peakSoilSinkageM > 0.0 and peakOpposingPowerW > 0.0 and minOpposingPowerW >= -1.0e-8;
    }
    requirement def FMR002_LoadAndGrip {
        doc /* On regolith all four wheels shall carry the settled lunar vehicle
         * weight within the total support bound. Each wheel shall transmit drive
         * torque and oppose sideways slip in the pivot, develop side force during
         * a rolling turn, and engage the soil model. The prescribed-wheel tow
         * and contact-subdivision tests check force magnitudes and moments.
         * FLIP-specific force and yaw accuracy remains open under FMR-005. */
        require FMR002_WheelCalibration;
    }
    requirement <'FMR-002'> fmr002 : FMR002_LoadAndGrip { subject rover : FlipRover; }

    constraint def FMR003_PivotEnvelope {
        in opposedPeakYawRadPerS : Real;
        in signedEndYawRadPerS : Real;
        in peakYawRadPerS : Real;
        in peakSideMps : Real;
        in releaseYawRadPerS : Real;
        opposedPeakYawRadPerS < 0.02 and signedEndYawRadPerS > 0.12
            and peakYawRadPerS < 0.35 and peakSideMps < 0.15 and releaseYawRadPerS < 0.025;
    }
    requirement def FMR003_ManualPivot {
        doc /* On the Griffin steering fixture, opposed keys held for 1 s shall
         * cancel. With throttle released, A and D separately shall yaw left
         * and right within the pivot envelope over 3 s. Residual yaw shall
         * meet the release limit after 2 s without applying the brake. */
        require FMR003_PivotEnvelope;
    }
    requirement <'FMR-003'> fmr003 : FMR003_ManualPivot { subject rover : FlipRover; }

    constraint def FMR004_MovingTurnEnvelope {
        in signedEntryMps : Real;
        in straightYawRadPerS : Real;
        in signedExitMps : Real;
        in signedEndYawRadPerS : Real;
        in peakYawRadPerS : Real;
        in peakSideMps : Real;
        in straightenedYawRadPerS : Real;
        in straightenedSideMps : Real;
        in brakedPlanarComponentMps : Real;
        signedEntryMps > 3.0 and straightYawRadPerS < 0.035 and signedExitMps > 3.0
            and signedEndYawRadPerS > 0.015 and peakYawRadPerS < 0.13 and peakSideMps < 0.50
            and straightenedYawRadPerS < 0.03 and straightenedSideMps < 0.15
            and brakedPlanarComponentMps < 0.05;
    }
    requirement def FMR004_ManualMovingTurn {
        doc /* After 4 s of straight drive, retain travel direction and turn
         * toward the commanded nose direction during a 3 s W+D or S+A arc.
         * Bound chassis lateral speed throughout each arc. Release steering
         * while driving forward for 2 s, then brake for 8 s before reversing.
         * Numeric bounds in FMR-003 and FMR-004 are Twin handling criteria. */
        require FMR004_MovingTurnEnvelope;
    }
    requirement <'FMR-004'> fmr004 : FMR004_ManualMovingTurn { subject rover : FlipRover; }

    requirement def FMR005_FLIPHandlingValidation {
        doc /* Before claiming FLIP-specific physical accuracy, compare independent,
         * representative wheel or rover measurements with model predictions.
         * Record wheel construction, soil state, gravity or validated scaling,
         * normal load, slip angle, longitudinal slip, speed and uncertainties.
         * Include lateral force at both signs of slip and multiple loads, then
         * pivot, steering release and moving-turn yaw and sideslip time histories.
         * Agree error bands for the intended use before evaluating held-out runs.
         * Status open. The Apollo proxy and the native steering regression alone
         * cannot close this physical validation requirement. */
    }
    requirement <'FMR-005'> fmr005 : FMR005_FLIPHandlingValidation { subject rover : FlipRover; }

    verification def Verify_FLIPSteering {
        subject rover : FlipRover;
        objective { verify fmr002; verify fmr003; verify fmr004; }
    }
}
