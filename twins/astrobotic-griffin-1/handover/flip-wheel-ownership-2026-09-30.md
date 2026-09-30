# FLIP wheel geometry ownership

FLIP had four wheel stations but two tire surfaces per station: the shared physical wheel Cylinder and a second authored `Visual/Tire` Cylinder. The simulator already transfers the first mesh to a runtime render child and drives that child from wheel state. The extra authored tire subtree bypassed that presentation owner.

The vehicle now keeps one wheel Cylinder per station, with the existing radius, width, dynamics ports, tire selection and material. The redundant component and its four references are removed. The shared wheel material provides tread, rim and hub appearance. `purpose = default` makes the same source geometry available to rendering and contact. Source dimensions remain estimates; no supplier dimension was inferred from this cleanup.

The simulator change is local terrain commit `2af4e4c5d`. Raycast animation preserves the USD-projected mesh rest orientation and spins around its axle. In-place parameter resynchronization re-reads the rest pose with the same transform, stage-convention and primitive-axis readers used by rendering. The shared Rhai numeric predicate also recognizes the engine's `i64` collection lengths; string counts remain rejected.

Validation:

- `cargo test -p lunco-mobility --lib wheel_spin`: 3 passed. The system regression covers X/Y/Z axles, zero-spin rest pose, additional local rotation, steering, and spinning tread with an unchanged cap normal.
- `cargo test -p lunco-usd-sim --lib raycast_tests`: 3 passed.
- Production `cargo build -p lunco-luncosim --bin luncosim`: passed.
- Fresh production API evaluation of `tests/flip_wheel_requirements.usda`: 73/73 passed, source revision 16047434418901459304. Includes source dimensions, no extra Visual subtree, material binding and inboard suspension-arm alignment.
- Exact Griffin/FLIP presentation scene: seven batches, 112/112 checks passed.
- Fresh Editor preview of `vehicles/flip.usda`, generation 0, projection ready: inspected. Screenshot: `flip-single-wheel-owner-review-2026-09-30.png`. Composed scene readback confirms four active Cylinder stations, radius 0.45 m, width 0.28 m and Z axle, without a Visual tire subtree.
- Repository structure validation passed. The requirement-source completeness script still reports pre-existing missing evidence records for GLL-010 and GR-039; this work does not qualify overall requirement completeness.

The production geometry check was invoked through the API independently of physics time. The standalone fixture reports a missing DirectionalLight; no full rover driving, wheel-ground rolling or mission acceptance is claimed. The Editor screenshot is geometry evidence, not a motion test. Griffin legs, skirt and engine bells remain separate unfinished modeling work.

No remote push was performed.
