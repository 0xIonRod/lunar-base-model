# Upper bottles, deck and skirt — 29 October 2026

The previous ramp/release work was committed and pushed as `99c5c85` before
this visual pass. Tether dynamics are deferred at the user's request.

## Public reference and reconstruction boundary

Astrobotic's [propulsion hot-fire report](https://www.linkedin.com/posts/astrobotic_the-astrobotic-team-recently-completed-a-activity-7402458294524530689-09jf)
confirms two fuel, two oxidizer and three helium pressurant tanks. Its
[October 2025 integration update](https://www.astrobotic.com/griffin-1-mission-update/)
also distinguishes the four main COPVs from the pressurant tanks.
The [NASA-hosted FLIP rendering](https://www.nasa.gov/image-detail/flip-rover-3k10-1/)
shows two prominent horizontal upper bottles. The
[October 2026 JPL hardware photographs](https://www.nasa.gov/missions/moon-base/nasa-jpl-testing-readies-voyager-technologies-lander-for-moon-mission/)
inform the silver insulation appearance. Exact bottle dimensions, mounts and
the third bottle's location are unpublished in these sources.

### Authenticity recheck requested by the user

The official October 2025 [pressurant fit-check photograph](https://www.astrobotic.com/wp-content/uploads/2025/10/Mailchimp6-1024x617.png)
shows a long, bare dark composite vessel with rounded ends and an end service
interface. It supports the cylindrical/domed form, not the reconstruction's
exact dimensions, band stations or small rectangular support feet.
NASA/JPL's [PIA26708 image set](https://science.nasa.gov/photojournal/voyager-technologies-griffin-1-completes-environmental-testing-at-nasa-jpl/),
published 13 October 2026, includes real July–August hardware photographed from
several sides. [Figure D, acoustic testing on 12 August](https://assets.science.nasa.gov/content/dam/science/psd/photojournal/pia/pia26/pia26708/figures/PIA26708_figD.jpg)
shows predominantly silver/white exterior blankets and small gold-colored tape
patches. This is stronger visual evidence for the current silver treatment
than the older gold artist's rendering; it is not a measured optical property
or proof that every visible test cover is a final flight blanket.

Authenticity status: three helium tanks and four main propellant tanks are
manufacturer-confirmed; the long rounded upper-bottle form is photo-supported;
the current silver blanket appearance is hardware-photo-supported. Two rendered
bottles are still an incomplete inventory, and the third location is not identified
confidently. Dimensions, precise mounts and routing remain study assumptions.
At this recheck, the exposed-frame deck and outer structure had less blanket
coverage than the latest hardware. A [subsequent visual pass](griffin-exterior-blankets-2026-10-29.md)
adds frame-fitted exterior coverage without changing physics. The added deck infill and mounting heads
are useful visual detail, not an as-built reconstruction. Do not describe this
visual pass as fully authentic or flight-accurate.

The four existing main-tank assemblies remain intact. A separate reusable
`griffin_upper_pressurant_visual.usda` component adds only the two visible upper
bottles; it does not claim to reconstruct the complete three-bottle inventory.
SysML owns the estimated dimensions, stations and presentation values in
`griffin_upper_visuals.sysml`. Both rounded envelopes use the native revolution
operation, with separate retention bands, seated mounting feet and end bosses.
Each envelope is 1.99 m long and 0.64 m in diameter. Feet overlap the existing
payload-frame edge, outside the central rover path. These are visual study
assumptions, not flight pressure-vessel or clearance qualification.

The payload deck gains a 16 mm render infill inside its octagonal perimeter
and twenty mounting heads. The original physical support geometry is retained.
The skirt keeps its finite-wall mesh and blanket seam geometry; only its existing
foil material's crinkle frequency, fold contrast, sheen and axial scale change.
The finer, shallower pattern avoids the earlier large crumpled-block appearance.

Materials reference the existing insulation and metal networks. No shader
source, Sun intensity, exposure, mass, inertia, collider or joint is changed.
All new hardware is non-colliding render geometry. It is not a pressurant
inventory, plumbing network, structural model or thermal-performance model.

## Checks and visual review

- Both source-owned bottle gates pass. Each blanket has 1,538 vertices and
  6,272 authored corner normals; maximum unit-normal error is below 7.5e-8.
  Native readback confirms the complete envelopes and material bindings.
- The deck gate passes its infill envelope, material, normals, render purpose,
  disabled collision and all twenty source-sized mounting heads.
- The actual review scene loads ready, with zero runtime errors or warnings.
  Front and overhead views were inspected under the unchanged Sun lighting.
  [Front view](../handover/griffin-upper-visuals-2026-10-29.png) and
  [overhead view](../handover/griffin-upper-overhead-2026-10-29.png).
- Manual departure regression: PASS, exit 0, six checks, seed
  6840157149251759617, 60 Hz, default threads, verdict tick 1565. Adapter removal,
  control/brake handoff and 0.6302798 m signed forward travel are unchanged.
- Repository structural validation and `git diff --check` pass.

USD was authored and explicitly saved through the native document owner.
One authoring session lost its named Twin mount after reopening the already
mounted Twin; that session was not used to apply the component plans. A valid
mounted session supplied generation-matched authoring and readback. Its Editor
preview reported ready projection but displayed a blank dock area after explicit
preview/view renewal; this is recorded as a UI limitation. Final visual evidence
comes from the actual composed scene in a fresh owned review process, not that
blank preview. Local journals and logs are in
`runs/griffin-top-visuals-2026-10-28/`.

## Deferred tether work

A future reduced 1D Modelica study could use distance along the source-owned study ramp
profile, wheel/brake torque, tether payout, tension and gravitational potential
energy, then drive presentation from the solved coordinate. It would need an
explicit surface-transfer/release boundary and assumed tether properties.
This pass implements none of those equations and adds no restraint forces.
