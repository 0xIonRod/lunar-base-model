package FlipMissionRequirements {
    private import ScalarValues::String;

    // Proposed engineering contract. All verification cases below are PLANNED.
    // No runtime binding or satisfaction evidence is claimed by this declaration.
    part def FlipMissionContract {
        attribute sourceComponent : String = "FlipRequirements::FlipRover";
        attribute verificationStatus : String = "PLANNED; acceptance limits unresolved";
        attribute evidenceIndex : String = "requirements/FLIP_IMPLEMENTATION_STEPS.md";
        attribute operationsTbd : String = "TBD: site, mission duration s, traverse distance m, duty cycle";
        attribute egressTbd : String = "TBD: direct or ramp branch, timing limits s, clearance m";
        attribute safeStateTbd : String = "TBD: trigger thresholds, response times s, recovery conditions";
    }

    requirement def FMO001_Operations {
        doc /* FMO-001 [engineering; proposed; PLANNED]
        The rover shall define mission duration, traverse distance, drive duty cycle and payload operating sequence against a selected landing site and illumination history.
        Verification: Analysis: execute a dated reference mission timeline with energy and thermal budgets.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fmo001 : FMO001_Operations { subject system : FlipMissionContract; }

    requirement def FMO002_Egress {
        doc /* FMO-002 [engineering; proposed; PLANNED]
        The rover shall remain restrained until the lander confirms touchdown and the selected egress path is ready; release shall precede driving and shall be confirmed.
        Verification: Integration test: nominal deployment and premature-release, failed-release and blocked-path fault cases; Griffin owns restraint actuation.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fmo002 : FMO002_Egress { subject system : FlipMissionContract; }

    requirement def FMO003_SafeState {
        doc /* FMO-003 [engineering; proposed; PLANNED]
        The rover shall enter a defined safe state on stale commands, loss of localization, depleted energy reserve or thermal limit violation.
        Verification: Fault injection: verify stop, payload load shedding, telemetry and guarded recovery against the allocated deadlines.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fmo003 : FMO003_SafeState { subject system : FlipMissionContract; }

    verification def Verify_FLIPMissionRequirements {
        subject system : FlipMissionContract;
        verify fmo001;
        verify fmo002;
        verify fmo003;
    }
}
