# Griffin hollow engine throat

Both flow shells now use the existing native RevolveProfileMesh mechanism.
The previously solid Throat Cylinder intruded into the bell and closed its bore.
The replacement is a 160 mm hollow neck with the same estimated 6 mm visual
wall. Lower rim derives from bell height/2=.26 m; centre=.34 m, upper rim=.42 m.
The existing adapter placement relationship moves its lower face to that upper
rim. Radius, height and wall remain explicitly unqualified reconstruction
estimates. NASA nozzle-design reference supports the flow-path topology, not
these supplier dimensions:
https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/nozzle-design/

Normal shading on both parts reuses Nozzle_Mat inherited from the shared
rocket_engine_visual library. No duplicate shader graphs, flames, extra physics
actors or optical engineering properties were added. The Bell prim's existing
inspection displayColor is now source-owned in the propulsion package with
an explicit artistic rationale. The generic material planner requests only
needed type/schema facts, avoiding an oversized full mesh payload.

GPP006 now binds actual throat mesh radius/height/centre/bore observations into
its existing typed conformance constraint; the former three scalar Cylinder
checks were replaced. Adapter fit reads the mesh upper rim. Final production
fixture passed at /tmp/griffin-hollow-nozzle-final-gate.log, 12 ticks at 60 Hz,
single thread, deterministic seed. Source catalogue and diff checks passed.
No flight propulsion performance, landing or rover traversal acceptance follows.

Owned Editor API remains 49746, terrain assets, installed optimization binary.
Component projection 115585610722374, view 26, projection ready. Component image:
/tmp/griffin-hollow-nozzle-component.png. Earlier complete vehicle underside
image: /tmp/griffin-metal-nozzle-underside.png. Both are shallow underside views;
the nozzle mouth still reads flat. A steep bore view and realistic lighting
remain required visual evidence. The Editor preview DirectionalLight currently
sets shadow_maps_enabled=false in lunco-usd-viewport-runtime/src/lib.rs;
do not label a raw topology pass as successful rendered nozzle acceptance.

Rail stages were separately committed as 88cfe70 and 8385d77. The active Griffin
landing/FLIP goal remains incomplete; continue visual refinement, preserving
source/estimate rationale and periodic commits. RCS requirements remain deferred.

## Follow-up: direct bore visual evidence

The isolated component was inspected on 2026-10-01 in the same owned Editor.
A temporary, unsaved root rotation (-55, 0, 35) degrees brought the bore toward
view 26's existing underside camera. At projected generation 2, projection_ready
was true and the two-layer composed component rendered a continuous curved
inner bell, thin exit rim and visibly open throat. Screenshot:
/tmp/griffin-bore-inspection.png. This resolves the apparent solid exit in the
previous shallow view; no cap, fake dark disc or geometry distortion was added.
The image still lacks cavity self-shadowing under the current preview lights.

Both temporary root attributes were removed through ApplyUsdOps. Generation 4
was projection-ready; QueryUsdPrim reported no rotateXYZ or xformOpOrder on
/EngineBell, with world position (0,0,0). SaveDocument restored the unchanged
source; the complete vehicle was left focused. This proves the visible isolated
flow path, not propulsion operation or full lander lighting acceptance.
