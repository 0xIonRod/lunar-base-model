package GriffinSolarRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import ScalarValues::String;
    private import VectorValues::CartesianThreeVectorValue;
    private import GriffinRequirementSources::TwinAssetPath;
    private import GriffinRequirementSources::UsdPrimPath;
    private import GriffinLanderRequirements::GriffinLanderComponent;

    attribute def CellContourPoint :> CartesianThreeVectorValue;
    attribute def Direction :> CartesianThreeVectorValue;
    enum def GriffinSolarVisualMember {
        Frame; Cells; ArrayBackplane; MountBracketNegativeX;
        MountBracketPositiveX; HingeBar; MountLinkNegativeX; MountLinkPositiveX;
    }

    part def GriffinSolarArrayAssembly {
        doc /* One Griffin-1 solar-array assembly, including its panel, collection surface, and structural attachment interface. */
        attribute usdRootPath : UsdPrimPath = "/World/Griffin1";
        attribute componentAsset : TwinAssetPath = "components/lander/griffin_solar_panel_visual.usda";
        attribute childNames : GriffinSolarVisualMember[8] = ("Frame", "Cells", "ArrayBackplane", "MountBracketNegativeX", "MountBracketPositiveX", "HingeBar", "MountLinkNegativeX", "MountLinkPositiveX");
        /* Current appearance reference: Astrobotic's integrated flight vehicle,
         * photographed 2026-06-15. https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/
         * https://www.nasa.gov/image-detail/26-06-15-griffin-1-pressconference-1419-edit-2/
         * Three tall panel faces replace the older belt/ESA combination. A
         * 13-column by 24-row nominal field and approximately 2:1 rectangular
         * cell pitch reconstruct the visible grid; counts are approximate,
         * especially at stepped edges. Supplier cell dimensions are unavailable.
         * The existing 1.866 m rail-fitted broad frame is retained as the only
         * metric packaging datum. Its 30 mm border yields 138.923 mm horizontal
         * pitch and 69.462 mm vertical pitch, hence 1.727 m frame height.
         * Absolute size, stock and mounting remain study estimates. */
        attribute frameWidthM : Real = 1.866;
        /* Panel/support stock is an explicit visual estimate from the 2021
         * product rendering https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png
         * linked from https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ .
         * The legacy 140 mm frame and 440 mm brackets obstructed the cell face.
         * Use 30 mm frame stock, 12 mm backplane, 2 mm visual cell surface,
         * 100 x 80 x 120 mm brackets and 50 mm hinge diameter.
         * These are appearance envelopes, not laminate/hinge design dimensions.
         * The 460 mm link stock covers the retained 220 mm normal standoff plus the 180 mm forward bank offset; 10 mm
         * overlap is a visual seating tolerance, not a structural engagement spec.
         * Current cell geometry and silhouette use the June 2026 source below;
         * these retained attachment stocks are still packaging estimates. */
        attribute cellDisplayColor : Real[3] = (.009, .012, .018);
        attribute cellMetallic : Real = .25;
        attribute cellRoughness : Real = .20;
        attribute frameThicknessM : Real = 0.03;
        attribute frameDepthM : Real = cellDepthM + 2.0 * frameThicknessM;
        /* Ground photos show lower openings, silver perimeter and dark rounded
         * cells over a warm inter-cell substrate. Use source-owned pitch-coordinate contours for the visible edge
         * steps, equipment recess and leg opening. This
         * is a conservative visual clearance envelope; exact asymmetric edge
         * and equipment contours are not released. Cell gaps 5 mm and 7 mm
         * corner clips approximate the visible shape; colors/roughness below
         * describe appearance, not engineering material properties. */
        attribute cellPitchAspectRatio : Real = 2.0;
        attribute cellGapM : Real = 0.005;
        attribute cellCornerClipM : Real = 0.007;
        attribute installationDatumHeightM : Real = 0.705;
        attribute substrateDisplayColor : Real[3] = (.34, .075, .022);
        attribute substrateMetallic : Real = .55;
        attribute substrateRoughness : Real = .32;
        attribute frameDisplayColor : Real[3] = (.62, .66, .71);
        attribute frameMetallic : Real = .80;
        attribute frameRoughness : Real = .28;
        attribute cellWidthM : Real = frameWidthM - 2.0 * frameThicknessM;
        attribute cellThicknessM : Real = 0.002;
        attribute cellDepthM : Real = cellWidthM * gridRowCount / gridColumnCount / cellPitchAspectRatio;
        attribute cellOffsetYM : Real = 0.007;
        attribute arrayBackplaneThicknessM : Real = 0.012;
        attribute arrayBackplaneCenterYM : Real = 0;
        attribute mountBracketWidthM : Real = 0.1;
        attribute mountBracketThicknessM : Real = 0.08;
        attribute mountBracketDepthM : Real = 0.12;
        attribute hingeBarRadiusM : Real = 0.025;
        attribute hingeBarLengthM : Real = frameWidthM;
        attribute hingeBarCenterYM : Real = -0.18;
        attribute hingeBarCenterZM : Real = 0.00;
        attribute mountLinkHeightM : Real = .46;
        attribute mountLinkDepthM : Real = 0.04;
        attribute mountLinkCenterYM : Real = -0.11;
        attribute mountLinkCenterZM : Real = 0.00;
        attribute gridColumnCount : Integer = 13;
        attribute gridRowCount : Integer = 24;
        /* Ordered entries follow solarArrayInstances. All three faces are tall;
         * both chamfers carry fewer columns at the same pitch. Source solarStations
         * stay bus attachment datums; the installed centre rises by half the
         * difference between frame height and installationDatumHeightM. The
         * 705 mm datum retains the previously fitted bus lower edge and the
         * original sockets; it is not a second panel-height requirement.
         * Clean-room stands, protective covers and elevated footpads are ground
         * test equipment/poses and must not become lunar landing geometry.
         * Real imagery supersedes the 2021/ESA renderings for this appearance
         * pass. Remaining unknowns: exact stepped contours, laminate, fasteners,
         * support ICD, cell supplier/count and electrical/thermal qualification. */
        attribute installedMaximumColumnCounts : Integer[3] = (13, 5, 5);
        attribute installedRowCounts : Integer[3] = (24, 24, 24);

        /* Outline vertices use cell-pitch coordinates (x column, y unused,
         * z row counted downward). They describe only the silhouette; they
         * are not measured flight dimensions. Front broad face: upper-left
         * steps and right equipment recess. Chamfer face: bottom leg opening.
         * Port chamfer: retained lower corner opening scaled to five columns. Face assignment
         * adapts the photographed panel silhouettes to the operator-selected forward-side bank.
         * Broad/front contour is read from the two June 15 photos; unseen
         * edge details and both five-column chamfers are packaging estimates, not photographed cell counts. */
        attribute frontCellContour : CellContourPoint[12] = ((3,0,0), (13,0,0), (13,0,11), (11,0,11), (11,0,19), (13,0,19), (13,0,24), (0,0,24), (0,0,15), (2,0,15), (2,0,12), (3,0,12));
        attribute chamferCellContour : CellContourPoint[8] = ((0,0,0), (5,0,0), (5,0,24), (4,0,24), (4,0,18), (1,0,18), (1,0,24), (0,0,24));
        attribute sideCellContour : CellContourPoint[6] = ((0,0,0), (5,0,0), (5,0,24), (2,0,24), (2,0,18), (0,0,18));

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
        doc /* GSA-003 [study layout] three tall arrays occupy the forward face and the two forward chamfers. Both +/-X ramp/rover corridors remain open; the rover walking plane is below the panel tops. This operator-selected one-side layout corrects the former +X exit obstruction. The June 2026 hardware photographs inform array appearance, not an exact flight mounting ICD or a verified site-Sun coverage envelope. */
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
        doc /* GSA-005 [installation interface] installed width is the lesser of the typed bus-rail span minus solarArrayEdgeClearanceM and the selected module column count times metric cell pitch plus the nominal frame border. Installed row count sets frame height; centre Y derives from the belt-centre datum plus half the height difference from installationDatumHeightM, preserving the lower-edge alignment. Stations and orientations remain source-owned reconstruction datums. Compact brackets seat at the unchanged bus rails; slanted links derive from the rail-to-panel-edge endpoints to preserve the load path. No supplier installation ICD is available. */
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
        in installedLocalFrameDepthM : Real;
        in cellWidthM : Real;
        in cellThicknessM : Real;
        in installedLocalCellDepthM : Real;
        in cellOffsetYM : Real;
        in arrayBackplaneThicknessM : Real;
        in arrayBackplaneCenterYM : Real;
        in geometryToleranceM : Real;
        geometryToleranceM >= 0.0
            and RealFunctions::abs(measuredFrameWidthM - frameWidthM) <= geometryToleranceM
            and RealFunctions::abs(measuredFrameThicknessM - frameThicknessM) <= geometryToleranceM
            and RealFunctions::abs(measuredFrameDepthM - installedLocalFrameDepthM) <= geometryToleranceM
            and RealFunctions::abs(measuredCellWidthM - installedLocalCellWidthM) <= geometryToleranceM
            and RealFunctions::abs(measuredCellThicknessM - cellThicknessM) <= geometryToleranceM
            and RealFunctions::abs(measuredCellDepthM - installedLocalCellDepthM) <= geometryToleranceM
            and RealFunctions::abs(measuredCellCenterYM - cellOffsetYM) <= geometryToleranceM
            and RealFunctions::abs(measuredBackplaneWidthM - cellWidthM) <= geometryToleranceM
            and RealFunctions::abs(measuredBackplaneThicknessM - arrayBackplaneThicknessM) <= geometryToleranceM
            and RealFunctions::abs(measuredBackplaneDepthM - installedLocalCellDepthM) <= geometryToleranceM
            and RealFunctions::abs(measuredBackplaneCenterYM - arrayBackplaneCenterYM) <= geometryToleranceM;
    }
    requirement def GSA006_PanelEnvelope {
        require GSAC006_PanelMeshEnvelope {
            in frameWidthM = GriffinSolarArrayAssembly::frameWidthM;
            in frameThicknessM = GriffinSolarArrayAssembly::frameThicknessM;
            in cellWidthM = GriffinSolarArrayAssembly::cellWidthM;
            in cellThicknessM = GriffinSolarArrayAssembly::cellThicknessM;
            in cellOffsetYM = GriffinSolarArrayAssembly::cellOffsetYM;
            in arrayBackplaneThicknessM = GriffinSolarArrayAssembly::arrayBackplaneThicknessM;
            in arrayBackplaneCenterYM = GriffinSolarArrayAssembly::arrayBackplaneCenterYM;
            in geometryToleranceM = GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::geometryVerificationToleranceM;
        }
        doc /* GSA-006 [geometry] the frame, backplane and substrate share the source-selected tall envelope and lower clearance. Nominal grid count and 2:1 rectangular cell pitch approximate June 2026 hardware photographs. The installed cell field width derives from a whole number of source-pitch columns, transformed back into the panel local frame. The bus-face scale fits the perimeter without distorting the cells. The lower cutout must remain open through the substrate, cells and frame; the exact stepped flight contour remains an estimate. */
    }
    constraint def GSAC007_UniformMetricCellPitch {
        in maximumColumnPitchErrorM : Real;
        in maximumRowPitchErrorM : Real;
        in maximumCellExtentErrorM : Real;
        in maximumCellCountError : Real;
        in toleranceM : Real;
        toleranceM >= 0.0 and maximumColumnPitchErrorM >= 0.0
            and maximumRowPitchErrorM >= 0.0
            and maximumColumnPitchErrorM <= toleranceM
            and maximumRowPitchErrorM <= toleranceM
            and maximumCellExtentErrorM >= 0.0 and maximumCellExtentErrorM <= toleranceM
            and maximumCellCountError == 0.0;
    }
    requirement def GSA007_CellGridAndMount {
        require GSAC007_UniformMetricCellPitch {
            in toleranceM = GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::geometryVerificationToleranceM;
        }
        doc /* GSA-007 [geometry] installed cells form row meshes of clipped rectangular cells, with horizontal pitch cellWidthM/gridColumnCount and vertical pitch divided by cellPitchAspectRatio. Narrow faces keep that pitch and reduce column count rather than squeezing cells. Source pitch-coordinate contours omit cells outside the silhouette, leaving equipment and leg clearances open. Counts and the 2:1 pitch ratio are estimates from the June 2026 Astrobotic photos linked above. Gaps, corner clips and appearance parameters are study values; no supplier panel drawing or electrical-performance claim is implied. */
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
