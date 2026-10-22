// Legacy runtime visual-study contract; not the corrected FreeCAD v3 geometry.
// See flip_cad_requirements.sysml for current CAD behavior and dimensions.
// Runtime sensor and array geometry remain explicit study estimates.
package FlipSensorPowerRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::String;
    private import GriffinVisualConfigurationRequirements::Direction;
    private import GriffinRequirementSources::TwinAssetPath;
    private import GriffinRequirementSources::UsdPrimPath;

    enum def FlipSensorMastMember { MastPost; SensorHead; SensorAntenna; }
    enum def FlipSolarArrayVisualMember { WhiteBacksheet; BlueCells; FoldHinge; }

    part def FlipSensorPowerAssembly {
        attribute usdRootPath : UsdPrimPath = "/World/FLIP";
        attribute componentAsset : TwinAssetPath = "components/rover/flip_sensor_mast_visual.usda";
        attribute solarComponentAsset : TwinAssetPath = "components/rover/flip_solar_panel_visual.usda";
        ref part sourceRover : FlipRequirements::FlipRover;
        ref attribute batteryNominalVoltageV : FlipRequirements::FlipRover::batteryNominalVoltageV;
        attribute mastPath : UsdPrimPath = "/World/FLIP/SensorMast";
        attribute solarPath : UsdPrimPath = "/World/FLIP/SolarArray";
        attribute batteryPath : UsdPrimPath = "/World/FLIP/Battery";
        // Internal packaging allocation, not a released Astrolab pack drawing.
        // X is longitudinal, Y is up, Z is lateral in the rover frame.
        attribute batteryEnclosureMarginM : Real = 0.05;
        attribute batteryLengthM : Real = FlipRequirements::FlipRover::equipmentBoxDepthM - 2.0 * batteryEnclosureMarginM;
        attribute batteryHeightM : Real = 0.20;
        attribute batteryWidthM : Real = FlipRequirements::FlipRover::equipmentBoxWidthM - 2.0 * batteryEnclosureMarginM;
        attribute batteryCenterXM : Real = 0.0;
        attribute batteryCenterYM : Real = FlipRequirements::FlipRover::equipmentBoxCenterYM;
        attribute batteryCenterZM : Real = 0.0;
        ref attribute mastHeight : FlipRequirements::FlipRover::sensorMastHeightM;
        ref attribute solarMount : FlipRequirements::FlipRover::solarArrayMount;
        ref attribute solarTilt : FlipRequirements::FlipRover::solarArrayTiltDeg;
        ref attribute solarStatus : FlipRequirements::FlipRover::solarArrayMode;
        attribute mastMountCenterYM : Real = 0.46;
        attribute mastMountCenterZM : Real = -0.28;
        attribute mastChildNames : FlipSensorMastMember[3] = ("MastPost", "SensorHead", "SensorAntenna");
        attribute solarChildNames : FlipSolarArrayVisualMember[3] = ("WhiteBacksheet", "BlueCells", "FoldHinge");
        attribute mastPostRadiusM : Real = 0.07;
        attribute mastPostHeightM : Real = 0.70;
        attribute mastPostCenterYM : Real = 0.35;
        attribute mastPostCenterZM : Real = 0.0;
        // Full metre envelopes of the current size=1 study Cube. The former
        // values doubled its actual geometry by retaining size=2 semantics.
        // This is authored study geometry, not supplier metrology.
        attribute sensorHeadWidthM : Real = 0.40;
        attribute sensorHeadHeightM : Real = 0.16;
        attribute sensorHeadDepthM : Real = 0.24;
        attribute sensorHeadCenterYM : Real = 0.78;
        attribute sensorHeadCenterZM : Real = 0.0;
        attribute antennaRadiusM : Real = 0.025;
        attribute antennaHeightM : Real = 0.28;
        attribute antennaCenterYM : Real = 1.0;
        attribute antennaCenterZM : Real = 0.0;
        attribute solarBacksheetWidthM : Real = 1.08;
        attribute solarBacksheetThicknessM : Real = 0.04;
        attribute solarBacksheetDepthM : Real = 0.78;
        attribute solarCellWidthM : Real = 1.00;
        attribute solarCellThicknessM : Real = 0.015;
        attribute solarCellDepthM : Real = 0.70;
        attribute solarHingeWidthM : Real = 1.10;
        attribute solarHingeThicknessM : Real = 0.06;
        attribute solarHingeDepthM : Real = 0.06;
        attribute solarHingeCenterZM : Real = -0.40;
        attribute solarArrayEfficiency : Real = 0.35;
        // Astrolab publishes these nameplate ratings; the physical models
        // realize them through the generic LunCoSim storage/source parameters.
        attribute batteryEnergyKWh : Real = 6.22;
        // The public post says nearly 270 W. Use 270 W as the rounded model
        // ceiling, not as a supplier tolerance or guaranteed bus delivery.
        attribute solarArrayPeakPowerW : Real = 270.0;
        attribute solarReferenceTemperatureK : Real = 298.15;
        // Generic standard-silicon sensitivity from PVWatts, not a FLIP cell
        // measurement. Replace with the installed cell supplier's coefficient.
        attribute solarPowerTemperatureCoefficientPerK : Real = -0.0037;
        // Ideal opaque absorber until a measured optical surface is available.
        attribute solarAbsorptivity : Real = 1.0;
        attribute visualOwnership : String = "mast and panel are render-only; rover sensor and electrical models own behavior";
    }

    part def FlipSolarVerificationInputs {
        doc /* Synthetic illumination for the native electrical verification; these are test stimuli, not lunar-site or supplier measurements. The front and back directions are expressed in the installed panel's local frame. */
        attribute brightIrradianceWm2 : Real = 2000.0;
        attribute dimIrradianceWm2 : Real = 100.0;
        attribute visibleSunFraction : Real = 1.0;
        attribute occludedSunFraction : Real = 0.0;
        attribute frontDirection : Direction = (0.0, 0.0, 1.0);
        attribute backDirection : Direction = (0.0, 0.0, -1.0);
        attribute frontCosine : Real = 1.0;
        attribute backCosine : Real = 0.0;
        attribute observationDwellS : Real = 0.5;
        attribute observationTimeoutS : Real = 30.0;
        attribute temperatureProbeDeltaK : Real = 50.0;
        attribute counterexampleAreaOffsetM2 : Real = 0.01;
        attribute counterexampleEfficiencyOffset : Real = 0.01;
        attribute counterexamplePowerOffsetW : Real = 1.0;
    }

    requirement def FSP001_MastStructure {
        doc /* FSP-001 [visual] FLIP exposes an inspectable sensor mast with post, sensor head, and antenna. These presentation members explicitly disable collision; the rover body and physical wheel assemblies own collision behavior. */
    }
    requirement def FSP002_SolarStructure {
        doc /* FSP-002 [visual] FLIP exposes a separately owned collapsible-array proxy with backsheet, cells, and fold hinge. These presentation members explicitly disable collision; this proxy does not qualify a physical deployment mechanism. */
    }
    requirement def FSP003_MastDatum {
        doc /* FSP-003 [geometry] the mast height and mount are checked against the rover SysML metre datum. */
    }
    requirement def FSP004_SensorPowerTraceability {
        doc /* FSP-004 [evidence] mast/solar paths and deployment status resolve from this package and the rover source. */
    }
    requirement def FSP005_MastGeometry {
        doc /* FSP-005 [geometry] the mast post, sensor head, antenna, and deck mount shall match the package's source-owned dimensions and placements. */
    }
    requirement def FSP006_SolarPanelGeometry {
        doc /* FSP-006 [geometry] the rover panel shall expose an active cell face sized by solarCellWidthM and solarCellDepthM. Its collection area is derived from those typed dimensions and shall fit on the source-owned backsheet and fold hinge. */
    }
    constraint def FSPC007_BatteryNameplateEnergy {
        in capacityAh : Real;
        in nominalVoltageV : Real;
        in requiredEnergyKWh : Real;
        in requiredVoltageV : Real;
        in capacityToleranceAh : Real;
        in voltageToleranceV : Real;
        capacityAh > 0.0 and nominalVoltageV > 0.0
            and requiredEnergyKWh > 0.0 and requiredVoltageV > 0.0
            and capacityToleranceAh >= 0.0 and voltageToleranceV >= 0.0
            and capacityAh >= requiredEnergyKWh * 1000.0 / requiredVoltageV - capacityToleranceAh
            and capacityAh <= requiredEnergyKWh * 1000.0 / requiredVoltageV + capacityToleranceAh
            and nominalVoltageV >= requiredVoltageV - voltageToleranceV
            and nominalVoltageV <= requiredVoltageV + voltageToleranceV;
    }
    requirement def FSP007_BatteryEnergyCapacity {
        doc /* FSP-007 [power] the electrical-storage model's authored ampere-hour capacity shall equal the source nameplate energy converted from kWh to Wh and divided by the source nominal voltage, within batteryCapacityToleranceAh. Its nominal voltage shall match the source within batteryVoltageToleranceV. Verification reads both values from the same composed USD snapshot. */
        // Numerical configuration allowances retained from the existing gate.
        attribute batteryCapacityToleranceAh : Real = 0.02;
        attribute batteryVoltageToleranceV : Real = 0.002;
        require FSPC007_BatteryNameplateEnergy {
            in requiredEnergyKWh = FlipSensorPowerAssembly::batteryEnergyKWh;
            in requiredVoltageV = FlipRequirements::FlipRover::batteryNominalVoltageV;
            in capacityToleranceAh = batteryCapacityToleranceAh;
            in voltageToleranceV = batteryVoltageToleranceV;
        }
    }
    constraint def FSPC008_SolarConfiguration {
        in areaM2 : Real;
        in efficiency : Real;
        in peakPowerW : Real;
        in cellWidthM : Real;
        in cellDepthM : Real;
        in requiredEfficiency : Real;
        in requiredPeakPowerW : Real;
        in areaToleranceM2 : Real;
        in efficiencyTolerance : Real;
        in powerToleranceW : Real;
        areaM2 > 0.0 and cellWidthM > 0.0 and cellDepthM > 0.0
            and efficiency > 0.0 and efficiency <= 1.0
            and requiredEfficiency > 0.0 and requiredEfficiency <= 1.0
            and requiredPeakPowerW > 0.0
            and areaToleranceM2 >= 0.0 and efficiencyTolerance >= 0.0 and powerToleranceW >= 0.0
            and areaM2 >= cellWidthM * cellDepthM - areaToleranceM2
            and areaM2 <= cellWidthM * cellDepthM + areaToleranceM2
            and efficiency >= requiredEfficiency - efficiencyTolerance
            and efficiency <= requiredEfficiency + efficiencyTolerance
            and peakPowerW >= requiredPeakPowerW - powerToleranceW
            and peakPowerW <= requiredPeakPowerW + powerToleranceW;
    }
    constraint def FSPC008_SolarAvailablePower {
        in availablePowerW : Real;
        in deliveredPowerW : Real;
        in irradianceWm2 : Real;
        in sunVisibility : Real;
        in incidenceCosine : Real;
        in cellTemperatureK : Real;
        in temperatureFactor : Real;
        in referenceTemperatureK : Real;
        in powerTemperatureCoefficientPerK : Real;
        in solarAbsorptivity : Real;
        in temperatureFactorTolerance : Real;
        in cellWidthM : Real;
        in cellDepthM : Real;
        in requiredEfficiency : Real;
        in requiredPeakPowerW : Real;
        in powerToleranceW : Real;
        irradianceWm2 >= 0.0 and sunVisibility >= 0.0 and sunVisibility <= 1.0
            and incidenceCosine >= 0.0 and incidenceCosine <= 1.0
            and cellWidthM > 0.0 and cellDepthM > 0.0
            and requiredEfficiency > 0.0 and requiredEfficiency <= 1.0
            and requiredPeakPowerW > 0.0 and powerToleranceW >= 0.0
            and cellTemperatureK > 0.0 and referenceTemperatureK > 0.0
            and solarAbsorptivity >= requiredEfficiency and solarAbsorptivity <= 1.0
            and temperatureFactor >= 0.0 and temperatureFactorTolerance >= 0.0
            and temperatureFactor >= (if 1.0 + powerTemperatureCoefficientPerK * (cellTemperatureK-referenceTemperatureK) > 0.0
                ? 1.0 + powerTemperatureCoefficientPerK * (cellTemperatureK-referenceTemperatureK) else 0.0) - temperatureFactorTolerance
            and temperatureFactor <= (if 1.0 + powerTemperatureCoefficientPerK * (cellTemperatureK-referenceTemperatureK) > 0.0
                ? 1.0 + powerTemperatureCoefficientPerK * (cellTemperatureK-referenceTemperatureK) else 0.0) + temperatureFactorTolerance
            and availablePowerW >= (if cellWidthM * cellDepthM * (if requiredEfficiency * temperatureFactor < solarAbsorptivity ? requiredEfficiency * temperatureFactor else solarAbsorptivity) * irradianceWm2 * sunVisibility * incidenceCosine < requiredPeakPowerW * temperatureFactor
                ? cellWidthM * cellDepthM * (if requiredEfficiency * temperatureFactor < solarAbsorptivity ? requiredEfficiency * temperatureFactor else solarAbsorptivity) * irradianceWm2 * sunVisibility * incidenceCosine
                else requiredPeakPowerW * temperatureFactor) - powerToleranceW
            and availablePowerW <= (if cellWidthM * cellDepthM * (if requiredEfficiency * temperatureFactor < solarAbsorptivity ? requiredEfficiency * temperatureFactor else solarAbsorptivity) * irradianceWm2 * sunVisibility * incidenceCosine < requiredPeakPowerW * temperatureFactor
                ? cellWidthM * cellDepthM * (if requiredEfficiency * temperatureFactor < solarAbsorptivity ? requiredEfficiency * temperatureFactor else solarAbsorptivity) * irradianceWm2 * sunVisibility * incidenceCosine
                else requiredPeakPowerW * temperatureFactor) + powerToleranceW
            and deliveredPowerW >= -powerToleranceW
            and deliveredPowerW <= availablePowerW + powerToleranceW
            and deliveredPowerW <= requiredPeakPowerW * temperatureFactor + powerToleranceW
            and (availablePowerW <= powerToleranceW or deliveredPowerW > 0.0);
    }
    requirement def FSP008_SolarArrayPeakPower {
        doc /* FSP-008 [power] derive collection area from the typed cell dimensions and apply the source temperature coefficient relative to solarReferenceTemperatureK. Both conversion efficiency and the rounded reference-temperature nameplate shall change with cell temperature; conversion cannot exceed absorbed radiant power. Delivered power shall be nonnegative and shall not exceed available power. The native gate shall exercise reference-temperature bright/dim/occluded/back-facing probes and hot/cold bright probes. The cell temperature may be prescribed or connected to a thermal network; absorbed radiation minus electrical delivery is the heat input for that network. A cooling sink has finite heat-rejection capacity and cannot remove heat below its minimum sink temperature. The generic coefficient and ideal absorptivity are explicit study assumptions, not FLIP supplier properties. Sources: Astrolab nameplate post, PVWatts standard-module temperature coefficient and the user's 2026-10-20 electrothermal requirement. */
        // Configuration/numeric allowances retained from the existing gate;
        // they do not express the precision of the public nameplate claim.
        attribute areaToleranceM2 : Real = 0.002;
        attribute efficiencyTolerance : Real = 0.002;
        attribute powerToleranceW : Real = 0.01;
        attribute temperatureFactorTolerance : Real = 1.0e-9;
        require FSPC008_SolarConfiguration {
            in cellWidthM = FlipSensorPowerAssembly::solarCellWidthM;
            in cellDepthM = FlipSensorPowerAssembly::solarCellDepthM;
            in requiredEfficiency = FlipSensorPowerAssembly::solarArrayEfficiency;
            in requiredPeakPowerW = FlipSensorPowerAssembly::solarArrayPeakPowerW;
            in areaToleranceM2 = FlipSensorPowerRequirements::FSP008_SolarArrayPeakPower::areaToleranceM2;
            in efficiencyTolerance = FlipSensorPowerRequirements::FSP008_SolarArrayPeakPower::efficiencyTolerance;
            in powerToleranceW = FlipSensorPowerRequirements::FSP008_SolarArrayPeakPower::powerToleranceW;
        }
        require FSPC008_SolarAvailablePower {
            in referenceTemperatureK = FlipSensorPowerAssembly::solarReferenceTemperatureK;
            in powerTemperatureCoefficientPerK = FlipSensorPowerAssembly::solarPowerTemperatureCoefficientPerK;
            in solarAbsorptivity = FlipSensorPowerAssembly::solarAbsorptivity;
            in temperatureFactorTolerance = FlipSensorPowerRequirements::FSP008_SolarArrayPeakPower::temperatureFactorTolerance;
            in cellWidthM = FlipSensorPowerAssembly::solarCellWidthM;
            in cellDepthM = FlipSensorPowerAssembly::solarCellDepthM;
            in requiredEfficiency = FlipSensorPowerAssembly::solarArrayEfficiency;
            in requiredPeakPowerW = FlipSensorPowerAssembly::solarArrayPeakPowerW;
            in powerToleranceW = FlipSensorPowerRequirements::FSP008_SolarArrayPeakPower::powerToleranceW;
        }
    }

    constraint def FSPC009_BatteryAllocation {
        in packLengthM : Real;
        in packHeightM : Real;
        in packWidthM : Real;
        in enclosureLengthM : Real;
        in enclosureHeightM : Real;
        in enclosureWidthM : Real;
        in marginM : Real;
        packLengthM > 0.0 and packHeightM > 0.0 and packWidthM > 0.0
            and marginM > 0.0
            and packLengthM + 2.0 * marginM <= enclosureLengthM
            and packWidthM + 2.0 * marginM <= enclosureWidthM
            and packHeightM + 2.0 * marginM <= enclosureHeightM;
    }
    requirement def FSP009_BatteryPackaging {
        doc /* FSP-009 [geometry] the visible battery case and its collision shape shall share the source-owned internal packaging allocation inside the equipment enclosure. The unit Cube shall use the declared SI dimensions and center through an explicit translate/scale transform order. This allocation preserves the electrical nameplate and existing study mass; it does not establish cell layout, supplier dimensions, or qualified mass properties. */
        // Serialization/projection agreement, not manufacturing accuracy.
        attribute geometryProjectionToleranceM : Real = 1.0e-9;
        require FSPC009_BatteryAllocation {
            in packLengthM = FlipSensorPowerAssembly::batteryLengthM;
            in packHeightM = FlipSensorPowerAssembly::batteryHeightM;
            in packWidthM = FlipSensorPowerAssembly::batteryWidthM;
            in enclosureLengthM = FlipRequirements::FlipRover::equipmentBoxDepthM;
            in enclosureHeightM = FlipRequirements::FlipRover::equipmentBoxHeightM;
            in enclosureWidthM = FlipRequirements::FlipRover::equipmentBoxWidthM;
            in marginM = FlipSensorPowerAssembly::batteryEnclosureMarginM;
        }
    }

    requirement <'FSP-001'> fsp001 : FSP001_MastStructure { subject sensorPower : FlipSensorPowerAssembly; }
    requirement <'FSP-002'> fsp002 : FSP002_SolarStructure { subject sensorPower : FlipSensorPowerAssembly; }
    requirement <'FSP-003'> fsp003 : FSP003_MastDatum { subject sensorPower : FlipSensorPowerAssembly; }
    requirement <'FSP-004'> fsp004 : FSP004_SensorPowerTraceability { subject sensorPower : FlipSensorPowerAssembly; }
    requirement <'FSP-005'> fsp005 : FSP005_MastGeometry { subject sensorPower : FlipSensorPowerAssembly; }
    requirement <'FSP-006'> fsp006 : FSP006_SolarPanelGeometry { subject sensorPower : FlipSensorPowerAssembly; }
    requirement <'FSP-007'> fsp007 : FSP007_BatteryEnergyCapacity { subject sensorPower : FlipSensorPowerAssembly; }
    requirement <'FSP-008'> fsp008 : FSP008_SolarArrayPeakPower { subject sensorPower : FlipSensorPowerAssembly; }
    requirement <'FSP-009'> fsp009 : FSP009_BatteryPackaging { subject sensorPower : FlipSensorPowerAssembly; }

    verification def Verify_FLIPSensorPowerRequirements {
        subject sensorPower : FlipSensorPowerAssembly;
        objective {
            verify fsp001;
            verify fsp002;
            verify fsp003;
            verify fsp004;
            verify fsp005;
            verify fsp006;
            verify fsp007;
            verify fsp008;
            verify fsp009;
        }
    }
}
