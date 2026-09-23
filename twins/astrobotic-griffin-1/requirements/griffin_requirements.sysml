package Griffin1Requirements {
    // Requirement definitions are grouped by engineering domain; this package
    // owns the Griffin integration subject, requirement usages, and verification.
    private import GriffinFunctionalRequirements::GR001_LanderArchitecture;
    private import GriffinFunctionalRequirements::GR002_PayloadAdapter;
    private import GriffinFunctionalRequirements::GR003_DeployableRamps;
    private import GriffinFunctionalRequirements::GR004_SurfaceSequence;
    private import GriffinFunctionalRequirements::GR006_SolarAssemblies;
    private import GriffinFunctionalRequirements::GR007_GatedEgress;
    private import GriffinFunctionalRequirements::GR009_PayloadCapacity;
    private import GriffinFunctionalRequirements::GR026_AdapterRelease;
    private import GriffinFunctionalRequirements::GR028_InterfaceResolution;
    private import GriffinFunctionalRequirements::GR034_SurfaceRouteDatums;
    private import GriffinFunctionalRequirements::GR035_EgressApronContact;
    private import GriffinVisualRequirements::GR015_NozzleGeometry;
    private import GriffinVisualRequirements::GR016_SolarSymmetry;
    private import GriffinVisualRequirements::GR020_ProxySuppression;
    private import GriffinVisualRequirements::GR032_MainEngineBells;
    private import GriffinVisualRequirements::GR033_PropellantTanks;
    private import GriffinVisualRequirements::GRV001_PresentationFrame;
    private import GriffinVisualRequirements::GRV002_LanderPresentation;
    private import GriffinVisualRequirements::GRV003_GriffinSolarAssemblies;
    private import GriffinVisualRequirements::GRV004_ScaleDatums;
    private import GriffinVisualRequirements::GRV005_RenderOwnership;
    private import GriffinVisualRequirements::GRV006_LunarContext;
    private import GriffinVisualRequirements::GRV007_VisualEvidence;
    private import GriffinMechanicalRequirements::GR010_FunctionalLegs;
    private import GriffinMechanicalRequirements::GR011_RampBodies;
    private import GriffinMechanicalRequirements::GR012_LoadBearingMass;
    private import GriffinMechanicalRequirements::GR017_RampSymmetry;
    private import GriffinMechanicalRequirements::GR018_HullAndDeck;
    private import GriffinMechanicalRequirements::GR019_LegPlacement;
    private import GriffinMechanicalRequirements::GR024_HingeFrames;
    private import GriffinMechanicalRequirements::GR025_SolarClearance;
    private import GriffinSimulationAccuracyRequirements::GR008_AttitudeCases;
    private import GriffinSimulationAccuracyRequirements::GR021_MassProperties;
    private import GriffinSimulationAccuracyRequirements::GR022_SupportPolygon;
    private import GriffinSimulationAccuracyRequirements::GR023_ContactContinuity;
    private import GriffinSimulationAccuracyRequirements::GR027_PropulsionAlignment;
    private import GriffinSimulationAccuracyRequirements::GR031_DeterministicVerdict;
    private import GriffinSimulationAccuracyRequirements::GR036_LandingStability;
    private import GriffinAssuranceRequirements::GR005_TraceableValues;
    private import GriffinAssuranceRequirements::GR013_ParameterProvenance;
    private import GriffinAssuranceRequirements::GR014_TypedAuthoring;
    private import GriffinAssuranceRequirements::GR029_PartProvenance;
    private import GriffinAssuranceRequirements::GR030_EvidenceGate;
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import ScalarValues::String;
    private import ScalarValues::Boolean;


    // Source-backed mission facts are kept separate from study values. These
    // scalar fields are exposed by the generic SysML/Rhai bridge.
    part def PublicMissionContext {
        attribute missionName : String = "Astrobotic Griffin Mission One / NASA Moon Base II";
        attribute landingRegion : String = "Nobile Region, lunar South Pole";
        attribute cargoStatement : String = "more than 499 kg of cargo (metric conversion of the public NASA lower bound)";
        attribute primaryRover : String = "Astrolab FLIP (FLEX Lunar Innovation Platform)";
        attribute griffinProductSource : String = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute nasaMissionSource : String = "https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/";
        attribute nasaLanderFactsSource : String = "https://science.nasa.gov/wp-content/uploads/2023/11/astrobotic-lunar-landers-pug.pdf";
        attribute astroboticMissionManifestSource : String = "https://www.astrobotic.com/lunar-delivery/manifest/";
        attribute griffinPressReference : String = "https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/";
        attribute flipProductSource : String = "https://www.astrobotic.com/astrolabs-flip-rover-joins-astrobotics-griffin-1-to-the-moon/";
        attribute flipEgressSource : String = "https://www.astrolab.space/2026/05/18/astrolab-announces-nasa-payloads-for-upcoming-mission-to-the-moon/";
        attribute tankSource : String = "https://www.astrobotic.com/griffin-1-mission-update/";
        attribute requirementUsageCount : Integer = 36;
        attribute verificationCaseName : String = "Griffin1Requirements::Verify_GriffinRequirements";
        attribute frameUnits : String = "metres";
        attribute frameRootDatum : String = "Griffin1";
        // Geometry-derived COM target for the vertical landing study.  The
        // inline pad/compound colliders settle at this composed contact datum
        // above the authored 0.35 m pad surface; keep the value in SysML so
        // the scene and Rhai checks share one source of truth.
        attribute landingComTouchdownY : Real = 3.98;
        // Landing-stability limits are owned by GR036 in the simulation
        // accuracy package; this integration context does not mirror them.
        attribute landingDivergenceToleranceM : Real = 0.50;
        attribute landingDivergenceToleranceUpright : Real = 0.02;
        attribute landingDivergenceToleranceSpeedMps : Real = 0.50;
        // Replay tolerances are distinct from engineering acceptance bounds.
        // With the deterministic single-thread profile, two fresh processes
        // must reproduce the same state to numerical round-off; the broader
        // divergence limits above describe acceptable physical envelopes, not
        // permission to hide an admission-order bug.
        attribute landingReplayToleranceM : Real = 1.0e-6;
        attribute landingReplayToleranceUpright : Real = 1.0e-7;
        attribute landingReplayToleranceSpeedMps : Real = 1.0e-6;
        attribute landingReplayToleranceTimeS : Real = 1.0e-9;
        // Mission watchdogs are explicit study policy, not hidden Rhai timing
        // literals. They bound a missing physical event and must never turn
        // into a PASS by themselves.
        attribute landingPhaseTimeoutS : Real = 300.0;
        attribute roverSettleTimeoutS : Real = 30.0;
        // FLIP is released from the top-deck adapter and must fall/roll to
        // the authored surface before wheel torque is enabled.  This is a
        // conservative upper bound for the rover's settled body centre,
        // derived from the metre-scale wheel radius and the normalized pad
        // datum; accepting deck height here would start route control while
        // the rover is airborne and create an artificial attitude impulse.
        attribute roverSettleHeightLimitM : Real = 2.00;
        attribute roverSettleSpeedLimitMps : Real = 0.25;
        attribute surfaceRouteTimeoutS : Real = 900.0;
        // A route that has no measurable horizontal progress is a physical
        // integration fault (usually contact/steering geometry), not a reason
        // to keep evaluating the same control law until the mission timeout.
        attribute surfaceRouteStallTimeoutS : Real = 15.0;
        // Visual review contract.  These are intentionally small, stable
        // presentation datums, not a hidden CAD model: the Twin graphics test
        // reads them and compares them with composed USD geometry.
        attribute visualRequirementUsageCount : Integer = 7;
        attribute visualVerificationCaseName : String = "GriffinVisualRequirements::Verify_GriffinVisualRequirements";
        attribute visualCameraName : String = "VisualCamera";
        attribute visualLanderName : String = "Griffin1";
        attribute visualLanderDeckWidthM : Real = 4.50;
        attribute visualLandingPadRadiusM : Real = 6.0;
        attribute visualReviewGroundWidthM : Real = 36.0;
        attribute visualTerrainAsset : String = "twin://astrobotic-griffin-1/environments/south_pole_surrogate.usda";
        attribute visualTerrainShaderAsset : String = "lunco://shaders/terrain_layered.wgsl";
        attribute visualRenderOwnership : String = "render-only review layer; physics colliders remain authored by vehicle components";
        attribute manifestPartCount : Integer = 20;
        // Reusable assembly identities are source data as well. Rhai derives
        // paths and pair checks from these names instead of carrying a second
        // list of Griffin topology constants.
        attribute solarArrayNames : String[2] = ("SolarPanelPort", "SolarPanelStarboard");
        attribute landingLegNames : String[4] = ("LegPX", "LegNX", "LegPZ", "LegNZ");
        attribute landingPadNames : String[4] = ("PadPX", "PadNX", "PadPZ", "PadNZ");
        attribute rampNames : String[2] = ("EgressRampPort", "EgressRampStarboard");
        attribute rampHingeNames : String[2] = ("RampHingePort", "RampHingeStarboard");
        attribute mainEngineNames : String[7] = ("Engine01", "Engine02", "Engine03", "Engine04", "Engine05", "Engine06", "Engine07");
        // Route markers are mission-interface datums, not navigation-code
        // constants.  Keep the complete marker table in SysML so the scene
        // can be regenerated through the typed Editor bridge without a
        // second literal table in Rhai or a hand-edited USDA file.
        attribute surfaceRouteMarkerNames : String[15] = ("RoverRampApproach", "RoverRampExit", "RoverTarget1", "RoverTransit1", "RoverTransit2", "RoverTransit3", "RoverTransit4", "RoverTransit5", "RoverTransit6", "RoverTarget2", "RoverBaseArc1", "RoverBaseArc2", "RoverBaseApproach", "RoverBaseFinal", "BaseSite");
        // The approach marker is the rover-centre datum before the
        // 3.20 m ramp hinge. The separate 1.05 m transition bridges the
        // 2.20 m adapter half-width and includes 0.05 m contact overlap.
        // With FLIP's roughly 1.2 m forward half-envelope, x=2.00 m brings
        // the front wheels onto the transition without
        // placing the route target itself on the moving ramp body. The
        // deployed ramp tip is near x=8.76 m, but the released rover's
        // measured two-wheel ground-transition pose is approximately
        // (11.03, -0.13) m in the x/z route plane. Put the exit gate at
        // (12.00, 0.00) m so the rover continues on the ramp centreline until
        // its trailing axle clears the ramp instead of steering laterally
        // toward a marker that is still inside the transition. The first
        // first survey transit was moved from z=2.00 m to z=1.00 m after
        // runtime evidence showed FLIP stalled 1.83 m from the old marker
        // with one support ray outside the 1.20 m envelope. This keeps the
        // first post-egress turn inside the measured supported lane; it is
        // an operational route assumption, not supplier data.
        attribute surfaceRouteMarkerX : Real[15] = (2.00, 12.00, 16.00, 19.00, 21.00, 22.50, 23.70, 24.60, 25.20, 25.40, 25.80, 26.70, 28.00, 29.50, 31.00);
        // Route navigation is authored in the terrain x/z plane.  The first
        // marker used to carry the 6.92 m deck-height value in Y, but the
        // rover guidance contract intentionally ignores Y and therefore
        // interpreted that datum as (3.20, 0.00).  Keep all surface markers
        // on the terrain plane so the SysML datum and the visible marker
        // agree; deck height belongs to the ramp/lander interface, not this
        // horizontal route table.
    attribute surfaceRouteMarkerY : Real[15] = (0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00);
    attribute surfaceRouteMarkerZ : Real[15] = (0.00, 0.00, 0.00, 1.00, 0.50, 0.20, -0.30, -1.20, -2.30, -3.60, -4.90, -6.10, -7.20, -8.50, -10.00);
        // Route commands are part of the mission interface, not controller
        // implementation constants. The first radius is a 0.35 m approach
        // lane around the centerline and must reach the composed deck-to-ramp
        // transition. The 1.05 m transition datum is derived from the
        // 2.20 m payload-deck half-width, 3.20 m hinge station, and 0.05 m
        // contact overlap; it remains a study value until composed contact
        // measurements are exposed. The second radius remains 0.30 m at the forward
        // (12.00,0.00) exit gate, after the trailing axle clears the ramp;
        // its forward centreline placement avoids asking Ackermann guidance
        // to reverse toward a lateral marker during the transition. The later diagonal legs deliberately reduce
        // speed to 0.18..0.14 m/s because the shared Ackermann law must turn
        // through the bounded corner sequence without overshooting a survey
        // marker; these are measured study-vehicle limits, not supplier data.
        attribute surfaceRouteSpeedMps : Real[15] = (0.22, 0.22, 0.35, 0.35, 0.35, 0.22, 0.20, 0.18, 0.16, 0.14, 0.14, 0.15, 0.18, 0.20, 0.22);
        // RoverTarget2 is the first survey gate on the finite-turn arc. The
        // deterministic replay crossed its centerline at 1.05 m while all
        // four wheels remained supported; 1.20 m accepts that measured
        // low-speed path without widening the ramp approach/exit gates.
        attribute surfaceRouteArrivalRadiusM : Real[15] = (0.35, 0.30, 1.20, 1.20, 1.20, 1.00, 1.00, 1.00, 1.00, 1.20, 1.00, 1.00, 1.00, 1.00, 1.20);
        // The physical 8.00 m ramp ends at about x=11.20 m, while the
        // original 12.00 m exit gate is outside the 12 m landing pad.  This
        // named apron is a small prepared transition surface, not a hidden
        // teleport or terrain override: it overlaps the ramp tip and gives
        // all four wheels a continuous collision plane before survey route
        // control begins.  Its dimensions are replaceable Twin study values
        // until the Griffin site ICD is available.
        attribute egressApronName : String = "EgressApron";
        attribute egressApronRequirementId : String = "GR-035";
        attribute egressApronCenterX : Real = 13.50;
        attribute egressApronCenterY : Real = -0.05;
        attribute egressApronCenterZ : Real = -1.00;
        attribute egressApronLengthM : Real = 10.00;
        attribute egressApronWidthM : Real = 8.00;
        attribute egressApronThicknessM : Real = 0.10;
        attribute egressApronSurfaceY : Real = 0.00;
        attribute egressApronSource : String = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/; twin://astrobotic-griffin-1/scenes/griffin_1_surface_ops.usda";
        attribute egressApronRationale : String = "The public Griffin material establishes the lander and optional egress context but does not publish a site-apron ICD. The apron is therefore an explicit, replaceable Twin study assumption sized to overlap the 8.00 m ramp tip at x=11.20 m and extend beyond the 12.00 m exit gate. Its top y=0.00 m matches the normalized ramp-tip terrain datum; the route keeps the exit gate on the ramp centreline so FLIP is not forced into a lateral steering reversal before the trailing axle clears the transition.";
    attribute cataloguedRequirementCheckIds : String[22] = ("GR-001", "GR-002", "GR-003", "GR-005", "GR-006", "GR-009", "GR-010", "GR-011", "GR-012", "GR-013", "GR-015", "GR-016", "GR-017", "GR-018", "GR-019", "GR-020", "GR-029", "GR-032", "GR-033", "GR-034", "GR-035", "GR-036");
        attribute plannedRequirementIds : String[11] = ("GR-004", "GR-007", "GR-008", "GR-014", "GR-021", "GR-022", "GR-023", "GR-024", "GR-025", "GR-027", "GR-028");
        attribute missionScopeRequirementIds : String[1] = ("GR-026");
        attribute processGateRequirementIds : String[2] = ("GR-030", "GR-031");
    }

    part def Griffin1Lander {
        // Public product/mission values.
        attribute payloadCapacityKg : Real = 625.0;
        attribute landingLegCount : Integer = 4;
        attribute mainEngineCount : Integer = 7;
        attribute propellantTankCount : Integer = 4;
        attribute solarArrayCount : Integer = 2;
        // Mechanical ICD values remain explicit study inputs until supplied.
        attribute geometryStatus : String = "study surrogate; Griffin ICD TBD";
        attribute massPropertiesStatus : String = "inherited simulator proxy; as-built data TBD";
        attribute rampStatus : String = "optional Griffin egress hardware; mechanism ICD TBD";
        attribute solarArrayStatus : String = "visual/power study proxy; flight layout TBD";
    }

    // Generic integration subject.  Rover-owned values and rover visual
    // requirements live in requirements/flip_requirements.sysml; Griffin only
    // verifies that a hosted vehicle interface exists at the release boundary.
    part def HostedRoverInterface {
        attribute interfaceName : String = "hosted rover interface";
    }











































    verification def Verify_GriffinRequirements {
        subject lander : Griffin1Lander;
        subject rover : HostedRoverInterface;
        objective {
            verify GriffinFunctionalRequirements::gr001;
            verify GriffinFunctionalRequirements::gr002;
            verify GriffinFunctionalRequirements::gr003;
            verify GriffinFunctionalRequirements::gr004;
            verify GriffinAssuranceRequirements::gr005;
            verify GriffinFunctionalRequirements::gr006;
            verify GriffinFunctionalRequirements::gr007;
            verify GriffinSimulationAccuracyRequirements::gr008;
            verify GriffinFunctionalRequirements::gr009;
            verify GriffinMechanicalRequirements::gr010;
            verify GriffinMechanicalRequirements::gr011;
            verify GriffinMechanicalRequirements::gr012;
            verify GriffinAssuranceRequirements::gr013;
            verify GriffinAssuranceRequirements::gr014;
            verify GriffinVisualRequirements::gr015;
            verify GriffinVisualRequirements::gr016;
            verify GriffinMechanicalRequirements::gr017;
            verify GriffinMechanicalRequirements::gr018;
            verify GriffinMechanicalRequirements::gr019;
            verify GriffinVisualRequirements::gr020;
            verify GriffinSimulationAccuracyRequirements::gr021;
            verify GriffinSimulationAccuracyRequirements::gr022;
            verify GriffinSimulationAccuracyRequirements::gr023;
            verify GriffinMechanicalRequirements::gr024;
            verify GriffinMechanicalRequirements::gr025;
            verify GriffinFunctionalRequirements::gr026;
            verify GriffinSimulationAccuracyRequirements::gr027;
            verify GriffinFunctionalRequirements::gr028;
            verify GriffinAssuranceRequirements::gr029;
            verify GriffinAssuranceRequirements::gr030;
            verify GriffinSimulationAccuracyRequirements::gr031;
            verify GriffinVisualRequirements::gr032;
            verify GriffinVisualRequirements::gr033;
            verify GriffinFunctionalRequirements::gr034;
            verify GriffinFunctionalRequirements::gr035;
            verify GriffinSimulationAccuracyRequirements::gr036;
        }
    }


    verification def Verify_GriffinSurfaceOperations {
        subject lander : Griffin1Lander;
        subject rover : HostedRoverInterface;
        objective {
            verify GriffinFunctionalRequirements::gr004;
            verify GriffinFunctionalRequirements::gr007;
            verify GriffinFunctionalRequirements::gr026;
        }
    }


}
