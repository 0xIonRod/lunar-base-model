# Component ownership

The visual component assets in this directory are kept separate from the
vehicle wrappers and mission scenes. Their normative requirements and Rhai
observers live under the Twin's `requirements/` and `scenarios/tests/`
directories, respectively; `twin.toml` `[[components]]` is the typed ownership
index that binds the three artifacts.

| Component family | SysML source | Rhai verification | Fixture |
|---|---|---|---|
| Griffin lander | `requirements/griffin_lander_requirements.sysml` | `scenarios/tests/griffin_lander_requirements.rhai` | `tests/griffin_lander_requirements.usda` |
| Griffin bus | `requirements/griffin_bus_requirements.sysml` | `scenarios/tests/griffin_bus_requirements.rhai` | `tests/griffin_bus_requirements.usda` |
| Griffin landing legs | `requirements/griffin_landing_legs_requirements.sysml` | `scenarios/tests/griffin_landing_legs_requirements.rhai` | `tests/griffin_landing_legs_requirements.usda` |
| Griffin propulsion | `requirements/griffin_propulsion_requirements.sysml` | `scenarios/tests/griffin_propulsion_requirements.rhai` | `tests/griffin_propulsion_requirements.usda` |
| Griffin tanks | `requirements/griffin_tank_requirements.sysml` | `scenarios/tests/griffin_tank_requirements.rhai` | `tests/griffin_tank_requirements.usda` |
| Griffin solar arrays | `requirements/griffin_solar_requirements.sysml` | `scenarios/tests/griffin_solar_requirements.rhai` | `tests/griffin_solar_requirements.usda` |
| Griffin egress ramps | `requirements/griffin_ramp_requirements.sysml` | `scenarios/tests/griffin_ramp_requirements.rhai` | `tests/griffin_ramp_requirements.usda` |
| FLIP rover | `requirements/flip_requirements.sysml` | `scenarios/tests/flip_requirements.rhai` | `tests/flip_requirements.usda` |
| FLIP chassis | `requirements/flip_chassis_requirements.sysml` | `scenarios/tests/flip_chassis_requirements.rhai` | `tests/flip_chassis_requirements.usda` |
| FLIP directional wheels | `requirements/flip_wheel_requirements.sysml` | `scenarios/tests/flip_wheel_requirements.rhai` | `tests/flip_wheel_requirements.usda` |
| FLIP sensor/power | `requirements/flip_sensor_power_requirements.sysml` | `scenarios/tests/flip_sensor_power_requirements.rhai` | `tests/flip_sensor_power_requirements.usda` |

Do not edit USD text directly. Build or adjust an assembly through the typed
LunCoSim Editor/runtime tools, then run the component's Rhai observer against
the resulting composed stage. The generic Twin registry rejects a missing,
shared, or mismatched requirement/test binding before simulation starts.

## Single-source component contract

The component SysML file is the source of truth for both identity and metric
placement.  Counts and names are declared once, while station datums (for
example `legStationX/Y/Z`, `engineStationX/Y/Z`, and FLIP's four
`wheelStationX/Y/Z` lists) are qualified attributes in that same package.  The
visual builder reads those attributes through `griffin_spec` and emits typed
Editor placement operations; it does not carry a second table of coordinates.

The matching Rhai observer verifies the same datums against the composed
`xformOp:translate` values, in addition to checking the component's children,
dimensions, and behavior.  A missing or cardinality-mismatched station list
is a failed source check, not a default.  This makes a component fixture
independently reviewable and prevents a combined lander/rover scene from
masking a misplaced subassembly.

For a fast focused gate, run the fixture and its qualified verification from
the `[[verification.cases]]` entry in `twin.toml`; all component gates use the
same deterministic invocation (`--max-ticks 120 --tick-hz 60 --threads 1
--jitter 0`).
