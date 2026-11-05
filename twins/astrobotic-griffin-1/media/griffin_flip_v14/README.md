# Griffin and FLIP V14 film layers

These layers are authored through LunCoSim USD document operations. The marketing
package owns the story, shot timing and exact take selection. The normal Twin
startup scene remains `scenes/griffin_1_surface_ops.usda`.

`routes.usda`, `plans.usda` and `later.usda` compose one shared destination:
(-8, -1.8668532820884138, -22) metres. The route policy rejects unequal endpoints.
Both rovers reach that point, face their solar cells toward the native Sun, move
clear by the same authored distance and brake. All motion, turns and waiting
remain physical and contribute to the energy result. Simulation holds after both
complete; the camera can then move. The validation requires measured arrival,
small parked drift, valid contact and energy accounting, not a preferred winner.

`drive.usda` adds a wide slope-analysis camera with the same exposure as its
normal physical camera. The capture program enables the native terrain diagnostic
only for the explicitly requested slope take. Its lead-in can run at 5x; the climb
switches to 1x, resets the cadence boundary explicitly and records two native fixed
ticks per selected image. The film uses four seconds after that transition.

The current landing comparison uses `drop-low-refresh.usda` and
`drop-high-refresh.usda`: one- and two-metre engine-off releases. Obsolete cold-start
experiments are not part of this package. Capture prims are disarmed after each
take; loading a saved scene must not overwrite an old recording.
