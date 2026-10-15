// Run through the production RunRhai surface after mounting the Griffin Twin.
// The final report and this gate consume the same structured phase check.
let completed = griffin_surface_mission_report::route_start_check(
    #{route_started: true, route_engaged: false});
let active = griffin_surface_mission_report::route_start_check(
    #{route_started: true, route_engaged: true});
let never_started = griffin_surface_mission_report::route_start_check(
    #{route_started: false, route_engaged: true});
let missing = griffin_surface_mission_report::route_start_check(
    #{route_engaged: true});
report_verdict([
    t_true(completed.ok && completed.actual == true,
        "completed route evidence survives release of guidance authority"),
    t_true(active.ok, "an active started route retains its phase evidence"),
    t_true(!never_started.ok && never_started.actual == false,
        "guidance authority alone cannot prove route entry"),
    t_true(!missing.ok && missing.actual == () && missing.error != "",
        "missing phase evidence remains an explicit failed check")
], "Griffin mission evidence", "GRIFFIN_MISSION_EVIDENCE");
