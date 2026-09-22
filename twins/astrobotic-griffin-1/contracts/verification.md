# Griffin verification boundary

The normative component identities, dimensions, requirements, verification
coverage, constraints, and provenance live in `requirements/*.sysml`. The USD
sources realize the design. Rhai may select and measure composed USD or live
telemetry, but requirement predicates belong in SysML constraints.

## Current executable slice

- `GriffinBusRequirements` defines executable predicates for deck/skirt
  separation, tank bore clearance, and observed scalar cardinality. The shared
  `component_requirements::constraint_assertion` adapter binds observations to
  the generic `sysml_evaluate_constraint` four-state evaluator and attaches
  requirement/verification identity through the generic report path.
- The bus observer still measures mesh topology, extent, face winding, color,
  and absent legacy prims in Rhai. Those verdicts are provisional until the
  generic evaluator can bind composed USD arrays and shape relations directly.
- `griffin_requirements.rhai` and the older scene observers still contain
  component-specific Rhai predicates for placement, part manifests, and
  mission interfaces. They cannot be treated as completed SysML execution.

## Required generic capabilities for the remaining migration

1. Resolve requirement-to-constraint membership and stable feature handles
   from the semantic SysML model. Evidence must identify the requirement,
   constraint, subject, source span/revision, and exact provider snapshot.
2. Bind document-scoped composed USD observations by typed subject path and
   attribute/relationship/geometry selector. A failed or stale projection
   must return `inconclusive`, never silently switch to another stage.
3. Support fixed and variable collection access, indexed values, cardinality,
   min/max/sum, and array equality so four tank bores and eight perimeter
   members can be expressed once in SysML rather than copied into Rhai loops.
4. Add generic mesh observations for bounds, profile, topology, manifold
   closure, normals/winding, and collision/render purpose. Keep numerical
   tolerance and unit conversion in the source-linked constraint evaluation.
5. Preserve `pass`, `fail`, `inconclusive`, and `error` through the final
   requirement report. The current Rhai `assert` bridge collapses the last
   three to a failed boolean while retaining the native verdict in evidence.
6. Bind mode and mission trace observations to SysML applicability and temporal
   predicates before calling the Griffin descent, ramp, and FLIP egress
   requirements verified.

The hidden physical body and deck collision proxies are active simulation
interfaces. Their current deck footprint is six-sided because the live ramp
transition study was dimensioned against that edge. The visible bus and its
central tank-support perimeter are octagonal. Changing the physical deck
requires rederiving the ramp transition and contact path in SysML and then
reauthoring the collider through the Editor.
