# Minimal relationship-driven assembly

Proposal only; no new loader or solver is shipped in this change.

Start with a small JSON list of **frame mates**. Each says which component
interface attaches to which host interface. Component dimensions and their
sources remain in SysML. Rhai loads the list and calls existing authoring
functions; it should not repeat coordinates or implement another solver.

Illustrative syntax (these interface names still need to be authored):

```json
{
  "mates": [
    {
      "moving": "frontPanel.mountFrame",
      "target": "bus.frontSolarMountFrame",
      "requirement": "GriffinSolarRequirements::gsa005"
    }
  ]
}
```

LunCoSim already has `assembly_builder::align_frames_plan` for rigid frame
alignment under sibling roots and `mount_component_plan` for authored sockets.
Use those mechanisms. The alignment adapter currently emits Euler rotations;
it needs to preserve the quaternion composition used by the corrected Griffin
panels before this particular assembly can rely on it. Named mating frames
must exist first. JSON by itself does not provide those missing interfaces.

For now, keep panel width derived from paired bus rails by the existing recipe.
Keep belt height derived from the wide-face aspect ratio in the source model.
Do not add expressions, a general constraint graph, or a CAD solver until an
actual assembly requires them. `mechanical_relations` already checks residuals
such as distances and parallelism; it does not solve poses.

The minimum loader should reject missing frames and duplicate placement drivers,
produce a dry typed edit plan, and apply it through the generation-fenced Editor.
Read back the matching USD projection and run the existing geometry checks.
A full frame mate fixes all six rigid pose freedoms; a plane mate would not,
so omit plane-only constraints from the first version.

The image estimates and their rationale remain in
[the size evidence record](../requirements/griffin-size-evidence.md), including
[ESA's concept image](https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander)
and [Astrobotic's rendering](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/).
They remain estimates rather than flight measurements.
