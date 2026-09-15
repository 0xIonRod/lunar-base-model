package GriffinSolarRequirements {
    private import ScalarValues::String;

    part def GriffinSolarArrayAssembly {
        attribute usdRootPath : String = "/World/Griffin1";
        attribute sourceComponent : String = "GriffinLanderRequirements::GriffinLanderComponent";
        attribute namesSource : String = "GriffinLanderRequirements::GriffinLanderComponent::solarArrayNames";
        attribute countSource : String = "GriffinLanderRequirements::GriffinLanderComponent::solarArrayCount";
        attribute childNames : String = "Frame,Cells";
        attribute deploymentStatus : String = "fixed visual study state; flight deployment state TBD";
    }

    requirement def GSA001_ArrayCount {
        doc /* GSA-001 [topology] exactly two named port/starboard solar-array owners are present and visible. */
    }
    requirement def GSA002_ArrayStructure {
        doc /* GSA-002 [visual] each array exposes a frame and cell surface with owned geometry. */
    }
    requirement def GSA003_ArraySymmetry {
        doc /* GSA-003 [layout] the two arrays occupy mirrored signed side stations in the authored SI/Y-up frame. */
    }
    requirement def GSA004_ArrayTraceability {
        doc /* GSA-004 [evidence] array identities and count resolve from the lander SysML source and deployment status is explicit. */
    }
    requirement def GSA005_ArrayPlacement {
        doc /* GSA-005 [layout] each array root transform matches the ordered metric station datum owned by GriffinLanderComponent. */
    }

    requirement gsa001 : GSA001_ArrayCount { subject arrays : GriffinSolarArrayAssembly; }
    requirement gsa002 : GSA002_ArrayStructure { subject arrays : GriffinSolarArrayAssembly; }
    requirement gsa003 : GSA003_ArraySymmetry { subject arrays : GriffinSolarArrayAssembly; }
    requirement gsa004 : GSA004_ArrayTraceability { subject arrays : GriffinSolarArrayAssembly; }
    requirement gsa005 : GSA005_ArrayPlacement { subject arrays : GriffinSolarArrayAssembly; }

    verification def Verify_GriffinSolarRequirements {
        subject arrays : GriffinSolarArrayAssembly;
        verify gsa001;
        verify gsa002;
        verify gsa003;
        verify gsa004;
        verify gsa005;
    }
}
