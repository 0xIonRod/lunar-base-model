// Legacy runtime visual-study contract; not the corrected FreeCAD v3 geometry.
// See flip_cad_requirements.sysml for current CAD behavior and dimensions.
// Runtime promotion remains OPEN; these builder-consumed values are unchanged.
package FlipSensorPowerRequirements {
    private import ScalarValues::String;

    part def FlipSensorPowerAssembly {
        attribute usdRootPath : String = "/World/FLIP";
        attribute sourceComponent : String = "FlipRequirements::FlipRover";
        attribute mastPath : String = "/World/FLIP/SensorMast";
        attribute solarPath : String = "/World/FLIP/SolarArray";
        attribute mastHeightSource : String = "FlipRequirements::FlipRover::sensorMastHeightM";
        attribute solarMountSource : String = "FlipRequirements::FlipRover::solarArrayMount";
        attribute solarTiltSource : String = "FlipRequirements::FlipRover::solarArrayTiltDeg";
        attribute solarStatusSource : String = "FlipRequirements::FlipRover::solarArrayMode";
        attribute mastChildNames : String = "MastPost,SensorHead,SensorAntenna";
        attribute solarChildNames : String = "WhiteBacksheet,BlueCells,FoldHinge";
    }

    requirement def FSP001_MastStructure {
        doc /* FSP-001 [visual] FLIP exposes an inspectable sensor mast with post, sensor head, and antenna. */
    }
    requirement def FSP002_SolarStructure {
        doc /* FSP-002 [visual] FLIP exposes a separately owned collapsible-array proxy with backsheet, cells, and fold hinge. */
    }
    requirement def FSP003_MastDatum {
        doc /* FSP-003 [geometry] mast height is checked against the rover SysML metre datum. */
    }
    requirement def FSP004_SensorPowerTraceability {
        doc /* FSP-004 [evidence] mast/solar paths and deployment status resolve from this package and the rover source. */
    }

    requirement fsp001 : FSP001_MastStructure { subject sensorPower : FlipSensorPowerAssembly; }
    requirement fsp002 : FSP002_SolarStructure { subject sensorPower : FlipSensorPowerAssembly; }
    requirement fsp003 : FSP003_MastDatum { subject sensorPower : FlipSensorPowerAssembly; }
    requirement fsp004 : FSP004_SensorPowerTraceability { subject sensorPower : FlipSensorPowerAssembly; }

    verification def Verify_FLIPSensorPowerRequirements {
        subject sensorPower : FlipSensorPowerAssembly;
        verify fsp001;
        verify fsp002;
        verify fsp003;
        verify fsp004;
    }
}
