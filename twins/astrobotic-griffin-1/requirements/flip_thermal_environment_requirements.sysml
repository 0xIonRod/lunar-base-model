package FlipThermalEnvironmentRequirements {
    private import ScalarValues::String;

    // Proposed engineering contract. All verification cases below are PLANNED.
    // No runtime binding or satisfaction evidence is claimed by this declaration.
    part def FlipThermalEnvironmentContract {
        attribute sourceComponent : String = "FlipRequirements::FlipRover";
        attribute verificationStatus : String = "PLANNED; acceptance limits unresolved";
        attribute evidenceIndex : String = "requirements/FLIP_IMPLEMENTATION_STEPS.md";
        attribute thermalLimitsTbd : String = "TBD: component limits K, site boundary conditions, heater power W";
        attribute nightSurvivalTbd : String = "TBD: dark interval s, survival limits K, restart energy Wh";
        attribute dustToleranceTbd : String = "TBD: dust simulant, size distribution, exposure dose, degradation limits";
        attribute radiationMaterialsTbd : String = "TBD: dose Gy, single-event criteria, material limits, cycle count";
    }

    requirement def FTE001_ThermalLimits {
        doc /* FTE-001 [engineering; proposed; PLANNED]
        Battery, electronics, motors and sensors shall remain within allocated operating or survival temperatures for site-specific hot, cold and shadow cases.
        Verification: Thermal analysis and thermal-vacuum testing: include solar, surface radiation, conduction, dissipation and heater control.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fte001 : FTE001_ThermalLimits { subject system : FlipThermalEnvironmentContract; }

    requirement def FTE002_NightSurvival {
        doc /* FTE-002 [engineering; proposed; PLANNED]
        The rover shall survive the allocated unilluminated interval and resume operations within the approved restart conditions.
        Verification: Coupled power/thermal analysis and survival test: account for battery temperature, reserve, heaters and cold start.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fte002 : FTE002_NightSurvival { subject system : FlipThermalEnvironmentContract; }

    requirement def FTE003_DustTolerance {
        doc /* FTE-003 [engineering; proposed; PLANNED]
        Exposed mechanisms, optics, radiators, solar cells and connectors shall retain allocated performance after the defined dust exposure.
        Verification: Dust exposure testing: compare torque, optical quality, heat rejection and power before and after exposure.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fte003 : FTE003_DustTolerance { subject system : FlipThermalEnvironmentContract; }

    requirement def FTE004_RadiationMaterials {
        doc /* FTE-004 [engineering; proposed; PLANNED]
        Electronics and exposed materials shall tolerate the mission radiation, vacuum and thermal-cycle environments with specified fault recovery.
        Verification: Analysis and qualification evidence: radiation dose/single-event effects, outgassing, lubrication and thermal-cycle compatibility.
        Acceptance is blocked until the corresponding contract TBD is resolved.
        */
    }
    requirement fte004 : FTE004_RadiationMaterials { subject system : FlipThermalEnvironmentContract; }

    verification def Verify_FLIPThermalEnvironmentRequirements {
        subject system : FlipThermalEnvironmentContract;
        verify fte001;
        verify fte002;
        verify fte003;
        verify fte004;
    }
}
