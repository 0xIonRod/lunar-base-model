package GriffinSolarRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import ScalarValues::String;

    part def GriffinSolarArrayAssembly {
        attribute usdRootPath : String = "/World/Griffin1";
        attribute componentAsset : String = "components/lander/griffin_solar_panel_visual.usda";
        attribute childNames : String[12] = ("Frame", "Cells", "ArrayBackplane", "CellDividerX", "CellDividerXLeft", "CellDividerXRight", "CellDividerZ", "CellDividerZUpper", "CellDividerZLower", "MountBracket", "HingeBar", "MountLink");
        attribute frameWidthM : Real = 3.70;
        attribute frameThicknessM : Real = 0.14;
        attribute frameDepthM : Real = 2.50;
        attribute cellWidthM : Real = 3.40;
        attribute cellThicknessM : Real = 0.05;
        attribute cellDepthM : Real = 2.20;
        attribute cellOffsetYM : Real = 0.075;
        attribute dividerXWidthM : Real = 0.05;
        attribute dividerXThicknessM : Real = 0.04;
        attribute dividerZWidthM : Real = 3.40;
        attribute dividerZThicknessM : Real = 0.04;
        attribute mountBracketWidthM : Real = 0.44;
        attribute mountBracketThicknessM : Real = 0.32;
        attribute mountBracketDepthM : Real = 0.44;
        // The released panel hinge ICD is not public. These render-only
        // datums make the attachment readable and leave an explicit
        // replacement boundary for the flight mechanism rather than letting
        // the panel float on an unexplained bracket.
        attribute hingeBarRadiusM : Real = 0.10;
        attribute hingeBarLengthM : Real = 2.10;
        attribute hingeBarCenterYM : Real = -0.18;
        attribute hingeBarCenterZM : Real = 0.00;
        attribute mountLinkWidthM : Real = 0.20;
        attribute mountLinkHeightM : Real = 0.36;
        attribute mountLinkDepthM : Real = 0.18;
        attribute mountLinkCenterXM : Real = 0.00;
        attribute mountLinkCenterYM : Real = -0.08;
        attribute mountLinkCenterZM : Real = 0.00;
        attribute gridColumnCount : Integer = 3;
        attribute gridRowCount : Integer = 3;
        attribute cellFaceNormal : String = "+Y in component frame; outward after signed root X rotation onto the signed Z side";
        attribute collisionPolicy : String = "panel, cells, dividers, and bracket are render-only; electrical power owner is separate";
        attribute deploymentStatus : String = "fixed visual study state; flight deployment state TBD";
        attribute sourceReference : String = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute sourceFact : String = "Griffin uses triple-junction solar cells and a lithium-ion battery";
        attribute sourceRationale : String = "Solar panels are an independently replaceable visual/power interface with a mirrored pair and explicit station datums";
        attribute geometryStatus : String = "metric visual study proxy; panel cell layout and deployment kinematics are not public";
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
        doc /* GSA-006 [geometry] each panel frame shall be 3.70 m wide, 0.14 m thick, and 2.50 m deep; the cell surface shall be 3.40 m by 0.05 m by 2.20 m and offset +0.075 m in local Y. */
    }
    requirement def GSA007_CellGridAndMount {
        doc /* GSA-007 [geometry] each panel shall contain a 3 by 3 cell grid with named divider members and a 0.44 m by 0.32 m by 0.44 m mount bracket, all as named child geometry. The grid is a visual study assumption because public Griffin material identifies solar cells but does not publish panel CAD. */
    }
    requirement def GSA008_HingeAndStandoff {
        doc /* GSA-008 [interface geometry] each panel shall expose a render-only Z-axis hinge bar of radius 0.10 m and length 2.10 m at local Y = -0.18 m, plus a 0.20 m by 0.36 m by 0.18 m mount link at the declared local datum. These are explicit study assumptions because the public Griffin source confirms the solar-array concept but does not publish the deployment/hinge ICD. */
    }

    requirement gsa001 : GSA001_ArrayCount { subject arrays : GriffinSolarArrayAssembly; }
    requirement gsa002 : GSA002_ArrayStructure { subject arrays : GriffinSolarArrayAssembly; }
    requirement gsa003 : GSA003_ArraySymmetry { subject arrays : GriffinSolarArrayAssembly; }
    requirement gsa004 : GSA004_ArrayTraceability { subject arrays : GriffinSolarArrayAssembly; }
    requirement gsa005 : GSA005_ArrayPlacement { subject arrays : GriffinSolarArrayAssembly; }
    requirement gsa006 : GSA006_PanelEnvelope { subject arrays : GriffinSolarArrayAssembly; }
    requirement gsa007 : GSA007_CellGridAndMount { subject arrays : GriffinSolarArrayAssembly; }
    requirement gsa008 : GSA008_HingeAndStandoff { subject arrays : GriffinSolarArrayAssembly; }

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
        }
    }
}
