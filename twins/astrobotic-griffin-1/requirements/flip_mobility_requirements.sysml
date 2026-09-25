package FlipMobilityRequirements {
    private import ScalarValues::String;

    // Proposed engineering contract. All verification cases below are PLANNED.
    // No runtime binding or satisfaction evidence is claimed by this declaration.
    part def FlipMobilityContract {
        attribute sourceComponent : String = "FlipRequirements::FlipRover";
        attribute verificationStatus : String = "PLANNED; acceptance limits unresolved";
        attribute evidenceIndex : String = "requirements/FLIP_IMPLEMENTATION_STEPS.md";
        attribute terrainEnvelopeTbd : String = "TBD: slopes deg, obstacles m, soil model, speed m/s, stopping distance m";
        attribute steeringTbd : String = "TBD: steering mode, angle limits deg, rate deg/s, turning radius m";
        attribute drivetrainTbd : String = "TBD: torque Nm, speed rad/s, gear efficiency, current A, stall duration s";
        attribute wheelSuspensionTbd : String = "TBD: wheel loads N, stiffness N/m, damping Ns/m, travel m, wear life";
    }

    requirement def FMB001_TerrainEnvelope {
        doc /* FMB-001 [engineering; proposed; PLANNED]
        The rover shall traverse and stop within a declared envelope of slope, cross-slope, obstacle height, trench width and soil properties with the specified payload.
        Verification: Analysis and terrain testing: record slip, sinkage, clearance and stability at envelope boundaries.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fmb001 : FMB001_TerrainEnvelope { subject system : FlipMobilityContract; }

    requirement def FMB002_Steering {
        doc /* FMB-002 [engineering; proposed; PLANNED]
        The rover shall use a selected steering law consistently across wheel stations, controls and requirements; mode changes shall require the defined stopped condition.
        Verification: Test: commanded straight, left, right and reverse motion; measure station angles and turning radius.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fmb002 : FMB002_Steering { subject system : FlipMobilityContract; }

    requirement def FMB003_Drivetrain {
        doc /* FMB-003 [engineering; proposed; PLANNED]
        Every driven wheel shall receive solver torque and return shaft speed; electrical demand and thermal losses shall follow the same drivetrain state.
        Verification: Runtime test: loaded drive and stall cases with all wheel port bindings resolved and torque, speed, current and loss telemetry recorded.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fmb003 : FMB003_Drivetrain { subject system : FlipMobilityContract; }

    requirement def FMB004_WheelSuspension {
        doc /* FMB-004 [engineering; proposed; PLANNED]
        Each wheel station shall meet its allocated load, deformation and travel envelope without chassis interference or loss of required ground contact.
        Verification: Component test: tire stiffness and suspension load/travel curves, then integrated terrain testing.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fmb004 : FMB004_WheelSuspension { subject system : FlipMobilityContract; }

    verification def Verify_FLIPMobilityRequirements {
        subject system : FlipMobilityContract;
        verify fmb001;
        verify fmb002;
        verify fmb003;
        verify fmb004;
    }
}
