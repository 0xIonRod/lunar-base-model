// Render-only reconstruction around the existing admitted A110 force owners.
// One corner is one authoring task. No actuator, mass or propulsion port edits.
import "griffin_spec" as spec;
import "lunco://scripting/tools/sysml_requirements" as requirements;
import "lunco://scripting/tools/assembly_builder" as frames;
fn owner(){"GriffinPropulsionRequirements::GriffinAttitudeEngineAssembly::"}
fn add(parent,name,kind){#{AddPrim:#{edit_target:"@root@",parent_path:parent,name:name,type_name:kind,reference:(),reference_prim_path:()}}}
fn attr(path,name,kind,value){#{SetAttribute:#{edit_target:"@root@",path:path,name:name,type_name:kind,value:value}}}
fn pod_name(sx,sz){"RcsPodMount"+if sx>0.0{"PX"}else{"NX"}+if sz>0.0{"PZ"}else{"NZ"}}
fn stations(doc,root,sx,sz){
    let m=requirements::model();let mount_y=m.value(owner()+"bellHeightM")/2.0+m.value(owner()+"collarHeightM")/2.0;let result=[];
    for jet in spec::rcs_port_mapping(){
        let name=jet.model_name.sub_string(0,jet.model_name.len()-5);let path=root+"/"+name;
        let r=query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:["xformOp:translate","xformOp:rotateXYZ"],schemas:true});
        if r==() || r.type_name!="Xform" || r.attrs==() || r.attrs["xformOp:translate"]==(){throw("RCS source projection is not current: "+path);}
        let p=vec3_from(r.attrs["xformOp:translate"]);
        if !r.api_schemas.contains("LunCoForceActuatorAPI"){throw("Existing RCS force owner required");}
        if p.x*sx<=0.0 || p.z*sz<=0.0{continue;}
        let nozzle=frames::mount_frame_in_body(doc,root,path+"/Nozzle");
        if !nozzle.ok{throw("Nozzle rigid frame is unavailable");}
        let q=quat_from(nozzle.value.rotation);let center=vec3_from(nozzle.value.translation)+qrot(q,vec3(0.0,mount_y,0.0));
        result.push(#{name:name,center:center,rotation:q,root_position:p,nozzle:path+"/Nozzle",record:r});
    }
    if result.len()!=3{throw("Select one complete sourced corner cluster");}result
}
fn beam(parent,name,start,end,width,thickness,width_axis,color){
    let path=parent+"/"+name;
    [add(parent,name,"Mesh"),#{TaperedBeamMesh:#{edit_target:"@root@",path:path,start:vec3_array(start),end:vec3_array(end),
        width_axis:vec3_array(width_axis),start_half_width:width/2.0,end_half_width:width/2.0,thickness:thickness,display_color:color,collision_enabled:false}},
        attr(path,"purpose","token","\"render\"")]
}
fn pod_plan(doc,root,sx,sz){
    if abs(sx)!=1.0 || abs(sz)!=1.0{throw("Select a signed bus corner");}
    let m=requirements::model();let selected=stations(doc,root,sx,sz);let name=pod_name(sx,sz);let path=root+"/"+name;
    let existing=query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:[]});if existing.type_name==(){throw("Existing corner support required");}
    let plate=m.value(owner()+"podMountPlateThicknessM");let overlap=m.value(owner()+"podMountPlateOverlapM");
    let chamber=m.value(owner()+"chamberRadiusM");let outer=chamber+m.value(owner()+"clampRadialStockM");
    let clamp_height=m.value(owner()+"clampAxialLengthM");let inset=m.value(owner()+"clampSeatingOverlapM");
    let color=spec::_sysml_model_value("silverDisplayColor");let radial=vnorm(vec3(sx,0.0,sz));let tangent=vec3(-radial.z,0.0,radial.x);
    let center=vec3(0.0,0.0,0.0);for s in selected{center+=s.root_position;}center*=1.0/selected.len().to_float();
    let deck=spec::_sysml_model_value("deckDimensions");let body=spec::_sysml_model_value("bodyMount");let deck_center=spec::_sysml_model_value("deckCenter");
    let profile=spec::visual_outer_body_profile_coordinates();let chamfer=(1.0+abs(profile[0].x))/2.0;
    let deck_y=body.y+deck_center.y+deck.y/2.0;
    let foot=vec3(sx*deck.x/2.0*chamfer,deck_y+plate/2.0,sz*deck.z/2.0*chamfer);
    // Place the spine inboard of the nozzle axes and solar facet plane. Separate saddles reach the
    // actual chamber centres of upward, downward and horizontal members.
    let spine=center-radial*(2.0*m.value(owner()+"exitRadiusM")+overlap+plate);
    let top=deck_y;for s in selected{top=max(top,s.center.y+overlap);}
    let low=vec3(spine.x,deck_y+plate/2.0,spine.z);let high=vec3(spine.x,top,spine.z);
    let ops=[#{RemovePrim:#{edit_target:"@root@",path:path}},add(root,name,"Xform")];
    // The pod is replaced as one unit. Always create its shoe; inspecting the
    // old pod here would incorrectly skip creation after RemovePrim.
    let dimensions=[overlap*4.0,plate,overlap*3.0];
    let shoe=frames::cube_shape_plan("@root@",path,"DeckShoe",1.0,dimensions,false);
    if !shoe.ok{throw("Deck shoe plan unavailable");}for op in shoe.ops{ops.push(op);}
    let placed=frames::place_plan("@root@",path+"/DeckShoe",vec3_array(foot),[0.0,-atan(sx/sz)*180.0/acos(-1.0),0.0],dimensions);
    if !placed.ok{throw("Deck shoe placement unavailable");}for op in placed.ops{ops.push(op);}
    ops.push(attr(path+"/DeckShoe","purpose","token","\"render\""));
    ops.push(attr(path+"/DeckShoe","primvars:displayColor","color3f[]","[("+color[0]+", "+color[1]+", "+color[2]+") ]"));
    if vlen(low-foot)>overlap{
        for op in beam(path,"DeckOutrigger",foot,low,overlap,plate,tangent,color){ops.push(op);}
        for op in beam(path,"Brace",foot,vec3(spine.x,top-overlap,spine.z),plate,plate,tangent,color){ops.push(op);}
    }
    for op in beam(path,"Spine",low,high,overlap,plate,tangent,color){ops.push(op);}
    let observations=[];
    for s in selected{
        let clamp=path+"/"+s.name+"Clamp";
        let a=chamber-inset;let b=outer;let h=clamp_height/2.0;
        ops.push(add(path,s.name+"Clamp","Mesh"));
        ops.push(#{RevolveProfileMesh:#{edit_target:"@root@",path:clamp,profile:[[a,-h],[b,-h],[b,h],[a,h]],axis:[0.0,1.0,0.0],angular_segments:32,
            normal_crease_angle_deg:60.0,display_color:color,collision_enabled:false}});
        let pose=frames::place_plan("@root@",clamp,vec3_array(s.center),frames::mount_xyz_deg_from_quat(quat_array(s.rotation)),[1.0,1.0,1.0]);
        if !pose.ok{throw("Clamp placement unavailable");}for op in pose.ops{ops.push(op);}
        ops.push(attr(clamp,"purpose","token","\"render\""));
        // Meet the collar radially. A fixed bus-radial direction can turn
        // a thick saddle through the bore when its spine is offset sideways.
        let axis=qrot(s.rotation,vec3(0.0,1.0,0.0));
        let start=vec3(spine.x,s.center.y,spine.z);
        let elbow=start+axis*vdot(s.center-start,axis);
        let outward=elbow-s.center;
        if vlen(outward)<outer+plate{throw("RCS spine cannot clear the chamber bore");}
        outward=vnorm(outward);let end=s.center+outward*(outer-inset);
        if vlen(elbow-start)>0.000001{
            for op in beam(path,s.name+"AxialStay",start,elbow,plate,plate,outward,color){ops.push(op);}
        }
        for op in beam(path,s.name+"Saddle",elbow,end,plate,plate,axis,color){ops.push(op);}
        observations.push(#{actuator:s.record.path,clamp_center_m:vec3_array(s.center),saddle_end_m:vec3_array(end)});
    }
    #{ok:true,doc_id:doc,generation:existing.document_generation,source_revision:m.source_revision,ops:ops,
        root:path,deck_foot_m:vec3_array(foot),spine_low_m:vec3_array(low),spine_high_m:vec3_array(high),stations:observations}
}

