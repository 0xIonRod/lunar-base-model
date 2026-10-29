import "twin://astrobotic-griffin-1/scenarios/griffin_1_surface_ops.rhai" as mission;
const ROOT="/Griffin1SurfaceOps";
fn simulation_dependencies(me,ctx) {mission::simulation_dependencies(me,ctx)}
fn on_start(me,ctx) {this.request_tick=();this.done=false;this.release_events=0;subscribe("griffin_flip_released");}
fn on_event(me,event,ctx) {if event.name=="griffin_flip_released" {this.release_events+=1;}}
fn on_tick(me,ctx) {
    if this.done || sim_tick()<120 {return;}
    if this.request_tick==() {
        this.qualified_at_click=griffin_surface_ops::landed_status().landed;
        this.request_tick=sim_tick();
        let click=griffin_surface_ops::on_hud_action("release_rover");
        if click.ok!=true {throw("Manual release click rejected");}
        return;
    }
    let rover=find_path(ROOT+"/FLIP");
    let detached=find_path(ROOT+"/FLIPPayloadAdapterJoint")<0;
    if (!detached || !is_controlled(rover) || this.release_events!=1) && sim_tick()-this.request_tick<180 {return;}
    let failures=[];
    if this.qualified_at_click {failures.push("Fixture did not exercise explicit release before landing qualification");}
    if !detached {failures.push("HUD click did not retire the real adapter");}
    if !is_controlled(rover) || this.release_events!=1 {failures.push("Detached FLIP did not receive control and one completion event");}
    let brake=();for p in read_ports(rover,["brake"]).ports {if p.direction=="in" {brake=p.value;}}
    if brake!=1.0 {failures.push("Release did not retain the parking hold");}
    this.done=true;
    report_structured_verdict(#{ok:failures.len()==0,verdict:if failures.len()==0{"pass"}else{"fail"},
      check_count:4,pass_count:4-failures.len(),failure_count:failures.len(),failures:failures,
      metrics:#{qualified_at_click:this.qualified_at_click,request_tick:this.request_tick,
        completed_tick:sim_tick(),detached:detached,release_events:this.release_events,brake:brake}},
      "GRIFFIN EXPLICIT RELEASE AUTHORITY","GRIFFIN_COMPACT_EARLY_RELEASE");
}
