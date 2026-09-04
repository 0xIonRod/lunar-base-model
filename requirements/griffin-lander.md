# Griffin Lander requirements

**Last updated:** 2026-09-04
**Scope:** Griffin-1 lander packaging, payload integration, ramp deployment,
and the FLIP surface-operations handoff.
**Boundary:** Geometry and numeric values marked as proxies are MoonDAO/LunCoSim
study inputs, not a released Griffin mechanical ICD.

## Requirements

| ID | Requirement | Status | Creation / acceptance note |
|---|---|---|---|
| GR-001 | Model a reusable Griffin lander body with four landing legs and a top payload deck. | MUST | Keep lander structure, deck, landing gear, propulsion, and power as separate subassemblies. |
| GR-002 | Provide a payload adapter that holds FLIP during descent. | MUST | The adapter is a physical fixed attachment during descent and releases only at the authored post-touchdown boundary. |
| GR-003 | Model two deployable side ramps with separate rigid bodies, physical contact surfaces, and explicit revolute joints. | MUST | The ramp joint, axis, limits, deployment state, and collision envelope must be inspectable and tested. |
| GR-004 | Preserve the surface sequence: landing → ramp deployment → adapter release → FLIP egress → base-site route. | MUST | Do not let FLIP consume the surface route while it remains fixed-joint cargo. |
| GR-005 | Keep all Griffin and FLIP integration values traceable as public fact, project requirement, study proxy, or `TBD`. | MUST | Update this record whenever scene, USD, CAD, or scenario behavior changes. |
| GR-006 | Treat Griffin solar arrays as separate visual/power subassemblies. | STUDY PROXY | Current Twin uses two side-mounted visual arrays; exact flight layout and electrical ICD remain open. |
| GR-007 | Model rover egress as a gated ramp operation, not a teleport from deck to terrain. | MUST | Ramp deployment and contact checks precede adapter release and rover drive commands. |
| GR-008 | Validate egress under nominal, high-pitch, uneven-roll, and combined pitch/roll lander attitudes. | MUST | Preserve wheel clearance, ramp engagement, traction, and a safe handoff to the surface route in each case. |

## Active study values

| Parameter | Active value | Status / provenance |
|---|---:|---|
| Mission | Astrobotic Griffin Mission One / NASA Moon Base II | Public mission identity. |
| Landing region | Nobile Crater area near the lunar South Pole | Public planning description; exact coordinates remain unresolved. |
| Primary rover payload | Astrolab FLIP | Public mission assignment. |
| Payload-class prototype | 625 kg | MoonDAO project requirement; explicitly not a public Griffin flight value. |
| Ramp count | 2 side ramps | Project requirement / simulation prototype. |
| Ramp clear envelope | 12 m | Contact-study geometry surrogate. |
| Ramp command limit | ±0.58 rad | Control surrogate, not released mechanical data. |
| Lander geometry, dry mass, propellant, inertia, thrust | `TBD` / inherited surrogate | Replace with source-backed Griffin data when available. |

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
