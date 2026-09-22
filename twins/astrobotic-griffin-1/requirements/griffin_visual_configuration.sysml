package GriffinVisualConfigurationRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
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
        SolarPanelPort;
        SolarPanelStarboard;
    }
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
        attribute visualReviewGriffinStation : Position = (-2.70, -0.38, 0.0);
        attribute visualReviewFlipStation : Position = (7.0, 1.0, 0.5);

        attribute bodyDimensions : Dimensions = (4.50, 2.00, 4.50);
        attribute bodyMount : Position = (0.0, 3.20, 0.0);
        attribute bodyGroundClearanceM : Real = 0.20;
        attribute lowerSkirtDimensions : Dimensions = (4.10, 0.42, 4.10);
        attribute lowerSkirtCenter : Position = (0.0, -1.02, 0.0);
        attribute deckDimensions : Dimensions = (4.40, 0.16, 4.40);
        attribute deckCenter : Position = (0.0, 1.03, 0.0);
        attribute avionicsDeckDimensions : Dimensions = (3.00, 0.10, 2.20);
        attribute avionicsDeckCenter : Position = (0.0, 1.20, 0.0);

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
        attribute frameRingCenterY : Real[2] = (0.92, -0.92);
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
        attribute solarArrayInstances : GriffinSolarArrayInstanceName[2] =
            ("SolarPanelPort", "SolarPanelStarboard");
        attribute mainEngineInstances : GriffinMainEngineInstanceName[7] =
            ("Engine01", "Engine02", "Engine03", "Engine04", "Engine05", "Engine06", "Engine07");
        attribute railStations : Position[8] =
            ((-1.272, 0.0, 2.17), (1.272, 0.0, 2.17),
             (2.17, 0.0, 1.272), (2.17, 0.0, -1.272),
             (1.272, 0.0, -2.17), (-1.272, 0.0, -2.17),
             (-2.17, 0.0, -1.272), (-2.17, 0.0, 1.272));
        attribute railDimensions : Dimensions = (0.16, 2.00, 0.16);

        /* Separate central tank-support assembly. The four bore centres are
         * derived from tankStations and tankInstances. The polygonal bore
         * radius clears the maximum scaled retention-band envelope by the
         * same 0.06 m study margin used by the tank/frame contract. */
        /* The central perimeter uses outerBodyProfileCoordinates at this
         * separate radius, so both structures share one octagonal profile. */
        attribute tankSupportPerimeterRadiusM : Real = 2.10;
        attribute tankSupportPerimeterSectionM : Real = 0.12;
        attribute tankSupportPlaneCenterYM : Real = 0.0;
        attribute tankSupportOpeningInnerRadiusM : Real = 0.86;
        attribute tankSupportOpeningOuterRadiusM : Real = 1.00;
        attribute tankSupportOpeningSegments : Integer = 16;

        attribute legStations : Position[4] =
            ((2.20, 2.20, 0.0), (-2.20, 2.20, 0.0),
             (0.0, 2.20, 2.20), (0.0, 2.20, -2.20));
        attribute legStationRotationYDeg : Real[4] = (0.0, 0.0, 90.0, 90.0);

        attribute solarStations : Position[2] =
            ((0.0, 3.20, 2.36), (0.0, 3.20, -2.36));
        attribute solarStationRotationXDeg : Real[2] = (90.0, -90.0);
        attribute solarStationRotationZDeg : Real[2] = (0.0, 0.0);
        attribute solarArrayWidthM : Real = 3.70;
        attribute solarArrayDepthM : Real = 2.50;
        attribute solarStandoffM : Real = 0.16;

        /* Four equally spaced cardinal stations give the 1.512 m installed
         * COPV bodies useful scale while keeping their largest 1.548 m bands
         * inside the 4.50 m footprint. At 1.15 m station radius, the bands
         * retain about 0.078 m inter-tank clearance and 0.066 m to the 0.16 m
         * octagonal frame stock. The lower and upper caps retain about 0.04 m
         * and 0.18 m skirt/deck clearance. Public material confirms four COPVs
         * but publishes no coordinates or dimensions; these are replaceable
         * visual-study assumptions. */
        attribute tankStations : Position[4] =
            ((1.15, 3.20, 0.0), (-1.15, 3.20, 0.0),
             (0.0, 3.20, 1.15), (0.0, 3.20, -1.15));
        attribute tankStationRotationYDeg : Real[4] = (0.0, 0.0, 0.0, 0.0);
        attribute tankScale : Real[4] = (0.90, 0.90, 0.90, 0.90);
        attribute minimumTankInstanceClearanceM : Real = 0.06;
        attribute minimumTankFrameClearanceM : Real = 0.06;

        attribute engineClusterMountYM : Real = 1.68;
        attribute engineBellDirection : Direction = (0.0, -1.0, 0.0);
        attribute engineStations : Position[7] =
            ((0.0, 1.75, 0.0), (1.0, 1.75, 0.0), (-1.0, 1.75, 0.0),
             (0.0, 1.75, 1.0), (0.0, 1.75, -1.0),
             (0.9, 1.75, 0.9), (-0.9, 1.75, -0.9));
    }

    requirement def GVC001_ConfigurationSelection {
        doc /* GVC-001 [configuration] the review model shall identify the landed polar side-array configuration and stowed ramp state with SysML enumerations, keeping optional deployed egress geometry out of the primary silhouette. Source: Astrobotic Griffin product material and NASA/Astrobotic Lunar Landers User Guide. */
    }
    requirement def GVC002_FrameAndOrigin {
        doc /* GVC-002 [datum] every component station shall use the declared native Position/Direction assembly frame and origin; this shared frame makes mirror, clearance, and Editor readback checks meaningful. Rationale: the prior diagonal/axis mismatch let the builder and verifier accept different layouts. */
    }
    requirement def GVC003_OctagonalAirframe {
        doc /* GVC-003 [geometry] the primary airframe shall use an open eight-sided clipped-square perimeter with eight corner posts and eight upper plus eight lower perimeter beams. Its 4.50 m x 4.50 m plan envelope and 2.00 m core height are visual-study datums. Lower service skirt, outer deck, and central tank-support plate remain separate features. Public references show a faceted bus but no released structural CAD; member stock and stations are replaceable study assumptions. */
    }
    requirement def GVC004_OctagonalPayloadDeck {
        doc /* GVC-004 [interface] the bus shall expose a separate 4.40 m x 4.40 m x 0.16 m octagonal payload-deck study surface at the upper bus datum. Source: Astrobotic Griffin product description identifies the main payload deck; these dimensions and the visual surface are study assumptions, not a modeled internal isogrid lattice. */
    }
    requirement def GVC005_LegStations {
        doc /* GVC-005 [layout] four leg roots shall occupy mirrored axial X/Z corner stations with local radial rotations and at least 0.20 m body-to-ground visual clearance. Source: Griffin's four shock-absorbing legs; exact station ICD is not public. */
    }
    requirement def GVC006_SolarStations {
        doc /* GVC-006 [layout] two broad solar arrays shall occupy opposite signed-Z side datums with panel faces rotated outward and a 0.16 m standoff. Source: NASA/Astrobotic User Guide describes side-mounted panels for polar Griffin missions. */
    }
    requirement def GVC007_TankPlacement {
        doc /* GVC-007 [layout] exactly four COPV visual proxies shall occupy equally spaced cardinal-axis stations in the Y=3.20 m bus-origin plane. A 0.84 m nominal tank radius at 0.90 assembly scale gives a 1.512 m installed vessel diameter and 1.548 m maximum band diameter. At the typed 1.15 m station radius, bands retain about 0.078 m inter-instance clearance and 0.066 m clearance to the open octagonal frame, exceeding the 0.06 m study minimum; lower/upper cap clearance is approximately 0.04/0.18 m at the skirt and deck. Astrobotic identifies four COPV tanks but publishes no dimensional ICD. The selected vessel envelope and station radius are replaceable visual-study assumptions sized within the roughly 4.5 m Griffin footprint, not flight dimensions. */
    }
    requirement def GVC008_EngineAndSkirtDatum {
        doc /* GVC-008 [interface] the seven-engine cluster and skirt shall remain below the body/deck datum; the nozzle axis is a typed downward Direction and must not duplicate flight thrust ownership. Source: Astrobotic identifies seven main engines; skirt dimensions are visual-study assumptions. */
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
        doc /* GVC-012 [geometry] eight named vertical corner posts shall use the eight typed Position stations and a 0.16 m x 2.00 m x 0.16 m Dimensions envelope. The octagonal frame ring derives eight upper and eight lower members. These remain explicit replaceable visual-study assumptions; the supplier frame ICD is not public. */
    }
    requirement def GVC013_SurfaceOrientation {
        doc /* GVC-013 [rendering] every authored frame, skirt, and deck face shall point outward and render single-sided. Verification computes normals from the actual composed mesh. Source: OpenUSD UsdGeomMesh winding convention and the observed Edit-perspective surface issue. Rationale: correct topology is durable; double-sided rendering would only hide bad winding. */
    }
    requirement def GVC014_ParametricProfile {
        doc /* GVC-014 [geometry] outer deck, skirt, and central tank-support perimeter use the eight normalized Cartesian vectors declared once in this configuration, scaled by their typed dimensions. The central support has four annular, through-opening collars concentric with the tank stations. */
    }
    requirement def GVC015_SurfaceAppearance {
        doc /* GVC-015 [appearance] frame, deck, service skirt, avionics, rails, and tank-support features shall take their linear display colors from this configuration. Each color channel shall remain in the [0,1] interval; Rhai and USD material adapters must not duplicate palette literals. */
    }

    requirement gvc001 : GVC001_ConfigurationSelection { subject configuration : GriffinVisualConfiguration; }
    requirement gvc002 : GVC002_FrameAndOrigin { subject configuration : GriffinVisualConfiguration; }
    requirement gvc003 : GVC003_OctagonalAirframe { subject configuration : GriffinVisualConfiguration; }
    requirement gvc004 : GVC004_OctagonalPayloadDeck { subject configuration : GriffinVisualConfiguration; }
    requirement gvc005 : GVC005_LegStations { subject configuration : GriffinVisualConfiguration; }
    requirement gvc006 : GVC006_SolarStations { subject configuration : GriffinVisualConfiguration; }
    requirement gvc007 : GVC007_TankPlacement { subject configuration : GriffinVisualConfiguration; }
    requirement gvc008 : GVC008_EngineAndSkirtDatum { subject configuration : GriffinVisualConfiguration; }
    requirement gvc009 : GVC009_RampState { subject configuration : GriffinVisualConfiguration; }
    requirement gvc010 : GVC010_ClearanceAndSymmetry { subject configuration : GriffinVisualConfiguration; }
    requirement gvc011 : GVC011_Traceability { subject configuration : GriffinVisualConfiguration; }
    requirement gvc012 : GVC012_FrameRails { subject configuration : GriffinVisualConfiguration; }
    requirement gvc013 : GVC013_SurfaceOrientation { subject configuration : GriffinVisualConfiguration; }
    requirement gvc014 : GVC014_ParametricProfile { subject configuration : GriffinVisualConfiguration; }
    requirement gvc015 : GVC015_SurfaceAppearance { subject configuration : GriffinVisualConfiguration; }

    verification def Verify_GriffinVisualConfiguration {
        subject configuration : GriffinVisualConfiguration;
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
