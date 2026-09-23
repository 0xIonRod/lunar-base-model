package GriffinAssuranceRequirements {
    private import Griffin1Requirements::Griffin1Lander;
    private import Griffin1Requirements::HostedRoverInterface;

    // Domain-owned requirement definitions. Griffin1Requirements owns only
    // the integrated system subject, requirement usages, and verification.

    requirement def GR005_TraceableValues {
        doc /* GR-005 [traceability] every value is labelled public fact, project requirement, study proxy, or TBD with a source or rationale. Source: SysML/Rhai verification policy. Rationale: a reviewer must be able to tell certified/public data from a visual or runtime assumption. */
    }

    requirement def GR013_ParameterProvenance {
        doc /* GR-013 [traceability] status and provenance metadata are required for every study parameter and every inherited surrogate. Source: SysML/Rhai provenance policy. Rationale: reviewers need to distinguish a public datum, an engineering assumption, and a missing supplier value before trusting a verdict. */
    }

    requirement def GR014_TypedAuthoring {
        doc /* GR-014 [process] model edits use the typed USD path and rerun the Twin contract before save; filesystem rewrites are not acceptance evidence. Source: LunCoSim typed Editor authoring contract. Rationale: the runtime's composed stage, not a raw layer rewrite, is what the simulation and verification actually consume. */
    }

    requirement def GR029_PartProvenance {
        doc /* GR-029 [traceability] every canonical part records source/provenance and known, proxy, or TBD parameter status. Source: SysML provenance policy and the public Griffin/FLIP references listed on the parts. Rationale: part-level provenance makes replacement and review tractable when supplier data arrives. */
    }

    requirement def GR030_EvidenceGate {
        doc /* GR-030 [evidence] changed geometry groups require fresh headful visual evidence plus composed query output from the same document generation. Source: Twin evidence gate. Rationale: a screenshot alone cannot prove authored topology, while a query alone cannot prove the visible composition. */
    }


    // System integration requirement usages owned by this domain.
    requirement gr005 : GR005_TraceableValues { subject lander : Griffin1Lander; }
    requirement gr013 : GR013_ParameterProvenance { subject lander : Griffin1Lander; }
    requirement gr014 : GR014_TypedAuthoring { subject lander : Griffin1Lander; }
    requirement gr029 : GR029_PartProvenance { subject lander : Griffin1Lander; subject rover : HostedRoverInterface; }
    requirement gr030 : GR030_EvidenceGate { subject lander : Griffin1Lander; }

}
