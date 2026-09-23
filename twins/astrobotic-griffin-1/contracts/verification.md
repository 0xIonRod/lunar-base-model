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
- The old standalone ramp assembly and custom component assertion bridge have
  been removed. FLIP remains a separately sourced and loaded Twin component.

## Active geometry migration

The bus visual source and tank-support perimeter are octagonal. The physical
`TopDeckCollisionProxy` is a different object: its current six-sided footprint
is misaligned with the chosen octagonal deck requirement. The 1.21 m transition
and +/-3.16 m deck edge are legacy measurements from that footprint, not
acceptance values. GRR-012 now requires typed observations for the composed
transition overlap, required geometric overlap, and octagonal profile
compatibility. Those observations are unavailable, so its verdict must remain
inconclusive until the collider is re-authored through the typed Editor path,
read back, and used to recompute the ramp-to-deck contact, hinge gap, transition
length, and FLIP wheel path. The tank-support perimeter remains octagonal
throughout; it is not the collision proxy.

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
