# Assumptions, Conflicts, and Open Gaps

## Snapshot and confidence

- Research was checked against public sources on **2026-08-22**.
- `High` confidence means a current agency or provider page names the mission and gives a stable mission description.
- `Medium` confidence means the mission is officially described but its date, vehicle assignment, or payload is not fully fixed.
- `Low` confidence means a schedule is disputed, proposed, or dependent on an option or approval.

## Schedule conflicts

### Draper Mission 1 / CP-12

NASA's CLPS provider page still presents CP-12 as a 2026 Draper delivery to Schrödinger Basin using an ispace-U.S. APEX 1.0 lander. ispace's 2026 schedule update says the revised execution is proposed as Mission 5 in 2030 and is pending NASA approval. The mission register keeps one record with both values rather than double-counting it.

### Blue Ghost Mission 2

Older NASA CLPS materials place the mission in 2026, while Firefly's current mission page says no earlier than 2027. The register uses Firefly's current provider date and retains the older discrepancy only as a source-history issue.

### Chang'e 8

CNSA sources describe the mission as around 2028 in one update and around 2029 in another. The register uses `2028–2029` and medium confidence.

### VIPER

NASA announced the standalone VIPER project would be discontinued in 2024, but the current Moon Base architecture page describes a late-2027 delivery through Blue Origin's second Blue Moon MK1 lander. The register marks the delivery as conditional rather than treating it as an unconditional launch.

## Modeling decisions

- Artemis III is modeled as a lunar-program mission with a low-Earth-orbit demonstration objective under the current NASA architecture; it is not modeled as a lunar surface landing.
- Lunar Pathfinder is modeled as an orbital relay asset attached to Blue Ghost Mission 2, not as an independent landing mission.
- Moonlight is modeled as a constellation/program, not as one spacecraft or one landing.
- Lunar Terrain Vehicles are modeled as surface assets delivered by a future mission; their vehicle identities are known before their final delivery mission is.
- The additional Moon Base/CLPS landing cadence is represented by a placeholder record because NASA has not published names and complete manifests for all of the promised missions.
- `TBD` is a valid data value. It is preferable to inventing a launch vehicle, coordinate, payload, or landing ellipse.

## Missing information for the next research pass

1. Exact launch vehicle, launch site, and launch window for each commercial lander.
2. Landing coordinates, landing ellipses, and local digital-elevation models.
3. Surface power, thermal-survival, and lunar-night plans for each lander and rover.
4. Detailed payload manifests for Chang’e 7/8, Chandrayaan-4, Artemis IV/V, and the unnamed CLPS deliveries.
5. Orbital state vectors, transfer trajectories, and relay-link budgets for CAPSTONE 02, Altus-1, Lunar Pathfinder, LASSO, and Moonlight.
6. Mission-level relationships between each lander delivery and the CLV-1/Pegasus vehicles.

## Source interpretation

The research uses current primary sources wherever available. Secondary reporting may be useful for discovery, but a mission should not be promoted to `high` confidence without a current agency, provider, or mission-owner source.
