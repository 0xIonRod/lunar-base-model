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
