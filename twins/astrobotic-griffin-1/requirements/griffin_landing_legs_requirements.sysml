package GriffinLandingLegRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Boolean;
    private import VectorValues::CartesianThreeVectorValue;
    private import GriffinRequirementSources::TwinAssetPath;
    private import GriffinRequirementSources::UsdPrimPath;

    attribute def Direction :> CartesianThreeVectorValue;
    attribute def Position :> CartesianThreeVectorValue;

    enum def GriffinLandingLegChild {
        StrutOuter;
        StrutInner;
        ShockPiston;
        FootPad;
        MountClevisOuter;
        MountClevisInner;
        FootPadPlate;
        MountAxle;
        BodyMountArm;
    }

    part def GriffinLandingLegAssembly {
        doc /* Public Griffin material confirms four shock-absorbing legs. The legs are a repeated load-bearing subassembly with an independent visual/collision contract and a mount datum at each bus corner; source links are owned by the typed requirement-evidence catalog. */
        attribute usdRootPath : UsdPrimPath = "/World/Griffin1";
        attribute componentAsset : TwinAssetPath = "components/lander/griffin_landing_leg_visual.usda";
        attribute childNames : GriffinLandingLegChild[9] =
            ("StrutOuter", "StrutInner", "ShockPiston", "FootPad",
             "MountClevisOuter", "MountClevisInner", "FootPadPlate", "MountAxle",
             "BodyMountArm");
        // Three-member topology follows the user-provided PGH Tech hardware
        // photograph. The source has perspective and no calibrated scale.
        // Coordinates below are explicit packaging estimates: local +X outward,
        // Y up, Z tangential. Main top meets the outer bus mount; brace tops
        // meet the current skirt's X=1.56 m rail at two separated Z stations.
        // Root Y=.90 puts the sleeve below the body belt. Primary local Y=0;
        // brace X=-.34 = skirt rail X1.56 - root X1.90, and Y=.10 =
        // skirt mount Y1.00 - root Y.90. These are interface derivations.
        attribute loadMembers : GriffinLandingLegChild[3] =
            ("ShockPiston", "StrutOuter", "StrutInner");
        attribute memberUpperAnchors : Position[3] =
            ((-.10, 0.0, 0.0), (-.34, .10, .68), (-.34, .10, -.68));
        attribute memberLowerAnchor : Position = (0.0, -.83, 0.0);
        // Diameter estimates: 0.12 m main shock and 0.07 m braces. These
        // approximate the slender primary/secondary silhouette, not a flight
        // tube section or wall thickness. Length/center/rotation are derived
        // from the endpoint datums, not separately estimated.
        attribute strutRadiusM : Real = .035;
        attribute strutAxis : Direction = (0.0, 1.0, 0.0);
        attribute shockPistonRadiusM : Real = .06;
        attribute memberEndpointToleranceM : Real = .002;
        attribute footPadRadiusM : Real = .35;
        attribute footPadHeightM : Real = .04;
        // Root moves down .30 m; local foot datums rise .30 m to preserve
        // vehicle-frame foot bottom -.01 m and the 4.50 m footprint.
        // Thin the pad rather than moving terrain/contact or the leg station.
        attribute footPadCenterYM : Real = -.89;
        // Suspension study values. The spring rest target is derived from the
        // authored vehicle touchdown datum, leg mount, pad, and site surface;
        // it is not a second hand-entered pose value.
        attribute springLowerLimitM : Real = -0.80;
        attribute springUpperLimitM : Real = 0.00;
        attribute springStiffnessNPerM : Real = 4000.0;
        attribute springDampingNsPerM : Real = 800.0;
        attribute springMaxForceN : Real = 12000.0;
        attribute springTargetVelocityMps : Real = 0.00;
        attribute springPoseToleranceM : Real = 0.001;
        // Physical and visual roots use the single shared leg stations and
        // outward-facing rotations in GriffinVisualConfiguration.
        attribute physicalLegPlacementToleranceM : Real = 0.001;
        attribute physicalLegRotationToleranceDeg : Real = 0.001;
        attribute padColliderToleranceM : Real = 0.001;
        attribute bodyMountOverlapM : Real = 0.05;
        // Numerical allowance for composed floating-point bound arithmetic;
        // it does not change the physical minimum-overlap datum.
        attribute bodyMountOverlapMeasurementToleranceM : Real = 0.000001;
        attribute mountClevisWidthM : Real = .16;
        attribute mountClevisHeightM : Real = .16;
        attribute mountClevisDepthM : Real = .12;
        attribute mountClevisCenterYM : Real = 0.0;
        // Visual correction requested in the assembly review: the bus-side
        // cylindrical mount sleeve follows local +X, along BodyMountArm.
        // Its center is the primary member's upper anchor. This render-only
        // sleeve is not the axis of the physical prismatic suspension joint.
        // This is an explicit interface reconstruction, not a flight ICD datum.
        attribute mountAxleAxis : Direction = (1.0, 0.0, 0.0);
        attribute footPadPlateWidthM : Real = .42;
        attribute footPadPlateHeightM : Real = .04;
        attribute footPadPlateDepthM : Real = .36;
        attribute footPadPlateCenterYM : Real = -.85;
    }

    requirement def GLL001_LegCount {
        doc /* GLL-001 [topology] every instance in the typed landing-leg identity collection is present and visible. */
    }
    requirement def GLL002_LegStructure {
        doc /* GLL-002 [visual] every landing leg exposes a bus-mount arm, two diagonal skirt braces and one primary shock member, a mount clevis pair, an axle, and a load-spreading foot pad/plate. These render-only members make the load path inspectable without claiming flight-collider ownership. */
    }
    requirement def GLL003_LegFrame {
        doc /* GLL-003 [layout] the four leg stations and pad envelopes extend beyond the source-owned octagonal body. The resulting footprint is derived from the typed stations and pad geometry; its evidence and configuration limits are recorded in griffin-size-evidence.md. */
    }
    requirement def GLL004_LegTraceability {
        doc /* GLL-004 [evidence] leg identities come from GriffinVisualConfigurationRequirements and their collection cardinality agrees with the typed lander count. */
    }
    requirement def GLL005_LegPlacement {
        doc /* GLL-005 [layout] visual and physical landing-leg roots match the same ordered native Position stations and outward-facing rotations owned by GriffinVisualConfiguration. Each root mounts directly below the corresponding octagonal bus side; there is no second physical station table. */
    }
    constraint def GLLC006_MemberClosure {
        in measuredUpperEndpointErrorM : Real;
        in measuredLowerEndpointErrorM : Real;
        in toleranceM : Real;
        measuredUpperEndpointErrorM <= toleranceM
            and measuredLowerEndpointErrorM <= toleranceM
    }
    requirement def GLL006_StrutGeometry {
        require GLLC006_MemberClosure;
        doc /* GLL-006 [geometry] two slender cylindrical braces connect the common foot-side hub to two separated skirt attachment datums. Their lengths and poses derive from memberUpperAnchors and memberLowerAnchor; composed cylinder endpoints shall close to those datums within memberEndpointToleranceM. Topology is reference-informed by https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png; numerical datums and sections are replaceable packaging estimates, not supplier structural sizing. */
    }
    requirement def GLL007_ShockPistonGeometry {
        require GLLC006_MemberClosure;
        doc /* GLL-007 [geometry] the primary cylindrical shock member connects the outer-frame attachment to the common foot-side hub using the first memberUpperAnchors datum and memberLowerAnchor. Derive length and pose from those endpoints, use shockPistonRadiusM and verify endpoint closure. Exact shock travel and flight joint mechanism are unpublished; the present prismatic dynamics proxy moves the whole visual leg, so moving upper-attachment kinematics remain unqualified. */
    }
    constraint def GLLC008_PadColliderMatchesVisual {
        in geometryDeviationM : Real;
        in sourceRadiusDeviationM : Real;
        in sourceHeightDeviationM : Real;
        in sourceCenterDeviationM : Real;
        in padGeometrySemanticsMatch : Boolean;
        in toleranceM : Real;
        geometryDeviationM <= toleranceM
            and sourceRadiusDeviationM <= toleranceM
            and sourceHeightDeviationM <= toleranceM
            and sourceCenterDeviationM <= toleranceM
            and padGeometrySemanticsMatch;
    }

    constraint def GLLC008_PadColliderOwnsContact {
        in collisionEnabled : Boolean;
        in proxyHidden : Boolean;
        in visualCollisionDisabled : Boolean;
        in collisionMatchesVisual : Boolean;
        in geometrySourceLinked : Boolean;
        in selfCollisionFilterClear : Boolean;
        in legacyCollisionDisabled : Boolean;
        collisionEnabled and proxyHidden and visualCollisionDisabled
            and collisionMatchesVisual and geometrySourceLinked
            and selfCollisionFilterClear and legacyCollisionDisabled;
    }

    constraint def GLLC008_PadColliderStationMatchesSource {
        in stationDeviationM : Real;
        in toleranceM : Real;
        in rotationMatches : Boolean;
        stationDeviationM <= toleranceM and rotationMatches;
    }

    requirement def GLL008_FootPadGeometry {
        require GLLC008_PadColliderMatchesVisual {
            in toleranceM = GriffinLandingLegAssembly::padColliderToleranceM;
        }
        require GLLC008_PadColliderOwnsContact;
        require GLLC008_PadColliderStationMatchesSource {
            in toleranceM = GriffinLandingLegAssembly::physicalLegPlacementToleranceM;
        }
        doc /* GLL-008 [contact geometry] each dynamics leg root shall match the ordered COM-frame legStations and legStationRotationYDeg in GriffinVisualConfiguration. Its hidden Y-axis cylinder contact proxy shall be generated from the composed visible FootPad cylinder and link to it through a typed USD relationship. The effective Avian-cooked contact cylinder shall match the composed visible FootPad cylinder in radius, height, Y-axis orientation, and center within the authored tolerance after both geometries are compared in the canonical-stage metre frame. The visible component remains the geometry source; only the proxy owns contact, and legacy strut/capsule proxies shall not also collide. The visible load-spreading plate shall use the typed footPadPlateWidthM, footPadPlateHeightM, footPadPlateDepthM, and footPadPlateCenterYM datums. */
    }
    constraint def GLLC009_BusAndAxleOverlap {
        in measuredBusOverlapM : Real;
        in measuredAxleOverlapM : Real;
        in requiredOverlapM : Real;
        in measurementToleranceM : Real;
        in physicalJointStationMatches : Boolean;
        measuredBusOverlapM + measurementToleranceM >= requiredOverlapM
            and measuredAxleOverlapM + measurementToleranceM >= requiredOverlapM
            and physicalJointStationMatches;
    }
    constraint def GLLC009_SpringFrameAlignment {
        doc /* At the zero-articulation starting pose, the body rotation implied by each prismatic joint's two local frames shall match its composed leg-body rotation within physicalLegRotationToleranceDeg. */
        in seatingErrorDeg : Real;
        in toleranceDeg : Real;
        seatingErrorDeg <= toleranceDeg;
    }
    requirement def GLL009_BusMountConnection {
        require GLLC009_BusAndAxleOverlap {
            in requiredOverlapM = GriffinLandingLegAssembly::bodyMountOverlapM;
            in measurementToleranceM = GriffinLandingLegAssembly::bodyMountOverlapMeasurementToleranceM;
        }
        require GLLC009_SpringFrameAlignment {
            in toleranceDeg = GriffinLandingLegAssembly::physicalLegRotationToleranceDeg;
        }
        doc /* GLL-009 [mechanical interface] each leg's visible BodyMountArm shall overlap the octagonal PerimeterFrame and its MountAxle by at least bodyMountOverlapM. The physical prismatic suspension joint shall connect the leg rigid body to the lander at the same typed leg station, with local frames that preserve the source-owned leg orientation when initially seated. The sleeve upper edge shall meet the body belt lower edge within the endpoint tolerance, so the primary shock stays below the side panel. A vertical bus-mount bracket connects that sleeve to the lower perimeter ring. Mount geometry is derived from the bus envelope, frame section, leg station, and clevis dimensions; it is not a second placement table. The explicit measurement tolerance covers floating-point bound readback only and does not reduce the physical overlap datum. */
    }
    constraint def GLLC010_SpringRestPoseMatchesTouchdownDatum {
        in vehicleReferenceTouchdownY : Real;
        in legMountY : Real;
        in springTargetPositionY : Real;
        in footPadCenterY : Real;
        in footPadHeightM : Real;
        in siteSurfaceY : Real;
        in springLowerLimitY : Real;
        in springUpperLimitY : Real;
        in toleranceM : Real;
        vehicleReferenceTouchdownY + legMountY + springTargetPositionY
                + footPadCenterY - footPadHeightM / 2.0
            >= siteSurfaceY - toleranceM
            and vehicleReferenceTouchdownY + legMountY + springTargetPositionY
                + footPadCenterY - footPadHeightM / 2.0
            <= siteSurfaceY + toleranceM
            and springTargetPositionY >= springLowerLimitY
            and springTargetPositionY <= springUpperLimitY;
    }
    requirement def GLL010_SpringRestPose {
        require GLLC010_SpringRestPoseMatchesTouchdownDatum {
            in toleranceM = GriffinLandingLegAssembly::springPoseToleranceM;
        }
        doc /* GLL-010 [landing interface] the source-owned prismatic spring target places each unloaded foot-pad bottom on the landing surface when the body reference is at its powered-descent touchdown datum. The target is derived from that datum, the shared leg station, and composed foot-pad geometry, and must lie inside the authored joint limits. Spring stiffness, damping, limits, and force capacity are explicit replaceable study assumptions because the supplier leg ICD is unavailable. */
    }

    requirement <'GLL-001'> gll001 : GLL001_LegCount { subject legs : GriffinLandingLegAssembly; }
    requirement <'GLL-002'> gll002 : GLL002_LegStructure { subject legs : GriffinLandingLegAssembly; }
    requirement <'GLL-003'> gll003 : GLL003_LegFrame { subject legs : GriffinLandingLegAssembly; }
    requirement <'GLL-004'> gll004 : GLL004_LegTraceability { subject legs : GriffinLandingLegAssembly; }
    requirement <'GLL-005'> gll005 : GLL005_LegPlacement { subject legs : GriffinLandingLegAssembly; }
    requirement <'GLL-006'> gll006 : GLL006_StrutGeometry { subject legs : GriffinLandingLegAssembly; }
    requirement <'GLL-007'> gll007 : GLL007_ShockPistonGeometry { subject legs : GriffinLandingLegAssembly; }
    requirement <'GLL-008'> gll008 : GLL008_FootPadGeometry { subject legs : GriffinLandingLegAssembly; }
    requirement <'GLL-009'> gll009 : GLL009_BusMountConnection { subject legs : GriffinLandingLegAssembly; }
    requirement <'GLL-010'> gll010 : GLL010_SpringRestPose { subject legs : GriffinLandingLegAssembly; }

    verification def Verify_GriffinLandingLegRequirements {
        subject legs : GriffinLandingLegAssembly;
        objective {
            verify gll001;
            verify gll002;
            verify gll003;
            verify gll004;
            verify gll005;
            verify gll006;
            verify gll007;
            verify gll008;
            verify gll009;
            verify gll010;
        }
    }
}
