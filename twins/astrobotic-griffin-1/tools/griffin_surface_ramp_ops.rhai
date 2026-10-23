// Griffin surface mission ramp commands.
//
// This module owns the SysML-targeted hinge command batches. The mission
// scenario remains the single owner of sequencing, measured settlement, and
// phase state.
import "lunco://scripting/tools/sysml_requirements" as requirements;

// Validate the complete pair before retiring either solver latch. USD owns
// the fixed attachment; SysML owns its hinge pairing; Rhai owns release order.
fn flight_latch_release_plan(root, hinge_names) {
    if root==() || root=="" || hinge_names==() || hinge_names.len()!=2 {
        return #{ok:false,error:"flight latch release requires a root and two hinge identities"};
    }
    let bindings=griffin_spec::ramp_flight_latch_bindings();
    let selected=[];
    let paths=[];
    for hinge in hinge_names {
        let binding=();
        for candidate in bindings {if candidate.hinge==hinge {binding=candidate;}}
        if binding==() || paths.contains(root+"/"+binding.latch) {
            return #{ok:false,error:"unknown or duplicate flight latch hinge identity",hinge:hinge};
        }
        selected.push(binding);
        paths.push(root+"/"+binding.latch);
        paths.push(root+"/"+binding.hinge);
    }
    let snapshot=query("QueryUsdPrims",#{paths:paths,rels:["physics:body0","physics:body1"]});
    if snapshot==() || snapshot.error!=() || snapshot.records==()
        || snapshot.records.len()!=paths.len() {
        return #{ok:false,error:"flight latch topology snapshot unavailable",snapshot:snapshot};
    }
    let targets=[];
    for index in 0..selected.len() {
        let latch=snapshot.records[2*index];
        let hinge=snapshot.records[2*index+1];
        if latch.type_name!="PhysicsFixedJoint" || hinge.type_name!="PhysicsRevoluteJoint"
            || latch.active!=true || hinge.active!=true
            || latch.relationships==() || hinge.relationships==() {
            return #{ok:false,error:"flight latch and revolute joint must be active standard joints",
                latch:latch,hinge:hinge};
        }
        for name in ["physics:body0","physics:body1"] {
            let locked=latch.relationships[name];
            let driven=hinge.relationships[name];
            if locked==() || driven==() || locked.len()!=1 || driven.len()!=1
                || locked[0]!=driven[0] {
                return #{ok:false,error:"flight latch body endpoint differs from its source-paired hinge",
                    relationship:name,latch:latch,hinge:hinge};
            }
        }
        let entity=find_path(paths[2*index]);
        if entity==() || entity<0 {
            return #{ok:false,error:"flight latch runtime entity unavailable",path:paths[2*index]};
        }
        targets.push(#{target:entity,path:paths[2*index],hinge:selected[index].hinge});
    }
    #{ok:true,targets:targets,snapshot:snapshot}
}

