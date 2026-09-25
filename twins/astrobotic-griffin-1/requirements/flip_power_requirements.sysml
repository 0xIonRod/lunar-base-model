package FlipPowerRequirements {
    private import ScalarValues::String;

    // Proposed engineering contract. All verification cases below are PLANNED.
    // No runtime binding or satisfaction evidence is claimed by this declaration.
    part def FlipPowerContract {
        attribute sourceComponent : String = "FlipRequirements::FlipRover";
        attribute verificationStatus : String = "PLANNED; acceptance limits unresolved";
        attribute evidenceIndex : String = "requirements/FLIP_IMPLEMENTATION_STEPS.md";
        attribute energyBudgetTbd : String = "TBD: usable capacity Wh, reserve Wh, load profiles W, shadow duration s";
        attribute batteryProtectionTbd : String = "TBD: voltage V, current A, temperature K, protection deadlines s";
        attribute busInterfacesTbd : String = "TBD: bus limits V, ripple V, peak power W, connector ICD";
        attribute solarGenerationTbd : String = "TBD: active area m2, efficiency, temperature coefficients, degradation factors";
    }

    requirement def FEP001_EnergyBudget {
        doc /* FEP-001 [engineering; proposed; PLANNED]
        The rover shall close its energy budget for driving, payloads, avionics, communications and survival heaters over the reference mission with a defined reserve.
        Verification: Analysis: integrate time-varying loads and solar generation including shadow, dust, conversion losses and battery degradation.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fep001 : FEP001_EnergyBudget { subject system : FlipPowerContract; }

    requirement def FEP002_BatteryProtection {
        doc /* FEP-002 [engineering; proposed; PLANNED]
        The battery system shall enforce approved cell voltage, temperature, charge and discharge limits and isolate hazardous electrical faults.
        Verification: Test: overcurrent, undervoltage, overtemperature, charge inhibit and brownout recovery; hardware safety evidence required for flight claims.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fep002 : FEP002_BatteryProtection { subject system : FlipPowerContract; }

    requirement def FEP003_BusInterfaces {
        doc /* FEP-003 [engineering; proposed; PLANNED]
        Every electrical consumer and payload shall declare its bus range, peak and steady loads, grounding, connector and fault isolation interface.
        Verification: Inspection and electrical test: verify power quality and concurrent peak loads against the interface allocation.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fep003 : FEP003_BusInterfaces { subject system : FlipPowerContract; }

    requirement def FEP004_SolarGeneration {
        doc /* FEP-004 [engineering; proposed; PLANNED]
        Solar power shall depend on array orientation, illumination, active cell area, temperature and degradation; generated and stored energy shall be observable.
        Verification: Analysis and test: illuminated, oblique, shadowed and degraded-array cases with energy balance evidence.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fep004 : FEP004_SolarGeneration { subject system : FlipPowerContract; }

    verification def Verify_FLIPPowerRequirements {
        subject system : FlipPowerContract;
        verify fep001;
        verify fep002;
        verify fep003;
        verify fep004;
    }
}
