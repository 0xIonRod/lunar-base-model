package FlipWheelRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::String;

    part def FlipDirectionalWheelAssembly {
        attribute usdRootPath : String = "/World/FLIP";
        attribute componentAsset : String = "components/rover/flip_wheel_visual.usda";
        ref part sourceRover : FlipRequirements::FlipRover;
        ref attribute wheelNames : FlipRequirements::FlipRover::visualWheelNames;
        ref attribute wheelCount : FlipRequirements::FlipRover::visualRoverWheelCount;
        ref attribute wheelRadius : FlipRequirements::FlipRover::visualRoverWheelRadiusM;
        attribute childNames : String[3] = ("Tire", "MetalHub", "HubCap");
        attribute suspensionVisualChild : String = "Suspension/SuspensionStrut";
        ref part suspension : FlipSuspensionRequirements::FlipSuspensionComponent;
        ref attribute frontSteeringAngle : FlipRequirements::FlipRover::frontSteeringAngleDeg;
        ref attribute rearSteeringAngle : FlipRequirements::FlipRover::rearSteeringAngleDeg;
        attribute tireRadiusM : Real = 0.45;
        attribute tireWidthM : Real = 0.30;
        attribute hubRadiusM : Real = 0.25;
        attribute hubWidthM : Real = 0.33;
        attribute hubCapRadiusM : Real = 0.10;
        attribute hubCapWidthM : Real = 0.36;
        attribute wheelAxis : String = "Z";
        attribute inactiveStationPolicy : String = "middle stations are authored inactive; exactly four directional wheels are acceptance scope";
    }

    requirement def FWW001_WheelCount {
        doc /* FWW-001 [topology] exactly four named FLIP directional wheel stations are active: FL, RL, FR, and RR. */
    }
    requirement def FWW002_WheelGeometry {
        doc /* FWW-002 [visual] every active station exposes a tire, metal hub, and hub cap with the source wheel radius. */
    }
    requirement def FWW003_AllWheelSteering {
        doc /* FWW-003 [behavior] front and rear steering angles are read from FlipRequirements and applied to the corresponding wheel stations. */
    }
    requirement def FWW004_WheelTraceability {
        doc /* FWW-004 [evidence] wheel identities and count resolve from the rover SysML source; inactive middle station proxies do not count. */
    }
    requirement def FWW005_WheelPlacement {
        doc /* FWW-005 [layout] each directional wheel station transform matches the ordered metric X/Y/Z station datum owned by FlipRover. */
    }
    requirement def FWW006_SuspensionVisual {
        doc /* FWW-006 [integration] each active wheel station references the detached FlipSuspension component; its internal geometry and collision contract are verified by FlipSuspensionRequirements. */
    }
    requirement def FWW007_WheelEnvelope {
        doc /* FWW-007 [geometry] each wheel shall contain a Z-axis tire of radius 0.45 m and width 0.30 m, a hub of radius 0.25 m and width 0.33 m, and a cap of radius 0.10 m and width 0.36 m. */
    }

    requirement <'FWW-001'> fww001 : FWW001_WheelCount { subject wheels : FlipDirectionalWheelAssembly; }
    requirement <'FWW-002'> fww002 : FWW002_WheelGeometry { subject wheels : FlipDirectionalWheelAssembly; }
    requirement <'FWW-003'> fww003 : FWW003_AllWheelSteering { subject wheels : FlipDirectionalWheelAssembly; }
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
