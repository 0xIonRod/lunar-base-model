# Griffin part contracts

Every named part has one canonical owner path, one geometry policy, one
collision policy, and an explicit parameter-status/provenance record. A
reference or inherited substitute does not satisfy the contract when the
canonical wrapper is hidden, empty, or mounted on the wrong datum.

| Part | Required topology | Required geometry / physics | Known study requirement |
|---|---|---|---|
| `Griffin1` | component-owned octagonal bus, payload adapter, seven-engine propulsion, four-leg landing system, three Griffin-1 solar arrays, optional two ramps | Xform root with capacity, collision, status, and provenance metadata | Current source scene has only two arrays and is nonconforming; four visual tank assemblies are a Twin study assumption |
| `GriffinBusComponent` | open octagonal frame, octagonal payload deck, lower service skirt, avionics, and a separate octagonal central tank-support perimeter | referenced component owns render geometry; the descent lander owns flight collision and mass | `GriffinVisualConfiguration` owns dimensions, stations, and appearance; the support perimeter has eight sides |
| `GriffinBody` | `BodyCollisionProxy` and four side collision proxies | Hidden flight-body colliders; visible structure comes from `Bus` | Flight collider geometry remains a simulator study envelope |
| `TopDeckBeamCollider0..7` | Eight hidden convex beams following the eight source-owned octagon edges | Enabled perimeter colliders; no hull closes the tank-support opening | Editor readback checks beam count, profile-derived dimensions, and collider state; dimensions remain a simulator study envelope |
| `RoverPayloadDeckCollider` | Hidden clipped-square convex collider matching the central FLIP payload adapter | Enabled, separate from the octagonal perimeter ring | Geometry is derived from adapter dimensions; supplier interface and load rating remain TBD |
| `TankPX/NX/PZ/NZ` | `components/lander/griffin_tank_visual.usda` through four source references | Four render-only COPV study assemblies at the ordered SysML stations; MainPropulsion owns flight propellant mass | Tank count, type, dimensions, and stations are not established by a public Griffin-1 ICD |
| `PayloadAdapter` | `AdapterPlate` | Adapter plate with enabled collider | FLIP interface/release datum TBD |
| `MainPropulsion` | Chamber, fuel tank, oxidizer tank | Named propulsion interface | Thrust, propellant, mass, and engine count TBD |
| `Nozzle` | `MainEngineCluster/Engine01..07` | Seven visible non-colliding engine-bell geometries; no single-bell design placeholder | Seven main engines are public; bell contour and spacing TBD |
| `SolarPanelPort` / `SolarPanelStarboard` | Current two study roots with `Cells`, frame, and borders | Opposite signed-Z proxy geometry; not the Griffin-1 mission arrangement | Griffin-1 imagery shows three upright panels across adjacent sides in one quadrant. Identities, stations, cell outlines, supports, hinges, and electrical data await controlled design sources |
| `LegPX/NX/PZ/NZ` | `Strut` and matching `PadPX/NX/PZ/NZ` | Positive mass body, visible strut, enabled pad collider | Four functional legs; dimensions and damping TBD |
| `EgressRampPort/Starboard` | Two source-aligned wheel tracks, open centre, two edge rails, and named hinge | Positive-mass Xform; both geometry-derived track colliders enabled | Track stations follow FLIP wheel datums; width and clearance remain replaceable study values |
| `RampHingePort/Starboard` | Body relationships to root and matching ramp | `PhysicsRevoluteJoint`, Z axis, ordered limits | Actuator/lock behavior TBD |

## Canonical frame

The study frame is metres, Y-up, with the lander body datum at the Griffin root.
The current solar-array proxy occupies opposite signed Z sides; Griffin-1
integration imagery instead shows three upright panels across adjacent sides
in one azimuth sector. The solar arrangement in the study frame is not a flight
installation. The optional egress ramps
occupy opposite signed X sides. FLIP's nominal public path is direct top-deck
egress; the ramp path is an alternate study branch. The four leg attachment
points occupy the four cardinal X/Z directions and their pads are below and
farther outboard than the body attachment points.

## Presentation component contracts

The integrated Griffin vehicle composes Twin-local USDA assets so a bus, leg,
panel, tank, ramp, engine bell, wheel, mast, or chassis can be replaced
independently through the runtime authoring tools.

| Component asset | Stable child geometry | Policy |
|---|---|---|
| `components/lander/griffin_bus_visual.usda` | octagonal open perimeter frame, white equipment box, thermal panel, logo marks, top deck | octagonal Griffin silhouette with open tank-support centre; render-only |
| `components/lander/griffin_landing_leg_visual.usda` | outer/inner strut, shock piston, foot pad | four repeated outboard strut assemblies; render-only |
| `components/lander/griffin_tank_visual.usda` | MLI tank and three bands | horizontal gold tank study; render-only |
| `components/lander/griffin_solar_panel_visual.usda` | frame, cells, dividers | side-mounted array pair; render-only |
| `components/lander/griffin_engine_bell_visual.usda` | bell and throat | seven repeated non-colliding bells; render-only |
| `components/lander/griffin_ramp_visual.usda` | paired wheel tracks, rails, paired supports, underside beams, posts, hinge collars, gussets, and per-track treads | referenced port/starboard visual component owns its geometry; render-only |
| `components/rover/flip_chassis_visual.usda` | lower frame, equipment box, bumper, payload deck, service panel | low white FLIP body; render-only |
| `components/rover/flip_wheel_visual.usda` | tire, metal hub, hub cap | four repeated directional wheels in the visual assembly; render-only |
| `components/rover/flip_sensor_mast_visual.usda` | mast post, sensor head, antenna | front sensor silhouette; render-only |
| `components/rover/flip_solar_panel_visual.usda` | white backsheet, blue cells, fold hinge | rear collapsible-array proxy; render-only |

The dynamic `vehicles/flip.usda` and the presentation assembly both use the
four-wheel directional study architecture. The visual wheel count is checked
explicitly so a presentation update cannot silently regress to the old
six-station proxy.
