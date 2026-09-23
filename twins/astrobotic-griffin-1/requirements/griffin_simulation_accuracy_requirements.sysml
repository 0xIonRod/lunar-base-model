package GriffinSimulationAccuracyRequirements {
    private import Griffin1Requirements::Griffin1Lander;
    private import Griffin1Requirements::HostedRoverInterface;
    private import ScalarValues::Real;
    private import ScalarValues::Boolean;

    constraint def GR036_LandingStabilityWithinBounds {
        in telemetryFinite : Boolean;
        in sampleAvailable : Boolean;
        in minimumUprightAxisY : Real;
        in minimumUprightAxisYLimit : Real;
        in maximumGroundSpeedMps : Real;
        in maximumGroundSpeedLimitMps : Real;
        in maximumAngularSpeedRadPerSec : Real;
        in maximumAngularSpeedLimitRadPerSec : Real;
        in maximumHorizontalDriftM : Real;
        in maximumHorizontalDriftLimitM : Real;
        telemetryFinite and sampleAvailable
            and minimumUprightAxisY >= minimumUprightAxisYLimit
            and maximumGroundSpeedMps <= maximumGroundSpeedLimitMps
            and maximumAngularSpeedRadPerSec <= maximumAngularSpeedLimitRadPerSec
            and maximumHorizontalDriftM <= maximumHorizontalDriftLimitM;
    }

    // Domain-owned requirement definitions. Griffin1Requirements owns only
    // the integrated system subject, requirement usages, and verification.

    requirement def GR008_AttitudeCases {
        doc /* GR-008 [verification] exercise nominal, high-pitch, uneven-roll, and combined pitch/roll egress cases; report inconclusive when contact data is unavailable. Source: Twin mission verification plan. Assumption: these four cases span the dominant attitude sensitivities of a two-track egress study; inconclusive is required when the runtime cannot observe contact. */
    }

    requirement def GR021_MassProperties {
        doc /* GR-021 [physics planned] every dynamic body has finite positive mass, center of mass, and inertia; report planned until the generic query exposes all fields. Source: rigid-body physics contract. Assumption: the current inherited mass proxy is temporary; no flight acceptance is claimed until all fields are queryable and checked. */
    }

    requirement def GR022_SupportPolygon {
        doc /* GR-022 [physics planned] at touchdown, the projected center of mass lies inside the leg support polygon with a documented margin. Source: rigid-body stability criterion. Rationale: a support-polygon margin is the appropriate geometric test for tip-over risk; the current Twin lacks the complete runtime observation seam. */
    }

    requirement def GR023_ContactContinuity {
        doc /* GR-023 [physics planned] pad and selected egress-path contact planes remain continuous and non-penetrating over the tested terrain crop. Source: contact/terrain acceptance contract. Assumption: the selected terrain crop is representative for this study; broader terrain statistics are not yet available. */
    }

    requirement def GR027_PropulsionAlignment {
        doc /* GR-027 [visual+physics planned] nozzle and flame align with the thrust axis and plume geometry remains visual-only. Source: propulsion presentation/flight-model boundary. Assumption: the current bell/throat profile is a visual proxy because a public Griffin engine ICD is unavailable. */
    }

    requirement def GR031_DeterministicVerdict {
        doc /* GR-031 [test] the production Twin test emits a deterministic verdict with fixed tick rate, threads, and jitter, including inconclusive runtime states. Source: LunCoSim deterministic test runner contract. Rationale: fixed execution settings make regressions reproducible and prevent missing observations from being mistaken for PASS. */
    }

    requirement def GR036_LandingStability {
        doc /* GR-036 [simulation accuracy] during the 60 s landing-stability observation window, telemetry shall remain finite, samples shall be available, the lander upright-axis Y component shall remain at least 0.9393727128473789 (cosine of the 0.35 rad study tilt limit), horizontal ground speed shall not exceed 5.0 m/s, angular speed shall not exceed 2.0 rad/s, and horizontal drift shall not exceed 50.0 m. These are replaceable Twin study limits, not supplier performance specifications. Missing physics samples are inconclusive. */
        attribute landingStabilityHorizonS : Real = 60.0;
        attribute landingMinimumUprightAxisY : Real = 0.9393727128473789;
        attribute landingMaxGroundSpeedMps : Real = 5.0;
        attribute landingMaxAngularSpeedRadPerSec : Real = 2.0;
        attribute landingMaxHorizontalDriftM : Real = 50.0;
        require GR036_LandingStabilityWithinBounds;
    }


    // System integration requirement usages owned by this domain.
    requirement gr008 : GR008_AttitudeCases { subject rover : HostedRoverInterface; }
    requirement gr021 : GR021_MassProperties { subject lander : Griffin1Lander; }
    requirement gr022 : GR022_SupportPolygon { subject lander : Griffin1Lander; }
    requirement gr023 : GR023_ContactContinuity { subject lander : Griffin1Lander; }
    requirement gr027 : GR027_PropulsionAlignment { subject lander : Griffin1Lander; }
    requirement gr031 : GR031_DeterministicVerdict { subject rover : HostedRoverInterface; }
    requirement gr036 : GR036_LandingStability { subject lander : Griffin1Lander; }


    verification def Verify_GriffinLandingStability {
        subject lander : Griffin1Lander;
        objective {
            verify GriffinSimulationAccuracyRequirements::gr036;
        }
    }

}
