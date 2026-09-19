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
        HexagonalOpenFrame;
    }
    enum def GriffinRampReviewState {
        Stowed;
        Deployed;
    }
    enum def GriffinFrameRailNode {
        FrameRailFront;
        FrameRailRear;
        FrameRailPortFront;
        FrameRailPortRear;
        FrameRailStarboardFront;
        FrameRailStarboardRear;
    }
    enum def GriffinOpenBayPanelNode {
        HexPanelFrontRight;
        HexPanelRightRear;
        HexPanelRearRight;
        HexPanelRearLeft;
        HexPanelLeftFront;
        HexPanelFrontLeft;
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
        attribute bodyProfile : GriffinBodyProfile = "HexagonalOpenFrame";
        attribute rampState : GriffinRampReviewState = "Stowed";

        /* Canonical assembly frame: SI metres, Y-up, right-handed. */
        attribute origin : Position = (0.0, 0.0, 0.0);
        attribute axisUp : Direction = (0.0, 1.0, 0.0);
        attribute axisPort : Direction = (-1.0, 0.0, 0.0);
        attribute axisForward : Direction = (0.0, 0.0, 1.0);

        attribute bodyDimensions : Dimensions = (4.50, 2.00, 4.50);
        attribute bodyMount : Position = (0.0, 3.20, 0.0);
        attribute bodyGroundClearanceM : Real = 0.20;
        attribute lowerSkirtDimensions : Dimensions = (4.10, 0.42, 4.10);
        attribute lowerSkirtCenter : Position = (0.0, -1.02, 0.0);
        attribute deckDimensions : Dimensions = (4.40, 0.16, 4.40);
        attribute deckCenter : Position = (0.0, 1.03, 0.0);
        attribute avionicsDeckDimensions : Dimensions = (3.00, 0.10, 2.20);
        attribute avionicsDeckCenter : Position = (0.0, 1.20, 0.0);

        attribute hexVertexCount : Integer = 6;
        attribute hexCornerCutRatio : Real = 0.25;
        /* Normalized (X, -Z) vertices. CartesianVectorValue is the standard
         * SysML vector datatype; its two coordinates stay a typed native Vec2
         * in the runtime bridge, not nested Real arrays or serialized text. */
        attribute hexProfileCoordinates : CartesianVectorValue[6] =
            ((0.0, -1.0), (1.0, -0.5), (1.0, 0.5),
             (0.0, 1.0), (-1.0, 0.5), (-1.0, -0.5));

        /* The frame uses six upper and six lower perimeter beams. Its exact
         * supplier ICD is not public, so station order and 0.16 m member stock
         * are explicit replaceable visual-study assumptions. */
        attribute framePerimeterStationOrder : Integer[6] = (1, 3, 4, 2, 6, 5);
        attribute frameRingCenterY : Real[2] = (0.92, -0.92);
        attribute frameRingMemberCount : Integer = 12;
        attribute frameRingSectionM : Real = 0.16;
        attribute frameOpenBayPanels : GriffinOpenBayPanelNode[6] =
            ("HexPanelFrontRight", "HexPanelRightRear", "HexPanelRearRight",
             "HexPanelRearLeft", "HexPanelLeftFront", "HexPanelFrontLeft");

        attribute frameRails : GriffinFrameRailNode[6] =
            ("FrameRailFront", "FrameRailRear", "FrameRailPortFront",
             "FrameRailPortRear", "FrameRailStarboardFront", "FrameRailStarboardRear");
        attribute tankInstances : GriffinTankInstanceName[4] =
            ("TankPX", "TankNX", "TankPZ", "TankNZ");
        attribute landingLegInstances : GriffinLandingLegInstanceName[4] =
            ("LegPX", "LegNX", "LegPZ", "LegNZ");
        attribute solarArrayInstances : GriffinSolarArrayInstanceName[2] =
            ("SolarPanelPort", "SolarPanelStarboard");
        attribute mainEngineInstances : GriffinMainEngineInstanceName[7] =
            ("Engine01", "Engine02", "Engine03", "Engine04", "Engine05", "Engine06", "Engine07");
        attribute railStations : Position[6] =
            ((0.0, 0.0, 2.178502), (0.0, 0.0, -2.178502),
             (2.17, 0.0, 1.089251), (2.17, 0.0, -1.089251),
             (-2.17, 0.0, 1.089251), (-2.17, 0.0, -1.089251));
        attribute railDimensions : Dimensions = (0.16, 2.00, 0.16);

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

        attribute tankStations : Position[4] =
            ((1.55, 4.25, -1.42), (-1.55, 4.25, -1.42),
             (1.55, 4.25, 1.42), (-1.55, 4.25, 1.42));
        attribute tankStationRotationYDeg : Real[4] = (0.0, 0.0, 0.0, 0.0);
        attribute tankScale : Real[4] = (0.78, 0.78, 0.78, 0.78);
        attribute tankSeatClearanceM : Real = 0.04;

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
    requirement def GVC003_HexagonalAirframe {
        doc /* GVC-003 [geometry] the primary airframe shall be an open six-sided frame: six individually inspectable vertical corner posts and six upper plus six lower perimeter beams, leaving six open side bays around the payload/equipment. Its member outside faces define a 4.50 m x 4.50 m plan envelope and a 2.00 m core-frame height; the lower service skirt and upper deck remain separate. Source: public Griffin product and supplied reference imagery show a faceted structural bus, but not released structural CAD. Rationale: an open frame exposes real subsystem placement and avoids the opaque invented prism; the 0.16 m study section and assembly stations are replaceable assumptions, not an unpublished ICD. */
    }
    requirement def GVC004_IsogridDeck {
        doc /* GVC-004 [interface] the bus shall expose a separate 4.40 m x 4.40 m x 0.16 m isogrid deck at the upper bus datum. Source: Astrobotic Griffin product description identifies the main isogrid payload deck; dimensions are visual-study assumptions. */
    }
    requirement def GVC005_LegStations {
        doc /* GVC-005 [layout] four leg roots shall occupy mirrored axial X/Z corner stations with local radial rotations and at least 0.20 m body-to-ground visual clearance. Source: Griffin's four shock-absorbing legs; exact station ICD is not public. */
    }
    requirement def GVC006_SolarStations {
        doc /* GVC-006 [layout] two broad solar arrays shall occupy opposite signed-Z side datums with panel faces rotated outward and a 0.16 m standoff. Source: NASA/Astrobotic User Guide describes side-mounted panels for polar Griffin missions. */
    }
    requirement def GVC007_TankPlacement {
        doc /* GVC-007 [layout] four compact tank render proxies shall remain below the upper visual silhouette, seated near the deck with mirrored stations and 0.04 m seat clearance. Source: supplied Griffin imagery shows deck-mounted pressure-vessel hardware; exact vessel ICD is not public, so dimensions and stations are replaceable study assumptions. */
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
        doc /* GVC-012 [geometry] six named Y-axis rails shall use the six typed Position stations and a 0.16 m x 2.00 m x 0.16 m Dimensions envelope; their outside faces define the 4.50 m bus footprint. Rationale: the four vertical members at X=±2.17 m plus 0.08 m half-section set the 4.50 m X envelope. For each sloped perimeter beam, its normal contributes about 0.07150 m to the Z envelope, so the end stations use |Z|=2.178502 m and the intermediate stations |Z|=1.089251 m to close the same 4.50 m envelope. The 2.00 m rail spans -1.00 m to +1.00 m and intersects the deck/skirt joints. Supplier frame ICD is not public; these remain explicit visual-study assumptions. */
    }
    requirement def GVC013_SurfaceOrientation {
        doc /* GVC-013 [rendering] every authored frame, skirt, and deck face shall point outward and render single-sided. Verification computes normals from the actual composed mesh. Source: OpenUSD UsdGeomMesh winding convention and the observed Edit-perspective surface issue. Rationale: correct topology is durable; double-sided rendering would only hide bad winding. */
    }
    requirement def GVC014_ParametricProfile {
        doc /* GVC-014 [geometry] the six-sided deck and skirt profile shall use the six normalized Cartesian vector vertices declared in this configuration, scaled by each component's typed Dimensions and extruded by its typed Y thickness. Rationale: a single native profile and a shared outward-winding extrusion avoid hand-maintained point/index arrays drifting between body subsystems. The normalized coordinates are a replaceable geometric assumption, while dimensional envelopes remain explicit SysML requirements. */
    }

    requirement gvc001 : GVC001_ConfigurationSelection { subject configuration : GriffinVisualConfiguration; }
    requirement gvc002 : GVC002_FrameAndOrigin { subject configuration : GriffinVisualConfiguration; }
    requirement gvc003 : GVC003_HexagonalAirframe { subject configuration : GriffinVisualConfiguration; }
    requirement gvc004 : GVC004_IsogridDeck { subject configuration : GriffinVisualConfiguration; }
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
    }
}
