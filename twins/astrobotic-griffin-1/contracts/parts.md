# Griffin part contracts

Every named part has one canonical owner path, one geometry policy, one
collision policy, and an explicit parameter-status/provenance record. A
reference or inherited substitute does not satisfy the contract when the
canonical wrapper is hidden, empty, or mounted on the wrong datum.

`../requirements/griffin_vehicle_assembly.sysml` now composes the bus, propulsion,
seven engine visuals, four study tanks, four legs, three arrays, optional ramp
assemblies, and the adapter interface. FLIP is a reference part that stays in
`vehicles/flip.usda`; its assembly is not nested into the Griffin asset. The
graph still needs canonical identity migration and generated realization links.

| Part | Required topology | Required geometry / physics | Known study requirement |
|---|---|---|---|
| `Griffin1` | component-owned octagonal bus, payload adapter, seven-engine propulsion, four-leg landing system, three Griffin-1 solar arrays, optional two ramps | Xform root with capacity, collision, status, and provenance metadata | Three panel instances occupy adjacent forward, bevel, and starboard faces; their stations and support dimensions are visual-study values. Four visual tank assemblies are also a Twin study assumption |
| `GriffinBusComponent` | open octagonal frame, octagonal payload deck, lower service skirt, avionics, and a separate octagonal central tank-support perimeter | referenced component owns render geometry; the descent lander owns flight collision and mass | `GriffinVisualConfiguration` owns dimensions, stations, and appearance; the support perimeter has eight sides |
| `GriffinBody` | `BodyCollisionProxy` and four side collision proxies | Hidden flight-body colliders; visible structure comes from `Bus` | Flight collider geometry remains a simulator study envelope |
| `TopDeckBeamCollider0..7` | Eight hidden convex beams following the eight source-owned octagon edges | Enabled perimeter colliders; no hull closes the tank-support opening | Editor readback checks beam count, profile-derived dimensions, and collider state; dimensions remain a simulator study envelope |
| `RoverPayloadDeckCollider` | Hidden clipped-square convex collider matching the central FLIP payload adapter | Enabled, separate from the octagonal perimeter ring | Geometry is derived from adapter dimensions; supplier interface and load rating remain TBD |
| `TankPX/NX/PZ/NZ` | `components/lander/griffin_tank_visual.usda` through four source references | Four render-only COPV study assemblies at the ordered SysML stations; MainPropulsion owns flight propellant mass | Tank count, type, dimensions, and stations are not established by a public Griffin-1 ICD |
| `PayloadAdapter` | `AdapterPlate` | Adapter plate with enabled collider; the surface scene owns one fixed FLIP payload joint | The graph names the adapter and release-joint paths and requires both touchdown/settling and a ready egress path before release; mechanical interface dimensions and release-load ICD remain TBD |
| `MainPropulsion` | Chamber, fuel and oxidizer tanks and pumps, representative nozzle design, shared plume photometry | The chamber remains the sole thrust and propellant authority; plume photometry derives per-nozzle rendering and light from aggregate simulated thrust, flow, velocity, chamber pressure, and nozzle geometry | Nozzle contour, engine-out behavior, and supplier propulsion data remain TBD |
| `Nozzle` | `MainEngineCluster/Engine01..07`, each with a bell, throat, outer plume, hot core, and local plume light | Seven non-colliding bells and flame pairs; all seven receive the same cluster state through the shared photometry model, which divides aggregate engine outputs by its configured nozzle count | Seven main engines are public; bell contour and spacing remain study geometry |
| `SolarPanelForward`, `SolarPanelFrontStarboard`, `SolarPanelStarboard` | Each root references `components/lander/griffin_solar_panel_visual.usda`, with `Cells`, `Frame`, dividers, hinge, brackets, and links | Three independently oriented panels use paired bus rails; each installed width derives from its rail span and shared edge clearance | The lower clearance cutout, as-built outline, installation datums, mechanism limits, and electrical behavior require the controlled panel and interface definitions |
| `LegPX/NX/PZ/NZ` | `Strut` and matching `PadPX/NX/PZ/NZ` | Positive mass body, visible strut, enabled pad collider | Four functional legs; dimensions and damping TBD |
| `EgressRampPort/Starboard` | Three rigid ramp sections from the upper deck; each section has two source-aligned wheel tracks, an open centre, and two upper edge-rail segments | Positive-mass rigid sections; both geometry-derived track colliders enabled | Track stations follow FLIP wheel datums; dimensions and ramp kinematics remain study values |
| `RampHingePort/Starboard` | Upper-deck hinge connects the lander body to the first ramp section | `PhysicsRevoluteJoint`, Z axis, angular drive, ±50° limits | Root deployment datum is the upper deck top; transport target is 0° |
| `RampSectionHingePort/Starboard01/12` | Two serial inter-section pivots per ramp; track surfaces, rail segments, and hinge fittings remain aligned at each joint | Native driven `PhysicsRevoluteJoint` between adjacent rigid section bodies, ±120° limits | Intermediate targets fold to +90°/-90° in transport and hold the sections coplanar during rover traversal |

