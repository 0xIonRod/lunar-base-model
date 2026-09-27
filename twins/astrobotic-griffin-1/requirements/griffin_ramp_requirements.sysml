package GriffinRampRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import ScalarValues::String;
    private import ScalarValues::Boolean;
    private import FlipWheelRequirements::FlipDirectionalWheelAssembly;
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
    enum def GriffinRampHingeAxis { Z; }
    enum def GriffinRampTreadIdentity { Tread01; Tread02; Tread03; Tread04; }
    enum def GriffinRampRailJointPinIdentity {
        OuterRailJointPin;
        InnerRailJointPin;
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
        in middleAngleRad : Real;
        in toeAngleRad : Real;
        in limitRad : Real;
        middleAngleRad > 0.0 and toeAngleRad < 0.0
            and middleAngleRad <= limitRad and middleAngleRad >= -limitRad
            and toeAngleRad <= limitRad and toeAngleRad >= -limitRad;
    }

    constraint def GRC023_RailsRemainOnUpperTrackFace {
        in railBottomYM : Real;
        in walkingSurfaceTopYM : Real;
        in toleranceM : Real;
        railBottomYM >= walkingSurfaceTopYM - toleranceM;
    }

    constraint def GRC024_RampSectionDeploymentTargetIsLevel {
        in deploymentTargetRad : Real;
        deploymentTargetRad == 0.0;
    }

    constraint def GRC025_StowedRailsClearLandingLegEnvelope {
        in lowestStowedRailBottomYM : Real;
        in highestLandingLegTopYM : Real;
        in geometryToleranceM : Real;
        lowestStowedRailBottomYM >= highestLandingLegTopYM + geometryToleranceM;
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
            and hingeGapM <= interfaceToleranceM
            and lateralCoverageM >= requiredLateralCoverageM
            and deckProfileCompatible;
    }

    // The ramp is a separately verifiable Griffin subsystem.  The visual and
    // physical study envelopes intentionally use the same full-scale datum so
    // the Editor review cannot show a toy ramp beside the physical egress
    // path. They remain study assumptions until Astrobotic publishes the
    // mechanical ICD.
    part def GriffinEgressRamp {
        doc /* Griffin provides optional rover egress ramps. Each ramp has its own hinge, actuator-limit, contact geometry, and mass-property assumptions, so it is modeled and verified independently from the bus. Supplier ramp and site interface control data remain unavailable; nonpublic geometry and dynamics values are replaceable Twin study assumptions. */
        attribute componentAsset : TwinAssetPath = "components/lander/griffin_ramp_visual.usda";
        attribute usdRootPath : String = "/World/Griffin1";
        attribute sectionAsset : TwinAssetPath = "components/lander/griffin_ramp_section_visual.usda";
        attribute sectionInstances : GriffinRampSectionIdentity[3] =
            ("DeckSection", "MiddleSection", "ToeSection");
        attribute intermediateJointInstances : GriffinRampIntermediateJointIdentity[4] =
            ("RampSectionHingePort01", "RampSectionHingePort12",
             "RampSectionHingeStarboard01", "RampSectionHingeStarboard12");
        attribute treadInstances : GriffinRampTreadIdentity[4] =
            ("Tread01", "Tread02", "Tread03", "Tread04");
        attribute railJointPinInstances : GriffinRampRailJointPinIdentity[2] =
            ("OuterRailJointPin", "InnerRailJointPin");
        attribute transitionBody : GriffinRampTransitionBodyIdentity = "TransitionPlate";
        attribute transitionContact : GriffinRampTransitionContactIdentity = "ContactSurface";
        attribute transitionJoints : GriffinRampTransitionJointIdentity[2] =
            ("RampTransitionJointPort", "RampTransitionJointStarboard");
        attribute rampCount : Integer = 2;
        attribute rampSurfaceLengthM : Real = 12.228605;
        attribute rampSectionCount : Integer = 3;
        attribute rampSectionGeometryToleranceM : Real = 0.002;
        attribute rampSectionLengthM : Real = 4.076201667;
        // This is the outside-to-outside rail envelope. The wheel-contact
        // surfaces are two narrower tracks centered on FLIP's source-owned
        // wheel stations; track width is wheel width plus twice the clearance.
        // Keep this package's value equal to that derived interface datum;
        // it is still a visual study value, not a supplier mechanical ICD.
        attribute rampSurfaceWidthM : Real = 3.50;
        attribute rampWheelClearanceM : Real = 0.15;
        attribute rampSurfaceThicknessM : Real = 0.18;
        attribute rampRailHeightM : Real = 0.28;
        attribute rampRailWidthM : Real = 0.14;
        attribute rampRailOffsetZM : Real = 1.68;
        attribute rampRailJointPinRadiusM : Real = 0.08;
        attribute rampRailJointPinLengthM : Real = 0.22;
        // Separate traction bars on each wheel track leave the centre open.
        // Count and pitch are visual study assumptions because Astrobotic has
        // not published the Griffin ramp tread ICD.
        attribute assemblyTreadCount : Integer = 12;
        attribute assemblyTreadCountPerSection : Integer = 4;
        attribute assemblyTreadWidthM : Real = 0.12;
        attribute assemblyTreadHeightM : Real = 0.05;
        // Source-owned track width; GRC016 constrains it against FLIP's wheel
        // width and the required clearance. Geometry builders use this value.
        attribute assemblyTrackWidthM : Real = 0.60;
        attribute contactTrackGeometryToleranceM : Real = 0.002;
        attribute assemblyTreadFirstCenterXM : Real = 0.50;
        attribute assemblyTreadPitchM : Real = 1.00;
        // A full-scale ramp needs a visible load path below the walking
        // surface. These are presentation-level structural proxies, not a
        // supplier drawing: two longitudinal beams sit just below the deck,
        // The source-owned section geometry uses two underside beams and three
        // upright posts per edge rail on every rigid ramp section.
        attribute assemblyUnderBeamWidthM : Real = 0.18;
        attribute assemblyUnderBeamHeightM : Real = 0.16;
        attribute assemblyUnderBeamCenterYM : Real = -0.17;
        attribute assemblyUnderBeamCenterOffsetZM : Real = 1.50;
        attribute assemblySidePostCountPerSectionPerSide : Integer = 3;
        attribute assemblySidePostWidthM : Real = 0.12;
        attribute assemblySidePostDepthM : Real = 0.12;
        attribute assemblySidePostEmbeddedDepthM : Real = 0.04;
        attribute assemblySidePostFirstCenterXM : Real = 0.50;
        attribute assemblySidePostPitchM : Real = 1.538100833;
        attribute rampSectionHingeBarrelRadiusM : Real = 0.12;
        attribute rampSectionHingeBarrelLengthM : Real = 3.50;
        attribute rampSectionHingeBarrelCenterYM : Real = -0.18;
        attribute rampSurfaceCenterYM : Real = 0.00;
        attribute rampRailCenterYM : Real = 0.23;
        attribute rampMaxDeploymentAngleRad : Real = 0.872664626;
        // Render-only mount: the 5.15 m octagonal top deck reaches x =
        // +/-2.575 m, so the visual hinge is placed at +/-2.80 m beyond the
        // clipped corner profile. The bus visual root is at Y=3.20 m; the top deck's
        // local top face is Y=1.67 m. Put the ramp centre 0.09 m below that
        // face so the 0.18 m surface top meets the deck instead of appearing
        // halfway down the equipment box. The visual and physical frames are
        // intentionally separate: the physical vehicle root is its COM.
        attribute rampPortMountX : Real = 2.80;
        attribute rampStarboardMountX : Real = -2.80;
        attribute rampMountY : Real = 4.78;
        attribute rampMountZ : Real = 0.0;
        attribute rampHingeOffsetX : Real = 0.00;
        attribute rampHingeOffsetY : Real = 0.0;
        attribute rampHingeOffsetZ : Real = 0.0;
        attribute rampSocketX : Real = 2.80;
        // Bus-local socket: busMountY + rampSocketY = rampMountY.
        // 1.58 = topDeckCenterYM + topDeckThicknessM/2 - rampSurfaceThicknessM/2.
        attribute rampSocketY : Real = 1.58;
        attribute rampSocketZ : Real = 0.0;
        // The render-only vehicle is already seated on the normalized visual
        // ground plane: its ramp hinge centre is 4.78 m high and the ramp
        // surface top is 0.09 m above that centre. A 23.4686 degree slope
        // brings the far top edge to Y=0 over the shared 12.228605 m track.
        // The physical mission pose uses its separately calculated 27.833532
        // degree deployment below; the render review keeps this 23.4686 degree pose.
        attribute rampPortDeploymentAngleRad : Real = -0.4096044958;
        attribute rampStarboardDeploymentAngleRad : Real = 0.4096044958;
        attribute hingeAxis : GriffinRampHingeAxis = "Z";
        /* The review asset is intentionally compact and stowed.  The
         * full-scale surface remains the mission/deployed envelope; the
         * instance transform below folds that same replaceable component
         * down from the deck hinge so the review silhouette cannot be
         * mistaken for a deployed ramp.  These are Twin study datums because
         * Astrobotic has not published the Griffin-1 stowage mechanism ICD. */
        attribute rampStowedScale : Real = 0.28;
        attribute rampStowedPortRotationZDeg : Real = -90.0;
        attribute rampStowedStarboardRotationYDeg : Real = 180.0;
        attribute rampStowedStarboardRotationZDeg : Real = 90.0;
        // The mission's physical egress path is a separate interface from the
        // short render-review ramp above. Public Griffin material confirms an
        // egress concept but does not publish an as-built ramp ICD, so these
        // values are explicit, replaceable study assumptions rather than
        // disguised product facts.
        // Physical contact geometry reuses the shared ramp length, outside
        // envelope, thickness, and rail dimensions above. This package owns
        // only the physical hinge, transition, and safe stowed pose.
        // The physical ramp is folded above the landing legs during descent.
        // The middle section folds upward by +90 deg and the toe section
        // folds back by -90 deg, keeping both horizontal sections' walking
        // faces and rails upright in flight. These replaceable study datums
        // are local component-frame angles because the released stowage
        // mechanism ICD is unavailable. After touchdown both intermediate
        // joints return to zero before the deck hinge deploys the ramp.
        // The physical ramp is hinged at the inboard edge, not at its centre:
        // the 12.228605 m contact surface therefore occupies x=0.00..12.228605 m
        // in the ramp body frame. Its centre is 6.1143025 m. The hinge
        // sits at x=3.20 m on the lander. The separate deck transition bridges
        // from the central payload deck and carries the defined contact
        // overlap, so the ramp body begins at its hinge datum.
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
        attribute physicalRampDeckTransitionRequiredOverlapM : Real = 0.05;
        attribute physicalRampDeckTransitionLengthM : Real = 1.96327;
        attribute physicalRampDeckTransitionInterfaceToleranceM : Real = 0.002;
        // The transition is a separate rigid-body child, fixed to the Griffin
        // deck frame.  Its mass is an explicit simulator assumption because
        // Astrobotic has not released a ramp/transition structural ICD.  The
        // inertia list is the rectangular-prism result for the source-owned
        // length, 0.18 m thickness, and 3.50 m width. It remains a study
        // estimate until the transition mass properties are measured.
        attribute physicalRampDeckTransitionMassKg : Real = 15.0;
        attribute physicalRampDeckTransitionInertiaKgM2 : Real[3] = (15.353, 20.131, 4.859);
        attribute physicalRampPortMountX : Real = 3.20;
        attribute physicalRampStarboardMountX : Real = -3.20;
        attribute physicalRampMountY : Real = 5.19;
        attribute physicalRampMountZ : Real = 0.0;
        // The physical contact surface meets the 5.28 m adapter top: its
        // centre is 5.19 m above the Griffin body-reference datum for a
        // 0.18 m track. At the 0.44 m nominal touchdown reference height,
        // the 12.228605 m track deployed 27.833532 degrees places both mitered
        // toe edges on the normalized terrain plane.
        // A thickness-and-angle-derived toe miter brings the lower toe edge
        // to that same plane and avoids a full-thickness collider penetrating
        // terrain. The command remains inside the 50 degree actuator limit.
        // These are replaceable study datums until the supplier mechanical ICD.
        attribute physicalRampTerrainContactToleranceM : Real = 0.02;
        attribute physicalRampPortDeploymentAngleRad : Real = -0.4857867749;
        attribute physicalRampStarboardDeploymentAngleRad : Real = 0.4857867749;
        // These values migrate the existing Twin dynamics proxy into the
        // requirement source. They are explicit replaceable assumptions, not
        // Griffin supplier data or an accepted mass-properties solution.
        attribute physicalRampMassKg : Real = 95.0;
        attribute physicalRampSectionMassKg : Real = 31.666666667;
        attribute physicalRampSectionInertiaXKgM2 : Real = 32.411888889;
        attribute physicalRampSectionInertiaYKgM2 : Real = 76.172636183;
        attribute physicalRampSectionInertiaZKgM2 : Real = 43.931747294;
        attribute physicalRampSectionMassPartitionToleranceKg : Real = 0.001;
        attribute physicalRampSectionJointLimitRad : Real = 2.094395102;
        attribute physicalRampSectionStowedAngleRad : Real = 1.570796327;
        attribute physicalRampToeSectionStowedAngleRad : Real = -1.570796327;
        attribute physicalRampSectionDriveTargetRad : Real = 0.0;
        attribute physicalRampSectionDriveStiffnessNmPerDeg : Real = 6000.0;
        attribute physicalRampSectionDriveDampingNmPerDegPerSec : Real = 900.0;
        attribute physicalRampSectionDriveMaxTorqueNm : Real = 5000.0;
        attribute physicalRampSectionMassPropertiesToleranceKgM2 : Real = 0.01;
    }

    requirement def GRR001_RampTopology {
        doc /* Each egress ramp shall be a replaceable component attached at the Griffin upper deck. It shall provide two FLIP-aligned contact tracks separated by an open centre, two top-mounted edge rails, and three rigid sections connected in series. */
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
        doc /* GRR-006 [geometry/physics] each composed physical ramp shall provide two continuous convex-mesh contact tracks whose top-face length and thickness match the SysML study values. Their lateral centres shall equal the source FLIP wheel stations, and their width shall equal the source wheel width plus twice the wheel clearance. The outer toe face shall be mitered from the track thickness and deployed angle so its upper and lower edges meet the terrain plane together. The centre remains open between tracks; rails and support load paths remain separately inspectable. */
        require GRC016_ContactTrackClearsTire {
            in trackWidthM = GriffinEgressRamp::assemblyTrackWidthM;
            in wheelWidthM = FlipDirectionalWheelAssembly::tireWidthM;
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
        doc /* Both edge rails shall start at the upper-deck hinge, sit above the walking surface, and continue to the toe as one rail segment per rigid ramp section. A visible pivot fitting shall join each rail segment at the deck hinge and at both section hinges. Pin centers shall coincide with the ramp hinge line, and each segment shall match its section length and source-owned rail envelope. */
    }
    requirement def GRR009_RailSupportGeometry {
        doc /* Each section shall connect both upper edge rails to the walking surface with three evenly spaced upright posts per side. Posts shall align with the rail stations and overlap the walking surface and rail so the supports visibly and structurally connect both members. Post height and center shall be derived from the authored surface, rail, and embedment datums. */
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
        doc /* The deck hinge and both intermediate section hinges shall be visible at the ramp assembly joints. Every intermediate joint shall use a Z-axis revolute connection at the adjacent section endpoints, and its hinge barrel shall remain below the walking surface. */
    }
    requirement def GRR016_ArticulatedRampSections {
        doc /* Each upper-deck-mounted ramp shall contain three equal rigid sections, one revolute deck hinge, and two native revolute joints between consecutive sections. Section lengths shall sum to the full contact-track length. Intermediate joints shall hold zero relative angle during rover traversal so the sections, contact tracks, and upper rails form one continuous deployed path. */
        require GRC018_SectionedRampMatchesEnvelope {
            in totalLengthM = GriffinEgressRamp::rampSurfaceLengthM;
            in sectionLengthM = GriffinEgressRamp::rampSectionLengthM;
            in sectionCount = GriffinEgressRamp::rampSectionCount;
            in measuredLengthDeviationM = 0.0;
            in toleranceM = GriffinEgressRamp::rampSectionGeometryToleranceM;
        }
    }
    requirement def GRR017_FlightStowAndPostTouchdownUnfold {
        doc /* During descent, each ramp shall be folded above the landing legs: the middle-section hinge shall hold the source-owned positive 90 degree stow angle and the toe hinge the source-owned negative 90 degree stow angle. The lowest composed rail point shall remain above the highest composed landing-leg geometry by the measurement tolerance, and each rail shall remain attached to the upper side of its walking section. After touchdown, the scenario shall command both intermediate hinges to zero before commanding the deck hinge to deploy. The stow angles remain explicit Twin study assumptions until the supplier mechanism ICD is released. */
        require GRC022_RampFlightStowAnglesWithinTravel {
            in middleAngleRad = GriffinEgressRamp::physicalRampSectionStowedAngleRad;
            in toeAngleRad = GriffinEgressRamp::physicalRampToeSectionStowedAngleRad;
            in limitRad = GriffinEgressRamp::physicalRampSectionJointLimitRad;
        }
        require GRC024_RampSectionDeploymentTargetIsLevel {
            in deploymentTargetRad = GriffinEgressRamp::physicalRampSectionDriveTargetRad;
        }
        require GRC025_StowedRailsClearLandingLegEnvelope {
            in geometryToleranceM = GriffinEgressRamp::rampSectionGeometryToleranceM;
        }
    }
    requirement def GRR018_RailsAboveWalkingSurface {
        doc /* Each physical section's paired edge rails shall sit on the upper face of its walking tracks; the bottom of each rail must not fall below the top of the walking surface beyond the authored geometry tolerance. This preserves the top-side rail orientation when the sections are folded for descent and when unfolded for egress. */
        require GRC023_RailsRemainOnUpperTrackFace {
            in railBottomYM = GriffinEgressRamp::rampRailCenterYM
                - GriffinEgressRamp::rampRailHeightM / 2.0;
            in walkingSurfaceTopYM = GriffinEgressRamp::rampSurfaceCenterYM
                + GriffinEgressRamp::rampSurfaceThicknessM / 2.0;
            in toleranceM = GriffinEgressRamp::rampSectionGeometryToleranceM;
        }
    }
    requirement def GRR010_PhysicalEgressEnvelope {
        doc /* GRR-010 [mission integration/physics] each selected physical ramp shall bridge the composed top-deck transition to the terrain plane with two FLIP-aligned contact tracks, a 3.50 m outside rail envelope, paired top-side rails, and a mitered toe whose upper and lower edges meet the authored terrain height at the commanded deployment angle. The current 12.228605 m top-face length and 27.833532 degree physical deployment are replaceable study datums derived from the 5.28 m adapter top, 0.44 m vehicle-reference touchdown height, and 0.18 m track thickness; the released ramp ICD remains unavailable. GRC010 checks both transformed toe edges against the terrain surface within the explicit contact tolerance. GRC016 requires each 0.60 m track to clear one tire and its side clearance. The render-only pose uses the same top-face length with a separate 4.78 m hinge datum and 23.4686 degree slope. GRR-012 independently checks the composed deck-to-transition-to-ramp static interface. These source-geometry checks do not replace composed mesh readback, deployed runtime contact, or rover traversal evidence. */
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
            verify grr010;
            verify grr011;
            verify grr012;
            verify grr013;
            verify grr014;
            verify grr015;
            verify grr016;
            verify grr017;
            verify grr018;
        }
    }

    verification def Verify_GriffinRampFlightStow {
        doc /* Verifies the descent stow pose and upper-side rail placement independently of the still-unverified landing and rover-egress sequence. */
        subject ramp : GriffinEgressRamp;
        verify grr017;
        verify grr018;
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
