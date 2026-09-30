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

    constraint def GR039_GuidanceAssemblyMassMatchesPhysics {
        in solverMassKg : Real;
        in guidanceMassKg : Real;
        in solverMassValid : Boolean;
        in guidanceMassValid : Boolean;
        in toleranceKg : Real;
        solverMassValid and guidanceMassValid
            and solverMassKg > 0.0 and guidanceMassKg > 0.0
            and guidanceMassKg >= solverMassKg - toleranceKg
            and guidanceMassKg <= solverMassKg + toleranceKg;
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
        doc /* GR-036 [simulation accuracy] beginning with detected touchdown, observe the source-owned post-touchdown horizon at the source-owned fixed-tick cadence. At every available observation all four landing legs shall remain in contact and telemetry shall be finite; upright attitude, horizontal speed, angular speed and drift shall remain within the typed bounds below. These are replaceable Twin screening limits, not supplier performance specifications or mission-level landing-stability acceptance. Missing physics samples are inconclusive. */
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


    requirement def GR039_GuidanceUsesDynamicJointIslandMass {
        doc /* GR-039 [flight dynamics] before descent guidance may command thrust, its vehicle_mass input shall equal the current finite positive mass of every dynamic rigid body in the lander's active joint island, within guidanceAssemblyMassToleranceKg. Guidance authority shall remain inhibited while that complete solver measurement is invalid. This preserves the force-to-acceleration balance for the actual articulated vehicle; it never substitutes the lander hull mass or a nominal fallback. Source: Newton's second law and LunCoSim dynamic joint-island mass contract. Assumption: the authored active dynamic-joint island is the controlled vehicle assembly; static and kinematic anchors are excluded. */
        attribute guidanceAssemblyMassToleranceKg : Real = 0.001;
        require GR039_GuidanceAssemblyMassMatchesPhysics {
            in toleranceKg = guidanceAssemblyMassToleranceKg;
        }
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
    requirement <'GR-039'> gr039 : GR039_GuidanceUsesDynamicJointIslandMass { subject lander : Griffin1Lander; }


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
