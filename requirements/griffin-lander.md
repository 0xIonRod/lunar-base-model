# Griffin Lander requirements

**Last updated:** 2026-09-13
**Scope:** Griffin-1 lander packaging, payload integration, ramp deployment,
and the FLIP surface-operations handoff.
**Boundary:** Geometry and numeric values marked as proxies are MoonDAO/LunCoSim
study inputs, not a released Griffin mechanical ICD.

## Requirements

| ID | Requirement | Status | Creation / acceptance note |
|---|---|---|---|
| GR-001 | Model a reusable Griffin lander body with four landing legs and a top payload deck. | MUST | Keep lander structure, deck, landing gear, propulsion, and power as separate subassemblies. |
| GR-002 | Provide a payload adapter that holds FLIP during descent. | MUST | The adapter is a physical fixed attachment during descent and releases only at the authored post-touchdown boundary. |
| GR-003 | Model Griffin's optional side-ramp hardware as two inspectable rigid bodies with physical contact surfaces and revolute joints. | PUBLIC OPTIONAL HARDWARE | Astrobotic advertises optional egress ramps; Astrolab's FLIP can also egress directly from the top deck. The ramp branch must not be treated as a mandatory FLIP interface. |
| GR-004 | Preserve the selected surface sequence: landing/settle → direct-deck or ramp preparation → adapter release → FLIP egress → base-site route. | MUST | Do not let FLIP consume the surface route while it remains fixed-joint cargo; record which egress branch was selected. |
| GR-005 | Keep all Griffin and FLIP integration values traceable as public fact, project requirement, study proxy, or `TBD`. | MUST | Update this record whenever scene, USD, CAD, or scenario behavior changes. |
| GR-006 | Treat Griffin solar arrays and FLIP's collapsible array as separate visual/power subassemblies. | PUBLIC CONCEPT + STUDY PROXY | FLIP's collapsible-array concept is public; the current fixed panel and Griffin side arrays are explicit visual/power proxies until the ICD is supplied. |
| GR-007 | Model rover egress as a gated direct-deck or optional-ramp operation, not a teleport from deck to terrain. | MUST | Adapter release and wheel/contact evidence precede route commands; a direct-deck case is valid for FLIP. |
| GR-008 | Validate the selected egress path under nominal, high-pitch, uneven-roll, and combined pitch/roll lander attitudes. | MUST | Preserve wheel clearance, contact/traction evidence, and a safe handoff to the surface route in each case. |
| GR-009 | Declare the Griffin payload capacity and reject any payload load above it. | PUBLIC PRODUCT VALUE | Astrobotic publishes a 625 kg payload capacity. The exact integrated mission load remains a separate manifest value; any load above 625 kg fails. |
| GR-010 | Keep exactly four visible functional landing-leg bodies, each with an explicit strut and enabled foot-pad collider. | MUST | Hidden historical comparison geometry does not count as a functional leg. |
| GR-011 | Keep exactly two side-ramp bodies, each with solid contact geometry and a correctly connected revolute hinge. | MUST | Validate body0/body1, hinge axis, and ordered joint limits from composed USD. |
| GR-012 | Require positive mass and explicit collision ownership for every load-bearing Griffin subassembly. | MUST | The source contract is checked for legs, deck, adapter, ramp surfaces, and rails; solver compound-body admission remains a runtime gate. |
| GR-013 | Require status and provenance metadata for every study parameter that is not source-backed. | MUST | Missing or empty status/source metadata is a lint error; `TBD` remains visible rather than becoming an invented number. |
| GR-014 | Apply model edits through the live typed USD path and re-run the Twin contract before save. | MUST | Live tools require explicit `doc_id`, `edit_target`, and optional `parent_gen`; no file reload is part of the edit loop. |
| GR-015 | Require every named lander part to resolve to the expected composed prim, geometry, and parameter contract; the main nozzle must be a visible bell geometry, not a hidden placeholder. | MUST | The nozzle dimensions, throat, exit, and engine count remain `TBD` until source-backed. Missing geometry is still an automatic failure. |
| GR-016 | Keep exactly two named solar-array parts, one on each signed side, with mirrored placement and owned cell geometry. | MUST | Current panel dimensions and electrical ICD are study/TBD; inherited substitute wings must not hide disabled wrappers. |
| GR-017 | Keep exactly two named ramps with mirrored side placement, mirrored hinge rotation, and consistent transform/angle metadata. | MUST | Current ±0.58 rad command envelope is a control surrogate; ramp mechanism and deformation limits remain TBD. |
| GR-018 | Keep a positive, collidable Y-up boxy hull and a positive upper-deck body above it. | STUDY PROXY | The public Griffin structure is described as stout/stiff with an isogrid deck; the current rectangular hull dimensions are visual/physical surrogates, not a flight mechanical ICD. |
| GR-019 | Mount four legs on the four signed horizontal body axes, with mirrored attachment points and pads below/outboard of the body. | MUST | Exact load paths and as-built leg angles remain TBD; current prototype uses the ±X/±Z datum. |
| GR-020 | Suppress inherited comparison geometry when a named Griffin part owns the visible representation. | MUST | Prevents duplicate hulls, wings, legs, and foot pads from silently changing mass/visual ownership. |

