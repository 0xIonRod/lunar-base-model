# FLIP engineering requirements: step-by-step implementation

Updated: 2026-09-25.

The immediate work is now the [visual-model build](../contracts/flip_visual_build.md)
under flip_visual_build_requirements.sysml. Follow that component sequence first.
The engineering sequence below remains later work and does not gate a labelled
visual study on unavailable flight-performance data.

The new packages follow the existing package, part, requirement definition,
subject and verification declaration structure. All new requirements are
proposed engineering contracts. All new verification definitions are PLANNED:
they have no Rhai observer or runtime fixture yet and cannot claim PASS.
The existing twin.toml SysML search path includes this requirements directory.

## Ordered work

| Step | Owning source | Exit evidence |
|---|---|---|
| 1 | [Baseline](flip_baseline_requirements.sysml) | Reconciled CAD/USD configuration, coordinate datums and mass roll-up |
| 2 | [Mission](flip_mission_requirements.sysml) | Defined timeline, selected egress branch and safe-state criteria |
| 3 | [Mobility](flip_mobility_requirements.sysml) | Steering agreement, resolved torque/speed bindings and terrain tests |
| 4 | [Power](flip_power_requirements.sysml) | Energy budget, protection tests and solar generation model |
| 5 | [Solar deployment](flip_solar_deployment_requirements.sysml) | Physical joint, clearance sweep and deployment fault tests |
| 6 | [Thermal/environment](flip_thermal_environment_requirements.sysml) | Thermal/night-survival analysis, dust and radiation evidence |
| 7 | [Avionics](flip_avionics_requirements.sysml) | Link/navigation performance, fault recovery and telemetry tests |
| 8 | [Interfaces](flip_interfaces_requirements.sysml) | Lander/payload ICDs, structural load cases and acceptance evidence |

## Repeat for each step

1. Resolve the named TBD fields from supplier ICDs, test data or documented
   study decisions. Record owner, units, source revision and uncertainty.
2. Add numeric limits to the owning SysML part with explicit units, following
   existing metre/degree conventions. Builders and tests read this source.
3. Implement one component/interface at a time. Use the
   [typed Editor procedure](../contracts/authoring.md) for USD geometry;
   inspect composed bounds, joints, ports and collision ownership.
4. Add a scoped observer under scenarios/tests and a matching Editor-authored
   fixture under tests. Exercise boundary and failure cases. Unresolved limits,
   missing ports or missing evidence must not produce a passing verdict.
5. Register the qualified verification, fixture, observer and verdict channel
   in twin.toml only when they exist. Mark the check Active in the catalog
   when executable; Active does not mean passed.
6. Run the component gate followed by affected assembly gates. Record source
   revision, document generation, configuration, fixed-clock horizon, inputs,
   thresholds, measurements and evidence paths.
7. Attach hardware analyses/test reports where required. Visual and simulation
   results cannot alone close flight qualification.
8. Close findings before progressing to dependent steps. Run the complete
   reference mission after the component/interface sequence passes.

## Baseline discrepancies

- CAD chassis dimensions are 1.8 m wide and 2.4 m long; existing rover SysML
  uses 4.40 m and 2.76 m. Select a configuration and compare matching axes and
  parts before changing either. Neither is established flight geometry.
- The Markdown 2.4 x 1.8 x 0.7 m envelope is used as chassis size in CAD.
  Wheels, mast and solar panel extend outside it. Measure separate overall
  stowed/deployed bounds.
- Visual requirements use front/rear steering; dynamic USD describes front
  Ackermann steering and straight rear wheels. Resolve the intended behavior.
- CAD has a placement-driven solar controller; runtime needs physical body,
  joint, mass, actuation and sensing evidence.
- The previous inventory used rg --files, which excludes ignored files.
  Locate generated/ignored FCStd artifacts explicitly before asserting absence.
- Wheel-binding failures in Markdown date to 2026-09-01. Reproduce against
  current runtime before claiming they still occur.
- The existing Python authored-spec validator expects a different steering
  configuration. Record its failures; reconcile its target rather than
  weakening checks merely to get a pass.

## Sources and applicability

These sources were consulted in the preceding gap review. They motivate
engineering obligations but do not supply the unresolved numeric limits.

- [Astrolab FLIP](https://www.astrolab.space/flip-rover/): wheel technology,
  battery enclosure and lunar-night survival intent (FMB, FEP, FTE).
- [Astrolab Griffin-1 announcement](https://www.astrolab.space/2025/02/05/astrolabs-flip-rover-joins-astrobotics-griffin-1-to-the-moon/):
  approximate mass and payload capacity. FIF-002 uses the existing
  FlipRequirements::FlipRover::flipPayloadCapacityKg allocation.
- [NASA lunar surface technology](https://www.nasa.gov/lunar-surface-technology/):
  thermal, autonomous-system and environmental context (FTE, FAV).
- [NASA dust mitigation guide](https://ntrs.nasa.gov/citations/20220018746):
  dust design/test context (FTE-003).
- [NASA lunar communications](https://www.nasa.gov/goddard/esc/lcrns/):
  communications/navigation context (FAV); relay availability is not assumed.

NASA human-system standards and FLEX-family limits are not automatically
mandatory for FLIP. Select applicable standards in the qualification plan.
Global lunar temperature extremes are not adopted as mission limits.

## Current status

Eight packages and 30 requirements have been added, including planned
verification declarations. Existing visual checks retain their scope.
Engineering limits, new runtime tests, hardware changes and qualification
evidence remain open in the corresponding packages.
