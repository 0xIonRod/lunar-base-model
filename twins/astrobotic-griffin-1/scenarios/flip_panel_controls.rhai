// One scene-owned UI lifetime per CAD rover, including while mounted on Griffin.
fn simulation_dependencies(me,ctx) {
    let root=flip_controls::panel_subject_path(me);
    let rover=find_path(root);let controller=find_path(root+"/SolarMechanism/Controller");
    #{modelica_entities:[controller],entity_reads:[rover,controller],
      entity_writes:[controller],query_reads:["QueryPhysicsState","QueryUsdPrim"],required_inputs:[]}
}
fn on_start(me,ctx) {
    this.root=flip_controls::panel_subject_path(me);
    let state=query("QueryPhysicsState",#{id:find_path(this.root)});
    // A static visual-review instance has no operational control surface.
    if state.body_mode!="dynamic" {return;}
    subscribe("flip_panel_requested");
    subscribe("key:KeyO");
    subscribe("key:KeyS");
    let result=flip_controls::show_panel_actions(this.root);
    if result==() || result.ok!=true {throw("FLIP panel HUD could not bind its callback");}
}
fn on_stop(me,ctx) {
    if this.root!=() {
        clear_guided_hud_actions("flip-panel:"+this.root);
        clear_hint("flip-panel:"+this.root);
    }
}
fn on_event(me,evt,ctx) {
    if evt.name=="flip_panel_requested" && evt.value.root==this.root {
        flip_controls::apply_panel_action(this.root,evt.value.action);
    }
    if evt.name=="key:KeyO" {
        flip_controls::apply_panel_action(this.root,"open");
    }
    // S remains reverse while the operator is driving the rover. The panel
    // button remains available then; mounted/unpossessed FLIP accepts S.
    if evt.name=="key:KeyS" && !is_controlled(me) {
        flip_controls::apply_panel_action(this.root,"stow");
    }
}
