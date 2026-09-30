package GriffinVisualConfigurationRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import ScalarValues::Boolean;
    private import VectorValues::CartesianThreeVectorValue;
    private import VectorValues::CartesianVectorValue;

    /* Semantic aliases over the standard SysML Cartesian three-vector type.
     * The names distinguish point, unit-direction, and size roles while the
     * bridge projects each literal directly to the shared f64 Vec3 value. */
    attribute def Position :> CartesianThreeVectorValue;
    attribute def Direction :> CartesianThreeVectorValue;
    attribute def Dimensions :> CartesianThreeVectorValue;

    /*
     * Discrete configuration choices are enumerations, stations are typed
     * Position values, and envelopes are Dimensions. This package contains
     * no free-form String geometry parameters. Source evidence and rationale
     * live in griffin_requirement_sources.sysml and the requirement docs.
     */
    enum def GriffinReviewConfiguration {
        LandedPolarSideArrays;
    }
    enum def GriffinBodyProfile {
        OctagonalOpenFrame;
    }
    enum def GriffinRampReviewState {
        Stowed;
        Deployed;
    }
    enum def GriffinFrameRailNode {
        FrameRailFrontPort;
        FrameRailFrontStarboard;
        FrameRailRearPort;
        FrameRailRearStarboard;
        FrameRailPortFront;
        FrameRailPortRear;
        FrameRailStarboardFront;
        FrameRailStarboardRear;
    }
    enum def GriffinTankInstanceName {
        TankPX;
        TankNX;
        TankPZ;
        TankNZ;
    }
    enum def GriffinLandingLegInstanceName {
        LegPX;
        LegNX;
        LegPZ;
        LegNZ;
    }
    enum def GriffinSolarArrayInstanceName {
        SolarPanelForward;
        SolarPanelFrontStarboard;
        SolarPanelStarboard;
    }
    enum def GriffinRampInstanceName {
        EgressRampPort;
        EgressRampStarboard;
    }
    enum def GriffinRampHingeInstanceName {
        RampHingePort;
        RampHingeStarboard;
    }
    enum def GriffinReviewCameraName { VisualCamera; }
    enum def GriffinReviewLanderName { Griffin1; }
    enum def UsdGeomPurpose { Render; Proxy; Guide; }
    enum def GriffinMainEngineInstanceName {
        Engine01;
        Engine02;
        Engine03;
        Engine04;
        Engine05;
        Engine06;
        Engine07;
    }

    part def GriffinVisualConfiguration {
        attribute configuration : GriffinReviewConfiguration = "LandedPolarSideArrays";
        attribute bodyProfile : GriffinBodyProfile = "OctagonalOpenFrame";
        attribute rampState : GriffinRampReviewState = "Stowed";

        /* Canonical assembly frame: SI metres, Y-up, right-handed. */
        attribute origin : Position = (0.0, 0.0, 0.0);
        attribute axisUp : Direction = (0.0, 1.0, 0.0);
        attribute axisPort : Direction = (-1.0, 0.0, 0.0);
        attribute axisForward : Direction = (0.0, 0.0, 1.0);
        // Shared numerical tolerance for source-backed geometric relations.
        // It is a review-policy datum, not a hidden Rust or Rhai literal.
        attribute verificationToleranceM : Real = 1.0e-6;
        attribute geometryVerificationToleranceM : Real = 0.002;
        attribute appearanceVerificationTolerance : Real = 1.0e-6;
        attribute doubleSidedFacesMustBe : Boolean = false;
        attribute renderOnlyCollisionEnabled : Boolean = false;
        attribute renderPurpose : UsdGeomPurpose = "Render";
        attribute reviewCameraName : GriffinReviewCameraName = "VisualCamera";
        attribute reviewLanderName : GriffinReviewLanderName = "Griffin1";
        attribute visualReviewGriffinStation : Position = (0.0, 0.0, 0.0);
        // FLIP is mounted on the payload adapter. Its wheel bottoms (station
        // -0.05 m minus 0.45 m tire radius) meet the adapter top at 2.08 m.
        // This station is the one review-scene placement source.
        attribute visualReviewFlipStation : Position = (0.0, 2.58, 0.0);

        /* SIZE ESTIMATE, 2026-09-30; rationale and uncertainties are in
         * requirements/griffin-size-evidence.md. NASA MSS 2024, slide 8
         * (https://ntrs.nasa.gov/citations/20240004236) labels the older
         * VIPER-configured vehicle envelope 4.5 m by 2.0 m, not its bus.
         * Estimate the bus at 80% of that lateral envelope (3.6 +/-0.4 m).
         * Current hardware photo https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/
         * motivates a taller 2.52 +/-0.5 m landed payload surface, excluding
         * its ground handling stand. Body belt height 0.72 +/-0.12 m and all internal
         * support coordinates below are packaging estimates, not metrology.
         * A 0.44 m vehicle touchdown datum plus adapter Y=2.0 and half its
         * 0.16 m thickness gives the 2.52 m ground-to-payload height. */
        attribute bodyDimensions : Dimensions = (3.60, 0.72, 3.60);
        attribute bodyMount : Position = (0.0, 1.34, 0.0);
        /* Exterior blanket/panel presentation follows the faceted wrapped
         * structure visible in the June 2026 Astrobotic hardware photo above.
         * Eight flat facets approximate the envelope; actual blanket folds,
         * fasteners and cutouts are unknown. Thickness 25 mm and 40 mm edge
         * margins are presentation estimates, not structural material sizing.
         * Light neutral panel color is an image-informed linear display-color estimate.
         * This cladding is render-only; the frame remains a separate part. */
        /* ESA artist impression, 23 September 2022:
         * https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander
         * The user's marked flat face is about 3:1 width/height, not the
         * full vehicle span. Flat face width = 0.5857864376 * 3.60 = 2.109 m;
         * /3 gives 0.703 m, rounded to 0.72 m for this study. Perspective
         * supports only an approximate ratio (2.65-3.35), not metrology.
         * Keep the body top at vehicle Y=1.70 and payload top Y=2.08;
         * the shallower belt therefore moves upward rather than moving ramps.
         * This older artist impression is a user-selected silhouette basis;
         * it is not a claim of June 2026 as-built panel geometry. */
        attribute bodySideFaceAspectRatio : Real = 3.0;
        attribute bodySideFaceAspectRatioTolerance : Real = 0.35;
        attribute bodySkinThicknessM : Real = 0.025;
        attribute bodySkinEdgeMarginM : Real = 0.04;
        attribute bodySkinDisplayColor : Real[3] = (0.32, 0.34, 0.36);
        attribute bodyGroundClearanceM : Real = 0.20;
        attribute lowerSkirtDimensions : Dimensions = (3.40, 0.24, 3.40);
        attribute lowerSkirtCenter : Position = (0.0, -0.36, 0.0);
        attribute deckDimensions : Dimensions = (3.50, 0.16, 3.50);
        attribute deckCenter : Position = (0.0, 0.37, 0.0);
        attribute avionicsDeckDimensions : Dimensions = (2.00, 0.10, 1.46);
        attribute avionicsDeckCenter : Position = (0.0, 0.46, 0.0);

        /* Linear scene-referred display colors are visual design parameters;
         * Rhai consumes these values but does not define a second palette. */
        attribute frameDisplayColor : Real[3] = (0.04, 0.06, 0.09);
        attribute deckDisplayColor : Real[3] = (0.025, 0.035, 0.05);
        attribute lowerSkirtDisplayColor : Real[3] = (0.02, 0.025, 0.035);
        attribute avionicsDeckDisplayColor : Real[3] = (0.10, 0.13, 0.17);
        attribute avionicsPodDisplayColor : Real[3] = (0.22, 0.25, 0.29);
        attribute railDisplayColor : Real[3] = (0.035, 0.045, 0.06);
        attribute tankSupportDisplayColor : Real[3] = (0.12, 0.15, 0.19);
        attribute tankCollarDisplayColor : Real[3] = (0.24, 0.28, 0.34);

        /* Normalized (X, -Z) clipped-square octagon profile. CartesianVectorValue
         * remains a typed native Vec2 in the runtime bridge. The tank support
         * is a separate inner feature, not a second outer-body profile. */
        attribute outerBodyProfileCoordinates : CartesianVectorValue[8] =
            ((-0.5857864376269049, -1.0), (0.5857864376269049, -1.0),
             (1.0, -0.5857864376269049), (1.0, 0.5857864376269049),
             (0.5857864376269049, 1.0), (-0.5857864376269049, 1.0),
             (-1.0, 0.5857864376269049), (-1.0, -0.5857864376269049));

        /* Eight upper and eight lower beams close the octagonal outer frame. */
        attribute frameRingCenterY : Real[2] = (0.28, -0.28);
        attribute frameRingSectionM : Real = 0.16;
        attribute frameRails : GriffinFrameRailNode[8] =
            ("FrameRailFrontPort", "FrameRailFrontStarboard",
             "FrameRailStarboardFront", "FrameRailStarboardRear",
             "FrameRailRearStarboard", "FrameRailRearPort",
             "FrameRailPortRear", "FrameRailPortFront");
        attribute tankInstances : GriffinTankInstanceName[4] =
            ("TankPX", "TankNX", "TankPZ", "TankNZ");
        attribute landingLegInstances : GriffinLandingLegInstanceName[4] =
            ("LegPX", "LegNX", "LegPZ", "LegNZ");
        attribute solarArrayInstances : GriffinSolarArrayInstanceName[3] =
            ("SolarPanelForward", "SolarPanelFrontStarboard", "SolarPanelStarboard");
        attribute mainEngineInstances : GriffinMainEngineInstanceName[7] =
            ("Engine01", "Engine02", "Engine03", "Engine04", "Engine05", "Engine06", "Engine07");
        attribute rampInstances : GriffinRampInstanceName[2] =
            ("EgressRampPort", "EgressRampStarboard");
        attribute rampHingeInstances : GriffinRampHingeInstanceName[2] =
            ("RampHingePort", "RampHingeStarboard");
        attribute railStations : Position[8] =
            ((-1.008, 0.0, 1.720), (1.008, 0.0, 1.720),
             (1.720, 0.0, 1.008), (1.720, 0.0, -1.008),
             (1.008, 0.0, -1.720), (-1.008, 0.0, -1.720),
             (-1.720, 0.0, -1.008), (-1.720, 0.0, 1.008));
        attribute railDimensions : Dimensions = (0.16, 0.72, 0.16);

        /* Separate central tank-support assembly. The four bore centres are
         * derived from tankStations and tankInstances. The polygonal bore
         * radius clears the maximum scaled retention-band envelope by the
         * same 0.06 m study margin used by the tank/frame contract. */
        /* The central perimeter uses outerBodyProfileCoordinates at this
         * separate radius, so both structures share one octagonal profile. */
        attribute tankSupportPerimeterRadiusM : Real = 1.62;
        attribute tankSupportPerimeterSectionM : Real = 0.12;
        attribute tankSupportOpeningInnerRadiusM : Real = 0.58;
        attribute tankSupportOpeningOuterRadiusM : Real = 0.70;
        attribute tankSupportOpeningSegments : Integer = 16;
        attribute tankSupportPlanes : Real[3] = (0.37, 0.0, -0.37);

        /* Open eight-sided upper and lower buckets bridge the tank rings;
         * neither shell crosses the four COPV columns. These are replaceable
         * presentation assumptions because the supplier structural ICD is
         * not public. */
        attribute centralBucketSegments : Integer = 8;
        attribute centralBucketShellThicknessM : Real = 0.12;
        attribute upperBucketInnerBottomRadiusM : Real = 0.52;
        attribute upperBucketOuterBottomRadiusM : Real = 0.64;
        attribute upperBucketInnerTopRadiusM : Real = 1.42;
        attribute upperBucketOuterTopRadiusM : Real = 1.54;
        attribute upperBucketBottomCenterYM : Real = 0.46;
        attribute upperBucketTopCenterYM : Real = 0.58;
        attribute lowerBucketInnerTopRadiusM : Real = 0.52;
        attribute lowerBucketOuterTopRadiusM : Real = 0.64;
        attribute lowerBucketInnerBottomRadiusM : Real = 1.42;
        attribute lowerBucketOuterBottomRadiusM : Real = 1.54;
        attribute lowerBucketTopCenterYM : Real = -0.46;
        attribute lowerBucketBottomCenterYM : Real = -0.58;
        attribute payloadAdapterDimensions : Dimensions = (3.20, .16, 3.20);
        attribute payloadAdapterCenterYM : Real = 2.00;

        attribute legStations : Position[4] =
            ((1.90, 1.20, 0.0), (-1.90, 1.20, 0.0),
             (0.0, 1.20, 1.90), (0.0, 1.20, -1.90));
        /* Each local +X axis points radially outward. This gives the shared
         * leg mount interface one canonical orientation at every bus side. */
        attribute legStationRotationYDeg : Real[4] = (0.0, 180.0, -90.0, 90.0);

        /* The three panel instances occupy consecutive forward, diagonal,
         * and starboard bus faces in the mission Sun quadrant. Stations and
         * orientations use lander coordinates; rail stations are Bus-local.
         * The diagonal station follows the beveled octagonal face normal.
         * Each pair maps local panel -X then +X to the corresponding rails.
         * Panel width derives from each rail pair's spacing minus the common
         * edge clearance; the component's maximum width is owned by GSA. */
        attribute solarStations : Position[3] =
            ((0.0, 1.34, 1.94), (1.49, 1.34, 1.49), (1.94, 1.34, 0.0));
        attribute solarMountRails : GriffinFrameRailNode[6] =
            ("FrameRailFrontPort", "FrameRailFrontStarboard",
             "FrameRailFrontStarboard", "FrameRailStarboardFront",
             "FrameRailStarboardFront", "FrameRailStarboardRear");
        attribute solarStationRotationXDeg : Real[3] = (90.0, 90.0, 90.0);
        attribute solarStationRotationZDeg : Real[3] = (0.0, -45.0, -90.0);
        attribute solarArrayEdgeClearanceM : Real = 0.15;

        /* Four tank stations and 0.60 instance scale are packaging estimates.
         * Their largest band radius is approximately 0.516 m, so 0.58 m
         * support openings retain over 0.06 m radial clearance. See
         * griffin-size-evidence.md; no supplier tank dimensions are public. */
        attribute tankStations : Position[4] =
            ((0.85, 1.40, 0.0), (-0.85, 1.40, 0.0),
             (0.0, 1.40, 0.85), (0.0, 1.40, -0.85));
        attribute tankStationRotationYDeg : Real[4] = (0.0, 0.0, 0.0, 0.0);
        attribute tankScale : Real[4] = (0.60, 0.60, 0.60, 0.60);
        attribute minimumTankInstanceClearanceM : Real = 0.06;
        attribute minimumTankFrameClearanceM : Real = 0.06;

        attribute engineClusterMountYM : Real = 1.00;
        attribute engineBellDirection : Direction = (0.0, -1.0, 0.0);
        /* One center engine and six equally spaced bells on a 1.05 m radius.
         * The 0.34 m exit radius leaves 0.37 m between adjacent bell envelopes
         * and keeps all seven inside the lower bucket's 1.54 m outer radius. */
        attribute engineStations : Position[7] =
            ((0.0, 1.00, 0.0), (1.05, 1.00, 0.0), (-1.05, 1.00, 0.0),
             (0.525, 1.00, 0.9093266739736606),
             (-0.525, 1.00, -0.9093266739736606),
             (-0.525, 1.00, 0.9093266739736606),
             (0.525, 1.00, -0.9093266739736606));
    }

    requirement def GVC001_ConfigurationSelection {
        doc /* GVC-001 [configuration] the review model shall identify the landed polar side-array configuration and stowed ramp state with SysML enumerations, keeping optional deployed egress geometry out of the primary silhouette. */
    }
    requirement def GVC002_FrameAndOrigin {
        doc /* GVC-002 [datum] every component station shall use the declared native Position/Direction assembly frame and origin; this shared frame makes mirror, clearance, and Editor readback checks meaningful. Rationale: the prior diagonal/axis mismatch let the builder and verifier accept different layouts. */
    }
    requirement def GVC003_OctagonalAirframe {
        doc /* GVC-003 [geometry] the primary airframe shall use an open eight-sided clipped-square perimeter with eight posts and upper/lower perimeter beams. The source-owned 3.60 m plan span and 1.40 m core height are low-confidence estimates documented in griffin-size-evidence.md, not supplier dimensions. Separate skirt, payload ring and central supports retain their own geometry. */
    }
    requirement def GVC004_OctagonalPayloadDeck {
        doc /* GVC-004 [interface] the upper bus datum shall expose a source-sized octagonal perimeter deck ring with four tank through-openings; it shall not be a solid plate across the COPV cluster. A raised central payload adapter is supported by the upper flared bucket and shall carry the linked FLIP review asset with all four tire bottoms resting on the adapter. The lander and rover review stations, adapter footprint, and member stock are replaceable study assumptions, not released supplier CAD. */
    }
    requirement def GVC005_LegStations {
        doc /* GVC-005 [layout] four leg roots shall occupy mirrored axial X/Z stations at a 3.10 m radial offset beyond the enlarged octagonal body, with local radial rotations and at least 0.20 m body-to-ground visual clearance. Source: Griffin's four shock-absorbing legs; exact station ICD is not public. */
    }
    requirement def GVC006_SolarStations {
        doc /* GVC-006 [configuration] for each solar-array identity, the configuration shall provide one assembly-frame station, panel orientation, and supporting bus-rail mapping. The configured stations shall satisfy the adjacent-side Sun-quadrant relationship defined by GriffinSolarRequirements. */
    }
    requirement def GVC007_TankPlacement {
        doc /* GVC-007 [layout] four COPV proxies occupy the source cardinal stations and pass through support-ring openings with at least 0.06 m radial clearance from their bands. Stations, tank scale and geometry are packaging estimates documented in griffin-size-evidence.md, not supplier data. */
    }
    requirement def GVC008_EngineAndSkirtDatum {
        doc /* GVC-008 [interface] the seven-engine cluster shall remain visibly below the lower flared bucket and bus; the nozzle axis is a typed downward Direction and must not duplicate flight thrust ownership. Source: Astrobotic identifies seven main engines; bucket and skirt dimensions are visual-study assumptions. */
    }
    requirement def GVC009_RampState {
        doc /* GVC-009 [configuration] the visual review shall use the typed Stowed ramp state while the physical mission scene may command the deployed state after touchdown. Rationale: optional egress ramps are payload interfaces, not the primary landed silhouette. */
    }
    requirement def GVC010_ClearanceAndSymmetry {
        doc /* GVC-010 [verification] body, deck, panels, legs, tanks, engines, and ramps shall be checked for signed symmetry, positive clearances, and no primary-silhouette collision. Rationale: isolated part checks cannot catch cross-component contradictions. */
    }
    requirement def GVC011_Traceability {
        doc /* GVC-011 [evidence] selected configuration assumptions and their reasons/sources shall be available from the separate SysML provenance catalog; geometry itself is verified from typed source values and composed shape, not scene-side text tags. */
    }
    requirement def GVC012_FrameRails {
        doc /* GVC-012 [geometry] eight vertical posts and two octagonal frame rings follow the typed stations, railDimensions and frameRingCenterY. Their dimensions are the provisional body reconstruction in griffin-size-evidence.md. */
    }
    requirement def GVC013_SurfaceOrientation {
        doc /* GVC-013 [rendering] every authored frame, skirt, and deck face shall point outward and render single-sided. Verification computes normals from the actual composed mesh. Source: OpenUSD UsdGeomMesh winding convention and the observed Edit-perspective surface issue. Rationale: correct topology is durable; double-sided rendering would only hide bad winding. */
    }
    requirement def GVC014_ParametricProfile {
        doc /* GVC-014 [geometry] outer deck, skirt, and central tank-support perimeters use the eight normalized Cartesian vectors declared once in this configuration, scaled by their typed dimensions. Upper, middle, and lower support planes carry four annular tank collars; open upper and lower eight-sided buckets connect the central structure without covering the tanks. */
    }
    requirement def GVC015_SurfaceAppearance {
        doc /* GVC-015 [appearance] frame, deck, service skirt, avionics, rails, and tank-support features shall take their linear display colors from this configuration. Each color channel shall remain in the [0,1] interval; Rhai and USD material adapters must not duplicate palette literals. */
    }

    requirement <'GVC-001'> gvc001 : GVC001_ConfigurationSelection { subject configuration : GriffinVisualConfiguration; }
    requirement <'GVC-002'> gvc002 : GVC002_FrameAndOrigin { subject configuration : GriffinVisualConfiguration; }
    requirement <'GVC-003'> gvc003 : GVC003_OctagonalAirframe { subject configuration : GriffinVisualConfiguration; }
    requirement <'GVC-004'> gvc004 : GVC004_OctagonalPayloadDeck { subject configuration : GriffinVisualConfiguration; }
    requirement <'GVC-005'> gvc005 : GVC005_LegStations { subject configuration : GriffinVisualConfiguration; }
    requirement <'GVC-006'> gvc006 : GVC006_SolarStations { subject configuration : GriffinVisualConfiguration; }
    requirement <'GVC-007'> gvc007 : GVC007_TankPlacement { subject configuration : GriffinVisualConfiguration; }
    requirement <'GVC-008'> gvc008 : GVC008_EngineAndSkirtDatum { subject configuration : GriffinVisualConfiguration; }
    requirement <'GVC-009'> gvc009 : GVC009_RampState { subject configuration : GriffinVisualConfiguration; }
    requirement <'GVC-010'> gvc010 : GVC010_ClearanceAndSymmetry { subject configuration : GriffinVisualConfiguration; }
    requirement <'GVC-011'> gvc011 : GVC011_Traceability { subject configuration : GriffinVisualConfiguration; }
    requirement <'GVC-012'> gvc012 : GVC012_FrameRails { subject configuration : GriffinVisualConfiguration; }
    requirement <'GVC-013'> gvc013 : GVC013_SurfaceOrientation { subject configuration : GriffinVisualConfiguration; }
    requirement <'GVC-014'> gvc014 : GVC014_ParametricProfile { subject configuration : GriffinVisualConfiguration; }
    requirement <'GVC-015'> gvc015 : GVC015_SurfaceAppearance { subject configuration : GriffinVisualConfiguration; }

    verification def Verify_GriffinVisualConfiguration {
        subject configuration : GriffinVisualConfiguration;
        objective {
            verify gvc001;
            verify gvc002;
            verify gvc003;
            verify gvc004;
            verify gvc005;
            verify gvc006;
            verify gvc007;
            verify gvc008;
            verify gvc009;
            verify gvc010;
            verify gvc011;
            verify gvc012;
            verify gvc013;
            verify gvc014;
            verify gvc015;
        }
    }
}
