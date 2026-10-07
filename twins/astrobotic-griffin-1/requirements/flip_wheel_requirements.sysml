// Provisional size reconstruction, 2026-09-30. See griffin-size-evidence.md.
// CAD dimensions are estimates; geometry promotion does not qualify dynamics.
package FlipWheelRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::String;
    private import GriffinRequirementSources::UsdPrimPath;

    enum def FlipWheelAxis { Z; }

    part def FlipDirectionalWheelAssembly {
        attribute usdRootPath : UsdPrimPath = "/World/FLIP";
        ref part sourceRover : FlipRequirements::FlipRover;
        ref attribute wheelStations : FlipRequirements::FlipRover::wheelStations;
        ref attribute tireRadiusM : FlipRequirements::FlipRover::wheelRadiusM;
        ref attribute tireWidthM : FlipRequirements::FlipRover::wheelWidthM;
        ref part suspension : FlipSuspensionRequirements::FlipSuspensionComponent;
        ref attribute suspensionRestLengthM : FlipRequirements::FlipRover::suspensionRestLengthM;
        attribute wheelAxis : FlipWheelAxis = "Z";
    }

    requirement def FWW001_WheelCount {
        doc /* FWW-001 [topology] exactly four named FLIP directional wheel stations are active: FL, RL, FR, and RR. */
    }
    requirement def FWW002_WheelGeometry {
        doc /* FWW-002 [visual] each active station uses its physical UsdGeomCylinder as the sole tire surface. No additional Visual/Tire geometry shall be authored. The shared tire material supplies rim, hub and tread appearance. Rationale: lunco-usd-sim::spawn_wheel_visual already transfers this cylinder mesh to a runtime render child driven by wheel state; a second authored tire creates duplicate surfaces. Source: LunCoSim skills/build-vehicle/SKILL.md and crates/lunco-usd-sim/src/lib.rs, inspected 2026-09-30. */
    }
    requirement def FWW003_SteeringArchitecture {
        doc /* FWW-003 [behavior] the composed FLIP vehicle uses the SysML-selected steering architecture; the shared skid drive law turns it with independent left/right wheel drive on fixed-axis wheels. */
    }
    requirement def FWW004_WheelTraceability {
        doc /* FWW-004 [evidence] wheel identities and count resolve from the rover SysML source. */
    }
    requirement def FWW005_WheelPlacement {
        doc /* FWW-005 [layout] each directional wheel station transform matches the ordered metric X/Y/Z station datum owned by FlipRover. */
    }
    requirement def FWW006_SuspensionVisual {
        doc /* FWW-006 [integration] each active wheel station references the detached FlipSuspension component; its internal geometry and collision contract are verified by FlipSuspensionRequirements. */
    }
    requirement def FWW007_WheelEnvelope {
        doc /* FWW-007 [geometry] the wheel cylinder radius and height shall match the physical wheel radius and width, with a Z axle in the reconstructed X-forward frame. Its purpose is default so the same geometry serves rendering and contact. Suspension and spin shall drive the runtime render child from wheel state, preserving the authored axle and rest pose. Dimensions remain study estimates in griffin-size-evidence.md; deleting duplicate geometry does not change their evidential status. */
    }

    requirement <'FWW-001'> fww001 : FWW001_WheelCount { subject wheels : FlipDirectionalWheelAssembly; }
    requirement <'FWW-002'> fww002 : FWW002_WheelGeometry { subject wheels : FlipDirectionalWheelAssembly; }
    requirement <'FWW-003'> fww003 : FWW003_SteeringArchitecture { subject wheels : FlipDirectionalWheelAssembly; }
    requirement <'FWW-004'> fww004 : FWW004_WheelTraceability { subject wheels : FlipDirectionalWheelAssembly; }
    requirement <'FWW-005'> fww005 : FWW005_WheelPlacement { subject wheels : FlipDirectionalWheelAssembly; }
    requirement <'FWW-006'> fww006 : FWW006_SuspensionVisual { subject wheels : FlipDirectionalWheelAssembly; }
    requirement <'FWW-007'> fww007 : FWW007_WheelEnvelope { subject wheels : FlipDirectionalWheelAssembly; }

    verification def Verify_FLIPWheelRequirements {
        subject wheels : FlipDirectionalWheelAssembly;
        objective {
            verify fww001;
            verify fww002;
            verify fww003;
            verify fww004;
            verify fww005;
            verify fww006;
            verify fww007;
        }
    }
}
