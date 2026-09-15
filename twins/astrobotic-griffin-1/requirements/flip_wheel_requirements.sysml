package FlipWheelRequirements {
    private import ScalarValues::String;

    part def FlipDirectionalWheelAssembly {
        attribute usdRootPath : String = "/World/FLIP";
        attribute sourceComponent : String = "FlipRequirements::FlipRover";
        attribute namesSource : String = "FlipRequirements::FlipRover::visualWheelNames";
        attribute countSource : String = "FlipRequirements::FlipRover::visualRoverWheelCount";
        attribute childNames : String = "Tire,MetalHub,HubCap";
        attribute steeringSource : String = "frontSteeringAngleDeg,rearSteeringAngleDeg";
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

    requirement fww001 : FWW001_WheelCount { subject wheels : FlipDirectionalWheelAssembly; }
    requirement fww002 : FWW002_WheelGeometry { subject wheels : FlipDirectionalWheelAssembly; }
    requirement fww003 : FWW003_AllWheelSteering { subject wheels : FlipDirectionalWheelAssembly; }
    requirement fww004 : FWW004_WheelTraceability { subject wheels : FlipDirectionalWheelAssembly; }

    verification def Verify_FLIPWheelRequirements {
        subject wheels : FlipDirectionalWheelAssembly;
        verify fww001;
        verify fww002;
        verify fww003;
        verify fww004;
    }
}
