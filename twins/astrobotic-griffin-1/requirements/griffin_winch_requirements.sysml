package GriffinWinchRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Boolean;
    private import ISQ::*;
    private import SI;
    private import GriffinPowerThermalRequirements::joulesPerKelvin;
    private import GriffinPowerThermalRequirements::squareMetre;

    part def WinchStudy {
        doc /* Reduced electrically powered dual drum and dissipative brake.
         * Every rating below is an explicit integration-study assumption,
         * not an identified Griffin flight actuator or qualified thermal path.
         * Rope/damper losses share one lumped actuator thermal node. */
        attribute maximumMotorPower : PowerValue = 3000.0[SI::W];
        attribute motorEfficiency : Real = .8;
        attribute enabledIdlePower : PowerValue = 15.0[SI::W];
        attribute voltageOff : ElectricPotentialDifferenceValue = 18.0[SI::V];
        attribute voltageOn : ElectricPotentialDifferenceValue = 20.0[SI::V];
        attribute heatCapacity : HeatCapacityValue = 10000.0[joulesPerKelvin];
        attribute initialTemperature : ThermodynamicTemperatureValue = 293.15[SI::K];
        attribute radiatorArea : AreaValue = .05[squareMetre];
        attribute radiatorEmissivity : Real = .8;
        attribute sinkTemperature : ThermodynamicTemperatureValue = 250.0[SI::K];
        attribute powerTolerance : PowerValue = .0001[SI::W];
        attribute rateToleranceMps : Real = .000001;
        attribute observationDuration : DurationValue = 8.0[SI::s];
        attribute testMotorPower : PowerValue = 1.0[SI::W];
        attribute testEpochJd : Real = 2461448.2197239352;
        attribute testBatteryCharge : ElectricChargeValue = 3.6[SI::C];
        attribute testInitialSoc : Real = .8;
        attribute testInitialLengthM : Real = 10.0;
        attribute testInitialSpanM : Real = 10.025;
        attribute testApproachSpeedMps : Real = .05;
        attribute testPayoutSpeedMps : Real = .12;
        attribute testPayoutDuration : DurationValue = .10[SI::s];
        attribute testPostLossSpanExtensionM : Real = .0125;
        attribute testStiffnessNPerM : Real = 4000.0;
        attribute testDampingNsPerM : Real = 300.0;
        attribute testPreloadN : Real = 50.0;
        attribute testTensionLimitN : Real = 2500.0;
        attribute testPayoutExtensionM : Real = .03;
    }
    constraint def GWPObservedAcceptance {
        in accepted : Boolean;
        accepted == true;
    }
    requirement def GWP001_ElectricalClosure {
        doc /* GWP-001: the winch shall draw its enabled idle and motoring
         * demand from the solved finite battery node; its power balance and
         * the battery storage/loss balance shall close. */
        require GWPObservedAcceptance;
    }
    requirement def GWP002_PowerBound {
        doc /* GWP-002: each drum's take-up shaft power shall remain bounded
         * by its authored rating under a sustained take-up request. */
        require GWPObservedAcceptance;
    }
    requirement def GWP003_ThermalClosure {
        doc /* GWP-003: converter, payout-brake and passive line losses shall
         * feed the solved thermal mass/radiator node with a closed heat balance. */
        require GWPObservedAcceptance;
    }
    requirement def GWP004_SupplyLossHold {
        doc /* GWP-004: after finite battery depletion enters sustained UVLO,
         * enabled drums shall hold length despite a nonzero request, draw no
         * electrical power, and retain passive rope load. The initially empty
         * negative fixture shall never admit powered drum motion. */
        require GWPObservedAcceptance;
    }
    requirement <'GWP-001'> gwp001 : GWP001_ElectricalClosure { subject winch : WinchStudy; }
    requirement <'GWP-002'> gwp002 : GWP002_PowerBound { subject winch : WinchStudy; }
    requirement <'GWP-003'> gwp003 : GWP003_ThermalClosure { subject winch : WinchStudy; }
    requirement <'GWP-004'> gwp004 : GWP004_SupplyLossHold { subject winch : WinchStudy; }
    verification def Verify_GriffinWinchPower {
        subject winch : WinchStudy;
        objective { verify gwp001; verify gwp002; verify gwp003; verify gwp004; }
    }
    verification def Verify_GriffinWinchUnpowered {
        subject winch : WinchStudy;
        objective { verify gwp004; }
    }
}
