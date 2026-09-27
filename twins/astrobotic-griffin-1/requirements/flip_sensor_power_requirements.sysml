// Legacy runtime visual-study contract; not the corrected FreeCAD v3 geometry.
// See flip_cad_requirements.sysml for current CAD behavior and dimensions.
// Runtime promotion remains OPEN; these builder-consumed values are unchanged.
package FlipSensorPowerRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::String;
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
        attribute sensorHeadWidthM : Real = 0.80;
        attribute sensorHeadHeightM : Real = 0.32;
        attribute sensorHeadDepthM : Real = 0.48;
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
        attribute solarArrayPeakPowerW : Real = 270.0;
        attribute visualOwnership : String = "mast and panel are render-only; rover sensor and electrical models own behavior";
    }

    requirement def FSP001_MastStructure {
        doc /* FSP-001 [visual] FLIP exposes an inspectable sensor mast with post, sensor head, and antenna. */
    }
    requirement def FSP002_SolarStructure {
        doc /* FSP-002 [visual] FLIP exposes a separately owned collapsible-array proxy with backsheet, cells, and fold hinge. */
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
        doc /* FSP-006 [geometry] the rover panel shall expose a 1.00 m by 0.70 m active cell face, matching the source-owned 0.70 m2 electrical collection area, on a fitted backsheet and fold hinge. */
    }
    requirement def FSP007_BatteryEnergyCapacity {
        doc /* FSP-007 [power] the FLIP electrical-storage model shall realize the published battery energy capacity held in this package's source attribute. */
    }
    requirement def FSP008_SolarArrayPeakPower {
        doc /* FSP-008 [power] model FLIP's 0.70 m2 solar array at 35% conversion efficiency and limit its electrical output to the source-owned 270 W nameplate rating. */
    }

    requirement <'FSP-001'> fsp001 : FSP001_MastStructure { subject sensorPower : FlipSensorPowerAssembly; }
    requirement <'FSP-002'> fsp002 : FSP002_SolarStructure { subject sensorPower : FlipSensorPowerAssembly; }
    requirement <'FSP-003'> fsp003 : FSP003_MastDatum { subject sensorPower : FlipSensorPowerAssembly; }
    requirement <'FSP-004'> fsp004 : FSP004_SensorPowerTraceability { subject sensorPower : FlipSensorPowerAssembly; }
    requirement <'FSP-005'> fsp005 : FSP005_MastGeometry { subject sensorPower : FlipSensorPowerAssembly; }
    requirement <'FSP-006'> fsp006 : FSP006_SolarPanelGeometry { subject sensorPower : FlipSensorPowerAssembly; }
    requirement <'FSP-007'> fsp007 : FSP007_BatteryEnergyCapacity { subject sensorPower : FlipSensorPowerAssembly; }
    requirement <'FSP-008'> fsp008 : FSP008_SolarArrayPeakPower { subject sensorPower : FlipSensorPowerAssembly; }

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
        }
    }
}
