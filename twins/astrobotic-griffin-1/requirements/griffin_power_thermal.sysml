package GriffinPowerThermalRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Boolean;
    private import Quantities::ScalarQuantityValue;
    private import MeasurementReferences::DerivedUnit;
    private import ISQ::*;
    private import SI;

    private import Quantities::QuantityPowerFactor;
    attribute def VoltageTemperatureSlopeUnit :> DerivedUnit {
        private attribute lengthPF : QuantityPowerFactor[1] { :>> quantity = ISQ::isq.L; :>> exponent = 2; }
        private attribute massPF : QuantityPowerFactor[1] { :>> quantity = ISQ::isq.M; :>> exponent = 1; }
        private attribute timePF : QuantityPowerFactor[1] { :>> quantity = ISQ::isq.T; :>> exponent = -3; }
        private attribute currentPF : QuantityPowerFactor[1] { :>> quantity = ISQ::isq.I; :>> exponent = -1; }
        private attribute temperaturePF : QuantityPowerFactor[1] { :>> quantity = ISQ::isq.'Θ'; :>> exponent = -1; }
        attribute :>> quantityDimension { :>> quantityPowerFactors = (lengthPF, massPF, timePF, currentPF, temperaturePF); }
    }
    attribute def CurrentTemperatureSlopeUnit :> DerivedUnit {
        private attribute currentPF : QuantityPowerFactor[1] { :>> quantity = ISQ::isq.I; :>> exponent = 1; }
        private attribute temperaturePF : QuantityPowerFactor[1] { :>> quantity = ISQ::isq.'Θ'; :>> exponent = -1; }
        attribute :>> quantityDimension { :>> quantityPowerFactors = (currentPF, temperaturePF); }
    }
    attribute voltsPerKelvin : VoltageTemperatureSlopeUnit = SI::V / SI::K;
    attribute amperesPerKelvin : CurrentTemperatureSlopeUnit = SI::A / SI::K;
    attribute wattsPerKelvin : ThermalConductanceUnit = SI::W / SI::K;
    attribute joulesPerKelvin : HeatCapacityUnit = SI::J / SI::K;
    attribute squareMetre : AreaUnit = SI::m^2;
    attribute ampereHour : ElectricChargeUnit = 3600.0 * SI::C;
    attribute wattsPerSquareMetre : IrradianceUnit = SI::W / SI::m^2;

    attribute def Azur3G30ACicStudyReference {
        doc /* Study reference, not an identified Griffin flight cell. AZUR
         * SPACE DB 00010893-01, 11-Apr-2025, p.2. BOL CIC, 100 micrometre AR
         * coverglass, AM0 1367 W/m2, 28 C. Linear temperature slopes apply over
         * 28--140 C. Absorptivity .91 selects the published upper bound.
         * https://www.azurspace.com/media/uploads/file_links/file/bdb_00010893-01-00_3g30-advanced_6x12_LrDRZvU.pdf
         * Accessed 2026-10-21. Geometry is reconstructed independently; cell
         * footprint and series/parallel wiring are not taken from this product.
         */
        attribute referenceEfficiency : Real = .288;
        attribute absorptivityUpperBound : Real = .91;
        attribute referenceTemperature : ThermodynamicTemperatureValue = 301.15[SI::K];
        attribute maximumTemperature : ThermodynamicTemperatureValue = 413.15[SI::K];
        attribute referenceIrradiance : IrradianceValue = 1367.0[wattsPerSquareMetre];
        attribute maximumPowerVoltage : ElectricPotentialDifferenceValue = 2.4[SI::V];
        attribute maximumPowerCurrent : ElectricCurrentValue = 1.170[SI::A];
        attribute voltageTemperatureSlope : ScalarQuantityValue = -0.0067[voltsPerKelvin];
        attribute currentTemperatureSlope : ScalarQuantityValue = 0.00057[amperesPerKelvin];
    }

    part def GriffinPowerThermalStudy {
        attribute photovoltaicMaterial : Azur3G30ACicStudyReference;
        doc /* Bounded solar/battery/cooling study. 28 V comes from the
         * historical Astrobotic guide p.28; capacity, resistance, load power,
         * initial SOC, heat capacity and cooler ratings below are explicit
         * project assumptions, not flight inventories or supplier ratings.
         * Each panel uses a 6000 J/K lumped thermal capacitance. The ideal
         * external coolant removes at most 200 W per panel, only above 301.15 K.
         * https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf
         */
        attribute busVoltage : ElectricPotentialDifferenceValue = 28.0[SI::V];
        attribute batteryChargeCapacity : ElectricChargeValue = 208.0[ampereHour];
        attribute batteryResistance : ResistanceValue = .02[SI::ohm];
        attribute initialStateOfCharge : Real = .8;
        attribute avionicsBaselinePower : PowerValue = 120.0[SI::W];
        attribute avionicsGuidancePower : PowerValue = 80.0[SI::W];
        attribute avionicsVoltageOff : ElectricPotentialDifferenceValue = 18.0[SI::V];
        attribute avionicsVoltageOn : ElectricPotentialDifferenceValue = 20.0[SI::V];
        attribute panelHeatCapacity : HeatCapacityValue = 6000.0[joulesPerKelvin];
        attribute panelInitialTemperature : ThermodynamicTemperatureValue = 301.15[SI::K];
        attribute maximumPanelCooling : PowerValue = 200.0[SI::W];
        attribute minimumCoolantTemperature : ThermodynamicTemperatureValue = 301.15[SI::K];
        attribute coolingConductance : ThermalConductanceValue = 40.0[wattsPerKelvin];
        attribute observationDuration : DurationValue = 45.0[SI::s];
        attribute powerResidualTolerance : PowerValue = .0001[SI::W];
        attribute temperatureLawTolerance : Real = .000001;
        attribute collectingAreaTolerance : AreaValue = .00001[squareMetre];
        attribute visibilitySampleOffset : LengthValue = .001[SI::m];
    }

    constraint def GEP001_ConversionClosed {
        in geometryAreaMatches : Boolean;
        in physicalSunDemand : Boolean;
        in temperatureLawMatches : Boolean;
        in radiantBalanceClosed : Boolean;
        in generatedPowerObserved : Boolean;
        geometryAreaMatches and physicalSunDemand and temperatureLawMatches
            and radiantBalanceClosed and generatedPowerObserved;
    }
    requirement def GEP001_SolarConversion {
        doc /* GEP-001: each of the three source-defined cell fields shall use
         * its active geometric area, physical irradiance, framed incidence and
         * terrain visibility. Available electrical power shall follow the
         * selected reference-cell temperature law. Absorbed power shall equal
         * delivered electrical power plus heat within the study tolerance.
         * This verifies the declared reference-cell study, not flight output.
         */
        require GEP001_ConversionClosed;
    }
    constraint def GEP002_CoolingClosed {
        in temperatureFeedbackWired : Boolean;
        in temperatureResponded : Boolean;
        in thermalNodeBalanceClosed : Boolean;
        in coolingWithinBounds : Boolean;
        in fullHorizonObserved : Boolean;
        temperatureFeedbackWired and temperatureResponded and thermalNodeBalanceClosed
            and coolingWithinBounds and fullHorizonObserved;
    }
    requirement def GEP002_PanelCooling {
        doc /* GEP-002: each panel's absorbed-minus-delivered heat shall enter
         * its thermal mass, whose temperature feeds electrical conversion.
         * Cooling shall be nonnegative, not exceed maximumPanelCooling, and
         * be zero at or below minimumCoolantTemperature. Observe temperature
         * evolution and thermal-node balance through observationDuration.
         */
        require GEP002_CoolingClosed;
    }
    constraint def GEP003_PowerSupplyClosed {
        in electricalNodeBalanceClosed : Boolean;
        in batteryEnergyBalanceClosed : Boolean;
        in loadPowerObserved : Boolean;
        in flightPowerGateWired : Boolean;
        electricalNodeBalanceClosed and batteryEnergyBalanceClosed
            and loadPowerObserved and flightPowerGateWired;
    }
    constraint def GEP004_LowSupplyCommandsOff {
        in poweredCommandsObserved : Boolean;
        in lowSupplyObserved : Boolean;
        in commandsSuppressed : Boolean;
        in loadDisconnected : Boolean;
        in actuatorsSettled : Boolean;
        poweredCommandsObserved and lowSupplyObserved and commandsSuppressed
            and loadDisconnected and actuatorsSettled;
    }
    requirement def GEP003_StorageAndControlSupply {
        doc /* GEP-003: the three arrays, finite battery and regulated avionics
         * load shall share one solved electrical node. Power and battery
         * storage/loss balance shall close. Flight command availability shall
         * be connected to the solved avionics powered signal.
         */
        require GEP003_PowerSupplyClosed;
    }
    requirement def GEP004_LowSupplyProtection {
        doc /* GEP-004: under a sustained command, loss of solved avionics
         * power shall suppress all thrust and attitude requests within three
         * completed fixed intervals. The unpowered computer shall draw zero
         * power. Engines shall settle through their own valve/chamber dynamics.
         * Qualify a powered interval followed by battery depletion under a
         * prescribed eclipse; reduced test inventory is not a flight rating.
         */
        require GEP004_LowSupplyCommandsOff;
    }
    requirement <'GEP-004'> gep004 : GEP004_LowSupplyProtection { subject power : GriffinPowerThermalStudy; }
    requirement <'GEP-001'> gep001 : GEP001_SolarConversion { subject power : GriffinPowerThermalStudy; }
    requirement <'GEP-002'> gep002 : GEP002_PanelCooling { subject power : GriffinPowerThermalStudy; }
    requirement <'GEP-003'> gep003 : GEP003_StorageAndControlSupply { subject power : GriffinPowerThermalStudy; }
    verification def Verify_GriffinPowerThermal {
        subject power : GriffinPowerThermalStudy;
        objective { verify gep001; verify gep002; verify gep003; }
    }
    verification def Verify_GriffinControlPowerLoss {
        doc /* Production vehicle under a prescribed eclipse with a reduced
         * test battery inventory. Sustained thrust/yaw requests must lose
         * authority when the solved avionics supply enters UVLO. */
        subject power : GriffinPowerThermalStudy;
        objective { verify gep004; }
    }
}
