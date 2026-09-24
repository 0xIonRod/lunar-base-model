package GriffinVisualRequirements {
    private import Griffin1Requirements::Griffin1Lander;
    private import Griffin1Requirements::HostedRoverInterface;

    // Domain-owned requirement definitions. Griffin1Requirements owns only
    // the integrated system subject, requirement usages, and verification.

    requirement def GR015_NozzleGeometry {
        doc /* GR-015 [visual+physics] each named lander part resolves to geometry and the nozzle owns visible bell geometry that is not a collider. Rationale: visible propulsion detail must remain replaceable presentation while thrust/collision stay with the flight model. */
    }

    requirement def GR016_SolarLayout {
        doc /* GR-016 [mission configuration] realize the array count and Sun-quadrant arrangement defined by GriffinSolarRequirements::GSA001_ArrayCount and GSA003_SunQuadrantLayout, with every panel supported from the bus structure. Astrobotic's integration image shows upright panel faces on adjacent lander sides. The current opposite-side visual proxy is nonconforming; exact stations, angles, dimensions, and supports await the installation drawing. */
    }

    requirement def GR020_ProxySuppression {
        doc /* GR-020 [visual ownership] suppress inherited comparison geometry when a named part owns the visible representation; hidden duplicates do not count as removal. Source: Twin component ownership policy. Rationale: inactive or hidden duplicates still obscure which component owns the rendered geometry and can reappear during composition. */
    }

    requirement def GR032_MainEngineBells {
        doc /* GR-032 [public product value] model exactly seven visible, non-colliding main-engine bell geometries. Rationale: the public seven-engine architecture fixes the count; bell dimensions remain a separately labeled visual proxy. */
    }

    requirement def GR033_PropellantTanks {
        doc /* GR-033 [public integration value] model four visible, source-owned COPV study assemblies at the ordered GriffinVisualConfiguration tank stations and scales. The vessel skin and retention bands are render-only; flight propellant mass remains in MainPropulsion. Exact COPV dimensions and placement remain TBD. Rationale: four repeated tank owners represent the visible system without retaining incompatible Capsule placeholders; public material does not provide a certified tank ICD. */
    }

    requirement def GRV001_PresentationFrame {
        doc /* GV-001 [visual] the review composition shall expose an authored VisualCamera in the project SI/Y-up frame. Source: LunCoSim visual review contract. Rationale: a named camera makes visual evidence repeatable across headful and capture runs. */
    }

    requirement def GRV002_LanderPresentation {
        doc /* GV-002 [visual] the review shall show Griffin-1 as a recognizable faceted lander with its four legs, payload deck, and seven-engine cluster. The current visual study uses an octagonal open frame and a separate octagonal tank-support perimeter with four study tank openings; this is not a published tank ICD. */
    }

    requirement def GRV003_GriffinSolarAssemblies {
        doc /* GV-003 [visual] the review shall show the solar configuration defined by GriffinSolarRequirements::GSA001_ArrayCount and GSA003_SunQuadrantLayout as upright frame/cell assemblies across adjacent lander sides, each with a visible structural support path and the clearance-shaped outline shown in current Griffin-1 integration imagery. The current Twin render has two arrays on opposite signed-Z sides and fails this visual configuration. Image-derived placement and outline are qualitative only; do not infer dimensions or hinge kinematics from perspective photographs. */
    }

    requirement def GRV004_ScaleDatums {
        doc /* GV-004 [visual] review geometry shall agree with the SysML deck, wheel, landing-pad, and ground scale datums in metres. Source: Moon Base SI/Y-up project contract. Rationale: common scale datums are required to judge rover-to-lander proportions and contact plausibility. */
    }

    requirement def GRV005_RenderOwnership {
        doc /* GV-005 [visual ownership] presentation geometry shall be render-only where it is not a load-bearing collider; metric landing-pad datums are guide-only and hidden, and the test shall query collision, purpose, and visibility attributes. Source: LunCoSim visual/physics ownership policy. Rationale: visible study geometry must not quietly alter contact or mass behavior. */
    }

    requirement def GRV006_LunarContext {
        doc /* GV-006 [visual] the review shall include the South-Pole terrain asset using the canonical terrain_layered.wgsl shader and one project light, without introducing a second physics model. Rationale: the context supports mission readability while keeping terrain physics owned by the simulator. */
    }

    requirement def GRV007_VisualEvidence {
        doc /* GV-007 [evidence] the visual verdict shall be emitted by Twin Rhai and paired with a captured frame and composed USD query from the same source revision. Source: Twin visual evidence gate. Rationale: matching source revision, query, and frame prevents stale screenshots from being presented as current model evidence. */
    }


    // System integration requirement usages owned by this domain.
    requirement <'GR-015'> gr015 : GR015_NozzleGeometry { subject lander : Griffin1Lander; }
    requirement <'GR-016'> gr016 : GR016_SolarLayout { subject lander : Griffin1Lander; }
    requirement <'GR-020'> gr020 : GR020_ProxySuppression { subject lander : Griffin1Lander; }
    requirement <'GR-032'> gr032 : GR032_MainEngineBells { subject lander : Griffin1Lander; }
    requirement <'GR-033'> gr033 : GR033_PropellantTanks { subject lander : Griffin1Lander; }
    requirement <'GV-001'> gv001 : GRV001_PresentationFrame { subject lander : Griffin1Lander; }
    requirement <'GV-002'> gv002 : GRV002_LanderPresentation { subject lander : Griffin1Lander; }
    requirement <'GV-003'> gv003 : GRV003_GriffinSolarAssemblies { subject lander : Griffin1Lander; }
    requirement <'GV-004'> gv004 : GRV004_ScaleDatums { subject lander : Griffin1Lander; subject rover : HostedRoverInterface; }
    requirement <'GV-005'> gv005 : GRV005_RenderOwnership { subject lander : Griffin1Lander; subject rover : HostedRoverInterface; }
    requirement <'GV-006'> gv006 : GRV006_LunarContext { subject lander : Griffin1Lander; }
    requirement <'GV-007'> gv007 : GRV007_VisualEvidence { subject lander : Griffin1Lander; subject rover : HostedRoverInterface; }



    verification def Verify_GriffinVisualRequirements {
        subject lander : Griffin1Lander;
        subject rover : HostedRoverInterface;
        objective {
            verify GriffinVisualRequirements::gv001;
            verify GriffinVisualRequirements::gv002;
            verify GriffinVisualRequirements::gv003;
            verify GriffinVisualRequirements::gv004;
            verify GriffinVisualRequirements::gv005;
            verify GriffinVisualRequirements::gv006;
            verify GriffinVisualRequirements::gv007;
        }
    }

}
