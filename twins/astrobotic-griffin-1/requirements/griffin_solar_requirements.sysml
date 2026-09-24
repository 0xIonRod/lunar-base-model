package GriffinSolarRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import VectorValues::CartesianThreeVectorValue;
    private import GriffinRequirementSources::TwinAssetPath;
    private import GriffinRequirementSources::UsdPrimPath;
    private import GriffinLanderRequirements::GriffinLanderComponent;

    attribute def Direction :> CartesianThreeVectorValue;
    enum def GriffinSolarVisualMember {
        Frame; Cells; ArrayBackplane; CellDividerX1; CellDividerX2;
        CellDividerX3; CellDividerX4; CellDividerX5; CellDividerZ1;
        CellDividerZ2; CellDividerZ3; MountBracketPort;
        MountBracketStarboard; HingeBar; MountLinkPort; MountLinkStarboard;
    }

    part def GriffinSolarArrayAssembly {
        doc /* One Griffin-1 solar-array assembly, including its panel, collection surface, and structural attachment interface. */
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
        doc /* GSA-001 [mission configuration] the Griffin-1 configuration and composed lander shall contain one uniquely identified installed array assembly for each value of the canonical GriffinLanderRequirements::GriffinLanderComponent::solarArrayCount. */
    }
    requirement def GSA002_ArrayStructure {
        doc /* GSA-002 [visual] each array exposes a frame and cell surface with owned geometry. */
    }
    requirement def GSA003_SunQuadrantLayout {
        doc /* GSA-003 [mission layout] in the Griffin-1 surface configuration, array assemblies shall occupy adjacent lander side faces within the azimuth quadrant traversed by the mission-window Sun path. Verify their installed frames and panel normals against the site-local Sun azimuth/elevation envelope and approved installation configuration. */
    }
    requirement def GSA004_ArrayTraceability {
        doc /* GSA-004 [evidence] array identities resolve from GriffinVisualConfigurationRequirements, their cardinality agrees with the typed lander count, and deployment status is explicit. */
    }
    requirement def GSA005_ArrayPlacement {
        doc /* GSA-005 [installation interface] each array root frame, azimuth, panel normal, support attachment, and stowed/deployed state shall conform to the approved Griffin-1 installation/interface definition. */
    }
    requirement def GSA006_PanelEnvelope {
        doc /* GSA-006 [geometry] each array shall match the approved installed panel outline, cell field, and clearance cutouts within the tolerances in its controlled geometry definition. */
    }
    requirement def GSA007_CellGridAndMount {
        doc /* GSA-007 [geometry] each array shall show cell modules, perimeter frame, and mounting features in the arrangement defined by the approved panel layout. */
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
        require GSAC009_MountPathOverlap;
        doc /* GSA-009 [visual integration] each array shall show connected support geometry from the panel frame to the lander mounting rails, including the bracket, link, and frame interfaces. */
    }
    requirement def GSA010_TransitSunPointing {
        doc /* GSA-010 [operational] during transit, Griffin attitude control shall keep the solar-array incidence within the approved Sun-pointing envelope whenever mission, thermal, and vehicle constraints permit. Verify against time-aligned Sun direction, commanded and measured vehicle attitude, panel incidence, and electrical-power evidence. */
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
