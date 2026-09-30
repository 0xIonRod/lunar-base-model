package FlipRecreationRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import ScalarValues::String;
    private import VerificationCases::*;
    private import ISQ::*;
    private import SI::*;

    // This is the 2026-09-30 public-source baseline for reference-based FLIP
    // reconstruction and the LunCoSim study.  Source claims, CAD study values,
    // and unavailable ICD values are intentionally kept distinct.
    part def FlipReferenceBaseline {
        attribute sourceRevision : String = "Public-source research checked 2026-09-30; see research/flip_rover.md";
        attribute sourceStatusPolicy : String = "PUBLIC, STUDY, or TBD; units and citation required for every numeric input";
        attribute verificationStatus : String = "PLANNED except for the v5 native CAD checks listed in the delivery review";

        attribute wheelCount : Integer = 4;
        attribute steeringMode : String = "four-wheel skid steer (LPSC 2026 #1874)";
        attribute wheelDiameterPublic :> ISQ::length = 0.930 [SI::m];
        attribute wheelWidthStudy :> ISQ::length = 0.280 [SI::m];
        attribute wheelbaseStudy :> ISQ::length = 1.700 [SI::m];
        attribute trackStudy :> ISQ::length = 2.000 [SI::m];
        attribute wheelCableCountPublic : Integer = 192;
        attribute wheelSpringCountPublic : Integer = 96;
        attribute wheelWidthStatus : String = "TBD flight value; 0.280 m is a CAD packaging choice";
        attribute wheelbaseTrackStatus : String = "TBD flight values; 1.700 m / 2.000 m are CAD packaging choices";

        attribute vehicleMassClaim :> ISQ::mass = 450.0 [SI::kg];
        attribute launchMassConstraint :> ISQ::mass = 480.0 [SI::kg];
        attribute payloadCapacityClaim :> ISQ::mass = 30.0 [SI::kg];
        attribute massStatus : String = "450 kg is a Venturi FLIP product claim; 480 kg is an LPSC launch/available-space constraint, not a second rover-mass measurement; payload inclusion and mass properties TBD";

        attribute maximumSpeedClaim :> ISQ::speed = 20.0 [SI::'km/h'];
        attribute alternateSpeedReference :> ISQ::speed = 15.0 [SI::'km/h'];
        attribute speedStatus : String = "20 km/h appears on current Venturi FLIP listing; 15 km/h appears on general wheel/rover material; no simulation limit is selected from either claim";
        attribute batteryPackCount : Integer = 2;
        attribute batteryPackLocationEvidence : String = "Venturi 2025 media kit: mounted behind the solar panels; exact placement and whether panels move with packs TBD";
        attribute batteryEnergyStatus : String = "TBD: usable Wh, voltage V, current A, chemistry, mass kg, operating-temperature K, BMS and cell series/parallel configuration";

        attribute arrayType : String = "collapsible solar array; exact flight segmentation and deployment mechanism TBD";
        attribute arrayStudyPose :> ISQ::planeAngle = 82.0 ['°'];
        attribute arrayStudyLimitDeg : String = "0..90 deg FreeCAD presentation proxy only";
        attribute arrayDimensionsStatus : String = "TBD flight dimensions, active area m2, power W, hinge axis and limits";
        attribute solarBackplateWidthStudy :> ISQ::length = 1.800 [SI::m];
        attribute solarBackplateHeightStudy :> ISQ::length = 1.380 [SI::m];
        attribute cameraCount : Integer = 2;
        attribute cameraLayout : String = "panel-mast-mounted, opposite-pointing cameras per Canadensys supplier post";

        attribute chassisDimensionsStatus : String = "TBD: no dimensioned FLIP general-arrangement drawing/ICD found in reviewed public sources";
        attribute chassisWidthStudy :> ISQ::length = 1.460 [SI::m];
        attribute chassisHeightStudy :> ISQ::length = 0.400 [SI::m];
        attribute chassisLengthStudy :> ISQ::length = 2.100 [SI::m];
        attribute batteryEnvelopeWidthStudy :> ISQ::length = 0.305 [SI::m];
        attribute batteryEnvelopeHeightStudy :> ISQ::length = 0.220 [SI::m];
        attribute batteryEnvelopeLengthStudy :> ISQ::length = 0.884 [SI::m];
        attribute rimFaceInsetStudy :> ISQ::length = 0.065 [SI::m];
        attribute visualBoundsStowedHeightStudy :> ISQ::length = 1.107 [SI::m];
        attribute visualBoundsDeployedHeightStudy :> ISQ::length = 2.634311 [SI::m];
        attribute lunarGravityStudy :> ISQ::acceleration = 1.62 [SI::m/(SI::s*SI::s)];
        attribute cadFrame : String = "X lateral, Y up, Z longitudinal; forward +Z; native CAD mm";
        attribute usdFrame : String = "right-handed Y-up SI metres; forward +Z; native authored geometry in m";
        attribute cadToUsdScale : Real = 0.001;

        attribute namedNasaPayloads : String = "METAL; LRA; LDES; Lunar LiDAR";
        attribute additionalPayloadStatus : String = "LPSC 2026 says 13 payloads total; May 2026 Astrolab release names four NASA investigations; remaining commercial/outreach allocations and ICDs TBD";
        attribute entryEgressMode : String = "direct top-deck egress after lander touchdown/release is the public baseline; ramp route is an optional separate study branch";
    }

    requirement def FVR001_SourceAndConfiguration {
        doc /* FVR-001 [configuration/evidence; PLANNED]
        Every numerical configuration value used by CAD, USD, Rust, Modelica, or Rhai shall state its unit, source revision, and status as PUBLIC, STUDY, or TBD. A TBD value shall block the affected run until an explicitly named and unit-bearing study override is supplied. Verification: inspect the SysML snapshot and each generated parameter manifest; fail preflight for unclassified or unitless inputs.
        */
    }
    requirement fvr001 : FVR001_SourceAndConfiguration { subject rover : FlipReferenceBaseline; }

    requirement def FVR002_WheelCountAndSteering {
        doc /* FVR-002 [mobility topology/behavior; PLANNED]
        FLIP shall be represented with four named directional stations (FL, RL, FR, RR) and the source-supported four-wheel skid-steer architecture. The control law shall command left/right wheel-side motion for straight, reverse, and turning maneuvers; it shall not apply front/rear steering angles. Verification: inspect four and only four station owners and run sign/parity tests for forward, reverse, left, right, braking, and stop on level terrain. Wheel actuator count, maximum torque, reduction and dynamic steering limits remain TBD until sourced.
        */
    }
    requirement fvr002 : FVR002_WheelCountAndSteering { subject rover : FlipReferenceBaseline; }

    requirement def FVR003_WheelGeometryAndCompliance {
        doc /* FVR-003 [wheel geometry; PLANNED]
        Each modeled FLIP wheel shall use the source-backed 0.930 m nominal diameter and reference-visible open hub, sprung cable web, inner wheel structure, crown and continuous flexible tread intent. The wheel-family evidence specifies 192 cables and 96 springs per wheel. Axial width, cable/spring sizing, tread material, hub geometry, loaded radius, stiffness, damping and deflection curves are TBD. A render may draw source-count detail, but only a separately parameterized and identified study tire law may affect physics. Verification: CAD/USD count and envelope check, plus contact/load-deflection test after an approved constitutive parameter set exists.
        */
    }
    requirement fvr003 : FVR003_WheelGeometryAndCompliance { subject rover : FlipReferenceBaseline; }

    requirement def FVR004_MassPayloadAndEnvelope {
        doc /* FVR-004 [mass/layout; PLANNED]
        The configuration ledger shall keep Venturi's 450 kg FLIP vehicle-mass claim, the LPSC 480 kg launch/available-space constraint, and the 30 kg payload-capacity claim as distinct values with distinct meanings. No mass roll-up shall silently double-count payload or infer component mass from render solids. The simulation shall declare one aggregate mass, centre of mass and inertia for each dynamic body, identify whether its payload is included, and expose any estimated mass properties as STUDY. FLIP overall chassis, wheelbase/track, component dimensions, CG, inertia and per-wheel load are TBD unless tagged STUDY. Verification: inspect mass roll-up, payload load cases, units, CG and inertia read-back; flight acceptance is blocked until the relevant ICD is provided.
        */
    }
    requirement fvr004 : FVR004_MassPayloadAndEnvelope { subject rover : FlipReferenceBaseline; }

    requirement def FVR005_FrameAndScale {
        doc /* FVR-005 [frame/unit behavior; PLANNED]
        The authored CAD reference shall declare X-lateral/Y-up/Z-longitudinal axes, +Z forward and millimetres. The LunCoSim/USD representation shall be right-handed, Y-up, +Z forward, in metres with one explicit 0.001 CAD-to-USD length scale. Wheel diameters, named station datums, panel pose, contact plane and aggregate bounds shall be checked in the composed world frame; no per-child visual rotation may conceal a root-frame error. Verification: round-trip a 930 mm reference length as 0.930 m and compare axes, bounds, and mount-frame translations.
        */
    }
    requirement fvr005 : FVR005_FrameAndScale { subject rover : FlipReferenceBaseline; }

    requirement def FVR006_SolarArrayBehavior {
        doc /* FVR-006 [power/mechanism; PLANNED]
        FLIP shall represent a collapsible solar array whose generated power depends on declared illumination, array orientation, active area, efficiency, temperature and degradation parameters. The CAD's single revolute panel with 0 degree stowed and 82 degree deployed pose inside a 0..90 degree limit is a presentation/study mechanism, not a flight hinge requirement. Runtime articulation shall use an explicit panel body, joint frames, limits, deployment command, retention state and collision envelope; unspecified flight values shall remain TBD. Verification: visual pose check, joint/frame audit, sampled clearance check, and Modelica illuminated/edge-on/shadowed power-balance cases.
        */
    }
    requirement fvr006 : FVR006_SolarArrayBehavior { subject rover : FlipReferenceBaseline; }

    requirement def FVR007_BatteryAndElectricalBehavior {
        doc /* FVR-007 [power; PLANNED]
        The rover shall expose two separately named battery-pack components, with the supplier-reported behind-array packaging represented only as a datum/visual study until pack mounting is confirmed. Modelica shall own continuous bus power, state of charge, charge/discharge limits and energy balance. State of charge shall remain within [0,1], and charge/discharge sign shall agree with power flow. Battery voltage, usable capacity, current limits, series/parallel topology, heater/BMS limits and mass are TBD; no legacy 28 V / 83.33 Ah value shall be used as FLIP flight data. Verification: compilation, port-binding, energy-balance and bounded SOC tests with every study override reported.
        */
    }
    requirement fvr007 : FVR007_BatteryAndElectricalBehavior { subject rover : FlipReferenceBaseline; }

    requirement def FVR008_ThermalBehavior {
        doc /* FVR-008 [thermal/environment; PLANNED]
        Modelica thermal states shall receive heat from declared wheel-motor, drive-electronics and battery loads and use explicit thermal storage, conductance and radiative/external boundary parameters. The Venturi public external-environment span (-240 to +130 deg C) shall not be used as an allowable internal component operating band. Component temperature limits, heater loads, emissivity, thermal paths and lunar-night duration are TBD. Verification: units/domain check, bounded-energy balance, and traceable thermal-boundary sensitivity runs; no survival claim without hardware-specific limits and evidence.
        */
    }
    requirement fvr008 : FVR008_ThermalBehavior { subject rover : FlipReferenceBaseline; }

    requirement def FVR009_SensingAndPayloads {
        doc /* FVR-009 [payload/perception; PLANNED]
        The representation shall provide two opposite-pointing solar-mast camera identities and separate, replaceable identities for the announced NASA payloads METAL, LRA, LDES and Lunar LiDAR. METAL's reported orientation is downward on a payload rail. The LRA is a passive optical marker and shall not be assigned an electrical load. LDES shall observe a dust-sensitive surface experiment; Lunar LiDAR shall provide range/point-cloud observations for navigation, obstacle detection and hazard avoidance. The LPSC 2026 update counts thirteen payloads total; the other manifest positions, all envelopes, mounts, interfaces, masses, fields of view and bus budgets are TBD. Verification: identity/count inspection, optical keep-out audit and API observation of only configured sensor outputs.
        */
    }
    requirement fvr009 : FVR009_SensingAndPayloads { subject rover : FlipReferenceBaseline; }

    requirement def FVR010_LanderReleaseAndEgress {
        doc /* FVR-010 [mission behavior; PLANNED]
        During descent and touchdown FLIP shall remain attached to its Griffin payload adapter. After validated lander touchdown and an explicit release event, the rover shall be able to leave the lander by the public direct top-deck egress route while preserving collision clearance. A ramp is optional only in a named alternative study branch and shall not gate baseline release. Adapter geometry, release loads/actuators and launch-state clearance remain TBD. Verification: fixed-joint presence before release; after release, no stale joint, positive separation, independent rover body ownership, and a short drive-away/contact check.
        */
    }
    requirement fvr010 : FVR010_LanderReleaseAndEgress { subject rover : FlipReferenceBaseline; }

    requirement def FVR011_VisualPhysicalOwnership {
        doc /* FVR-011 [implementation boundary; PLANNED]
        FreeCAD-derived GLB/mesh geometry shall be assigned visual-only purpose. USD component topology shall own render/collision/mass roles, wheel stations, rigid bodies and joints. Collision geometry shall use named simple proxies with a declared owner; detailed cables, spring coils, solar graphics and decals shall not become unintended colliders or physical bodies. Verification: composed USD topology and physicality-manifest audit plus geometry-only render comparison.
        */
    }
    requirement fvr011 : FVR011_VisualPhysicalOwnership { subject rover : FlipReferenceBaseline; }

    requirement def FVR012_ModelicaRustPolicy {
        doc /* FVR-012 [software/model ownership; PLANNED]
        Continuous electrical, wheel-compliance-study and thermal equations shall reside in Modelica. Mission phase order, command gating, remote/autonomy selection and discrete release policy shall reside in Twin-local Rhai. Existing generic Rust USD projection, rigid-body, wheel, control and port-binding kernels shall be used first. Add a reusable Rust capability only when a focused failing fixture proves that the generic API cannot express the required wheel, port, body or sensor behavior; do not add FLIP-name-specific fallback behavior or direct ECS mutation. Verification: architecture review, Modelica compilation, USD topology check and four-wheel actuator-port parity test.
        */
    }
    requirement fvr012 : FVR012_ModelicaRustPolicy { subject rover : FlipReferenceBaseline; }

    requirement def FVR013_StudyOverridesAndVerification {
        doc /* FVR-013 [verification/evidence; PLANNED]
        Every run shall record Twin/source revision, selected configuration, parameter override values/units/status, composed asset paths, body/joint/mass/collider report, Modelica generation/status, test duration, telemetry channels and verdict. The four wheel torque/speed ports shall all resolve before any mobility pass is reported. Sampled pose or wheel sweeps shall be described as sampled and shall not claim continuous clearance or hardware performance. Negative fixtures shall reject missing wheel ports, missing units, unknown mass status, invalid frame transforms and unbound physical bodies. Verification: execute the named Rhai observer and retain its structured verdict with the matching Editor-generation evidence.
        */
    }
    requirement fvr013 : FVR013_StudyOverridesAndVerification { subject rover : FlipReferenceBaseline; }

    verification def Verify_FLIPRecreationRequirements {
        subject rover : FlipReferenceBaseline;
        objective review_all_requirements {
            verify fvr001;
            verify fvr002;
            verify fvr003;
            verify fvr004;
            verify fvr005;
            verify fvr006;
            verify fvr007;
            verify fvr008;
            verify fvr009;
            verify fvr010;
            verify fvr011;
            verify fvr012;
            verify fvr013;
        }
    }
}
