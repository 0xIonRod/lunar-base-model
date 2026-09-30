# Griffin bus, tank and engine packaging

The ramp stock refinement is committed as `bafb82e`; support datum and cooked-hull correction as `a7e9881`. Subsequent work replaces the oversized central adapter shells, seats tank interfaces from consistent frame datums, and makes clearances explicit in SysML and the component gates.

The final installed tank diameter is 1.008 m; center Y is 1.39 m. The minimum diameter is a 1.00 m packing estimate, replacing the stale 1.51 m bound from the abandoned larger assembly. The upper cap has 14 mm clearance beneath the FLIP payload frame; the gate requires 10 mm. Upper adapter-to-tank-band radial clearance is 64 mm, and lower adapter-to-peripheral-bell clearance is 70 mm. These dimensions are reconstruction assumptions, not released supplier CAD. Exact rationale and primary references are in `requirements/griffin-size-evidence.md` and the affected SysML requirements.

The lower cradle seats from the service-skirt bottom datum plus its source clearance. The post has a positive 40 mm component-local span, scaled once at installation. The shared `griffin_geometry::tank_brace_datum` accounts for the actual mirrored rotation when seating brace feet on the pad and deriving vessel contact. The tank gate uses the shared geometry dependency contract, avoiding a duplicate dependency map.

Fresh production fixtures passed:

- Tank geometry and payload clearance: 536 checks (`/tmp/griffin-tank-payload-clearance-gate.log`).
- Bus geometry, adapter profiles and clearances: 353 checks (`/tmp/griffin-final-bus-clearance-gate.log`).
- Five-engine geometry and dataflow: 115 checks (`/tmp/griffin-compact-adapter-engine-gate.log`).
- Deployed ramp interface: 845 checks (`/tmp/griffin-final-packing-ramp-gate.log`).
- Source catalog: 207 typed targets / 207 evidence records / 46 source elements / 3 roles.

These are component/assembly geometry checks, not landing or flight qualification. The payload collider remains a documented convex-envelope approximation that fills internal gaps. RCS presentation integration remains deferred. Further refinement should inspect engine-skirt mounting hardware and the bus thermal/radiator treatment against the PGH hardware photograph, without treating the launch adapter as a central engine bell.

Owned review API is 49746. This work did not operate the session on 4113. The installed main binary identifies itself as `3b2cd195`; it predates the new smoothing operation field. Existing smooth bell geometry is retained. New adapter profiles use the supported flat-shaded revolve operation, appropriate for the eight-sided shells. Do not claim that this binary verifies the latest core build.

A fresh static Editor session rendered the saved vehicle at document/projected generation 0. [Review image](griffin-bus-tank-packing-review-2026-09-30.png) confirms removal of the detached upper shell and preserves the slim ramp members. The payload frame still obscures much of the domes from this camera; taller tanks would require revising that interface, not merely raising the tank instances. Engine-skirt hardware and thermal presentation remain further visual work.