## Visual review requirements

The render review is a separate, componentized USD assembly. It is not a CAD
or B-rep claim and does not replace the dynamic lander/FLIP assets.

| ID | Requirement | Acceptance |
|---|---|---|
| GV-001 | Provide an authored review camera in the project metre/Y-up frame. | `VisualCamera` exists in the visual scene. |
| GV-002 | Show a recognisable Griffin silhouette with a white rectangular bus, dark frame, four corner legs, gold horizontal tanks, two ramps, dual solar panels, and seven engine bells. | Every referenced component and named child passes the Twin Rhai visual check. |
| GV-003 | Show FLIP as a low white six-wheel rover with a mast and rear collapsible-array proxy. | Six wheel stations, chassis/mast/array children, and `visualRoverWheelCount` agree. The dynamic model remains a four-wheel study proxy. |
| GV-004 | Keep visual scale in SI metres. | Composed `geometry_bounds` agree with SysML deck, wheel, pad, and ground datums. |
| GV-005 | Keep review-only geometry out of physics. | Render purpose and collision attributes are checked on the visual context. |
| GV-006 | Include a bounded lunar surface context and one review light. | Ground and `Sun` are present without introducing a second physics model. |
| GV-007 | Emit visual evidence from the Twin. | Rhai emits a verdict that can be paired with a same-generation composed query and frame. |

## Part contracts

The part manifest in `tools/griffin_requirements.rhai` is the Twin-local CAD
acceptance contract. Its audit engine is generic: it checks prim existence and
type, required children, render geometry, collision ownership, and authored
parameter bounds. The Griffin manifest supplies only the names and requirements
that are specific to this vehicle.

| Part ID | Composed path | Required geometry / interface | Known parameters | Open / `TBD` |
|---|---|---|---|---|
| `lander` | `/Griffin1` | Xform root and named subassemblies | 625 kg public payload capacity; four-leg declaration; provenance and collision contract | Flight ICD and as-built geometry |
| `deck` | `/Griffin1/IsogridDeck` | visible Xform and `DeckPlate` enabled collider | Prototype deck dimensions | Flight deck ICD |
| `hull` | `/Griffin1/BoxyAirframe` | visible rectangular hull with enabled collider | Boxy study surrogate | As-built dimensions, height, and mass |
| `upper_deck` | `/Griffin1/IsogridDeck` | visible upper-deck geometry and deck-plate collider | Isogrid-deck study surrogate | As-built deck geometry |
| `payload_adapter` | `/Griffin1/PayloadAdapter` | `AdapterPlate` enabled collider | FLIP interface role | Release datum and as-built interface |
| `main_propulsion` | `/Griffin1/MainPropulsion` | chamber, fuel tank, oxidizer tank interfaces | Subassembly presence | Thrust, propellant, mass, inertia, nozzle ICD |
| `landing_leg_*` | `/Griffin1/LegPX/NX/PZ/NZ` | `Strut` plus one enabled foot-pad collider | Four functional legs; positive inherited study mass | As-built leg geometry and load data |
| `egress_ramp_*` | `/Griffin1/EgressRampPort/Starboard` | surface and two enabled edge-rail colliders | Positive study mass; command envelope ±0.58 rad | Mechanical stop, actuator, deformation, exact dimensions |
| `solar_*` | `/Griffin1/SolarPanelPort/Starboard` | visible Xform, cell geometry, and installation metadata | Two separate visual/power proxy arrays | Electrical ICD and flight deployment |
| `flame` | `/Griffin1/Flame` | visible plume geometry | Photometric exhaust proxy | Engine exhaust ICD |
| `nozzle` | `/Griffin1/Nozzle` | visible `Bell` geometry under an Xform | Bell is required as a study geometry part | Throat, exit, dimensions, and engine count |

