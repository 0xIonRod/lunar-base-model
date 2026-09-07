# Griffin 8 — body completion

The approved Griffin 7 rails are retained. The body now includes 40 additional structural features: upper/lower octagonal perimeter beams, eight corner posts, upper payload-support and lower launch-adapter cones with flanges, four underdeck webs, sixteen tank-cradle gussets, and four bored landing-leg root yokes.

## Reference and modeling boundary

[Astrobotic Payload User's Guide, August 2021](https://science.nasa.gov/wp-content/uploads/2023/11/astrobotic-lunar-landers-pug.pdf), printed pages 25–26, shows the frame, upper support cone, lower launch-vehicle adapter cone, tank bays and propulsion arrangement. These informed the added body architecture. The open underside is intentional; this is not a sealed box with an omitted bottom panel.

This remains an older GLAM-like, five-engine study. It is not an exact reconstruction of current Griffin flight hardware. The new dimensions, mounting details and interfaces are estimates fitted to the existing model, not manufacturer engineering drawings. Avionics, wiring, plumbing, complete thermal blankets and fasteners are not comprehensively modeled. The guide was visually inspected using the PDF skill; its structure drawing drove the decision to retain an open frame.

## Verification

- All 176 pre-existing shape definitions and global placements remained identical during body construction and seating, including the approved rails.
- All 12 native hinge expressions were retained during construction.
- All 40 new features have valid geometry.
- Exact solid-intersection checks found no added-body interference above 1 cubic millimeter against existing volumetric features or other added features after seating five frame interfaces.
- All 69 named attachment tests returned zero gap to six decimal places. These include cone flanges, perimeter posts, deck webs, tank gussets and both plates of each leg-root yoke.
- No added-body/ramp overlap above 1 cubic millimeter was found at 15 sampled deployment positions from 0 to 100 percent. This is sampled geometric testing, not continuous collision detection, load validation, flight qualification or terrain testing.

Evidence: `griffin_8_body_build.json`, `griffin_8_body_seating.json`, `griffin_8_body_audit.json`. GUI visibility and native-file reopen results are recorded separately in `griffin_8_presentation.json`.

## Files and reproducibility

- `griffin_8_lander.FCStd`: new model; Griffin 7 remains untouched.
- `build_griffin_8_body.py`: constructs the body additions from Griffin 7.
- `seat_griffin_8_body.py`: trims only the new frame interfaces and runs `validate_griffin_8_body.py`.
- `present_griffin_8.FCMacro`: creates fresh view metadata, styles the geometry, renders inspection views and tests two saved-file reopens.
- `griffin_8_frame_cutaway.png`: inspection-only hiding of skins, tanks and carrier; the final saved assembly restores those components.

## Recurrent blank-view investigation

The Griffin 7 archive passed ZIP CRC/XML checks and opened twice with FreeCADCmd, but one fresh GUI open reported “Invalid project file.” This does not establish geometry corruption. Griffin 8 starts with newly generated GUI metadata, without altering the original Griffin 7 file. Only a successful GUI presentation report verifies the new opening behavior; the underlying intermittent failure has not been conclusively attributed to a single cause.
