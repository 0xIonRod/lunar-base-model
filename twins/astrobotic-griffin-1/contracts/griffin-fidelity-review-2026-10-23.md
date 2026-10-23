# Griffin size, ramp and RCS review — 23 October 2026

The reference configuration remains Astrobotic's June 2026 integration hardware, with the separately selected gold presentation finish. Public images establish arrangement, not calibrated flight dimensions. The 2023 NASA prototype and 2021 concept images describe earlier egress work. Their geometry must not silently become a current flight ICD.

## Scale audit

| Native/source datum | Current reconstruction | Interpretation |
| --- | ---: | --- |
| Bus span across broad faces | 4.50 m | Estimated bus envelope; historical 4.5 m overall labels do not establish this current flight dimension. |
| Perimeter deck span | 4.40 m | Source-owned fit inside bus. |
| Lower inner frame span / height | 3.60 / 0.72 m | Retained tank module, connected to the wider perimeter by radial links. It is an inner structure, not the exterior width. |
| Wrapped tank diameter | 1.008 m | 1.68 m component diameter at 0.60 assembly scale; provisional. |
| Payload walking plane | 2.12 m above lander root | Approximately 2.56 m above the nominal flat touchdown datum; actual landed plane follows the body pose. |
| Three array faces | 1.866 m nominal face width | Facet stations and cutouts follow the assembly contract; not a 5.598 m flat wall. |
| Landing foot envelope | approximately 6.07 m | Cardinal foot reach plus pad radius, not bus width. |
| FLIP tire diameter | 0.93 m | Vendor-based wheel scale; about 21% of bus width. |
| FLIP longitudinal wheel envelope / width | 2.23 / 2.28 m | Compact study reconstruction; about half the bus span. |
| Extended ramp length | 5.397 m | Sum of 2.149 m root, 1.449 m middle and 1.799 m toe. Derived from the walking-plane study. |

This audit does not support another uniform scale increase. The model already has a 4.50 m bus, distinct from its retained 3.60 m inner tank frame. Increasing every part would also enlarge the source-based wheels, legs and ramp geometry. Absolute bus/deck height and current flight envelope remain unqualified. No rover dimensions or vehicle-wide scaling were changed in this review.

## Terrain annotations

The route is frozen in the landed port exit frame. Previously only X/Z were transformed; Y stayed zero. A yawed landing therefore moved the markers over different DEM heights while retaining the wrong elevation. `surface_route_target` now queries the retained terrain at the transformed X/Z and rejects missing terrain. Ground annotations sit 50 mm above that surface. The first marker sits above the measured payload walking plane, using its actual position and normal. Authored reference-scene markers also use sampled DEM heights. Presentation uses transient view edits; it preserves authored route identities and horizontal coordinates.

## Independent ramp tracks

[NASA's 2023 egress report](https://www.nasa.gov/centers-and-facilities/ames/nasas-moon-rover-prototype-conquers-steep-scary-lander-exit-test/) explicitly includes one ramp being steeper than the other. This supports independent terrain accommodation; it does not identify the current flight hinge or deployment actuator design. The former rigid pairing forced both tire lanes to share one pitch target.

The installed reconstruction uses four wheel tracks, each with independent root, middle and toe hinges. Six small USD adapters reference the qualified full-bank stock, deactivate the opposite half and recenter the selected half; the mesh definitions remain in their existing component owners. Local guide pivots remain outside the tire paths. Root shafts belong to the bus; intermediate cross-track shafts are omitted so they do not reconnect independently rotating tracks.

Each bank retains 95 kg moving mass. Each of six track sections receives one sixth of that bank mass. Per-track stiffness, damping and effort are half the previous paired-bank values, preserving aggregate pitch authority. Inertia uses each actual section span and the 0.592 m track envelope. These are explicit thin-plate estimates, not measured inertia or flight motor laws. Adjacent-joint exclusions and the existing fixed transition interface exclusion remain; nonadjacent contact is not suppressed.

Opening preserves the measured sequence: folded root clearance, middle extension, opposite toe extension, then root lowering. Each root fits its own four toe corners against the retained DEM. Release requires all twelve hinges to meet the existing angle, rate and dwell gates. A missing terrain sample or unbracketed target rejects deployment.

## RCS mounting

Agile's [2023 delivery report](https://agilespaceindustries.com/press/2023-year-in-review) identifies A110 flight units delivered for Griffin. The [A110 data sheet](https://static1.squarespace.com/static/634ee7b32099c80fdfcc8cac/t/6418ea80e1144560207215ca/1679505951405/AgileSpace_A110SpecDoc.pdf) gives 111.2 N nominal thrust and a 60.96 mm exit diameter. Those nozzle values were already present.

The presentation defect was four large flat shelves, with upward, downward and horizontal chambers lacking matching supports. Each corner now has a short deck shoe, an inboard spine and three chamber-specific saddle/ring mounts. The native nozzle frames determine their centers and axes. Rings have open bores; saddles approach radially. Horizontal jets receive a separate axial stay so the saddle stock remains outside the chamber bore. Mounts are render-only and do not introduce artificial inertia, contacts or force owners. All twelve actuator frames, directions and ratings compare exactly with the pre-edit native snapshot. Cluster topology and bracket dimensions remain reconstruction assumptions; public A110 data does not establish Griffin's flight mounting ICD.

## Qualification record

The final production files pass all **199 checks** in fresh normal-runtime processes:

| Case | Checks |
| --- | ---: |
| Independent track references, exact body bindings, mass, mount interfaces, 26 joint/latch/transition frames | 54 |
| Flight stow, mirrored axes and active-guide/leg clearance | 40 |
| Nominal mitered toe geometry | 16 |
| Production descent, ordered deployment, all-hinge settlement, projected waypoint readback and missing-terrain rejection | 43 |
| Six signed RCS commands, propellant flow, and native clamp/support/bore geometry | 31 |
| Solar-panel stock contact and open cutouts | 15 |

The RCS observation measures installed ring vertices and the closest projected point on every saddle-stock edge. It rejects the earlier slanted saddle geometry at eight vertical jets; the corrected radial approach passes all twelve. A separate 100 mm clamp displacement was also rejected. Native pre/post snapshots confirm that all twelve actuator frames, directions and ratings are unchanged.

Validation used the existing normal UI artifact `3ebc93a7-dirty`, SHA-256 `6fb5f3596919d4ba9d675d71b4b4163d3a37b4129d9dfa5281b5cc12cbb3d248`, with the tutorials shared assets, fixed 60 Hz, one Compute thread, zero jitter and standard physics substeps. No engine, solver or dependency source changed. Windowed manual opening also reached all twelve measured goals. The 60 FPS real-time target, complete loaded rover traversal and flight dimensional qualification remain separate open acceptance items.

Local logs, native snapshots and `production-final-gates.json` are under `usd/.cache/codex-evidence/griffin-fidelity-20261023/` in the linked engine workspace. Temporary vehicle/test candidates were archived byte-for-byte under this Twin's ignored `.cache/fidelity-candidates-20261023/`; the production references resolve to `vehicles/griffin_1.usda`. The authoring owners are `tools/griffin_ramp_tracks.rhai` and `tools/griffin_rcs_mounts.rhai`.

The portable [qualification receipt](../handover/griffin-fidelity-2026-10-23.json) includes source hashes, six verdicts and windowed hinge measurements. The captures show the [deployed assembly](../handover/griffin-fidelity-2026-10-23-deployed.png) and an [RCS clamp/saddle detail](../handover/griffin-fidelity-2026-10-23-rcs-detail.png); the latter is a neutral source inspection, not a flight photograph.
