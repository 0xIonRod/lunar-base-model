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
        // Local +X points outward along a chamfer normal, Y up, Z tangential.
        // Body edge radius = 1.80*(1+.5857864376269049)/sqrt(2) = 2.0183766 m.
        // Foot/root radius = 1.90*sqrt(2) = 2.6870058 m. Their difference is
        // the primary local upper X datum. Both are reconstruction estimates.
        // Brace tops lie at skirt-frame world X/Z=(1.56,.68) and (.68,1.56)
        // for the +X/+Z corner. Rotate them into this shared leg frame:
        // upper X=(1.56+.68)/sqrt(2)-foot radius; tangential Z=+/- .88/sqrt(2).
        // Y=.10 = skirt mount 1.00 - root .90. The .68 m tangential rail
        // station remains a packaging estimate. Endpoint poses derive once
        // from these datums; no independent cylinder length/angle guesses.
        attribute loadMembers : GriffinLandingLegChild[3] =
            ("ShockPiston", "StrutOuter", "StrutInner");
        attribute memberUpperAnchors : Position[3] =
            ((-0.668629150101524, 0.0, 0.0), (-1.103086578651014, .10, 0.622253967444162), (-1.103086578651014, .10, -0.622253967444162));
        attribute memberLowerAnchor : Position = (0.0, -1.26, 0.0);
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
        // Remove the legacy -0.43 m whole-leg rest translation by baking that
        // offset only into the foot/hub nominal datums. Upper anchors stay at
        // their bus/skirt stations. At body Y=.44 the pad bottom remains Y=0;
        // the 4.50 m X/Z footprint is unchanged. No ground mesh is moved.
        attribute footPadCenterYM : Real = -1.32;
        // Axial suspension study values. The target is zero at the nominal
        // seated linkage pose; nominal foot height follows the touchdown datum.
        attribute springLowerLimitM : Real = -0.15;
        attribute springUpperLimitM : Real = 0.02;
        attribute springStiffnessNPerM : Real = 40000.0;
        attribute springDampingNsPerM : Real = 8000.0;
        attribute springMaxForceN : Real = 12000.0;
        // Replaceable mechanics study, not flight hardware specifications.
        // 150 mm compression / 20 mm rebound, 40 kN/m axial stiffness and
        // 8 kNs/m damping give roughly 55 mm static stroke at a 2.2 kN/leg
        // lunar load before linkage leverage. The previous 0.80 m whole-leg
        // slider moved the bus anchors; it was not shock absorption geometry.
        // Existing 180 kg/leg study mass is conserved: 160 kg V-brace/foot,
        // 10 kg barrel and 10 kg piston. These masses are uncalibrated proxies.
        attribute braceFootMassKg : Real = 160.0;
        attribute shockBarrelMassKg : Real = 10.0;
        attribute shockPistonMassKg : Real = 10.0;
        attribute shockBarrelLengthFraction : Real = 0.72;
        attribute shockPistonLengthFraction : Real = 0.65;
        attribute shockPistonRadiusFraction : Real = 0.70;
        attribute hingeTravelDeg : Real = 45.0;
        attribute springTargetVelocityMps : Real = 0.00;
        attribute springPoseToleranceM : Real = 0.001;
        // Physical and visual roots use the single shared leg stations and
        // outward-facing rotations in GriffinVisualConfiguration.
        attribute physicalLegPlacementToleranceM : Real = 0.001;
        attribute physicalLegRotationToleranceDeg : Real = 0.001;
        // Numerical anti-tunneling policy, not an Astrobotic hardware datum.
        // The 40 mm pads can cross the 100 mm site slab between collision
        // samples during an impact. Sweep the physical leg body against
        // native terrain/solid colliders; never move the rendered pad alone.
        // Source: NVIDIA PhysxRigidBodyAPI physxRigidBody:enableCCD;
        // https://docs.omniverse.nvidia.com/kit/docs/omni_physics/107.2/dev_guide/schemas/physxschema.html
        // Backend: Avian 0.7 SweptCcd NON_LINEAR (translation and rotation).
        attribute continuousCollisionDetection : Boolean = true;
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
        attribute footPadPlateCenterYM : Real = -1.28;
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
        doc /* GLL-005 [layout] visual and physical landing-leg roots match the same ordered native Position stations and outward-facing rotations owned by GriffinVisualConfiguration. Each root sits outward of a different chamfered bus corner; the primary upper anchor meets that chamfer midpoint below the body belt; there is no second physical station table. */
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
        doc /* GLL-007 [geometry] the primary cylindrical shock member connects the outer-frame attachment to the common foot-side hub using the first memberUpperAnchors datum and memberLowerAnchor. Derive length and pose from those endpoints, use shockPistonRadiusM and verify endpoint closure. Exact shock travel and flight joint mechanism are unpublished. Reconstruct a planar pinned V-brace plus a telescoping primary shock: brace hinge at the midpoint of the two fixed skirt anchors, shock upper pin at the outer-frame anchor, axial prismatic joint between the barrel and piston, and lower pin at the common foot hub. All three pins use the tangential axis; the slider follows the inclined primary member and is zero-seated at the nominal pose, with negative displacement denoting compression. This idealized mechanism is inferred from the three-member load path in https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png and the shock-absorbing function in https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ ; it is not a supplier linkage ICD. */
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
        doc /* GLL-008 [contact geometry] each dynamics leg root shall match the ordered COM-frame legStations and legStationRotationYDeg in GriffinVisualConfiguration. Its hidden Y-axis cylinder contact proxy shall be generated from the composed visible FootPad cylinder and link to it through a typed USD relationship. The effective Avian-cooked contact cylinder shall match the composed visible FootPad cylinder in radius, height, Y-axis orientation, and center within the authored tolerance after both geometries are compared in the canonical-stage metre frame. The visible component remains the geometry source; only the proxy owns contact, and legacy strut/capsule proxies shall not also collide. The visible load-spreading plate shall use the typed footPadPlateWidthM, footPadPlateHeightM, footPadPlateDepthM, and footPadPlateCenterYM datums.  The physical leg body shall use the source continuousCollisionDetection policy so thin pad contact is swept through time, rather than accepted from endpoint overlap alone. A runtime landing/impact test must separately establish terrain clearance; source geometry agreement is not that verdict. */
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
        doc /* At the zero-articulation starting pose, the body rotation implied by each brace hinge's two local frames shall match its composed leg-body rotation within physicalLegRotationToleranceDeg. */
        in seatingErrorDeg : Real;
        in toleranceDeg : Real;
        seatingErrorDeg <= toleranceDeg;
    }
    requirement def GLL009_BusMountConnection {
        require GLLC006_MemberClosure;
        require GLLC009_BusAndAxleOverlap {
            in requiredOverlapM = GriffinLandingLegAssembly::bodyMountOverlapM;
            in measurementToleranceM = GriffinLandingLegAssembly::bodyMountOverlapMeasurementToleranceM;
        }
        require GLLC009_SpringFrameAlignment {
            in toleranceDeg = GriffinLandingLegAssembly::physicalLegRotationToleranceDeg;
        }
        doc /* GLL-009 [mechanical interface] each leg's visible BodyMountArm shall overlap the octagonal PerimeterFrame and its MountAxle by at least bodyMountOverlapM. The brace hinge shall connect the V-brace/foot body to the bus at the midpoint of its two skirt anchors. The primary shock upper and lower pins shall remain attached to the bus and foot hub while the axial spring slides only the piston inside the barrel. Mount sleeves, clevises and the bus bracket belong to the bus, not the translating foot or piston. The four joints form one closed planar mechanism per leg; both halves of every joint frame shall coincide at the nominal pose. The sleeve upper edge shall meet the body belt lower edge within the endpoint tolerance, so the primary shock stays below the side panel. A vertical bus-mount bracket connects that sleeve to the lower perimeter ring. Mount geometry is derived from the bus envelope, frame section, leg station, and clevis dimensions; it is not a second placement table. The explicit measurement tolerance covers floating-point bound readback only and does not reduce the physical overlap datum. */
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
        vehicleReferenceTouchdownY + legMountY
                + footPadCenterY - footPadHeightM / 2.0
            >= siteSurfaceY - toleranceM
            and vehicleReferenceTouchdownY + legMountY
                + footPadCenterY - footPadHeightM / 2.0
            <= siteSurfaceY + toleranceM
            and springTargetPositionY >= -toleranceM
            and springTargetPositionY <= toleranceM
            and springTargetPositionY >= springLowerLimitY
            and springTargetPositionY <= springUpperLimitY;
    }
    requirement def GLL010_SpringRestPose {
        require GLLC010_SpringRestPoseMatchesTouchdownDatum {
            in toleranceM = GriffinLandingLegAssembly::springPoseToleranceM;
        }
        doc /* GLL-010 [landing interface] the zero-seated axial shock and nominal leg linkage place each unloaded foot-pad bottom on the landing surface when the body reference is at its powered-descent touchdown datum. The spring target is zero because both shock frames are seated at the nominal foot hub; that nominal pose derives from the touchdown datum, shared leg station and composed pad geometry. Zero must lie inside the axial travel limits. Spring stiffness, damping, limits, and force capacity are explicit replaceable study assumptions because the supplier leg ICD is unavailable. */
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
