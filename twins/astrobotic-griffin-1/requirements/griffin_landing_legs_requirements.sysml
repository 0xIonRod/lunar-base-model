package GriffinLandingLegRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Boolean;
    private import ScalarValues::String;
    private import VectorValues::CartesianThreeVectorValue;

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
    }

    part def GriffinLandingLegAssembly {
        attribute usdRootPath : String = "/World/Griffin1";
        attribute componentAsset : String = "components/lander/griffin_landing_leg_visual.usda";
        attribute childNames : GriffinLandingLegChild[8] =
            ("StrutOuter", "StrutInner", "ShockPiston", "FootPad",
             "MountClevisOuter", "MountClevisInner", "FootPadPlate", "MountAxle");
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
        // The dynamics assembly has its own COM-frame leg mounts. These
        // stations are distinct from the standalone visual review frame.
        attribute physicalLegStations : Position[4] =
            ((3.10, -1.55, 0.0), (-3.10, -1.55, 0.0),
             (0.0, -1.55, 3.10), (0.0, -1.55, -3.10));
        attribute physicalLegStationRotationYDeg : Real[4] = (0.0, 0.0, 90.0, 90.0);
        attribute physicalLegPlacementToleranceM : Real = 0.001;
        attribute padColliderToleranceM : Real = 0.001;
        attribute mountClevisWidthM : Real = 0.42;
        attribute mountClevisHeightM : Real = 0.24;
        attribute mountClevisDepthM : Real = 0.36;
        attribute mountClevisCenterYM : Real = 0.12;
        attribute footPadPlateWidthM : Real = 0.92;
        attribute footPadPlateHeightM : Real = 0.16;
        attribute footPadPlateDepthM : Real = 0.72;
        attribute footPadPlateCenterYM : Real = -1.93;
        attribute collisionPolicy : String = "flight leg and pad colliders own contact; visual struts remain presentation geometry";
        attribute placementFrame : String = "signed X/Z body axes; local Y is vertical";
        attribute sourceReference : String = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute sourceFact : String = "Griffin has four legs that absorb shock and stabilize the lander during touchdown";
        attribute sourceRationale : String = "Legs are a repeated load-bearing subassembly with an independent visual/collision contract and a mount datum at each bus corner";
        attribute geometryStatus : String = "metric visual study proxy; shock absorber dimensions are not public";
    }

    requirement def GLL001_LegCount {
        doc /* GLL-001 [topology] every instance in the typed landing-leg identity collection is present and visible. */
    }
    requirement def GLL002_LegStructure {
        doc /* GLL-002 [visual] every landing leg exposes two canted tubular load struts, a shock piston, a mount clevis pair, an axle, and a load-spreading foot pad/plate. These render-only members make the load path inspectable without claiming flight-collider ownership. */
    }
    requirement def GLL003_LegFrame {
        doc /* GLL-003 [layout] leg stations use the signed X/Z body frame, extend beyond the enlarged 5.40 m octagonal core, and remain separate replaceable components. */
    }
    requirement def GLL004_LegTraceability {
        doc /* GLL-004 [evidence] leg identities come from GriffinVisualConfigurationRequirements and their collection cardinality agrees with the typed lander count. */
    }
    requirement def GLL005_LegPlacement {
        doc /* GLL-005 [layout] standalone visual leg roots and physical landing-leg roots match their ordered native Position stations. Both sets use the same 3.10 m signed X/Z footprint; their Y datums remain distinct because the visual assembly and dynamics model use different roots. */
    }
    requirement def GLL006_StrutGeometry {
        doc /* GLL-006 [geometry] each leg shall expose two cylindrical struts of 0.08 m radius and 2.60 m height, aligned with the typed local +Y axis, centered at X = +/-0.34 m and Y = -1.15 m, with the declared mirrored Z rotations; the upper ends meet the clevis and the lower ends splay toward the foot plate. The radius is an explicit visual-study assumption because the supplier does not publish the leg-member section. */
    }
    requirement def GLL007_ShockPistonGeometry {
        doc /* GLL-007 [geometry] the shock piston shall be a Y-axis cylinder of radius 0.13 m and height 1.85 m centered at local Y = -0.82 m, spanning the clevis-to-load-plate visual path. */
    }
    constraint def GLLC008_PadColliderMatchesVisual {
        in geometryDeviationM : Real;
        in toleranceM : Real;
        geometryDeviationM <= toleranceM;
    }

    constraint def GLLC008_PadColliderOwnsContact {
        in collisionEnabled : Boolean;
        in proxyHidden : Boolean;
        in visualCollisionDisabled : Boolean;
        in collisionMatchesVisual : Boolean;
        in legacyCollisionDisabled : Boolean;
        collisionEnabled and proxyHidden and visualCollisionDisabled
            and collisionMatchesVisual and legacyCollisionDisabled;
    }

    constraint def GLLC008_PadColliderStationMatchesSource {
        in stationDeviationM : Real;
        in toleranceM : Real;
        in rotationMatches : Boolean;
        stationDeviationM <= toleranceM and rotationMatches;
    }

    requirement def GLL008_FootPadGeometry {
        require GLLC008_PadColliderMatchesVisual;
        require GLLC008_PadColliderOwnsContact;
        require GLLC008_PadColliderStationMatchesSource;
        doc /* GLL-008 [contact geometry] each dynamics leg root shall match the ordered COM-frame physicalLegStations and physicalLegStationRotationYDeg, and shall use a hidden Y-axis cylinder contact proxy whose radius, height, and leg-local center exactly match the source-owned visible FootPad cylinder within the authored tolerances. The visual LandingLeg component and hidden contact proxy are both derived from these SysML datums; legacy strut and capsule proxies shall not also own terrain contact. The 0.92 m by 0.72 m load plate remains visible geometry above the pad. These are replaceable study dimensions because the supplier leg ICD is not public. */
    }

    requirement gll001 : GLL001_LegCount { subject legs : GriffinLandingLegAssembly; }
    requirement gll002 : GLL002_LegStructure { subject legs : GriffinLandingLegAssembly; }
    requirement gll003 : GLL003_LegFrame { subject legs : GriffinLandingLegAssembly; }
    requirement gll004 : GLL004_LegTraceability { subject legs : GriffinLandingLegAssembly; }
    requirement gll005 : GLL005_LegPlacement { subject legs : GriffinLandingLegAssembly; }
    requirement gll006 : GLL006_StrutGeometry { subject legs : GriffinLandingLegAssembly; }
    requirement gll007 : GLL007_ShockPistonGeometry { subject legs : GriffinLandingLegAssembly; }
    requirement gll008 : GLL008_FootPadGeometry { subject legs : GriffinLandingLegAssembly; }

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
        }
    }
}
