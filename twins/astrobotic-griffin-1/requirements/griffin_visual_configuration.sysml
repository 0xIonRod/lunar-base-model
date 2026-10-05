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
        // Flat review datum: unloaded feet use the prismatic spring rest
        // pose and all physics is disabled. Live terrain contact belongs to
        // griffin_1_surface_ops, which is the Twin default. See size evidence.
        attribute visualReviewGriffinStation : Position = (0.0, 0.44, 0.0);
        // FLIP is mounted on the payload adapter. Its wheel bottoms (station
        // -0.05 m minus 0.45 m tire radius) meet the adapter top at 2.84 m.
        // This station is the one review-scene placement source.
        attribute visualReviewFlipStation : Position = (0.0, 3.78, 0.0);

        /* SIZE ESTIMATE, 2026-09-30; rationale and uncertainties are in
         * requirements/griffin-size-evidence.md. NASA MSS 2024, slide 8
         * (https://ntrs.nasa.gov/citations/20240004236) labels the older
         * VIPER-configured vehicle envelope 4.5 m by 2.0 m, not its bus.
         * Estimate the bus at 80% of that lateral envelope (3.6 +/-0.4 m).
         * Current hardware photo https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/
         * motivates a taller payload surface; the revised 3.28 +/-0.5 m study datum, excluding
         * its ground handling stand. Body belt height 0.72 +/-0.12 m and all internal
         * support coordinates below are packaging estimates, not metrology.
         * A 0.44 m vehicle touchdown datum plus adapter Y=2.80 and half its
         * 0.08 m thickness gives the revised 3.28 m ground-to-payload height. */
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
         * Keep the body top at vehicle Y=1.70 and payload top Y=2.84;
         * the shallower belt therefore moves upward rather than moving ramps.
         * This older artist impression is a user-selected silhouette basis;
         * it is not a claim of June 2026 as-built panel geometry. */
        attribute bodySideFaceAspectRatio : Real = 3.0;
        attribute bodySideFaceAspectRatioTolerance : Real = 0.35;
        attribute bodySkinThicknessM : Real = 0.025;
        attribute bodySkinEdgeMarginM : Real = 0.04;
        attribute bodySkinDisplayColor : Real[3] = (0.65, 0.66, 0.64);
        /* Thin gold edge tape is visible in the PGH hardware photo:
         * https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png .
         * Estimate 10 mm width and 1 mm presentation offset, because the image
         * has no calibrated scale. Strips follow the composed exterior facet
         * perimeter; they do not assign a blanket stack or thermal properties.
         * Linear RGB is a replaceable appearance estimate. */
        attribute blanketEdgeTapeWidthM : Real = .010;
        attribute blanketEdgeTapeOffsetM : Real = .001;
        attribute blanketEdgeTapeDisplayColor : Real[3] = (.55, .36, .05);
        /* Standard UsdPreviewSurface presentation parameters. ESA/Astrobotic
         * reference renderings show pale exterior panels
         * and silver ramp/leg members. These linear RGB colors, metallic and
         * roughness values are artistic estimates; they are not measured
         * optical properties, alloy definitions or a released blanket stack.
         * Source: https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander
         * and https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ . */
        attribute silverDisplayColor : Real[3] = (.55, .58, .62);
        attribute silverMetallic : Real = .75;
        attribute silverRoughness : Real = .42;
        /* Silver exterior blanket appearance, 2026-10-03. Crumpled silver
         * surfaces and narrow gold edge tape are visible in the hardware photo:
         * https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png .
         * Reuse LunCoSim's mli_foil shader with bodySkinDisplayColor as the
         * bright color. Valley RGB (.58,.59,.57), contrast .65 and sheen .10
         * retain broad silver reflections in the shared foil shader. The low
         * sheen avoids nearly black grazing faces in inspection lighting. Density 26
         * per metre gives centimetre-scale shading detail on the 0.72 m belt;
         * axial scale 1 keeps the object-space pattern isotropic. These are
         * artistic estimates from an uncalibrated photograph, not measured
         * reflectance, thermal properties, blanket construction or wrinkles
         * in the actual mesh. Shader inputs narrow only at the GPU boundary. */
        attribute busFoilValleyColor : Real[3] = (.58, .59, .57);
        attribute busFoilCrinkleDensity : Real = 26.0;
        attribute busFoilFacetContrast : Real = .65;
        attribute busFoilSheen : Real = .10;
        attribute busFoilAxialPatternScale : Real = 1.0;
        attribute bodyGroundClearanceM : Real = 0.20;
        attribute lowerSkirtDimensions : Dimensions = (3.40, 0.24, 3.40);
        attribute lowerSkirtCenter : Position = (0.0, -0.36, 0.0);
        /* Apply the same estimated 80 mm stock to the upper perimeter deck
         * ring. Raise its center 40 mm to retain the original top surface:
         * bus-local .41 + .08/2 = .45 m. This reduces the opaque band below
         * that surface without altering its physical support elevation. */
        attribute deckDimensions : Dimensions = (3.50, 0.08, 3.50);
        attribute deckCenter : Position = (0.0, 0.41, 0.0);
        /* Griffin high-gain dish: PUG August 2021 v5.02 p.30 labels a dish
         * at the bus edge. Reuse the parked shared antenna mechanism. Its
         * default 0.58 m reflector radius times the estimated 0.60 head scale
         * yields 0.696 m diameter, roughly one fifth of this 3.60 m bus.
         * 180 mm mast and 70 degree parked tilt are packaging estimates;
         * they are not supplier CAD or Earth-pointing acceptance. The mount
         * derives from the top deck elevation and midline of its perimeter
         * stock at negative Z, clear of FLIP's +/-1 m track stations.
         * Source: https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf */
        attribute highGainMastHeightM : Real = .18;
        attribute highGainMastRadiusM : Real = .025;
        attribute highGainHeadScale : Real = .60;
        attribute highGainParkedTiltDeg : Real = -70.0;
        /* Flat medium-gain panel inferred from PUG v5.02 pp20/30, rather
         * than another dish. Griffin-specific size is unpublished. The
         * 320x280x40 mm enclosure is a small visible panel study estimate;
         * 120 mm square, 35 mm deep mounting block gives a compact standoff.
         * X station is 22% of bus width to keep it on the straight rear face;
         * its upper edge aligns with the body skin top and its bracket seats
         * on the negative-Z body boundary plus the authored skin thickness. This mounting/parked orientation
         * is a reconstruction, not a supplier interface or gain pattern.
         * Near-white radome color is an appearance estimate from the guide,
         * not an RF material or measured optical property.
         * https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf */
        attribute mediumGainPanelDimensions : Dimensions = (.32, .28, .04);
        attribute mediumGainBracketDimensions : Dimensions = (.12, .12, .035);
        attribute mediumGainMountWidthFraction : Real = .22;
        attribute mediumGainRadomeDisplayColor : Real[3] = (.90, .90, .87);

        /* Rear inner-face electronics shelf. The old central 2.00 x 1.46 m
         * shelf and 0.72 m box crossed tank domes and the upper central shell.
         * The rear bay at Z=-1.58 avoids the four cardinal COPV envelopes;
         * the box bottom sits on the shelf top. Shelf and rack dimensions are
         * explicit packaging estimates, not a vendor electronics drawing.
         * References: PUG v5.02 pp.25-26 internal structure and June 2026
         * hardware, https://www.nasa.gov/gallery/astrobotics-griffin-1/ . */
        attribute avionicsPodDimensions : Dimensions = (.72, .36, .12);
        attribute avionicsDeckDimensions : Dimensions = (.80, .05, .16);
        attribute avionicsDeckCenter : Position = (0.0, -.205, -1.58);

        /* Linear scene-referred display colors are visual design parameters;
         * Rhai consumes these values but does not define a second palette. */
        /* Exposed aluminum frame appearance, revised 2026-10-03.
         * Astrobotic describes an aluminum frame:
         * https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ .
         * Silver members are visible in the hardware photograph:
         * https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png .
         * Reuse the source silver palette and metallic/roughness controls for
         * perimeter, payload frame, rails and service-skirt members. This
         * replaces the unsourced dark-blue finish, not geometry or mass.
         * Color and finish remain display estimates, not alloy qualification,
         * measured reflectance or the as-built coating specification. */
        attribute avionicsDeckDisplayColor : Real[3] = (0.10, 0.13, 0.17);
        attribute avionicsPodDisplayColor : Real[3] = (0.22, 0.25, 0.29);
        attribute tankSupportDisplayColor : Real[3] = (0.12, 0.15, 0.19);
        attribute tankCollarDisplayColor : Real[3] = (0.24, 0.28, 0.34);
        /* Tank blanket appearance follows the visibly crumpled gold wraps in
         * https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png
         * and https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander.
         * These are illustrative sources, not measured optical properties.
         * Reuse LunCo's object-space mli_foil shader: density 32 per metre
         * gives roughly 31 mm pattern cells; equal axial/radial pattern scale
         * avoids elongated smooth bands. Full facet contrast and a darker
         * valley color make folds legible at assembly distance. All colors,
         * contrast and sheen are artistic estimates, not blanket thickness,
         * insulation performance, absorptance or infrared emittance. */
        attribute tankFoilBrightColor : Real[3] = (.83, .62, .18);
        attribute tankFoilValleyColor : Real[3] = (.18, .13, .04);
        attribute tankFoilCrinkleDensity : Real = 32.0;
        attribute tankFoilFacetContrast : Real = 1.0;
        attribute tankFoilSheen : Real = .85;
        attribute tankFoilAxialPatternScale : Real = 1.0;


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

        /* Central eight-sided upper and lower adapter shells stay inside the tank and engine envelopes. The former 3.08 m top span crossed the four tank columns and peripheral nozzles. The revised 0.54 m upper diameter, 1.28 m lower maximum diameter and 25 mm shell thickness are packaging estimates, not supplier CAD. Source: central adapter architecture in Astrobotic Payload User Guide (August 2021 v5.02), pp.25-26, https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf. Their diameters are limited by this study tank/engine stations and clearances; no public dimensions calibrate them. Upper and lower buckets bridge the central structure;
         * neither shell crosses the four COPV columns. These are replaceable
         * presentation assumptions because the supplier structural ICD is
         * not public. */
        attribute centralBucketSegments : Integer = 8;
        attribute centralBucketShellThicknessM : Real = .025;
        attribute upperBucketInnerBottomRadiusM : Real = .215;
        attribute upperBucketOuterBottomRadiusM : Real = .24;
        attribute upperBucketInnerTopRadiusM : Real = .245;
        attribute upperBucketOuterTopRadiusM : Real = .27;
        attribute upperBucketBottomCenterYM : Real = .45;
        attribute upperBucketTopCenterYM : Real = 1.34;
        attribute lowerBucketInnerTopRadiusM : Real = .615;
        attribute lowerBucketOuterTopRadiusM : Real = .64;
        attribute lowerBucketInnerBottomRadiusM : Real = .555;
        attribute lowerBucketOuterBottomRadiusM : Real = .58;
        attribute lowerBucketTopCenterYM : Real = -0.46;
        attribute lowerBucketBottomCenterYM : Real = -0.58;
        /* The former 160 mm square-stock payload frame dominated the upper
         * silhouette and hid tank domes. Use 80 mm stock as an explicit visual
         * estimate (not load-qualified supplier sizing), informed by the slender
         * open structure in https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ .
         * Preserve the wheel contact top: center 2.80 + .08/2 = 2.84 m.
         * The visible frame and its contact proxy must change together. */
        attribute payloadAdapterDimensions : Dimensions = (3.20, .08, 3.20);
        /* Retain the existing 1.30 m square central payload interface footprint;
         * align its thickness with the 80 mm walking frame. This is a simulator
         * interface estimate, not a released FLIP attachment drawing. Two
         * orthogonal 80 mm crossmembers beneath it connect the four cardinal
         * columns and the central upper shell. Column ends derive from the
         * bus-deck top and payload-frame underside, avoiding the tank domes.
         * The upper-shell bottom Y=.45 meets the bus-deck top; its top Y=1.34
         * equals 2.80 - bodyMount.y(1.34) - 1.5*.08, meeting the crossmember
         * underside. Its radii remain the previous clearance-constrained study
         * envelope. All added members are render-only within the lander's mass
         * owner; this reconstruction does not qualify their structural strength.
         * Architecture reference: Astrobotic PUG v5.02 pp.25-26,
         * https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf . */
        attribute payloadInterfacePlateDimensions : Dimensions = (1.30, .08, 1.30);
        /* The former Y=2.08 m walking top was below the 2.714577 m tall-panel
         * top, making folded ramps and rover egress intersect the array.
         * Y=2.84 m preserves 125 mm of top clearance as a packaging estimate.
         * Raise the rover/deck/ramp interfaces together and provide supports.
         * This supersedes the earlier 2.52 m landed height; photos establish
         * relative placement, not this dimension. Source, 2026-10-05:
         * https://www.nasa.gov/gallery/astrobotics-griffin-1/ . */
        attribute payloadAdapterCenterYM : Real = 2.80;
        // Presentation focus is the hosted rover interface top, derived from
        // the same packaging estimate as the adapter; not a supplier datum.
        // Rhai derives center Y + native Dimensions.y / 2; indexed SysML
        // initializers are not currently evaluated by the source bridge.

        /* Correct the upper leg mount to the lower body edge, per the user's
         * Astrobotic rendering: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/
         * and https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR2r1xQLuK9FVl67Bpt2FkrW5JXaLk0HFu78gfflGo-r32Rt636APG830o&s=10.
         * Sleeve center Y=.90 = body center 1.34 - belt height .72/2
         * - sleeve radius .08. Thus sleeve top meets body bottom .98.
         * This is a reference-informed packaging estimate, not measured CAD.
         * Shift the shared physics/visual root down .30 m and compensate the
         * local foot datums to preserve the previous terrain contact. */
        attribute legStations : Position[4] =
            ((1.90, .90, 1.90), (-1.90, .90, -1.90),
             (-1.90, .90, 1.90), (1.90, .90, -1.90));
        /* Each local +X axis points radially outward. This gives the shared
         * leg mount interface one canonical orientation at every chamfered corner.
         * The legacy PX/NX/PZ/NZ instance names are retained as stable IDs,
         * rather than treated as placement directions. Feet at (+/-1.90,
         * +/-1.90) preserve the estimated 4.50 m X/Z envelope including pads.
         * Primary upper anchors meet chamfer midpoints; legs splay outward. */
        attribute legStationRotationYDeg : Real[4] = (-45.0, 135.0, -135.0, 45.0);

        /* The three panel instances occupy consecutive forward, diagonal,
         * and starboard bus faces in the mission Sun quadrant. Stations and
         * orientations use lander coordinates; rail stations are Bus-local.
         * The diagonal station follows the beveled octagonal face normal.
         * Each pair maps local panel -X then +X to the corresponding rails.
         * Panel width derives from each rail pair's spacing minus the common
         * edge clearance; the component's maximum width is owned by GSA. */
        /* Diagonal center = mean of adjacent rail X/Z (1.364 m) plus
         * 0.22/sqrt(2), so all three arrays share the same local bracket
         * depth as the axial station (1.94 - 1.72 = 0.22 m). This is a
         * mount-closure derivation, not an image measurement. */
        /* 2026-10-04: one Sun-facing quadrant follows the 2021
         * Astrobotic rendering https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png .
         * Stations and 220 mm standoff remain installation estimates;
         * no opposite hidden-face coverage or flight ICD is inferred. */
        attribute solarStations : Position[3] =
            ((0.0, 1.34, 1.94), (1.519563492, 1.34, 1.519563492), (1.94, 1.34, 0.0));
        attribute solarMountRails : GriffinFrameRailNode[6] =
            ("FrameRailFrontPort", "FrameRailFrontStarboard",
             "FrameRailFrontStarboard", "FrameRailStarboardFront",
             "FrameRailStarboardFront", "FrameRailStarboardRear");
        /* X is panel tilt; negative signed Z values below name the clockwise
         * plan bearing, not a literal USD rotateXYZ triple. The authored
         * quaternion composes Y(-bearing) after local X(tilt), keeping all
         * panels upright and their normal on the intended octagonal face. */
        attribute solarStationRotationXDeg : Real[3] = (90.0, 90.0, 90.0);
        attribute solarStationRotationZDeg : Real[3] = (0.0, -45.0, -90.0);
        attribute solarArrayEdgeClearanceM : Real = 0.15;

        /* Four tank stations and 0.60 instance scale are packaging estimates.
         * The 1.39 m center exposes approximately 0.23 m of spherical dome above
         * the 1.66 m skin top, following the exposed-domes silhouette of
         * https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander.
         * Dome exposure is limited by the FLIP support-frame underside.
         * The upper cap now has 94 mm vertical clearance below the slimmer
         * payload rails; the previous 160 mm stock left only 14 mm. This explicit packing
         * estimate also leaves a
         * positive lower-neck support span above the source-derived cradle.
         * Their largest band radius is approximately 0.516 m, so 0.58 m
         * support openings retain over 0.06 m radial clearance. See
         * griffin-size-evidence.md; no supplier tank dimensions are public. */
        attribute tankStations : Position[4] =
            ((0.85, 1.39, 0.0), (-0.85, 1.39, 0.0),
             (0.0, 1.39, 0.85), (0.0, 1.39, -0.85));
        attribute tankStationRotationYDeg : Real[4] = (0.0, 0.0, 0.0, 0.0);
        attribute tankScale : Real[4] = (0.60, 0.60, 0.60, 0.60);
        attribute minimumTankInstanceClearanceM : Real = 0.06;
        attribute minimumTankFrameClearanceM : Real = 0.06;
        // Estimated render/hardware separation from the payload underside.
        attribute minimumTankPayloadClearanceM : Real = 0.01;

        attribute engineClusterMountYM : Real = 0.34;
        attribute engineBellDirection : Direction = (0.0, -1.0, 0.0);
        /* Seven engines: current Astrobotic Griffin product page, accessed
         * 2026-10-03: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ .
         * The August 2021 PUG v5.02 p.26 five-engine configuration is historical.
         * No current mounting drawing is available. One center plus a regular
         * six-engine ring is an explicit symmetric packaging estimate, not
         * supplier geometry. The 1.19 m ring leaves 0.51 m between 0.34 m bell
         * exits, at least 0.11 m to the 3.44 m frame's inner rail edges, and
         * collar clearance below the four estimated tank envelopes and their
         * lower end hardware. Y=0.34 m puts the uppermost collar at 0.76 m,
         * below the tank cradle bottoms at 0.784 m (24 mm separation).
         * The adapter plate occupies Y=0.76..0.88 m. Its frame centers at
         * Y=0.82 m, with rail tops at the lower service-skirt bottom Y=0.86 m.
         * Thus the frame supports the upper engine interface rather than
         * surrounding the bell exits. The lowest exit Y=0.08 m plus the
         * 0.44 m touchdown root elevation leaves 0.52 m ground clearance.
         * Shared aluminum tank-seat/adapter interfaces are structural joins;
         * their geometry is a study proxy, not a released attachment ICD.
         * This visual-only placement does not alter aggregate Modelica thrust
         * or add force actuators. Current thrust/mass calibration remains open.
         */
        attribute engineStations : Position[7] =
            ((0.0, 0.34, 0.0), (1.19, 0.34, 0.0),
             (0.595, 0.34, 1.030570230503), (-0.595, 0.34, 1.030570230503),
             (-1.19, 0.34, 0.0), (-0.595, 0.34, -1.030570230503),
             (0.595, 0.34, -1.030570230503));
    }

    requirement def GVC001_ConfigurationSelection {
        doc /* GVC-001 [configuration] the review model shall identify the landed polar side-array configuration and stowed ramp state with SysML enumerations, keeping optional deployed egress geometry out of the primary silhouette. Include the bus-edge high-gain antenna identified in Astrobotic Payload User Guide August 2021 v5.02 page 30, using the reusable parked mechanism and source-owned study sizing. Its placement derives from the upper deck datum and shall keep the rover tracks clear. The elevated payload mast in the ESA illustration does not establish a Griffin mast size. Antenna operation and Earth pointing are separate future evidence. Source: https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf. */
    }
    requirement def GVC002_FrameAndOrigin {
        doc /* GVC-002 [datum] every component station shall use the declared native Position/Direction assembly frame and origin; this shared frame makes mirror, clearance, and Editor readback checks meaningful. Rationale: the prior diagonal/axis mismatch let the builder and verifier accept different layouts. */
    }
    requirement def GVC003_OctagonalAirframe {
        doc /* GVC-003 [geometry] the primary airframe shall use an open eight-sided clipped-square perimeter with eight posts and upper/lower perimeter beams. Its envelope and member dimensions shall resolve from the typed GriffinVisualConfiguration values; they are low-confidence presentation estimates documented in griffin-size-evidence.md, not supplier dimensions. Separate skirt, payload ring and central supports retain their own geometry. */
    }
    requirement def GVC004_OctagonalPayloadDeck {
        doc /* GVC-004 [interface] the upper bus datum shall expose a source-sized octagonal perimeter deck ring with four tank through-openings; it shall not be a solid plate across the COPV cluster. A raised open payload support frame is supported by four cardinal columns and two crossmembers, with the central upper shell meeting their underside and shall carry the linked FLIP review asset with all four tire bottoms resting on its two wheel-track rails. The perimeter uses the adapter thickness as square-stock section; rails follow FlipRover::wheelStationZ and reuse GriffinEgressRamp::assemblyTrackWidthM as the wheel-width-plus-clearance datum. Rails are clipped to the source octagonal footprint. This is an explicit FLIP packaging estimate; the overall footprint and top elevation stay at the study datums. Astrobotic Payload User Guide (August 2021 v5.02), page 25, shows a central upper cone and large surrounding openings and says the illustrated payload interface is VIPER-specific: https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf. That drawing motivates an open surrounding structure, but does not specify these FLIP rails. The contact realization uses a convex-envelope proxy for this frame, which fills internal gaps; it supports wheel-track contact but is not exact gap-contact geometry. The lander and rover review stations, adapter footprint, and member stock are replaceable study assumptions, not released supplier CAD. */
    }
    requirement def GVC005_LegStations {
        doc /* GVC-005 [layout] four leg roots shall match the ordered typed leg stations and radial rotations. Their pad envelope shall satisfy the source-owned body-to-ground clearance. Exact station and pad geometry remains a replaceable study assumption because the supplier ICD is not public. */
    }
    requirement def GVC006_SolarStations {
        doc /* GVC-006 [configuration] for each solar-array identity, the configuration shall provide one assembly-frame station, panel orientation, and supporting bus-rail mapping. The configured stations shall satisfy the adjacent-side Sun-quadrant relationship defined by GriffinSolarRequirements. */
    }
    requirement def GVC007_TankPlacement {
        doc /* GVC-007 [layout] four COPV proxies occupy the source cardinal stations and pass through support-ring openings while satisfying the typed minimumTankFrameClearanceM radial clearance from their bands. Stations, tank scale and geometry are packaging estimates documented in griffin-size-evidence.md, not supplier data. */
    }
    requirement def GVC008_EngineAndSkirtDatum {
        doc /* GVC-008 [interface] the seven-engine cluster shall remain visibly below the lower flared bucket and bus; the nozzle axis is a typed downward Direction and must not duplicate flight thrust ownership. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ specifies seven engines. Center-plus-six layout, dimensions and mount heights are explicit packaging estimates; no current supplier mounting drawing is available. The earlier PUG five-engine configuration is historical. */
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
        doc /* GVC-015 [appearance] frame, deck, service skirt, avionics, rails, tank blankets, and tank-support features shall take their linear display colors from this configuration. Each color channel shall remain in the [0,1] interval; Rhai and USD material adapters must not duplicate palette literals. */
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
