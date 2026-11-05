# FLIP Rover v5 Visual Review Twin

This Twin opens the latest FLIP v5 CAD as a visual-only asset in LunCoSim. The canonical CAD export remains `freecad/flip_rover_v5/FLIP_rover_v5.usdc`; LunCoSim's current document importer does not read binary USDC roots, so the scene mounts a GLB translation of that export. The GLB retains the USD stage's Y-up, metre coordinates and mesh geometry.

- Source USD: `../../freecad/flip_rover_v5/FLIP_rover_v5.usdc`
- Source SHA-256: `5fdc36abe1d083c49932b51d15c7968b0d9f8dfcde7d3a84d43d59fe81d1a151`
- Display asset: `visuals/FLIP_rover_v5.glb` (195 meshes, 12 materials)
- GLB SHA-256: `58a222e7adac01d6f7ef33993f3a791f85d8a5e968c1a038a1944ec5324ad4ff`
- Geometry dimensions in the export: approximately 2.332 x 2.634 x 2.630 m.

This review Twin intentionally contains no physics body, collision geometry, mass properties, joints, controls, Modelica models, or behaviors. Those need to be authored separately from requirements and validated data; the visual asset alone does not define them.
