import "social_surface_finish" as surface;
import "griffin_tank_finish" as finish;
import "griffin_bus_detail" as harness;
import "lunco://scripting/tools/assembly_builder" as builder;

// Pure, source-mounted visual detail plans. No imported mesh or physics edits.
fn datum(name) {
    let model=sysml_model("twin://astrobotic-griffin-1/requirements/griffin_presentation_study.sysml");
    let value=model.value("GriffinPresentationStudy::GeometryDetail::"+name);
    if value==() {throw("Missing geometry-detail source: "+name);}
    value
}
fn shape(name,position,scale,rotation,material) {
    #{name:name,position:position,scale:scale,rotation:rotation,material:material}
}
fn cube(ops,parent,spec) {
    ops=harness::append(ops,builder::cube_shape_plan("@root@",parent,spec.name,1.0,spec.scale,false));
    let path=parent+"/"+spec.name;
    ops=harness::append(ops,builder::place_plan("@root@",path,spec.position,spec.rotation,spec.scale));
    // Remove the generic shape planner's disabled collision API entirely.
    ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:path,schemas:["MaterialBindingAPI"]}});
    ops.push(surface::attr(path,"purpose","token","\"render\""));
    ops.push(finish::binding(path,spec.material));ops
}
fn bounds(doc,path) {
    let q=query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:["extent"]});
    if q.type_name!="Mesh" || q.attrs.extent==() || q.attrs.extent.len()!=2 {throw("Missing CAD extent: "+path);}
    q.attrs.extent
}
fn center(b) {[(b[0][0]+b[1][0])/2.0,(b[0][1]+b[1][1])/2.0,(b[0][2]+b[1][2])/2.0]}
fn griffin_specs(doc) {
    let path="/World/EngineSkirt/EngineSkirtShell";
    let q=query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:["points"]});
    if q.type_name!="Mesh" || q.attrs.points==() || q.attrs.points.len()!=32 {throw("Expected the source-owned finite-wall octagonal skirt");}
    let p=q.attrs.points;let specs=[];
    let width=datum("SeamWidthM");let depth=datum("SeamDepthM");let lift=depth/2.0-datum("SeamEmbedM");
    let material=path+"/BlanketSeams/Looks/SeamTape";
    for i in 0..8 {
        let j=(i+1)%8;
        let top=[(p[i][0]+p[j][0])/2.0,p[i][1],(p[i][2]+p[j][2])/2.0];
        let bottom=[(p[i+8][0]+p[j+8][0])/2.0,p[i+8][1],(p[i+8][2]+p[j+8][2])/2.0];
        let radius=sqrt(top[0]*top[0]+top[2]*top[2]);
        let nx=top[0]/radius;let nz=top[2]/radius;
        let height=top[1]-bottom[1];
        let dr=(top[0]-bottom[0])*nx+(top[2]-bottom[2])*nz;
        if height<=0.0 {throw("Invalid source skirt height");}
        let yaw=harness::angle(nx,nz)*180.0/acos(-1.0);
        let tilt=atan(dr/height)*180.0/acos(-1.0);
        specs.push(shape("Vertical"+i,[(top[0]+bottom[0])/2.0+nx*lift,(top[1]+bottom[1])/2.0,(top[2]+bottom[2])/2.0+nz*lift],
            [width,sqrt(height*height+dr*dr),depth],[tilt,yaw,0.0],material));
        let band=0;
        for f in datum("SeamBandFractions") {
            let a=[p[i+8][0]+(p[i][0]-p[i+8][0])*f,bottom[1]+height*f,p[i+8][2]+(p[i][2]-p[i+8][2])*f];
            let b=[p[j+8][0]+(p[j][0]-p[j+8][0])*f,a[1],p[j+8][2]+(p[j][2]-p[j+8][2])*f];
            let length=sqrt((b[0]-a[0])*(b[0]-a[0])+(b[2]-a[2])*(b[2]-a[2]));
            specs.push(shape("Band"+band+"Face"+i,[(a[0]+b[0])/2.0+nx*lift,a[1],(a[2]+b[2])/2.0+nz*lift],
                [length,width,depth],[tilt,yaw,0.0],material));band+=1;
        }
    }
    specs
}
fn chassis_specs(doc) {
    let specs=[];let width=datum("EdgeWidthM");let depth=datum("EdgeDepthM");let embed=datum("EdgeEmbedM");
    let dark="/FLIP/PresentationLooks/DarkHousing";let frame="/FLIP/PresentationLooks/Frame";
    for item in [["SkinL",1.0],["SkinR",-1.0]] {
        let b=bounds(doc,"/FLIP/CADVisuals/"+item[0]);let c=center(b);let height=b[1][1]-b[0][1];let length=b[1][2]-b[0][2];
        let x=if item[1]>0.0 {b[1][0]+depth/2.0-embed}else{b[0][0]-depth/2.0+embed};
        for side in [0,1] {
            let y=if side==0 {b[0][1]+width/2.0}else{b[1][1]-width/2.0};
            specs.push(shape(item[0]+"Rail"+side,[x,y,c[2]],[depth,width,length],[0.0,0.0,0.0],frame));
        }
        let index=0;
        for f in datum("ChassisDivisionFractions") {
            specs.push(shape(item[0]+"Joint"+index,[x,c[1],b[0][2]+length*f],[depth,height-width*2.0,width],[0.0,0.0,0.0],dark));index+=1;
        }
        for side in [0,1] {
            let z=if side==0 {b[0][2]+width/2.0}else{b[1][2]-width/2.0};
            specs.push(shape(item[0]+"Corner"+side,[x,c[1],z],[depth,height,width],[0.0,0.0,0.0],frame));
        }
    }
    for item in [["SkinFront",-1.0],["SkinRear",1.0]] {
        let b=bounds(doc,"/FLIP/CADVisuals/"+item[0]);let c=center(b);let height=b[1][1]-b[0][1];let length=b[1][0]-b[0][0];
        let z=if item[1]>0.0 {b[1][2]+depth/2.0-embed}else{b[0][2]-depth/2.0+embed};
        for side in [0,1] {
            let y=if side==0 {b[0][1]+width/2.0}else{b[1][1]-width/2.0};
            specs.push(shape(item[0]+"Rail"+side,[c[0],y,z],[length,width,depth],[0.0,0.0,0.0],frame));
        }
        let hw=length*datum("HatchWidthFraction");let hh=height*datum("HatchHeightFraction");let hd=datum("HatchDepthM");let border=datum("HatchBorderM");
        specs.push(shape(item[0]+"HatchSeal",[c[0],c[1],z],[hw,hh,hd],[0.0,0.0,0.0],dark));
        specs.push(shape(item[0]+"HatchCover",[c[0],c[1],z+item[1]*hd/2.0],[hw-border*2.0,hh-border*2.0,hd],[0.0,0.0,0.0],"/FLIP/PresentationLooks/Chassis"));
    }
    specs
}
fn panel_specs(doc) {
    let specs=[];let parent="/FLIP/SolarMechanism/CADVisuals/";
    let points=query("QueryUsdPrim",#{doc_id:doc,path:parent+"SolarFrameL",attrs:["points"]}).attrs.points;
    if points==() || points.len()!=8 {throw("Expected eight CAD panel-frame corners");}
    // Existing frame vertices supply the moving panel's long axis and front normal.
    let dx=points[1][0]-points[0][0];let dy=points[1][1]-points[0][1];
    let length=sqrt(dx*dx+dy*dy);let nx=dy/length;let ny=-dx/length;
    let tilt=atan(-dx/dy)*180.0/acos(-1.0);
    let width=datum("PanelCapWidthM");let depth=datum("PanelCapDepthM");let embed=datum("EdgeEmbedM");
    let normalStock=abs((points[2][0]-points[0][0])*nx+(points[2][1]-points[0][1])*ny);
    let offset=normalStock/2.0+depth/2.0-embed;
    for name in ["SolarFrameL","SolarFrameR","SolarFrameFront","SolarFrameRear"] {
        let b=bounds(doc,parent+name);let c=center(b);
        let longSide=name=="SolarFrameL" || name=="SolarFrameR";
        let dimensions=if longSide {[depth,length,width]}else{[depth,width,b[1][2]-b[0][2]]};
        specs.push(shape(name+"Cap",[c[0]+nx*offset,c[1]+ny*offset,c[2]],dimensions,[0.0,0.0,tilt],"/FLIP/PresentationLooks/Frame"));
        if longSide {
            let cornerLength=datum("PanelCornerLengthM");let cornerWidth=datum("PanelCornerWidthM");
            for end in [-1.0,1.0] {
                let along=end*(length-cornerLength)/2.0;
                specs.push(shape(name+if end<0.0 {"LowerCorner"}else{"UpperCorner"},
                    [c[0]+dx/length*along+nx*(offset+depth/2.0),c[1]+dy/length*along+ny*(offset+depth/2.0),c[2]],
                    [depth,cornerLength,cornerWidth],[0.0,0.0,tilt],"/FLIP/PresentationLooks/DarkHousing"));
            }
        }
    }
    specs
}
fn root(group) {
    if group=="blanket" {return "/World/EngineSkirt/EngineSkirtShell/BlanketSeams";}
    if group=="chassis" {return "/FLIP/CADVisuals/TopDeck/GeometryDetail";}
    if group=="panel" {return "/FLIP/SolarMechanism/CADVisuals/SolarBackplate/GeometryDetail";}
    throw("Unknown geometry-detail group: "+group)
}
fn specs(doc,group) {
    if group=="blanket" {return griffin_specs(doc);}
    if group=="chassis" {return chassis_specs(doc);}
    if group=="panel" {return panel_specs(doc);}
    throw("Unknown geometry-detail group: "+group)
}
fn plan(doc,group) {
    let path=root(group);let parts=path.split("/");let name=parts.pop();let parent="";
    for part in parts {if part!="" {parent+="/"+part;}}
    let q=query("InspectUsdDocument",#{doc_id:doc,path:parent});
    if !q.prim.exists {throw("Open the exact geometry owner: "+parent);}
    if query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:[]}).type_name!=() {throw("Detail already exists; inspect before revising: "+path);}
    let ops=[surface::add(parent,name,"Xform")];
    if group=="blanket" {
        ops.push(surface::add(path,"Looks","Scope"));
        ops=finish::material(ops,path+"/Looks","SeamTape",surface::text_color(datum("SeamColor")),datum("SeamMetallic").to_string(),datum("SeamRoughness").to_string());
    }
    let shapes=specs(doc,group);
    for spec in shapes {ops=cube(ops,path,spec);}
    #{doc_id:doc,generation:q.generation,ops:ops,shape_count:shapes.len()}
}
fn check(doc,group) {
    let path=root(group);let shapes=specs(doc,group);
    for spec in shapes {
        let p=query("QueryUsdPrim",#{doc_id:doc,path:path+"/"+spec.name,attrs:["xformOp:translate","xformOp:scale","purpose","physics:collisionEnabled"],relationships:true});
        if p.type_name!="Cube" || p.attrs.purpose!="render" || p.attrs["physics:collisionEnabled"]!=false {throw("Invalid visual-only detail: "+spec.name);}
        for axis in 0..3 {
            if abs(p.attrs["xformOp:translate"][axis]-spec.position[axis])>0.000001 || abs(p.attrs["xformOp:scale"][axis]-spec.scale[axis])>0.000001 {throw("Detail left its source mount: "+spec.name);}
        }
        if p.relationships["material:binding"]!=[spec.material] {throw("Missing detail finish: "+spec.name);}
    }
    #{ok:true,group:group,visual_shapes:shapes.len(),scope:"Source-mounted visual geometry only; unchanged source CAD and physical surfaces"}
}
