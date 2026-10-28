package GriffinPresentationStudy {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    part def HardwareFinish {
        doc /* Presentation reconstruction, 27 October 2026. June integration photo:
         * https://www.nasa.gov/image-detail/26-06-15-griffin-1-pressconference-1348-edit/
         * Silver-gray lower blankets, metallic struts, dark dished pads and fine
         * service harnesses inform appearance only. All colors, PBR coefficients,
         * dome proportions and harness dimensions below are STUDY ASSUMPTIONS.
         * They are not measured optical/thermal properties, flight CAD or loads.
         * The mesh cover adds no mass, collision, joints or force authority. */
        attribute retentionColor : Real[3] = (0.34, 0.38, 0.43);
        attribute retentionMetallic : Real = 0.85;
        attribute retentionRoughness : Real = 0.28;
        attribute aluminumColor : Real[3] = (0.63, 0.67, 0.72);
        attribute aluminumMetallic : Real = 0.82;
        attribute aluminumRoughness : Real = 0.33;
        attribute valveColor : Real[3] = (0.47, 0.34, 0.14);
        attribute valveMetallic : Real = 0.8;
        attribute valveRoughness : Real = 0.30;
        attribute pistonColor : Real[3] = (0.58, 0.63, 0.68);
        attribute pistonMetallic : Real = 0.92;
        attribute pistonRoughness : Real = 0.20;
        attribute padColor : Real[3] = (0.32, 0.36, 0.38);
        attribute padMetallic : Real = 0.70;
        attribute padRoughness : Real = 0.48;
        attribute jointColor : Real[3] = (0.25, 0.29, 0.33);
        attribute jointMetallic : Real = 0.80;
        attribute jointRoughness : Real = 0.34;
        attribute padProfileRadiusFractions : Real[7] = (0.0, 0.30, 0.65, 0.90, 1.0, 1.0, 0.0);
        attribute padProfileHeightFractions : Real[7] = (3.2, 3.2, 2.6, 1.3, 0.5, -0.5, -0.5);
        attribute padAngularSegments : Integer = 64;
        attribute harnessRadiusM : Real = 0.008;
        attribute harnessDropM : Real = 0.045;
        // Blanket palette remains owned by GriffinVisualConfiguration.
        attribute harnessMetallic : Real = 0.0;
        attribute harnessRoughness : Real = 0.72;
        attribute connectorMetallic : Real = 0.80;
        attribute connectorRoughness : Real = 0.30;
        attribute harnessColor : Real[3] = (0.075, 0.085, 0.10);
        attribute connectorColor : Real[3] = (0.46, 0.31, 0.10);
    }

    part def SocialFinish {
        attribute ReviewExposureStops : Real = -0.6;
        attribute ReviewFillIntensity : Real = 1000.0;
        doc /* Social-video appearance study, 28 October 2026. Artistic renderer
         * settings only; clean pre-egress baseline. No flight optical properties.
         * Brushing and cell electrodes are illustrative surface detail. */
        attribute FrameColor : Real[3] = (0.55, 0.59, 0.64);
        attribute FrameMetallic : Real = 0.82;
        attribute FrameRoughness : Real = 0.3;
        attribute FrameGrain : Real = 0.035;
        attribute FrameScale : Real = 160;
        attribute FrameBrush : Real = 8;
        attribute ChassisColor : Real[3] = (0.67, 0.7, 0.73);
        attribute ChassisMetallic : Real = 0.15;
        attribute ChassisRoughness : Real = 0.46;
        attribute ChassisGrain : Real = 0.022;
        attribute ChassisScale : Real = 120;
        attribute ChassisBrush : Real = 3;
        attribute DarkHousingColor : Real[3] = (0.035, 0.045, 0.06);
        attribute DarkHousingMetallic : Real = 0.15;
        attribute DarkHousingRoughness : Real = 0.56;
        attribute DarkHousingGrain : Real = 0.025;
        attribute DarkHousingScale : Real = 100;
        attribute DarkHousingBrush : Real = 2;
        attribute TreadColor : Real[3] = (0.16, 0.18, 0.21);
        attribute TreadMetallic : Real = 0.65;
        attribute TreadRoughness : Real = 0.58;
        attribute TreadGrain : Real = 0.065;
        attribute TreadScale : Real = 90;
        attribute TreadBrush : Real = 2;
        attribute SpiderColor : Real[3] = (0.48, 0.53, 0.59);
        attribute SpiderMetallic : Real = 0.88;
        attribute SpiderRoughness : Real = 0.27;
        attribute SpiderGrain : Real = 0.025;
        attribute SpiderScale : Real = 190;
        attribute SpiderBrush : Real = 10;
        attribute CableColor : Real[3] = (0.21, 0.24, 0.29);
        attribute CableMetallic : Real = 0.85;
        attribute CableRoughness : Real = 0.38;
        attribute CableGrain : Real = 0.035;
        attribute CableScale : Real = 180;
        attribute CableBrush : Real = 3;
        attribute FastenerColor : Real[3] = (0.63, 0.67, 0.72);
        attribute FastenerMetallic : Real = 0.92;
        attribute FastenerRoughness : Real = 0.22;
        attribute FastenerGrain : Real = 0.018;
        attribute FastenerScale : Real = 220;
        attribute FastenerBrush : Real = 10;
        attribute LensColor : Real[3] = (0.008, 0.018, 0.028);
        attribute LensMetallic : Real = 0.15;
        attribute LensRoughness : Real = 0.1;
        attribute LensGrain : Real = 0;
        attribute LensScale : Real = 100;
        attribute LensBrush : Real = 1;
        attribute CellColor : Real[3] = (0.018, 0.035, 0.075);
        attribute ElectrodeColor : Real[3] = (0.32, 0.36, 0.42);
        attribute CellRoughness : Real = 0.24;
        attribute CellMetallic : Real = 0.28;
        attribute ElectrodePitchM : Real = 0.006;
        attribute ElectrodeWidthM : Real = 0.00012;
    }

    part def GeometryDetail {
        doc /* Visual-only geometry study, 28 October 2026. Blanket seam placement,
         * tape width and CAD edge caps are artistic assumptions. The June Griffin
         * integration photo informs the assembly language, not measured seam routing.
         * Existing mesh points and extents supply each mount; no physical mass,
         * collisions or joint authority is assigned to these details. */
        attribute SeamWidthM : Real = 0.035;
        attribute SeamDepthM : Real = 0.009;
        attribute SeamEmbedM : Real = 0.002;
        attribute SeamBandFractions : Real[2] = (0.12, 0.88);
        attribute SeamColor : Real[3] = (0.22, 0.24, 0.27);
        attribute SeamMetallic : Real = 0.05;
        attribute SeamRoughness : Real = 0.78;
        attribute EdgeWidthM : Real = 0.025;
        attribute EdgeDepthM : Real = 0.014;
        attribute EdgeEmbedM : Real = 0.002;
        attribute ChassisDivisionFractions : Real[2] = (0.333333333333, 0.666666666667);
        attribute HatchWidthFraction : Real = 0.42;
        attribute HatchHeightFraction : Real = 0.68;
        attribute HatchBorderM : Real = 0.018;
        attribute HatchDepthM : Real = 0.012;
        attribute PanelCapWidthM : Real = 0.045;
        attribute PanelCapDepthM : Real = 0.018;
        attribute PanelCornerLengthM : Real = 0.11;
        attribute PanelCornerWidthM : Real = 0.065;
    }

    part def PublicHardwareDetail {
        doc /* Public-reference presentation pass, 28 October 2026.
         * NASA/JPL 2026-071 test imagery, photographed July-August 2026:
         * https://www.nasa.gov/missions/moon-base/nasa-jpl-testing-readies-voyager-technologies-lander-for-moon-mission/
         * Astrobotic public Payload User Guide, August 2021 v5.0, pp.24-31:
         * https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf
         * The guide is historical VIPER configuration context; current photos
         * govern visible wrapping and hardware. Every dimension below is an
         * artistic reconstruction, not a measured flight dimension. Cable routes
         * are illustrative service loops, not an electrical/pressure network.
         * Upper-strut insulation retains the lower exposed piston envelope. */
        attribute TrimLipHeightM : Real = 0.007;
        attribute TrimOverhangM : Real = 0.004;
        attribute SleeveFraction : Real = 0.46;
        attribute SleeveCenterFraction : Real = 0.20;
        attribute SmallSleeveAllowanceM : Real = 0.009;
        attribute PistonSleeveAllowanceM : Real = 0.014;
        attribute BarrelCoverageFraction : Real = 0.90;
        attribute CuffAllowanceM : Real = 0.004;
        attribute CuffHeightM : Real = 0.024;
        attribute CableRadiusM : Real = 0.012;
        attribute CableSagM : Real = 0.11;
        attribute CableOutsetM : Real = 0.015;
        attribute ConnectorRadiusFactor : Real = 1.65;
        attribute ConnectorLengthM : Real = 0.045;
    }

}
