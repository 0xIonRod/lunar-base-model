# FLIP rover v5 delivery review

**Reviewed:** 2026-09-30<br>
**Native application:** FreeCAD 1.1.1<br>
**Model:** `FLIP_rover_v5.FCStd`<br>
**Saved model SHA-256:** `af57d7e22f943f39bc1380663888adb8d8b18d0d35fa93464c2e75f69e24285b`

## Measured native CAD state

The source baseline was the frozen v4 file `FLIP_rover_v4_input.FCStd` (SHA-256 `926d4b6952a0402d9903004c4b25c03829d550ae0af9bd162faa63b3525d286e`). The final v5 document was reopened, rendered, and checked with `audit_v5.py` in FreeCAD 1.1.1. The bounded audit passes its declared model-integrity checks: **195 visual features, zero invalid visual B-reps**, four wheel stations, exact study bounds for the chassis and both battery envelopes, 192 cable solids and 96 spring-detail solids per wheel, nominal 930 mm wheel diameter at all four stations, and a saved 82° panel study pose. The nine CAD pose samples each recompute with valid panel solids.

| Measured item | Saved v5 value | Meaning |
|---|---:|---|
| Wheel centers FL / FR / RL / RR | (-1000, 465, 850), (1000, 465, 850), (-1000, 465, -850), (1000, 465, -850) mm | Global X/Y/Z station datums; study values |
| Wheelbase / track | 1,700 / 2,000 mm | Derived from study station coordinates |
| Wheel band | 930 × 280 mm diameter × width | Diameter is public wheel-family information; width is study-only |
| Inner rim-face setback | 65 mm per side | Concentric axial recess inferred for this visual study from user image; not supplier dimension |
| Chassis assembly bounding box | 1,460 × 400 × 2,100 mm | X × Y × Z; excludes wheel and array bounds; study only |
| Each battery envelope | 305 × 220 × 884 mm | X × Y × Z; two separately named study envelopes; no assigned mass |
| Array backplate | 1,800 × 1,380 mm | Study only |
| Overall stowed bounds | 2,332 × 1,107 × 2,630 mm | X × Y × Z; measured at CAD pose 0° |
| Overall deployed bounds | 2,332 × 2,634.311 × 2,630 mm | X × Y × Z; measured at CAD pose 82° |

The saved v5 root transform converts the inherited v4 geometry into the stated global X-lateral/Y-up/+Z-forward frame. This is a CAD transform, not evidence that a LunCoSim exporter preserves it. The former exporter path named in the older handover is absent from this checkout, so no FreeCAD-to-USD/GLB asset export or round-trip check is claimed here.

## Requirement and evidence status

| Requirement group | Review result |
|---|---|
| Public-source facts versus study values | **Partial / documented.** Unit-typed source claims, measured v5 study dimensions, status/provenance and TBD values are in `requirements/flip-recreation.sysml`, `parameters_v5.json`, the FreeCAD spreadsheet, and `requirements/flip-rover.md`. |
| SysML structure and quantities | **Reviewed, not compiled.** Requirement/verification structure and `ISQ`/`SI` quantity types follow official SysML v2 examples. No project SysML parser/compiler is available in this checkout. |
| Wheel count, nominal diameter, detail counts | **Pass at visual-model integrity scope.** Four named stations; 930 mm wheel; 192 cable and 96 spring solids each. Detail geometry and layout remain visual-only/study. |
| Recessed inner rim | **Visual study implemented.** The face is concentric and axially inset 65 mm on both sides from the tire edge. The supplied photo does not give a measured offset or prove axle eccentricity. |
| Main silhouette, upright panel, cameras, two battery envelopes | **Partial.** Separate named pieces and image evidence exist. Chassis and panel shape are block-study geometry; complete flight packaging is unavailable publicly. |
| Solar-array articulation | **CAD pose samples pass shape recompute only.** The 0–90° controller is presentation-only; 82° deployed pose is not a flight deployment angle. Clearance is not evaluated. |
| Mass, centre of mass, inertia | **Open / not assigned in CAD.** The 450 kg public vehicle claim and 480 kg launch/space constraint are stored as distinct metadata; neither is used as solid-derived physical mass. |
| LunCoSim import, USD physics, Rust, Modelica, Rhai | **Not run.** The guide specifies the implementation and test sequence. The current checkout contains no runnable FreeCAD asset-export tool at the historical path and no current Twin runtime pass was produced. |
| Exact as-built match | **Not established and not possible from located public material.** No public dimensioned GA, native flight CAD or current flight ICD was found. |

`audit_v5.json` deliberately does not claim geometric collision/clearance verification. The former all-pairs OpenCascade intersection audit was computationally unbounded over the detailed wheel web and coil compounds; the replacement audit checks file/shape integrity, selected exact dimensions, detail counts and pose recomputes. Clearance, articulated mechanism contact, wheel dynamics, mass properties and performance need a dedicated physics/collision representation and runtime tests.

## Captures

- [`deployed.png`](deployed.png) — saved 82° study view.
- [`stowed.png`](stowed.png) — 0° study view.
- [`front.png`](front.png), [`side.png`](side.png), [`top.png`](top.png) — orthographic inspections.
- [`wheel_face.png`](wheel_face.png), [`wheel_oblique.png`](wheel_oblique.png) — wheel construction and inset study.
- [`hinge.png`](hinge.png), [`equipment_cutaway.png`](equipment_cutaway.png) — local component inspections.

Recreate the simulator assembly using [`LUNCO_SIM_RECREATION.md`](LUNCO_SIM_RECREATION.md). Public sources and their exact claim boundaries are in [`REFERENCES.md`](REFERENCES.md). The overall source review is [`research/flip_rover.md`](../../research/flip_rover.md).
