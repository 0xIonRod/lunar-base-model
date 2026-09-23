package GriffinFunctionalRequirements {
    private import Griffin1Requirements::Griffin1Lander;
    private import Griffin1Requirements::HostedRoverInterface;
    private import ScalarValues::Real;
    private import ScalarValues::Boolean;

    // Domain-owned requirement definitions. Griffin1Requirements owns only
    // the integrated system subject, requirement usages, and verification.

    requirement def GR001_LanderArchitecture {
        doc /* GR-001 [public+study] model a reusable Griffin body, four legs, and an octagonal payload deck; verify named USD topology. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/. Rationale: the product page establishes the lander architecture; the named component split is the Twin's inspectable study representation. */
    }

    requirement def GR002_PayloadAdapter {
        doc /* GR-002 [integration] provide an explicit payload-adapter datum that holds FLIP before the release gate; verify the fixed-joint interface in composed USD. Source: Twin adapter/release contract and https://www.astrolab.space/flip/. Rationale: a named interface is needed to distinguish secured pre-release state from post-release mobility. */
    }

    requirement def GR003_DeployableRamps {
        doc /* GR-003 [public optional hardware] model two optional Griffin side ramps with contact surfaces and inspectable hinges; do not treat ramps as a mandatory FLIP interface. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/. Rationale: ramps are a public/optional egress interpretation, while the Twin must preserve the direct-deck alternative. */
    }

    requirement def GR004_SurfaceSequence {
        doc /* GR-004 [mission flow] preserve landing/settle, egress-path preparation, adapter release, FLIP egress, and route order; verify with a Twin Rhai scenario. Source: Twin mission scenario contract. Rationale: the ordered gates prevent control from transferring to an airborne or still-secured rover. */
    }

    requirement def GR006_SolarAssemblies {
        doc /* GR-006 [subsystem] represent Griffin arrays and FLIP's collapsible-array concept as named visual/power subassemblies; verify deployment state is not silently assumed. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ and https://www.astrolab.space/flip/. Rationale: separate ownership lets panel dimensions, placement, and deployment state be reviewed without mixing them with vehicle dynamics. */
    }

    requirement def GR007_GatedEgress {
        doc /* GR-007 [runtime] egress shall be a physical direct-deck or optional-ramp path with wheel/contact evidence, never a teleport from deck to terrain. Source: Twin egress runtime contract. Rationale: wheel/contact evidence is the minimum proof that rover release represents a traversable path rather than a scripted relocation. */
    }

    requirement def GR009_PayloadCapacity {
        doc /* GR-009 [public product value] Griffin payload capacity is 625 kg; accept loads from zero through the stated boundary and reject negative or over-capacity loads. The reusable GR009_PayloadWithinCapacity SysML constraint owns the predicate; provider observations and evidence are supplied by the generic SysML requirements evaluator. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/. Rationale: the public product datum is the only authoritative capacity available to this Twin. */
        require GR009_PayloadWithinCapacity;
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
        doc /* GR-026 [runtime] adapter release leaves no stale joint or pre-release route ownership and transfers FLIP control exactly once. Source: Twin adapter-release runtime contract. Rationale: exactly-once ownership transfer prevents the lander and rover controllers from simultaneously commanding the released vehicle. */
        require GR026_ReleaseEvidenceComplete;
    }

    requirement def GR028_InterfaceResolution {
        doc /* GR-028 [integration planned] electrical, thermal, propulsion, guidance, and mobility interface names resolve without silent defaults. Source: Twin subsystem interface registry. Rationale: explicit unresolved interfaces are safer than silently accepting a default that changes mission behavior. */
    }

    requirement def GR034_SurfaceRouteDatums {
        doc /* GR-034 [provisional mission interface] author every surface-operations route marker, speed, and arrival radius from one ordered SysML table; the approach marker and 0.35 m approach-lane radius shall require FLIP's front wheels to reach the composed deck-to-ramp transition while accepting measured low-speed steering drift, and the exit marker shall lie beyond the 8.00 m physical ramp envelope with a 0.30 m radius on the ramp centreline. The 1.05 m transition datum bridges the central 2.20 m adapter half-width to the 3.20 m hinge with 0.05 m contact overlap; the route remains unaccepted until the transition, wheel path, and octagonal deck interface have composed observations. The later diagonal survey legs use the conservative 0.22..0.14 m/s study-speed envelope. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ and the Twin physical-ramp study in requirements/griffin_ramp_requirements.sysml. Rationale: route control must target the composed component interface instead of stale coordinates, excessive corner speed, or an oversized tolerance that can declare egress complete while FLIP remains on the deck. */
    }

    requirement def GR035_EgressApronContact {
        doc /* GR-035 [mission interface+physics] provide a named, collidable EgressApron that overlaps the deployed 8.00 m ramp tip and extends beyond the (12.00,0.00) centreline exit marker so the released FLIP transitions to a continuous surface before survey navigation. Source: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/; https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/; twin://astrobotic-griffin-1/scenes/griffin_1_surface_ops.usda. Rationale: the public sources do not publish a Griffin site-apron ICD, so the 10.00 m x 8.00 m x 0.10 m apron at (13.50,-0.05,-1.00) is an explicit replaceable Twin study assumption. Its top y=0.00 m matches the normalized ramp-tip terrain datum and its centreline placement works with the straight exit gate; it closes the measured geometry gap between the ramp end near x=11.20 m and the original landing-pad boundary at x=6.00 m. It must be authored through the typed Editor and verified through composed collision and wheel-contact evidence, never by moving the rover. */
    }


    // System integration requirement usages owned by this domain.
    requirement gr001 : GR001_LanderArchitecture { subject lander : Griffin1Lander; }
    requirement gr002 : GR002_PayloadAdapter { subject lander : Griffin1Lander; }
    requirement gr003 : GR003_DeployableRamps { subject lander : Griffin1Lander; }
    requirement gr004 : GR004_SurfaceSequence { subject lander : Griffin1Lander; subject rover : HostedRoverInterface; }
    requirement gr006 : GR006_SolarAssemblies { subject lander : Griffin1Lander; subject rover : HostedRoverInterface; }
    requirement gr007 : GR007_GatedEgress { subject rover : HostedRoverInterface; }
    requirement gr009 : GR009_PayloadCapacity { subject lander : Griffin1Lander; }
    requirement gr026 : GR026_AdapterRelease { subject lander : Griffin1Lander; subject rover : HostedRoverInterface; }
    requirement gr028 : GR028_InterfaceResolution { subject lander : Griffin1Lander; subject rover : HostedRoverInterface; }
    requirement gr034 : GR034_SurfaceRouteDatums { subject rover : HostedRoverInterface; }
    requirement gr035 : GR035_EgressApronContact { subject rover : HostedRoverInterface; }


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
