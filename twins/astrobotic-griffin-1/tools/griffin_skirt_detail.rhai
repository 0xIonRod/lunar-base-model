// Source-owned, render-only engine-bay edge and attachment reconstruction.
import "griffin_geometry" as geometry;
import "griffin_spec" as spec;
import "griffin_tank_finish" as finish;
import "lunco://scripting/tools/assembly_builder" as builder;
import "lunco://scripting/tools/sysml_requirements" as requirements;

fn required(model, prefix, name) {
    let value=model.value(prefix+name);
    if value==() {throw("Missing skirt detail source: "+prefix+name);}
    value
}
fn append(ops, plan) {
    if !plan.ok {throw("Skirt detail geometry rejected: "+plan);}
    for op in plan.ops {ops.push(op);} ops
}
fn owned(ops, path, material) {
    ops.push(finish::attr(path,"purpose","token","\"render\""));
    ops.push(finish::attr(path,"physics:collisionEnabled","bool","false"));
    ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:path,
        schemas:["PhysicsCollisionAPI","MaterialBindingAPI"]}});
    ops.push(finish::binding(path,material)); ops
}
fn material(ops, model, prefix, root, name, role) {
    finish::material(ops,root,name,
        finish::color_text(required(model,prefix,role+"Color")),
        required(model,prefix,role+"Metallic").to_string(),
        required(model,prefix,role+"Roughness").to_string())
}
fn plan(doc) {
    let root="/World/EngineSkirt";
    let current=query("InspectUsdDocument",#{doc_id:doc,path:root});
    if !current.prim.exists {throw("Open the canonical skirt document");}
    let detail=root+"/ThermalFinishDetail";
    let existing=query("QueryUsdPrim",#{doc_id:doc,path:detail,attrs:[]});
    if existing.type_name!=() && existing.type_name!="Xform" {
        throw("Skirt detail owner must be an Xform");
    }
    let model=requirements::model();
    let p="GriffinPresentationStudy::EngineBayDetail::";
    let g="GriffinPropulsionRequirements::GriffinEngineSkirtComponent::";
    let opening=required(model,g,"thermalOpeningApothemM");
    let stock=required(model,g,"shellWallAllowanceM");
    let outer=required(model,g,"railLengthM")/2.0-required(model,g,"shellBottomInsetM")-stock;
    let lower=required(model,g,"shellLowerYM");
    let hem=required(model,p,"hemWidthM");
    let height=required(model,p,"hemHeightM");
    let drop=required(model,p,"hemDropM");
    let seam_width=required(model,p,"seamWidthM");
    let seam_height=required(model,p,"seamHeightM");
    let fastener_radius=required(model,p,"fastenerRadiusM");
    let fastener_height=required(model,p,"fastenerHeightM");
    let fractions=required(model,p,"fastenerFaceFractions");
    if opening<=0.0 || hem<=0.0 || height<=0.0 || outer-opening<=2.0*hem
        || fastener_radius<=0.0 || fastener_height<=0.0 || fractions.len()!=2 {
        throw("Invalid skirt-detail envelope");
    }
    let profile=spec::visual_outer_body_profile_coordinates();
    if profile.len()!=8 {throw("Skirt requires the source octagonal profile");}
    let edge=root+"/Looks/BayEdgeMetal";
    let tape=root+"/Looks/BayApronSeams";
    let ops=[];
    if existing.type_name!=() {
        ops.push(#{RemovePrim:#{edit_target:"@root@",path:detail}});
        for path in [edge,tape] {
            ops.push(#{RemovePrim:#{edit_target:"@root@",path:path}});
        }
    }
    ops.push(finish::add(root,"ThermalFinishDetail","Xform"));
    ops=material(ops,model,p,root+"/Looks","BayEdgeMetal","edge");
    ops=material(ops,model,p,root+"/Looks","BayApronSeams","seam");
    for item in [["InnerHem",opening+hem],["OuterHem",outer+stock]] {
        let mesh=geometry::octagonal_ring_geometry(profile,item[1],
            lower+height/2.0-drop,hem,height);
        if !mesh.ok {throw("Invalid edge hem");}
        ops=append(ops,builder::mesh_shape_plan("@root@",detail,item[0],
            mesh.points,mesh.face_counts,mesh.face_indices,
            required(model,p,"edgeColor"),false));
        ops=owned(ops,detail+"/"+item[0],edge);
    }
    for i in 0..profile.len() {
        let a=profile[i]; let b=profile[(i+1)%profile.len()];
        let mid=(outer+opening)/2.0;
        let radius=sqrt(a.x*a.x+a.y*a.y);
        let angle=if a.y==0.0 {if a.x>0.0 {90.0}else{-90.0}}
            else {atan(a.x/a.y)*180.0/acos(-1.0)+if a.y<0.0 {180.0}else{0.0}};
        let name="ApronSeam"+i;
        let length=(outer-opening-2.0*hem)*radius;
        ops=append(ops,builder::cube_shape_plan("@root@",detail,name,1.0,
            [seam_width,seam_height,length],false));
        ops=append(ops,builder::place_plan("@root@",detail+"/"+name,
            [a.x*mid,lower-seam_height/2.0,a.y*mid],[0.0,angle,0.0],()));
        ops=owned(ops,detail+"/"+name,tape);
        for j in 0..fractions.len() {
            let f=fractions[j];
            if f<=0.0 || f>=1.0 {throw("Retaining station must lie inside its panel face");}
            let position=[(a.x*(1.0-f)+b.x*f)*mid,
                lower-fastener_height/2.0,(a.y*(1.0-f)+b.y*f)*mid];
            let name="Retainer"+i+"_"+j;
            ops=append(ops,builder::cylinder_shape_plan_axis("@root@",detail,name,
                fastener_radius,fastener_height,position,(),(),"Y",false));
            ops=owned(ops,detail+"/"+name,edge);
        }
    }
    ops.push(#{SetPrimDocumentation:#{edit_target:"@root@",path:detail,
        documentation:"Reference-informed edge hems, panel seams and retaining-head proxies. Intentional fitted overlaps with apron/liner; render-only, no mass or flight fastener claim."}});
    #{ok:true,doc_id:doc,generation:current.generation,ops:ops,
      hems:2,seams:8,retainers:16}
}

fn check(doc) {
    let root="/World/EngineSkirt";
    let detail=root+"/ThermalFinishDetail";
    let q=query("QueryUsdPrim",#{doc_id:doc,path:detail,children:true,attrs:[]});
    let model=requirements::model();
    let p="GriffinPresentationStudy::EngineBayDetail::";
    let sides=spec::visual_outer_body_profile_coordinates().len();
    let fractions=required(model,p,"fastenerFaceFractions");
    if q.type_name!="Xform" || q.children.len()!=2+sides*(1+fractions.len()) {
        throw("Skirt detail inventory differs from its source");
    }
    let checked=0;
    for path in q.children {
        let record=query("QueryUsdPrim",#{doc_id:doc,path:path,
            attrs:["purpose","physics:collisionEnabled","points","faceVertexCounts",
                "faceVertexIndices","doubleSided","radius","height","axis"],schemas:true});
        if record.document_generation!=q.document_generation
            || record.attrs.purpose!="render" || record.attrs["physics:collisionEnabled"]!=false
            || record.api_schemas.contains("PhysicsRigidBodyAPI") {
            throw("Skirt detail changed snapshot or acquired physics ownership: "+path);
        }
        if record.type_name=="Mesh" {
            let a=record.attrs;
            let metrics=geometry::closed_mesh_metrics(a.points,a.faceVertexCounts,a.faceVertexIndices);
            if !metrics.available || metrics.boundary!=0 || metrics.nonmanifold!=0
                || metrics.winding!=0 || metrics.volume<=0.0 || a.doubleSided!=false {
                throw("Invalid closed edge hem: "+path);
            }
        } else if record.type_name=="Cylinder" {
            if abs(record.attrs.radius-required(model,p,"fastenerRadiusM"))>0.000001
                || abs(record.attrs.height-required(model,p,"fastenerHeightM"))>0.000001
                || record.attrs.axis!="Y" {throw("Retainer dimensions differ from source");}
        } else if record.type_name!="Cube" {throw("Unexpected skirt-detail shape: "+path);}
        checked+=1;
    }
    #{ok:true,render_shapes:checked,scope:"Source inventory, closed edge hems and render-only ownership"}
}
