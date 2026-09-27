package GriffinLanderRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import ScalarValues::String;
    private import GriffinRequirementSources::TwinAssetPath;
    private import GriffinRequirementSources::UsdPrimPath;
    private import GriffinVisualConfigurationRequirements::GriffinReviewLanderName;

    // This package owns the integrated lander realization contract. The
    // vehicle file composes flight dynamics, collision geometry, and the
    // reusable visual component assets into one Griffin source assembly.
    part def GriffinLanderComponent {
        doc /* This package owns the canonical reusable lander component counts and presentation/flight ownership boundary. Typed component identities and configuration stations are owned by GriffinVisualConfigurationRequirements. */
        attribute componentName : GriffinReviewLanderName = "Griffin1";
        attribute componentAsset : TwinAssetPath = "vehicles/griffin_1.usda";
        attribute usdRootPath : UsdPrimPath = "/Griffin1";
        // Geometry configuration is owned by
        // GriffinVisualConfigurationRequirements::GriffinVisualConfiguration.
        // This part intentionally retains only identity, counts, and the
        // render/flight ownership boundary; station and envelope literals are
        // not duplicated here.
        attribute legCount : Integer = 4;
        attribute tankCount : Integer = 4;
        attribute engineCount : Integer = 7;
        attribute solarArrayCount : Integer = 3;
        // The open-frame mesh is a render study made from bounded member
        // sections. Its composed envelope may differ slightly from the
        // nominal station datum at clipped beam corners. This tolerance is
        // for that visual realization only; it is not a flight-structure
        // clearance or manufacturing tolerance.
        attribute visualEnvelopeToleranceM : Real = 0.02;
    }

    requirement def GLR001_BusTopology {
        doc /* GLR-001 [visual] the reusable lander shall expose the named octagonal open-frame bus configuration, lower service skirt, upper deck, and inspectable frame rails. */
    }
    requirement def GLR002_LandingLegs {
        doc /* GLR-002 [visual] exactly four named landing-leg components shall expose struts and a visible foot pad. */
    }
    requirement def GLR003_PropellantTanks {
        doc /* GLR-003 [visual study] exactly four named propellant-tank study assemblies shall expose a tank body and retention bands/cradle. Four is a replaceable Twin visualization assumption; public Griffin-1 sources do not publish tank count, type, stations, or dimensions. */
    }
    requirement def GLR004_EngineCluster {
        doc /* GLR-004 [visual] exactly seven named main-engine components shall expose a visible bell and throat. */
    }
    requirement def GLR005_SolarArrays {
        doc /* GLR-005 [configuration] installed array identities shall match the canonical solarArrayCount and the array configuration defined by GriffinSolarRequirements. Each array shall use the approved installation frame, orientation, deployment state, and panel envelope. */
    }
    requirement def GLR006_MetricEnvelope {
        doc /* GLR-006 [geometry] the render-only bus envelope shall match the authored metric width, depth, and height study datums within visualEnvelopeToleranceM; this tolerance does not qualify flight geometry. */
    }
    requirement def GLR007_Traceability {
        doc /* GLR-007 [evidence] component counts, status, and public references shall come from this SysML package; repeated instance identities shall use the typed enumerations in GriffinVisualConfigurationRequirements and be checked by a Twin Rhai observer. */
    }
    requirement def GLR008_StationPlacement {
        doc /* GLR-008 [layout] every replaceable lander component root uses the native Position and Direction values in GriffinVisualConfigurationRequirements; no verifier or builder owns a second placement table. The two Z-side legs rotate 90 degrees because the reusable leg asset's canted struts are authored in local X/Y. */
    }
    requirement def GLR009_ComponentIdentity {
        doc /* GLR-009 [configuration] the Griffin visual assembly shall use the stage-root part /Griffin1 and expose the composed bus and subsystem parts. */
    }
    requirement def GLR010_LocalFrameAndOwnership {
        doc /* GLR-010 [boundary] component transforms shall use the declared Y-up SI frame, while flight dynamics and collision authority remain outside the render-only component layer. */
    }
    requirement def GLR011_SolarOrientation {
        doc /* GLR-011 [configuration consistency] each composed solar-array root shall match its typed station and orientation in GriffinVisualConfigurationRequirements. */
    }

    requirement <'GLR-001'> glr001 : GLR001_BusTopology { subject lander : GriffinLanderComponent; }
    requirement <'GLR-002'> glr002 : GLR002_LandingLegs { subject lander : GriffinLanderComponent; }
    requirement <'GLR-003'> glr003 : GLR003_PropellantTanks { subject lander : GriffinLanderComponent; }
    requirement <'GLR-004'> glr004 : GLR004_EngineCluster { subject lander : GriffinLanderComponent; }
    requirement <'GLR-005'> glr005 : GLR005_SolarArrays { subject lander : GriffinLanderComponent; }
    requirement <'GLR-006'> glr006 : GLR006_MetricEnvelope { subject lander : GriffinLanderComponent; }
    requirement <'GLR-007'> glr007 : GLR007_Traceability { subject lander : GriffinLanderComponent; }
    requirement <'GLR-008'> glr008 : GLR008_StationPlacement { subject lander : GriffinLanderComponent; }
    requirement <'GLR-009'> glr009 : GLR009_ComponentIdentity { subject lander : GriffinLanderComponent; }
    requirement <'GLR-010'> glr010 : GLR010_LocalFrameAndOwnership { subject lander : GriffinLanderComponent; }
    requirement <'GLR-011'> glr011 : GLR011_SolarOrientation { subject lander : GriffinLanderComponent; }

    verification def Verify_GriffinLanderRequirements {
        subject lander : GriffinLanderComponent;
        objective {
            verify glr001;
            verify glr002;
            verify glr003;
            verify glr004;
            verify glr005;
            verify glr006;
            verify glr007;
            verify glr008;
            verify glr009;
            verify glr010;
            verify glr011;
        }
    }
}
