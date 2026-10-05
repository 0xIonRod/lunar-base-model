package GriffinRampRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import ScalarValues::String;
    private import ScalarValues::Boolean;
    private import FlipRequirements::FlipRover;
    private import FlipCadRequirements::CadStudy;
    private import GriffinRequirementSources::TwinAssetPath;

    enum def GriffinRampSectionIdentity {
        DeckSection;
        MiddleSection;
        ToeSection;
    }

    enum def GriffinRampIntermediateJointIdentity {
        RampSectionHingePort01;
        RampSectionHingePort12;
        RampSectionHingeStarboard01;
        RampSectionHingeStarboard12;
    }
    enum def GriffinRampRootJointIdentity {
        RampHingePort;
        RampHingeStarboard;
    }
    enum def GriffinRampHingeAxis { Z; }
    enum def GriffinRampTreadIdentity { Tread01; Tread02; Tread03; Tread04; }
    enum def GriffinRampRailJointPinIdentity {
        OuterRailJointPin;
        InnerRailJointPin;
        CenterRailPortJointPin;
        CenterRailStarboardJointPin;
    }
    enum def GriffinRampTransitionBodyIdentity { TransitionPlate; }
    enum def GriffinRampTransitionContactIdentity { ContactSurface; }
    enum def GriffinRampTransitionJointIdentity {
        RampTransitionJointPort;
        RampTransitionJointStarboard;
    }

    constraint def GRC005_DeploymentCommandWithinLimit {
        in commandRad : Real;
        in limitRad : Real;
        commandRad >= -limitRad and commandRad <= limitRad;
    }

    constraint def GRC003_WidthClearsFlipWheelEnvelope {
        in rampWidthM : Real;
        in wheelHalfTrackM : Real;
        in wheelHalfWidthM : Real;
        in wheelClearanceM : Real;
        rampWidthM >= 2.0 * (wheelHalfTrackM + wheelHalfWidthM + wheelClearanceM);
    }

    constraint def GRC016_ContactTrackClearsTire {
        in trackWidthM : Real;
        in wheelWidthM : Real;
        in wheelClearanceM : Real;
        trackWidthM >= wheelWidthM + 2.0 * wheelClearanceM;
    }

    constraint def GRC017_ComposedContactTrackMatchesSource {
        in maximumDimensionDeviationM : Real;
        in maximumPlacementDeviationM : Real;
        in toleranceM : Real;
        toleranceM >= 0.0
            and maximumDimensionDeviationM <= toleranceM
            and maximumPlacementDeviationM <= toleranceM;
    }

    constraint def GRC018_SectionedRampMatchesEnvelope {
        in totalLengthM : Real;
        in sectionLengthM : Real;
        in sectionCount : Integer;
        in measuredLengthDeviationM : Real;
        in toleranceM : Real;
        sectionCount > 1 and sectionLengthM > 0.0
            and measuredLengthDeviationM <= toleranceM
            and sectionLengthM * sectionCount >= totalLengthM - toleranceM
            and sectionLengthM * sectionCount <= totalLengthM + toleranceM;
    }

    constraint def GRC019_RampSectionMassPartition {
        in totalMassKg : Real;
        in sectionMassKg : Real;
        in sectionCount : Integer;
        in toleranceKg : Real;
        sectionCount > 1 and sectionMassKg > 0.0 and toleranceKg >= 0.0
            and sectionMassKg * sectionCount >= totalMassKg - toleranceKg
            and sectionMassKg * sectionCount <= totalMassKg + toleranceKg;
    }

    constraint def GRC020_RampSectionInertiaMatchesEnvelope {
        in measuredXKgM2 : Real;
        in measuredYKgM2 : Real;
        in measuredZKgM2 : Real;
        in sectionMassKg : Real;
        in sectionLengthM : Real;
        in outsideWidthM : Real;
        in thicknessM : Real;
        in toleranceKgM2 : Real;
        toleranceKgM2 >= 0.0
            and measuredXKgM2 >= sectionMassKg * (outsideWidthM * outsideWidthM + thicknessM * thicknessM) / 12.0 - toleranceKgM2
            and measuredXKgM2 <= sectionMassKg * (outsideWidthM * outsideWidthM + thicknessM * thicknessM) / 12.0 + toleranceKgM2
            and measuredYKgM2 >= sectionMassKg * (sectionLengthM * sectionLengthM + outsideWidthM * outsideWidthM) / 12.0 - toleranceKgM2
            and measuredYKgM2 <= sectionMassKg * (sectionLengthM * sectionLengthM + outsideWidthM * outsideWidthM) / 12.0 + toleranceKgM2
            and measuredZKgM2 >= sectionMassKg * (sectionLengthM * sectionLengthM + thicknessM * thicknessM) / 12.0 - toleranceKgM2
            and measuredZKgM2 <= sectionMassKg * (sectionLengthM * sectionLengthM + thicknessM * thicknessM) / 12.0 + toleranceKgM2;
    }

    constraint def GRC021_RampTreadCountMatchesSections {
        in totalTreadCount : Integer;
        in treadCountPerSection : Integer;
        in sectionCount : Integer;
        treadCountPerSection > 0
            and sectionCount > 1
            and totalTreadCount == treadCountPerSection * sectionCount;
    }

    constraint def GRC022_RampFlightStowAnglesWithinTravel {
        in rootStowAngleRad : Real;
        in sectionStowRelativeAngleRad : Real;
        in sectionDeploymentRelativeAngleRad : Real;
        in sectionJointFrameOffsetRad : Real;
        in portRootLimitRad : Real;
        in starboardRootLimitRad : Real;
        in sectionLimitRad : Real;
        rootStowAngleRad > 0.0 and rootStowAngleRad <= portRootLimitRad
            and rootStowAngleRad <= starboardRootLimitRad
            and sectionStowRelativeAngleRad > 0.0
            and sectionStowRelativeAngleRad <= sectionLimitRad
            and sectionStowRelativeAngleRad >= -sectionLimitRad
            and sectionStowRelativeAngleRad > sectionDeploymentRelativeAngleRad
            and sectionStowRelativeAngleRad + sectionJointFrameOffsetRad < sectionLimitRad
            and sectionStowRelativeAngleRad + sectionJointFrameOffsetRad > -sectionLimitRad
            and sectionDeploymentRelativeAngleRad + sectionJointFrameOffsetRad < sectionLimitRad
            and sectionDeploymentRelativeAngleRad + sectionJointFrameOffsetRad > -sectionLimitRad;
    }

    constraint def GRC023_RailsRemainOnUpperTrackFace {
        in railCenterYM : Real;
        in railHeightM : Real;
        in walkingSurfaceCenterYM : Real;
        in walkingSurfaceThicknessM : Real;
        in toleranceM : Real;
        railCenterYM - railHeightM / 2.0
            >= walkingSurfaceCenterYM + walkingSurfaceThicknessM / 2.0 - toleranceM;
    }

    constraint def GRC024_RampSectionDeploymentTargetIsLevel {
        in deploymentRelativeAngleRad : Real;
        deploymentRelativeAngleRad == 0.0;
    }

    constraint def GRC025_StowedRailsClearLandingLegEnvelope {
        in lowestStowedRailBottomYM : Real;
        in highestLandingLegTopYM : Real;
        in geometryToleranceM : Real;
        lowestStowedRailBottomYM >= highestLandingLegTopYM + geometryToleranceM;
    }

    constraint def GRC026_SideTrussBracing {
        in braceCountPerSide : Integer;
        in postCountPerSide : Integer;
        in braceThicknessM : Real;
        in lowerChordHeightM : Real;
        in lowerChordCenterYM : Real;
        in upperChordCenterYM : Real;
        in walkingSurfaceCenterYM : Real;
        in walkingSurfaceThicknessM : Real;
        in toleranceM : Real;
        postCountPerSide == 2 and braceCountPerSide > 1
            and braceThicknessM > 0.0
            and lowerChordHeightM > 0.0
            and lowerChordCenterYM - lowerChordHeightM / 2.0
                >= walkingSurfaceCenterYM + walkingSurfaceThicknessM / 2.0 - toleranceM
            and lowerChordCenterYM < upperChordCenterYM;
    }

    constraint def GRC027_RampStowedRootAxesMirror {
        in portForwardX : Real;
        in portForwardY : Real;
        in starboardForwardX : Real;
        in starboardForwardY : Real;
        in tolerance : Real;
        tolerance >= 0.0
            and RealFunctions::abs(portForwardX + starboardForwardX) <= tolerance
            and RealFunctions::abs(portForwardY - starboardForwardY) <= tolerance;
    }

    // A visual-review guard, not a structural strength limit. The image
    // evidence cannot calibrate stock sizes; these explicit estimated bounds
    // reject the earlier thick chords and oversized transverse cylinders.
    constraint def GRC029_PivotFittingsMatchJoint {
        in maximumDatumErrorM : Real;
        in invalidFittingCount : Integer;
        in toleranceM : Real;
        toleranceM >= 0.0 and maximumDatumErrorM <= toleranceM
            and invalidFittingCount == 0;
    }

    constraint def GRC028_RailAndPivotSlenderness {
        in chordHeightM : Real;
        in sectionLengthM : Real;
        in hingeRadiusM : Real;
        in pinRadiusM : Real;
        in maxChordFraction : Real;
        in maxFittingDiameterRatio : Real;
        sectionLengthM > 0.0 and chordHeightM > 0.0
            and hingeRadiusM > 0.0 and pinRadiusM > 0.0
            and chordHeightM <= sectionLengthM * maxChordFraction
            and 2.0 * hingeRadiusM <= chordHeightM * maxFittingDiameterRatio
            and 2.0 * pinRadiusM <= chordHeightM * maxFittingDiameterRatio;
    }

    constraint def GRC010_PhysicalRampReachesTerrain {
        in rampTipTopYM : Real;
        in rampTipBottomYM : Real;
        in terrainSurfaceYM : Real;
        in contactToleranceM : Real;
        contactToleranceM >= 0.0
            and rampTipTopYM >= terrainSurfaceYM - contactToleranceM
            and rampTipTopYM <= terrainSurfaceYM + contactToleranceM
            and rampTipBottomYM >= terrainSurfaceYM - contactToleranceM
            and rampTipBottomYM <= terrainSurfaceYM + contactToleranceM;
    }

    constraint def GRC011_RampMassPropertiesArePositive {
        in massKg : Real;
        in inertiaXKgM2 : Real;
        in inertiaYKgM2 : Real;
        in inertiaZKgM2 : Real;
        massKg > 0.0 and inertiaXKgM2 > 0.0
            and inertiaYKgM2 > 0.0 and inertiaZKgM2 > 0.0;
    }

    constraint def GRC012_ComposedDeckTransitionFit {
        in measuredOverlapM : Real;
        in requiredOverlapM : Real;
        in measuredTransitionLengthM : Real;
        in requiredTransitionLengthM : Real;
        in transitionLengthToleranceM : Real;
        in deckTopStepM : Real;
        in transitionRampTopStepM : Real;
        in interfaceToleranceM : Real;
        in hingeGapM : Real;
        in lateralCoverageM : Real;
        in requiredLateralCoverageM : Real;
        in deckProfileCompatible : Boolean;
        requiredOverlapM > 0.0
            and requiredTransitionLengthM > 0.0
            and transitionLengthToleranceM >= 0.0
            and interfaceToleranceM > 0.0
            and requiredLateralCoverageM > 0.0
            and measuredOverlapM >= requiredOverlapM
            and measuredOverlapM < measuredTransitionLengthM
            and measuredTransitionLengthM >= requiredTransitionLengthM - transitionLengthToleranceM
            and measuredTransitionLengthM <= requiredTransitionLengthM + transitionLengthToleranceM
            and deckTopStepM <= interfaceToleranceM
            and transitionRampTopStepM <= interfaceToleranceM
            and hingeGapM <= interfaceToleranceM
            and lateralCoverageM + interfaceToleranceM >= requiredLateralCoverageM
            and deckProfileCompatible;
    }

    // The ramp is a separately verifiable Griffin subsystem.  The visual and
    // physical study envelopes intentionally use the same full-scale datum so
    // the Editor review cannot show a toy ramp beside the physical egress
    // path. They remain study assumptions until Astrobotic publishes the
    // mechanical ICD.
    part def GriffinEgressRamp {
        doc /* Size/provenance basis: requirements/griffin-size-evidence.md; 5.397252161 m length is calculated from 2.52 m estimated deck height, and 2.86 m width from estimated FLIP track and tire clearance. Griffin provides optional rover egress ramps. Each ramp has its own hinge, actuator-limit, contact geometry, and mass-property assumptions, so it is modeled and verified independently from the bus. Supplier ramp and site interface control data remain unavailable; nonpublic geometry and dynamics values are replaceable Twin study assumptions. */
        attribute componentAsset : TwinAssetPath = "components/lander/griffin_ramp_visual.usda";
        attribute usdRootPath : String = "/World/Griffin1";
        attribute sectionAsset : TwinAssetPath = "components/lander/griffin_ramp_section_visual.usda";
        attribute sectionInstances : GriffinRampSectionIdentity[3] =
            ("DeckSection", "MiddleSection", "ToeSection");
        attribute rootJointInstances : GriffinRampRootJointIdentity[2] =
            ("RampHingePort", "RampHingeStarboard");
        attribute intermediateJointInstances : GriffinRampIntermediateJointIdentity[4] =
            ("RampSectionHingePort01", "RampSectionHingePort12",
             "RampSectionHingeStarboard01", "RampSectionHingeStarboard12");
        attribute treadInstances : GriffinRampTreadIdentity[4] =
            ("Tread01", "Tread02", "Tread03", "Tread04");
        attribute railJointPinInstances : GriffinRampRailJointPinIdentity[4] =
            ("OuterRailJointPin", "InnerRailJointPin",
             "CenterRailPortJointPin", "CenterRailStarboardJointPin");
        attribute transitionBody : GriffinRampTransitionBodyIdentity = "TransitionPlate";
        attribute transitionContact : GriffinRampTransitionContactIdentity = "ContactSurface";
        attribute transitionJoints : GriffinRampTransitionJointIdentity[2] =
            ("RampTransitionJointPort", "RampTransitionJointStarboard");
        attribute rampCount : Integer = 2;
        attribute rampSurfaceLengthM : Real = 5.397252161;
        attribute rampSectionCount : Integer = 3;
        attribute rampSectionGeometryToleranceM : Real = 0.002;
        attribute rampSectionLengthM : Real = 1.799084054;
        // This is the outside-to-outside rail envelope. The wheel-contact
        // surfaces are two narrower tracks centered on FLIP's source-owned
        // wheel stations; track width is wheel width plus twice the clearance.
        // Keep this package's value equal to that derived interface datum;
        // it is still a visual study value, not a supplier mechanical ICD.
        /* 2026-10-01 consistency correction: derive the outside rail span
         * from its actual outer edges. Retained 2.86 m belonged to 140 mm
         * rails; the image-based 6 mm web now gives 2.592 m. Wheel spacing,
         * track clearance and stock rationale are unchanged. Inertia remains
         * an unqualified rectangular-envelope proxy using this current span. */
        attribute rampSurfaceWidthM : Real = 2.0 *
            (GriffinEgressRamp::rampRailOffsetZM + GriffinEgressRamp::rampRailWidthM / 2.0);
        attribute rampWheelClearanceM : Real = 0.15;
        /* Walking plate reconstruction: 30 mm instead of the legacy 180 mm
         * slab; traction strips 60 mm wide / 10 mm high instead of 120/50 mm.
         * These are explicit visual estimates from the slender ramp appearance
         * in https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander
         * and https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ .
         * No supplier plate gauge or load capacity is known. Geometry/contact
         * use the same plate thickness. Hinge offsets and toe miter derive
         * from half-thickness and deployment slope; deck/terrain tops remain
         * fixed. Retain the unqualified 95 kg ramp / 15 kg transition proxy
         * masses and recompute their rectangular-envelope inertias. */
        attribute rampSurfaceThicknessM : Real = 0.030000000000;
        /* Slimmer truss silhouette estimated from the ESA 2022 Griffin artist
         * impression and Astrobotic product rendering, linked in
         * griffin-size-evidence.md. 0.20 m walking-plane-to-chord-top versus
         * 1.799 m section length gives depth/length 0.11; prior 0.81 m gave
         * 0.45 and resembled a large handrail. These are render structural
         * proxies, not strength-qualified stock. Ramp mount, length, angle,
         * walking contact and width datums remain unchanged. */
        /* Rail-section reconstruction, 2026-09-30, user review of fat rails:
         * ESA 2022 image: https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander
         * Astrobotic rendering: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/
         * Both show slender triangulated webs and compact pivot fittings.
         * Neither gives stock dimensions. Chords are estimated at 40 mm
         * (~2.2% of the 1.799 m section length); finer web members are
         * estimated below using the selected rendering's shorter lattice bays.
         * 50 mm common hinge diameter avoids the previous oversized
         * 240 mm transverse barrels; local pins are refined below. These are visual
         * estimates, not calibrated measurements or strength-qualified stock.
         * Under-beam top derives from the revised plate bottom: -.015 m = -.0375+.045/2.
         * Keep walking contact, span, hinge axes and section poses unchanged.
         */
        // Explicit review bounds: chord <=3% section length, fittings <=1.5x
        // chord depth. Selected to preserve the image's slender silhouette.
        attribute maxRailHeightToSectionLength : Real = 0.03;
        attribute maxPivotDiameterToRailHeight : Real = 1.5;
        /* Upper-strip end profile, 2026-10-01: the ESA and Astrobotic
         * renderings show compact rounded tips rather than square protruding
         * blocks. Use semicircular ends with radius half the existing strip
         * height, retaining its length, height, web thickness and centre.
         * This is a low-confidence presentation estimate; the images do not
         * disclose the cut profile, bearings or qualified structural gauge.
         * https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander
         * https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png */
        attribute rampRailHeightM : Real = 0.04;
        /* Side-web refinement, 2026-10-01: the selected Astrobotic artist
         * rendering shows thin, plate-like triangulated sides, rather than
         * square-section fence posts. Estimate a common 6 mm transverse web
         * thickness (0.33% of the 1.799 m section length), 40 mm upper strip,
         * 20 mm lower strip and 12 mm in-plane diagonals. Uprights and both
         * chords share the same transverse thickness, leaving triangular
         * openings. The rendered stock gauge cannot be measured from this
         * oblique image; 6 mm is a low-confidence silhouette reconstruction,
         * not a supplier thickness or structural sizing calculation.
         * https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png
         * https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander
         * Post embedment ends at the track midplane; its transverse edge meets
         * the track edge. The top chord/fold datum and wheel clearance persist.
         * Local pins remain estimated 40 mm diameter by 60 mm long. */
        attribute rampRailWidthM : Real = 0.006;
        /* Two guide edges per track. Guide inner faces meet the physical
         * track edges, retaining the source tire clearance. Centre-side
         * guides mirror the outside ones around the wheel station. The old
         * outside guides sat 50 mm away from the tracks, leaving unsupported
         * posts. Posts share the guide thickness and meet the plate edge.
         * This paired-track topology is informed by the two-sided lattice
         * tracks in https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png ;
         * member stock and attachments remain unqualified study estimates. */
        attribute rampRailOffsetZM : Real = CadStudy::trackMm / (2.0 * CadStudy::millimetresPerMetre) + GriffinEgressRamp::assemblyTrackWidthM / 2.0 + GriffinEgressRamp::rampRailWidthM / 2.0;
        attribute rampCenterRailOffsetZM : Real = CadStudy::trackMm / (2.0 * CadStudy::millimetresPerMetre) - GriffinEgressRamp::assemblyTrackWidthM / 2.0 - GriffinEgressRamp::rampRailWidthM / 2.0;
        attribute rampRailJointPinRadiusM : Real = 0.020;
        attribute rampRailJointPinLengthM : Real = 0.06;
        /* Pivot reconstruction, 2026-10-04: the 60 mm circular tongue
         * and its 40 mm pin sit on each native section hinge axis, leaving
         * 10 mm radial stock. The tongue is 10 mm thick. Each intermediate
         * parent section carries two fork cheeks of rampRailWidthM stock;
         * their Z offsets are +/-(tongue thickness + cheek thickness)/2.
         * This seats the tongue between the cheeks without overlapping it.
         * Parent and child plates use physics:localPos0 and localPos1;
         * they follow their existing section bodies with no added collider,
         * mass, motor, joint or independent animation. The old full-height
         * lugs incorrectly stretched from track bottom to guard top.
         * Circular plate shape and stock are low-confidence study estimates,
         * not a machined bearing design. Images establish three folding
         * sections and compact interfaces, but no bearing ICD or released
         * deployment sequence. Astrobotic's stowed 2021 configuration is
         * the selected layout; ESA's 2022 artist impression is a different
         * partly-open pose, not a commanded unfolding trajectory:
         * https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png
         * https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/
         * https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander */
        attribute rampPivotLugWidthM : Real = 0.06;
        attribute rampPivotLugThicknessM : Real = 0.010;
        // Separate traction bars on each wheel track leave the centre open.
        // Count and pitch are visual study assumptions because Astrobotic has
        // not published the Griffin ramp tread ICD.
        attribute assemblyTreadCount : Integer = 12;
        attribute assemblyTreadCountPerSection : Integer = 4;
        attribute assemblyTreadWidthM : Real = 0.060000000000;
        attribute assemblyTreadHeightM : Real = 0.010000000000;
        // Source-owned track width; GRC016 constrains it against FLIP's wheel
        // width and the required clearance. Geometry builders use this value.
        // Derive the exact source interface instead of rounding a duplicate
        // decimal; .28 + 2*.15 can differ from literal .58 in f64 arithmetic.
        attribute assemblyTrackWidthM : Real = FlipRover::wheelWidthM + 2.0 * GriffinEgressRamp::rampWheelClearanceM;
        attribute contactTrackGeometryToleranceM : Real = 0.002;
        attribute assemblyTreadFirstCenterXM : Real = 0.224885507;
        attribute assemblyTreadPitchM : Real = 0.449771013;
        // A full-scale ramp needs a visible load path below the walking
        // surface. These are presentation-level structural proxies, not a
        // supplier drawing. Two longitudinal beams sit just below the deck.
        // The source-owned section geometry uses two underside beams and two end
        // upright posts per edge rail on every rigid ramp section.
        attribute assemblyUnderBeamWidthM : Real = 0.06;
        attribute assemblyUnderBeamHeightM : Real = 0.045;
        attribute assemblyUnderBeamCenterYM : Real = -0.037500000000;
        attribute assemblyUnderBeamCenterOffsetZM : Real = 1.20;
        /* Web topology review, 2026-10-01: interpret the triangular openings
         * in the selected Astrobotic 2021 rendering as a continuous zigzag
         * web with end posts, rather than adding an upright in every bay.
         * Twelve equal diagonal bays across 1.799 m give about 150 mm pitch;
         * this count is a low-confidence visual estimate. Lower-strip bottom
         * is derived to meet the track top, eliminating the unsupported gap.
         * 12 mm end posts/diagonals and 20 mm lower strips are in-plane
         * silhouette estimates. No structural load capacity is claimed.
         * https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png */
        attribute assemblySidePostCountPerSectionPerSide : Integer = 2;
        attribute assemblySidePostWidthM : Real = 0.012;
        attribute assemblySidePostDepthM : Real = GriffinEgressRamp::rampRailWidthM;
        attribute assemblySidePostEmbeddedDepthM : Real = GriffinEgressRamp::rampSurfaceThicknessM / 2.0;
        attribute assemblySidePostFirstCenterXM : Real = 0.0;
        attribute assemblySidePostPitchM : Real = GriffinEgressRamp::rampSectionLengthM / (GriffinEgressRamp::assemblySidePostCountPerSectionPerSide - 1.0);
        attribute assemblySideTrussChordHeightM : Real = 0.020;
        attribute assemblySideTrussLowerChordCenterYM : Real = GriffinEgressRamp::rampSurfaceCenterYM + GriffinEgressRamp::rampSurfaceThicknessM / 2.0 + GriffinEgressRamp::assemblySideTrussChordHeightM / 2.0;
        attribute assemblySideTrussBraceThicknessM : Real = 0.012;
        attribute assemblySideTrussBraceCountPerSide : Integer = 12;
        attribute rampSectionHingeBarrelRadiusM : Real = 0.025;
        /* Keep the central hinge shaft inside the open gap between wheel tracks.
         * The four rail-local pins represent the coaxial track-side bearings;
         * no shaft crosses either tire corridor above the walking surface.
         * Source: operator obstruction report, 2026-10-02, and the paired
         * open trusses in https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png .
         * This split-shaft layout is an explicit low-confidence reconstruction,
         * not a released hinge design. Length derives from inner rail clearance,
         * rather than the former outside-to-outside full-width shaft. */
        attribute rampSectionHingeBarrelLengthM : Real = 2.0 * (GriffinEgressRamp::rampCenterRailOffsetZM - GriffinEgressRamp::rampRailWidthM / 2.0);
        // Root shaft is on the physical deck axis. Middle shaft derives
        // from chord top; toe shaft from plate bottom, matching joint datums.
        attribute rampSectionHingeBarrelCenterYM : Real = 0.0;
        /* The physical contact-track Mesh is also the visible walking plate.
         * Do not hide it and substitute sparse traction bars, or add a second
         * render mesh with independent dimensions. Display color is an artistic
         * silver-gray estimate from the selected Astrobotic 2021 rendering. */
        /* Dark walking-plate/back finish, 2026-10-05. June 15 hardware
         * photo shows broad dark stowed ramp faces beside silver framing:
         * https://www.nasa.gov/wp-content/uploads/2026/06/26-06-15-griffin-1-pressconference-1348-edit.jpg
         * https://www.nasa.gov/gallery/astrobotics-griffin-1/
         * Use the existing physical walking Mesh for both visible faces; do
         * not add a separate animated back, collider, mass or joint. The
         * photograph does not establish flight laminate, coating or exposed
         * walking-side finish. Applying one dark finish to the whole plate
         * is a replaceable appearance estimate. Linear display RGB, metallic
         * and roughness are rendering choices, not measured optical or
         * structural properties. Keep guide rails and traction strips silver.
         */
        attribute rampTrackDisplayColor : Real[3] = (.025, .028, .033);
        attribute rampTrackMetallic : Real = .10;
        attribute rampTrackRoughness : Real = .68;
        attribute rampSurfaceCenterYM : Real = 0.00;
        /* Replace the legacy 340 mm rail elevation, retained from the thick
         * slab, with an estimated 180 mm chord center above the track datum.
         * With 40 mm upper stock the fold datum is 200 mm. The lower
         * strip now derives from the track top and leaves a 155 mm web. This produces the slender
         * paired folded tracks shown in the selected Astrobotic 2021 render:
         * https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png .
         * It is a silhouette reconstruction, not released ramp section data.
         * The middle-fold joint offsets derive from chord top; change them
         * together. Walking contact, span and root stow angle are retained. */
        attribute rampRailCenterYM : Real = 0.18;
        attribute rampMaxDeploymentAngleRad : Real = 0.872664626;
        // Render review uses the revised top ring at Y=1.79; hinge center
        // Y=1.70 places a 0.18 m track flush with that ring. The mission
        // ramp attaches to the separate higher payload adapter. These are
        // reconstruction estimates; see griffin-size-evidence.md.
        attribute rampPortMountX : Real = 1.90;
        attribute rampStarboardMountX : Real = -1.90;
        attribute rampMountY : Real = 1.70;
        attribute rampMountZ : Real = 0.0;
        attribute rampHingeOffsetX : Real = 0.00;
        attribute rampHingeOffsetY : Real = 0.0;
        attribute rampHingeOffsetZ : Real = 0.0;
        attribute rampSocketX : Real = 1.90;
        // Bus-local socket: busMountY + rampSocketY = rampMountY.
        // 0.70 = deckCenterY + deckThickness/2 - rampThickness/2.
        attribute rampSocketY : Real = .70;
        attribute rampSocketZ : Real = 0.0;
        // Render deployment angle derives from its 1.79 m ring height and
        // the shared revised length. Physical deployment uses the 2.52 m
        // landed payload height and the retained estimated 27.8335 deg slope.
        attribute rampPortDeploymentAngleRad : Real = -0.338052286;
        attribute rampStarboardDeploymentAngleRad : Real = 0.338052286;
        attribute hingeAxis : GriffinRampHingeAxis = "Z";
        /* The review asset is intentionally compact and stowed.  The
         * full-scale surface remains the mission/deployed envelope; the
         * instance transform below folds that same replaceable component
         * down from the deck hinge so the review silhouette cannot be
         * mistaken for a deployed ramp.  These are Twin study datums because
         * Astrobotic has not published the Griffin-1 stowage mechanism ICD. */
        attribute rampStowedScale : Real = 0.28;
        attribute rampStowedRotationZDeg : Real = -90.0;
        attribute rampStowedStarboardRotationYDeg : Real = 180.0;
        // The mission's physical egress path is a separate interface from the
        // short render-review ramp above. Public Griffin material confirms an
        // egress concept but does not publish an as-built ramp ICD, so these
        // values are explicit, replaceable study assumptions rather than
        // disguised product facts.
        // Physical contact geometry reuses the shared ramp length, outside
        // envelope, thickness, and rail dimensions above. This package owns
        // only the physical hinge, transition, and safe stowed pose.
        // The physical ramp is folded above the landing legs during descent.
        // One shared 45 deg stow magnitude drives mirrored roots: port uses
        // Z=+45; starboard uses USD rotateXYZ=(0,180,-45). Both intermediate
        // hinges fold through 180
        // deg. These are image-based Twin study datums, not released supplier
        // geometry. Each root limit leaves 15 deg beyond its stow target.
        // half-turn in either direction so operators can command and inspect
        // the complete travel.
        // These replaceable study datums are not an as-built mechanism: public
        // Griffin material confirms launch stow and spring deployment but does
        // not publish the stowage geometry or supplier ICD. After touchdown,
        // an operator command returns the section hinges to zero and deploys
        // the deck hinges within their separate descent/deployment envelope.
        // The physical ramp is hinged at the inboard edge, not at its centre:
        // the source-owned contact surface occupies x=0..rampSurfaceLengthM
        // in the ramp body frame. Its centre is half that length. The hinge
        // sits just outboard and above the transition face: its offset equals
        // the deployed track half-thickness projection, so the ramp top meets
        // the transition top edge. Keep the transition datum independent of
        // the ramp hinge datum.
        // USD PhysicsRevoluteJoint limits are authored in degrees by the
        // USD joint attributes are authored in degrees; the sole command
        // limit below remains in radians and is converted at that boundary.
        // The local ramp geometry remains horizontal in its stowed pose; the
        // revolute joint, not child transforms, supplies deployment rotation.
        // The clipped-square octagonal adapter profile in
        // GriffinVisualConfiguration determines the outboard edge at the full
        // lateral span. The source-owned transition length places its outboard
        // face beyond that edge by the required overlap and interface margin.
        // These are replaceable study datums until the supplier mechanical
        // ICD exists.
        // Simulator interface policy: exclude contact only between each fixed
        // TransitionPlate and its matching hinged root ramp. The simplified
        // envelopes meet around a pin that is already constrained by joints.
        // Owned 49811 measured 3.603 mm initial overlap; 49812 removes that
        // contact through PhysicsFilteredPairsAPI. This is a proxy-model
        // assumption, not supplier clearance data. Rover and terrain contact
        // remain enabled. The public June 2026 hardware photographs do not
        // resolve this hidden interface; no flight ICD is available.
        // Photo reference: https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/
        attribute physicalRampDeckTransitionRequiredOverlapM : Real = 0.05;
        attribute physicalRampDeckTransitionLengthM : Real = .90;
        attribute physicalRampDeckTransitionInterfaceToleranceM : Real = 0.002;
        attribute physicalRampDeckTransitionOutboardX : Real = 1.90;
        attribute physicalRampDeckTransitionCenterY : Real = 2.065000000000;
        // The transition is a separate rigid-body child, fixed to the Griffin
        // deck frame.  Its mass is an explicit simulator assumption because
        // Astrobotic has not released a ramp/transition structural ICD.  The
        // inertia list is the rectangular-prism result for the source-owned
        // length, source contact thickness, and current outside rail width. It remains a study
        // estimate until the transition mass properties are measured.
        attribute physicalRampDeckTransitionMassKg : Real = 15.0;
        attribute physicalRampDeckTransitionInertiaKgM2 : Real[3] = (
            GriffinEgressRamp::physicalRampDeckTransitionMassKg * (GriffinEgressRamp::rampSurfaceWidthM * GriffinEgressRamp::rampSurfaceWidthM + GriffinEgressRamp::rampSurfaceThicknessM * GriffinEgressRamp::rampSurfaceThicknessM) / 12.0,
            GriffinEgressRamp::physicalRampDeckTransitionMassKg * (GriffinEgressRamp::physicalRampDeckTransitionLengthM * GriffinEgressRamp::physicalRampDeckTransitionLengthM + GriffinEgressRamp::rampSurfaceWidthM * GriffinEgressRamp::rampSurfaceWidthM) / 12.0,
            GriffinEgressRamp::physicalRampDeckTransitionMassKg * (GriffinEgressRamp::physicalRampDeckTransitionLengthM * GriffinEgressRamp::physicalRampDeckTransitionLengthM + GriffinEgressRamp::rampSurfaceThicknessM * GriffinEgressRamp::rampSurfaceThicknessM) / 12.0);
        attribute physicalRampPortMountX : Real = 1.907003563827;
        attribute physicalRampStarboardMountX : Real = -1.907003563827;
        attribute physicalRampMountY : Real = 2.066735381886;
        attribute physicalRampMountZ : Real = 0.0;
        // At deployment, the ramp hinge position offsets the track half
        // thickness so the upper root edge meets the 2.08 m adapter top. At
        // the 0.44 m nominal touchdown reference height,
        // the 5.397252161 m track deployed 27.833532 degrees places both mitered
        // toe edges on the normalized terrain plane.
        // A thickness-and-angle-derived toe miter brings the lower toe edge
        // to that same plane and avoids a full-thickness collider penetrating
        // terrain. The command remains inside the 50 degree actuator limit.
        // These are replaceable study datums until the supplier mechanical ICD.
        // Nominal angles above describe the static flat-plane geometry only.
        // GRR-017 runtime targets shall instead use the measured landed root
        // hinge frames and retained NOBILE03 DEM under all eight toe corners,
        // without an artificial pad or apron overriding that native terrain.
        // Choose the shallowest terrain-contact solution inside the existing
        // joint travel with minimum predicted clearance = half the contact
        // tolerance below. This 10 mm allowance is an unqualified study
        // estimate to reserve half the 20 mm geometry tolerance for section
        // alignment/deflection; it is not supplier actuator or lock data.
        // Reject missing terrain or an unbracketed target before payload release.
        // Evidence: handover/griffin-landed-ramp-contact-2026-10-01.md,
        // owned core 24dd835fa / Twin fec3026 replay, tick 19196:
        // touchdown succeeds but toe speeds exceed 0.02 rad/s; lander up Y
        // 0.996980044 and actual root targets differ from the flat-plane datum.
        // Keep angle/rate/dwell gates unchanged; this plan is not acceptance.
        attribute physicalRampTerrainContactToleranceM : Real = 0.02;
        attribute physicalRampPortDeploymentAngleRad : Real = -0.4857867749;
        attribute physicalRampStarboardDeploymentAngleRad : Real = 0.4857867749;
        // These values migrate the existing Twin dynamics proxy into the
        // requirement source. They are explicit replaceable assumptions, not
        // Griffin supplier data or an accepted mass-properties solution.
        attribute physicalRampMassKg : Real = 95.0;
        attribute physicalRampSectionMassKg : Real = 31.666666667;
        attribute physicalRampSectionInertiaXKgM2 : Real = GriffinEgressRamp::physicalRampSectionMassKg *
            (GriffinEgressRamp::rampSurfaceWidthM * GriffinEgressRamp::rampSurfaceWidthM + GriffinEgressRamp::rampSurfaceThicknessM * GriffinEgressRamp::rampSurfaceThicknessM) / 12.0;
        attribute physicalRampSectionInertiaYKgM2 : Real = GriffinEgressRamp::physicalRampSectionMassKg *
            (GriffinEgressRamp::rampSectionLengthM * GriffinEgressRamp::rampSectionLengthM + GriffinEgressRamp::rampSurfaceWidthM * GriffinEgressRamp::rampSurfaceWidthM) / 12.0;
        attribute physicalRampSectionInertiaZKgM2 : Real = GriffinEgressRamp::physicalRampSectionMassKg *
            (GriffinEgressRamp::rampSectionLengthM * GriffinEgressRamp::rampSectionLengthM + GriffinEgressRamp::rampSurfaceThicknessM * GriffinEgressRamp::rampSurfaceThicknessM) / 12.0;
        attribute physicalRampSectionMassPartitionToleranceKg : Real = 0.001;
        attribute physicalRampPortRootJointStowLimitRad : Real = 1.0471975512;
        attribute physicalRampRootStowedAngleRad : Real = 0.7853981634;
        attribute physicalRampStarboardRootJointStowLimitRad : Real = 1.0471975512;
        attribute physicalRampRootAxisMirrorTolerance : Real = 0.002;
        attribute physicalRampSectionJointLimitRad : Real = 3.141592654;
        // This is the section's physical fold relative to its parent. The
        // joint frame offset below expresses the same pose away from the
        // solver's +/-pi branch cut and selects the intended opening sweep.
        attribute physicalRampSectionStowedRelativeAngleRad : Real = 3.141592654;
        attribute physicalRampSectionJointFrameOffsetRad : Real = -1.570796327;
        // Physical relative angle of a level, deployed section. The joint
        // coordinate target is this angle plus the joint frame offset.
        attribute physicalRampSectionDeploymentRelativeAngleRad : Real = 0.0;
        /* Deployment sweep policy, 2026-10-01: Avian 0.7.0 wraps the motor
         * position error to [-pi,pi), so a direct 180-degree command has no
         * robust direction under settling error. Local joint-frame offsets
         * do not change that target-to-current difference. Require a measured
         * halfway pose before the final level target; this selects two
         * quarter-turns along the intended outward opening sweep.
         * Derived from the existing study poses, not supplier actuator data.
         * Inspected source: avian3d-0.7.0/src/dynamics/solver/xpbd/joints/revolute.rs,
         * apply_motor position_error = (raw_error + PI).rem_euclid(TAU) - PI.
         * https://docs.rs/avian3d/0.7.0/src/avian3d/dynamics/solver/xpbd/joints/revolute.rs.html */
        attribute physicalRampSectionUnfoldWaypointRelativeAngleRad : Real =
            (GriffinEgressRamp::physicalRampSectionStowedRelativeAngleRad
             + GriffinEgressRamp::physicalRampSectionDeploymentRelativeAngleRad) / 2.0;

        /* Settlement observation policy, 2026-10-01: the owned mission
         * replay crossed the root target tolerance at tick8534 but showed
         * 0.19-0.20 rad root errors by8550. A position crossing is not rest.
         * Source: handover/griffin-measured-unfold-waypoint-2026-10-01.md.
         * Retain the existing 0.035 rad observation tolerance; require
         * abs(relative hinge speed)<=0.02 rad/s at intermediate waypoints
         * and final targets. Before payload release, all six hinges must
         * satisfy angle and speed over a 1 s sampled dwell (probed every
         * six admitted 60 Hz ticks). Reset dwell on any failed sample.
         * Speed and dwell are unqualified study choices: at this rate a
         * hinge advances <=0.02 rad in the dwell, below the angle tolerance;
         * 1 s exceeds the observed 0.25 s overshoot window by four times.
         * This does not prove toe contact, deck continuity, load capacity or
         * hardware stability. Supplier actuator and deployed-lock data are
         * unavailable. The native port is Avian revolute angular_velocity,
         * SI rad/s, from lunco-cosim/src/joint.rs and ports.rs. */
        attribute physicalRampHingeSettleAngleToleranceRad : Real = 0.035;
        attribute physicalRampHingeSettleSpeedToleranceRadPerS : Real = 0.02;
        attribute physicalRampTraversalSettleDwellS : Real = 1.0;
        /* Motion estimate, 2026-10-03: each measured 90-degree unfold
         * waypoint uses a six-second quintic command profile, with zero
         * endpoint speed and acceleration. Average speed is 15 deg/s and
         * peak speed 28.125 deg/s; the existing motor and physical joints
         * still determine actual motion. The previous step command completed
         * the middle half-turn in about 1.2 s and unloaded one pad during
         * owned runtime trials (ticks 1520/1560). Six seconds is an explicit
         * conservative study estimate to reduce inertial reaction, not an
         * Astrobotic actuator rating. The paired fold topology follows
         * https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png ; that
         * image supplies no timing data. Measured waypoint/final angle and
         * speed gates remain mandatory; time alone never permits egress. */
        attribute physicalRampUnfoldQuarterTurnDurationS : Real = 6.0;
        attribute physicalRampJointDriveStiffnessNmPerDeg : Real = 6000.0;
        attribute physicalRampRootJointDriveDampingNmPerDegPerSec : Real = 900.0;
        // Replaceable near-critical damping assumption for the authored
        // section generalized inertias (approximately 41–58 kg m²). The
        // supplier actuator curve is not available in the source package.
        attribute physicalRampSectionJointDriveDampingNmPerDegPerSec : Real = 150.0;
        attribute physicalRampJointDriveMaxTorqueNm : Real = 5000.0;
        attribute physicalRampSectionMassPropertiesToleranceKgM2 : Real = 0.01;
    }

    requirement def GRR001_RampTopology {
        doc /* Each egress ramp shall be a replaceable component attached at the Griffin upper deck. It shall provide two FLIP-aligned contact tracks separated by an open centre, four top-mounted guide rails (two per track), and three rigid sections connected in series. */
    }

    requirement def GRR002_RampHinge {
        doc /* GRR-002 [integration] each ramp shall expose a Z-axis hinge datum related to the matching Griffin bus socket; numeric placement is authored through the Editor assembly tools. */
    }

    requirement def GRR003_RampEnvelope {
        doc /* GRR-003 [study] the visual ramp rail envelope shall use the metric length/width and deployment limit in this package; its outside width shall clear the four FLIP tyre stations by the authored lateral wheel-clearance datum. These values remain study proxies until the mechanical ICD is available. */
        require GRC003_WidthClearsFlipWheelEnvelope;
    }

    requirement def GRR004_RampPlacement {
        doc /* GRR-004 [integration] each ramp root, hinge frame, and matching bus socket shall use the authored metric mount datums and mirrored side placement. */
    }

    requirement def GRR005_RampBehavior {
        doc /* GRR-005 [behavior] each ramp shall expose a revolute Z hinge, publish its commanded angle in radians, mirror port/starboard signs, and reject commands outside rampMaxDeploymentAngleRad. GRC005_DeploymentCommandWithinLimit owns the signed command-envelope predicate; its 0.872664626 rad study limit converts to the native USD joint's degree-valued limits. */
        require GRC005_DeploymentCommandWithinLimit {
            in limitRad = GriffinEgressRamp::rampMaxDeploymentAngleRad;
        }
    }

    requirement def GRR006_RampGeometry {
        doc /* GRR-006 [geometry/physics] each composed physical ramp shall provide two visible continuous convex-mesh contact tracks whose top-face length and thickness match the SysML study values. Their lateral centres shall equal the source FLIP wheel stations, and their width shall equal the source wheel width plus twice the wheel clearance. The outer toe face shall be mitered from the track thickness and deployed angle so its upper and lower edges meet the terrain plane together. The centre remains open between tracks; rails and support load paths remain separately inspectable. */
        require GRC016_ContactTrackClearsTire {
            in trackWidthM = GriffinEgressRamp::assemblyTrackWidthM;
            in wheelWidthM = FlipRover::wheelWidthM;
            in wheelClearanceM = GriffinEgressRamp::rampWheelClearanceM;
        }
        require GRC017_ComposedContactTrackMatchesSource {
            in toleranceM = GriffinEgressRamp::contactTrackGeometryToleranceM;
        }
    }

    requirement def GRR007_RampEvidence {
        doc /* Port and starboard egress ramps shall be independently addressable component instances that share the same section geometry source and use mirrored deck mounting stations. */
    }
    requirement def GRR008_RailGeometry {
        doc /* Both guide edges of each contact track shall start at the upper-deck hinge, sit above the walking surface, and continue to the toe as one rounded-end plate rail segment per rigid ramp section. The root section's guide centre shall rise linearly from walkingSurfaceTop + rampRailHeightM/2 at its deck entrance to rampRailCenterYM at the downstream hinge. Middle and toe guides retain the full fold height. Posts and triangulated webs shall follow that same line. Rationale: owned production contact snapshot 49819 recorded the FLIP lower frame striking the abrupt inner guard end at root-local (0.00845, 0.17307, 0.70984) m with opposing normal impulse 59.96 N s. A flush, gradually rising entrance removes that obstruction while retaining physical rail contacts and the downstream fold datum. This is a low-confidence interface reconstruction derived from existing track/section datums, not a released supplier design. Public reference images show folding, slender tracks but do not disclose this entrance: https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png ; https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander . The June 2026 hardware release does not show integrated FLIP or deployed ramp interfaces: https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/ . Four coaxial pin fittings and rounded extruded plate lugs shall join the guards to each section hinge. Pin centers shall use the native section-axis elevations (root shaft, middle chord top, toe plate bottom), and each segment shall match its section length and source-owned rail envelope. */
    }
    requirement def GRR009_RailSupportGeometry {
        doc /* Each section shall connect all four upper guide rails to the walking surface with two end posts per guide. Posts shall align with the rail stations, meet the contact-track edge, and join the upper chord. Upper/lower chords, uprights and diagonals shall share the source transverse web thickness, giving plate-like triangulated sides with open bays. Post height and center shall be derived from the authored surface, rail, and embedment datums. This is a visual reconstruction; structural qualification requires supplier data. */
    }
    requirement def GRR013_TractionTreadGeometry {
        doc /* Each contact track shall have four transverse traction bars on every ramp section. Bars shall span one track, sit above its walking surface, and use the source-owned first station and pitch. The open centre remains clear. */
        require GRC021_RampTreadCountMatchesSections {
            in totalTreadCount = GriffinEgressRamp::assemblyTreadCount;
            in treadCountPerSection = GriffinEgressRamp::assemblyTreadCountPerSection;
            in sectionCount = GriffinEgressRamp::rampSectionCount;
        }
    }
    requirement def GRR014_RampLoadPathGeometry {
        doc /* Every rigid ramp section shall have two longitudinal underside beams and the source-owned edge support posts. Each section body shall own positive mass and diagonal inertia that partition the ramp mass and match its section envelope. */
    }
    requirement def GRR015_RampHingeGussetGeometry {
        doc /* GRR-015 root bearings shall have a visible load path to the bus perimeter deck. Two inner-track pedestals per ramp derive their upper elevation from physicalRampMountY plus the bearing radius and their lower elevation from bodyMount.y plus deckCenter.y plus half deckDimensions.y. Short deck shoes overlap the bus edge and reach the native root hinge X station. Square member width reuses rampPivotLugWidthM; stations reuse rampCenterRailOffsetZM, outside tire corridors. These are render-only members of the existing bus rigid body, with no extra mass or contact owner. Bracket shape and stock are low-confidence reconstruction estimates prompted by the operator's floating-ramp image on 2026-10-02. ESA's artist rendering shows bus-mounted ramps but supplies no bracket ICD: https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander . The Astrobotic hardware photo documents the bus/leg structure, not a deployed ramp bracket: https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png .  The deck hinge and both intermediate section hinges shall be visible at the ramp assembly joints. Every intermediate joint shall use a Z-axis revolute connection at the adjacent section endpoints, and its hinge fittings shall remain outside the tire corridors. The central shaft shall end at the inner rail edges; local coaxial bearings shall join each track guard without a full-width bar above the wheel paths. Each intermediate parent shall carry paired circular fork cheeks around a compact child tongue, with centres at the existing native joint anchors. Their thickness and spacing derive from the source plate stock. The fittings shall remain render-only and shall not span the tire paths. This split-shaft reconstruction retains the folding axes needed for stowage; it is an explicit image-based study estimate, not supplier geometry. */
        require GRC029_PivotFittingsMatchJoint {
            in toleranceM = GriffinEgressRamp::rampSectionGeometryToleranceM;
        }
        require GRC028_RailAndPivotSlenderness {
            in chordHeightM = GriffinEgressRamp::rampRailHeightM;
            in sectionLengthM = GriffinEgressRamp::rampSectionLengthM;
            in hingeRadiusM = GriffinEgressRamp::rampSectionHingeBarrelRadiusM;
            in pinRadiusM = GriffinEgressRamp::rampRailJointPinRadiusM;
            in maxChordFraction = GriffinEgressRamp::maxRailHeightToSectionLength;
            in maxFittingDiameterRatio = GriffinEgressRamp::maxPivotDiameterToRailHeight;
        }
    }
    requirement def GRR016_ArticulatedRampSections {
        doc /* Each upper-deck-mounted ramp shall contain three equal rigid sections, a revolute deck hinge, and two native revolute joints between consecutive sections. All six physical ramp joints shall expose the source-owned angular drive and limits so their typed angle ports can command motion inside the authored range. Section lengths shall sum to the full contact-track length. Intermediate joints shall hold zero relative angle during rover traversal so the sections, contact tracks, and upper rails form one continuous deployed path. */
        require GRC018_SectionedRampMatchesEnvelope {
            in totalLengthM = GriffinEgressRamp::rampSurfaceLengthM;
            in sectionLengthM = GriffinEgressRamp::rampSectionLengthM;
            in sectionCount = GriffinEgressRamp::rampSectionCount;
            in measuredLengthDeviationM = 0.0;
            in toleranceM = GriffinEgressRamp::rampSectionGeometryToleranceM;
        }
    }
    requirement def GRR017_FlightStowAndPostTouchdownUnfold {
        doc /* The descent stow pose shall place the two root ramp axes as mirror images across the lander X=0 centerline: both bodies use a +45 degree Z rotation, and the starboard body is mounted at 180 degrees about Y. Their lander-frame headings are +45 and +135 degrees. One shared 45 degree stow magnitude defines both body poses; the starboard revolute target is -45 degrees because its joint frame reverses the hinge axis. The port root joint spans -50 to +60 degrees and the starboard joint spans -60 to +50 degrees, retaining the authored outward/down deployment targets. Both intermediate hinges fold 180 degrees in the physical section geometry. Their child-side joint frames are offset by -90 degrees, so the transport pose is represented at +90 degrees and the level deployment pose at -90 degrees in the joint coordinate. This keeps both commanded poses inside the +/-180 degree travel. A measured halfway relative pose then selects the intended sweep: a frame offset alone cannot resolve the motor error at an antipodal half-turn. The first hinge axis is offset to the top rail chord and the second by half the walking-surface thickness, so the three sections stack as a compact bundle instead of occupying one plane. At the level physical relative angle, these frame offsets keep the deployed walking surfaces aligned. The image-based angles and fold offsets are replaceable study estimates informed by the 2021 Griffin-1 product image; the image supplies qualitative silhouette only, not released supplier geometry or an ICD. The lowest composed rail point shall remain above the highest composed landing-leg geometry by the measurement tolerance, and each rail shall remain attached to the upper side of its walking section. An operator U / OPEN RAMPS command in any flight or landing phase shall drive the middle hinges through their measured halfway pose to level while the toes remain stowed, then drive the toes through the same halfway pose to level; only then shall the deck hinges enter the deployment envelope using terrain-contact targets derived from the measured landed hinge frames and all eight toe corners when Modelica reports a physical landing. During flight, use the existing source-owned nominal deployment angles as an explicit mechanism pose, without claiming terrain contact or traversable egress. Source: operator instruction, 2026-10-01; rationale: an airborne surface can lie beyond the mechanism travel and shall not prevent manual opening. The static nominal deployment angles are flat-plane study datums, not unconditional commands for a tilted lander on the retained DEM. Missing terrain shall prevent automatic terrain-fitted deployment and egress acceptance; targets outside joint travel shall always be rejected. Manual F detachment is independent of deployment and settlement. Each quarter-turn command shall follow the source-owned physicalRampUnfoldQuarterTurnDurationS quintic profile on the admitted simulation clock, with zero endpoint speed and acceleration, to reduce abrupt reaction loads on the landing gear. Every waypoint and final section target shall meet the source angle and speed tolerances. Before automatic rover release and egress acceptance, all six hinges shall meet these limits for the source sampled dwell; any failing sample resets the dwell. */
        require GRC022_RampFlightStowAnglesWithinTravel {
            in rootStowAngleRad = GriffinEgressRamp::physicalRampRootStowedAngleRad;
            in sectionStowRelativeAngleRad = GriffinEgressRamp::physicalRampSectionStowedRelativeAngleRad;
            in sectionDeploymentRelativeAngleRad = GriffinEgressRamp::physicalRampSectionDeploymentRelativeAngleRad;
            in sectionJointFrameOffsetRad = GriffinEgressRamp::physicalRampSectionJointFrameOffsetRad;
            in portRootLimitRad = GriffinEgressRamp::physicalRampPortRootJointStowLimitRad;
            in starboardRootLimitRad = GriffinEgressRamp::physicalRampStarboardRootJointStowLimitRad;
            in sectionLimitRad = GriffinEgressRamp::physicalRampSectionJointLimitRad;
        }
        require GRC024_RampSectionDeploymentTargetIsLevel {
            in deploymentRelativeAngleRad = GriffinEgressRamp::physicalRampSectionDeploymentRelativeAngleRad;
        }
        require GRC025_StowedRailsClearLandingLegEnvelope {
            in geometryToleranceM = GriffinEgressRamp::rampSectionGeometryToleranceM;
        }
        require GRC027_RampStowedRootAxesMirror {
            in tolerance = GriffinEgressRamp::physicalRampRootAxisMirrorTolerance;
        }
    }
    requirement def GRR018_RailsAboveWalkingSurface {
        doc /* Each physical section's four upper chords shall remain above the walking surface with source-owned clearance and continuous upright supports. This preserves the top-side rail orientation when the sections are raised for descent and when lowered for egress. */
        require GRC023_RailsRemainOnUpperTrackFace {
            in railCenterYM = GriffinEgressRamp::rampRailCenterYM;
            in railHeightM = GriffinEgressRamp::rampRailHeightM;
            in walkingSurfaceCenterYM = GriffinEgressRamp::rampSurfaceCenterYM;
            in walkingSurfaceThicknessM = GriffinEgressRamp::rampSurfaceThicknessM;
            in toleranceM = GriffinEgressRamp::rampSectionGeometryToleranceM;
        }
    }
    requirement def GRR019_SideTrussBracing {
        doc /* Each physical ramp section shall show a triangulated side truss on both edges of each contact track: twelve alternating diagonal braces connect the track level to the upper chords between two end posts, over continuous lower strips seated on the track top. Member sizes and stations are explicit visual study values because the supplier truss drawing is not public. */
        require GRC026_SideTrussBracing {
            in braceCountPerSide = GriffinEgressRamp::assemblySideTrussBraceCountPerSide;
            in postCountPerSide = GriffinEgressRamp::assemblySidePostCountPerSectionPerSide;
            in braceThicknessM = GriffinEgressRamp::assemblySideTrussBraceThicknessM;
            in lowerChordHeightM = GriffinEgressRamp::assemblySideTrussChordHeightM;
            in lowerChordCenterYM = GriffinEgressRamp::assemblySideTrussLowerChordCenterYM;
            in upperChordCenterYM = GriffinEgressRamp::rampRailCenterYM;
            in walkingSurfaceCenterYM = GriffinEgressRamp::rampSurfaceCenterYM;
            in walkingSurfaceThicknessM = GriffinEgressRamp::rampSurfaceThicknessM;
            in toleranceM = GriffinEgressRamp::rampSectionGeometryToleranceM;
        }
    }
    requirement def GRR010_PhysicalEgressEnvelope {
        doc /* GRR-010 [mission integration/physics] each physical ramp bridges the payload-deck transition to terrain using two FLIP-aligned tracks and a mitered toe. Length derives from the estimated landed payload height and retained estimated deployment slope; width derives from estimated wheel spacing, tire width, clearance and rail widths. All values and uncertainties are documented in griffin-size-evidence.md. GRC010 checks both toe edges; GRC016 checks tire clearance; GRR-012 checks the composed static deck/transition interface. Source agreement does not establish hardware accuracy or successful rover traversal. */
        require GRC010_PhysicalRampReachesTerrain;
    }
    requirement def GRR011_PhysicalDeploymentLifecycle {
        doc /* Each section shall carry positive mass and diagonal inertia. Port and starboard ramps shall remain within the deck-hinge travel limit and use zero relative angle targets at the intermediate hinges during FLIP traversal. */
        require GRC011_RampMassPropertiesArePositive {
            in massKg = GriffinEgressRamp::physicalRampSectionMassKg;
            in inertiaXKgM2 = GriffinEgressRamp::physicalRampSectionInertiaXKgM2;
            in inertiaYKgM2 = GriffinEgressRamp::physicalRampSectionInertiaYKgM2;
            in inertiaZKgM2 = GriffinEgressRamp::physicalRampSectionInertiaZKgM2;
        }
        require GRC019_RampSectionMassPartition {
            in totalMassKg = GriffinEgressRamp::physicalRampMassKg;
            in sectionMassKg = GriffinEgressRamp::physicalRampSectionMassKg;
            in sectionCount = GriffinEgressRamp::rampSectionCount;
            in toleranceKg = GriffinEgressRamp::physicalRampSectionMassPartitionToleranceKg;
        }
        require GRC020_RampSectionInertiaMatchesEnvelope {
            in measuredXKgM2 = GriffinEgressRamp::physicalRampSectionInertiaXKgM2;
            in measuredYKgM2 = GriffinEgressRamp::physicalRampSectionInertiaYKgM2;
            in measuredZKgM2 = GriffinEgressRamp::physicalRampSectionInertiaZKgM2;
            in sectionMassKg = GriffinEgressRamp::physicalRampSectionMassKg;
            in sectionLengthM = GriffinEgressRamp::rampSectionLengthM;
            in outsideWidthM = GriffinEgressRamp::rampSurfaceWidthM;
            in thicknessM = GriffinEgressRamp::rampSurfaceThicknessM;
            in toleranceKgM2 = GriffinEgressRamp::physicalRampSectionMassPropertiesToleranceKgM2;
        }
        require GRC005_DeploymentCommandWithinLimit;
    }
    requirement def GRR012_PhysicalDeckTransition {
        doc /* GRR-012 [physical interface] each physical ramp shall have a separate deck-frame TransitionPlate and collision-enabled ContactSurface rigid body, fixed to the Griffin body. A single composed-collider snapshot shall establish the minimum travel-direction overlap across the adapter's entire lateral span from exact convex footprints, the source-owned transition length within tolerance, coplanar deck and transition top faces, and a closed transition-to-ramp-track hinge seam. Aggregate AABB overlap is not acceptance evidence because the octagonal adapter corners can reduce the actual contact width. The octagonal outer deck remains eight separate convex beam colliders and the rover platform keeps its own geometry-derived convex collider, preserving the tank openings. These checks accept the authored static interface only; rover traversal and runtime wheel contacts require separate mission evidence. Dimensions remain explicit Twin study datums until supplier mechanical CAD/ICD is available. */
        require GRC012_ComposedDeckTransitionFit;
    }

    requirement <'GRR-001'> grr001 : GRR001_RampTopology { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-002'> grr002 : GRR002_RampHinge { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-003'> grr003 : GRR003_RampEnvelope { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-004'> grr004 : GRR004_RampPlacement { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-005'> grr005 : GRR005_RampBehavior { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-006'> grr006 : GRR006_RampGeometry { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-007'> grr007 : GRR007_RampEvidence { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-008'> grr008 : GRR008_RailGeometry { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-009'> grr009 : GRR009_RailSupportGeometry { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-013'> grr013 : GRR013_TractionTreadGeometry { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-014'> grr014 : GRR014_RampLoadPathGeometry { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-015'> grr015 : GRR015_RampHingeGussetGeometry { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-016'> grr016 : GRR016_ArticulatedRampSections { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-017'> grr017 : GRR017_FlightStowAndPostTouchdownUnfold { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-018'> grr018 : GRR018_RailsAboveWalkingSurface { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-019'> grr019 : GRR019_SideTrussBracing { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-010'> grr010 : GRR010_PhysicalEgressEnvelope { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-011'> grr011 : GRR011_PhysicalDeploymentLifecycle { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-012'> grr012 : GRR012_PhysicalDeckTransition { subject ramp : GriffinEgressRamp; }

    verification def Verify_GriffinRampRequirements {
        subject ramp : GriffinEgressRamp;
        objective {
            verify grr001;
            verify grr002;
            verify grr003;
            verify grr004;
            verify grr005;
            verify grr006;
            verify grr007;
            verify grr008;
            verify grr009;
            verify grr011;
            verify grr012;
            verify grr013;
            verify grr014;
            verify grr015;
            verify grr016;
        }
    }

    verification def Verify_GriffinRampFlightStow {
        doc /* Verifies the descent stow pose and upper-side rail placement independently of the still-unverified landing and rover-egress sequence. */
        subject ramp : GriffinEgressRamp;
        objective {
            verify grr017;
            verify grr018;
            verify grr019;
        }
    }

    verification def Verify_GriffinRampTouchdownGeometry {
        doc /* Verifies source-owned physical-ramp deployment angles against the composed ramp hinge and mount data, then checks both mitered toe edges against the authored terrain plane at the touchdown reference height. This geometry check is separate from dynamic deployment and rover traversal. */
        subject ramp : GriffinEgressRamp;
        verify grr010;
    }

    verification def Verify_GriffinRampCommandEnvelope {
        subject ramp : GriffinEgressRamp;
        objective {
            verify grr005;
        }
    }
}
