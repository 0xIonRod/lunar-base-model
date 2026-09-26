package GriffinMechanicalRequirements {
    private import Griffin1Requirements::Griffin1Lander;
    private import ScalarValues::Boolean;
    private import ScalarValues::Integer;
    private import ScalarValues::Real;

    // Domain-owned requirement definitions. Griffin1Requirements owns only
    // the integrated system subject, requirement usages, and verification.

    requirement def GR010_FunctionalLegs {
        doc /* GR-010 [public product value] retain exactly four visible functional landing-leg bodies with struts and pad colliders. Rationale: the public four-leg architecture determines count/topology; the visual strut and pad envelopes are separate study assumptions until an ICD is available. */
    }

    requirement def GR011_RampBodies {
        doc /* GR-011 [study control] retain two side-ramp bodies with contact geometry and revolute hinges; the command bound is a proxy, not a released mechanical limit. The current 50 degree (0.872664626 rad) command envelope comes from GriffinRampRequirements::rampMaxDeploymentAngleRad and is evaluated by its source-defined deployment constraint. Replace it when the mechanical ICD is released. */
    }

    requirement def GR012_LoadBearingMass {
        doc /* GR-012 [physics] every load-bearing subassembly has positive mass and explicit collision ownership; compound-body admission is a runtime gate. Source: LunCoSim physics admission contract. Rationale: positive mass and one declared collider owner prevent visual-only parts from silently becoming a second physical system. */
    }

    requirement def GR017_RampSymmetry {
        doc /* GR-017 [layout] optional ramps mirror in side placement, hinge rotation, and angle metadata when the ramp branch is selected. Source: Twin ramp component contract. Rationale: mirrored signs make port/starboard behavior deterministic and prevent one side from inheriting an accidental transform. */
    }

    constraint def GRC018_TopDeckColliderTopologyMatchesSource {
        in topologyMatches : Boolean;
        in sourceGeometryLinked : Boolean;
        topologyMatches and sourceGeometryLinked;
    }

    constraint def GRC018_TopDeckColliderProfileWithinTolerance {
        in profileDeviationM : Real;
        in toleranceM : Real;
        profileDeviationM <= toleranceM;
    }

    constraint def GRC018_TopDeckColliderOwnsContact {
        in collisionEnabled : Boolean;
        in proxyHidden : Boolean;
        in convexHullApproximation : Boolean;
        collisionEnabled and proxyHidden and convexHullApproximation;
    }

    requirement def GR018_HullAndDeck {
        attribute topDeckProfileToleranceM : Real = 0.001;
        require GRC018_TopDeckColliderTopologyMatchesSource;
        require GRC018_TopDeckColliderProfileWithinTolerance {
            in toleranceM = GR018_HullAndDeck::topDeckProfileToleranceM;
        }
        require GRC018_TopDeckColliderOwnsContact;
        doc /* GR-018 [mechanical and collision] the powered body and its load-bearing deck geometry shall have explicit collision ownership. The octagonal outer deck ring shall use eight individually convex beam colliders derived from the visible Bus/TopDeckOctagon profile; a single convex hull across this open perimeter is prohibited because it closes the tank openings. The central rover payload platform shall have a separate hidden convex collider derived from RoverPayloadDeck dimensions and profile. Each proxy shall carry a typed USD relationship to its composed visible source prim. Composed transforms, mesh points, collision state, and hidden proxy role shall match the SysML source within topDeckProfileToleranceM. The one-millimetre correspondence tolerance is a Twin geometry bound, not a supplier manufacturing tolerance. Public Griffin material confirms a main payload deck and optional rover interface but does not provide its mechanical ICD, so the dimensions remain replaceable simulation-study assumptions. */
    }

    requirement def GR019_LegPlacement {
        doc /* GR-019 [layout] mount four legs on signed horizontal body axes with mirrored pads and a documented local frame. Rationale: signed stations expose the four-leg support pattern and make symmetry errors observable in the composed stage. */
    }

    requirement def GR024_HingeFrames {
        doc /* GR-024 [physics planned] selected ramp hinge frames, axes, limits, and body ownership agree with the authored pose. Source: Twin mount-socket and revolute-joint contract. Rationale: checking the complete hinge frame prevents a visually plausible ramp from being physically attached to the wrong body or axis. */
    }

    requirement def GR025_SolarClearance {
        doc /* GR-025 [layout planned] arrays have clearance from bodies and each other in both stowed and deployed study states. Source: spacecraft deployable-clearance practice. Assumption: the current visual panel envelopes are proxies; the clearance margin must be replaced by a released deployment ICD. */
    }


    // System integration requirement usages owned by this domain.
    requirement <'GR-010'> gr010 : GR010_FunctionalLegs { subject lander : Griffin1Lander; }
    requirement <'GR-011'> gr011 : GR011_RampBodies { subject lander : Griffin1Lander; }
    requirement <'GR-012'> gr012 : GR012_LoadBearingMass { subject lander : Griffin1Lander; }
    requirement <'GR-017'> gr017 : GR017_RampSymmetry { subject lander : Griffin1Lander; }
    requirement <'GR-018'> gr018 : GR018_HullAndDeck { subject lander : Griffin1Lander; }
    requirement <'GR-019'> gr019 : GR019_LegPlacement { subject lander : Griffin1Lander; }
    requirement <'GR-024'> gr024 : GR024_HingeFrames { subject lander : Griffin1Lander; }
    requirement <'GR-025'> gr025 : GR025_SolarClearance { subject lander : Griffin1Lander; }

}
