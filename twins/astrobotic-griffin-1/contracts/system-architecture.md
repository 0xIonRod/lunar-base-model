# Griffin executable system architecture

The default mission is `scenes/griffin_1_surface_ops.usda`. It composes Griffin,
FLIP, terrain, the payload attachment and the cross-vehicle tether interface.
`tests/griffin_tether_descent.usda` references that same scene and changes only
its observer's `verification_mode`. It is the manifest-mapped
`Griffin1Requirements::Verify_GriffinSurfaceOperations` case.

## Authoritative owners

| Concern | Source and consumer |
| --- | --- |
| Requirement intent, dimensions, ratings and study assumptions | `requirements/*.sysml`; consumed through the typed SysML model |
| Installed component identities, references, solver collections and wiring | composed USD; consumed by native projection and Modelica assembly |
| Propellant pressure/flow, charge, heat, line load and drum motion | Modelica; consumed by the shared fixed-step co-simulation runtime |
| Landing, preload, adapter release, ground transfer and operator authority | Rhai mission tasks and events; consume admitted native physics and domain state |
| Grouping and diagram placement | `views/*.lunco-view.toml`; independent of executable topology |
| Release compatibility and qualification | repository `tools/qualification.toml`, pinned runtime/assets, native validation and registered scene verdicts |

The egress task samples the current lander, ramp and rear wheel poses into one
routing snapshot. Modelica's input adapter adds live rates and centre-of-mass
facts and writes the ordered scalar ports. The tether view consumes routing
vectors directly. During landing standby it samples them after the previous
curve publication completes, on the existing visual tick cadence. Route
selection still comes from the Modelica output snapshot.

Authoring plans are separated by domain. `griffin_propulsion_builder` owns
engine/feed assembly, propellant mass properties, thrust ratings and RCS
actuator plans. `griffin_power_builder` owns the electrical/thermal network and
FLIP electrical ratings. `griffin_winch_builder` installs the actuator energy
network and its mission boundary. `griffin_visual_builder` owns presentation
geometry, material assignment, collision proxies and exhaust rendering.
`griffin_assembly_support` supplies shared composed-document reads and plan
diagnostics. Plans commit through typed USD operations and the document journal;
they do not write USDA text.

## Coupled assemblies and interfaces

MainPropulsion places the two reservoirs, fourteen valves, seven chambers,
nozzle design, plume and wall models in one coupled assembly. Each engine is a
referenced USD assembly with independently inspectable valve/chamber programs.
The engine command is a requested fraction of the assumed nominal flow; the
passive valve law and chamber relation solve pressure and flow together.

ElectricalPower places the finite battery, three photovoltaic/thermal branches,
avionics and winch converter/thermal branch in one coupled assembly. Battery
current is determined by its electrical node. The winch consumes enabled idle
and motoring power, dissipates payout braking and conversion losses, and routes
line damping into the explicitly assumed lumped thermal node. Its thermal mass
and radiator close the heat-flow network.

The scene binds each signed tether spool-power output to ElectricalPower's
public winch inputs and returns solved drive availability to the tether. The
bridge uses the existing sampled fixed-step port contract. Each drum has an
explicit motoring-power limit. Loss of supply stops paid-out length evolution;
the passive loaded line and drum hold remain. These are reduced actuator
assumptions, including an ideal holding brake, not a flight winch specification.
The power gate observes both finite-battery depletion and an initially empty
negative fixture under sustained commands.

Tether geometry and load equations remain in Modelica. The scenario applies
wheel forces/torques and equal/opposite lander reactions through atomic native
wrench commands. The Connections panel's **Scenario access** overlay shows
admitted scenario reads/writes as distinct dashed interactions. These are access
declarations, not measured force-transfer provenance. Exact accesses remain
inspectable when displayed groups aggregate them. Static USD connection counts
exclude this overlay.

Solar conversion exposes actual cell temperature separately from its coefficient
evaluation temperature. Griffin holds coefficient evaluation at the published
cold reference as an explicit study assumption, records off-calibration cold
samples, and rejects temperatures above the authored upper limit. Thermal
acceptance permits measured heating or cooling and still requires closed heat
and electrical balances. The converter's discrete voltage-crossing latch retains
UVLO state through the battery rebound after a load disconnects.

## Fidelity boundary

| Subsystem | Executable representation | Boundary |
| --- | --- | --- |
| Main propellant tanks | Two lumped reactant reservoirs | Four visible tank assemblies do not imply four independently solved inventories |
| Feed and engines | Acausal valves, injector loss and choked chambers | Flow ratings, pressures and responses are explicit study assumptions |
| Pressurization | Tank pressure envelope | Finite helium inventory and a resolved regulator circuit are outside this model |
| RCS | Existing simplified availability and consumption model | No resolved branch plumbing or discrete pulse qualification |
| Tether and winches | Routed lines, bounded powered drum motion, electrical demand and lumped heat rejection | End rigging, material failure, holding-brake hardware and flight ratings are unqualified |
| Exit tracks | Static physical geometry | No deployment hydraulics are implied |

These boundaries must remain visible in subsystem documentation and diagrams.
Adding decorative parts or wires does not increase physical coverage. A higher
fidelity model needs explicit source-backed parts, interfaces and acceptance
criteria before replacing one of these reduced representations.

## Acceptance and delivery

The motion gate drives FLIP forward and reverse through the native local
controller, qualifies physical stops and stationary dwells, and evaluates
source-owned scalar acceptance with typed telemetry and source-literal limits.
Its document-authored missing-brake variant must fail on measured stopping
behavior. Both directions publish exact source-revision-bound requirement
evidence; raw motion metrics use a separate telemetry channel.

The surface-operations verifier reports the seven `GriffinFlipEgressStudy::gfe*`
requirements plus the two landing datum requirements, with source revision and
exact verification identity. It requires
qualified unlock, persistent drive authority, measured manual travel, bounded
line loads, unloaded release and stable fixed support, brake-admission rejection,
and dynamic-versus-fixed support discrimination. After its manual drive proof,
the verifier applies the controller brake and requires continuously stable
fixed support for the source-owned dwell, within a bounded stop deadline.
The normal interactive scene
continues to require explicit DEPLOY FLIP and DISCONNECT TETHERS actions.

The winch power/unpowered cases map to `GriffinWinchRequirements` and check the
solved electrical/storage and thermal balances, per-drum power saturation and
supply-loss hold. Component benches may intentionally prescribe geometry or
inventory; those inputs are declared in their source-owned study configuration.
They do not replace the full mission gate.

Repository structural validation checks TOML and package-local manifest paths.
It does not parse domain languages or prove simulation. Release qualification
uses the pinned, clean engine checkout and matching shared assets, validates the
mounted Twin source set and composed scenes through native owners, provisions
terrain through the native asset manager, and requires the selected registered
production cases to pass with unchanged source revisions. A ZIP checksum alone
cannot qualify a model. Release archives exclude terrain cache and include the
qualification receipt; native dataset provisioning supplies the pinned terrain.
