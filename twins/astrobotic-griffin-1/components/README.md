# Component ownership

Reusable Griffin and FLIP subcomponent assets live here, separate from the two
integrated vehicle assets in `vehicles/` and mission scenes in `scenes/`. The
SysML requirement packages are normative. `twin.toml` is the single typed
registry binding each component to its requirement source, verification, and
fixture; this README describes the ownership rules without duplicating that
registry.

Griffin's visual pieces, body collision geometry, and reusable physical landing
leg are separate component assets under `lander/`. FLIP's chassis, wheels,
suspension, and solar hardware are under `rover/`. `vehicles/griffin_1.usda`
and `vehicles/flip.usda` compose those component assets into their complete
vehicle assemblies.

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

The suspension module demonstrates the detached-subcomponent rule: the wheel
assembly verifies only the reference identity, station placement and handed
mirror; `flip_suspension_requirements.sysml` and its Rhai gate own the arm,
knuckle, strut dimensions and render-only collision policy.  The same split is
required for every reusable or articulated mission component.  The gate loads
`components/rover/flip_suspension_visual.usda` from the SysML `componentAsset`
datum through `assembly_builder::referenced_instance_plan` at runtime, using
the document handle discovered from the active workspace.

For a fast focused gate, run the fixture and its qualified verification from
the `[[verification.cases]]` entry in `twin.toml`; all component gates use the
same deterministic invocation (`--max-ticks 120 --tick-hz 60 --threads 1
--jitter 0`).
