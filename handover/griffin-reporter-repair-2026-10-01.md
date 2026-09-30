# Mission reporter repair

The owned landing replay reached touchdown and ramp unfolding, then repeatedly
threw `Length of string too large` while formatting the middle-fold timeout
snapshot. Remove that debug conversion and retain native ramp pose/joint maps
in the structured verdict metrics. Qualify module constants inside functions
with Rhai `global::` so the reporter can execute without missing variables.

Registered the library in owned Editor API 49746. A diagnostic invocation of
`fail_phase` with empty mission state emitted a structured FAIL with two
requirement failures and no exception. This is reporter smoke evidence, not
landing or ramp motion acceptance. No physics or deployment limit changed.
