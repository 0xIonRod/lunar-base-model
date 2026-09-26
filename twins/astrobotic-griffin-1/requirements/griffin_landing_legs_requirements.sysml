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
        // 2.60 m load path readable without the broad, slab-like silhouette
        // made by 0.28 m square members. This radius is a replaceable visual
        // study assumption, not a structural sizing claim.
        attribute strutRadiusM : Real = 0.08;
        attribute strutHeightM : Real = 2.60;
        attribute strutAxis : Direction = (0.0, 1.0, 0.0);
        attribute strutOuterCenterXM : Real = 0.34;
        attribute strutInnerCenterXM : Real = -0.34;
        attribute strutCenterYM : Real = -1.15;
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
        attribute shockPistonHeightM : Real = 1.85;
        attribute shockPistonCenterYM : Real = -0.82;
        attribute footPadRadiusM : Real = 0.52;
        attribute footPadHeightM : Real = 0.18;
        attribute footPadCenterYM : Real = -2.05;
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
        attribute footPadPlateWidthM : Real = 0.92;
        attribute footPadPlateHeightM : Real = 0.16;
        attribute footPadPlateDepthM : Real = 0.72;
        attribute footPadPlateCenterYM : Real = -1.93;
    }

    requirement def GLL001_LegCount {
        doc /* GLL-001 [topology] every instance in the typed landing-leg identity collection is present and visible. */
    }
    requirement def GLL002_LegStructure {
        doc /* GLL-002 [visual] every landing leg exposes a bus-mount arm, two canted tubular load struts, a shock piston, a mount clevis pair, an axle, and a load-spreading foot pad/plate. These render-only members make the load path inspectable without claiming flight-collider ownership. */
    }
    requirement def GLL003_LegFrame {
        doc /* GLL-003 [layout] leg stations use the signed X/Z body frame, extend beyond the enlarged 5.40 m octagonal core, and remain separate replaceable components. */
    }
    requirement def GLL004_LegTraceability {
        doc /* GLL-004 [evidence] leg identities come from GriffinVisualConfigurationRequirements and their collection cardinality agrees with the typed lander count. */
    }
    requirement def GLL005_LegPlacement {
        doc /* GLL-005 [layout] visual and physical landing-leg roots match the same ordered native Position stations and outward-facing rotations owned by GriffinVisualConfiguration. Each root mounts directly below the corresponding octagonal bus side; there is no second physical station table. */
    }
    requirement def GLL006_StrutGeometry {
        doc /* GLL-006 [geometry] each leg shall expose two cylindrical struts of 0.08 m radius and 2.60 m height, aligned with the typed local +Y axis, centered at X = +/-0.34 m and Y = -1.15 m, with the declared mirrored Z rotations; the upper ends meet the clevis and the lower ends splay toward the foot plate. The radius is an explicit visual-study assumption because the supplier does not publish the leg-member section. */
    }
    requirement def GLL007_ShockPistonGeometry {
        doc /* GLL-007 [geometry] the shock piston shall be a Y-axis cylinder of radius 0.13 m and height 1.85 m centered at local Y = -0.82 m, spanning the clevis-to-load-plate visual path. */
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
        doc /* GLL-008 [contact geometry] each dynamics leg root shall match the ordered COM-frame legStations and legStationRotationYDeg in GriffinVisualConfiguration. Its hidden Y-axis cylinder contact proxy shall be generated from the composed visible FootPad cylinder and link to it through a typed USD relationship. Proxy and visual geometry bounds, radius, height, and leg-local center shall agree with the typed SysML dimensions within the authored tolerance. The visible component remains the geometry source; only the proxy owns contact, and legacy strut/capsule proxies shall not also collide. The 0.92 m by 0.72 m load plate remains visible above the pad. These replaceable dimensions are study values because the supplier leg ICD is not public. */
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
    requirement def GLL009_BusMountConnection {
        require GLLC009_BusAndAxleOverlap {
            in requiredOverlapM = GriffinLandingLegAssembly::bodyMountOverlapM;
            in measurementToleranceM = GriffinLandingLegAssembly::bodyMountOverlapMeasurementToleranceM;
        }
        doc /* GLL-009 [mechanical interface] each leg's visible BodyMountArm shall overlap the octagonal PerimeterFrame and its MountAxle by at least bodyMountOverlapM. The physical prismatic suspension joint shall connect the leg rigid body to the lander at the same typed leg station. Mount geometry is derived from the bus envelope, frame section, leg station, and clevis dimensions; it is not a second placement table. The explicit measurement tolerance covers floating-point bound readback only and does not reduce the physical overlap datum. */
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
        }
    }
}