## Canonical frame

The study frame is metres, Y-up, with the lander body datum at the Griffin root.
The three solar-array instances occupy the forward, bevel, and starboard faces
in the Sun quadrant shown in Griffin-1 integration imagery. Their authored
stations, dimensions, and support geometry are visual-study values, not a
released flight installation. The optional egress ramps
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
| `components/lander/griffin_solar_panel_visual.usda` | frame, cells, dividers, hinge, paired brackets, paired support links | shared render-only component referenced by the three independently placed panel roots |
| `components/lander/griffin_engine_bell_visual.usda` | bell, throat, fixed-capacity outer plume and hot core, and a per-nozzle point light | referenced by each of the seven engines; plume visibility, derived length, and light output are connected to the shared Modelica photometry result; all geometry is render-only |
| `components/lander/griffin_ramp_visual.usda` | three visual ramp sections, each with paired wheel tracks, upper rail segments and joint pins, deck-to-rail posts, underside beams, hinge barrel, and per-track treads | standalone preview asset; the integrated vehicle renders its articulated physical sections and does not mount a static duplicate |
| `components/lander/griffin_ramp_section_visual.usda` | reusable full section with geometry-derived track collision, upper edge rails, rail pivot pins, supports, treads, beams, and hinge barrel | shared source section referenced by visual and physical ramp assemblies |
| `components/lander/griffin_ramp_toe_section_visual.usda` | final section with the deployment-angle-derived toe bevel | inherits shared geometry and collision from the section source |
| `components/rover/flip_chassis_visual.usda` | lower frame, equipment box, bumper, payload deck, service panel | referenced by the canonical FLIP vehicle; the same shapes provide visible chassis geometry and wheel-filtered rigid-body collision |
| `components/rover/flip_wheel_visual.usda` | tire, metal hub, hub cap | referenced at each typed wheel station in the canonical FLIP vehicle; render geometry stays separate from the physical wheel prim |
| `components/rover/flip_sensor_mast_visual.usda` | mast post, sensor head, antenna | front sensor silhouette; render-only |
| `components/rover/flip_solar_panel_visual.usda` | white backsheet, blue cells, fold hinge | rear collapsible-array proxy; render-only |

`vehicles/flip.usda` is the only FLIP vehicle assembly. It composes the dynamic
wheel and drivetrain model with the chassis, wheel, suspension, mast, and solar
visual components. SysML owns wheel identities, station datums, and dimensions;
the references keep repeated geometry in one component source.

The Griffin main-engine plume is authored as a direct presentation of the
propulsion simulation. `MainPropulsion/PlumePhotometry` consumes combustion
activity and the chamber's total thrust, flow, and exhaust velocity, plus nozzle
area and radius from `MainPropulsion/NozzleDesign`. Its `engine_count`
parameter normalizes the cluster totals to each of the seven equal nozzles. The
program declares `outputs:render_throttle`,
`outputs:visual_length_fraction`, `outputs:intensity`, and `outputs:radius`;
the seven bell flame pairs and local lights connect to those outputs. At zero
delivered thrust the model specifies zero plume and zero light. Rhai does not
animate plume transforms or brightness. The propulsion network must compile
and produce live values before this behavior is considered demonstrated.
