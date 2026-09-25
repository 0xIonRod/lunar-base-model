package FlipSolarDeploymentRequirements {
    private import ScalarValues::String;

    // Proposed engineering contract. All verification cases below are PLANNED.
    // No runtime binding or satisfaction evidence is claimed by this declaration.
    part def FlipSolarDeploymentContract {
        attribute sourceComponent : String = "FlipRequirements::FlipRover";
        attribute verificationStatus : String = "PLANNED; acceptance limits unresolved";
        attribute evidenceIndex : String = "requirements/FLIP_IMPLEMENTATION_STEPS.md";
        attribute articulationTbd : String = "TBD: flight hinge geometry and limits deg; CAD angles remain study values";
        attribute clearanceTbd : String = "TBD: minimum clearance m, manufacturing and deflection tolerances";
        attribute actuationTbd : String = "TBD: torque Nm, rate deg/s, cycle count, harness bend radius m";
    }

    requirement def FSD001_Articulation {
        doc /* FSD-001 [engineering; proposed; PLANNED]
        The runtime solar assembly shall expose a separately owned physical body and bounded revolute joint consistent with the selected CAD hinge datum.
        Verification: Inspection and runtime sweep: compare parent/child relationships, axis, initial pose and limit behavior.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fsd001 : FSD001_Articulation { subject system : FlipSolarDeploymentContract; }

    requirement def FSD002_Clearance {
        doc /* FSD-002 [engineering; proposed; PLANNED]
        The panel and attached hardware shall clear chassis, payload, mast and wheels throughout deployment, including tolerance and harness envelopes.
        Verification: CAD interference sweep and composed collision inspection over the full motion range.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fsd002 : FSD002_Clearance { subject system : FlipSolarDeploymentContract; }

    requirement def FSD003_Actuation {
        doc /* FSD-003 [engineering; proposed; PLANNED]
        The deployment system shall define actuator torque, rate, end-stop sensing, retention and failure response; the harness shall tolerate the full motion.
        Verification: Test: nominal deployment, stalled mechanism, missing end-stop and interrupted power cases.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fsd003 : FSD003_Actuation { subject system : FlipSolarDeploymentContract; }

    verification def Verify_FLIPSolarDeploymentRequirements {
        subject system : FlipSolarDeploymentContract;
        verify fsd001;
        verify fsd002;
        verify fsd003;
    }
}
