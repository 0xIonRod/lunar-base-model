# Griffin tank support surfaces

Live Editor API49746 authored two shared UsdPreviewSurface networks and fifteen
material bindings in griffin_bus_visual. Operations used the existing generic
source-driven material planner, 14 frame operations and 32 collar operations,
in bounded document-generation batches. PhysicsCollisionAPI was preserved.
No geometry, collision, mass, tank station or Modelica parameter changed.
GBC011 and griffin-size-evidence record the existing finish source and explicit
artistic rationale. No new tool, shader implementation or test suite was added.

After saving, the vehicle was reopened as document115587894790448, view29,
projection generation0 ready, with17 recipe layers. Composed readback resolved
TankFrame and TankCollars under /Griffin1/Bus/Looks, with sourced colors,
metallic .75 and roughness .42. Review image:
/tmp/griffin-support-finish-review.png. The visual difference is modest in this
preview lighting; this is material ownership evidence, not a claim of complete
photorealism. The full assembly remains focused in the owned Editor.

Production bus fixture PASS: /tmp/griffin-support-finish-bus-gate.log,
source revision14416739560136011407, 28ticks, 60Hz, single thread,
seed6840157149251759617. This fixture covers existing bus geometry; material
binding evidence is the separate composed readback and screenshot. Requirement
source catalogue passes207targets/207records/47sources/3roles. Landing and FLIP
egress acceptance remain open.
