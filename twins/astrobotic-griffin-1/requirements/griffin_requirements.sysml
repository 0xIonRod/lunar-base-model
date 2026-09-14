package Griffin1Requirements {
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
        attribute requirementUsageCount : Integer = 33;
        attribute verificationCaseName : String = "Griffin1Requirements::Verify_GriffinRequirements";
        attribute frameUnits : String = "metres";
        attribute frameRootDatum : String = "Griffin1";
        // Geometry-derived COM target for the vertical landing study.  The
        // inline pad/compound colliders settle at this composed contact datum
        // above the authored 0.35 m pad surface; keep the value in SysML so
        // the scene and Rhai checks share one source of truth.
        attribute landingComTouchdownY : Real = 3.98;
        // Landing-stability acceptance datums are explicit study limits.
        // Rhai reads these values through the generic SysML snapshot; the
        // runner contributes no Griffin-specific thresholds.
    attribute landingStabilityHorizonS : Real = 60.0;
        attribute landingMaxTiltRad : Real = 0.35;
        attribute landingMaxGroundSpeedMps : Real = 5.0;
        attribute landingMaxAngularSpeedRadPerSec : Real = 2.0;
        attribute landingMaxHorizontalDriftM : Real = 50.0;
        attribute landingDivergenceToleranceM : Real = 0.50;
        attribute landingDivergenceToleranceUpright : Real = 0.02;
        attribute landingDivergenceToleranceSpeedMps : Real = 0.50;
        // Visual review contract.  These are intentionally small, stable
        // presentation datums, not a hidden CAD model: the Twin graphics test
        // reads them and compares them with composed USD geometry.
        attribute visualRequirementUsageCount : Integer = 7;
        attribute visualVerificationCaseName : String = "Griffin1Requirements::Verify_GriffinVisualRequirements";
        attribute visualCameraName : String = "VisualCamera";
        attribute visualLanderName : String = "Griffin1";
        attribute visualLanderDeckWidthM : Real = 5.20;
        attribute visualLandingPadRadiusM : Real = 6.0;
        attribute visualReviewGroundWidthM : Real = 36.0;
        attribute visualRenderOwnership : String = "render-only review layer; physics colliders remain authored by vehicle components";
        attribute manifestPartCount : Integer = 20;
        attribute canonicalPartNames : String = "BoxyAirframe,IsogridDeck,PayloadAdapter,MainPropulsion,Nozzle,SolarPanelPort,SolarPanelStarboard,LegPX,LegNX,LegPZ,LegNZ,EgressRampPort,EgressRampStarboard,PropellantTanks,EngineCluster";
        // Reusable assembly identities are source data as well. Rhai derives
        // paths and pair checks from these names instead of carrying a second
        // list of Griffin topology constants.
        attribute solarArrayNames : String = "SolarPanelPort,SolarPanelStarboard";
        attribute landingLegNames : String = "LegPX,LegNX,LegPZ,LegNZ";
        attribute landingPadNames : String = "PadPX,PadNX,PadPZ,PadNZ";
        attribute rampNames : String = "EgressRampPort,EgressRampStarboard";
        attribute rampHingeNames : String = "RampHingePort,RampHingeStarboard";
        attribute propellantTankNames : String = "TankPX,TankNX,TankPZ,TankNZ";
        attribute mainEngineNames : String = "Engine01,Engine02,Engine03,Engine04,Engine05,Engine06,Engine07";
        attribute executableRequirementIds : String = "GR-001,GR-002,GR-003,GR-005,GR-006,GR-009,GR-010,GR-011,GR-012,GR-013,GR-015,GR-016,GR-017,GR-018,GR-019,GR-020,GR-029,GR-032,GR-033";
        attribute plannedRequirementIds : String = "GR-004,GR-007,GR-008,GR-014,GR-021,GR-022,GR-023,GR-024,GR-025,GR-027,GR-028";
        attribute missionScopeRequirementIds : String = "GR-026";
        attribute processGateRequirementIds : String = "GR-030";
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

    requirement def GR001_LanderArchitecture {
        doc /* GR-001 [public+study] model a reusable Griffin body, four legs, and an isogrid payload deck; verify named USD topology. Source: Astrobotic Griffin product page. */
    }

    requirement def GR002_PayloadAdapter {
        doc /* GR-002 [integration] provide an explicit payload-adapter datum that holds FLIP before the release gate; verify the fixed-joint interface in composed USD. */
    }

    requirement def GR003_DeployableRamps {
        doc /* GR-003 [public optional hardware] model two optional Griffin side ramps with contact surfaces and inspectable hinges; do not treat ramps as a mandatory FLIP interface. Source: Astrobotic Griffin product page. */
    }

    requirement def GR004_SurfaceSequence {
        doc /* GR-004 [mission flow] preserve landing/settle, egress-path preparation, adapter release, FLIP egress, and route order; verify with a Twin Rhai scenario. */
    }

    requirement def GR005_TraceableValues {
        doc /* GR-005 [traceability] every value is labelled public fact, project requirement, study proxy, or TBD with a source or rationale. */
    }

    requirement def GR006_SolarAssemblies {
        doc /* GR-006 [subsystem] represent Griffin arrays and FLIP's collapsible-array concept as named visual/power subassemblies; verify deployment state is not silently assumed. */
    }

    requirement def GR007_GatedEgress {
        doc /* GR-007 [runtime] egress shall be a physical direct-deck or optional-ramp path with wheel/contact evidence, never a teleport from deck to terrain. */
    }

    requirement def GR008_AttitudeCases {
        doc /* GR-008 [verification] exercise nominal, high-pitch, uneven-roll, and combined pitch/roll egress cases; report inconclusive when contact data is unavailable. */
    }

    requirement def GR009_PayloadCapacity {
        doc /* GR-009 [public product value] Griffin payload capacity is 625 kg; accept the boundary and reject loads above it. Source: Astrobotic Griffin product page. */
    }

    requirement def GR010_FunctionalLegs {
        doc /* GR-010 [public product value] retain exactly four visible functional landing-leg bodies with struts and pad colliders. Source: Astrobotic Griffin product page. */
    }

    requirement def GR011_RampBodies {
        doc /* GR-011 [study control] retain two side-ramp bodies with contact geometry and revolute hinges; the command bound is a proxy, not a released mechanical limit. */
    }

    requirement def GR012_LoadBearingMass {
        doc /* GR-012 [physics] every load-bearing subassembly has positive mass and explicit collision ownership; compound-body admission is a runtime gate. */
    }

    requirement def GR013_ParameterProvenance {
        doc /* GR-013 [traceability] status and provenance metadata are required for every study parameter and every inherited surrogate. */
    }

    requirement def GR014_TypedAuthoring {
        doc /* GR-014 [process] model edits use the typed USD path and rerun the Twin contract before save; filesystem rewrites are not acceptance evidence. */
    }

    requirement def GR015_NozzleGeometry {
        doc /* GR-015 [visual+physics] each named lander part resolves to geometry and the nozzle owns visible bell geometry that is not a collider. */
    }

    requirement def GR016_SolarSymmetry {
        doc /* GR-016 [layout] keep exactly two named Griffin solar-array owners on signed sides with mirrored placement and owned cell geometry. */
    }

    requirement def GR017_RampSymmetry {
        doc /* GR-017 [layout] optional ramps mirror in side placement, hinge rotation, and angle metadata when the ramp branch is selected. */
    }

    requirement def GR018_HullAndDeck {
        doc /* GR-018 [visual+physics] keep a positive collidable Y-axis hull and a positive upper deck above it; exact flight dimensions remain TBD. */
    }

    requirement def GR019_LegPlacement {
        doc /* GR-019 [layout] mount four legs on signed horizontal body axes with mirrored pads and a documented local frame. */
    }

    requirement def GR020_ProxySuppression {
        doc /* GR-020 [visual ownership] suppress inherited comparison geometry when a named part owns the visible representation; hidden duplicates do not count as removal. */
    }

    requirement def GR021_MassProperties {
        doc /* GR-021 [physics planned] every dynamic body has finite positive mass, center of mass, and inertia; report planned until the generic query exposes all fields. */
    }

    requirement def GR022_SupportPolygon {
        doc /* GR-022 [physics planned] at touchdown, the projected center of mass lies inside the leg support polygon with a documented margin. */
    }

    requirement def GR023_ContactContinuity {
        doc /* GR-023 [physics planned] pad and selected egress-path contact planes remain continuous and non-penetrating over the tested terrain crop. */
    }

    requirement def GR024_HingeFrames {
        doc /* GR-024 [physics planned] selected ramp hinge frames, axes, limits, and body ownership agree with the authored pose. */
    }

    requirement def GR025_SolarClearance {
        doc /* GR-025 [layout planned] arrays have clearance from bodies and each other in both stowed and deployed study states. */
    }

    requirement def GR026_AdapterRelease {
        doc /* GR-026 [runtime] adapter release leaves no stale joint or pre-release route ownership and transfers FLIP control exactly once. */
    }

    requirement def GR027_PropulsionAlignment {
        doc /* GR-027 [visual+physics planned] nozzle and flame align with the thrust axis and plume geometry remains visual-only. */
    }

    requirement def GR028_InterfaceResolution {
        doc /* GR-028 [integration planned] electrical, thermal, propulsion, guidance, and mobility interface names resolve without silent defaults. */
    }

    requirement def GR029_PartProvenance {
        doc /* GR-029 [traceability] every canonical part records source/provenance and known, proxy, or TBD parameter status. */
    }

    requirement def GR030_EvidenceGate {
        doc /* GR-030 [evidence] changed geometry groups require fresh headful visual evidence plus composed query output from the same document generation. */
    }

    requirement def GR031_DeterministicVerdict {
        doc /* GR-031 [test] the production Twin test emits a deterministic verdict with fixed tick rate, threads, and jitter, including inconclusive runtime states. */
    }

    requirement def GR032_MainEngineBells {
        doc /* GR-032 [public product value] model exactly seven visible, non-colliding main-engine bell geometries. Source: Astrobotic Griffin product page. */
    }

    requirement def GR033_PropellantTanks {
        doc /* GR-033 [public integration value] model four visible propellant-tank owners; exact COPV dimensions and placement remain TBD. Source: Astrobotic Griffin mission update. */
    }

    requirement def GRV001_PresentationFrame {
        doc /* GV-001 [visual] the review composition shall expose an authored VisualCamera in the project SI/Y-up frame. */
    }

    requirement def GRV002_LanderPresentation {
        doc /* GV-002 [visual] the review shall show Griffin-1 as a recognisable hexagonal-footprint lander with its four legs, payload deck, and seven-engine cluster. */
    }

    requirement def GRV003_GriffinSolarAssemblies {
        doc /* GV-003 [visual] the review shall show Griffin's two mirrored side solar arrays as named frame/cell assemblies. */
    }

    requirement def GRV004_ScaleDatums {
        doc /* GV-004 [visual] review geometry shall agree with the SysML deck, wheel, landing-pad, and ground scale datums in metres. */
    }

    requirement def GRV005_RenderOwnership {
        doc /* GV-005 [visual ownership] presentation geometry shall be render-only where it is not a load-bearing collider; metric landing-pad datums are guide-only and hidden, and the test shall query collision, purpose, and visibility attributes. */
    }

    requirement def GRV006_LunarContext {
        doc /* GV-006 [visual] the review shall include an authored lunar surface context and a single project light, without introducing a second physics model. */
    }

    requirement def GRV007_VisualEvidence {
        doc /* GV-007 [evidence] the visual verdict shall be emitted by Twin Rhai and paired with a captured frame and composed USD query from the same source revision. */
    }

    requirement gr001 : GR001_LanderArchitecture { subject lander : Griffin1Lander; }
    requirement gr002 : GR002_PayloadAdapter { subject lander : Griffin1Lander; }
    requirement gr003 : GR003_DeployableRamps { subject lander : Griffin1Lander; }
    requirement gr004 : GR004_SurfaceSequence { subject lander : Griffin1Lander; subject rover : HostedRoverInterface; }
    requirement gr005 : GR005_TraceableValues { subject lander : Griffin1Lander; }
    requirement gr006 : GR006_SolarAssemblies { subject lander : Griffin1Lander; subject rover : HostedRoverInterface; }
    requirement gr007 : GR007_GatedEgress { subject rover : HostedRoverInterface; }
    requirement gr008 : GR008_AttitudeCases { subject rover : HostedRoverInterface; }
    requirement gr009 : GR009_PayloadCapacity { subject lander : Griffin1Lander; }
    requirement gr010 : GR010_FunctionalLegs { subject lander : Griffin1Lander; }
    requirement gr011 : GR011_RampBodies { subject lander : Griffin1Lander; }
    requirement gr012 : GR012_LoadBearingMass { subject lander : Griffin1Lander; }
    requirement gr013 : GR013_ParameterProvenance { subject lander : Griffin1Lander; }
    requirement gr014 : GR014_TypedAuthoring { subject lander : Griffin1Lander; }
    requirement gr015 : GR015_NozzleGeometry { subject lander : Griffin1Lander; }
    requirement gr016 : GR016_SolarSymmetry { subject lander : Griffin1Lander; }
    requirement gr017 : GR017_RampSymmetry { subject lander : Griffin1Lander; }
    requirement gr018 : GR018_HullAndDeck { subject lander : Griffin1Lander; }
    requirement gr019 : GR019_LegPlacement { subject lander : Griffin1Lander; }
    requirement gr020 : GR020_ProxySuppression { subject lander : Griffin1Lander; }
    requirement gr021 : GR021_MassProperties { subject lander : Griffin1Lander; }
    requirement gr022 : GR022_SupportPolygon { subject lander : Griffin1Lander; }
    requirement gr023 : GR023_ContactContinuity { subject lander : Griffin1Lander; }
    requirement gr024 : GR024_HingeFrames { subject lander : Griffin1Lander; }
    requirement gr025 : GR025_SolarClearance { subject lander : Griffin1Lander; }
    requirement gr026 : GR026_AdapterRelease { subject lander : Griffin1Lander; subject rover : HostedRoverInterface; }
    requirement gr027 : GR027_PropulsionAlignment { subject lander : Griffin1Lander; }
    requirement gr028 : GR028_InterfaceResolution { subject lander : Griffin1Lander; subject rover : HostedRoverInterface; }
    requirement gr029 : GR029_PartProvenance { subject lander : Griffin1Lander; subject rover : HostedRoverInterface; }
    requirement gr030 : GR030_EvidenceGate { subject lander : Griffin1Lander; }
    requirement gr031 : GR031_DeterministicVerdict { subject rover : HostedRoverInterface; }
    requirement gr032 : GR032_MainEngineBells { subject lander : Griffin1Lander; }
    requirement gr033 : GR033_PropellantTanks { subject lander : Griffin1Lander; }
    requirement gv001 : GRV001_PresentationFrame { subject lander : Griffin1Lander; }
    requirement gv002 : GRV002_LanderPresentation { subject lander : Griffin1Lander; }
    requirement gv003 : GRV003_GriffinSolarAssemblies { subject lander : Griffin1Lander; }
    requirement gv004 : GRV004_ScaleDatums { subject lander : Griffin1Lander; subject rover : HostedRoverInterface; }
    requirement gv005 : GRV005_RenderOwnership { subject lander : Griffin1Lander; subject rover : HostedRoverInterface; }
    requirement gv006 : GRV006_LunarContext { subject lander : Griffin1Lander; }
    requirement gv007 : GRV007_VisualEvidence { subject lander : Griffin1Lander; subject rover : HostedRoverInterface; }

    verification def Verify_GriffinRequirements {
        subject lander : Griffin1Lander;
        subject rover : HostedRoverInterface;
        verify gr001;
        verify gr002;
        verify gr003;
        verify gr004;
        verify gr005;
        verify gr006;
        verify gr007;
        verify gr008;
        verify gr009;
        verify gr010;
        verify gr011;
        verify gr012;
        verify gr013;
        verify gr014;
        verify gr015;
        verify gr016;
        verify gr017;
        verify gr018;
        verify gr019;
        verify gr020;
        verify gr021;
        verify gr022;
        verify gr023;
        verify gr024;
        verify gr025;
        verify gr026;
        verify gr027;
        verify gr028;
        verify gr029;
        verify gr030;
        verify gr031;
        verify gr032;
        verify gr033;
    }

    verification def Verify_GriffinVisualRequirements {
        subject lander : Griffin1Lander;
        subject rover : HostedRoverInterface;
        verify gv001;
        verify gv002;
        verify gv003;
        verify gv004;
        verify gv005;
        verify gv006;
        verify gv007;
    }

    verification def Verify_GriffinSurfaceOperations {
        subject lander : Griffin1Lander;
        subject rover : HostedRoverInterface;
        verify gr004;
        verify gr007;
        verify gr008;
        verify gr026;
        verify gr031;
    }

    verification def Verify_GriffinLandingStability {
        subject lander : Griffin1Lander;
        verify gr031;
    }
}