A part can therefore be geometrically incomplete while its unknown numeric
parameters remain honest `TBD`; the checker must fail the missing geometry and
must not invent a value to make the part pass.

The visual component manifest is separate and lives in
`twins/astrobotic-griffin-1/components/`. The runtime helper
`tools/griffin_visual_builder.rhai` creates or reuses those references through
LunCoSim's generic typed `assembly_builder` and `assembly_edit` tools. It is
safe to call against an open Editor document: the helper returns a dry plan,
then submits one journaled `ApplyUsdOps` batch without restarting or rewriting
USDA source.

## Active study values

| Parameter | Active value | Status / provenance |
|---|---:|---|
| Mission | Astrobotic Griffin Mission One / NASA Moon Base II | Public mission identity. |
| Landing region | Nobile Crater area near the lunar South Pole | Public planning description; exact coordinates remain unresolved. |
| Primary rover payload | Astrolab FLIP | Public mission assignment. |
| Griffin payload capacity | 625 kg | Public Astrobotic product value; integrated mission manifest remains separate. |
| FLIP payload capacity | 30 kg | Public Astrolab/Astrobotic value; exact payload mounting ICD remains open. |
| FLIP vehicle mass | nearly 500 kg | Public class statement; the 450 kg dynamic mass is a study proxy. |
| Ramp count | 2 side ramps | Public Griffin option; geometry and mechanism remain a simulation prototype. |
| Ramp clear envelope | 12 m | Contact-study geometry surrogate. |
| Ramp command limit | ±0.58 rad | Control surrogate, not released mechanical data. |
| Lander geometry, dry mass, propellant, inertia, thrust | `TBD` / inherited surrogate | Replace with source-backed Griffin data when available. Seven main engines, four legs, and four propellant tanks are source-backed counts. |

## Executable Twin checks

The Twin owns the Griffin-specific requirement intent in
`twins/astrobotic-griffin-1/requirements/griffin_requirements.sysml`. Rhai
(`tools/griffin_requirements.rhai`, with the compatibility projection in
`tools/griffin_spec.rhai`) remains the executable test and verdict backend. The
reviewable architecture and the complete active/planned check catalog live
under `twins/astrobotic-griffin-1/contracts/`. It is deliberately separate from
the generic simulator `RunLint` rules: the generic linter reports
USD-wide authoring facts, while this library knows that this Twin requires 625
kg, four functional legs, two ramps, and the named Griffin interfaces.

The structural test fixture is
`twins/astrobotic-griffin-1/tests/griffin_requirements.usda`, with its Rhai
observer at `scenarios/tests/griffin_requirements.rhai`. It composes only the
Griffin wrapper, so terrain, FLIP, guidance, and release timing cannot hide a
model-contract failure. Before those USD assertions, the Rhai observer runs the
compact `ValidateSysml` query against the SysML source and requires the
`Verify_GriffinRequirements` case. It checks:

- the 625 kg capacity declaration and the exact pass/fail payload boundary;
- exactly four visible `LegPX/NX/PZ/NZ` bodies, their struts, and foot-pad colliders;
- two ramp bodies, their three contact surfaces/rails, and both revolute hinges;
- deck, adapter, propulsion, power, collision, status, and provenance metadata;
- every manifest part, including required geometry and known parameter bounds;
- exact solar-panel count and signed-side symmetry;
- ramp count, mirrored placement, transform/angle consistency, and leg attachment layout;
- hull/upper-deck primitive shape and suppression of inherited comparison geometry;
- the missing/hidden nozzle contract (`GR-015`), until a real bell is authored;
- the ±0.58 rad command limiter at its accepted boundary and just above it.

The contract catalog also records the checks that are not yet executable with
the current generic query seam: support-polygon stability, finite mass
properties, pad/ramp contact continuity, panel clearance, nozzle/flame
alignment, and complete electrical/thermal interface resolution. Those remain
planned acceptance work and are not counted as passing by the active fixture.

