# Griffin Voyager photo review — 8 November 2026

The blanket work planned in this review was implemented on 18 November.
See the [completion and verification record](../handover/griffin-blankets-2026-11-18.md)
for the saved geometry and results for GVREF-NOV08-01 through -03. The remaining
equipment, leg, harness and configuration rows below retain their planned scope.

## Scope and selected reference

Reviewed the four photos in the user's Voyager post, the public Voyager
company feed, the indexed vibration-test post, the 4 November thermal article,
the 13 October acceptance release and NASA/JPL's environmental-test photographs.
LinkedIn public views and search snapshots expose different portions of the
feed. This is a review of publicly accessible recent Griffin material, with
incomplete coverage of the full company posting history.

Select the exposed spacecraft in the user's post as the current side-view
target. Use NASA/JPL's acoustic-test image for front/underside wrapping and leg
detail. The latter depicts the August test configuration. Reconcile individual
features between configurations before changing their placement.

## Reference register

| ID | Source | Date and type | Inspected evidence |
|---|---|---|---|
| V01 | [User-linked Voyager post](https://www.linkedin.com/posts/voyg-acceleratingtheadvantage-missionready-ugcPost-7521194558664134656-sxOp/) | Public view says 1w, exact publication date unverified. Hardware and handling photos. | Four images. Image 1 exposes the vehicle. Images 2–4 show a large handling/transport cover that conceals most geometry. |
| V02 | [Voyager vibration post](https://www.linkedin.com/posts/voyagertechnologies-inc_voyg-acceleratingtheadvantage-missionready-activity-7500326630251208704-p3EA) | Exact date unverified. Test hardware. | Small front-view thumbnail exposes black panel faces and their cutout outlines. Insufficient resolution for fastener or cell measurements. |
| V03 | [Griffin-1's Thermal Journey to the Moon](https://www.linkedin.com/pulse/griffin-1s-thermal-journey-moon-voyagertechnologies-inc-2k9hc) | Published 4 November 2026. Diagram and explanatory article. | Header is a temperature chart. Article describes three side-mounted solar panels and the top payload orientation. It supplies no new close-up geometry. |
| V04 | [Voyager acceptance release](https://voyagertechnologies.com/press-releases/voyagers-griffin-1-on-track-for-the-moon/) | Published 13 October 2026. | Located a hardware press image and cross-checked the test-campaign context. No independent close-up measurement extracted. |
| J01 | [NASA/JPL photo set PIA26708](https://www.jpl.nasa.gov/images/pia26708-voyager-technologies-griffin-1-completes-environmental-testing-at-nasa-jpl/) | Published 12 October 2026. Hardware photographed July–August 2026. | NASA identifies the striped top box as a FLIP payload simulator. The microphone stands, cart, crane and test fixtures have ground-test roles. |
| J02 | [NASA test article](https://www.nasa.gov/missions/moon-base/nasa-jpl-testing-readies-voyager-technologies-lander-for-moon-mission/) | Published 13 October 2026, updated 14 October. | Inspected chamber-entry, hallway and acoustic photographs. Acoustic image is the clearest front/underside reference in this review. |

## Model baseline

The comparison uses the saved USD bus and the native Editor bus preview captured
on 7 November, not a new full-vehicle render. Its eight exterior blanket bays are
thin planar cubes. Upper pressurant vessels have smooth capsule silhouettes.
The requirements describe the 4.50 m bus envelope as a packaging study.

- `twins/astrobotic-griffin-1/components/lander/griffin_bus_visual.usda`
  SHA256 `388DFC842545FD582C9805E7BDA040C8D2C60B4A5BB5D2339AC616FCD3184915`.
- `twins/astrobotic-griffin-1/vehicles/griffin_1.usda`
  SHA256 `C195952BF0FD072F40530F4C41DC5560EC0CD9815A5E956BAA598DB28B65E78F`.
- `tools/griffin_exterior_blankets.rhai` contains the unimplemented border planner
  committed in `aedf084`. This review revises its design basis.

## Component requirements and build order

All rows are **Planned**. These are visual requirements for the next authoring
pass. No model geometry changed during this review.

| ID | Owner and visible correction | Reference and acceptance |
|---|---|---|
| GVREF-NOV08-01 | Bus exterior blankets. Replace the flat-belt appearance with separately fitted covers, broad folds, gathered corners and discontinuities around fittings. Use the existing bus datums for mounts. Fold depth and layout require declared study parameters. | V01 image 1 and J02 acoustic. Compare front and matching three-quarter views. Check cover bounds and named support contacts in the common frame. |
| GVREF-NOV08-02 | Upper pressurant visual covers. Give insulation a fuller, angular envelope with folded ends, local tape patches and interruptions at support interfaces. | V01 image 1. Compare side silhouette with the smooth capsules in the baseline. Actual underlying pressure-vessel geometry remains unobservable. |
| GVREF-NOV08-03 | Exterior tape and seams. Use localized warm patches and irregular panel joints. Reassess the proposed continuous four-edge rectangular borders before applying them. | V01 image 1 and J02 acoustic. Require a visible reference for each major seam route. Neither image establishes a regular tape rectangle on every octagonal face. |
| GVREF-NOV08-04 | Bus side equipment. Resolve the visible circular apertures, rings, protruding fittings and rectangular side plate against their existing component owners. | V01 image 1 and J02 acoustic. Record each feature by view-relative position before mapping to model axes. Do not assign a sensor or thruster identity from appearance alone. |
| GVREF-NOV08-05 | Landing-leg visuals. Model transitions between foil-wrapped upper members, exposed lower cylinders, collars and thin dark footpads. | V01 image 1 and J02 acoustic. Focused leg view plus full assembly front/side. Recheck fitted contacts through existing supported leg poses. No new leg dimensions measured here. |
| GVREF-NOV08-06 | Solar/panel assembly. Reconcile black face outlines, folded pose, edge hardware and cutouts with the existing panel components. | V02 thumbnail and J02 hallway. Obtain an unobstructed higher-resolution view before changing cell count or hinge locations. Deployment state must be explicit. |
| GVREF-NOV08-07 | Service harnesses. Trace only identifiable on-vehicle runs and attachment points. | V01 image 1 and J02 acoustic. Separate the blue and black test leads by termination evidence before retaining a route as vehicle equipment. |
| GVREF-NOV08-08 | Configuration and integration. Keep test surrogate, covered transport and rover-equipped presentation as explicit configurations. | J01 identifies the striped box as a payload simulator. V01 images 2–4 expose transport covers. Require front, side, top and three-quarter views for the selected final vehicle configuration. |

## Evidence limits and next checkpoint

The photographs establish wrapping, silhouettes, exposed interfaces and relative
placement. They do not establish absolute dimensions, flight sheet gauges,
material coefficients, hidden engines or a complete underside. Reflectance is
affected by indoor lighting and exposure. No dimension was calibrated from a
person, cart or perspective photograph.

Begin with the bus blanket envelope and one representative upper cover. Inspect
each native Editor projection before repeating the detail. Then check leg cover
transitions, visible equipment and folded panels. Use the existing typed USD
document owner and retain explicit source parameters for new visual estimates.
Visual fidelity remains Partial until those geometry changes and matching views
have been inspected. Simulation and hardware qualification are Not evaluated.

Downloaded inspection copies are in the local ignored/untracked
`output/voyager-reference-2026-11-08/` directory. Source links above remain the
portable reference register. The older exposed-structure photograph used for the
previous border draft is supporting historical evidence, not the selected outer
blanket silhouette target for this pass.
