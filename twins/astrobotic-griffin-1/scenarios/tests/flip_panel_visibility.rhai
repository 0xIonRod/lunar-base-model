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
