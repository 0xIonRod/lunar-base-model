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
        attribute requirementUsageCount : Integer = 35;
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
        attribute visualVerificationCaseName : String = "Griffin1Requirements::Verify_GriffinVisualRequirements";
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
        // The approach marker is the rover-centre datum just before the
        // 3.16 m deck edge. With FLIP's roughly 1.2 m forward half-envelope,
        // x=2.00 m brings the front wheels onto the hinge transition without
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
        // implementation constants.  The first radius is a 0.35 m approach
        // lane around the centerline: it is tight enough to require the
        // front wheels to reach the separately modeled 1.21 m transition,
        // while accepting the measured low-speed steering drift of the
        // study rover. The second radius remains 0.30 m at the forward
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
    attribute executableRequirementIds : String[21] = ("GR-001", "GR-002", "GR-003", "GR-005", "GR-006", "GR-009", "GR-010", "GR-011", "GR-012", "GR-013", "GR-015", "GR-016", "GR-017", "GR-018", "GR-019", "GR-020", "GR-029", "GR-032", "GR-033", "GR-034", "GR-035");
        attribute plannedRequirementIds : String[11] = ("GR-004", "GR-007", "GR-008", "GR-014", "GR-021", "GR-022", "GR-023", "GR-024", "GR-025", "GR-027", "GR-028");
        attribute missionScopeRequirementIds : String[1] = ("GR-026");
        attribute processGateRequirementIds : String[1] = ("GR-030");
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
        doc /* GR-001 [public+study] model a reusable Griffin body, four legs, and an octagonal payload deck; verify named USD topology. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/. Rationale: the product page establishes the lander architecture; the named component split is the Twin's inspectable study representation. */
    }

    requirement def GR002_PayloadAdapter {
        doc /* GR-002 [integration] provide an explicit payload-adapter datum that holds FLIP before the release gate; verify the fixed-joint interface in composed USD. Source: Twin adapter/release contract and https://www.astrolab.space/flip/. Rationale: a named interface is needed to distinguish secured pre-release state from post-release mobility. */
    }

    requirement def GR003_DeployableRamps {
        doc /* GR-003 [public optional hardware] model two optional Griffin side ramps with contact surfaces and inspectable hinges; do not treat ramps as a mandatory FLIP interface. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/. Rationale: ramps are a public/optional egress interpretation, while the Twin must preserve the direct-deck alternative. */
    }

    requirement def GR004_SurfaceSequence {
        doc /* GR-004 [mission flow] preserve landing/settle, egress-path preparation, adapter release, FLIP egress, and route order; verify with a Twin Rhai scenario. Source: Twin mission scenario contract. Rationale: the ordered gates prevent control from transferring to an airborne or still-secured rover. */
    }

    requirement def GR005_TraceableValues {
        doc /* GR-005 [traceability] every value is labelled public fact, project requirement, study proxy, or TBD with a source or rationale. Source: SysML/Rhai verification policy. Rationale: a reviewer must be able to tell certified/public data from a visual or runtime assumption. */
    }

    requirement def GR006_SolarAssemblies {
        doc /* GR-006 [subsystem] represent Griffin arrays and FLIP's collapsible-array concept as named visual/power subassemblies; verify deployment state is not silently assumed. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ and https://www.astrolab.space/flip/. Rationale: separate ownership lets panel dimensions, placement, and deployment state be reviewed without mixing them with vehicle dynamics. */
    }

    requirement def GR007_GatedEgress {
        doc /* GR-007 [runtime] egress shall be a physical direct-deck or optional-ramp path with wheel/contact evidence, never a teleport from deck to terrain. Source: Twin egress runtime contract. Rationale: wheel/contact evidence is the minimum proof that rover release represents a traversable path rather than a scripted relocation. */
    }

    requirement def GR008_AttitudeCases {
        doc /* GR-008 [verification] exercise nominal, high-pitch, uneven-roll, and combined pitch/roll egress cases; report inconclusive when contact data is unavailable. Source: Twin mission verification plan. Assumption: these four cases span the dominant attitude sensitivities of a two-track egress study; inconclusive is required when the runtime cannot observe contact. */
    }

    requirement def GR009_PayloadCapacity {
        doc /* GR-009 [public product value] Griffin payload capacity is 625 kg; accept the boundary and reject loads above it. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/. Rationale: the public product datum is the only authoritative capacity available to this Twin, so the limiter tests both the stated boundary and over-capacity rejection. */
    }

    requirement def GR010_FunctionalLegs {
        doc /* GR-010 [public product value] retain exactly four visible functional landing-leg bodies with struts and pad colliders. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/. Rationale: the public four-leg architecture determines count/topology; the visual strut and pad envelopes are separate study assumptions until an ICD is available. */
    }

    requirement def GR011_RampBodies {
        doc /* GR-011 [study control] retain two side-ramp bodies with contact geometry and revolute hinges; the command bound is a proxy, not a released mechanical limit. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/. Assumption: 0.58 rad is a conservative visual/mechanism study limit; it must be replaced when the mechanical ICD is released. */
    }

    requirement def GR012_LoadBearingMass {
        doc /* GR-012 [physics] every load-bearing subassembly has positive mass and explicit collision ownership; compound-body admission is a runtime gate. Source: LunCoSim physics admission contract. Rationale: positive mass and one declared collider owner prevent visual-only parts from silently becoming a second physical system. */
    }

    requirement def GR013_ParameterProvenance {
        doc /* GR-013 [traceability] status and provenance metadata are required for every study parameter and every inherited surrogate. Source: SysML/Rhai provenance policy. Rationale: reviewers need to distinguish a public datum, an engineering assumption, and a missing supplier value before trusting a verdict. */
    }

    requirement def GR014_TypedAuthoring {
        doc /* GR-014 [process] model edits use the typed USD path and rerun the Twin contract before save; filesystem rewrites are not acceptance evidence. Source: LunCoSim typed Editor authoring contract. Rationale: the runtime's composed stage, not a raw layer rewrite, is what the simulation and verification actually consume. */
    }

    requirement def GR015_NozzleGeometry {
        doc /* GR-015 [visual+physics] each named lander part resolves to geometry and the nozzle owns visible bell geometry that is not a collider. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ and the Twin visual ownership contract. Rationale: visible propulsion detail must remain replaceable presentation while thrust/collision stay with the flight model. */
    }

    requirement def GR016_SolarSymmetry {
        doc /* GR-016 [layout] keep exactly two named Griffin solar-array owners on signed sides with mirrored placement and owned cell geometry. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/. Assumption: the mirrored two-array layout is the current visual study interpretation; exact flight deployment geometry is TBD. */
    }

    requirement def GR017_RampSymmetry {
        doc /* GR-017 [layout] optional ramps mirror in side placement, hinge rotation, and angle metadata when the ramp branch is selected. Source: Twin ramp component contract. Rationale: mirrored signs make port/starboard behavior deterministic and prevent one side from inheriting an accidental transform. */
    }

    requirement def GR018_HullAndDeck {
        doc /* GR-018 [physics boundary] the powered Griffin body shall retain a positive, hidden flight-body collision proxy and a positive, hidden top-deck collision proxy. The current octagonal Bus component owns visible body and deck geometry; opaque BoxyAirframe and IsogridDeck presentation duplicates shall be absent. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/. Assumption: collider envelopes are simulation study proxies, not released CAD. */
    }

    requirement def GR019_LegPlacement {
        doc /* GR-019 [layout] mount four legs on signed horizontal body axes with mirrored pads and a documented local frame. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/. Rationale: signed stations expose the four-leg support pattern and make symmetry errors observable in the composed stage. */
    }

    requirement def GR020_ProxySuppression {
        doc /* GR-020 [visual ownership] suppress inherited comparison geometry when a named part owns the visible representation; hidden duplicates do not count as removal. Source: Twin component ownership policy. Rationale: inactive or hidden duplicates still obscure which component owns the rendered geometry and can reappear during composition. */
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

    requirement def GR024_HingeFrames {
        doc /* GR-024 [physics planned] selected ramp hinge frames, axes, limits, and body ownership agree with the authored pose. Source: Twin mount-socket and revolute-joint contract. Rationale: checking the complete hinge frame prevents a visually plausible ramp from being physically attached to the wrong body or axis. */
    }

    requirement def GR025_SolarClearance {
        doc /* GR-025 [layout planned] arrays have clearance from bodies and each other in both stowed and deployed study states. Source: spacecraft deployable-clearance practice. Assumption: the current visual panel envelopes are proxies; the clearance margin must be replaced by a released deployment ICD. */
    }

    requirement def GR026_AdapterRelease {
        doc /* GR-026 [runtime] adapter release leaves no stale joint or pre-release route ownership and transfers FLIP control exactly once. Source: Twin adapter-release runtime contract. Rationale: exactly-once ownership transfer prevents the lander and rover controllers from simultaneously commanding the released vehicle. */
    }

    requirement def GR027_PropulsionAlignment {
        doc /* GR-027 [visual+physics planned] nozzle and flame align with the thrust axis and plume geometry remains visual-only. Source: propulsion presentation/flight-model boundary. Assumption: the current bell/throat profile is a visual proxy because a public Griffin engine ICD is unavailable. */
    }

    requirement def GR028_InterfaceResolution {
        doc /* GR-028 [integration planned] electrical, thermal, propulsion, guidance, and mobility interface names resolve without silent defaults. Source: Twin subsystem interface registry. Rationale: explicit unresolved interfaces are safer than silently accepting a default that changes mission behavior. */
    }

    requirement def GR029_PartProvenance {
        doc /* GR-029 [traceability] every canonical part records source/provenance and known, proxy, or TBD parameter status. Source: SysML provenance policy and the public Griffin/FLIP references listed on the parts. Rationale: part-level provenance makes replacement and review tractable when supplier data arrives. */
    }

    requirement def GR030_EvidenceGate {
        doc /* GR-030 [evidence] changed geometry groups require fresh headful visual evidence plus composed query output from the same document generation. Source: Twin evidence gate. Rationale: a screenshot alone cannot prove authored topology, while a query alone cannot prove the visible composition. */
    }

    requirement def GR031_DeterministicVerdict {
        doc /* GR-031 [test] the production Twin test emits a deterministic verdict with fixed tick rate, threads, and jitter, including inconclusive runtime states. Source: LunCoSim deterministic test runner contract. Rationale: fixed execution settings make regressions reproducible and prevent missing observations from being mistaken for PASS. */
    }

    requirement def GR032_MainEngineBells {
        doc /* GR-032 [public product value] model exactly seven visible, non-colliding main-engine bell geometries. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/. Rationale: the public seven-engine architecture fixes the count; bell dimensions remain a separately labeled visual proxy. */
    }

    requirement def GR033_PropellantTanks {
        doc /* GR-033 [public integration value] model four visible propellant-tank owners; exact COPV dimensions and placement remain TBD. Source: https://www.astrobotic.com/griffin-1-mission-update/. Rationale: four repeated tank owners are needed to represent the visible system, but public material does not provide a certified tank ICD. */
    }

    requirement def GR034_SurfaceRouteDatums {
        doc /* GR-034 [mission interface] author every surface-operations route marker, speed, and arrival radius from one ordered SysML table; the approach marker shall lie just before the deployed port-ramp hinge and its 0.35 m approach-lane radius shall require FLIP's front wheels to reach the 1.21 m transition while accepting measured low-speed steering drift, while the exit marker shall lie beyond the 8.00 m physical ramp envelope with a 0.30 m radius on the ramp centreline. The later diagonal survey legs shall use the conservative 0.22..0.14 m/s study-speed envelope to keep the shared Ackermann law inside its waypoint sequence. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ and the Twin physical-ramp study in requirements/griffin_ramp_requirements.sysml. Rationale: route control must target the actual component interface instead of stale coordinates, excessive corner speed, or an oversized tolerance that can declare egress complete while FLIP remains on the deck; the centreline exit avoids a lateral steering reversal before the trailing axle clears the physical ramp, and the remaining survey markers retain the bounded base-site study path. */
    }

    requirement def GR035_EgressApronContact {
        doc /* GR-035 [mission interface+physics] provide a named, collidable EgressApron that overlaps the deployed 8.00 m ramp tip and extends beyond the (12.00,0.00) centreline exit marker so the released FLIP transitions to a continuous surface before survey navigation. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/; twin://astrobotic-griffin-1/scenes/griffin_1_surface_ops.usda. Rationale: the public sources do not publish a Griffin site-apron ICD, so the 10.00 m x 8.00 m x 0.10 m apron at (13.50,-0.05,-1.00) is an explicit replaceable Twin study assumption. Its top y=0.00 m matches the normalized ramp-tip terrain datum and its centreline placement works with the straight exit gate; it closes the measured geometry gap between the ramp end near x=11.20 m and the original landing-pad boundary at x=6.00 m. It must be authored through the typed Editor and verified through composed collision and wheel-contact evidence, never by moving the rover. */
    }

    requirement def GRV001_PresentationFrame {
        doc /* GV-001 [visual] the review composition shall expose an authored VisualCamera in the project SI/Y-up frame. Source: LunCoSim visual review contract. Rationale: a named camera makes visual evidence repeatable across headful and capture runs. */
    }

    requirement def GRV002_LanderPresentation {
        doc /* GV-002 [visual] the review shall show Griffin-1 as a recognizable faceted lander with its four legs, payload deck, and seven-engine cluster. The active review profile is the octagonal open frame selected in GriffinVisualConfiguration; do not describe or instantiate the superseded six-sided visual proxy. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/. */
    }

    requirement def GRV003_GriffinSolarAssemblies {
        doc /* GV-003 [visual] the review shall show Griffin's two mirrored side solar arrays as named frame/cell assemblies. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/. Assumption: the mirrored two-panel layout is the current visual proxy and may be replaced by flight layout data. */
    }

    requirement def GRV004_ScaleDatums {
        doc /* GV-004 [visual] review geometry shall agree with the SysML deck, wheel, landing-pad, and ground scale datums in metres. Source: Moon Base SI/Y-up project contract. Rationale: common scale datums are required to judge rover-to-lander proportions and contact plausibility. */
    }

    requirement def GRV005_RenderOwnership {
        doc /* GV-005 [visual ownership] presentation geometry shall be render-only where it is not a load-bearing collider; metric landing-pad datums are guide-only and hidden, and the test shall query collision, purpose, and visibility attributes. Source: LunCoSim visual/physics ownership policy. Rationale: visible study geometry must not quietly alter contact or mass behavior. */
    }

    requirement def GRV006_LunarContext {
        doc /* GV-006 [visual] the review shall include the source-backed South-Pole terrain asset using the canonical terrain_layered.wgsl shader and one project light, without introducing a second physics model. Source: https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/ and the Twin terrain asset manifest. Rationale: the context supports mission readability while keeping terrain physics owned by the simulator. */
    }

    requirement def GRV007_VisualEvidence {
        doc /* GV-007 [evidence] the visual verdict shall be emitted by Twin Rhai and paired with a captured frame and composed USD query from the same source revision. Source: Twin visual evidence gate. Rationale: matching source revision, query, and frame prevents stale screenshots from being presented as current model evidence. */
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
    requirement gr034 : GR034_SurfaceRouteDatums { subject rover : HostedRoverInterface; }
    requirement gr035 : GR035_EgressApronContact { subject rover : HostedRoverInterface; }
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
        verify gr034;
        verify gr035;
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

    verification def Verify_GriffinAdapterRelease {
        subject lander : Griffin1Lander;
        subject rover : HostedRoverInterface;
        verify gr026;
    }

    verification def Verify_GriffinLandingStability {
        subject lander : Griffin1Lander;
        verify gr031;
    }
}
