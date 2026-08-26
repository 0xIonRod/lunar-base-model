# Mission 001 — Blue Moon MK1 Endurance

This package represents Mission One (`M01`) as a planning model for Blue
Origin’s Blue Moon Mark 1 Endurance lander. Public mission facts and unknowns
are recorded in [`mission-research.md`](mission-research.md).

The executable scene remains intentionally simple:

- flat 1 km × 1 km local ground plane;
- one simplified Endurance lander body at a 40 m landing pad;
- lunar gravity of 1.62 m/s²; and
- one rover marked as a simulator-only test asset, not an Endurance payload.

`mission.yaml` is the machine-readable contract. Values that are not public
are `null` or explicitly labeled as engineering assumptions; they must not be
silently replaced with guesses.

