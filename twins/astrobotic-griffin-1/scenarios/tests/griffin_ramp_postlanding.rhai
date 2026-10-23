// Observe the production mission; commands and motion stay in its normal task.
import "twin://astrobotic-griffin-1/scenarios/griffin_1_surface_ops.rhai" as mission;
import "twin://astrobotic-griffin-1/tools/griffin_surface_ops.rhai" as surface;
import "twin://astrobotic-griffin-1/tools/griffin_surface_ramp_ops.rhai" as ramps;
import "twin://astrobotic-griffin-1/tools/griffin_spec.rhai" as spec;
import "lunco://scripting/tools/sysml_requirements" as requirements;

fn simulation_dependencies(me,ctx){let deps=mission::simulation_dependencies(me,ctx);deps.entity_writes=[];deps}
fn on_start(me,ctx){
    this.done=false;this.finished=false;this.failed=false;this.opening_landing=();this.events=[];this.snapshots=#{};
    this.contract=ramps::unfold_event_contract();
    for name in this.contract.ordered{subscribe(name);}subscribe("griffin_phase_timeout");
}
fn on_event(me,event,ctx){
    if this.done{return;}
    if event.name=="griffin_phase_timeout"{this.failed=true;return;}
    if !this.contract.ordered.contains(event.name){return;}
    this.events.push(#{name:event.name,sim_tick:event.sim_tick});
    if event.name==this.contract.root_clear_commanded{this.opening_landing=surface::landed_status();}
    if event.name==this.contract.root_clear_settled || event.name==this.contract.middle_settled
        || event.name==this.contract.toes_settled || event.name==this.contract.roots_settled{
        this.snapshots[event.name]=surface::physical_ramp_hinge_report();
    }
    if event.name==this.contract.roots_settled{this.finished=true;}
}
fn hinge_at(snapshot,name){
    if snapshot==() || snapshot.ok!=true{throw("Measured hinge snapshot unavailable");}
    for hinge in snapshot.hinges{if hinge.name==name{return hinge;}}
    throw("Expected physical hinge missing: "+name);
}
fn check_settled(snapshot,expected,failures){
    let count=0;
    for e in expected{
        let h=hinge_at(snapshot,e.name);count+=1;
        if surface::_ramp_angle_error_rad(h.measured_angle_rad,e.target_rad)>spec::physical_ramp_hinge_settle_angle_tolerance_rad()
            || abs(h.measured_angular_speed_rad_per_s)>spec::physical_ramp_hinge_settle_speed_tolerance_rad_per_s(){failures.push("Measured settlement failed: "+e.name);}
    }#{count:count,failures:failures}
}
fn on_tick(me,ctx){
    if this.done || (!this.finished && !this.failed){return;}
    let failures=[];let count=1;
    if this.failed{failures.push("Production mission reported a phase failure");}
    if this.opening_landing==() || this.opening_landing.ok!=true || !this.opening_landing.landed{failures.push("Opening did not start after a measured landing");}count+=1;
    if this.events.len()!=this.contract.ordered.len(){failures.push("Incomplete production unfold event sequence");}count+=1;
    let chronology=ramps::event_order_report(this.events);count+=1;
    if !chronology.ok{failures.push("Unfold phase chronology failed: "+chronology.to_string());}
    if this.finished{
        let clear=check_settled(this.snapshots[this.contract.root_clear_settled],ramps::root_clearance_targets(),failures);failures=clear.failures;count+=clear.count;
        let joints=spec::ramp_intermediate_joint_names();let middle=[];let toe=[];
        for i in 0..joints.len(){let stage=if i%2==0{"middle"}else{"toe"};
            toe.push(#{name:joints[i],target_rad:spec::physical_ramp_section_deployment_joint_angle_rad(stage)});
            middle.push(#{name:joints[i],target_rad:if stage=="middle"{spec::physical_ramp_section_deployment_joint_angle_rad(stage)}else{spec::physical_ramp_section_stowed_joint_angle_rad(stage)}});
        }
        let a=check_settled(this.snapshots[this.contract.middle_settled],middle,failures);failures=a.failures;count+=a.count;
        let b=check_settled(this.snapshots[this.contract.toes_settled],toe,failures);failures=b.failures;count+=b.count;
        let final=this.snapshots[this.contract.roots_settled];let c=check_settled(final,toe,failures);failures=c.failures;count+=c.count;
        let roots=spec::ramp_root_joint_names();
        for i in 0..roots.len(){let h=hinge_at(final,roots[i]);count+=1;
            if (i==0 && h.measured_angle_rad>=0.0) || (i==1 && h.measured_angle_rad<=0.0)
                || abs(h.measured_angle_rad)>spec::max_ramp_command_rad()
                || abs(h.measured_angular_speed_rad_per_s)>spec::physical_ramp_hinge_settle_speed_tolerance_rad_per_s(){failures.push("Root did not settle in its outward deployment envelope: "+h.name);}
        }
    }
    report_structured_verdict(#{ok:failures.len()==0,verdict:if failures.len()==0{"pass"}else{"fail"},check_count:count,
        failure_count:failures.len(),pass_count:count-failures.len(),failures:failures,source_revision:requirements::model().source_revision,
        metrics:#{events:this.events,chronology:chronology,opening_landing:this.opening_landing,measured_hinge_snapshots:this.snapshots,
            scope:"Production descent and measured root-clear/middle/opposite-toe/root-lowering sequence; no pose overrides"}},
        "GRIFFIN POST-LANDING RAMP DEPLOYMENT","GRIFFIN_RAMP_POSTLANDING");this.done=true;
}
