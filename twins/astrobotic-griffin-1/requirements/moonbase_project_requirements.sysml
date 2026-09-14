package MoonBaseProjectRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import ScalarValues::String;

    // Moon Base project baseline. Vehicle-specific SysML documents may add
    // product facts, but they inherit this unit/frame/evidence contract.
    part def ProjectSimulationContract {
        attribute unitSystem : String = "SI metric";
        attribute lengthUnit : String = "metres";
        attribute massUnit : String = "kilograms";
        attribute angleUnit : String = "radians";
        attribute timeUnit : String = "seconds";
        attribute frameUpAxis : String = "Y";
        attribute metersPerUnit : Real = 1.0;
        attribute moonbaseRequirementUsageCount : Integer = 4;
        attribute moonbaseRequirementIds : String = "mb001,mb002,mb003,mb004";
        attribute moonbaseVerificationCaseName : String = "MoonBaseProjectRequirements::Verify_MoonBaseProjectRequirements";
    }

    requirement def MB001_MetricSystem {
        doc /* MB-001 [project] all authored geometry and simulation parameters use SI metric units: metres, kilograms, radians, and seconds. */
    }

    requirement def MB002_YUpFrame {
        doc /* MB-002 [project] composed USD uses a Y-up frame with metersPerUnit = 1.0 and a documented root datum. */
    }

    requirement def MB003_DeterministicRhai {
        doc /* MB-003 [project] executable acceptance is authored in Twin Rhai and runs with fixed tick rate, thread count, jitter, and an explicit verdict channel. */
    }

    requirement def MB004_VisualEvidence {
        doc /* MB-004 [project] changed visual assemblies require fresh headful/offscreen evidence plus a composed USD query from the same source revision. */
    }

    requirement mb001 : MB001_MetricSystem { subject simulation : ProjectSimulationContract; }
    requirement mb002 : MB002_YUpFrame { subject simulation : ProjectSimulationContract; }
    requirement mb003 : MB003_DeterministicRhai { subject simulation : ProjectSimulationContract; }
    requirement mb004 : MB004_VisualEvidence { subject simulation : ProjectSimulationContract; }

    verification def Verify_MoonBaseProjectRequirements {
        subject simulation : ProjectSimulationContract;
        verify mb001;
        verify mb002;
        verify mb003;
        verify mb004;
    }
}
