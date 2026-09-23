# Griffin verification index

This file is an index only. Requirement text, limits, assumptions, and required
constraint memberships are owned by the SysML files below. Executable
verification bindings live in `twin.toml`; component observers and fixtures
are listed in `README.md`.

## System requirement domains

| Domain | SysML source | Verification case |
|---|---|---|
| Functional and mission interfaces | `requirements/griffin_functional_requirements.sysml` | `GriffinFunctionalRequirements::Verify_GriffinAdapterRelease`; integrated coverage in `Griffin1Requirements::Verify_GriffinRequirements` |
| Visual presentation | `requirements/griffin_visual_requirements.sysml` | `GriffinVisualRequirements::Verify_GriffinVisualRequirements` |
| Mechanical interfaces | `requirements/griffin_mechanical_requirements.sysml` | Integrated coverage in `Griffin1Requirements::Verify_GriffinRequirements` |
| Simulation accuracy | `requirements/griffin_simulation_accuracy_requirements.sysml` | `GriffinSimulationAccuracyRequirements::Verify_GriffinLandingStability`; integrated coverage in `Griffin1Requirements::Verify_GriffinRequirements` |
| Assurance and evidence | `requirements/griffin_assurance_requirements.sysml` | Integrated coverage in `Griffin1Requirements::Verify_GriffinRequirements` |

The top-level integration case contains `verify` memberships for all 36 `GR`
usages; that is traceability intent, not proof that every requirement has a
current runtime result. The visual case contains `verify` memberships for
seven `GRV` usages. Domain packages own their requirement definitions and
usage identities; the integration package owns the system subjects and
aggregate verification.

## Independent component contracts

Bus, landing-leg, propulsion, tank, solar-array, ramp, and FLIP component
requirements remain separate source packages with their own mapped Editor
fixtures and read-only observers. See the component rows in
[`README.md`](../README.md) and the `[verification]` registry in
[`twin.toml`](../twin.toml).

## Verdict boundary

The shared `sysml_requirements` evaluator checks composed USD observations and
executes supported SysML constraints through the neutral Rust IR. A constraint
check must resolve to a `require` membership of its named requirement before
the provider values are evaluated. Source-projection diagnostics use a
separate preflight report and are not counted as requirement evidence.

This index does not claim that a structural pass qualifies landing dynamics,
ramp deployment, or FLIP egress. Those claims require their own current
verification case and runtime evidence.