Run it against the already-built production binary after model edits:

    /home/rod/Documents/luncosim-workspace/main/target/debug/luncosim test --scene /home/rod/Documents/models/lunar-base-model/twins/astrobotic-griffin-1/tests/griffin_requirements.usda --max-ticks 120 --tick-hz 60 --threads 1 --jitter 0 --verdict-channel GRIFFIN_REQUIREMENTS

For the headful Editor, use the same library against the open document instead
of closing or reloading it:

    griffin_requirements::lint_live(doc_id, "/Griffin1")
    griffin_requirements::part_report_live(doc_id, "/Griffin1")
    griffin_requirements::layout_report_live(doc_id, "/Griffin1")
    griffin_requirements::payload_limit_live(doc_id, "/Griffin1", payload_kg)
    griffin_requirements::apply_ramp_deployment(doc_id, "@root@", "/Griffin1", ramp_path, angle_rad, parent_gen)

`apply_ramp_deployment` rejects an out-of-limit command before dispatching a
typed `ApplyUsdOps` change set. After the document projection advances, call
`lint_live` again; the document remains open and the edit is still undoable.
Saving is a separate approval step.

## Joint and release contract

Every moving Griffin part must have a separate rigid body and a named joint.
For each ramp record:

- parent body and ramp body;
- revolute hinge axis and datum;
- stowed pose, deployed pose, angular limit, and actuator/lock behavior;
- physical collision/contact surfaces;
- the runtime event that makes the ramp available for egress.

For the FLIP adapter record the fixed-joint parent/child bodies, mount datum,
release event, and post-release ownership. A scene hierarchy does not replace a
joint. The current integration boundary is: fixed adapter during descent,
touchdown, both ramps deployed, then interactive adapter release.

## Ramp-egress reference

**Visual reference supplied by the user:** [YouTube Short](https://www.youtube.com/shorts/BIpNcboh7aY).
The Short could not be retrieved in the current environment, so its exact
dimensions and timing are not treated as verified facts.

The creation contract is based on the Griffin/VIPER egress test pattern
documented by NASA:

1. Land and settle; keep FLIP restrained by the adapter.
2. Deploy the two folding side ramps.
3. Verify ramp clearance, contact-surface continuity, and correct wheel
   engagement before releasing the adapter.
4. Release the adapter at the authored post-touchdown boundary.
5. Drive FLIP down the ramps under low-speed traction/steering control; allow
   for one ramp being steeper than the other and compensate for pitch/roll.
6. Confirm all wheels clear the ramps before enabling the base-site route.

NASA’s public VIPER technical information gives a 30° total egress-ramp angle
limit with respect to lunar gravity, including deformation, local terrain
slope, and lander deck attitude; use it as a reference bound, not as a Griffin
flight ICD. The current 12 m envelope and ±0.58 rad command remain project
proxies.

## Public facts versus project assumptions

Public material does not provide a complete Griffin mechanical ICD, final
landing coordinates, or full FLIP vehicle geometry. Keep the existing source
and assumption records authoritative for citations, but copy any
creation-critical result into this requirements record with a status and date.
Do not present the four-leg wrapper, two ramps, 625 kg payload class, ramp
envelope, or FLIP four-wheel proxy as flight facts.

## Sources and implementation records

- `https://www.nasa.gov/centers-and-facilities/ames/nasas-moon-rover-prototype-conquers-steep-scary-lander-exit-test/` — clearance, wheel engagement, and pitch/roll egress testing.
- `https://www.nasa.gov/image-article/off-ramps-moon/` — two folding ramps and Griffin egress context.
- `https://assets.science.nasa.gov/content/dam/science/psd/lunar-science/documents/VIPER_Technical_Information_AFPP.pdf` — public egress-ramp angle bound.
- `twins/astrobotic-griffin-1/research/griffin_1_assumptions.md` — current
  fact/assumption boundary and source list.
- `twins/astrobotic-griffin-1/vehicles/griffin_1.usda` — lander wrapper.
- `twins/astrobotic-griffin-1/scenes/griffin_1_surface_ops.usda` — payload
  adapter, ramps, release, and mission composition.
- `twins/astrobotic-griffin-1/handover.md` — validated integration boundary
  and known limitations.
