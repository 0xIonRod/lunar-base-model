import "lunco://scripting/tools/assembly_builder" as assembly;
import "lunco://scripting/tools/sysml_requirements" as requirements;
import "griffin_spec" as spec;

fn attribute(target,path,name,type_name,value){#{SetAttribute:#{edit_target:target,path:path,name:name,type_name:type_name,value:value}}}
fn add(target,parent,name,kind,reference){#{AddPrim:#{edit_target:target,parent_path:parent,name:name,type_name:kind,reference:reference,reference_prim_path:""}}}
fn fixture_header_plan(doc,target){
    let ops=[#{SetStageMetrics:#{edit_target:target,metrics:#{meters_per_unit:1.0,up_axis:"Y"}}},
        add(target,"/World","PhysicsScene","PhysicsScene",()),
        attribute(target,"/World/PhysicsScene","physics:gravityDirection","vector3f","(0.0, -1.0, 0.0)"),
        attribute(target,"/World/PhysicsScene","physics:gravityMagnitude","float","0.0"),
        add(target,"/World","Scenario","Scope",()),add(target,"/World/Scenario","Mission","Scope",()),
        #{SetApiSchemas:#{edit_target:target,path:"/World/Scenario/Mission",schemas:["LunCoProgramAPI"]}},
        attribute(target,"/World/Scenario/Mission","info:implementationSource","token","\"sourceAsset\""),
        attribute(target,"/World/Scenario/Mission","info:sourceAsset","asset","@../scenarios/tests/griffin_solar_collision.rhai@"),
        add(target,"/World","TestLight","DistantLight",()),
        attribute(target,"/World/TestLight","inputs:intensity","float","1000.0"),
        attribute(target,"/World/TestLight","xformOp:rotateXYZ","double3","(-45.0, 25.0, 0.0)"),
        attribute(target,"/World/TestLight","xformOpOrder","token[]","[\"xformOp:rotateXYZ\"]")];
    #{ok:true,doc_id:doc,generation:query("InspectUsdDocument",#{doc_id:doc}).generation,ops:ops}
}
fn fixture_opening_plan(doc,target,index){
    let model=requirements::model();let own="GriffinSolarRequirements::GriffinSolarCollisionStudy::";
    let layout=spec::solar_installed_cell_layout(index);let witnesses=model.value(own+"openingWitnesses");
    if layout==() || index<0 || index>=witnesses.len(){throw("Panel opening witness is unavailable");}
    let point=vec3_from(witnesses[index]);let path="/World/Panel"+index.to_string()+"/OpeningProbe";
    let position=[-layout.local_cell_width_m/2.0+point.x*layout.local_cell_width_m/layout.columns,
        model.value(own+"initialNormalOffsetM"),-layout.cell_depth_m/2.0+point.z*layout.pitch_z_m];
    let ops=[add(target,"/World/Panel"+index.to_string(),"OpeningProbe","Sphere",()),
        #{SetApiSchemas:#{edit_target:target,path:path,schemas:["PhysicsRigidBodyAPI","PhysicsMassAPI","PhysicsCollisionAPI"]}},
        attribute(target,path,"radius","double",model.value(own+"probeRadiusM").to_string()),
        attribute(target,path,"physics:mass","float",model.value(own+"probeMassKg").to_string()),
        attribute(target,path,"physics:collisionEnabled","bool","true"),
        attribute(target,path,"physics:velocity","vector3f","(0.0, "+(-model.value(own+"initialSpeedMPerS")).to_string()+", 0.0)")];
    let pose=assembly::place_plan(target,path,position,(),());if !pose.ok{return pose;}for op in pose.ops{ops.push(op);}
    #{ok:true,doc_id:doc,generation:query("InspectUsdDocument",#{doc_id:doc}).generation,ops:ops}
}
fn fixture_panel_plan(doc,target,source_doc,index){
    let model=requirements::model();let own="GriffinSolarRequirements::GriffinSolarCollisionStudy::";
    let assets=model.value("GriffinSolarRequirements::GriffinSolarArrayAssembly::componentAssets");
    let origin=query("InspectUsdDocument",#{doc_id:source_doc}).origin;
    if index<0 || index>=assets.len() || origin.File==() || !origin.File.path.ends_with("/"+assets[index]){throw("Match the fixture station to its canonical source component");}
    let path="/World/Panel"+index.to_string();let ops=[add(target,"/World","Panel"+index.to_string(),"Xform","../"+assets[index]),
        #{SetApiSchemas:#{edit_target:target,path:path,schemas:["PhysicsRigidBodyAPI"]}},
        attribute(target,path,"physics:kinematicEnabled","bool","true")];
    let placement=assembly::place_plan(target,path,[index*model.value(own+"laneSpacingM"),0.0,0.0],(),());if !placement.ok{return placement;}for op in placement.ops{ops.push(op);}
    let stock=mesh_boxes(source_doc,"/SolarPanel/ArrayBackplane").boxes[0];
    let radius=model.value(own+"probeRadiusM");let mass=model.value(own+"probeMassKg");let offset=model.value(own+"initialNormalOffsetM");let speed=model.value(own+"initialSpeedMPerS");
    for side in ["Top","Bottom"]{
        let sign=if side=="Top"{1.0}else{-1.0};let name="Probe"+side;let probe=path+"/"+name;
        ops.push(add(target,path,name,"Sphere",()));ops.push(#{SetApiSchemas:#{edit_target:target,path:probe,schemas:["PhysicsRigidBodyAPI","PhysicsMassAPI","PhysicsCollisionAPI"]}});
        ops.push(attribute(target,probe,"radius","double",radius.to_string()));ops.push(attribute(target,probe,"physics:mass","float",mass.to_string()));
        ops.push(attribute(target,probe,"physics:collisionEnabled","bool","true"));
        ops.push(attribute(target,probe,"physics:velocity","vector3f","(0.0, "+(-sign*speed).to_string()+", 0.0)"));
        let pose=assembly::place_plan(target,probe,[stock.center.x+sign*stock.dimensions.x/4.0,stock.center.y+sign*offset,stock.center.z],(),());if !pose.ok{return pose;}for op in pose.ops{ops.push(op);}
    }
    #{ok:true,doc_id:doc,generation:query("InspectUsdDocument",#{doc_id:doc}).generation,ops:ops}
}

// Recover separate closed rectangular stock members from the composed meshes.
// A whole-panel convex hull would fill the leg opening and equipment recess.
fn mesh_boxes(doc,path){
    let record=assembly::composed_query(doc,#{path:path,attrs:["points","faceVertexCounts","faceVertexIndices"]});
    if record.type_name!="Mesh"{throw("Panel stock mesh unavailable: "+path);}
    let pose=assembly::mount_local_transform(doc,path);
    if !pose.ok || pose.value.translation!=[0.0,0.0,0.0] || pose.value.rotation!=[0.0,0.0,0.0,1.0]{throw("Panel stock requires its component-local identity frame");}
    let points=record.attrs.points;let counts=record.attrs.faceVertexCounts;let indices=record.attrs.faceVertexIndices;
    if points==() || counts==() || indices==() || points.len()==0{throw("Panel stock topology unavailable");}
    let parents=[];for i in 0..points.len(){parents.push(i);}
    let cursor=0;let faces=[];let edges=#{};
    for count in counts{
        if count!=4 || cursor+count>indices.len(){throw("Panel stock requires closed quad boxes");}
        let face=[];
        for j in 0..count{
            let a=indices[cursor+j];let b=indices[cursor+(j+1)%count];
            if a<0 || a>=points.len() || b<0 || b>=points.len() || a==b{throw("Invalid panel stock edge");}
            let key=min(a,b).to_string()+":"+max(a,b).to_string();edges[key]=if edges[key]==(){1}else{edges[key]+1};
            let x=a;while parents[x]!=x{x=parents[x];}
            let y=b;while parents[y]!=y{y=parents[y];}
            parents[max(x,y)]=min(x,y);face.push(a);
        }
        faces.push(face);cursor+=count;
    }
    if cursor!=indices.len(){throw("Unused panel stock indices");}
    for key in edges.keys(){if edges[key]!=2{throw("Panel stock is not closed");}}
    let groups=#{};let order=[];let roots=[];let face_totals=#{};
    for i in 0..points.len(){let representative=i;while parents[representative]!=representative{representative=parents[representative];}let key=representative.to_string();roots.push(key);if groups[key]==(){groups[key]=[];order.push(key);face_totals[key]=0;}groups[key].push(i);}
    for face in faces{let key=roots[face[0]];face_totals[key]+=1;}
    let boxes=[];
    for key in order{
        let members=groups[key];if members.len()!=8{throw("Panel stock is not an eight-corner box");}
        let lo=vec3_from(points[members[0]]);let hi=lo;
        for i in members{let p=vec3_from(points[i]);lo=vec3(min(lo.x,p.x),min(lo.y,p.y),min(lo.z,p.z));hi=vec3(max(hi.x,p.x),max(hi.y,p.y),max(hi.z,p.z));}
        let corners=[];
        for i in members{
            let p=vec3_from(points[i]);let bits=0;
            for axis in 0..3{let value=points[i][axis];let low=vec3_array(lo)[axis];let high=vec3_array(hi)[axis];if low>=high || (value!=low && value!=high){throw("Panel stock is not an axis-aligned solid box");}if value==high{bits+=if axis==0{1}else if axis==1{2}else{4};}}
            if corners.contains(bits){throw("Repeated panel stock corner");}corners.push(bits);
        }
        if face_totals[key]!=6{throw("Panel stock does not have six faces");}
        boxes.push(#{center:(lo+hi)*0.5,dimensions:hi-lo});
    }
    #{boxes:boxes,record:record}
}
fn plan(doc,target,index){
    let model=requirements::model();let assets=model.value("GriffinSolarRequirements::GriffinSolarArrayAssembly::componentAssets");
    if index<0 || index>=assets.len(){throw("Unknown Griffin panel station");}
    let origin=query("InspectUsdDocument",#{doc_id:doc}).origin;
    if origin.File==() || !origin.File.path.ends_with("/"+assets[index]){throw("Select the matching canonical solar component document");}
    let root="/SolarPanel/PanelCollision";let found=query("QueryUsdPrim",#{doc_id:doc,path:root,attrs:[]});
    if found.type_name!=(){throw("Panel collision shell already exists");}
    let ops=[#{AddPrim:#{edit_target:target,parent_path:"/SolarPanel",name:"PanelCollision",type_name:"Scope",reference:(),reference_prim_path:""}},
        #{SetAttribute:#{edit_target:target,path:root,name:"purpose",type_name:"token",value:"\"proxy\""}},
        #{SetAttribute:#{edit_target:target,path:root,name:"visibility",type_name:"token",value:"\"invisible\""}}];
    #{ok:true,doc_id:doc,generation:query("InspectUsdDocument",#{doc_id:doc}).generation,source_revision:model.source_revision,ops:ops}
}
// Bounded stock batches keep inspection and operation construction below the
// shared interpreter budget. The source mesh is re-read at each generation.
fn stock_plan(doc,target,source,start,end){
    if source!="Frame" && source!="ArrayBackplane"{throw("Unknown panel stock role");}
    let root="/SolarPanel/PanelCollision";
    if query("QueryUsdPrim",#{doc_id:doc,path:root,attrs:[]}).type_name!="Scope"{throw("Create the panel collision owner first");}
    let stock=mesh_boxes(doc,"/SolarPanel/"+source);
    if start<0 || end<=start || end>stock.boxes.len() || end-start>4{throw("Select at most four source stock members");}
    let ops=[];
    for i in start..end{
            let box=stock.boxes[i];let name=source+i.to_string();let path=root+"/"+name;
            if query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:[]}).type_name!=(){throw("Panel stock collider already exists");}
            ops.push(#{AddPrim:#{edit_target:target,parent_path:root,name:name,type_name:"Cube",reference:(),reference_prim_path:""}});
            ops.push(#{SetApiSchemas:#{edit_target:target,path:path,schemas:["PhysicsCollisionAPI"]}});
            ops.push(#{SetAttribute:#{edit_target:target,path:path,name:"size",type_name:"double",value:"1.0"}});
            ops.push(#{SetAttribute:#{edit_target:target,path:path,name:"physics:collisionEnabled",type_name:"bool",value:"true"}});
            let pose=assembly::place_plan(target,path,vec3_array(box.center),(),vec3_array(box.dimensions));
            if !pose.ok{return pose;}for op in pose.ops{ops.push(op);}
    }
    #{ok:true,doc_id:doc,generation:query("InspectUsdDocument",#{doc_id:doc}).generation,stock_count:stock.boxes.len(),ops:ops}
}
fn stock_checks(doc,root,source,start,end){
    let tolerance=requirements::model().value("GriffinSolarRequirements::GriffinSolarArrayAssembly::collisionMatchToleranceM");
    if tolerance==() || tolerance<0.0{throw("Panel collision matching tolerance is unavailable");}
    let stock=mesh_boxes(doc,root+"/"+source);
    if start<0 || end!=start+1 || end>stock.boxes.len(){throw("Inspect one cooked source stock member per bounded check");}
    let checks=[];
    for i in start..end{
        let path=root+"/PanelCollision/"+source+i.to_string();
        let record=assembly::composed_query(doc,#{path:path,attrs:["physics:collisionEnabled"],collision_geometry:true,collision_bounds:true});
        let geometry=record.collision_geometry;let box=stock.boxes[i];let valid=record.type_name=="Cube" && record.attrs["physics:collisionEnabled"]==true;
        valid=valid && record.document_generation==stock.record.document_generation && record.stage_generation==stock.record.stage_generation;
        valid=valid && geometry!=() && geometry.shape=="convex_hull" && geometry.vertices!=() && geometry.vertices.len()==8;
        let matched=[];let maximum_error=0.0;
        if valid{
            for vertex in geometry.vertices{
                let corner=vec3_from(vertex);let bits=0;
                for axis in 0..3{
                    let value=vertex[axis];let lo=vec3_array(box.center-box.dimensions*0.5)[axis];let hi=vec3_array(box.center+box.dimensions*0.5)[axis];
                    let error=min(abs(value-lo),abs(value-hi));maximum_error=max(maximum_error,error);
                    if error>tolerance{valid=false;}
                    if abs(value-hi)<=tolerance{bits+=if axis==0{1}else if axis==1{2}else{4};}
                }
                if matched.contains(bits){valid=false;}matched.push(bits);
            }
        }
        checks.push(t_true(valid,path+": enabled cooked collider matches actual closed visual stock; maximum corner error "+maximum_error.to_string()+" m"));
    }
    #{checks:checks,stock_count:stock.boxes.len(),doc_id:doc,document_generation:stock.record.document_generation,stage_generation:stock.record.stage_generation}
}
