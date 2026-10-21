package GriffinSolarRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import ScalarValues::Boolean;
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
        attribute componentAssets : TwinAssetPath[3] = ("components/lander/griffin_solar_panel_visual.usda", "components/lander/griffin_solar_panel_starboard_visual.usda", "components/lander/griffin_solar_panel_port_visual.usda");
        attribute childNames : GriffinSolarVisualMember[8] = ("Frame", "Cells", "ArrayBackplane", "MountBracketNegativeX", "MountBracketPositiveX", "HingeBar", "MountLinkNegativeX", "MountLinkPositiveX");
        /* Current appearance reference: Astrobotic's integrated flight vehicle,
         * photographed 2026-06-15. https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/
         * https://www.nasa.gov/image-detail/26-06-15-griffin-1-pressconference-1419-edit-2/
         * Three tall panel faces replace the older belt/ESA combination. A
         * 12-column by 24-row nominal field and approximately 2:1 rectangular
         * cell pitch reconstruct the visible grid; counts are approximate,
         * especially at stepped edges. Supplier cell dimensions are unavailable.
         * The existing 1.866 m rail-fitted broad frame is retained as the only
         * metric packaging datum. Its 30 mm border yields 150.5 mm horizontal
         * pitch and 75.25 mm vertical pitch, hence 1.866 m frame height.
         * Absolute size, stock and mounting remain study estimates. */
        attribute frameWidthM : Real = 1.866;
        /* Panel/support stock is an explicit visual estimate from the 2021
         * product rendering https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png
         * linked from https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ .
         * The legacy 140 mm frame and 440 mm brackets obstructed the cell face.
         * Use 30 mm frame stock, 12 mm backplane, 2 mm visual cell surface,
         * 100 x 80 x 120 mm brackets and 50 mm hinge diameter.
         * These are appearance envelopes, not laminate/hinge design dimensions.
         * Installed link lengths derive from their named bus-rail and
         * panel-frame endpoints plus seating overlap at both ends. The 10 mm
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
        // The installed forward array lies on vehicle +Z; local +Y is its outward collecting face.
        attribute illuminatedFaceNormal : Direction = (0.0, 1.0, 0.0);
        attribute arrayBackplaneThicknessM : Real = 0.012;
        attribute arrayBackplaneCenterYM : Real = 0;
        attribute mountBracketWidthM : Real = 0.1;
        attribute mountBracketThicknessM : Real = 0.08;
        attribute mountBracketDepthM : Real = 0.12;
        attribute hingeBarRadiusM : Real = 0.025;
        attribute hingeBarLengthM : Real = frameWidthM;
        attribute hingeBarCenterYM : Real = -0.18;
        attribute hingeBarCenterZM : Real = 0.00;
        attribute mountLinkDepthM : Real = 0.04;
        attribute gridColumnCount : Integer = 12;
        attribute gridRowCount : Integer = 24;
        /* June 15, 2026 photographs show twelve cell columns and twenty-four
         * rows on the full panel faces. Count the near-face cells rather than
         * treating perspective foreshortening as a narrower module. The forward
         * face clears the cardinal landing leg; the side faces have mirrored
         * stepped shoulders and an inboard equipment recess. Coordinates below
         * trace visible cell boundaries, not a released supplier drawing.
         * Source: NASA/Astrobotic 1348, 1419 and 1442 clean-room photographs.
         * Metric pitch, exact laminate and mounting ICD remain study estimates. */
        attribute installedColumnCounts : Integer[3] = (12, 12, 12);
        attribute installedRowCounts : Integer[3] = (24, 24, 24);
        /* X is the cell column; Z counts rows downward. The forward panel's
         * stepped leg opening and right equipment recess follow photo 1348.
         * The two side profiles follow the stepped panel in 1419 and its
         * opposite-side counterpart visible in 1348; unseen fine edge details
         * are explicitly estimated. */
        attribute frontCellContour : CellContourPoint[16] = ((0,0,0), (12,0,0), (12,0,16), (11,0,16), (11,0,22), (12,0,22), (12,0,24), (8,0,24), (8,0,18), (7,0,18), (7,0,16), (5,0,16), (5,0,19), (4,0,19), (4,0,24), (0,0,24));
        attribute chamferCellContour : CellContourPoint[12] = ((9,0,0), (0,0,0), (0,0,11), (2,0,11), (2,0,19), (0,0,19), (0,0,24), (12,0,24), (12,0,15), (10,0,15), (10,0,12), (9,0,12));
        attribute sideCellContour : CellContourPoint[12] = ((3,0,0), (12,0,0), (12,0,11), (10,0,11), (10,0,19), (12,0,19), (12,0,24), (0,0,24), (0,0,15), (2,0,15), (2,0,12), (3,0,12));

        attribute cellFaceNormal : Direction = (0.0, 1.0, 0.0);
        /* Quaternion component tolerance covers authored serialization precision,
         * not an angular hardware tolerance. USD orient uses (w,x,y,z). */
        attribute orientationTolerance : Real = 0.00001;
        attribute minimumMountOverlapM : Real = 0.01;
    }

    part def GriffinDescentSunPointingStudy {
        doc /* Operator-requested simulation acceptance for solar heading during descent. These are study limits, not supplier flight-GNC tolerances. Thrust-vector tilt, manual authority and native contact handoff retain priority. */
        attribute azimuthToleranceRad : Real = 0.08726646259971647;
        attribute acquisitionTimeS : Real = 2.0;
        // Final-approach yaw derived from the authored epoch/site Sun azimuth.
        attribute initialYawDeg : Real = 172.483;
        attribute yawRateToleranceRadS : Real = 0.02;
        attribute minimumTrackingTimeS : Real = 3.0;
        attribute testTimeoutS : Real = 180.0;
    }

    constraint def GSAC001_InstalledArrayPopulation {
        in requiredArrayCount : Real;
        in declaredArrayCount : Real;
        in distinctArrayCount : Real;
        in activeVisibleArrayCount : Real;
        requiredArrayCount > 0.0 and declaredArrayCount == requiredArrayCount
            and distinctArrayCount == requiredArrayCount
            and activeVisibleArrayCount == requiredArrayCount;
    }
    requirement def GSA001_ArrayCount {
        doc /* GSA-001 [mission configuration] the Griffin-1 configuration and composed lander shall contain one uniquely identified installed array assembly for each value of the canonical GriffinLanderRequirements::GriffinLanderComponent::solarArrayCount. */
        require GSAC001_InstalledArrayPopulation;
    }
    constraint def GSAC002_VisibleMemberInventory {
        in requiredMemberCount : Real;
        in activeVisibleMemberCount : Real;
        requiredMemberCount > 0.0 and activeVisibleMemberCount == requiredMemberCount;
    }
    requirement def GSA002_ArrayStructure {
        doc /* GSA-002 [component structure] every installed array shall contain the source-enumerated frame, cell surface, backplane, brackets, hinge and support links plus every row mesh declared by its installed cell layout. All required members shall be active and have visibility other than invisible. GSA-006/007 independently accept mesh geometry and cell pitch. */
        require GSAC002_VisibleMemberInventory;
    }
    constraint def GSAC003_ForwardFaceFrame {
        in centerX : Real;
        in centerZ : Real;
        in normalX : Real;
        in normalY : Real;
        in normalZ : Real;
        in positionToleranceM : Real;
        in normalTolerance : Real;
        centerZ > 0.0 and normalZ > 0.0 and positionToleranceM >= 0.0 and normalTolerance >= 0.0
            and RealFunctions::abs(centerX) <= positionToleranceM
            and RealFunctions::abs(normalX) <= normalTolerance
            and RealFunctions::abs(normalY) <= normalTolerance;
    }
    constraint def GSAC003_ChamferFaceFrame {
        in centerX : Real;
        in centerZ : Real;
        in normalX : Real;
        in normalY : Real;
        in normalZ : Real;
        in lateralSign : Real;
        in normalTolerance : Real;
        (lateralSign == 1.0 or lateralSign == -1.0)
            and lateralSign * centerX > 0.0 and centerZ > 0.0
            and lateralSign * normalX > 0.0 and normalZ > 0.0
            and normalTolerance >= 0.0
            and RealFunctions::abs(normalY) <= normalTolerance;
    }
    constraint def GSAC003_NoOppositeArray {
        in oppositeArrayAbsent : Boolean;
        oppositeArrayAbsent == true;
    }
    requirement def GSA003_SunQuadrantLayout {
        doc /* GSA-003 [installed facet layout] the three array collecting normals shall face vehicle +Z, +X/+Z, and -X/+Z respectively, with all normal Y components zero within the dimensionless appearanceVerificationTolerance. Their centres shall lie on the corresponding forward face and signed forward chamfers; the forward centre X shall be zero within geometryVerificationToleranceM. The rear-array installation shall be absent. Verification uses composed poses in the vehicle frame. Sources and reconstruction limits are recorded in the provenance catalog; this criterion makes no mission-wide Sun coverage claim. */
        require GSAC003_ForwardFaceFrame {
            in positionToleranceM = GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::geometryVerificationToleranceM;
            in normalTolerance = GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::appearanceVerificationTolerance;
        }
        require GSAC003_ChamferFaceFrame {
            in normalTolerance = GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::appearanceVerificationTolerance;
        }
        require GSAC003_NoOppositeArray;
    }
    constraint def GSAC004_ResolvedArraySources {
        in declaredRequirementCount : Real;
        in requirementsWithResolvedSources : Real;
        declaredRequirementCount > 0.0
            and requirementsWithResolvedSources == declaredRequirementCount;
    }
    requirement def GSA004_ArrayTraceability {
        doc /* GSA-004 [source traceability] every array requirement selected by Verify_GriffinSolarRequirements shall resolve one unambiguous provenance owner and at least one source with a nonempty typed locator and enumeration role. Array identity and cardinality are accepted under GSA-001; installation poses are accepted under GSA-005. */
        require GSAC004_ResolvedArraySources;
    }
    constraint def GSAC005_InstalledModuleSize {
        in expectedInstalledFrameWidthM : Real;
        in measuredInstalledFrameWidthM : Real;
        in toleranceM : Real;
        toleranceM >= 0.0
            and RealFunctions::abs(measuredInstalledFrameWidthM
                - expectedInstalledFrameWidthM) <= toleranceM;
    }
    requirement def GSA005_ArrayPlacement {
        require GSAC005_InstalledModuleSize {
            in toleranceM = GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::geometryVerificationToleranceM;
        }
        doc /* GSA-005 [installation interface] installed width is the source column count times metric cell pitch plus the frame border. The bus attachment span controls the support links; it shall not truncate a photographed cell field. Installed row count sets frame height; centre Y derives from the belt-centre datum plus half the height difference from installationDatumHeightM, preserving the lower-edge alignment. Stations and orientations remain source-owned reconstruction datums. Compact brackets seat at the unchanged bus rails; slanted links derive from the rail-to-panel-edge endpoints to preserve the load path. No supplier installation ICD is available. */
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
    constraint def GSAC008_HingeEnvelope {
        in axisMatches : Boolean;
        in maximumDimensionOrStationErrorM : Real;
        in toleranceM : Real;
        axisMatches and toleranceM >= 0.0 and maximumDimensionOrStationErrorM >= 0.0
            and maximumDimensionOrStationErrorM <= toleranceM;
    }
    constraint def GSAC008_SupportLinkEndpoints {
        in maximumEndpointErrorSquaredM2 : Real;
        in toleranceM : Real;
        toleranceM >= 0.0 and maximumEndpointErrorSquaredM2 >= 0.0
            and maximumEndpointErrorSquaredM2 <= toleranceM * toleranceM;
    }
    requirement def GSA008_HingeAndStandoff {
        doc /* GSA-008 [reconstructed support geometry] each installed hinge cylinder shall use the source-defined X axis, radius, length and local station. Both support links shall place their axial endpoints at the source-derived rail-to-frame stations including minimumMountOverlapM seating at both ends. The maximum hinge dimension/station error and endpoint distance shall not exceed geometryVerificationToleranceM. This accepts the fixed presentation geometry; deployment kinematics and structural qualification require a separate mechanism definition. */
        require GSAC008_HingeEnvelope {
            in toleranceM = GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::geometryVerificationToleranceM;
        }
        require GSAC008_SupportLinkEndpoints {
            in toleranceM = GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::geometryVerificationToleranceM;
        }
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
    constraint def GSAC011_DescentSolarHeading {
        in telemetryFinite : Boolean;
        in automaticAuthority : Boolean;
        in acquisitionCompleted : Boolean;
        in acquisitionTimeS : Real;
        in maximumAcquisitionTimeS : Real;
        in landingHandoff : Boolean;
        in sampleCount : Real;
        in initialHeadingErrorRad : Real;
        in maximumTrackingErrorRad : Real;
        in trackingTimeS : Real;
        in azimuthToleranceRad : Real;
        in minimumTrackingTimeS : Real;
        telemetryFinite and automaticAuthority and acquisitionCompleted
            and acquisitionTimeS >= 0.0 and acquisitionTimeS <= maximumAcquisitionTimeS
            and landingHandoff and sampleCount > 0.0
            and RealFunctions::abs(initialHeadingErrorRad) <= azimuthToleranceRad
            and maximumTrackingErrorRad <= azimuthToleranceRad
            and trackingTimeS >= minimumTrackingTimeS;
    }
    requirement def GSA011_DescentSunPointing {
        require GSAC011_DescentSolarHeading {
            in azimuthToleranceRad = GriffinDescentSunPointingStudy::azimuthToleranceRad;
            in minimumTrackingTimeS = GriffinDescentSunPointingStudy::minimumTrackingTimeS;
            in maximumAcquisitionTimeS = GriffinDescentSunPointingStudy::acquisitionTimeS;
        }
        doc /* GSA-011 [operator study] the final approach shall start Sun-aligned and descending without a heading-acquisition hover; during autonomous powered descent, Griffin shall yaw the forward solar-array outward normal toward the measured Sun azimuth within GriffinDescentSunPointingStudy limits. Required thrust tilt retains priority. First accepted pilot flight input releases solar heading control; settled native contact hands control to the landing gear. The verification shall observe live heading error, automatic authority and successful landing. */
    }

    constraint def GSAC012_ArrayFacetClosure {
        in measuredEdgeGapSquaredM2 : Real;
        in toleranceM : Real;
        toleranceM >= 0.0 and measuredEdgeGapSquaredM2 >= 0.0
            and measuredEdgeGapSquaredM2 <= toleranceM * toleranceM;
    }
    requirement def GSA012_ConnectedArrayFacets {
        require GSAC012_ArrayFacetClosure {
            in toleranceM = GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::geometryVerificationToleranceM;
        }
        doc /* GSA-012 [derived installation geometry] the upper inboard frame corners of the side arrays shall meet the matching forward-array corners in the common Griffin assembly frame. Read composed Mesh points and instance poses from one document/stage generation. Missing or unsupported pose data are unavailable evidence. The June 2026 hardware photographs inform connected facets; the nominal width, bearings and metre-valued closure tolerance remain explicit reconstruction assumptions, not a flight mounting ICD. */
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
    requirement <'GSA-011'> gsa011 : GSA011_DescentSunPointing { subject lander : GriffinLanderComponent; }
    requirement <'GSA-012'> gsa012 : GSA012_ConnectedArrayFacets { subject arrays : GriffinSolarArrayAssembly; }

    verification def Verify_GriffinDescentSunPointing {
        subject lander : GriffinLanderComponent;
        objective { verify gsa011; }
    }

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
            verify gsa012;
        }
    }
}
