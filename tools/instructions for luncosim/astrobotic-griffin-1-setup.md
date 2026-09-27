# Griffin-1 / FLIP Twin authoring entry point

The executable Griffin-1 / FLIP model has one home:
[`twins/astrobotic-griffin-1/`](../../twins/astrobotic-griffin-1/). Make vehicle,
terrain, mission-scene, requirement, and verification edits there. The
`missions/mission-002/` package records mission facts; its `scene.usda`
composes the Twin's canonical surface-operations scene and must not define
parallel Griffin, FLIP, or terrain geometry.

## Canonical sources

- Griffin lander: [`vehicles/griffin_1.usda`](../../twins/astrobotic-griffin-1/vehicles/griffin_1.usda)
- FLIP rover: [`vehicles/flip.usda`](../../twins/astrobotic-griffin-1/vehicles/flip.usda)
- Mission composition: [`scenes/griffin_1_surface_ops.usda`](../../twins/astrobotic-griffin-1/scenes/griffin_1_surface_ops.usda)
- Visual review composition: [`scenes/griffin_flip_visual.usda`](../../twins/astrobotic-griffin-1/scenes/griffin_flip_visual.usda)
- Requirements and typed configuration: [`requirements/`](../../twins/astrobotic-griffin-1/requirements/)
- Current implementation gaps: [`contracts/implementation_gaps.md`](../../twins/astrobotic-griffin-1/contracts/implementation_gaps.md)
- Twin authoring and verification workflow: [`Twin README`](../../twins/astrobotic-griffin-1/README.md) and [`Twin instructions`](../../twins/astrobotic-griffin-1/instructions.md)

Every mission and verification scene should reference these integrated
vehicle assets. Edit reusable component assets only when their geometry is
shared by a canonical vehicle; do not copy a full vehicle into a scene or
fixture. Keep FLIP separately loadable as its own vehicle.

## Model ownership

- SysML owns vehicle identities, configuration, requirements, units, datums,
  and measurable constraints.
- USD owns the composed vehicle realization, geometry, materials, physics,
  and scene references.
- Rhai owns authoring plans, mission policy, and Twin-specific verification
  observations.
- Modelica owns continuous subsystem equations.
- Rust owns generic typed simulation, authoring, and verification
  capabilities; add reusable behavior there instead of Griffin-specific
  branches.

Use the Twin-local authoring cycle documented in its README: inspect the
current source, create one dry plan, apply one generation-checked Editor
batch, read back the composed result, and save through the Editor. The
implementation gap report records unresolved features and evidence; do not
copy its status notes into normative requirements.
