# Griffin appearance review — 2026-10-20

The requested bus finish is yellow-gold MLI. Its canonical owner is
`components/lander/griffin_bus_visual.usda`, with the palette and fold controls
in `GriffinVisualConfiguration`. Eight existing exterior facets share one
object-space foil material. Their SI geometry, local Y-up frame, collision
exclusion and mass ownership are unchanged. GBC-009 and GBC-012 and the mapped
bus gate check the composed geometry and source-owned material inputs.

The gold finish is a user-selected presentation estimate. The existing
[hardware photograph](https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png)
shows pale exterior blankets and gold seam tape. Neither a photograph nor an
RGB value establishes blanket construction, absorptivity or emissivity.

Solar review uses the existing three-panel polar configuration and its
source-owned cell contours, pitch, inter-cell gaps, mounting datums and frame.
The [Astrobotic payload guide](https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf)
describes side-mounted panels for polar missions and triple-junction solar
cells. Accessed 2026-10-20. Flight-cell reflectance and laminate dimensions are
not released in that guide; visual materials remain explicit estimates.

## Solar panel reconstruction

The [NASA June 15, 2026 gallery](https://www.nasa.gov/gallery/astrobotics-griffin-1/),
particularly the [1348 view](https://www.nasa.gov/image-detail/26-06-15-griffin-1-pressconference-1348-edit/)
and [1419 view](https://www.nasa.gov/image-detail/26-06-15-griffin-1-pressconference-1419-edit-2/),
shows three broad, differently cut panel faces. The reconstruction uses a
12-column by 24-row field before cutouts. The cardinal panel clears the landing
leg; the two mirrored side panels have stepped shoulders and equipment recesses.
The frame, backplane, substrate and individual cell rows follow the same contour.
The old rail-span width cap narrowed the corner panels incorrectly.

All three physical panels have separate canonical component assets, selected by
`GriffinSolarArrayAssembly::componentAssets`. Vehicle overrides own only the
mount poses and rail links. The retained 1.866 m frame width gives 150.5 mm
horizontal and 75.25 mm vertical pitch, with 30 mm frame stock. These SI values
are packaging estimates, not calibrated measurements. A 610 mm forward bank
placement and 900 mm mount-link stock reserve the ramp corridors; the native
solar geometry gate observes the actual composed frames, links and cell rows.

## Main engine and skirt sizing

The [current Astrobotic product page](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/)
confirms seven main engines. The [2021 engine selection release](https://www.astrobotic.com/astrobotic-selects-lander-engines-more-for-griffin-viper-mission/)
and January 2022 PUG describe **five** 700 lbf engines. The historical unit rating
is a provisional study input for the seven-engine model; it is not a released
current rating. Current nozzle dimensions, chamber pressure and expansion ratio
were not found in those sources or [Frontier's product page](https://www.frontier.us/propulsion).

`python3 tools/size_main_nozzle.py` reproduces the sizing independently of USD.
At 3,113.755 N per engine, assumed 1.5 MPa chamber pressure, gamma 1.2 and assumed
100:1 expansion, the supersonic isentropic solution gives:

| Quantity | Study value |
| --- | ---: |
| Vacuum thrust coefficient | 1.9522298164 |
| Throat bore diameter | 36.795 mm |
| Exit bore diameter | 367.948 mm |
| Outside exit diameter, with 6 mm visual wall | 379.948 mm |
| Bell length, 80% of a 15-degree cone | 494.352 mm |
| Aggregate throat area, seven engines | 0.0074432104 m² |
| Nominal aggregate reacting flow | 7.5032363 kg/s |

The radius ratio and length fraction are explicit SysML parameters. Native
`BellNozzle` consumes the same throat, exit and length, and pressure-fed engine
members consume the corresponding throat area and flow. The 6 mm wall is solely
a rendering envelope; it is not a pressure-wall or cooling design. The contour
uses the existing reduced bell law, not a supplier-qualified Rao contour.
Thrust alone cannot determine nozzle size; changing the assumed expansion or
pressure requires recomputing the throat and native acceptance.

The skirt retains its bus-derived 3.44 m octagonal footprint. Its adapter lower
face seats at the chamber upper end, and its open lower lip follows the new
exit envelope with a 20 mm recess. Its depth therefore derives from engine
geometry instead of an independent artistic scale. The native propulsion gate
checks open bores, seven-engine spacing, tank separation, adapter seating and
skirt clearance. The skirt shares the user-selected gold bus foil. Thermal
shield qualification and exhaust impingement remain outside this study.

Component edits use bounded `griffin_solar_component_group_plan(doc, target,
root, index, group)` calls for `frame`, `backplane`, `substrate`, `materials`,
`cleanup` and `mounts`. `griffin_solar_cell_row_plan` edits one row per call.
Indices follow `solarArrayInstances` and `componentAssets`; no full-panel
operation bypasses the script budget. Read back each compound generation before
the next group, then save and inspect the complete panel in its own preview.
