// Stateless panel commands; Modelica and the native hinge own the motion.
fn panel_subject_path(host) {
    // Generic executable children run on their vehicle owner, not the Scope.
    let path=usd_path(host);
    if path==() {throw("FLIP panel controls require their authored vehicle owner");}
    path
}
fn show_panel_actions(root) {
    let hud="flip-panel:"+root;
    hint(hud,"FLIP solar panel");
    guided_hud_actions(hud,"flip_controls","on_panel_action",[
        #{id:root+"|open",label:"OPEN SOLAR PANEL  O",enabled:true},
        #{id:root+"|stow",label:"STOW SOLAR PANEL  S",enabled:true}
    ])
}
fn on_panel_action(action) {
    let parts=action.split("|");
    if parts.len()!=2 || (parts[1]!="open" && parts[1]!="stow") {
        throw("Unknown FLIP panel action");
    }
    // UI callbacks request an action; the scene-owned actor holds port authority.
    emit("flip_panel_requested",#{root:parts[0],action:parts[1]});
    #{ok:true}
}
fn apply_panel_action(root,action) {
    if action!="open" && action!="stow" {throw("Unknown FLIP panel action");}
    let controller=find_path(root+"/SolarMechanism/Controller");
    if controller<0 {throw("FLIP panel controller is unavailable");}
    let config=query("QueryUsdPrim",#{path:root+"/PanelControls",
        attrs:["inputs:open_angle_deg","inputs:stow_angle_deg"]});
    let name=if action=="open" {"inputs:open_angle_deg"} else {"inputs:stow_angle_deg"};
    let target=config.attrs[name];
    if target==() || !target.is_finite() || target<0.0 || target>90.0 {
        throw("FLIP panel deployment target must be within its authored 0–90 degree range");
    }
    let result=cmd("SetPorts",#{target:controller,writes:[["command_deg",target]]});
    if result==() || result.ok!=true {throw("FLIP panel command rejected: "+result);}
    hint("flip-panel:"+root,if action=="open" {"Opening FLIP solar panel"} else {"Stowing FLIP solar panel"});
    #{ok:true,controller:controller,command_deg:target}
}
