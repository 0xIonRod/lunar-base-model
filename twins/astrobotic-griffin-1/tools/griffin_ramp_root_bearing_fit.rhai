// Read-only root/pedestal mating certificate. Rotation about the pin leaves
// axial intervals and distance from its axis invariant. Filled stock bounds
// are conservative; only an actual coaxial Z Cylinder gets its exact radius.
import "griffin_ramp_packaging" as packaging;
import "lunco://scripting/tools/assembly_builder" as frames;
import "lunco://scripting/tools/sysml_requirements" as requirements;
import "usd_geometry_inspection" as inspection;
fn interval_gap(a,b){max(a[0]-b[1],b[0]-a[1])}
fn pose(p){transform(vec3_from(p.translation),quat_from(p.rotation),vec3(1.0,1.0,1.0))}
fn range_in_axis(box,axis_pose){
    let inverse=pose(frames::mount_transform_inverse(axis_pose));let zmin=();let zmax=();let rmax=0.0;let distance_max=0.0;
    // Only the axial interval and outer radial bound use corners. The lower
    // radial bound of the fixed axis-aligned stem is derived separately.
    for x in [box.min[0],box.max[0]]{for y in [box.min[1],box.max[1]]{for z in [box.min[2],box.max[2]]{
        let p=transform_apply_point(inverse,vec3(x,y,z));
        if zmin==(){zmin=p.z;zmax=p.z;}else{zmin=min(zmin,p.z);zmax=max(zmax,p.z);}
        rmax=max(rmax,vlen(vec3(p.x,p.y,0.0)));distance_max=max(distance_max,vlen(p));
    }}}
    #{axial:[zmin,zmax],outer:rmax,distance_max:distance_max}
}
fn inspect(doc,root_doc,bearing_doc,bank,station){
    if (bank!=0 && bank!=1) || (station!=0 && station!=1){throw("Select one of the four source bearing stations");}
    let model=requirements::model();let own="GriffinRampRootBearingRequirements::RampRootBearing::";
    let lander=model.value(packaging::owner()+"landerPath");
    let name="RampMount"+if bank==0{"Port"}else{"Starboard"}+if station==0{"InnerRear"}else{"InnerFront"};
    let stem_path=lander+"/"+name;let house=stem_path+"Bearing";
    let pin_name=if (bank==0 && station==1)||(bank==1 && station==0){"CenterRailPortJointPin"}else{"CenterRailStarboardJointPin"};
    let root=lander+"/"+packaging::bank_names(model)[bank]+"/DeckSection";
    let pin_frame=frames::mount_frame_in_body(doc,model.value(packaging::owner()+"usdRootPath"),root+"/"+pin_name);
    let house_frame=frames::mount_frame_in_body(doc,model.value(packaging::owner()+"usdRootPath"),house+"/Housing");
    if !pin_frame.ok || !house_frame.ok{throw("Mating frames must have native rigid SI transforms");}
    let scene=frames::mount_local_transform(doc,model.value(packaging::owner()+"usdRootPath"));if !scene.ok{throw("Scene frame is unavailable");}
    let pin_map=frames::mount_transform_compose(scene.value,pin_frame.value);let house_map=frames::mount_transform_compose(scene.value,house_frame.value);let pin_pose=pose(pin_map);let house_pose=pose(house_map);
    let delta=transform_apply_point(pose(frames::mount_transform_inverse(pin_map)),transform_apply_point(house_pose,vec3(0.0,0.0,0.0)));
    let coaxial_error=vlen(vec3(delta.x,delta.y,0.0));
    let pin_axis=qrot(quat_from(pin_map.rotation),vec3(0.0,0.0,1.0));let house_axis=qrot(quat_from(house_map.rotation),vec3(0.0,0.0,1.0));
    let sine=vlen(vcross(pin_axis,house_axis));let cosine=abs(vdot(pin_axis,house_axis));
    let axis_error=sine*model.value(own+"pinLengthM")/2.0;
    if house_axis.x!=0.0 || house_axis.y!=0.0{throw("Certificate requires the fixture's fixed Z-axis housings");}
    let attrs=["points","faceVertexCounts","faceVertexIndices","physics:collisionEnabled","purpose"];
    let stock=query("QueryUsdPrim",#{doc_id:bearing_doc,path:"/RootBearing/Housing",attrs:attrs});
    let measured=query("QueryUsdPrims",#{doc_id:doc,paths:[house+"/Housing",stem_path,stem_path+"DeckShoe",root+"/"+pin_name],attrs:attrs+["radius","height"],geometry_bounds:true});
    if !inspection::same_snapshot(measured.records){throw("Mating snapshot is incoherent");}
    let ring=measured.records[0];let stem=measured.records[1];let shoe=measured.records[2];let pin=measured.records[3];
    let geometry_matches=ring.type_name=="Mesh";
    for attr in attrs{if ring.attrs[attr]!=stock.attrs[attr]{geometry_matches=false;}}
    let origin=transform_apply_point(pin_pose,vec3(0.0,0.0,0.0));let b=stem.geometry_bounds;
        let dx=max(max(b.min[0]-origin.x,origin.x-b.max[0]),0.0);
    let dy=max(max(b.min[1]-origin.y,origin.y-b.max[1]),0.0);
    let stem_range=range_in_axis(b,pin_map);
    let axis_difference=vlen(pin_axis-vec3(0.0,0.0,if pin_axis.z<0.0{-1.0}else{1.0}));
    let stem_inner=max(vlen(vec3(dx,dy,0.0))-stem_range.distance_max*axis_difference,0.0);
    let ring_range=range_in_axis(ring.geometry_bounds,pin_map);
    let tolerance=model.value(own+"geometryToleranceM");let pin_radius=model.value(own+"pinRadiusM");
    let connected=b.max[1]>origin.y-model.value(own+"outerRadiusM") && b.max[1]<origin.y-model.value(own+"innerRadiusM")
        && b.min[0]<=origin.x && b.max[0]>=origin.x && abs(b.min[1]-shoe.geometry_bounds.max[1])<=tolerance;
    let pin_contains=ring_range.axial[0]>=-pin.attrs.height/2.0-tolerance && ring_range.axial[1]<=pin.attrs.height/2.0+tolerance;
    let pass=geometry_matches && coaxial_error<=tolerance && axis_error<=tolerance && connected && pin_contains && pin.attrs.radius==pin_radius;
    let source_frame=frames::mount_local_transform(root_doc,"/RampSection");
    if !source_frame.ok{throw("Root source frame is unavailable");}let source_rotation=quat_from(source_frame.value.rotation);
    if vlen(vec3_from(source_frame.value.translation))!=0.0 || source_rotation.x!=0.0 || source_rotation.y!=0.0 || source_rotation.z!=0.0{throw("Certificate requires the canonical component source frame");}
    let source_pin=query("QueryUsdPrim",#{doc_id:root_doc,path:"/RampSection/"+pin_name,attrs:[]});let pivot=vec3_from(source_pin.world_position);
    let source=query("QueryUsdPrim",#{doc_id:root_doc,path:"/RampSection",children:true});
    let parts=query("QueryUsdPrims",#{doc_id:root_doc,paths:source.children,attrs:["radius","axis"],geometry_bounds:true});
    if !inspection::same_snapshot(parts.records){throw("Root stock snapshot is incoherent");}
    let uncertain=[];let count=0;let minimum=();
    for part in parts.records{
        let box=part.geometry_bounds;if box==(){if part.type_name!="Xform" && part.type_name!="Scope"{throw("Root stock is unmeasured");}continue;}
        let axial=[box.min[2]-pivot.z,box.max[2]-pivot.z];
        let xnear=max(max(box.min[0]-pivot.x,pivot.x-box.max[0]),0.0);let ynear=max(max(box.min[1]-pivot.y,pivot.y-box.max[1]),0.0);
        let inner=vlen(vec3(xnear,ynear,0.0));let outer=vlen(vec3(max(abs(box.min[0]-pivot.x),abs(box.max[0]-pivot.x)),max(abs(box.min[1]-pivot.y),abs(box.max[1]-pivot.y)),0.0));
        if part.type_name=="Cylinder" && part.attrs.axis=="Z" && part.world_position[0]==pivot.x && part.world_position[1]==pivot.y{inner=0.0;outer=part.attrs.radius;}
        for target in [#{name:"housing",axial:ring_range.axial,inner:(pin_radius+model.value(own+"minimumRadialClearanceM"))*cosine-coaxial_error-axis_error,outer:model.value(own+"outerRadiusM")+coaxial_error+axis_error},
            #{name:"stem",axial:stem_range.axial,inner:stem_inner,outer:stem_range.outer}]{
            let gap=max(interval_gap(axial,target.axial),max(inner-target.outer,target.inner-outer))-tolerance;count+=1;
            if minimum==() || gap<minimum{minimum=gap;}
            if gap<=0.0{uncertain.push(#{part:part.path,target:target.name,gap_m:gap});pass=false;}
        }
    }
    #{passes:pass,bank:bank,station:station,comparisons:count,minimum_certified_gap_m:minimum,uncertain:uncertain,
        target_paths:[house+"/Housing",stem_path],coaxial_error_m:coaxial_error,axis_alignment_error_m:axis_error,source_geometry_matches:geometry_matches,stem_connected:connected,pin_contains_housing:pin_contains,
        doc_id:doc,document_generation:ring.document_generation,stage_generation:ring.stage_generation,source_revision:model.source_revision,
        scope:"Entire root versus this housing and stem for any root angle; qualified source bore geometry required; other sections and loaded physics unaccepted"}
}
