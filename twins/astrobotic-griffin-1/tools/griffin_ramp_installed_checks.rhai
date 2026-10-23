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
    for bank in spec::ramp_names(){for section in ["DeckSection","MiddleSection","MiddleSection/ToeSection"]{
        let r=query("QueryUsdPrim",#{doc_id:vehicle.doc_id,path:ROOT+"/"+bank+"/"+section+"/RampTrackPort",attrs:[]});
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
    for name in spec::ramp_names(){for section in ["DeckSection","MiddleSection","MiddleSection/ToeSection"]{for rail in ["OuterRail","InnerRail"]{
        let r=query("QueryUsdPrim",#{doc_id:doc,path:ROOT+"/"+name+"/"+section+"/"+rail,attrs:[],geometry_bounds:true});
        if r.geometry_bounds==() || r.geometry_bounds.min==(){throw("Stowed rail bounds missing");}lowest=min(lowest,r.geometry_bounds.min[1]);count+=1;
    }}}
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
fn step(state){
    if state.done{return state;}
    if state.doc==(){state=resolve(state);state.waits+=1;if state.waits>600{throw("Exact source documents did not become queryable");}return state;}
    if requirements::model().source_revision!=state.source_revision{throw("Source revision changed during installed observation");}
    if state.index<6{state=record(state,installed::component(state.doc,ROOT,state.docs,state.index/3,state.index%3));}
    else if state.mode=="requirements"{
        let i=state.index-6;
        if i<6{state=record(state,installed::mass(state.doc,ROOT,i/3,i%3));}
        else if i<20{state=record(state,installed::joint(state.doc,ROOT,joint_names()[i-6]));}
        else if i<24{state=record(state,transition(state.doc,(i-20)/2,(i-20)%2));}
        else{state.done=true;}
    }else if state.mode=="stow"{
        let i=state.index-6;
        if i<14{state=record(state,installed::joint(state.doc,ROOT,joint_names()[i]));}
        else if i==14{state=record(state,root_axes(state.doc));}
        else if i==15{state=record(state,rail_leg_clearance(state.doc));}
        else{state.done=true;}
    }else if state.mode=="touchdown"{
        let i=state.index-6;if i<4{state=record(state,toe_contact(state,i/2,i%2));}else{state.done=true;}
    }else{throw("Unknown installed ramp gate");}
    state.index+=1;state
}
fn verdict(state){#{ok:true,verdict:"pass",check_count:state.count,pass_count:state.count,source_revision:state.source_revision,
    metrics:#{mode:state.mode,source_vehicle:"vehicles/griffin_1.usda",doc_id:state.doc,measurements:state.measurements,
        scope:"Read-only authored integration; standalone component geometry and dynamic deployment have independent cases"}}}
