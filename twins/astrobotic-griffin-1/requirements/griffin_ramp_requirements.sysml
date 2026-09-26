package GriffinRampRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import ScalarValues::String;
    private import ScalarValues::Boolean;
    private import FlipWheelRequirements::FlipDirectionalWheelAssembly;

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
        attribute componentAsset : String = "components/lander/griffin_ramp_visual.usda";
        attribute usdRootPath : String = "/World/Griffin1";
        // This ordered source list owns the replaceable ramp topology and is
        // the shared child inventory for builders and composed-stage checks.
        attribute childNames : String[54] = (
            "MountFrame", "RampTrackPort", "RampTrackStarboard", "OuterRail", "InnerRail",
            "SupportArm", "SupportArmOuter", "SupportArmInner",
            "UnderBeamPort", "UnderBeamStarboard",
            "SidePostPort1", "SidePostPort2", "SidePostPort3", "SidePostPort4", "SidePostPort5", "SidePostPort6", "SidePostPort7",
            "SidePostStarboard1", "SidePostStarboard2", "SidePostStarboard3", "SidePostStarboard4", "SidePostStarboard5", "SidePostStarboard6", "SidePostStarboard7",
            "HingeCollarPort", "HingeCollarStarboard", "HingeGussetPort", "HingeGussetStarboard",
            "TreadPort1", "TreadPort2", "TreadPort3", "TreadPort4", "TreadPort5", "TreadPort6", "TreadPort7", "TreadPort8", "TreadPort9", "TreadPort10", "TreadPort11", "TreadPort12",
            "TreadStarboard1", "TreadStarboard2", "TreadStarboard3", "TreadStarboard4", "TreadStarboard5", "TreadStarboard6", "TreadStarboard7", "TreadStarboard8", "TreadStarboard9", "TreadStarboard10", "TreadStarboard11", "TreadStarboard12",
            "MountPlate", "HingePin");
        attribute rampCount : Integer = 2;
        attribute rampSurfaceLengthM : Real = 12.228605;
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
        attribute supportArmCenterXM : Real = 1.60;
        attribute supportArmCenterYM : Real = 0.50;
        attribute supportArmHalfWidthM : Real = 0.08;
        attribute supportArmHalfHeightM : Real = 0.95;
        attribute supportArmHalfDepthM : Real = 0.12;
        attribute supportArmPairOffsetZM : Real = 1.05;
        attribute supportArmTiltZDeg : Real = -18.0;
        // Separate traction bars on each wheel track leave the centre open.
        // Count and pitch are visual study assumptions because Astrobotic has
        // not published the Griffin ramp tread ICD.
        attribute assemblyTreadNamePrefix : String = "Tread";
        attribute assemblyTreadCount : Integer = 12;
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
        // seven upright posts support each edge rail, and two collars make the
        // revolute hinge readable in the Editor. The values are deliberately
        // independent SysML datums so a future ramp ICD can replace them
        // without rewriting the visual builder.
        attribute assemblyUnderBeamWidthM : Real = 0.18;
        attribute assemblyUnderBeamHeightM : Real = 0.16;
        attribute assemblyUnderBeamCenterYM : Real = -0.17;
        attribute assemblyUnderBeamCenterOffsetZM : Real = 1.50;
        attribute assemblySidePostCountPerSide : Integer = 7;
        attribute assemblySidePostWidthM : Real = 0.12;
        attribute assemblySidePostHeightM : Real = 0.50;
        attribute assemblySidePostDepthM : Real = 0.12;
        attribute assemblySidePostCenterYM : Real = -0.16;
        attribute assemblySidePostFirstCenterXM : Real = 0.50;
        attribute assemblySidePostPitchM : Real = 1.85;
        attribute assemblyHingeCollarRadiusM : Real = 0.18;
        attribute assemblyHingeCollarLengthM : Real = 0.32;
        attribute assemblyHingeCollarOffsetZM : Real = 0.35;
        // Short inboard cheek/gusset blocks visually tie the hinge collars and
        // underside beams into the raised edge rails.  The Griffin ramp ICD is
        // not public, so these are render-only study proxies rather than
        // claimed structural dimensions.
        attribute assemblyHingeGussetWidthM : Real = 0.70;
        attribute assemblyHingeGussetHeightM : Real = 0.24;
        attribute assemblyHingeGussetDepthM : Real = 0.18;
        attribute assemblyHingeGussetCenterXM : Real = 0.35;
        attribute assemblyHingeGussetCenterYM : Real = -0.12;
        attribute assemblyHingeGussetOffsetZM : Real = 1.50;
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
        // The physical mission pose uses its separate COM-relative 49 degree
        // deployment below.
        attribute rampPortDeploymentAngleRad : Real = -0.4096044958;
        attribute rampStarboardDeploymentAngleRad : Real = 0.4096044958;
        attribute rampBehavior : String = "revolute about Z; command in radians; USD rotateXYZ in degrees";
        attribute hingeAxis : String = "Z";
        attribute mountDatum : String = "Bus/RampSocket";
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
        attribute rampGeometryStatus : String = "full-scale metric visual/physical study envelope; mechanical ICD TBD";
        // The mission's physical egress path is a separate interface from the
        // short render-review ramp above. Public Griffin material confirms an
        // egress concept but does not publish an as-built ramp ICD, so these
        // values are explicit, replaceable study assumptions rather than
        // disguised product facts.
        // Physical contact geometry reuses the shared ramp length, outside
        // envelope, thickness, and rail dimensions above. This package owns
        // only the physical hinge, transition, and safe stowed pose.
        // The physical ramp is stowed horizontally until touchdown.  These
        // are local component-frame datums: the port ramp uses +X and the
        // starboard ramp mirrors the X sign in the Editor recipe.  Keeping
        // the safe pre-landing pose in SysML prevents a deployed collision
        // proxy from touching terrain during powered descent.
        // The physical ramp is hinged at the inboard edge, not at its centre:
        // the 12.228605 m contact surface therefore occupies x=0.00..12.228605 m
        // in the ramp body frame. Its centre is 6.1143025 m. The hinge
        // sits at x=3.20 m on the lander. The separate deck transition bridges
        // from the central payload deck and carries the defined contact
        // overlap, so the ramp body begins at its hinge datum.
        attribute physicalRampStowedAngleRad : Real = 0.00;
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
        attribute physicalRampTransitionChildName : String = "TransitionPlate";
        attribute physicalRampTransitionContactChildName : String = "ContactSurface";
        // The transition is a separate rigid-body child, fixed to the Griffin
        // deck frame.  Its mass is an explicit simulator assumption because
        // Astrobotic has not released a ramp/transition structural ICD.  The
        // inertia list is the rectangular-prism result for the source-owned
        // length, 0.18 m thickness, and 3.50 m width. It remains a study
        // estimate until the transition mass properties are measured.
        attribute physicalRampDeckTransitionMassKg : Real = 15.0;
        attribute physicalRampDeckTransitionInertiaKgM2 : Real[3] = (15.353, 20.131, 4.859);
        attribute physicalRampTransitionJointNamePrefix : String = "RampTransitionJoint";
        attribute physicalRampPortMountX : Real = 3.20;
        attribute physicalRampStarboardMountX : Real = -3.20;
        attribute physicalRampMountY : Real = 5.19;
        attribute physicalRampMountZ : Real = 0.0;
        // The physical contact surface meets the 5.28 m adapter top: its
        // centre is 5.19 m above the Griffin COM datum for a 0.18 m track.
        // At a 3.98 m touchdown COM height, the 12.228605 m track deployed
        // 49 degrees reaches the normalized terrain plane at its top toe.
        // A thickness-and-angle-derived toe miter brings the lower toe edge
        // to that same plane and avoids a full-thickness collider penetrating
        // terrain. The command remains inside the 50 degree actuator limit.
        // These are replaceable study datums until the supplier mechanical ICD.
        attribute physicalRampTerrainContactToleranceM : Real = 0.02;
        attribute physicalRampPortDeploymentAngleRad : Real = -0.8552113335;
        attribute physicalRampStarboardDeploymentAngleRad : Real = 0.8552113335;
        // These values migrate the existing Twin dynamics proxy into the
        // requirement source. They are explicit replaceable assumptions, not
        // Griffin supplier data or an accepted mass-properties solution.
        attribute physicalRampMassKg : Real = 95.0;
        attribute physicalRampInertiaXKgM2 : Real = 210.0;
        attribute physicalRampInertiaYKgM2 : Real = 34.0;
        attribute physicalRampInertiaZKgM2 : Real = 210.0;
        attribute physicalRampMassPropertiesStatus : String = "study proxy; supplier ramp mass, center of mass, and inertia TBD";
    }

    requirement def GRR001_RampTopology {
        doc /* GRR-001 [visual] each side ramp shall be a named replaceable component with two full-scale wheel-contact tracks, two edge rails, paired support arms, hinge pin, and mount plate. The open centre is retained; paired supports are a presentation-level load-path assumption, not supplier CAD. */
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
        doc /* GRR-007 [process] port and starboard ramps shall be edited and reviewed independently in Editor Perspective, with a composed USD readback and fresh screenshot. */
    }
    requirement def GRR008_RailGeometry {
        doc /* GRR-008 [geometry] each ramp shall expose two rails matching the 12.228605 m contact-track length, 0.28 m height, and 0.14 m width, centered at signed Z = +/-1.68 m above the ramp surface. The full-width 3.50 m envelope and rail stations are study assumptions sized to the FLIP wheel envelope. */
    }
    requirement def GRR009_SupportArmGeometry {
        doc /* GRR-009 [geometry] each ramp shall expose a centre support and a mirrored support pair, each with a 0.16 m by 1.90 m by 0.24 m envelope, centre at (1.60, 0.50, 0.0) m and signed Z offsets +/-1.05 m, using local Z rotation -18 degrees in the port template. */
    }
    requirement def GRR013_TractionTreadGeometry {
        doc /* GRR-013 [visual geometry] each full-scale visual ramp shall expose twelve named transverse traction bars on each contact track. Each bar has 0.12 m travel width, 0.05 m height, and spans exactly one track; its lateral station follows the FLIP wheel station. The first bar is centered 0.50 m from the hinge and pitch is 1.00 m. The centre gap remains open. These are presentation-level rover-driving assumptions pending a supplier ramp ICD. */
    }
    requirement def GRR014_RampLoadPathGeometry {
        doc /* GRR-014 [visual geometry] each visual ramp shall expose two typed longitudinal underside beams, seven typed upright edge supports per side, and two typed hinge collars. The beam/post/collar sizes and stations are explicit SysML study assumptions that make the rover load path and revolute interface inspectable without claiming supplier CAD. */
    }
    requirement def GRR015_RampHingeGussetGeometry {
        doc /* GRR-015 [visual geometry] each visual ramp shall expose two named inboard hinge gussets that bridge the hinge/underside load path to the raised edge rails. Their width, height, depth, station, and signed edge offsets are explicit render-only study assumptions because the supplier ramp structural ICD is not public. */
    }
    requirement def GRR010_PhysicalEgressEnvelope {
        doc /* GRR-010 [mission integration/physics] each selected physical ramp shall bridge the composed top-deck transition to the terrain plane with two FLIP-aligned contact tracks, a 3.50 m outside rail envelope, paired rails, and a mitered toe whose upper and lower edges meet the authored terrain height at the commanded deployment angle. The current 12.228605 m top-face length and 49 degree physical deployment are replaceable study datums derived from the 5.28 m adapter top, 3.98 m touchdown COM height, and 0.18 m track thickness; the released ramp ICD remains unavailable. GRC010 checks both transformed toe edges against the terrain surface within the explicit contact tolerance. GRC016 requires each 0.60 m track to clear one tire and its side clearance. The render-only pose uses the same top-face length with a separate 4.78 m hinge datum and 23.4686 degree slope. GRR-012 independently checks the composed deck-to-transition-to-ramp static interface. These source-geometry checks do not replace composed mesh readback, deployed runtime contact, or rover traversal evidence. */
        require GRC010_PhysicalRampReachesTerrain;
    }
    requirement def GRR011_PhysicalDeploymentLifecycle {
        doc /* GRR-011 [mission lifecycle/mechanics] physical ramp bodies shall carry positive source-owned mass and diagonal inertia, remain horizontal and collision-enabled during descent, and receive the typed revolute-joint command only after touchdown. The current 95 kg and (210,34,210) kg m^2 values are replaceable Twin study proxies, not supplier data; GRC011 checks only positivity and the composed USD checks confirm the builder used these source values. The port/starboard deployed commands are -0.8552113335 and +0.8552113335 rad and remain within the single 0.872664626 rad source-owned limit, converted to degrees only when writing native USD joint bounds. Runtime actuation, center-of-mass/inertia validity, and contact still require mission evidence. */
        require GRC011_RampMassPropertiesArePositive;
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
    requirement <'GRR-009'> grr009 : GRR009_SupportArmGeometry { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-013'> grr013 : GRR013_TractionTreadGeometry { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-014'> grr014 : GRR014_RampLoadPathGeometry { subject ramp : GriffinEgressRamp; }
    requirement <'GRR-015'> grr015 : GRR015_RampHingeGussetGeometry { subject ramp : GriffinEgressRamp; }
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
        }
    }

    verification def Verify_GriffinRampCommandEnvelope {
        subject ramp : GriffinEgressRamp;
        objective {
            verify grr005;
        }
    }
}
