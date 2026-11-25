// ── Assertion harness for rhai tests ────────────────────────────────────────
//
// TEST-ONLY. This lives under `assets/scripting/tests/`, NOT
// `assets/scripting/prelude/` — the runtime asset pipeline loads it, so nothing
// here is ever auto-loaded into a running
// scenario. Test code must not ride along in production scripts; a harness
// concatenates these libs ahead of a test file explicitly — either
// `scripts/api/run_rhai_test.sh <port> <test.rhai> [probe-prim]` for both pure
// and live suites. The wrapper prepends these assertion libraries and sends
// the authored source through the production Rhai bridge.
//
// ## Why every helper returns a string
//
// Rhai functions are PURE: a function body cannot see or mutate script-level
// variables, so the usual "assert throws / bumps a global counter" shape is not
// available. Instead each check RETURNS "" on pass or a failure message, and the
// test file collects them:
//
//     let fails = [];
//     fails.push(t_near(a, b, 1e-6, "wall thickness"));
//     t_report(fails);
//
// `t_report` filters the empty strings, so a passing check costs one "" in an
// array and nothing else.
//
// ## Verdict contract
//
// The LAST line of output is `TESTS_OK <n>` or `TESTS_FAIL <n>/<m>`, which the
// runner greps to set its exit code. Keep that contract — the harness's own
// output is the only channel a shell/CI has.

/// Absolute-tolerance float compare. `tol` is absolute, not relative: these
/// check authored dimensions in metres, where "within 1 mm" is the meaningful
/// question and a relative epsilon would be looser on big numbers than on small
/// ones for no reason.
///
/// A `()` (missing attribute) is a FAILURE, never a silent pass — reading an
/// attribute that does not exist is exactly the drift these tests hunt.
fn t_near(actual, expected, tol, what) {
    if type_of(actual) == "()" || type_of(expected) == "()" {
        return what + ": MISSING (got " + actual + ", expected " + expected + ")";
    }
    let d = actual - expected;
    if d < 0.0 { d = -d; }
    if d > tol {
        return what + ": " + actual + " != " + expected + " (delta " + d + ", tol " + tol + ")";
    }
    return "";
}

/// Exact compare, for values that are genuinely discrete — counts, orders,
/// vertex totals, type names, booleans. Use `t_near` for anything measured.
fn t_eq(actual, expected, what) {
    if type_of(actual) == "()" {
        return what + ": MISSING (expected " + expected + ")";
    }
    if actual != expected {
        return what + ": " + actual + " != " + expected;
    }
    return "";
}

/// Bare predicate, for conditions that do not reduce to a comparison.
fn t_true(cond, what) {
    if cond { return ""; }
    return what + ": expected true";
}

/// Assert a value is ABSENT. The mirror of the others, and load-bearing here:
/// several invariants are about an attribute that must NOT be authored (a
/// per-face transform, an override that should live on the parent).
fn t_absent(actual, what) {
    if type_of(actual) == "()" { return ""; }
    return what + ": expected absent, got " + actual;
}

/// Print the verdict and the failures. Call ONCE, last, in a test file.
fn t_report(fails) {
    let real = [];
    for f in fails {
        if f != "" { real.push(f); }
    }
    let total = fails.len();
    if real.is_empty() {
        print("TESTS_OK " + total);
    } else {
        for f in real { print("  FAIL " + f); }
        print("TESTS_FAIL " + real.len() + "/" + total);
    }
}

// Run as a Twin-owned UI tool after the surface scene is ready.
// The API driver prepends the shared test assertion library.
fn apply(ctx) {
    let saved=get_twin_setting("ui.vehicle_controls");
    let hud="flip-panel:"+ctx.root;
    let checks=[];
    set_twin_setting("ui.vehicle_controls",true);
    let shown=flip_controls::show_panel_actions(ctx.root);
    checks.push(t_true(shown!=() && shown.ok==true,"visible controls acknowledge their binding"));
    let visible_count=0;
    for card in cmd_data("InspectGuidedHud",#{}).cards {
        if card.hud==hud {visible_count+=card.actions.len();}
    }
    checks.push(t_eq(visible_count,2,"visible panel exposes both actions"));
    set_twin_setting("ui.vehicle_controls",false);
    let hidden=flip_controls::show_panel_actions(ctx.root);
    checks.push(t_true(hidden!=() && hidden.ok==true,"hidden controls complete without a startup error"));
    let hidden_count=0;
    for card in cmd_data("InspectGuidedHud",#{}).cards {
        if card.hud==hud {hidden_count+=card.actions.len();}
    }
    checks.push(t_eq(hidden_count,0,"hidden controls retire their action bindings"));
    set_twin_setting("ui.vehicle_controls",saved);
    flip_controls::show_panel_actions(ctx.root);
    t_report(checks);
}
