package GriffinSimulationAccuracyRequirements {
    private import Griffin1Requirements::Griffin1Lander;
    private import Griffin1Requirements::HostedRoverInterface;
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
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
        in touchdownObserved : Boolean;
        in allFourLegsContact : Boolean;
        telemetryFinite and sampleAvailable and touchdownObserved and allFourLegsContact
            and minimumUprightAxisY >= minimumUprightAxisYLimit
            and maximumGroundSpeedMps <= maximumGroundSpeedLimitMps
            and maximumAngularSpeedRadPerSec <= maximumAngularSpeedLimitRadPerSec
            and maximumHorizontalDriftM <= maximumHorizontalDriftLimitM;
    }

    constraint def GR037_LandingTargetDatumMatchesSource {
        in authoredTargetY : Real;
        in sourceTargetY : Real;
        in toleranceM : Real;
        authoredTargetY >= sourceTargetY - toleranceM
            and authoredTargetY <= sourceTargetY + toleranceM;
    }

    constraint def GR038_LandingSurfaceContainsTargetOnTerrainPlane {
        in authoredPadTopY : Real;
        in sourceSurfaceY : Real;
        in padCenterX : Real;
        in padCenterZ : Real;
        in targetX : Real;
        in targetZ : Real;
        in actualPadHalfExtentX : Real;
        in actualPadHalfExtentZ : Real;
        in requiredPadHalfExtentM : Real;
        in actualPadThicknessM : Real;
        in requiredPadThicknessM : Real;
        in toleranceM : Real;
        authoredPadTopY >= sourceSurfaceY - toleranceM
            and authoredPadTopY <= sourceSurfaceY + toleranceM
            and actualPadHalfExtentX >= requiredPadHalfExtentM - toleranceM
            and actualPadHalfExtentX <= requiredPadHalfExtentM + toleranceM
            and actualPadHalfExtentZ >= requiredPadHalfExtentM - toleranceM
            and actualPadHalfExtentZ <= requiredPadHalfExtentM + toleranceM
            and actualPadThicknessM >= requiredPadThicknessM - toleranceM
            and actualPadThicknessM <= requiredPadThicknessM + toleranceM
            and targetX >= padCenterX - requiredPadHalfExtentM - toleranceM
            and targetX <= padCenterX + requiredPadHalfExtentM + toleranceM
            and targetZ >= padCenterZ - requiredPadHalfExtentM - toleranceM
            and targetZ <= padCenterZ + requiredPadHalfExtentM + toleranceM;
    }

    // Domain-owned requirement definitions. Griffin1Requirements owns only
    // the integrated system subject, requirement usages, and verification.

    requirement def GR008_AttitudeCases {
        doc /* GR-008 [verification] exercise nominal, high-pitch, uneven-roll, and combined pitch/roll egress cases; report inconclusive when contact data is unavailable. Source: Twin mission verification plan. Assumption: these four cases span the dominant attitude sensitivities of a two-track egress study; inconclusive is required when the runtime cannot observe contact. */
    }

    requirement def GR021_MassProperties {
        doc /* GR-021 [physics planned] every dynamic body has finite positive mass, center of mass, and inertia in its declared body frame. QueryUsdPrim can read authored mass-property fields; this requirement remains planned until each body's COM and inertia are sourced, composed, frame-checked, and verified against the model. The Griffin ramp's mass and diagonal inertia are now explicit replaceable Twin study proxies, not supplier data or acceptance evidence. Source: rigid-body physics contract. */
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
        doc /* GR-036 [simulation accuracy] beginning with detected touchdown, observe a full 60 s post-touchdown window at the source-owned fixed-tick cadence. At every available observation all four landing legs shall remain in contact and telemetry shall be finite; the lander upright-axis Y component shall remain at least 0.9393727128473789 (cosine of the 0.35 rad study tilt limit), horizontal ground speed shall not exceed 5.0 m/s, angular speed shall not exceed 2.0 rad/s, and horizontal drift from the touchdown position shall not exceed 50.0 m. These are replaceable Twin study limits, not supplier performance specifications. Missing physics samples are inconclusive. */
        attribute landingStabilityHorizonS : Real = 60.0;
        attribute landingStabilitySampleEveryNTicks : Integer = 10;
        attribute landingMinimumUprightAxisY : Real = 0.9393727128473789;
        attribute landingMaxGroundSpeedMps : Real = 5.0;
        attribute landingMaxAngularSpeedRadPerSec : Real = 2.0;
        attribute landingMaxHorizontalDriftM : Real = 50.0;
        require GR036_LandingStabilityWithinBounds {
            in minimumUprightAxisYLimit = landingMinimumUprightAxisY;
            in maximumGroundSpeedLimitMps = landingMaxGroundSpeedMps;
            in maximumAngularSpeedLimitRadPerSec = landingMaxAngularSpeedRadPerSec;
            in maximumHorizontalDriftLimitM = landingMaxHorizontalDriftM;
        }
    }

    requirement def GR037_LandingTargetDatum {
        doc /* GR-037 [simulation setup] the mission's authored landing-target Y datum shall agree with the SysML vehicle-reference touchdown datum within the source-owned tolerance before descent starts. This is a setup consistency check, not evidence that the vehicle has landed or that the touchdown dynamics are accurate. */
        attribute landingTargetDatumToleranceM : Real = 0.001;
        require GR037_LandingTargetDatumMatchesSource;
    }

    requirement def GR038_LandingSurfaceDatum {
        doc /* GR-038 [simulation setup] the collision pad top shall be continuous with the normalized terrain surface, and the landing target shall lie within the pad footprint. This setup check does not substitute for native four-leg contact or touchdown stability evidence. */
        attribute landingSurfaceDatumToleranceM : Real = 0.001;
        require GR038_LandingSurfaceContainsTargetOnTerrainPlane;
    }


    // System integration requirement usages owned by this domain.
    requirement <'GR-008'> gr008 : GR008_AttitudeCases { subject rover : HostedRoverInterface; }
    requirement <'GR-021'> gr021 : GR021_MassProperties { subject lander : Griffin1Lander; }
    requirement <'GR-022'> gr022 : GR022_SupportPolygon { subject lander : Griffin1Lander; }
    requirement <'GR-023'> gr023 : GR023_ContactContinuity { subject lander : Griffin1Lander; }
    requirement <'GR-027'> gr027 : GR027_PropulsionAlignment { subject lander : Griffin1Lander; }
    requirement <'GR-031'> gr031 : GR031_DeterministicVerdict { subject rover : HostedRoverInterface; }
    requirement <'GR-036'> gr036 : GR036_LandingStability { subject lander : Griffin1Lander; }
    requirement <'GR-037'> gr037 : GR037_LandingTargetDatum { subject lander : Griffin1Lander; }
    requirement <'GR-038'> gr038 : GR038_LandingSurfaceDatum { subject lander : Griffin1Lander; }


    verification def Verify_GriffinLandingStability {
        subject lander : Griffin1Lander;
        objective {
            verify gr036;
        }
    }

    verification def Verify_GriffinLandingTargetDatum {
        subject lander : Griffin1Lander;
        objective {
            verify gr037;
        }
    }

    verification def Verify_GriffinLandingSurfaceDatum {
        subject lander : Griffin1Lander;
        objective {
            verify gr038;
        }
    }

}
