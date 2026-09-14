# Griffin part contracts

Every named part has one canonical owner path, one geometry policy, one
collision policy, and an explicit parameter-status/provenance record. A
reference or inherited substitute does not satisfy the contract when the
canonical wrapper is hidden, empty, or mounted on the wrong datum.

| Part | Required topology | Required geometry / physics | Known study requirement |
|---|---|---|---|
| `Griffin1` | `BoxyAirframe`, `IsogridDeck`, `PayloadAdapter`, `MainPropulsion`, four tanks, both arrays, `Nozzle`, four legs, optional two ramps | Xform root with capacity, collision, status, and provenance metadata | Public 625 kg capacity, four legs, seven engines, four tanks; dimensions and dynamics TBD |
| `BoxyAirframe` | Primary body shell | Visible rectangular Cube with positive dimensions and enabled collider | Global Griffin references establish the boxy frame; exact dimensions, dry mass, and inertia TBD |
| `IsogridDeck` | `DeckPlate` | Visible plate with enabled collider | Payload deck dimensions TBD |
| `TankPX/NX/PZ/NZ` | None beyond each tank shape owner | Four visible Y-axis Capsule study geometries; visual-only unless a body contract says otherwise | Four-tank integration is public; exact tank dimensions TBD |
| `PayloadAdapter` | `AdapterPlate` | Adapter plate with enabled collider | FLIP interface/release datum TBD |
| `MainPropulsion` | Chamber, fuel tank, oxidizer tank | Named propulsion interface | Thrust, propellant, mass, and engine count TBD |
| `Nozzle` | `MainEngineCluster/Engine01..07` | Seven visible non-colliding engine-bell geometries; no single-bell design placeholder | Seven main engines are public; bell contour and spacing TBD |
| `SolarPanelPort` | `Cells` plus frame/borders | Visible side array with explicit installation metadata; exactly one port array | Electrical ICD TBD |
| `SolarPanelStarboard` | `Cells` plus frame/borders | Visible mirrored side array; exactly one starboard array | Electrical ICD TBD |
| `LegPX/NX/PZ/NZ` | `Strut` and matching `PadPX/NX/PZ/NZ` | Positive mass body, visible strut, enabled pad collider | Four functional legs; dimensions and damping TBD |
| `EgressRampPort/Starboard` | Surface and two edge rails | Positive-mass Xform, colliding contact geometry, named hinge | Optional Griffin hardware; command proxy limited to +/-0.58 rad |
| `RampHingePort/Starboard` | Body relationships to root and matching ramp | `PhysicsRevoluteJoint`, Z axis, ordered limits | Actuator/lock behavior TBD |

## Canonical frame

The study frame is metres, Y-up, with the lander body datum at the Griffin root.
Port/starboard arrays occupy opposite signed Z sides. The optional egress ramps
occupy opposite signed X sides. FLIP's nominal public path is direct top-deck
egress; the ramp path is an alternate study branch. The four leg attachment
points occupy the four cardinal X/Z directions and their pads are below and
farther outboard than the body attachment points.

## Presentation component contracts

The render-only review assembly does not replace the dynamic contracts above.
It is composed from small Twin-local USDA assets so a bus, leg, panel, tank,
ramp, engine bell, wheel, mast, or chassis can be replaced independently
through the runtime authoring tools.

| Component asset | Stable child geometry | Policy |
|---|---|---|
| `components/lander/griffin_bus_visual.usda` | perimeter frame, white equipment box, thermal panel, logo marks, top deck | rectangular Griffin silhouette; render-only |
| `components/lander/griffin_landing_leg_visual.usda` | outer/inner strut, shock piston, foot pad | four repeated outboard strut assemblies; render-only |
| `components/lander/griffin_tank_visual.usda` | MLI tank and three bands | horizontal gold tank study; render-only |
| `components/lander/griffin_solar_panel_visual.usda` | frame, cells, dividers | side-mounted array pair; render-only |
| `components/lander/griffin_engine_bell_visual.usda` | bell and throat | seven repeated non-colliding bells; render-only |
| `components/lander/griffin_ramp_visual.usda` | surface, two rails, support arm | optional side-ramp silhouette; render-only |
| `components/rover/flip_chassis_visual.usda` | lower frame, equipment box, bumper, payload deck, service panel | low white FLIP body; render-only |
| `components/rover/flip_wheel_visual.usda` | tire, metal hub, hub cap | four repeated directional wheels in the visual assembly; render-only |
| `components/rover/flip_sensor_mast_visual.usda` | mast post, sensor head, antenna | front sensor silhouette; render-only |
| `components/rover/flip_solar_panel_visual.usda` | white backsheet, blue cells, fold hinge | rear collapsible-array proxy; render-only |

The dynamic `vehicles/flip.usda` and the presentation assembly both use the
four-wheel directional study architecture. The visual wheel count is checked
explicitly so a presentation update cannot silently regress to the old
six-station proxy.
