// Fault geometry is authored in the fixture. This observer never commands
// motion; the production mission must refuse readiness and payload release.
import "twin://astrobotic-griffin-1/scenarios/griffin_1_surface_ops.rhai" as mission;
import "twin://astrobotic-griffin-1/tools/griffin_surface_ramp_ops.rhai" as ramps;
import "lunco://scripting/tools/sysml_requirements" as requirements;
fn simulation_dependencies(me,ctx){let deps=mission::simulation_dependencies(me,ctx);deps.entity_writes=[];deps}
fn on_start(me,ctx){
    this.done=false;this.failure=();this.ready=false;this.released=false;
    this.contract=ramps::unfold_event_contract();
    this.fault=query("QueryUsdPrim",#{path:"/Griffin1SurfaceOps/RampDeploymentObservation/Program",attrs:["custom:contactFault"]}).attrs["custom:contactFault"];
    if this.fault!="toe_gap" && this.fault!="deck_gap"{throw("Expected an explicit contact fault on the observer Program");}
    subscribe("griffin_phase_timeout");subscribe(this.contract.roots_settled);subscribe("griffin_surface_route_started");
}
fn on_event(me,event,ctx){
    if event.name=="griffin_phase_timeout"{this.failure=event.value;}
    if event.name==this.contract.roots_settled{this.ready=true;}
    if event.name=="griffin_surface_route_started"{this.released=true;}
}
fn on_tick(me,ctx){
    if this.done || this.failure==(){return;}
    let failures=[];let count=5;
    if this.failure.phase!="ramp-root-deployment-settle"{failures.push("Wrong production rejection phase: "+this.failure.phase);}
    if this.ready{failures.push("Faulty path emitted traversal readiness");}
    if this.released{failures.push("Faulty path started automatic egress");}
    let joint=query("QueryUsdPrim",#{path:"/Griffin1SurfaceOps/FLIPPayloadAdapterJoint",attrs:["physics:jointEnabled"]});
    if joint.attrs["physics:jointEnabled"]!=true || find_path("/Griffin1SurfaceOps/FLIPPayloadAdapterJoint")<0{failures.push("Payload adapter was released");}
    let e=this.failure.traversal;
    if e==() || e.ok!=true || e.hinges_settled!=true || e.settled!=false{failures.push("Fault was not rejected after measured hinge settlement");}
    if e!=() && e.contact!=() && e.contact.ok==true && e.contact.tracks.len()==4{
        for track in e.contact.tracks{
            count+=2;
            if this.fault=="toe_gap"{
                if track.toe_contact || track.minimum_toe_clearance_m<=e.contact.tolerance_m{failures.push("Shortened toe did not fail actual terrain contact: "+track.track);}
                if !track.deck_continuous{failures.push("Toe fixture also lost deck continuity");}
            }else if this.fault=="deck_gap"{
                if track.deck_continuous || track.entry_gap_m<=e.contact.interface_tolerance_m{failures.push("Lowered bridge did not fail deck continuity: "+track.track);}
                if !track.toe_contact{failures.push("Deck fixture also lost toe contact");}
            }else{failures.push("Unknown fixture fault");}
        }
    }else{count+=1;failures.push("Native contact evidence missing");}
    report_structured_verdict(#{ok:failures.len()==0,verdict:if failures.len()==0{"pass"}else{"fail"},check_count:count,
        failure_count:failures.len(),pass_count:count-failures.len(),failures:failures,source_revision:requirements::model().source_revision,
        metrics:#{fault:this.fault,rejection:this.failure,ready_emitted:this.ready,route_started:this.released}},
        "GRIFFIN RAMP CONTACT REJECTION","GRIFFIN_RAMP_CONTACT_REJECTION");this.done=true;
}
