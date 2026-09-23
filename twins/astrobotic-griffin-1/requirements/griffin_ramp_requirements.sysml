package GriffinRampRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import ScalarValues::String;
    private import ScalarValues::Boolean;

    constraint def GRC005_DeploymentCommandWithinLimit {
        in commandRad : Real;
        in limitRad : Real;
        commandRad >= -limitRad and commandRad <= limitRad;
    }

    constraint def GRC003_WidthClearsFlipWheelEnvelope {
        in rampWidthM : Real;
        in wheelHalfTrackM : Real;
        in wheelRadiusM : Real;
        in wheelClearanceM : Real;
        rampWidthM >= 2.0 * (wheelHalfTrackM + wheelRadiusM + wheelClearanceM);
    }

    constraint def GRC012_TransitionOverlapWithinSurface {
        in overlapM : Real;
        in requiredOverlapM : Real;
        in surfaceLengthM : Real;
        in deckProfileCompatible : Boolean;
        requiredOverlapM > 0.0
            and overlapM >= requiredOverlapM
            and overlapM < surfaceLengthM
            and deckProfileCompatible;
    }

    // The ramp is a separately verifiable Griffin subsystem.  The visual and
    // physical study envelopes intentionally use the same full-scale datum so
    // the Editor review cannot show a toy ramp beside the physical egress
    // path. They remain study assumptions until Astrobotic publishes the
    // mechanical ICD.
    part def GriffinEgressRamp {
        attribute componentAsset : String = "components/lander/griffin_ramp_visual.usda";
        attribute usdRootPath : String = "/World/Griffin1";
        // The saved component owns the complete replaceable ramp topology,
        // including the edge-support posts. `assemblyChildNames` remains a
        // focused load-path verification list below; it is not a second
        // geometry owner or a legacy assembly overlay.
        attribute childNames : String[32] = ("MountFrame", "RampSurface", "OuterRail", "InnerRail", "SupportArm", "SupportArmOuter", "SupportArmInner", "UnderBeamPort", "UnderBeamStarboard", "SidePostPort1", "SidePostPort2", "SidePostPort3", "SidePostPort4", "SidePostStarboard1", "SidePostStarboard2", "SidePostStarboard3", "SidePostStarboard4", "HingeCollarPort", "HingeCollarStarboard", "HingeGussetPort", "HingeGussetStarboard", "Tread1", "Tread2", "Tread3", "Tread4", "Tread5", "Tread6", "Tread7", "Tread8", "MountPlate", "HingePin");
        attribute assemblyChildNames : String[28] = ("MountPlate", "HingePin", "SupportArm", "SupportArmOuter", "SupportArmInner", "UnderBeamPort", "UnderBeamStarboard", "SidePostPort1", "SidePostPort2", "SidePostPort3", "SidePostPort4", "SidePostStarboard1", "SidePostStarboard2", "SidePostStarboard3", "SidePostStarboard4", "HingeCollarPort", "HingeCollarStarboard", "HingeGussetPort", "HingeGussetStarboard", "Tread1", "Tread2", "Tread3", "Tread4", "Tread5", "Tread6", "Tread7", "Tread8");
        attribute rampCount : Integer = 2;
        attribute rampSurfaceLengthM : Real = 8.00;
        // The operational width is derived in the Rhai verifier from the
        // independent FLIP wheel-station and tyre datums:
        // 2 * (maxAbs(FlipRover.wheelStationZ)
        //      + FlipRover.visualRoverWheelRadiusM
        //      + rampWheelClearanceM).
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
        // Transverse traction bars make the full-scale review ramp read as a
        // drive surface instead of a featureless slab.  Their count and
        // pitch are visual study assumptions because Astrobotic has not
        // published the Griffin ramp tread ICD.
        attribute assemblyTreadNamePrefix : String = "Tread";
        attribute assemblyTreadCount : Integer = 8;
        attribute assemblyTreadWidthM : Real = 0.12;
        attribute assemblyTreadHeightM : Real = 0.05;
        attribute assemblyTreadSpanM : Real = 3.10;
        attribute assemblyTreadFirstCenterXM : Real = 0.50;
        attribute assemblyTreadPitchM : Real = 1.00;
        // A full-scale ramp needs a visible load path below the walking
        // surface. These are presentation-level structural proxies, not a
        // supplier drawing: two longitudinal beams sit just below the deck,
        // four upright posts support each edge rail, and two collars make the
        // revolute hinge readable in the Editor. The values are deliberately
        // independent SysML datums so a future ramp ICD can replace them
        // without rewriting the visual builder.
        attribute assemblyUnderBeamWidthM : Real = 0.18;
        attribute assemblyUnderBeamHeightM : Real = 0.16;
        attribute assemblyUnderBeamCenterYM : Real = -0.17;
        attribute assemblyUnderBeamCenterOffsetZM : Real = 1.50;
        attribute assemblySidePostCountPerSide : Integer = 4;
        attribute assemblySidePostWidthM : Real = 0.12;
        attribute assemblySidePostHeightM : Real = 0.50;
        attribute assemblySidePostDepthM : Real = 0.12;
        attribute assemblySidePostCenterYM : Real = -0.16;
        attribute assemblySidePostFirstCenterXM : Real = 1.25;
        attribute assemblySidePostPitchM : Real = 1.75;
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
        // Render-only mount: the 5.55 m hex deck reaches x = +/-2.775 m,
        // so the visual hinge is placed at +/-2.80 m with a 25 mm seam
        // allowance. The bus visual root is at Y=3.20 m; the top deck's
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
        // surface top is 0.09 m above that centre. A 37.3329 degree slope
        // brings the far top edge to Y=0 over 8.00 m. This is a visual study
        // datum; the physical mission ramp retains its COM-relative 45.7457
        // degree deployment below.
        attribute rampPortDeploymentAngleRad : Real = -0.6515821350;
        attribute rampStarboardDeploymentAngleRad : Real = 0.6515821350;
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
        attribute physicalRampSurfaceLengthM : Real = 8.00;
        // The physical collision study must clear the current FLIP lateral
        // wheel envelope: +/-1.15 m wheel stations, a conservative +/-0.45 m
        // tyre envelope, and 0.15 m route clearance on each side produce a
        // 3.50 m full-width ramp. This is a mission study datum, not supplier
        // CAD; it avoids the visibly oversized 5.50 m placeholder.
        attribute physicalRampSurfaceWidthM : Real = 3.50;
        attribute physicalRampSurfaceThicknessM : Real = 0.18;
        attribute physicalRampRailHeightM : Real = 0.28;
        attribute physicalRampRailWidthM : Real = 0.14;
        // The physical ramp is stowed horizontally until touchdown.  These
        // are local component-frame datums: the port ramp uses +X and the
        // starboard ramp mirrors the X sign in the Editor recipe.  Keeping
        // the safe pre-landing pose in SysML prevents a deployed collision
        // proxy from touching terrain during powered descent.
        // The physical ramp is hinged at the inboard edge, not at its centre:
        // the 8.00 m contact surface therefore occupies x=0.00..8.00 m in
        // the ramp body frame.  Its centre is 8.00/2 = 4.00 m.  The hinge
        // sits at x=3.20 m on the lander, only 0.04 m beyond the authored
        // deck edge x=3.16 m; keeping the inboard edge at the hinge makes the
        // deployed slope continuous instead of lifting an overlapped inboard
        // section above the deck.
        attribute physicalRampStowedSurfaceCenterXM : Real = 4.00;
        attribute physicalRampStowedSurfaceCenterYM : Real = 0.00;
        attribute physicalRampStowedRailCenterYM : Real = 0.23;
        attribute physicalRampStowedAngleRad : Real = 0.00;
        // USD PhysicsRevoluteJoint limits are authored in degrees by the
        // standard USD reader; the command port remains radians.  The 50 deg
        // limit is actuator travel allowance, not the deployed ramp slope.
        attribute physicalRampHingeLimitDeg : Real = 50.0;
        // The surface cube is centred half-way along the deployed ramp.  The
        // hinge rotation supplies the vertical drop, so the component-local
        // Y datum remains zero; putting the drop here as well would apply the
        // same slope twice and leave a gap between deck and ramp.
        attribute physicalRampSurfaceCenterYM : Real = 0.00;
        attribute physicalRampRailCenterYM : Real = 0.23;
        // Historical six-sided collider measurement. The +/-3.16 m edge and
        // 0.04 m hinge clearance are provisional and must be recomputed from
        // the octagonal composed collider before physical acceptance.
        attribute physicalRampDeckEdgeXM : Real = 3.16;
        attribute physicalRampDeckToHingeClearanceM : Real = 0.04;
        // Historical placeholder: 1.21 m was derived from the old six-sided
        // TopDeckCollisionProxy. The intended bus/deck footprint is octagonal.
        // Keep this value only to describe the current authored asset; it is
        // not a required overlap or an acceptance limit. Recompute it from
        // the composed octagonal collider, ramp hinge, and FLIP wheel envelope
        // after Editor authoring and typed geometry readback.
        attribute physicalRampDeckTransitionOverlapM : Real = 1.21;
        attribute physicalRampTransitionChildName : String = "TransitionPlate";
        attribute physicalRampTransitionContactChildName : String = "ContactSurface";
        // The transition is a separate rigid-body child, fixed to the Griffin
        // deck frame.  Its mass is an explicit simulator assumption because
        // Astrobotic has not released a ramp/transition structural ICD.  The
        // inertia list is the rectangular-prism result for
        // m=15 kg, dimensions (1.21, 0.18, 3.50) m:
        // Ixx=m*(0.18^2+3.50^2)/12=15.35,
        // Iyy=m*(1.21^2+3.50^2)/12=17.14,
        // Izz=m*(1.21^2+0.18^2)/12=1.87 kg m^2.
        attribute physicalRampDeckTransitionMassKg : Real = 15.0;
        attribute physicalRampDeckTransitionInertiaKgM2 : Real[3] = (15.35, 17.14, 1.87);
        attribute physicalRampTransitionJointNamePrefix : String = "RampTransitionJoint";
        attribute physicalRampPortMountX : Real = 3.20;
        attribute physicalRampStarboardMountX : Real = -3.20;
        attribute physicalRampMountY : Real = 1.75;
        attribute physicalRampMountZ : Real = 0.0;
        // Geometry-derived deployment for the physical landed scene: the
        // canonical touchdown COM datum is 3.98 m above terrain and the
        // physical hinge is another 1.75 m above that COM datum, so
        // asin((3.98 + 1.75) / 8.00) = 0.7984136958 rad = 45.7457 deg.
        // The sign is mirrored about the lander Z axis so the port/starboard
        // surfaces descend away from the deck. This is distinct from the
        // render-only rampMountY/rampPortDeploymentAngleRad values above.
        attribute physicalRampPortDeploymentAngleRad : Real = -0.7984136958;
        attribute physicalRampStarboardDeploymentAngleRad : Real = 0.7984136958;
        attribute physicalRampRouteClearanceM : Real = 0.25;
        attribute provenanceSource : String = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute missionReference : String = "https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/";
        attribute productReference : String = "https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/";
        attribute referenceImage : String = "https://aviationweek.com/gallery-look-nasas-commercial-lunar-payload-services-deliveries";
        attribute sourceFact : String = "Griffin provides optional egress ramps so a rover can drive off the lander";
        attribute sourceRationale : String = "A ramp has its own hinge, actuator-limit and contact geometry, so it is detached and verified independently from the bus";
    }

    requirement def GRR001_RampTopology {
        doc /* GRR-001 [visual] each side ramp shall be a named replaceable component with a full-scale surface, two edge rails, paired support arms, hinge pin, and mount plate. The paired supports are a presentation-level load-path assumption, not supplier CAD. */
    }

    requirement def GRR002_RampHinge {
        doc /* GRR-002 [integration] each ramp shall expose a Z-axis hinge datum related to the matching Griffin bus socket; numeric placement is authored through the Editor assembly tools. */
    }

    requirement def GRR003_RampEnvelope {
        doc /* GRR-003 [study] the visual ramp envelope shall use the metric length/width and deployment limit in this package; its width shall clear the four FLIP wheel stations by the authored wheel-clearance datum. These values remain study proxies until the mechanical ICD is available. */
        require GRC003_WidthClearsFlipWheelEnvelope;
    }

    requirement def GRR004_RampPlacement {
        doc /* GRR-004 [integration] each ramp root, hinge frame, and matching bus socket shall use the authored metric mount datums and mirrored side placement. */
    }

    requirement def GRR005_RampBehavior {
        doc /* GRR-005 [behavior] each ramp shall expose a revolute Z hinge, publish its commanded angle in radians, mirror port/starboard signs, and reject commands outside rampMaxDeploymentAngleRad. GRC005_DeploymentCommandWithinLimit owns the signed command-envelope predicate; the authored 50 degree value is a replaceable study limit pending the mechanical ICD. */
        require GRC005_DeploymentCommandWithinLimit;
    }

    requirement def GRR006_RampGeometry {
        doc /* GRR-006 [geometry] the composed ramp surface shall match the authored metric length, width, and thickness envelope; the width must be sufficient for the FLIP track plus two tyre envelopes and the wheel-clearance datum. Rails and support arm remain separately inspectable. */
    }

    requirement def GRR007_RampEvidence {
        doc /* GRR-007 [process] port and starboard ramps shall be edited and reviewed independently in Editor Perspective, with a composed USD readback and fresh screenshot. */
    }
    requirement def GRR008_RailGeometry {
        doc /* GRR-008 [geometry] each ramp shall expose two rails of 8.00 m length, 0.28 m height, and 0.14 m width, centered at signed Z = +/-1.68 m above the ramp surface. The full-width 3.50 m envelope and rail stations are study assumptions sized to the FLIP wheel envelope. */
    }
    requirement def GRR009_SupportArmGeometry {
        doc /* GRR-009 [geometry] each ramp shall expose a centre support and a mirrored support pair, each with a 0.16 m by 1.90 m by 0.24 m envelope, centre at (1.60, 0.50, 0.0) m and signed Z offsets +/-1.05 m, using local Z rotation -18 degrees in the port template. */
    }
    requirement def GRR013_TractionTreadGeometry {
        doc /* GRR-013 [visual geometry] each full-scale visual ramp shall expose eight named transverse traction bars, each 0.12 m in travel width, 0.05 m high, and 3.10 m spanning between the rails; the first bar is centered 0.50 m from the hinge and the pitch is 1.00 m. These are a presentation-level rover-driving assumption until a supplier ramp ICD is available. */
    }
    requirement def GRR014_RampLoadPathGeometry {
        doc /* GRR-014 [visual geometry] each visual ramp shall expose two typed longitudinal underside beams, four typed upright edge supports per side, and two typed hinge collars. The beam/post/collar sizes and stations are explicit SysML study assumptions that make the rover load path and revolute interface inspectable without claiming supplier CAD. */
    }
    requirement def GRR015_RampHingeGussetGeometry {
        doc /* GRR-015 [visual geometry] each visual ramp shall expose two named inboard hinge gussets that bridge the hinge/underside load path to the raised edge rails. Their width, height, depth, station, and signed edge offsets are explicit render-only study assumptions because the supplier ramp structural ICD is not public. */
    }
    requirement def GRR010_PhysicalEgressEnvelope {
        doc /* GRR-010 [mission integration] the selected physical ramp shall bridge the Griffin top-deck datum to the normalized terrain plane with an 8.00 m x 3.50 m contact surface, paired rails, and a geometry-derived 45.7457 degree deployed slope; the exact mechanical ICD remains TBD. Source: https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/ and https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/. Rationale: public material supports optional rover egress but does not publish dimensions; the explicit 3.50 m envelope is a simulation assumption based on the current +/-1.15 m FLIP wheel stations, a conservative +/-0.45 m tyre envelope, and 0.15 m route clearance on each side. asin((3.98 + 1.75)/8.00) reaches the normalized terrain plane from the landed Griffin body without leaving the rover above the ramp or dropping the ramp below it. The render-only ramp has a separate 4.78 m visual hinge datum and 37.3329 degree presentation slope because its standalone vehicle root is already on the normalized visual ground plane. The deck transition is specified separately by GRR-012 so the 8.00 m physical ramp remains a hinge-to-tip surface. */
    }
    requirement def GRR011_PhysicalDeploymentLifecycle {
        doc /* GRR-011 [mission lifecycle] physical ramp colliders shall be authored in a horizontal stowed pose for descent and commanded through the typed revolute-joint angle port only after touchdown; the port/starboard deployed commands are -0.7984136958 and +0.7984136958 rad within a 50 degree USD joint limit. Source: LunCoSim PhysicsRevoluteJoint angle-port contract and the Griffin physical-ramp study in this package. Rationale: a full-length deployed ramp reaches the terrain plane before the lander legs; stowing it prevents premature lander/ramp terrain contact, while a post-touchdown typed joint command preserves a real hinged deployment instead of a pose teleport. The 45.7457 degree command is physical COM-relative geometry; the standalone render assembly uses the separately documented visual slope. */
    }
    requirement def GRR012_PhysicalDeckTransition {
        doc /* GRR-012 [blocked physical interface] each physical ramp shall have a separate horizontal deck-frame TransitionPlate with a ContactSurface collider, explicit rigid-body ownership, and a fixed attachment to the Griffin deck. Its overlap and width shall be derived from the composed octagonal TopDeckCollisionProxy, ramp hinge, terrain contact plane, and FLIP wheel envelope. The current 1.21 m value is a historical placeholder calculated from the obsolete six-sided collider; it is not a requirement value and shall not be accepted. Verification requires composed geometry observations and must remain inconclusive until the octagonal collider is authored in Editor, read back, and used to recompute the transition. Source: https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/; https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; twin://astrobotic-griffin-1/research/griffin_1_assumptions.md. The transition remains a separate component rather than geometry parented to the rotating ramp. Mass and inertia values remain replaceable simulator assumptions pending a mechanical ICD. */
        require GRC012_TransitionOverlapWithinSurface;
    }

    requirement grr001 : GRR001_RampTopology { subject ramp : GriffinEgressRamp; }
    requirement grr002 : GRR002_RampHinge { subject ramp : GriffinEgressRamp; }
    requirement grr003 : GRR003_RampEnvelope { subject ramp : GriffinEgressRamp; }
    requirement grr004 : GRR004_RampPlacement { subject ramp : GriffinEgressRamp; }
    requirement grr005 : GRR005_RampBehavior { subject ramp : GriffinEgressRamp; }
    requirement grr006 : GRR006_RampGeometry { subject ramp : GriffinEgressRamp; }
    requirement grr007 : GRR007_RampEvidence { subject ramp : GriffinEgressRamp; }
    requirement grr008 : GRR008_RailGeometry { subject ramp : GriffinEgressRamp; }
    requirement grr009 : GRR009_SupportArmGeometry { subject ramp : GriffinEgressRamp; }
    requirement grr013 : GRR013_TractionTreadGeometry { subject ramp : GriffinEgressRamp; }
    requirement grr014 : GRR014_RampLoadPathGeometry { subject ramp : GriffinEgressRamp; }
    requirement grr015 : GRR015_RampHingeGussetGeometry { subject ramp : GriffinEgressRamp; }
    requirement grr010 : GRR010_PhysicalEgressEnvelope { subject ramp : GriffinEgressRamp; }
    requirement grr011 : GRR011_PhysicalDeploymentLifecycle { subject ramp : GriffinEgressRamp; }
    requirement grr012 : GRR012_PhysicalDeckTransition { subject ramp : GriffinEgressRamp; }

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
