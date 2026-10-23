// Read the canonical vehicle reference in the production composition.
// Explicit document reads measure authored geometry, independently of UI focus.
// Reusable component geometry is qualified by the three component cases;
// this gate measures reference equivalence, installation and native joints.
import "griffin_ramp_mechanism_checks" as installed;
import "griffin_ramp_packaging" as packaging;
import "griffin_spec" as spec;
import "lunco://scripting/tools/assembly_builder" as frames;
import "lunco://scripting/tools/sysml_requirements" as requirements;
const ROOT="/Griffin1SurfaceOps/Lander";
const OWN="GriffinRampRequirements::GriffinEgressRamp::";
fn dependencies(){#{modelica_entities:[],entity_reads:[],entity_writes:[],query_reads:["AnalyzeSysml","QueryUsdPrim","QueryUsdPrims","ReadActiveTwinContract","ListOpenDocuments"],required_inputs:[#{owner:"sysml.twin-analysis",identity:twin_name()}]}}
fn begin(mode){
    let model=requirements::model();let paths=[];
    for label in ["root","middle","toe"]{paths.push(model.value(packaging::component_owner(label)+"::componentAsset"));}
    for path in paths{cmd("OpenFile",#{path:twin_root()+"/"+path});}
    #{mode:mode,paths:paths,docs:#{},doc:(),index:0,count:0,measurements:[],done:false,waits:0,source_revision:model.source_revision}
}
fn record(state,result){
    if result.passes==false || result.ok==false{throw("Installed ramp observation failed: "+result.to_string());}
    state.count+=1;state.measurements.push(result);state
}
fn resolve(state){
    let found=[];
    for path in state.paths{
        let id=();for doc in query("ListOpenDocuments").open_documents{
            if doc.kind=="usd" && doc.origin.path==twin_root()+"/"+path{id=doc.doc_id;}
        }
        if id==(){return state;}found.push(id);
    }
    for i in 0..found.len(){let r=query("QueryUsdPrim",#{doc_id:found[i],path:"/RampSection",attrs:[]});if r.type_name!="Xform"{return state;}}
    let vehicle=query("QueryUsdPrim",#{path:ROOT,attrs:[]});if vehicle.doc_id==(){return state;}
    // The root spec can be queryable before its reference dependencies.
    // Admission requires actual composed stock in every referenced section.
    for binding in spec::ramp_track_bindings(){let bank=binding.body;for section in ["DeckSection","MiddleSection","MiddleSection/ToeSection"]{
        let r=query("QueryUsdPrim",#{doc_id:vehicle.doc_id,path:ROOT+"/"+bank+"/"+section+"/"+if binding.track==0{"RampTrackPort"}else{"RampTrackStarboard"},attrs:[]});
        if r.type_name!="Mesh"{return state;}
    }}
    state.doc=vehicle.doc_id;state.docs=#{root:found[0],middle:found[1],toe:found[2]};state
}
fn joint_names(){let names=[];for pair in spec::ramp_flight_latch_bindings(){names.push(pair.hinge);names.push(pair.latch);}for side in ["port","starboard"]{names.push(spec::physical_ramp_transition_joint_name(side));}names}
fn transition(doc,bank,track){
    let model=requirements::model();let side=if bank==0{"port"}else{"starboard"};let path=ROOT+"/"+spec::physical_ramp_transition_body_name(side);
    let child=path+"/"+if track==0{"RampTrackPort"}else{"RampTrackStarboard"};
    let r=query("QueryUsdPrim",#{doc_id:doc,path:child,attrs:["physics:collisionEnabled","xformOp:scale","xformOp:translate"],schemas:true});
    let old=query("QueryUsdPrim",#{doc_id:doc,path:path+"/"+spec::physical_ramp_transition_contact_child_name(),attrs:[]});
    let width=model.value(packaging::owner()+"transitionTrackWidthM");let length=model.value(OWN+"physicalRampDeckTransitionLengthM");let tolerance=model.value(OWN+"physicalRampDeckTransitionInterfaceToleranceM");
    let size=r.attrs["xformOp:scale"];let position=r.attrs["xformOp:translate"];let station=abs(spec::rover_wheel_station_z()[0]);
    if r.type_name!="Cube" || size==() || position==(){throw("Native transition stock unavailable");}
    #{passes:r.attrs["physics:collisionEnabled"]==true && r.api_schemas.contains("PhysicsCollisionAPI") && old.type_name==()
        && abs(size[0]-length)<=tolerance && abs(size[1]-spec::ramp_surface_thickness_m())<=tolerance && abs(size[2]-width)<=tolerance
        && abs(position[2]-if track==0{station}else{-station})<=tolerance,
        path:child,dimensions_m:size,station_m:position[2],doc_id:doc,document_generation:r.document_generation,stage_generation:r.stage_generation}
}
fn root_axes(doc){
    let axes=[];let model=requirements::model();
    for name in spec::ramp_names(){let pose=frames::mount_local_transform(doc,ROOT+"/"+name);if !pose.ok{throw("Root frame unavailable");}axes.push(vec3_array(qrot(quat_from(pose.value.rotation),vec3(1.0,0.0,0.0))));}
    let tolerance=model.value(OWN+"physicalRampRootAxisMirrorTolerance");let angle=model.value(OWN+"physicalRampRootStowedAngleRad");
    #{passes:abs(axes[0][0]+axes[1][0])<=tolerance && abs(axes[0][1]-axes[1][1])<=tolerance
        && abs(axes[0][0]-cos(angle))<=tolerance && abs(axes[0][1]-sin(angle))<=tolerance && abs(axes[0][2])<=tolerance && abs(axes[1][2])<=tolerance,
        measured_forward_axes:axes,doc_id:doc}
}
fn rail_leg_clearance(doc){
    let lowest=1.0e30;let highest=-1.0e30;let count=0;
    for binding in spec::ramp_track_bindings(){
        let guides=if binding.track==0{["OuterRail","CenterRailPort"]}else{["InnerRail","CenterRailStarboard"]};
        for section in ["DeckSection","MiddleSection","MiddleSection/ToeSection"]{for rail in guides{
            let r=query("QueryUsdPrim",#{doc_id:doc,path:ROOT+"/"+binding.body+"/"+section+"/"+rail,attrs:[],geometry_bounds:true});
            if r.geometry_bounds==() || r.geometry_bounds.min==(){throw("Active stowed guide bounds missing");}
            lowest=min(lowest,r.geometry_bounds.min[1]);count+=1;
        }}
    }
    for leg in ["LegPX","LegNX","LegPZ","LegNZ"]{for shape in ["StrutOuter","StrutInner","ShockPiston","FootPad","MountClevisOuter","MountClevisInner","FootPadPlate","MountAxle","BodyMountArm","FootPadCollider"]{
        let r=query("QueryUsdPrim",#{doc_id:doc,path:ROOT+"/"+leg+"/LandingLegVisual/"+shape,attrs:[],geometry_bounds:true});
        if r.geometry_bounds==() || r.geometry_bounds.max==(){throw("Landing leg bounds missing");}highest=max(highest,r.geometry_bounds.max[1]);count+=1;
    }}
    #{passes:lowest-highest>=requirements::model().value(OWN+"rampSectionGeometryToleranceM"),vertical_clearance_m:lowest-highest,measured_members:count,doc_id:doc}
}
// Native convex toe vertices in component space, transformed into the nominal
// level, fully extended bank. This is a static flat-plane check, not DEM fit.
fn toe_contact(state,bank,track){
    let model=requirements::model();let side=if bank==0{"Port"}else{"Starboard"};
    let path="/RampSection/"+if track==0{"RampTrackPort"}else{"RampTrackStarboard"};
    let r=query("QueryUsdPrim",#{doc_id:state.docs.toe,path:path,attrs:[],collision_geometry:true});
    if r.collision_geometry==() || r.collision_geometry.shape!="convex_hull"{throw("Native convex toe stock unavailable");}
    let prefix=model.value(packaging::component_owner("root")+"::lengthM")+model.value(packaging::component_owner("middle")+"::lengthM");
    let entry=model.value(packaging::component_owner("root")+"::entryAxisYM");
    let angle=model.value(OWN+"physicalRamp"+side+"DeploymentAngleRad");
    let q=quat_from_euler_xyz_deg(vec3(0.0,if bank==0{0.0}else{180.0},angle*180.0/acos(-1.0)));
    let origin=frames::mount_local_transform(state.doc,ROOT+"/"+spec::ramp_names()[bank]);if !origin.ok{throw("Installed root origin unavailable");}
    let touchdown=model.value("Griffin1Requirements::PublicMissionContext::landingVehicleReferenceTouchdownY");let terrain=model.value("Griffin1Requirements::PublicMissionContext::siteSurfaceY");
    let toe_length=model.value(packaging::component_owner("toe")+"::lengthM");let minimum=1.0e30;let maximum=-1.0e30;let corners=0;
    // The toe's last four vertices include the upper edge and mitered lower
    // edge. Distinguish them from the section entry using its half-span.
    for v in r.collision_geometry.vertices{if v[0]>toe_length/2.0{
        let p=vec3_from(origin.value.translation)+qrot(q,vec3(prefix+v[0],v[1]-entry,v[2]));
        let y=touchdown+p.y;minimum=min(minimum,y);maximum=max(maximum,y);corners+=1;
    }}
    let tolerance=model.value(OWN+"physicalRampTerrainContactToleranceM");
    #{passes:corners==4 && minimum>=terrain-tolerance && maximum<=terrain+tolerance,
        minimum_toe_y_m:minimum,maximum_toe_y_m:maximum,terrain_y_m:terrain,native_corners:corners,path:path,bank:bank,
        doc_id:state.doc,toe_doc_id:state.docs.toe,source_revision:state.source_revision}
}
fn component_track(state,index,stage){
    let model=requirements::model();let binding=spec::ramp_track_bindings()[index];
    let labels=["root","middle","toe"];let label=labels[stage];let paths=[ROOT+"/"+binding.body+"/DeckSection",ROOT+"/"+binding.body+"/MiddleSection",ROOT+"/"+binding.body+"/MiddleSection/ToeSection"];
    let path=paths[stage];let source=state.docs[label];let place=packaging::bank_placements(model,state.docs,binding.bank);
    let expected=if stage==0{place.deck}else if stage==1{place.middle}else{place.toe};
    if stage<2{expected.translation[2]+=binding.station;}
    let pose=frames::mount_local_transform(state.doc,path);if !pose.ok{throw("Track local frame unavailable");}
    let error=vlen(vec3_from(pose.value.translation)-vec3_from(expected.translation));
    let forward_error=vlen(qrot(quat_from(pose.value.rotation),vec3(1.0,0.0,0.0))-qrot(quat_from(expected.rotation),vec3(1.0,0.0,0.0)));
    let children=query("QueryUsdPrim",#{doc_id:source,path:"/RampSection",attrs:[],children:true}).children;
    let parts=0;let disabled=0;let failures=[];
    for child in children{
        let native=query("QueryUsdPrim",#{doc_id:source,path:child,attrs:["xformOp:translate"],geometry_bounds:true});
        if native.geometry_bounds==(){continue;}
        let target=path+child.sub_string(12);
        let selected=native.geometry_bounds.center[2]*if binding.track==0{1.0}else{-1.0}>0.0 && !child.ends_with("/HingeBarrel");
        let observed=query("QueryUsdPrim",#{doc_id:state.doc,path:target,attrs:["xformOp:translate","physics:collisionEnabled"],schemas:true});
        if selected{
            parts+=1;let position=native.attrs["xformOp:translate"];if position==(){position=[0.0,0.0,0.0];}position[2]-=binding.station;
            if observed.active!=true || observed.type_name!=native.type_name || observed.attrs["xformOp:translate"]==()
                || vlen(vec3_from(observed.attrs["xformOp:translate"])-vec3_from(position))>0.00001{failures.push(target);}
            if child.contains("/RampTrack") && (observed.attrs["physics:collisionEnabled"]!=true || !observed.api_schemas.contains("PhysicsCollisionAPI")){failures.push("Missing track collider: "+target);}
        }else{disabled+=1;if observed.active==true{failures.push("Opposite stock remains active: "+target);}}
    }
    let body=ROOT+"/"+binding.body;let bodies=[ROOT,body,body+"/MiddleSection",body+"/MiddleSection/ToeSection"];
    let joint_path=ROOT+"/"+[binding.root,binding.middle,binding.toe][stage];
    let hinge=query("QueryUsdPrim",#{doc_id:state.doc,path:joint_path,attrs:["physics:collisionEnabled"],rels:["physics:body0","physics:body1"]});
    let independent=hinge.relationships["physics:body0"]==[bodies[stage]] && hinge.relationships["physics:body1"]==[bodies[stage+1]] && hinge.attrs["physics:collisionEnabled"]==false;
    let mount_ok=true;
    if stage==0{
        let mounted=query("QueryUsdPrim",#{doc_id:state.doc,path:body,attrs:["lunco:operational_width_m","lunco:track_station_z_m"],rels:["lunco:mount:frame","physics:filteredPairs"],schemas:true});
        mount_ok=mounted.api_schemas.contains("LunCoMountPlugAPI") && mounted.relationships["lunco:mount:frame"]==[body+"/MountFrame"]
            && mounted.attrs["lunco:track_station_z_m"]==binding.station && abs(mounted.attrs["lunco:operational_width_m"]-model.value(OWN+"physicalTrackEnvelopeWidthM"))<0.00001
            && mounted.relationships["physics:filteredPairs"]==[ROOT+"/"+spec::physical_ramp_transition_body_name(if binding.bank==0{"port"}else{"starboard"})];
    }
    #{passes:independent && mount_ok && parts>=42 && disabled>=43 && failures.len()==0 && error<0.00001 && forward_error<0.00001,
        path:path,independent_body_binding:independent,mount_interface_ok:mount_ok,active_members:parts,disabled_members:disabled,placement_residual_m:error,orientation_residual:forward_error,failures:failures,doc_id:state.doc}
}
fn track_mass(state,index,stage){
    let binding=spec::ramp_track_bindings()[index];let paths=[ROOT+"/"+binding.body];paths.push(paths[0]+"/MiddleSection");paths.push(paths[1]+"/ToeSection");
    let r=query("QueryUsdPrim",#{doc_id:state.doc,path:paths[stage],attrs:["physics:mass","physics:centerOfMass","physics:diagonalInertia"]});
    let model=requirements::model();let m=model.value(OWN+"physicalTrackSectionMassKg");let l=model.value(packaging::component_owner(["root","middle","toe"][stage])+"::lengthM");
    let w=model.value(OWN+"physicalTrackEnvelopeWidthM");let t=spec::ramp_surface_thickness_m();
    let expected=[m*(w*w+t*t)/12.0,m*(l*l+w*w)/12.0,m*(l*l+t*t)/12.0];
    let residual=0.0;for i in 0..3{residual=max(residual,abs(expected[i]-r.attrs["physics:diagonalInertia"][i]));}
    let centre=[l/2.0,model.value(OWN+"rampSurfaceCenterYM")-if stage==0{model.value(packaging::component_owner("root")+"::entryAxisYM")}else{0.0},if stage==0{binding.station}else{0.0}];
    #{passes:abs(r.attrs["physics:mass"]-m)<0.001 && residual<0.01 && vlen(vec3_from(centre)-vec3_from(r.attrs["physics:centerOfMass"]))<0.00001,
        path:paths[stage],mass_kg:r.attrs["physics:mass"],inertia_residual_kg_m2:residual,doc_id:state.doc}
}
fn step(state){
    if state.done{return state;}
    if state.doc==(){state=resolve(state);state.waits+=1;if state.waits>600{throw("Exact source documents did not become queryable");}return state;}
    if requirements::model().source_revision!=state.source_revision{throw("Source revision changed during installed observation");}
    if state.index<12{state=record(state,component_track(state,state.index/3,state.index%3));}
    else if state.mode=="requirements"{
        let i=state.index-12;
        if i<12{state=record(state,track_mass(state,i/3,i%3));}
        else if i<38{state=record(state,installed::joint(state.doc,ROOT,joint_names()[i-12]));}
        else if i<42{state=record(state,transition(state.doc,(i-38)/2,(i-38)%2));}
        else{state.done=true;}
    }else if state.mode=="stow"{
        let i=state.index-12;
        if i<26{state=record(state,installed::joint(state.doc,ROOT,joint_names()[i]));}
        else if i==26{state=record(state,root_axes(state.doc));}
        else if i==27{state=record(state,rail_leg_clearance(state.doc));}
        else{state.done=true;}
    }else if state.mode=="touchdown"{
        let i=state.index-12;if i<4{state=record(state,toe_contact(state,i/2,i%2));}else{state.done=true;}
    }else{throw("Unknown installed ramp gate");}
    state.index+=1;state
}
fn verdict(state){#{ok:true,verdict:"pass",check_count:state.count,pass_count:state.count,source_revision:state.source_revision,
    metrics:#{mode:state.mode,source_vehicle:"vehicles/griffin_1.usda",doc_id:state.doc,measurements:state.measurements,
        scope:"Four independent referenced wheel tracks, native anchors, latches and mass properties; deployment has a separate production case"}}}
