package FlipBaselineRequirements {
    private import ScalarValues::String;

    // Proposed engineering contract. All verification cases below are PLANNED.
    // No runtime binding or satisfaction evidence is claimed by this declaration.
    part def FlipBaselineContract {
        attribute sourceComponent : String = "FlipRequirements::FlipRover";
        attribute verificationStatus : String = "PLANNED; acceptance limits unresolved";
        attribute evidenceIndex : String = "requirements/FLIP_IMPLEMENTATION_STEPS.md";
        attribute configurationTbd : String = "TBD: selected configuration, dimensional tolerances";
        attribute framesTbd : String = "TBD: mount datum tolerances";
        attribute massPropertiesTbd : String = "TBD: component masses, inertia tensors, allowable centre-of-mass envelope";
        attribute traceabilityTbd : String = "TBD: supplier CAD and interface control document revisions";
    }

    requirement def FBL001_Configuration {
        doc /* FBL-001 [engineering; proposed; PLANNED]
        The rover shall identify one selected configuration and reconcile CAD, visual USD and dynamic USD chassis dimensions, wheel stations and steering architecture before geometry acceptance.
        Verification: Inspection: compare dimensioned CAD and composed USD in a common frame; record intentional representation differences and resolve every unexplained discrepancy.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fbl001 : FBL001_Configuration { subject system : FlipBaselineContract; }

    requirement def FBL002_Frames {
        doc /* FBL-002 [engineering; proposed; PLANNED]
        The rover shall document its origin, up and forward axes and the millimetre-to-metre CAD export transform; each mount shall expose a named datum.
        Verification: Inspection and round-trip measurement: compare mount positions and bounds before and after export.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fbl002 : FBL002_Frames { subject system : FlipBaselineContract; }

    requirement def FBL003_MassProperties {
        doc /* FBL-003 [engineering; proposed; PLANNED]
        Each physical body shall have positive finite mass and inertia with a documented centre of mass; the assembly shall account for payload and solar deployment without double counting.
        Verification: Analysis: mass roll-up and stability assessment in stowed, deployed and loaded states.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fbl003 : FBL003_MassProperties { subject system : FlipBaselineContract; }

    requirement def FBL004_Traceability {
        doc /* FBL-004 [engineering; proposed; PLANNED]
        Each engineering value shall carry units, source revision and public-fact, study-assumption or unknown status; a verification shall identify the exact model revision and evidence.
        Verification: Inspection: audit all adopted limits and reject qualification claims based solely on presentation checks.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fbl004 : FBL004_Traceability { subject system : FlipBaselineContract; }

    verification def Verify_FLIPBaselineRequirements {
        subject system : FlipBaselineContract;
        verify fbl001;
        verify fbl002;
        verify fbl003;
        verify fbl004;
    }
}
