# Griffin lower-bus presentation contract

The appearance baseline is the 15 June 2026 integration hardware, viewed in
[Astrobotic's front photograph](https://www.astrobotic.com/wp-content/uploads/2026/06/26.06.15_Griffin-1_PressConference_1348_Edit-scaled.jpg)
and [NASA's gallery](https://www.nasa.gov/gallery/astrobotics-griffin-1/),
accessed 21 October 2026. Below the photovoltaic faces, the photographs show
rounded wrapped-tank contours and exposed support members. A continuous flat
polygonal belt is not supported by those views. Occluded components and the
black panels are not assigned new mechanical identities from appearance alone.
The photographed black handling stand and wheeled cart are ground equipment.

The bus component owns its structural presentation, payload supports and
shared blanket material template in `components/lander/griffin_bus_visual.usda`.
The assembly separately references four tank components, the engine-bay
blanket and the three photovoltaic faces. The bus uses SI metres and Y-up,
with its existing local origin and assembly mount. Its revised 4.50 m span and 0.72 m
internal-frame height remain unqualified packaging estimates. They do not
represent measured flight dimensions or an exterior blanket envelope. The
[22 October packaging correction](griffin-integrated-packaging-review.md)
supersedes the earlier 3.60 m span and regenerates the wider deck collision
beams and frame attachments, while retaining the inner tank module.

GBC-009 requires the complete source-enumerated structural inventory, together
with the independent frame/deck/support geometry requirements. The component
has 17 structural/presentation children and eight source-named frame posts.
An assembly may additionally declare empty Xform socket frames through
`lunco:mount:sockets`; each must carry `LunCoMountSocketAPI`. Other extra
children fail the inventory gate. The two-part medium-gain antenna mounts directly at the frame envelope; its
bracket provides the stand-off. The gold blanket palette remains a user display
preference. Its actual consumer is the separate engine-bay component through
the existing USD material reference, alongside the separately owned tank foil.
No blanket thickness, thermal law or flight optical coefficient is inferred.

Authored USD edits use the exact bus document and grouped typed operations.
The component checkpoint compares its complete child inventory and previews
the composed vehicle. A temporary extra child must fail that same inventory
gate; undo must restore it. The complete bus gate also checks payload support
interfaces, material inputs, frame/deck geometry and tank-opening clearance.
The original 21 October presentation pass did not alter mass, collision, hinge limits or any
Modelica equation. The existing structural collision envelope is a coarse
proxy and does not provide exact open-bay contact behavior.

Production verification on 21 October 2026: the separately opened vehicle
composes 27 bus children (25 component children plus two declared ramp sockets).
The complete bus observer passes 257 checks. The two-check open-bay observer
passes, rejects a journaled extra Cube, and passes after undo. The component
preview and complete assembled vehicle were inspected in Editor Perspective.
This qualifies the lower-bus presentation and its assembly interfaces; it does
not qualify hidden hardware dimensions, ramp poses or performance targets.

The complete powered-vehicle verification fixture references the shared
`environments/lunar_surface_base.usda` preamble. It supplies the physical Sun
source and lunar gravity required by the connected solar-power network. Without
that environment, initial solar observations are unavailable and the fixture
cannot certify its coupled initialization. The integrated bus gate passes all
257 checks with zero pending readiness tickets and a ready co-simulation topology.

The mapped `Verify_GriffinBusOpenBays` case uses
`tests/griffin_bus_open_bays.usda`. It preserves that same vehicle and environment
and explicitly mounts the open-bay observer, which emits `GRIFFIN_BUS_OPEN_BAYS`.
The registry-driven case passes both checks with the requested source revision
at run start and end. The general bus fixture remains mapped to its own bus
requirements observer and verdict channel.

The subsequent formal-acceptance audit replaces the bus identity, physics
ownership and provenance-link-only checks with three source-declared
constraints (GBC-001, GBC-003, GBC-004). The updated gate passes 254 checks.
`tests/check_bus_failure_rejection.py` then authors disposable USD forks through
the live document API. The production observer rejects all three injected
faults: collision enabled on a nested tank collar, an extra mass owner on that
collar, and an invisible top deck. Each produces exit 1 and the exact expected
typed failing constraint; fixture-admission errors and timeouts do not count.
All three runs use source revision `8817007894596470783` and binary SHA-256
`39f60840b5ea0412f5eb3aabc0769d1ceb57e671050ad563f3674ec62962834c`.
The full receipts and typed failures are retained under
`.cache/bus-failure-qualification/results.json`; disposable layers are removed.

From the Twin root, with an owned windowed authoring session and a free test
port:

```sh
python3 tests/check_bus_failure_rejection.py --engine /path/to/lunco-sim --author-port 4291 --test-port 4294
```
