package GriffinSolarRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import VectorValues::CartesianThreeVectorValue;
    private import GriffinRequirementSources::TwinAssetPath;
    private import GriffinRequirementSources::UsdPrimPath;

    attribute def Direction :> CartesianThreeVectorValue;
    enum def GriffinSolarVisualMember {
        Frame; Cells; ArrayBackplane; CellDividerX1; CellDividerX2;
        CellDividerX3; CellDividerX4; CellDividerX5; CellDividerZ1;
        CellDividerZ2; CellDividerZ3; MountBracketPort;
        MountBracketStarboard; HingeBar; MountLinkPort; MountLinkStarboard;
    }

    part def GriffinSolarArrayAssembly {
        doc /* Public Griffin material identifies the triple-junction solar-cell and lithium-ion power concept. The solar arrays remain an independently replaceable visual/power interface with a mirrored pair and explicit station datums; source links are owned by the typed requirement-evidence catalog. */
        attribute usdRootPath : UsdPrimPath = "/World/Griffin1";
        attribute componentAsset : TwinAssetPath = "components/lander/griffin_solar_panel_visual.usda";
        attribute childNames : GriffinSolarVisualMember[16] = ("Frame", "Cells", "ArrayBackplane", "CellDividerX1", "CellDividerX2", "CellDividerX3", "CellDividerX4", "CellDividerX5", "CellDividerZ1", "CellDividerZ2", "CellDividerZ3", "MountBracketPort", "MountBracketStarboard", "HingeBar", "MountLinkPort", "MountLinkStarboard");
        attribute frameWidthM : Real = 4.80;
        attribute frameThicknessM : Real = 0.14;
        attribute frameDepthM : Real = 3.00;
        attribute cellWidthM : Real = 4.45;
        attribute cellThicknessM : Real = 0.05;
        attribute cellDepthM : Real = 2.65;
        attribute cellOffsetYM : Real = 0.075;
        attribute arrayBackplaneThicknessM : Real = 0.04;
        attribute arrayBackplaneCenterYM : Real = 0.03;
        attribute dividerXWidthM : Real = 0.04;
        attribute dividerXThicknessM : Real = 0.04;
        attribute dividerZWidthM : Real = 0.04;
        attribute dividerZThicknessM : Real = 0.04;
        attribute mountBracketWidthM : Real = 0.44;
        attribute mountBracketThicknessM : Real = 0.32;
        attribute mountBracketDepthM : Real = 0.44;
        // The released panel hinge ICD is not public. These render-only
        // datums make the attachment readable and leave an explicit
        // replacement boundary for the flight mechanism rather than letting
        // the panel float on an unexplained bracket.
        attribute hingeBarRadiusM : Real = 0.10;
        attribute hingeBarLengthM : Real = 3.10;
        attribute hingeBarCenterYM : Real = -0.18;
        attribute hingeBarCenterZM : Real = 0.00;
        attribute mountLinkHeightM : Real = 0.44;
        attribute mountLinkDepthM : Real = 0.18;
        attribute mountLinkCenterYM : Real = -0.08;
        attribute mountLinkCenterZM : Real = 0.00;
        attribute gridColumnCount : Integer = 6;
        attribute gridRowCount : Integer = 4;
        attribute cellFaceNormal : Direction = (0.0, 1.0, 0.0);
        attribute minimumMountOverlapM : Real = 0.05;
    }

    requirement def GSA001_ArrayCount {
        doc /* GSA-001 [topology] every instance in the typed solar-array identity collection is present and visible. */
    }
    requirement def GSA002_ArrayStructure {
        doc /* GSA-002 [visual] each array exposes a frame and cell surface with owned geometry. */
    }
    requirement def GSA003_ArraySymmetry {
        doc /* GSA-003 [layout] the two arrays occupy mirrored signed side stations in the authored SI/Y-up frame. */
    }
    requirement def GSA004_ArrayTraceability {
        doc /* GSA-004 [evidence] array identities resolve from GriffinVisualConfigurationRequirements, their cardinality agrees with the typed lander count, and deployment status is explicit. */
    }
    requirement def GSA005_ArrayPlacement {
        doc /* GSA-005 [layout] each array root transform matches the ordered native Position datum owned by GriffinVisualConfigurationRequirements. */
    }
    requirement def GSA006_PanelEnvelope {
        doc /* GSA-006 [geometry] each panel shall use an open 4.80 m by 3.00 m perimeter frame with 0.14 m stock; its 4.45 m by 2.65 m cell field rests on a 0.04 m backplane at local Y=0.03 m and has a 0.05 m cell surface centered at Y=+0.075 m. These are expanded study dimensions, not public panel ICD values. */
    }
    requirement def GSA007_CellGridAndMount {
        doc /* GSA-007 [geometry] each panel shall contain a 6 by 4 cell-module grid with five X dividers, three Z dividers, and a 0.44 m by 0.32 m by 0.44 m mount bracket, all as named child geometry. The segmented wing is a visual study assumption because public Griffin material identifies solar cells but does not publish panel CAD. */
    }
    requirement def GSA008_HingeAndStandoff {
        doc /* GSA-008 [interface geometry] each panel shall expose a render-only X-axis hinge shaft of radius 0.10 m and length 3.10 m at local Y = -0.18 m. Two mount links bridge the corner-post stations to the panel side rails; their spans and overlap are derived from the shared bus rail stations, panel frame width, and minimumMountOverlapM. These are explicit study assumptions because the public Griffin source confirms the solar-array concept but does not publish the deployment/hinge ICD. */
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
        require GSAC009_MountPathOverlap;
        doc /* GSA-009 [mechanical interface] each deployed side array shall have a continuous render-only mount path from the octagonal bus PerimeterFrame through MountBracket and MountLink into the panel Frame. Every adjacent geometry pair shall overlap by at least minimumMountOverlapM in the composed SI frame. Both arrays remain mounted at the signed-Z stations in GriffinVisualConfiguration. */
    }

    requirement <'GSA-001'> gsa001 : GSA001_ArrayCount { subject arrays : GriffinSolarArrayAssembly; }
    requirement <'GSA-002'> gsa002 : GSA002_ArrayStructure { subject arrays : GriffinSolarArrayAssembly; }
    requirement <'GSA-003'> gsa003 : GSA003_ArraySymmetry { subject arrays : GriffinSolarArrayAssembly; }
    requirement <'GSA-004'> gsa004 : GSA004_ArrayTraceability { subject arrays : GriffinSolarArrayAssembly; }
    requirement <'GSA-005'> gsa005 : GSA005_ArrayPlacement { subject arrays : GriffinSolarArrayAssembly; }
    requirement <'GSA-006'> gsa006 : GSA006_PanelEnvelope { subject arrays : GriffinSolarArrayAssembly; }
    requirement <'GSA-007'> gsa007 : GSA007_CellGridAndMount { subject arrays : GriffinSolarArrayAssembly; }
    requirement <'GSA-008'> gsa008 : GSA008_HingeAndStandoff { subject arrays : GriffinSolarArrayAssembly; }
    requirement <'GSA-009'> gsa009 : GSA009_BusMountConnection { subject arrays : GriffinSolarArrayAssembly; }

    verification def Verify_GriffinSolarRequirements {
        subject arrays : GriffinSolarArrayAssembly;
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
        }
    }
}
