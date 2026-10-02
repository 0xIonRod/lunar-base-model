package GriffinSolarRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import ScalarValues::String;
    private import VectorValues::CartesianThreeVectorValue;
    private import GriffinRequirementSources::TwinAssetPath;
    private import GriffinRequirementSources::UsdPrimPath;
    private import GriffinLanderRequirements::GriffinLanderComponent;

    attribute def Direction :> CartesianThreeVectorValue;
    enum def GriffinSolarVisualMember {
        Frame; Cells; ArrayBackplane; CellDividerX1; CellDividerX2;
        CellDividerX3; CellDividerX4; CellDividerX5; CellDividerZ1;
        CellDividerZ2; CellDividerZ3; CellDividerX6; CellDividerX7; CellDividerX8; CellDividerX9; CellDividerX10; CellDividerX11; CellDividerX12; CellDividerX13; CellDividerZ4; MountBracketNegativeX;
        MountBracketPositiveX; HingeBar; MountLinkNegativeX; MountLinkPositiveX;
    }

    part def GriffinSolarArrayAssembly {
        doc /* One Griffin-1 solar-array assembly, including its panel, collection surface, and structural attachment interface. */
        attribute usdRootPath : UsdPrimPath = "/World/Griffin1";
        attribute componentAsset : TwinAssetPath = "components/lander/griffin_solar_panel_visual.usda";
        attribute childNames : GriffinSolarVisualMember[25] = ("Frame", "Cells", "ArrayBackplane", "CellDividerX1", "CellDividerX2", "CellDividerX3", "CellDividerX4", "CellDividerX5", "CellDividerZ1", "CellDividerZ2", "CellDividerZ3", "CellDividerX6", "CellDividerX7", "CellDividerX8", "CellDividerX9", "CellDividerX10", "CellDividerX11", "CellDividerX12", "CellDividerX13", "CellDividerZ4", "MountBracketNegativeX", "MountBracketPositiveX", "HingeBar", "MountLinkNegativeX", "MountLinkPositiveX");
        // Panel size revised to fit the smaller bus: 1.716 m maximum face
        // width comes from rail spacing minus edge margins; 0.66 m height
        // fits the 0.72 m body belt. The 14 x 5 grid is observed in the
        // Astrobotic Griffin product rendering; cells have nearly equal pitch.
        // https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/
        // Cell size retains frame
        // edge margins. Estimates, not vendor dimensions; griffin-size-evidence.md.
        attribute frameWidthM : Real = 1.716;
        /* Panel/support stock is an explicit visual estimate from the 2021
         * product rendering https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png
         * linked from https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ .
         * The legacy 140 mm frame and 440 mm brackets obstructed the cell face.
         * Use 30 mm frame stock, 12 mm backplane, 2 mm visual cell surface,
         * 1 mm dividers, 100 x 80 x 120 mm brackets and 50 mm hinge diameter.
         * These are appearance envelopes, not laminate/hinge design dimensions.
         * The 280 mm link bridges the unchanged 220 mm bus standoff; 10 mm
         * overlap is a visual seating tolerance, not a structural engagement spec.
         * Divider placement must apply translation after shape scaling so the
         * 14 x 5 observed grid retains uniform metric spacing. */
        attribute cellDisplayColor : Real[3] = (.015, .025, .060);
        attribute cellMetallic : Real = .15;
        attribute cellRoughness : Real = .25;
        attribute frameThicknessM : Real = 0.03;
        attribute frameDepthM : Real = 0.66;
        /* This reconstruction follows the 2021 product rendering's rectangular
         * 14 x 5 arrays. No lower notch is visible there and corner leg sleeves
         * now sit below the belt. Zero width/depth explicitly selects a full
         * panel; the previous hardware-photo notch belongs to another revision. */
        doc /* Width of the centered lower opening as a fraction of the panel frame width. */
        attribute lowerClearanceWidthFraction : Real = 0.0;
        doc /* Depth of the lower opening from the panel edge as a fraction of frame depth. */
        attribute lowerClearanceDepthFraction : Real = 0.0;
        doc /* Lateral position of the opening center as a fraction of frame width; zero centers it on the panel. */
        attribute lowerClearanceCenterXFraction : Real = 0.0;
        attribute cellWidthM : Real = 1.596;
        attribute cellThicknessM : Real = 0.002;
        attribute cellDepthM : Real = 0.58;
        attribute cellOffsetYM : Real = 0.007;
        attribute arrayBackplaneThicknessM : Real = 0.012;
        attribute arrayBackplaneCenterYM : Real = 0;
        attribute dividerXWidthM : Real = 0.006;
        attribute dividerXThicknessM : Real = 0.001;
        attribute dividerZWidthM : Real = 0.006;
        attribute dividerZThicknessM : Real = 0.001;
        attribute mountBracketWidthM : Real = 0.1;
        attribute mountBracketThicknessM : Real = 0.08;
        attribute mountBracketDepthM : Real = 0.12;
        attribute hingeBarRadiusM : Real = 0.025;
        attribute hingeBarLengthM : Real = 1.716;
        attribute hingeBarCenterYM : Real = -0.18;
        attribute hingeBarCenterZM : Real = 0.00;
        attribute mountLinkHeightM : Real = 0.28;
        attribute mountLinkDepthM : Real = 0.04;
        attribute mountLinkCenterYM : Real = -0.11;
        attribute mountLinkCenterZM : Real = 0.00;
        attribute gridColumnCount : Integer = 14;
        attribute gridRowCount : Integer = 5;
        attribute cellFaceNormal : Direction = (0.0, 1.0, 0.0);
        /* Quaternion component tolerance covers authored serialization precision,
         * not an angular hardware tolerance. USD orient uses (w,x,y,z). */
        attribute orientationTolerance : Real = 0.00001;
        attribute minimumMountOverlapM : Real = 0.01;
    }

    requirement def GSA001_ArrayCount {
        doc /* GSA-001 [mission configuration] the Griffin-1 configuration and composed lander shall contain one uniquely identified installed array assembly for each value of the canonical GriffinLanderRequirements::GriffinLanderComponent::solarArrayCount. */
    }
    requirement def GSA002_ArrayStructure {
        doc /* GSA-002 [visual] each array exposes a frame and cell surface with owned geometry. */
    }
    requirement def GSA003_SunQuadrantLayout {
        doc /* GSA-003 [mission layout] the forward, forward-starboard bevel, and starboard arrays occupy the original mission Sun quadrant. A fourth study array occupies the opposite broad face to reconstruct the belt-panel appearance requested by the operator on 2026-10-02; hidden-face hardware coverage is not established by the available renderings. Their installed frames and panel normals shall satisfy the site-local Sun azimuth/elevation envelope and the approved installation configuration. */
    }
    requirement def GSA004_ArrayTraceability {
        doc /* GSA-004 [evidence] array identities resolve from GriffinVisualConfigurationRequirements, their cardinality agrees with the typed lander count, and deployment status is explicit. */
    }
    constraint def GSAC005_RailSpanFit {
        in expectedInstalledFrameWidthM : Real;
        in measuredInstalledFrameWidthM : Real;
        in toleranceM : Real;
        toleranceM >= 0.0
            and RealFunctions::abs(measuredInstalledFrameWidthM
                - expectedInstalledFrameWidthM) <= toleranceM;
    }
    requirement def GSA005_ArrayPlacement {
        require GSAC005_RailSpanFit {
            in toleranceM = GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::geometryVerificationToleranceM;
        }
        doc /* GSA-005 [installation interface] installed width is the lesser of the typed bus-rail span minus solarArrayEdgeClearanceM and frameWidthM, so the component maximum cannot inflate on wide faces. Stations and orientations remain source-owned reconstruction datums. Compact brackets seat at the unchanged bus rails; slanted links derive from the rail-to-panel-edge endpoints to preserve the load path. No supplier installation ICD is available. */
    }
    constraint def GSAC006_PanelMeshEnvelope {
        in measuredFrameWidthM : Real;
        in measuredFrameThicknessM : Real;
        in measuredFrameDepthM : Real;
        in measuredCellWidthM : Real;
        in installedLocalCellWidthM : Real;
        in measuredCellThicknessM : Real;
        in measuredCellDepthM : Real;
        in measuredCellCenterYM : Real;
        in measuredBackplaneWidthM : Real;
        in measuredBackplaneThicknessM : Real;
        in measuredBackplaneDepthM : Real;
        in measuredBackplaneCenterYM : Real;
        in frameWidthM : Real;
        in frameThicknessM : Real;
        in frameDepthM : Real;
        in cellWidthM : Real;
        in cellThicknessM : Real;
        in cellDepthM : Real;
        in cellOffsetYM : Real;
        in arrayBackplaneThicknessM : Real;
        in arrayBackplaneCenterYM : Real;
        in geometryToleranceM : Real;
        geometryToleranceM >= 0.0
            and RealFunctions::abs(measuredFrameWidthM - frameWidthM) <= geometryToleranceM
            and RealFunctions::abs(measuredFrameThicknessM - frameThicknessM) <= geometryToleranceM
            and RealFunctions::abs(measuredFrameDepthM - frameDepthM) <= geometryToleranceM
            and RealFunctions::abs(measuredCellWidthM - installedLocalCellWidthM) <= geometryToleranceM
            and RealFunctions::abs(measuredCellThicknessM - cellThicknessM) <= geometryToleranceM
            and RealFunctions::abs(measuredCellDepthM - cellDepthM) <= geometryToleranceM
            and RealFunctions::abs(measuredCellCenterYM - cellOffsetYM) <= geometryToleranceM
            and RealFunctions::abs(measuredBackplaneWidthM - cellWidthM) <= geometryToleranceM
            and RealFunctions::abs(measuredBackplaneThicknessM - arrayBackplaneThicknessM) <= geometryToleranceM
            and RealFunctions::abs(measuredBackplaneDepthM - cellDepthM) <= geometryToleranceM
            and RealFunctions::abs(measuredBackplaneCenterYM - arrayBackplaneCenterYM) <= geometryToleranceM;
    }
    requirement def GSA006_PanelEnvelope {
        require GSAC006_PanelMeshEnvelope {
            in frameWidthM = GriffinSolarArrayAssembly::frameWidthM;
            in frameThicknessM = GriffinSolarArrayAssembly::frameThicknessM;
            in frameDepthM = GriffinSolarArrayAssembly::frameDepthM;
            in cellWidthM = GriffinSolarArrayAssembly::cellWidthM;
            in cellThicknessM = GriffinSolarArrayAssembly::cellThicknessM;
            in cellDepthM = GriffinSolarArrayAssembly::cellDepthM;
            in cellOffsetYM = GriffinSolarArrayAssembly::cellOffsetYM;
            in arrayBackplaneThicknessM = GriffinSolarArrayAssembly::arrayBackplaneThicknessM;
            in arrayBackplaneCenterYM = GriffinSolarArrayAssembly::arrayBackplaneCenterYM;
            in geometryToleranceM = GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::geometryVerificationToleranceM;
        }
        doc /* GSA-006 [geometry] the frame and backplane use the rectangular 2021 rendering configuration. The installed cell field width derives from a whole number of source-pitch columns, transformed back into the panel local frame. The bus-face scale fits the perimeter without distorting the cells. No lower notch is observed in that rendering; the different hardware-photo configuration is not mixed into this reconstruction. */
    }
    constraint def GSAC007_UniformMetricCellPitch {
        in maximumColumnPitchErrorM : Real;
        in maximumRowPitchErrorM : Real;
        in toleranceM : Real;
        toleranceM >= 0.0 and maximumColumnPitchErrorM >= 0.0
            and maximumRowPitchErrorM >= 0.0
            and maximumColumnPitchErrorM <= toleranceM
            and maximumRowPitchErrorM <= toleranceM;
    }
    requirement def GSA007_CellGridAndMount {
        require GSAC007_UniformMetricCellPitch {
            in toleranceM = GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::geometryVerificationToleranceM;
        }
        doc /* GSA-007 [geometry] full faces use the 14-column, 5-row module observed by the user in https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png linked from https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ . Installed cell pitch follows cellWidthM/gridColumnCount and cellDepthM/gridRowCount. Narrow faces reduce column count to the largest whole count fitting their rail span minus the nominal frame-to-cell border allowance, capped at gridColumnCount. Keep the metric pitch after instance scaling; never squeeze 14 columns into a narrower panel. A six-column bevel panel is a reconstruction estimate from available space, not an observed flight count. The retained five rows, 114 by 116 mm pitches and frame borders are appearance estimates; supplier panel configuration is unavailable. */
    }
    requirement def GSA008_HingeAndStandoff {
        doc /* GSA-008 [mechanical interface] panel pivots, restraints, support links, deployment envelope, and structural load path shall conform to the approved Griffin-1 mechanism and structural interface definition. */
    }
    constraint def GSAC009_MountPathOverlap {
        in busToBracketOverlapM : Real;
        in bracketToLinkOverlapM : Real;
        in linkToFrameOverlapM : Real;
        in requiredOverlapM : Real;
        busToBracketOverlapM >= requiredOverlapM
            and bracketToLinkOverlapM >= requiredOverlapM
            and linkToFrameOverlapM >= requiredOverlapM;
    }
    requirement def GSA009_BusMountConnection {
        require GSAC009_MountPathOverlap {
            in requiredOverlapM = GriffinSolarArrayAssembly::minimumMountOverlapM;
        }
        doc /* GSA-009 [visual integration] each array shall show connected support geometry from the panel frame to the lander mounting rails, including the bracket, link, and frame interfaces. */
    }
    requirement def GSA010_TransitSunPointing {
        attribute acceptanceStatus : String = "OPEN: approved incidence bounds, evaluation window, and exception authority are not source-defined";
        doc /* GSA-010 [operational, OPEN] during transit, Griffin attitude control shall keep solar-array incidence within a source-defined Sun-pointing envelope when mission, thermal, and vehicle constraints permit. Define the envelope, evaluation window, and permitted exceptions before claiming a pass. Verification evidence shall correlate time-aligned Sun direction, commanded and measured vehicle attitude, panel incidence, and electrical-power data. */
    }

    requirement <'GSA-001'> gsa001 : GSA001_ArrayCount { subject arrays : GriffinSolarArrayAssembly; }
    requirement <'GSA-002'> gsa002 : GSA002_ArrayStructure { subject arrays : GriffinSolarArrayAssembly; }
    requirement <'GSA-003'> gsa003 : GSA003_SunQuadrantLayout { subject arrays : GriffinSolarArrayAssembly; }
    requirement <'GSA-004'> gsa004 : GSA004_ArrayTraceability { subject arrays : GriffinSolarArrayAssembly; }
    requirement <'GSA-005'> gsa005 : GSA005_ArrayPlacement { subject arrays : GriffinSolarArrayAssembly; }
    requirement <'GSA-006'> gsa006 : GSA006_PanelEnvelope { subject arrays : GriffinSolarArrayAssembly; }
    requirement <'GSA-007'> gsa007 : GSA007_CellGridAndMount { subject arrays : GriffinSolarArrayAssembly; }
    requirement <'GSA-008'> gsa008 : GSA008_HingeAndStandoff { subject arrays : GriffinSolarArrayAssembly; }
    requirement <'GSA-009'> gsa009 : GSA009_BusMountConnection { subject arrays : GriffinSolarArrayAssembly; }
    requirement <'GSA-010'> gsa010 : GSA010_TransitSunPointing { subject lander : GriffinLanderComponent; }

    verification def Verify_GriffinSolarRequirements {
        subject arrays : GriffinSolarArrayAssembly;
        subject lander : GriffinLanderComponent;
        objective {
            verify gsa001;
            verify gsa002;
            verify gsa003;
            verify gsa004;
            verify gsa005;
            verify gsa006;
            verify gsa007;
            verify gsa008;
            verify gsa009;
            verify gsa010;
        }
    }
}
