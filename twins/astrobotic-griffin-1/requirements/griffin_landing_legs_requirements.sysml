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
        // The exact landing-leg ICD is not public. Round tubes keep the
        // revised 1.40 m load path readable without the broad, slab-like silhouette
        // made by 0.28 m square members. This radius is a replaceable visual
        // study assumption, not a structural sizing claim.
        attribute strutRadiusM : Real = 0.08;
        attribute strutHeightM : Real = 1.40;
        attribute strutAxis : Direction = (0.0, 1.0, 0.0);
        attribute strutOuterCenterXM : Real = .20;
        attribute strutInnerCenterXM : Real = -.20;
        attribute strutCenterYM : Real = -.57;
        // Positive/negative signs make the lower ends splay toward the foot
        // while the upper ends meet the bus clevis.  This is the load-path
        // presentation assumption; the public Griffin material confirms
        // four shock-absorbing legs but does not publish the strut angles.
        attribute strutOuterTiltZDeg : Real = 16.0;
        attribute strutInnerTiltZDeg : Real = -16.0;
        attribute shockPistonRadiusM : Real = 0.13;
        // The piston spans from the upper clevis datum (+0.12 m) toward the
        // load plate, keeping the visible central load path continuous. This
        // is a presentation study assumption; the Griffin shock ICD is not
        // public.
        attribute shockPistonHeightM : Real = 1.15;
        attribute shockPistonCenterYM : Real = -.45;
        attribute footPadRadiusM : Real = .35;
        attribute footPadHeightM : Real = .12;
        attribute footPadCenterYM : Real = -1.15;
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
        attribute mountClevisWidthM : Real = 0.42;
        attribute mountClevisHeightM : Real = 0.24;
        attribute mountClevisDepthM : Real = 0.36;
        attribute mountClevisCenterYM : Real = 0.12;
        attribute footPadPlateWidthM : Real = .62;
        attribute footPadPlateHeightM : Real = .10;
        attribute footPadPlateDepthM : Real = .48;
        attribute footPadPlateCenterYM : Real = -1.07;
    }

    requirement def GLL001_LegCount {
        doc /* GLL-001 [topology] every instance in the typed landing-leg identity collection is present and visible. */
    }
    requirement def GLL002_LegStructure {
        doc /* GLL-002 [visual] every landing leg exposes a bus-mount arm, two canted tubular load struts, a shock piston, a mount clevis pair, an axle, and a load-spreading foot pad/plate. These render-only members make the load path inspectable without claiming flight-collider ownership. */
    }
    requirement def GLL003_LegFrame {
        doc /* GLL-003 [layout] four leg stations extend beyond the source-owned octagonal body. The approximate 4.50 m pad-edge footprint is an older-envelope-informed reconstruction, with rationale and configuration limitations in griffin-size-evidence.md. */
    }
    requirement def GLL004_LegTraceability {
        doc /* GLL-004 [evidence] leg identities come from GriffinVisualConfigurationRequirements and their collection cardinality agrees with the typed lander count. */
    }
    requirement def GLL005_LegPlacement {
        doc /* GLL-005 [layout] visual and physical landing-leg roots match the same ordered native Position stations and outward-facing rotations owned by GriffinVisualConfiguration. Each root mounts directly below the corresponding octagonal bus side; there is no second physical station table. */
    }
    requirement def GLL006_StrutGeometry {
        doc /* GLL-006 [geometry] two cylindrical struts use the typed radius, height, centers and mirrored Z rotations. Shortened geometry is a packaging estimate connecting the revised bus mount to the pad, not supplier structural sizing; see griffin-size-evidence.md. */
    }
    requirement def GLL007_ShockPistonGeometry {
        doc /* GLL-007 [geometry] the Y-axis shock piston uses the typed radius, height and local center. Its shortened clevis-to-pad path is an explicit packaging estimate in griffin-size-evidence.md. */
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
        doc /* GLL-008 [contact geometry] each dynamics leg root shall match the ordered COM-frame legStations and legStationRotationYDeg in GriffinVisualConfiguration. Its hidden Y-axis cylinder contact proxy shall be generated from the composed visible FootPad cylinder and link to it through a typed USD relationship. The effective Avian-cooked contact cylinder shall match the composed visible FootPad cylinder in radius, height, Y-axis orientation, and center within the authored tolerance after both geometries are compared in the canonical-stage metre frame. The visible component remains the geometry source; only the proxy owns contact, and legacy strut/capsule proxies shall not also collide. The 0.92 m by 0.72 m load plate remains visible above the pad. */
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
        doc /* GLL-009 [mechanical interface] each leg's visible BodyMountArm shall overlap the octagonal PerimeterFrame and its MountAxle by at least bodyMountOverlapM. The physical prismatic suspension joint shall connect the leg rigid body to the lander at the same typed leg station, with local frames that preserve the source-owned leg orientation when initially seated. Mount geometry is derived from the bus envelope, frame section, leg station, and clevis dimensions; it is not a second placement table. The explicit measurement tolerance covers floating-point bound readback only and does not reduce the physical overlap datum. */
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
