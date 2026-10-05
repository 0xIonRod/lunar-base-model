package GriffinFunctionalRequirements {
    private import Griffin1Requirements::Griffin1Lander;
    private import Griffin1Requirements::HostedRoverInterface;
    private import ScalarValues::Real;
    private import ScalarValues::Boolean;

    // Domain-owned requirement definitions. Griffin1Requirements owns only
    // the integrated system subject, requirement usages, and verification.

    requirement def GR001_LanderArchitecture {
        doc /* GR-001 [public+study] model a reusable Griffin body, four legs, and an octagonal payload deck; verify named USD topology. Rationale: public product material establishes the lander architecture; the named component split is the Twin's inspectable study representation. */
    }

    requirement def GR002_PayloadAdapter {
        doc /* GR-002 [integration] secure FLIP above the Griffin rover payload deck before release. All four wheel contact planes shall meet the adapter top surface within the shared geometry verification tolerance, and one fixed payload-adapter joint shall connect FLIP to the lander until the release gate. Verify wheel stations, tire radii, deck bounds, and joint topology in the composed scene. */
    }

    requirement def GR003_DeployableRamps {
        doc /* GR-003 [public optional hardware] model two optional Griffin side ramps with contact surfaces and inspectable hinges; do not treat ramps as a mandatory FLIP interface. Rationale: ramps are a public/optional egress interpretation, while the Twin must preserve the direct-deck alternative. */
    }

    requirement def GR004_SurfaceSequence {
        doc /* GR-004 [mission flow+operator policy] the unattended mission preserves powered descent/handoff, landing/settle, egress-path preparation, adapter release, FLIP egress, and route order. Manual U / OPEN RAMPS and lander F / DETACH ROVER shall remain enabled in every flight and landing phase, without requiring touchdown, automatic-guidance handoff, or settled ramps. F requests solver-owned adapter detachment immediately and repeated requests are idempotent. U starts the existing physical middle/toe/root hinge sequence independently of landing; finite target, travel-limit and measured settlement checks remain required. HUD actions remain available while FLIP is selected; its F retains the rover-specific autopilot meaning. Interactive landing presentation uses Modelica landing_contact, qualified by four-pad contact, upright attitude, velocity and angular/suspension rates, independently of the GNC handoff latch; an already-landed state shall be sampled rather than relying solely on a missed event. The operator touchdown-confirmed announcement shall occur once per scene descent, even if the live qualified touchdown signal falls and rises while the suspension settles. Scene restart shall reset the announcement latch. The vehicle HUD shall show the locally controlled lander or rover, with bounded display precision and waypoint labels below it. Source: explicit operator instructions, 2026-10-02. Rationale: a contact edge is live physics telemetry, not a new landing mission, and the HUD must identify the active control endpoint. Automatic egress/control transfer still waits for physical landing, settled ramps and completed adapter retirement. Source: explicit operator instruction, 2026-10-01, and assets/models/Lander.mo landing_contact equation. Rationale: manual mechanism authority is distinct from autonomous mission acceptance; a manually landed vehicle need not have a flight-supervisor handoff. */
    }

    requirement def GR006_SolarAssemblies {
        doc /* GR-006 [subsystem] represent Griffin arrays and FLIP's collapsible-array concept as named visual/power subassemblies; verify deployment state is not silently assumed. Rationale: separate ownership lets panel dimensions, placement, and deployment state be reviewed without mixing them with vehicle dynamics. */
    }

    requirement def GR007_GatedEgress {
        doc /* GR-007 [runtime] egress shall be a physical direct-deck or optional-ramp path with wheel/contact evidence, never a teleport from deck to terrain. Source: Twin egress runtime contract. Rationale: wheel/contact evidence is the minimum proof that rover release represents a traversable path rather than a scripted relocation. */
    }

    requirement def GR009_PayloadCapacity {
        doc /* GR-009 [public product value] Griffin payload capacity is 625 kg; accept loads from zero through the stated boundary and reject negative or over-capacity loads. The reusable GR009_PayloadWithinCapacity SysML constraint owns the predicate; provider observations and evidence are supplied by the generic SysML requirements evaluator. Rationale: the public product datum is the only authoritative capacity available to this Twin. */
        require GR009_PayloadWithinCapacity {
            in capacityKg = Griffin1Lander::payloadCapacityKg;
        }
    }

    constraint def GR009_PayloadWithinCapacity {
        in payloadKg : Real;
        in capacityKg : Real;
        payloadKg >= 0.0 and payloadKg <= capacityKg;
    }

    constraint def GR026_ReleaseEvidenceComplete {
        in touchdownObserved : Boolean;
        in detachAccepted : Boolean;
        in releaseTopologyValid : Boolean;
        touchdownObserved and detachAccepted and releaseTopologyValid;
    }

    requirement def GR026_AdapterRelease {
        doc /* GR-026 [automatic mission runtime] adapter release leaves no stale joint or pre-release route ownership and transfers FLIP control exactly once after the automatic mission gates. The touchdownObserved constraint qualifies automatic mission acceptance, not permission for manual F detachment. Source: Twin adapter-release runtime contract. Rationale: exactly-once ownership transfer prevents the lander and rover controllers from simultaneously commanding the released vehicle. */
        require GR026_ReleaseEvidenceComplete;
    }

    requirement def GR028_InterfaceResolution {
        doc /* GR-028 [integration planned] electrical, thermal, propulsion, guidance, and mobility interface names resolve without silent defaults. Source: Twin subsystem interface registry. Rationale: explicit unresolved interfaces are safer than silently accepting a default that changes mission behavior. */
    }

    requirement def GR034_SurfaceRouteDatums {
        doc /* GR-034 [provisional mission interface] author every surface-operations route marker, speed, and arrival radius from one ordered SysML table; the approach marker and 0.35 m approach-lane radius shall require FLIP's front wheels to reach the composed deck-to-ramp transition, and the centreline exit gate shall place the trailing wheels beyond the deployed ramp tip even at the edge of its source-owned arrival radius. The transition length and required overlap are owned by GriffinRampRequirements::GriffinEgressRamp and measured across the full octagonal adapter width; route acceptance also requires composed transition, wheel-path, and octagonal deck evidence. During the approach leg, continuous guidance aims at the next authored ramp-exit datum in the landed ramp frame; the original approach datum and 0.35 m radius remain the arrival test. Rationale: an Ackermann chassis cannot turn in place toward a nearby deck-edge point; owned production trial 49817 stalled 0.530 m from that point with about 0.64 rad heading error. This is simulator mission policy, not an Astrobotic navigation specification. The later diagonal survey legs use the conservative 0.22..0.14 m/s study-speed envelope. Rationale: route control must target the composed component interface and must not declare egress complete while FLIP's trailing wheels are still on the ramp. */
    }

    requirement def GR035_EgressTerrainContact {
        doc /* GR-035 [mission interface+physics] after leaving the deployed
         * ramp, FLIP shall have four valid native wheel contacts whose measured
         * hit heights match the source-backed DEM within the study tolerance
         * owned by GriffinSimulation. Production landing and egress surfaces
         * shall contain no artificial slabs. The terrain source is the locally
         * reprojected LROC NOBILE03 crop; the selected touchdown anchor remains
         * a study location, not an Astrobotic site ICD. Contact observations,
         * DEM heights and sample ticks are retained at the ramp-exit boundary.
         * Source/rationale: user removal request and the artificial apron edge
         * causing route stall in the 2026-10-04 production run. Verify through
         * Griffin1Requirements::Verify_GriffinSurfaceOperations.
         */
    }


    // System integration requirement usages owned by this domain.
    requirement <'GR-001'> gr001 : GR001_LanderArchitecture { subject lander : Griffin1Lander; }
    requirement <'GR-002'> gr002 : GR002_PayloadAdapter { subject lander : Griffin1Lander; }
    requirement <'GR-003'> gr003 : GR003_DeployableRamps { subject lander : Griffin1Lander; }
    requirement <'GR-004'> gr004 : GR004_SurfaceSequence { subject lander : Griffin1Lander; subject rover : HostedRoverInterface; }
    requirement <'GR-006'> gr006 : GR006_SolarAssemblies { subject lander : Griffin1Lander; subject rover : HostedRoverInterface; }
    requirement <'GR-007'> gr007 : GR007_GatedEgress { subject rover : HostedRoverInterface; }
    requirement <'GR-009'> gr009 : GR009_PayloadCapacity { subject lander : Griffin1Lander; }
    requirement <'GR-026'> gr026 : GR026_AdapterRelease { subject lander : Griffin1Lander; subject rover : HostedRoverInterface; }
    requirement <'GR-028'> gr028 : GR028_InterfaceResolution { subject lander : Griffin1Lander; subject rover : HostedRoverInterface; }
    requirement <'GR-034'> gr034 : GR034_SurfaceRouteDatums { subject rover : HostedRoverInterface; }
    requirement <'GR-035'> gr035 : GR035_EgressTerrainContact { subject rover : HostedRoverInterface; }


    verification def Verify_GriffinAdapterRelease {
        subject lander : Griffin1Lander;
        subject rover : HostedRoverInterface;
        objective {
            verify GriffinFunctionalRequirements::gr026;
        }
    }

    verification def Verify_GriffinPayloadCapacity {
        subject lander : Griffin1Lander;
        objective {
            verify gr009;
        }
    }

}
