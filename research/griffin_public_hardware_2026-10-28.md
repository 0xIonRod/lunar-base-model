# Griffin public hardware references — 28 October 2026

This review supports an exterior presentation upgrade. It does not supply released
flight CAD, optical coefficients, cable ICDs or a new physical parameter set.

| Primary source | What it supports | Boundary |
|---|---|---|
| [Astrobotic Payload User's Guide, August 2021 v5.0, pp.24–31](https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf) | Aluminum structure, side-mounted polar solar arrays, landing legs, and the use of radiators, heat pipes and MLI. | Historical VIPER-era configuration; its dimensions and layout are not automatically Griffin-1/FLIP as-built data. |
| [NASA/JPL test campaign, published 13 October 2026](https://www.nasa.gov/missions/moon-base/nasa-jpl-testing-readies-voyager-technologies-lander-for-moon-mission/) | July–August 2026 imagery reveals thermal wrapping, exposed lower structure and retaining bands. | Panels and test equipment vary between photographs. Laboratory cables, stands, microphones and lifting fixtures are not flight-model details. |
| [NASA June integration gallery](https://www.nasa.gov/gallery/astrobotics-griffin-1/) | Current integrated solar-bank outlines, exposed members and service-harness appearance. | Qualitative visual evidence; perspective and illumination do not establish dimensions, alloys or exact routes. |

The user-provided laboratory screenshot is consistent with the June integration
imagery, but the changes are not a literal reconstruction of that single image.

## Implemented reconstruction

The upgrade adds raised lips following the three existing cutout panel-frame
profiles; silver insulation sleeves on upper struts; retaining cuffs; wraps on
the separately installed stationary shock barrels; and four externally visible
service looms beneath the panel bank. All added geometry is render-only.

The wrapping lengths, radial allowances, lip thickness, cable sag, cable routing
and cuff colors are **presentation assumptions**. Existing component geometry
supplies the mounting frames and dimensions. The model does not claim the looms
are a released electrical network or that the warm cuff finish identifies an
alloy/coating. The original structure, panel cutouts, contacts, mass, joint travel,
electrical behavior and thermal equations remain authoritative.

Controls are owned by `GriffinPresentationStudy::PublicHardwareDetail`, with dry
typed plans in `tools/griffin_public_hardware.rhai`. See the
[implementation and verification record](../twins/astrobotic-griffin-1/contracts/griffin-public-hardware-2026-10-28.md).