fn _release_flight_latches(hinge_names) {
    let plan=flight_latch_release_plan("/Griffin1SurfaceOps/Lander",hinge_names);
    if plan.ok!=true {return plan;}
    let commands=[];
    for target in plan.targets {
        let result=cmd("DetachJoint",#{target:target.target,intent:"Interactive"});
        commands.push(#{path:target.path,result:result});
        if result==() || result.ok!=true {
            return #{ok:false,error:"flight latch release rejected",plan:plan,commands:commands};
        }
    }
    #{ok:true,plan:plan,commands:commands}
}

// The mission owns these profiles for one admitted scene. A mechanical flight
// latch holds the stowed coordinate; its parallel motor supplies no effort.
fn hold_flight_latch_motors(root) {
    let drives=[];
    for binding in griffin_spec::ramp_flight_latch_bindings() {
        let id=find_path(root+"/"+binding.hinge);
        let law=joint_drive(id);
        if law==() || law.angular!=true || law.enabled!=true || law.model!="force"
            || !law.max_effort.is_finite() || law.max_effort<=0.0 {
            return #{ok:false,error:"flight latch requires an enabled finite-effort hinge motor",
                hinge:binding.hinge,drive:law};
        }
        drives.push(#{name:binding.hinge,id:id,law:law});
    }
    if drives.len()!=6 {return #{ok:false,error:"six source-paired flight latch motors required"};}
    let sections=griffin_spec::ramp_intermediate_joint_names();
    for names in [griffin_spec::ramp_root_joint_names(),
        [sections[0],sections[2]],[sections[1],sections[3]]] {
        let plan=flight_latch_release_plan(root,names);
        if plan.ok!=true {return plan;}
    }
    for drive in drives {
        if !set_joint_drive(drive.id,drive.law.stiffness,drive.law.damping,0.0) {
            throw("flight latch motor effort suppression rejected: "+drive.name);
        }
    }
    #{ok:true,drives:drives}
}

// Validate the entire pair before restoring either native motor. Targets are
// already owned by the phase command and must survive this effort change.
fn released_motor_plan(profiles,names) {
    if profiles==() || names==() || names.len()!=2 || names[0]==names[1] {
        return #{ok:false,error:"released motor plan requires two distinct hinge identities"};
    }
    let drives=[];
    for name in names {
        let matches=[];
        for profile in profiles {if profile.name==name {matches.push(profile);}}
        if matches.len()!=1 {return #{ok:false,error:"released hinge has no unique saved motor law",hinge:name};}
        let drive=matches[0];
        let live=joint_drive(drive.id);
        if live==() || live.angular!=true || live.stiffness!=drive.law.stiffness
            || live.damping!=drive.law.damping
            || (live.max_effort!=0.0 && live.max_effort!=drive.law.max_effort) {
            return #{ok:false,error:"released hinge motor law changed after flight latch admission",hinge:name};
        }
        drives.push(drive);
    }
    #{ok:true,drives:drives}
}

fn restore_released_motors(profiles,event_name) {
    let events=unfold_event_contract();
    let names=[];
    if event_name==events.middle_commanded || event_name==events.toes_commanded {
        let sections=griffin_spec::ramp_intermediate_joint_names();
        let offset=if event_name==events.middle_commanded {0} else {1};
        names=[sections[offset],sections[offset+2]];
    } else if event_name==events.root_clear_commanded {names=griffin_spec::ramp_root_joint_names();}
    else {return #{ok:true,restored:[]};}
    let plan=released_motor_plan(profiles,names);
    if plan.ok!=true {return plan;}
    for drive in plan.drives {
        if !set_joint_drive(drive.id,drive.law.stiffness,drive.law.damping,drive.law.max_effort) {
            throw("released flight latch motor restoration rejected: "+drive.name);
        }
    }
    #{ok:true,restored:names}
}

fn unfold_event_contract() {
    let root_clear_commanded = "griffin_ramp_root_clearance_commanded";
    let root_clear_settled = "griffin_ramp_root_clearance_settled";
    let middle_commanded = "griffin_ramp_middle_sections_unfold_commanded";
    let middle_settled = "griffin_ramp_middle_sections_unfold_settled";
    let toes_commanded = "griffin_ramp_toes_unfold_commanded";
    let toes_settled = "griffin_ramp_toes_unfold_settled";
    let roots_commanded = "griffin_ramps_deploy_commanded";
    let roots_settled = "griffin_ramp_deployment_settled";
    #{
        root_clear_commanded:root_clear_commanded,
        root_clear_settled:root_clear_settled,
        middle_commanded: middle_commanded,
        middle_settled: middle_settled,
        toes_commanded: toes_commanded,
        toes_settled: toes_settled,
        roots_commanded: roots_commanded,
        roots_settled: roots_settled,
        ordered: [root_clear_commanded,root_clear_settled,middle_commanded, middle_settled, toes_commanded,
            toes_settled, roots_commanded, roots_settled]
    }
}

// Delivery order within one admitted tick is unspecified. A phase must settle
// on a later tick than its command; its successor may begin on that same tick.
fn event_order_report(trace){
    let required=unfold_event_contract().ordered;let observed=[];let previous=();
    if trace==(){return #{ok:false,expected:required,error:"Unfold event trace unavailable"};}
    for i in 0..required.len(){
        let matches=[];for index in 0..trace.len(){if trace[index].name==required[i]{matches.push(index);}}
        if matches.len()!=1{return #{ok:false,expected:required,observed:observed,event:required[i],match_count:matches.len(),error:"Each phase event must occur exactly once"};}
        let index=matches[0];let tick=trace[index].sim_tick;
        if tick==() || tick<0 || (previous!=() && (tick<previous || (i%2==1 && tick==previous))){
            return #{ok:false,expected:required,observed:observed,event:required[i],sim_tick:tick,previous_tick:previous,error:"Unfold phase chronology violated"};
        }
        observed.push(#{name:required[i],event_index:index,sim_tick:tick});previous=tick;
    }
    #{ok:true,expected:required,observed:observed}
}

fn root_clearance_targets() {
    let model=requirements::model();let angle=model.value("GriffinVehicleAssemblyRequirements::GriffinRampPackagingStudy::rootClearanceAngleRad");
    let names=griffin_spec::ramp_root_joint_names();
    if names.len()!=2 || angle<=0.0 || !angle.is_finite(){throw("Source root-clearance targets unavailable");}
    [#{name:names[0],target_rad:angle},#{name:names[1],target_rad:-angle}]
}

fn _begin_root_motion(expected,event_name) {
    let snapshot=griffin_surface_ops::physical_ramp_joint_evidence();
    if snapshot.ok!=true || expected.len()!=2{return #{ok:false,error:"Both measured root coordinates are required"};}
    let starts=[];let travel=0.0;
    for target in expected{
        let measured=();for hinge in snapshot.hinges{if hinge.name==target.name{measured=hinge.measured_angle_rad;}}
        if measured==() || !measured.is_finite(){return #{ok:false,error:"Root coordinate unavailable",hinge:target.name};}
        starts.push(#{name:target.name,target_rad:measured});travel=max(travel,abs(target.target_rad-measured));
    }
    let quarter=abs(griffin_spec::physical_ramp_section_stowed_relative_angle_rad())/2.0;
    let duration=griffin_spec::physical_ramp_unfold_quarter_turn_duration_s()*travel/quarter;
    if duration<=0.0 || !duration.is_finite(){return #{ok:false,error:"Root motion requires finite positive travel and source duration"};}
    let command=griffin_surface_ops::set_physical_ramp_hinge_angles(starts);if command.ok!=true{return command;}
    emit(event_name);
    #{ok:true,expected_angles:expected,motion:#{start_tick:sim_tick(),starts:starts,targets:expected,duration_s:duration}}
}

fn clear_roots() {
    let release=_release_flight_latches(griffin_spec::ramp_root_joint_names());if release.ok!=true{return release;}
    let result=_begin_root_motion(root_clearance_targets(),unfold_event_contract().root_clear_commanded);
    result.flight_latch_release=release;result
}

fn root_motion_progress(motion) {
    if motion==(){return #{ok:true,complete:true,motion:()};}
    let clock=clock_snapshot();
    if clock.fixed_dt_s==() || clock.fixed_dt_s<=0.0 || clock.sim_tick<motion.start_tick{
        return #{ok:false,error:"Root motion has no admitted simulation clock"};
    }
    let u=min(1.0,max(0.0,(clock.sim_tick-motion.start_tick).to_float()*clock.fixed_dt_s/motion.duration_s));
    let fraction=u*u*u*(10.0+u*(-15.0+6.0*u));let expected=[];
    for i in 0..motion.targets.len(){let a=motion.starts[i];let b=motion.targets[i];
        expected.push(#{name:b.name,target_rad:if u>=1.0{b.target_rad}else{a.target_rad+(b.target_rad-a.target_rad)*fraction}});}
    let command=griffin_surface_ops::set_physical_ramp_hinge_angles(expected);if command.ok!=true{return command;}
    #{ok:true,complete:u>=1.0,motion:if u>=1.0{()}else{motion}}
}

// Break the antipodal half-turn into two measured quarter-turns. A joint
// frame offset alone cannot disambiguate the motor's shortest-path error.
fn _command_section_unfold(stage, target, publish_start) {
    let names=griffin_spec::ramp_intermediate_joint_names();
    if names.len()!=4 || target==()
        || (stage!="middle" && stage!="toe") {
        return #{ok:false,error:"ramp section unfold source or stage is invalid"};
    }
    let expected=[];
    let writes=[];
    for index in 0..4 {
        let moving=if stage=="middle" {index%2==0} else {index%2==1};
        let held=if stage=="middle" {griffin_spec::physical_ramp_section_stowed_joint_angle_rad("toe")}
            else {griffin_spec::physical_ramp_section_deployment_joint_angle_rad("middle")};
        let item=#{name:names[index],target_rad:if moving {target} else {held}};
        expected.push(item);
        if moving {writes.push(item);}
    }
    let command=griffin_surface_ops::set_physical_ramp_hinge_angles(writes);
    if command==() || command.ok!=true {
        return #{ok:false,error:"atomic section unfold command was rejected",
            expected_angles:expected,command:command};
    }
    if publish_start {
        emit(if stage=="middle" {unfold_event_contract().middle_commanded}
            else {unfold_event_contract().toes_commanded});
    }
    if publish_start {print("[griffin] "+stage+" section unfold started");}
    #{ok:true,command:command,expected_angles:expected}
}

// Quintic command interpolation has zero endpoint speed and acceleration.
// Avian still owns the driven bodies: no pose or velocity is overwritten.
fn _begin_section_motion(stage, start, target, publish_start) {
    let duration=griffin_spec::physical_ramp_unfold_quarter_turn_duration_s();
    if duration==() || !duration.is_finite() || duration<=0.0
        || start==() || target==() || !start.is_finite() || !target.is_finite() {
        return #{ok:false,error:"ramp quarter-turn source is unavailable or invalid"};
    }
    let release=();
    if publish_start {
        let names=griffin_spec::ramp_intermediate_joint_names();
        if names.len()!=4 || (stage!="middle" && stage!="toe") {
            return #{ok:false,error:"ramp section release identities unavailable"};
        }
        let offset=if stage=="middle" {0} else {1};
        release=_release_flight_latches([names[offset],names[offset+2]]);
        if release.ok!=true {return release;}
    }
    let result=_command_section_unfold(stage,start,publish_start);
    if result.ok!=true {return result;}
    result.motion=#{start_tick:sim_tick(),start_target:start,target:target,duration_s:duration};
    result.flight_latch_release=release;
    result
}

fn unfold_middle_sections() {
    _begin_section_motion("middle",griffin_spec::physical_ramp_section_stowed_joint_angle_rad("middle"),
        griffin_spec::physical_ramp_section_unfold_waypoint_joint_angle_rad("middle"),true)
}

fn unfold_toes() {
    _begin_section_motion("toe",griffin_spec::physical_ramp_section_stowed_joint_angle_rad("toe"),
        griffin_spec::physical_ramp_section_unfold_waypoint_joint_angle_rad("toe"),true)
}

// The scenario owns state and timing. Return the next expected snapshot
// explicitly; do not try to mutate the caller's Rhai map through a parameter.
fn section_unfold_progress(expected, stage, final_commanded, waypoints, motion) {
    if motion!=() {
        let clocks=clock_snapshot();
        if clocks.fixed_dt_s==() || !clocks.fixed_dt_s.is_finite() || clocks.fixed_dt_s<=0.0
            || clocks.sim_tick<motion.start_tick {
            return #{ok:false,error:"ramp motion has no valid admitted simulation clock"};
        }
        let elapsed=(clocks.sim_tick-motion.start_tick).to_float()*clocks.fixed_dt_s;
        let u=min(1.0,max(0.0,elapsed/motion.duration_s));
        let fraction=u*u*u*(10.0+u*(-15.0+6.0*u));
        let target=if u>=1.0 {motion.target}
            else {motion.start_target+(motion.target-motion.start_target)*fraction};
        let command=_command_section_unfold(stage,target,false);
        if command.ok!=true {return command;}
        expected=command.expected_angles;
        if u<1.0 {
            return #{ok:true,settled:false,evidence:(),waypoint_evidence:waypoints,
                expected_angles:expected,final_commanded:final_commanded,motion:motion};
        }
        motion=();
    }
    let evidence=griffin_surface_ops::physical_ramp_hinges_settled(expected,
        griffin_spec::physical_ramp_hinge_settle_angle_tolerance_rad());
    if evidence.ok!=true {
        return #{ok:false,error:"section hinge settlement evidence is unavailable",
            evidence:evidence};
    }
    if evidence.settled==true && !final_commanded {
        let next=_begin_section_motion(stage,
            griffin_spec::physical_ramp_section_unfold_waypoint_joint_angle_rad(stage),
            griffin_spec::physical_ramp_section_deployment_joint_angle_rad(stage),false);
        if next.ok!=true {return next;}
        waypoints.push(#{stage:stage,evidence:evidence});
        return #{ok:true,settled:false,evidence:evidence,
            waypoint_evidence:waypoints,expected_angles:next.expected_angles,
            final_commanded:true,motion:next.motion};
    }
    #{ok:true,settled:evidence.settled && final_commanded,evidence:evidence,
        waypoint_evidence:waypoints,expected_angles:expected,final_commanded:final_commanded,motion:motion}
}

// Final traversal gate includes every hinge, not only the roots. One angle
// crossing cannot release the payload while the deployed bundle is moving.
fn traversal_settle_progress(expected, stable_since) {
    let evidence=griffin_surface_ops::physical_ramp_hinges_settled(expected,
        griffin_spec::physical_ramp_hinge_settle_angle_tolerance_rad());
    let dwell=griffin_spec::physical_ramp_traversal_settle_dwell_s();
    let clocks=clock_snapshot();
    let dt=clocks.fixed_dt_s;
    if evidence.ok!=true || dwell==() || !dwell.is_finite() || dwell<=0.0
        || dt==() || !dt.is_finite() || dt<=0.0 {
        return #{ok:false,settled:false,stable_since:(),evidence:evidence,
            error:"ramp traversal settlement or clock contract is unavailable"};
    }
    let tick=evidence.sim_tick;
    if evidence.settled!=true {stable_since=();}
    else if stable_since==() {stable_since=tick;}
    let elapsed=if stable_since==() {0.0} else {(tick-stable_since).to_float()*dt};
    evidence.instantaneous_settled=evidence.settled;
    evidence.settled=evidence.settled && elapsed>=dwell;
    evidence.dwell_elapsed_s=elapsed;
    evidence.dwell_required_s=dwell;
    #{ok:true,settled:evidence.settled,stable_since:stable_since,evidence:evidence}
}

// Plan from the landed hinge frames, not the nominal flat touchdown datum.
// A single root rotation cannot remove transverse terrain slope. Use the
// lowest clearance of all eight toe corners, preserving the authored miter.
fn _toe_clearance(angle, frame) {
    let delta=frame.sign*(angle-frame.measured);
    let minimum=1000000.0;
    let points=[];
    for z in frame.stations {
        for edge in [[frame.length,frame.track_y+frame.half_thickness],
            [frame.length-frame.bevel,frame.track_y-frame.half_thickness]] {
            let local=vec3(edge[0]*cos(delta)-edge[1]*sin(delta),
                edge[0]*sin(delta)+edge[1]*cos(delta),z);
            let point=frame.position+qrot(frame.rotation,local);
            let terrain=query("TerrainHeight",#{x:point.x,z:point.z});
            if terrain==() || terrain.found!=true || !terrain.height.is_finite() {
                return #{ok:false,error:"ramp toe has no retained DEM surface"};
            }
            let height=terrain.height;
            let gap=point.y-height;
            minimum=min(minimum,gap);
            points.push(#{point:vec3_array(point),surface_y_m:height,clearance_m:gap});
        }
    }
    #{ok:true,minimum_clearance_m:minimum,points:points}
}

fn landed_root_deployment_plan() {
    let joints=griffin_spec::ramp_root_joint_names();
    let snapshot=griffin_surface_ops::physical_ramp_joint_evidence();
    let limit=griffin_spec::max_ramp_command_rad();
    let tolerance=griffin_spec::physical_ramp_terrain_contact_tolerance_m();
    let thickness=griffin_spec::ramp_surface_thickness_m();
    let width=griffin_spec::ramp_contact_track_width_m();
    let model=requirements::model();let length=0.0;
    for name in ["GriffinRampRootSectionRequirements::RampRootSection", "GriffinRampMiddleSectionRequirements::RampMiddleSection", "GriffinRampToeSectionRequirements::RampToeSection"]{length+=model.value(name+"::lengthM");}
    let track_y=model.value("GriffinRampRequirements::GriffinEgressRamp::rampSurfaceCenterYM")-model.value("GriffinRampRootSectionRequirements::RampRootSection::entryAxisYM");
    let nominal=abs(griffin_spec::physical_ramp_port_deployment_angle_rad());
    if snapshot.ok!=true || joints.len()!=2 || limit==() || tolerance==()
        || thickness==() || width==() || length==() || nominal==() {
        return #{ok:false,error:"landed ramp planning inputs unavailable"};
    }
    let stations=[];
    for z in griffin_spec::rover_wheel_station_z() {
        for edge in [z-width/2.0,z+width/2.0] {
            if !stations.contains(edge) {stations.push(edge);}
        }
    }
    if stations.len()!=4 {return #{ok:false,error:"FLIP requires four lateral track edges"};}
    let expected=[];
    let evidence=[];
    for index in 0..2 {
        let side=if index==0 {"Port"} else {"Starboard"};
        let id=find_path("/Griffin1SurfaceOps/Lander/EgressRamp"+side);
        let position=world_pos3(id);
        let rotation=world_rotation_quat(id);
        let measured=();
        for hinge in snapshot.hinges {
            if hinge.name==joints[index] {measured=hinge.measured_angle_rad;}
        }
        if position==() || rotation==() || measured==() {
            return #{ok:false,error:"landed root frame unavailable"};
        }
        let sign=if index==0 {1.0} else {-1.0};
        let frame=#{position:position,rotation:rotation,measured:measured,
            sign:sign,length:length,track_y:track_y,half_thickness:thickness/2.0,
            bevel:mechanical_relations::planar_horizontal_face_bevel_run(thickness,nominal),
            stations:stations};
        let shallow=0.0;
        let steep=-sign*limit;
        let raised=_toe_clearance(shallow,frame);
        let lowered=_toe_clearance(steep,frame);
        // Half the existing contact tolerance reserves space for imperfect
        // section alignment; this is an explicit study allowance, not an ICD.
        let clearance=tolerance/2.0;
        if raised.ok!=true || lowered.ok!=true
            || raised.minimum_clearance_m<clearance || lowered.minimum_clearance_m>clearance {
            return #{ok:false,error:"terrain-contact target is outside root travel",
                side:side,raised:raised,lowered:lowered};
        }
        for iteration in 0..32 {
            let angle=(shallow+steep)/2.0;
            let sample=_toe_clearance(angle,frame);
            if sample.ok!=true {return sample;}
            if sample.minimum_clearance_m>=clearance {shallow=angle;} else {steep=angle;}
        }
        let planned=_toe_clearance(shallow,frame);
        expected.push(#{name:joints[index],target_rad:shallow});
        evidence.push(#{side:side,source_tick:snapshot.sim_tick,target_rad:shallow,
            nominal_target_rad:if index==0 {-nominal} else {nominal},
            planned_clearance:planned});
    }
    #{ok:true,expected_angles:expected,evidence:evidence}
}

/// Airborne opening is a commanded mechanism pose, not terrain contact.
/// Reuse the source-owned nominal deployment targets; never fit an unreachable
/// surface while flying or claim that this pose establishes rover egress.
fn root_deployment_plan() {
    let status = griffin_surface_ops::landed_status();
    if status.ok != true { return #{ok: false, error: "physical landing status unavailable"}; }
    if status.landed { return landed_root_deployment_plan(); }
    let joints = griffin_spec::ramp_root_joint_names();
    let port = griffin_spec::physical_ramp_port_deployment_angle_rad();
    let starboard = griffin_spec::physical_ramp_starboard_deployment_angle_rad();
    if joints.len() != 2 || port == () || starboard == () {
        return #{ok: false, error: "airborne deployment pose unavailable in SysML"};
    }
    #{ok: true, mode: "airborne_pose", expected_angles: [
        #{name: joints[0], target_rad: port},
        #{name: joints[1], target_rad: starboard}
    ]}
}

fn deploy_roots(expected) {
    // Lower the roots only after all intermediate sections reach their
    // source-defined level deployment targets.
    let joints = griffin_spec::ramp_root_joint_names();
    if joints.len() != 2 {
        return #{ok: false, error: "SysML must name both top-deck ramp hinges"};
    }
    let port_angle = expected[0].target_rad;
    let starboard_angle = expected[1].target_rad;
    if port_angle == () || starboard_angle == () {
        return #{ok: false, error: "physical ramp deployment angles are missing from SysML"};
    }
    let command=_begin_root_motion(expected,unfold_event_contract().roots_commanded);
    if command.ok!=true{return command;}
    notify_kind("Griffin solid side ramps are deploying after touchdown.", "info");
    print("[griffin] atomic physical egress ramp angle command accepted");
    #{ok: true, command: command,motion:command.motion,
        port_angle_rad: port_angle, starboard_angle_rad: starboard_angle}
}