// Read actual installed ring vertices and chamber frames. Authoring plans are
// deliberately not the observation: moving a clamp breaks this check.
fn installed_clamp(doc,root,index){
    let m=requirements::model();let measurements=[];let failures=[];
    let chamber=m.value(owner()+"chamberRadiusM");let stock=m.value(owner()+"clampRadialStockM");
    let inset=m.value(owner()+"clampSeatingOverlapM");let length=m.value(owner()+"clampAxialLengthM");
    for jet in [spec::rcs_port_mapping()[index]]{
        let name=jet.model_name.sub_string(0,jet.model_name.len()-5);let nozzle=frames::mount_frame_in_body(doc,root,root+"/"+name+"/Nozzle");
        if !nozzle.ok{throw("Native nozzle frame missing");}
        let p=vec3_from(nozzle.value.translation);let q=quat_from(nozzle.value.rotation);
        let height=m.value(owner()+"bellHeightM")/2.0+m.value(owner()+"collarHeightM")/2.0;
        let expected=p+qrot(q,vec3(0.0,height,0.0));
        let actuator=query("QueryUsdPrim",#{doc_id:doc,path:root+"/"+name,attrs:["xformOp:translate"]});let a=vec3_from(actuator.attrs["xformOp:translate"]);
        let pod=root+"/"+pod_name(if a.x>0.0{1.0}else{-1.0},if a.z>0.0{1.0}else{-1.0});let path=pod+"/"+name+"Clamp";
        let ring=query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:["points"],schemas:true});let pose=frames::mount_frame_in_body(doc,root,path);
        if ring.type_name!="Mesh" || ring.attrs.points==() || !pose.ok{throw("Installed clamp geometry unavailable");}
        let inner=1.0e30;let outer=0.0;let lo=1.0e30;let hi=-1.0e30;
        for vertex in ring.attrs.points{let radius=sqrt(vertex[0]*vertex[0]+vertex[2]*vertex[2]);inner=min(inner,radius);outer=max(outer,radius);lo=min(lo,vertex[1]);hi=max(hi,vertex[1]);}
        let error=vlen(vec3_from(pose.value.translation)-expected);let axis_error=vlen(qrot(quat_from(pose.value.rotation),vec3(0.0,1.0,0.0))-qrot(q,vec3(0.0,1.0,0.0)));
        let spine=query("QueryUsdPrim",#{doc_id:doc,path:pod+"/Spine",attrs:["points"]});
        let spine_center=vec3(0.0,0.0,0.0);for v in spine.attrs.points{spine_center+=vec3_from(v);}spine_center*=1.0/spine.attrs.points.len().to_float();
        let radial=vnorm(vec3(a.x,0.0,a.z));let inset_distance=vdot(vec3(spine_center.x-a.x,0.0,spine_center.z-a.z),radial);
        let saddle=query("QueryUsdPrim",#{doc_id:doc,path:pod+"/"+name+"Saddle",attrs:["points","faceVertexCounts","faceVertexIndices"]});
        let axis=qrot(q,vec3(0.0,1.0,0.0));let nearest=1.0e30;let cursor=0;
        // Closest projected point on every actual stock edge, not just the
        // vertices: a beam crossing the open chamber bore must fail.
        for count in saddle.attrs.faceVertexCounts{
            for i in 0..count{
                let va=vec3_from(saddle.attrs.points[saddle.attrs.faceVertexIndices[cursor+i]])-expected;
                let vb=vec3_from(saddle.attrs.points[saddle.attrs.faceVertexIndices[cursor+(i+1)%count]])-expected;
                let pa=va-axis*vdot(va,axis);let pb=vb-axis*vdot(vb,axis);let delta=pb-pa;
                let u=if vdot(delta,delta)<1.0e-15{0.0}else{max(0.0,min(1.0,-vdot(pa,delta)/vdot(delta,delta)))};
                nearest=min(nearest,vlen(pa+delta*u));
            }cursor+=count;
        }
        let pass=inset_distance<0.0 && nearest>=chamber-inset-0.00001 && error<0.00001 && axis_error<0.00001 && abs(inner-(chamber-inset))<0.00001 && abs(outer-(chamber+stock))<0.00001 && abs(hi-lo-length)<0.00001 && !ring.api_schemas.contains("PhysicsCollisionAPI");
        if !pass{failures.push(path);}
        measurements.push(#{path:path,center_residual_m:error,axis_residual:axis_error,spine_inset_m:-inset_distance,saddle_axis_clearance_m:nearest,inner_radius_m:inner,outer_radius_m:outer,axial_length_m:hi-lo,passes:pass});
    }
    #{ok:failures.len()==0 && measurements.len()==1,failures:failures,measurements:measurements,doc_id:doc}
}
