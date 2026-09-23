# Griffin verification boundary

The SysML requirement packages own normative identities, requirement text,
study limits, and formal `require` constraint memberships. Verification cases
own `verify` relationships inside their `objective` blocks. USD supplies the
realized assembly; Modelica supplies continuous equations; Rhai selects those
providers, samples observations, orchestrates runs, and formats evidence. The
shared Rust/Rhai evaluator executes the supported scalar constraint subset.

## Current executable slice

- Payload capacity, ramp deployment range, bus and tank geometric checks, and
  FLIP suspension rest length now use reusable SysML constraints linked to
  their owning requirements.
- The generic evaluator resolves requirement identity and accepts only a
  matching `require` membership. `assume` is preserved in source projection
  but cannot satisfy an acceptance check. Results preserve `pass`, `fail`,
  `inconclusive`, and `error` with source revision and constraint fingerprint.
- The authored requirement-check catalog and Planned/mission/process
  groupings are implementation metadata, not a runtime invocation trace.
  Current evidence consists of the structural and layout reports, per-part
  observations, provenance record, and explicit payload/ramp constraint
  boundary evaluations. Those checks do not cover all requirements listed by
  `Verify_GriffinRequirements`.
- Rhai still measures composed USD mesh topology, extents, face winding,
  material properties, child presence, and live physics/mission telemetry.
  These measurements are provider observations; their geometry extraction,
  frame conversion, temporal sampling, and collection reductions are not yet a
  generic Rust provider surface.
- The ramp geometry is owned by the replaceable Twin component and its SysML
  child inventory. FLIP remains a separately sourced and loaded component.

## Geometry migration status

The physical top deck uses eight hidden convex beam colliders following the
SysML octagonal profile, and the central rover platform has a separate
geometry-derived collider. Composed Editor readback passed profile, topology,
and source-deviation checks. The render ramp uses two FLIP-aligned
wheel tracks with an open centre, using the same wheel stations and track-width
datum as the physical contact geometry.

GRR-012 remains inconclusive because the generic typed USD provider does not
yet expose the composed transition contact overlap. The 1.05 m SysML study
datum bridges the 2.20 m payload-deck half-width to the 3.20 m hinge with 0.05 m
overlap, but it is not acceptance evidence until the transition and wheel
contact envelope are observed together. The separate octagonal tank-support
perimeter remains distinct from the outer deck collider.

## Remaining acceptance boundary

1. Promote mesh, transform, material, and physics observations into generic
   typed USD providers. Rhai should choose a SysML feature and provider target,
   not reconstruct a geometric verdict from path strings and arrays.
2. Add resolved SysML feature navigation, constraint invocation/bindings,
   collection/index/aggregate operations, and quantity/unit/frame validation.
3. Map dynamic-body mass, center of mass, inertia, collider ownership,
   contacts, and solver state to typed provider facts. Keep unavailable or
   stale samples inconclusive.
4. Model configuration and temporal applicability in source before treating
   a landing, ramp, detach, or FLIP egress run as acceptance evidence.
5. Capture a source revision, composed document generation, physics run
   configuration, observation time/frame, and evidence artifact identity in a
   single result package.

The full gap inventory and migration order are in
[`implementation_gaps.md`](implementation_gaps.md). A structural pass does not
qualify landing dynamics, structural loads, propulsion, or FLIP egress.
