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
        doc /* Astrobotic's current Griffin-1 integration post reports three arrays (two installed, one remaining) and states that all are positioned within the mission-window Sun-path quadrant. The 2026 integration photograph shows three upright panel faces across adjacent sides of one lander sector, attached through structural supports. The current Twin geometry is a two-array opposite-side proxy and is not the mission arrangement. Source links are owned by the typed requirement-evidence catalog. */
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
        doc /* GSA-001 [mission configuration] the typed solar-array identity collection and composed installed components shall match the canonical GriffinLanderRequirements::GriffinLanderComponent::solarArrayCount. The source post reports two installed panels with one remaining; the current two-array Twin assembly is incomplete. */
    }
    requirement def GSA002_ArrayStructure {
        doc /* GSA-002 [visual] each array exposes a frame and cell surface with owned geometry. */
    }
    requirement def GSA003_SunQuadrantLayout {
        doc /* GSA-003 [mission layout] all configured upright arrays occupy adjacent azimuth stations within the single Sun-path quadrant selected for the Griffin-1 mission window. The integration image supports a same-sector arrangement; exact facet assignments and azimuths require the mission installation drawing. Opposite-side mirror symmetry is not a Griffin-1 requirement. */
    }
    requirement def GSA004_ArrayTraceability {
        doc /* GSA-004 [evidence] array identities resolve from GriffinVisualConfigurationRequirements, their cardinality agrees with the typed lander count, and deployment status is explicit. */
    }
    requirement def GSA005_ArrayPlacement {
        doc /* GSA-005 [installation interface] each array root transform, azimuth, panel normal, support attachment, and stowed/deployed state shall match the controlled Griffin-1 installation/interface drawing. Public images do not provide dimensional datums. The existing two-station signed-Z list is a replaceable visual study proxy and cannot verify this mission requirement. */
    }
    requirement def GSA006_PanelEnvelope {
        doc /* GSA-006 [geometry] each array shall preserve the installed panel outline, cell field, and visible clearance cutouts from the controlled mission geometry. The current 4.80 m by 3.00 m frame, 4.45 m by 2.65 m cell field, and thicknesses are render-study values only; the public photographs do not establish dimensions or manufacturing tolerances. */
    }
    requirement def GSA007_CellGridAndMount {
        doc /* GSA-007 [geometry] each array shall show its cell modules and perimeter frame, with module segmentation following the released panel layout. The current 6 by 4 grid and bracket dimensions are render-study values; the integration photos are insufficient to determine cell count, frame section, or bracket dimensions. */
    }
    requirement def GSA008_HingeAndStandoff {
        doc /* GSA-008 [mechanical interface] panel pivots, restraints, support links, deployment envelope, and load path shall follow the released Griffin-1 mechanism and structural interface definition. The current X-axis hinge bar and two-link bracket are visual proxies inferred from incomplete views, not verified flight mechanisms. */
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
        doc /* GSA-009 [visual integration] each modeled array shall have a continuous visible support path into the lander structure. The current overlap check proves only that study meshes touch in the composed SI frame; it does not prove the Griffin-1 attachment, load path, fasteners, clearances, or deployed mechanism. */
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
