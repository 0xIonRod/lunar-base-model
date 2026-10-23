import "lunco://scripting/tools/sysml_requirements" as requirements;
import "griffin_visual_builder" as materials;
fn owner(){"FlipAirlessWheelRequirements::AirlessWheelVisual::"}
fn value(model,name){let result=model.value(owner()+name);if result==(){throw("Missing airless wheel source: "+name);}result}
fn empty_mesh(){#{points:[],face_vertex_counts:[],face_vertex_indices:[]}}
fn append(buffer,mesh,offset){
    let first=buffer.points.len();
    for p in mesh.points{buffer.points.push(vec3_array(p+offset));}
    for n in mesh.face_vertex_counts{buffer.face_vertex_counts.push(n);}
    for i in mesh.face_vertex_indices{buffer.face_vertex_indices.push(first+i);}
    buffer
}
fn polar(radius,angle){vec2(radius*cos(angle),radius*sin(angle))}
fn ring(inner,outer,width,segments){revolve_profile([vec2(inner,-width/2.0),vec2(outer,-width/2.0),vec2(outer,width/2.0),vec2(inner,width/2.0)],vec3(0.0,0.0,1.0),segments)}
fn cylinder(radius,length,direction,segments){revolve_profile([vec2(0.0,0.0),vec2(radius,0.0),vec2(radius,length),vec2(0.0,length)],direction,segments)}
fn groups(){let names=["Hub","Rim","Web0","Web1","Fasteners","Carrier","Blades0","Blades1"];
    let model=requirements::model();
    for i in 0..value(model,"cableRows"){names.push("Cables"+i.to_string());}
    for i in 0..(value(model,"springCount")/value(model,"springsPerMesh")){names.push("Springs"+i.to_string());}
    names
}
fn role(name){if name.starts_with("Cables") || name.starts_with("Springs"){"Cable"}else if name.starts_with("Blades"){"Blade"}else if name=="Carrier"{"Carrier"}else{"Metal"}}
fn create_plan(doc,target){
    if query("QueryUsdPrim",#{doc_id:doc,path:"/AirlessWheel"}).type_name!=(){throw("Wheel creation requires an empty source document");}
    #{ok:true,doc_id:doc,generation:query("InspectUsdDocument",#{doc_id:doc}).generation,ops:[
        #{SetStageMetrics:#{edit_target:target,metrics:#{meters_per_unit:1.0,up_axis:"Y"}}},
        #{SetStageDocumentation:#{edit_target:target,documentation:"FLIP airless wheel visual reconstruction; centred Z axle, SI/Y-up. Published 930 mm and 192-cable/four-row architecture; other dimensions/optical controls are estimates. Render-only; no deformable tire, mass or contact model. See requirements/flip_airless_wheel_requirements.sysml."}},
        #{AddPrim:#{edit_target:target,parent_path:"/",name:"AirlessWheel",type_name:"Xform",reference:(),reference_prim_path:""}},
        #{SetDefaultPrim:#{edit_target:target,default_prim:"/AirlessWheel"}},
        #{SetPrimKind:#{edit_target:target,path:"/AirlessWheel",kind:"component"}},
        #{AddPrim:#{edit_target:target,parent_path:"/AirlessWheel",name:"HubAxis",type_name:"Xform",reference:(),reference_prim_path:""}},
        #{SetAttribute:#{edit_target:target,path:"/AirlessWheel/HubAxis",name:"xformOp:translate",type_name:"double3",value:"(0,0,0)"}},
        #{SetAttribute:#{edit_target:target,path:"/AirlessWheel/HubAxis",name:"xformOpOrder",type_name:"token[]",value:"[\"xformOp:translate\"]"}},
        #{RemovePrim:#{edit_target:target,path:"/World"}}]}
}
fn geometry(name){
    if !groups().contains(name){throw("Select a declared wheel geometry group");}
    let m=requirements::model();let r=value(m,"radiusM");let w=value(m,"widthM");let segments=value(m,"ringSegments");let pi=acos(-1.0);
    let rim=value(m,"rimRadiusM");let hub=value(m,"hubRadiusM");let result=empty_mesh();
    if name=="Hub"{return append(result,ring(value(m,"axleApertureM"),hub,value(m,"hubWidthM"),segments),vec3(0.0,0.0,0.0));}
    if name=="Rim"{return append(result,ring(rim-value(m,"rimRadialStockM"),rim,value(m,"rimWidthM"),segments),vec3(0.0,0.0,0.0));}
    if name.starts_with("Web"){
        let side=if name=="Web0"{-1.0}else{1.0};let z=side*(value(m,"rimWidthM")-value(m,"webThicknessM"))/2.0;
        let count=value(m,"webCount");let half=value(m,"webAngularWidthRad")/2.0;let rake=value(m,"webRakeRad");
        for i in 0..count{let a=2.0*pi*(i+0.5)/count;
            let mesh=extrude_profile([polar(hub-value(m,"webThicknessM"),a-half),polar(rim,a+rake-half),polar(rim,a+rake+half),polar(hub-value(m,"webThicknessM"),a+half)],value(m,"webThicknessM"),profile_plane_xy());
            result=append(result,mesh,vec3(0.0,0.0,z));
        }return result;
    }
    if name=="Fasteners"{
        for side in [-1.0,1.0]{for i in 0..value(m,"webCount"){
            let a=2.0*pi*i/value(m,"webCount");let mesh=cylinder(value(m,"fastenerRadiusM"),value(m,"fastenerLengthM"),vec3(0.0,0.0,side),value(m,"cableSegments"));
            result=append(result,mesh,vec3(value(m,"fastenerPitchRadiusM")*cos(a),value(m,"fastenerPitchRadiusM")*sin(a),side*value(m,"hubWidthM")/2.0));
        }}return result;
    }
    if name=="Carrier"{return append(result,ring(r-value(m,"treadThicknessM"),r-value(m,"treadBladeThicknessM"),w,segments),vec3(0.0,0.0,0.0));}
    if name.starts_with("Blades"){
        let group=if name=="Blades0"{0}else{1};let count=value(m,"treadBladeCount");let half=value(m,"treadBladeAngularWidthRad")/2.0;
        for i in (group*count/2)..((group+1)*count/2){let a=2.0*pi*i/count;
            let mesh=extrude_profile([polar(r-value(m,"treadBladeThicknessM"),a-half),polar(r,a-half),polar(r,a+half),polar(r-value(m,"treadBladeThicknessM"),a+half)],w,profile_plane_xy());
            result=append(result,mesh,vec3(0.0,0.0,0.0));
        }return result;
    }
    if name.starts_with("Cables"){
        let row=parse_int(name.sub_string("Cables".len()));let rows=value(m,"cableRows");let count=value(m,"cablesPerRow");
        if row<0 || row>=rows{throw("Cable row is outside the source architecture");}
        let outer_z=w*(row.to_float()/(rows-1)-0.5)*0.85;
        let inner_z=if row<rows/2{-w/4.0}else{w/4.0};
        let lead=if row%2==0{value(m,"cableLeadRad")}else{-value(m,"cableLeadRad")};
        for i in 0..count{let a=2.0*pi*i/count;
            let start=vec3(value(m,"cableInnerRadiusM")*cos(a),value(m,"cableInnerRadiusM")*sin(a),inner_z)
                +vec3(-sin(a),cos(a),0.0)*value(m,"springRadiusM");
            let end=vec3(value(m,"cableOuterRadiusM")*cos(a+lead),value(m,"cableOuterRadiusM")*sin(a+lead),outer_z);
            result=append(result,cylinder(value(m,"cableRadiusM"),vlen(end-start),end-start,value(m,"cableSegments")),start);
        }return result;
    }
    if name.starts_with("Springs"){
        let group=parse_int(name.sub_string("Springs".len()));let count=value(m,"springCount");let batch=value(m,"springsPerMesh");
        let steps=value(m,"springTurns")*value(m,"springSamplesPerTurn");let wire=value(m,"springWireRadiusM");
        if group<0 || (group+1)*batch>count{throw("Spring group is outside the source architecture");}
        for i in (group*batch)..((group+1)*batch){
            let per_side=count/2;let a=2.0*pi*(i%per_side)/per_side;let axial=vec3(cos(a),sin(a),0.0);let tangential=vec3(-sin(a),cos(a),0.0);let up=vec3(0.0,0.0,1.0);
            let z=if i<per_side{-w/4.0}else{w/4.0};let first=result.points.len();
            for step in 0..(steps+1){let phase=2.0*pi*value(m,"springTurns")*step/steps;
                let normal=tangential*cos(phase)+up*sin(phase);
                let tangent=axial*value(m,"springLengthM")+(tangential*(-sin(phase))+up*cos(phase))*(2.0*pi*value(m,"springTurns")*value(m,"springRadiusM"));
                let binormal=vnorm(vcross(tangent,normal));
                let centre=axial*(rim+value(m,"springLengthM")*step/steps)+normal*value(m,"springRadiusM")+up*z;
                for corner in 0..4{let around=2.0*pi*corner/4;result.points.push(vec3_array(centre+wire*(normal*cos(around)+binormal*sin(around))));}
            }
            for step in 0..steps{for corner in 0..4{let a0=first+step*4+corner;let b0=first+step*4+(corner+1)%4;
                result.face_vertex_counts.push(4);for index in [a0,b0,b0+4,a0+4]{result.face_vertex_indices.push(index);}
            }}
            result.face_vertex_counts.push(4);for index in [first+3,first+2,first+1,first]{result.face_vertex_indices.push(index);}
            result.face_vertex_counts.push(4);for corner in 0..4{result.face_vertex_indices.push(first+steps*4+corner);}
        }return result;
    }
    throw("Unknown airless wheel geometry group: "+name);
}
fn creation_plan(doc,target,name){
    if !groups().contains(name){throw("Select a declared wheel geometry group");}
    let m=requirements::model();let color=value(m,role(name).to_lower()+"Color");let path="/AirlessWheel/"+name;
    // Numeric geometry is transported separately from this header. The API's
    // SetAttribute USD-literal boundary consumes the native f64 arrays; no
    // geometry is reconstructed or narrowed in the transport adapter.
    #{ok:true,doc_id:doc,generation:query("InspectUsdDocument",#{doc_id:doc}).generation,source_revision:m.source_revision,ops:[
        #{AddPrim:#{edit_target:target,parent_path:"/AirlessWheel",name:name,type_name:"Mesh",reference:(),reference_prim_path:""}},
        #{SetApiSchemas:#{edit_target:target,path:path,schemas:["PhysicsCollisionAPI"]}},
        #{SetAttribute:#{edit_target:target,path:path,name:"physics:collisionEnabled",type_name:"bool",value:"false"}},
        #{SetAttribute:#{edit_target:target,path:path,name:"purpose",type_name:"token",value:"\"render\""}},
        #{SetAttribute:#{edit_target:target,path:path,name:"subdivisionScheme",type_name:"token",value:"\"none\""}},
        #{SetAttribute:#{edit_target:target,path:path,name:"orientation",type_name:"token",value:"\"rightHanded\""}},
        #{SetAttribute:#{edit_target:target,path:path,name:"primvars:displayColor",type_name:"color3f[]",value:"[("+color[0].to_string()+","+color[1].to_string()+","+color[2].to_string()+")]"}}]}
}
fn material_plan(doc,target,selected){
    let paths=[];for name in groups(){if role(name)==selected{paths.push("/AirlessWheel/"+name);}}
    if paths.len()==0{throw("Select a declared wheel surface role");}
    let m=requirements::model();let prefix=selected.to_lower();
    let result=materials::griffin_surface_material_plan(doc,target,"/AirlessWheel",selected,paths,value(m,prefix+"Color"),value(m,prefix+"Metallic"),value(m,prefix+"Roughness"));
    result.doc_id=doc;result.generation=query("InspectUsdDocument",#{doc_id:doc}).generation;result.source_revision=m.source_revision;result
}
