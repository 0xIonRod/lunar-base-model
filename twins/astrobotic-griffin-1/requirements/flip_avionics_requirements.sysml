package FlipAvionicsRequirements {
    private import ScalarValues::String;

    // Proposed engineering contract. All verification cases below are PLANNED.
    // No runtime binding or satisfaction evidence is claimed by this declaration.
    part def FlipAvionicsContract {
        attribute sourceComponent : String = "FlipRequirements::FlipRover";
        attribute verificationStatus : String = "PLANNED; acceptance limits unresolved";
        attribute evidenceIndex : String = "requirements/FLIP_IMPLEMENTATION_STEPS.md";
        attribute communicationsTbd : String = "TBD: frequency Hz, data rate bit/s, margin dB, latency and outage s";
        attribute navigationTbd : String = "TBD: position error m, heading error deg, detection range m, latency s";
        attribute faultRecoveryTbd : String = "TBD: fault list, detection/recovery times s, degraded modes";
        attribute telemetryTbd : String = "TBD: channel inventory, rates Hz, timestamp error s, storage bytes";
    }

    requirement def FAV001_Communications {
        doc /* FAV-001 [engineering; proposed; PLANNED]
        The rover shall support command and telemetry through a declared communications architecture with coverage, data-rate, latency and link-margin allocations.
        Verification: Link analysis and end-to-end test: include terrain occlusion, antenna orientation, blackout and reconnection.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fav001 : FAV001_Communications { subject system : FlipAvionicsContract; }

    requirement def FAV002_Navigation {
        doc /* FAV-002 [engineering; proposed; PLANNED]
        The rover shall estimate pose within an allocated error bound and detect hazards in time to stop over its operational lighting and terrain envelope.
        Verification: Test: compare pose with independent truth and inject slip, shadows, blinded sensors and localization loss.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fav002 : FAV002_Navigation { subject system : FlipAvionicsContract; }

    requirement def FAV003_FaultRecovery {
        doc /* FAV-003 [engineering; proposed; PLANNED]
        The rover shall detect defined processor, sensor, actuator and communications faults and execute a bounded recovery or safe-state transition.
        Verification: Fault injection: watchdog reset, stale sensor data, invalid command and actuator failure; retain event records.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fav003 : FAV003_FaultRecovery { subject system : FlipAvionicsContract; }

    requirement def FAV004_Telemetry {
        doc /* FAV-004 [engineering; proposed; PLANNED]
        Telemetry shall timestamp wheel state, energy, temperatures, deployment state, faults and navigation quality without silently dropping required channels.
        Verification: Runtime test: verify required channels, units, time alignment and loss indication at maximum configured load.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fav004 : FAV004_Telemetry { subject system : FlipAvionicsContract; }

    verification def Verify_FLIPAvionicsRequirements {
        subject system : FlipAvionicsContract;
        verify fav001;
        verify fav002;
        verify fav003;
        verify fav004;
    }
}
