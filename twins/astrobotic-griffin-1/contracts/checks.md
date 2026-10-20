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

The top-level integration case contains `verify` memberships for all 37 `GR`
usages; that is traceability intent, not proof that every requirement has a
current runtime result. The visual case contains `verify` memberships for
seven `GRV` usages. Domain packages own their requirement definitions and
usage identities; the integration package owns the system subjects and
aggregate verification.

## Independent component contracts

The unallocated GBC-002 envelope statement is retired. GBC-005 already
measures the composed perimeter-frame envelope against its typed dimensions;
GBC-006 measures the deck and GBC-010 checks its separation from the skirt.
These distinguish the core frame from the whole lander envelope. Their metric
criteria and production checks remain intact. Other requirement IDs stay stable.

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

The CAD FR-016 baseline is the preserved `freecad/flip_v3/audited_source.FCStd`
from revision `86917ca`; the SysML statement now records its artifact hash.
`compare_published.py` measures component and pose counts from the native
comparison instead of printing assumed counts. External CAD evidence remains
separate from the runnable Twin suite.
