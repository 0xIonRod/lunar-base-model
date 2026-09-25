package FlipInterfacesRequirements {
    private import ScalarValues::String;

    // Proposed engineering contract. All verification cases below are PLANNED.
    // No runtime binding or satisfaction evidence is claimed by this declaration.
    part def FlipInterfacesContract {
        attribute sourceComponent : String = "FlipRequirements::FlipRover";
        attribute verificationStatus : String = "PLANNED; acceptance limits unresolved";
        attribute evidenceIndex : String = "requirements/FLIP_IMPLEMENTATION_STEPS.md";
        attribute landerMountTbd : String = "TBD: bolt pattern, tolerances m, release stroke m, load limits N";
        attribute payloadTbd : String = "TBD: payload envelope m, fasteners, power W, data rate bit/s, thermal interface";
        attribute structuralQualificationTbd : String = "TBD: load spectra, acceleration m/s2, shock spectrum, factors of safety";
        attribute acceptanceEvidenceTbd : String = "TBD: qualification plan and evidence record locations";
    }

    requirement def FIF001_LanderMount {
        doc /* FIF-001 [engineering; proposed; PLANNED]
        The rover-side mounting interface shall specify attachment datums, restraints, umbilicals and keep-out volumes compatible with the Griffin-owned adapter.
        Verification: Interface inspection and integrated release test: verify transforms, connector separation and absence of residual constraints.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fif001 : FIF001_LanderMount { subject system : FlipInterfacesContract; }

    requirement def FIF002_Payload {
        doc /* FIF-002 [engineering; proposed; PLANNED]
        The rover shall allocate mechanical, electrical, data and thermal interfaces for payloads within the capacity referenced from FlipRequirements.
        Verification: Analysis and interface test: verify loaded mass/centre of mass, mounting, concurrent power, data transfer and thermal loads.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fif002 : FIF002_Payload { subject system : FlipInterfacesContract; }

    requirement def FIF003_StructuralQualification {
        doc /* FIF-003 [engineering; proposed; PLANNED]
        The rover shall withstand allocated launch vibration, release shock, landing and traverse loads in its stowed and operating configurations.
        Verification: Structural analysis and qualification tests with pre/post functional inspections.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fif003 : FIF003_StructuralQualification { subject system : FlipInterfacesContract; }

    requirement def FIF004_AcceptanceEvidence {
        doc /* FIF-004 [engineering; proposed; PLANNED]
        Each requirement shall have a verification method, resolved acceptance limits and revision-matched evidence before it can be marked satisfied.
        Verification: Review: require component results before assembly and mission results; missing runtime bindings or unresolved limits prevent a passing claim.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fif004 : FIF004_AcceptanceEvidence { subject system : FlipInterfacesContract; }

    verification def Verify_FLIPInterfacesRequirements {
        subject system : FlipInterfacesContract;
        verify fif001;
        verify fif002;
        verify fif003;
        verify fif004;
    }
}
