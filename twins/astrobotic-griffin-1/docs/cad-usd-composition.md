# Griffin CAD geometry in the USD twin

The maintained surface-operations twin uses `vehicles/griffin_1.usda`. It owns
the layout, station transforms, joints, connections, collision and mass
configuration. The CAD source owns the shapes used by the visual components.

[Griffin 8](../../../freecad/griffin_8/README.md) is the latest documented
FreeCAD body revision. Its five-engine layout and fore/aft articulated ramps
describe an older Griffin study. The maintained assembly has seven engine
stations and its own ramp and solar interfaces. Use Griffin 8 as a source for
individual compatible parts. A complete Griffin 8 assembly would need a
separately named study vehicle and verification contract.

The shared engine-bell layer references the engine library's Bell, Looks, and
Exhaust prims independently. The seven station references use the same Griffin
component root. The Griffin component owns its two meshes and plume styling.
The vehicle owns each station's actuator and plume input wiring.

| Asset | USD owner and reuse | Adoption gate |
|---|---|---|
| Engine bell | Existing `components/lander/griffin_engine_bell_visual.usda`, referenced by Engine01 through Engine07 | Compare one CAD engine to the existing bell envelope and mount. Confirm all seven stations still place the visual correctly and retain their local authored behavior. |
| Solar arrays | Existing forward, port and starboard component layers | Register each component at its own hinge. Compare outlines, normal direction, cell area and deployed clearances. Keep distinct assets where the geometry or handedness differs. |
| Bus and engine skirt | Bus and skirt component layers, referenced at their existing assembly mounts | Compare deck, leg, payload and engine interfaces before accepting Griffin 8 structure. Review the skirt independently of the bells so the existing material and profile can be evaluated in place. |
| Tanks and landing legs | Reusable visual components attached to existing tank or leg stations | Check repeat geometry and handedness. Preserve tank connections, strut travel and foot contact datums. |
| Ramp sections | Existing section references and named bearing datums | Compare hinge axes, running surface and FLIP clearance before mapping any CAD rails to the operating ramp. Compare stowed, intermediate and deployed poses. |

Use one stable root per independently editable component. Put mount and hinge
datums in the component's local frame, then place each occurrence with a USD
reference on an assembly-owned prim. Use native instanceable references only
for visual subtrees whose descendants need no station-specific opinions and
whose projection has been verified in LunCoSim. Keep station-specific controls,
physics, ports, and relationships outside such subtrees. Existing station paths
are part of the test and scenario contracts.

Capture the FreeCAD revision and file hash, object names, saved pose, mount frame,
mesh tolerance, and millimetre-to-metre and axis conversion for each adopted
mesh. Tessellate by component in FreeCAD, transform each mesh into its mount
frame, and submit indexed points and faces through the Editor's typed mesh plans.
Use the Editor to apply the plan, save the layer and reopen it. The component
asset should open independently for inspection and be usable by both review
scenes and the assembled twin.

Start with one engine bell. Check mesh winding and bounds, read back its mount
and all seven assembly references, and inspect the composed underside. Check
that existing engine behavior and connections still resolve before adopting
another part. For moving components, also run their existing motion and
clearance gates. Record which CAD objects actually passed adoption. The
inventory above is an integration plan.
