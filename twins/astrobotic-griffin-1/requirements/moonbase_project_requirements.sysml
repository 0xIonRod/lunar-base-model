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
    }

    requirement def MB001_MetricSystem {
        doc /* MB-001 [project] authored Twin geometry and simulation parameters use SI metric units: metres, kilograms, radians, and seconds. Source-exchange artifacts may retain their explicitly declared native units; every value bound into the Twin model shall be converted to SI at its typed integration source. */
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

    requirement <'MB-001'> mb001 : MB001_MetricSystem { subject simulation : ProjectSimulationContract; }
    requirement <'MB-002'> mb002 : MB002_YUpFrame { subject simulation : ProjectSimulationContract; }
    requirement <'MB-003'> mb003 : MB003_DeterministicRhai { subject simulation : ProjectSimulationContract; }
    requirement <'MB-004'> mb004 : MB004_VisualEvidence { subject simulation : ProjectSimulationContract; }
}
