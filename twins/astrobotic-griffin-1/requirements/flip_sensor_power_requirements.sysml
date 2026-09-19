package FlipSensorPowerRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::String;

    part def FlipSensorPowerAssembly {
        attribute usdRootPath : String = "/World/FLIP";
        attribute componentAsset : String = "components/rover/flip_sensor_mast_visual.usda";
        attribute solarComponentAsset : String = "components/rover/flip_solar_panel_visual.usda";
        attribute sourceComponent : String = "FlipRequirements::FlipRover";
        attribute mastPath : String = "/World/FLIP/SensorMast";
        attribute solarPath : String = "/World/FLIP/SolarArray";
        attribute mastHeightSource : String = "FlipRequirements::FlipRover::sensorMastHeightM";
        attribute solarMountSource : String = "FlipRequirements::FlipRover::solarArrayMount";
        attribute solarTiltSource : String = "FlipRequirements::FlipRover::solarArrayTiltDeg";
        attribute solarStatusSource : String = "FlipRequirements::FlipRover::solarArrayMode";
        attribute mastMountCenterYM : Real = 0.46;
        attribute mastMountCenterZM : Real = -0.28;
        attribute mastChildNames : String[3] = ("MastPost", "SensorHead", "SensorAntenna");
        attribute solarChildNames : String[3] = ("WhiteBacksheet", "BlueCells", "FoldHinge");
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
        attribute solarBacksheetWidthM : Real = 3.30;
        attribute solarBacksheetThicknessM : Real = 0.12;
        attribute solarBacksheetDepthM : Real = 2.10;
        attribute solarCellWidthM : Real = 2.84;
        attribute solarCellThicknessM : Real = 0.04;
        attribute solarCellDepthM : Real = 1.64;
        attribute solarHingeWidthM : Real = 3.40;
        attribute solarHingeThicknessM : Real = 0.16;
        attribute solarHingeDepthM : Real = 0.16;
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
        doc /* FSP-005 [geometry] the mast is authored in a local deck-mounted frame: the 0.07 m radius by 0.70 m Y-axis post is centered at (0.0, 0.35, 0.0) m, the sensor head at (0.0, 0.78, 0.0) m, and the antenna at (0.0, 1.0, 0.0) m. The assembly mount translates this replaceable visual component to (0.0, 0.46, -0.28) m on the rover deck, keeping local geometry independent of the vehicle envelope. */
    }
    requirement def FSP006_SolarPanelGeometry {
        doc /* FSP-006 [geometry] the rover panel shall expose a 3.30 m by 0.12 m by 2.10 m backsheet, a 2.84 m by 0.04 m by 1.64 m cell surface, and a 3.40 m by 0.16 m by 0.16 m fold hinge. */
    }

    requirement fsp001 : FSP001_MastStructure { subject sensorPower : FlipSensorPowerAssembly; }
    requirement fsp002 : FSP002_SolarStructure { subject sensorPower : FlipSensorPowerAssembly; }
    requirement fsp003 : FSP003_MastDatum { subject sensorPower : FlipSensorPowerAssembly; }
    requirement fsp004 : FSP004_SensorPowerTraceability { subject sensorPower : FlipSensorPowerAssembly; }
    requirement fsp005 : FSP005_MastGeometry { subject sensorPower : FlipSensorPowerAssembly; }
    requirement fsp006 : FSP006_SolarPanelGeometry { subject sensorPower : FlipSensorPowerAssembly; }

    verification def Verify_FLIPSensorPowerRequirements {
        subject sensorPower : FlipSensorPowerAssembly;
        verify fsp001;
        verify fsp002;
        verify fsp003;
        verify fsp004;
        verify fsp005;
        verify fsp006;
    }
}
