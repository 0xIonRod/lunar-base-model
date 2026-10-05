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

    constraint def GR038_LandingTerrainDatum {
        in measuredTerrainY : Real;
        in sourceTerrainY : Real;
        in surfaceAvailable : Boolean;
        in toleranceM : Real;
        surfaceAvailable and measuredTerrainY >= sourceTerrainY - toleranceM
            and measuredTerrainY <= sourceTerrainY + toleranceM;
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
        doc /* GR-031 [test] the production Twin test emits a deterministic verdict with fixed tick rate, threads, and jitter, including inconclusive runtime states. Source: LunCoSim deterministic test runner contract. Rationale: fixed execution settings make regressions reproducible and prevent missing observations from being mistaken for PASS. Fresh load and same-process reload of the same saved source shall admit the same USD bodies, joints, visible geometry and Modelica state before the first physics tick. Referenced layer revisions belong to this invariant; resetting only root-scene state is insufficient. Source: user acceptance requirement and owned 2026-10-03 warm/cold Griffin review reproduction, where the warm process retained the removed shock-body paths and stalled admission but the cold process resolved the current axial mechanism. Camera/render readiness is separate from geometry PASS; an inactive window camera is not rendered evidence. Compound colliders shall exclude deactivated prims and their descendants, including inactive proxies; viewport invisibility alone is not a collision filter. Pose refresh shall preserve the seated native quaternion hemisphere because q and -q represent one attitude but Avian 0.7 XPBD fixed-angle feedback is sign-sensitive. Rationale/source: owned 2026-10-05 first-step isolation on APIs 49827-49829 and same-process cooked bounds capture showed the rover growing from 2.168 m to 6.2 m because the deactivated reusable solar-panel frame entered its compound; the native inactive-geometry and sign-changing-pose regressions reproduce these mechanisms. These are simulator consistency requirements, not measurements of flight hardware. Retained Rhai programs shall wait for incoming scene readiness before rebinding their Modelica dependency plan; keeping VM state does not preserve outgoing participant references. Source/rationale: owned 2026-10-05 rendered reload API 49832 stopped a retained observer because its dependency plan was validated before the replacement Modelica participants existed. The native lifecycle regression fails before the readiness gate and passes after it; all 30 scripting tests pass. Owned production API 49833 then passes the unmodified strict two-run 90 s replay at 94 samples, including exact thrust and throttle, and the full 16-gate surface mission. These are same-host simulator consistency observations, not spacecraft measurements. USD contact-pair endpoint roles shall follow stable composed source identity before narrow phase creates oriented manifolds and caches; the graph edge and contact pair shall agree on collider and body roles. Source/rationale: owned 2026-10-05 full native traces match through tick 2362, then the two fresh processes discover ramp-to-toe contacts in opposite endpoint orders at tick 2363. The initial rounding difference grows to a 0.000257979 m final X difference. A native 40-step contact-trajectory regression fails without canonical endpoint roles and passes with them; all nine bridge tests pass. Ordering retains the same colliders, forces and contact constraints; no trajectory rounding or tolerance change is allowed. This rule covers authored USD collider pairs; native/generated collider identities remain owned by their backend. Surface gravity for an admitted rigid body shall use native double-precision Position in the active physics frame, with the provider expressed in that same frame through common-ancestor composition. Render interpolation, f32 Transform writeback and astronomical ancestors above the common frame shall not change the local force. Source/rationale: owned High rendered API 49834 diverged at replay tick 300 in exact thrust by about 0.000740 N despite only nanometre-scale pose differences. The native gravity regression deliberately separates physics and render poses and changes the astronomical ancestor; it fails with the world/render-pose calculation and passes with native relative-frame evaluation. All 15 environment tests pass. Owned High rendered API 49835 then passes the unmodified two-run 90 s replay at 94 samples, including exact thrust and throttle. The source-pinned fresh-process pair also has exactly zero final position, upright, ground-speed and angular-speed deltas, with all four pads in 361 of 361 samples per run. These are same-mode simulator consistency observations; the renderer and headless executor are separately verified. Fresh-process, retained headless replay and rendered replay are separate acceptance runs. Replay includes admission and the first three solver steps, cooked rover bounds, continuous trajectory limits and exact touchdown/handoff states; a mission PASS does not replace the strict replay verdict. */
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
        doc /* GR-037 [simulation setup] the mission's authored landing-target Y datum shall agree with the sum of the DEM height and the SysML vehicle-reference touchdown height above support within the source-owned tolerance before descent starts. This is a setup consistency check, not evidence that the vehicle has landed or that the touchdown dynamics are accurate. */
        attribute landingTargetDatumToleranceM : Real = 0.001;
        require GR037_LandingTargetDatumMatchesSource;
    }

    requirement def GR038_LandingSurfaceDatum {
        doc /* GR-038 [simulation setup] the source-backed DEM shall provide a finite support height at the landing target; that height shall agree with the pinned study anchor datum. Artificial landing slabs are excluded from the production scene. The measured DEM height is added to the vehicle-reference height for target placement. Source: processed LROC NOBILE03 crop sampled through TerrainHeight on 2026-10-04. This setup check does not substitute for native four-leg contact or touchdown stability evidence. */
        attribute landingSurfaceDatumToleranceM : Real = 0.001;
        require GR038_LandingTerrainDatum;
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
