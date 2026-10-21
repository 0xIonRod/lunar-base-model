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
    attribute def KelvinPerSecondUnit :> DerivedUnit {
        private attribute timePF : QuantityPowerFactor[1] { :>> quantity = ISQ::isq.T; :>> exponent = -1; }
        private attribute temperaturePF : QuantityPowerFactor[1] { :>> quantity = ISQ::isq.'Θ'; :>> exponent = 1; }
        attribute :>> quantityDimension { :>> quantityPowerFactors = (timePF, temperaturePF); }
    }
    attribute def StefanBoltzmannUnit :> DerivedUnit {
        private attribute massPF : QuantityPowerFactor[1] { :>> quantity = ISQ::isq.M; :>> exponent = 1; }
        private attribute timePF : QuantityPowerFactor[1] { :>> quantity = ISQ::isq.T; :>> exponent = -3; }
        private attribute temperaturePF : QuantityPowerFactor[1] { :>> quantity = ISQ::isq.'Θ'; :>> exponent = -4; }
        attribute :>> quantityDimension { :>> quantityPowerFactors = (massPF, timePF, temperaturePF); }
    }
    attribute wattsPerSquareMetreKelvinFourth : StefanBoltzmannUnit = SI::W / (SI::m^2 * SI::K^4);
    attribute kelvinPerSecond : KelvinPerSecondUnit = SI::K / SI::s;
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

    attribute def ImageSolarCellThermalStudyReference {
        doc /* Infrared emissivity surrogate only. NASA IMAGE Failure Review
         * Board Final Presentation, 21 April 2006, p.99 reports solar-cell
         * alpha/epsilon .89/.87 for its dual-junction array. This is not an
         * identification or measurement of Griffin or AZUR 3G30A coverglass.
         * The reduced study treats .87 as diffuse grey-body emissivity.
         * https://image.gsfc.nasa.gov/publication/document/IMAGE_FRB_Presentation_4-21-06.pdf
         */
        attribute infraredEmissivity : Real = .87;
    }
    part def GriffinPowerThermalStudy {
        attribute photovoltaicMaterial : Azur3G30ACicStudyReference;
        attribute radiativeMaterial : ImageSolarCellThermalStudyReference;
        // Level outward faces use equal sky/ground hemispheres. Only the
        // active cell-face area emits in this conservative reduced geometry;
        // frame and rear-face emission and mutual vehicle view factors are
        // excluded. The 3 K sky and 250 K ground are prescribed study baths,
        // not a measured Nobile thermal field or dynamic terrain solution.
        // NIST CODATA value rounded to the displayed ten significant digits.
        attribute stefanBoltzmannConstant : ScalarQuantityValue = 5.670374419e-8[wattsPerSquareMetreKelvinFourth];
        attribute skyViewFactor : Real = .5;
        attribute groundViewFactor : Real = .5;
        attribute skyRadiationTemperature : ThermodynamicTemperatureValue = 3.0[SI::K];
        attribute groundRadiationTemperature : ThermodynamicTemperatureValue = 250.0[SI::K];
        attribute sustainedObservationDuration : DurationValue = 3600.0[SI::s];
        attribute maximumSettledTemperatureRate : ScalarQuantityValue = .001[kelvinPerSecond];
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
    constraint def GEP005_SustainedHeatRejection {
        in radiationTopologyClosed : Boolean;
        in emittingAreaMatches : Boolean;
        in radiativeLawMatches : Boolean;
        in thermalBalanceClosed : Boolean;
        in referenceRangeMaintained : Boolean;
        in settledAtHorizon : Boolean;
        in fullHorizonObserved : Boolean;
        radiationTopologyClosed and emittingAreaMatches and radiativeLawMatches
            and thermalBalanceClosed and referenceRangeMaintained
            and settledAtHorizon and fullHorizonObserved;
    }
    requirement def GEP005_RadiativeThermalStudy {
        doc /* GEP-005: each collecting face shall exchange infrared heat with
         * both prescribed sky and ground boundaries using its source-selected
         * emissivity, geometric area and view factors. Thermal balance shall
         * close with solar heat and bounded coolant rejection. Over one hour
         * under the observed held Sun boundary, each panel shall remain in the
         * selected photovoltaic coefficient range and settle within the study
         * temperature-rate bound. This is a reduced external-boundary study,
         * not flight calibration or a one-hour mission trajectory.
         */
        require GEP005_SustainedHeatRejection;
    }
    requirement <'GEP-005'> gep005 : GEP005_RadiativeThermalStudy { subject power : GriffinPowerThermalStudy; }
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
    verification def Verify_GriffinSustainedThermal {
        subject power : GriffinPowerThermalStudy;
        objective { verify gep005; }
    }
}
