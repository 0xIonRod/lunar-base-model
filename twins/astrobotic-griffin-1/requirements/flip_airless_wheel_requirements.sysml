package FlipAirlessWheelRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import ScalarValues::Boolean;
    private import GriffinRequirementSources::TwinAssetPath;
    private import GriffinRequirementSources::UsdPrimPath;

    enum def MaterialFamily { UnspecifiedMetal; StainlessSteelUnspecifiedGrade; ProprietaryElasticMaterial; }
    part def MaterialSelection {
        attribute family : MaterialFamily;
        attribute gradeReleased : Boolean = false;
    }
    part treadBladeMaterial : MaterialSelection { attribute family : MaterialFamily = "StainlessSteelUnspecifiedGrade"; }
    part elasticCarrierMaterial : MaterialSelection { attribute family : MaterialFamily = "ProprietaryElasticMaterial"; }
    part cableAndRimMaterial : MaterialSelection { attribute family : MaterialFamily = "UnspecifiedMetal"; }

    part def AirlessWheelVisual {
        doc /* SI metres, Y up, axle +Z, origin at hub centre. Detached render-only
         * reconstruction; wheel body, inertia, tire/contact and deformation
         * remain owned by the existing physical wheel. Venturi 2023 publishes
         * 930 mm diameter, 192 cables and four cable rows. Astrolab identifies
         * FLIP's full-size FLEX wheels. All other sizes, spring/tread detail,
         * material optical controls and drawing budget below are explicit
         * reconstruction choices, not released supplier dimensions/allowables.
         * Sources and validation: contracts/flip-airless-wheel-2026-10-23.md. */
        attribute componentAsset : TwinAssetPath = "components/rover/flip_airless_wheel_visual.usda";
        attribute usdPath : UsdPrimPath = "/World/AirlessWheel";
        attribute radiusM : Real = FlipRequirements::FlipRover::wheelRadiusM;
        attribute widthM : Real = FlipRequirements::FlipRover::wheelWidthM;
        attribute cableCount : Integer = 192;
        attribute cableRows : Integer = 4;
        attribute cablesPerRow : Integer = AirlessWheelVisual::cableCount / AirlessWheelVisual::cableRows;
        attribute springCount : Integer = 96;
        attribute treadBladeCount : Integer = AirlessWheelVisual::springCount;
        attribute rimRadiusM : Real = 0.35;
        attribute rimRadialStockM : Real = 0.012;
        attribute rimWidthM : Real = 0.18;
        attribute hubRadiusM : Real = 0.105;
        attribute axleApertureM : Real = 0.035;
        attribute hubWidthM : Real = 0.22;
        attribute fastenerRadiusM : Real = 0.004;
        attribute fastenerLengthM : Real = 0.006;
        attribute fastenerPitchRadiusM : Real = 0.075;
        attribute webCount : Integer = 12;
        attribute webAngularWidthRad : Real = 0.065;
        attribute webRakeRad : Real = 0.10;
        attribute webThicknessM : Real = 0.012;
        attribute cableRadiusM : Real = 0.0008;
        attribute cableLeadRad : Real = 0.065;
        attribute cableOuterRadiusM : Real = AirlessWheelVisual::radiusM - AirlessWheelVisual::treadThicknessM
            + AirlessWheelVisual::cableRadiusM;
        attribute treadThicknessM : Real = 0.009;
        attribute treadBladeThicknessM : Real = 0.001;
        attribute treadBladeAngularWidthRad : Real = 0.008;
        attribute springRadiusM : Real = 0.007;
        attribute springWireRadiusM : Real = 0.0012;
        attribute springLengthM : Real = 0.025;
        attribute cableInnerRadiusM : Real = AirlessWheelVisual::rimRadiusM + AirlessWheelVisual::springLengthM;
        attribute springTurns : Integer = 2;
        attribute springSamplesPerTurn : Integer = 8;
        attribute springsPerMesh : Integer = 8;
        attribute ringSegments : Integer = 96;
        attribute cableSegments : Integer = 8;
        attribute maximumTriangles : Integer = 40000;
        attribute maximumMeshes : Integer = 24;
        attribute geometryToleranceM : Real = 0.000002;
        attribute metalColor : Real[3] = (0.55, 0.58, 0.62);
        attribute metalMetallic : Real = 1.0;
        attribute metalRoughness : Real = 0.32;
        attribute cableColor : Real[3] = (0.38, 0.40, 0.42);
        attribute cableMetallic : Real = 1.0;
        attribute cableRoughness : Real = 0.28;
        attribute bladeColor : Real[3] = (0.48, 0.50, 0.52);
        attribute bladeMetallic : Real = 1.0;
        attribute bladeRoughness : Real = 0.30;
        attribute carrierColor : Real[3] = (0.025, 0.030, 0.035);
        attribute carrierMetallic : Real = 0.0;
        attribute carrierRoughness : Real = 0.58;
        attribute materialProjectionTolerance : Real = 0.000001;
        ref bladeSubstrate = treadBladeMaterial;
        ref treadBinder = elasticCarrierMaterial;
        ref remainingMetal = cableAndRimMaterial;
    }
    constraint def FAWC001_ContainedGeometry {
        in measuredRadiusErrorM : Real;
        in measuredWidthErrorM : Real;
        in maximumEnvelopeExcessM : Real;
        in maximumCableSeatErrorM : Real;
        in maximumCableTreadExcessM : Real;
        in topologyAndRoles : Boolean;
        in toleranceM : Real;
        topologyAndRoles and toleranceM > 0.0
            and measuredRadiusErrorM >= 0.0 and measuredRadiusErrorM <= toleranceM
            and measuredWidthErrorM >= 0.0 and measuredWidthErrorM <= toleranceM
            and maximumEnvelopeExcessM <= toleranceM
            and maximumCableSeatErrorM >= 0.0 and maximumCableSeatErrorM <= toleranceM
            and maximumCableTreadExcessM <= toleranceM;
    }
    requirement def FAW001_AirlessArchitecture {
        doc /* FAW-001 a reusable wheel visual shall expose an open machined hub/web,
         * annular rim, four rows totalling 192 cables, 96 visible spring packages
         * and thin transverse tread blades. Only diameter/cable architecture is
         * a published 2023 numerical baseline. Spring and blade placement/shape
         * are rigid visual estimates; no deformable tire simulation is claimed.
         * Every mesh shall be render-only, contain valid topology and remain
         * inside the source wheel cylinder. Each actual cable start cap shall
         * seat at an actual spring terminal-cap centre within geometryToleranceM,
         * with two cables per spring. Outer cap centres shall embed in the
         * measured elastic-carrier annulus. This is rendered connection closure,
         * not a rated fastening or load-transfer joint. HubAxis shall be centred
         * on +Z. */
        require FAWC001_ContainedGeometry { in toleranceM = AirlessWheelVisual::geometryToleranceM; }
    }
    requirement def FAW002_SurfaceRoles {
        doc /* FAW-002 standard UsdPreviewSurface materials shall distinguish exposed
         * metal, cable/spring metal, stainless tread blades and the dark elastic
         * carrier. Explicit bindings/connections and source-owned normalized
         * optical controls are mandatory. These are presentation estimates,
         * separate from the typed material-family selections and physical data. */
        require FlipChassisRequirements::FCCC006_NormalizedPreviewSurface;
    }
    constraint def FAWC003_RenderCost {
        in measuredMeshes : Integer;
        in measuredTriangles : Integer;
        in maximumMeshes : Integer;
        in maximumTriangles : Integer;
        measuredMeshes > 0 and measuredMeshes <= maximumMeshes
            and measuredTriangles > 0 and measuredTriangles <= maximumTriangles;
    }
    requirement def FAW003_RenderCost {
        doc /* FAW-003 the detached visual shall remain within maximumMeshes and
         * maximumTriangles, share its four material networks and add no bodies,
         * colliders, scripts or textures. This is a component cost budget; the
         * complete scene must separately meet 60 FPS at 1280x720 High with
         * real-time physics. */
        require FAWC003_RenderCost {
            in maximumMeshes = AirlessWheelVisual::maximumMeshes;
            in maximumTriangles = AirlessWheelVisual::maximumTriangles;
        }
    }
    requirement <'FAW-001'> faw001 : FAW001_AirlessArchitecture { subject wheel : AirlessWheelVisual; }
    requirement <'FAW-002'> faw002 : FAW002_SurfaceRoles { subject wheel : AirlessWheelVisual; }
    requirement <'FAW-003'> faw003 : FAW003_RenderCost { subject wheel : AirlessWheelVisual; }
    verification def Verify_FLIPAirlessWheel {
        subject wheel : AirlessWheelVisual;
        objective { verify faw001; verify faw002; verify faw003; }
    }
}
