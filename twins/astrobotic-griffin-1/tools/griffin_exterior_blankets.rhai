import "griffin_upper_visuals" as study;
import "griffin_tank_finish" as finish;
import "social_surface_finish" as surface;
import "social_geometry_detail" as geometry;
import "griffin_bus_detail" as harness;
import "griffin_insulation_detail" as wrapping;
import "lunco://scripting/tools/assembly_builder" as builder;

fn root() {"/GriffinBus/TankSupportPlate/ExteriorBlankets"}
fn bay(doc,index) {
    if index<0 || index>=8 {throw("Blanket bay must be one of the eight existing structural faces");}
    let upper=query("QueryUsdPrim",#{doc_id:doc,path:"/GriffinBus/PerimeterFrame",attrs:["points"]});
    if upper.type_name!="Mesh" || upper.attrs.points.len()!=128 {throw("Expected eight upper and eight lower stock-box frame segments");}
    let top=1.0e20;let bottom=-1.0e20;
    for i in 0..64 {top=min(top,upper.attrs.points[i][1]);bottom=max(bottom,upper.attrs.points[64+i][1]);}
    let a=upper.attrs.points[index*8+4];let b=upper.attrs.points[index*8+5];
    let center=[(a[0]+b[0])/2.0,0.0,(a[2]+b[2])/2.0];
    let radius=sqrt(center[0]*center[0]+center[2]*center[2]);
    let normal=[center[0]/radius,0.0,center[2]/radius];
    let width=sqrt((b[0]-a[0])*(b[0]-a[0])+(b[2]-a[2])*(b[2]-a[2]));
    let yaw=harness::angle(normal[0],normal[2])*180.0/acos(-1.0);
    let gap=study::datum("BlanketEdgeGapM");let depth=study::datum("BlanketThicknessM");
    let inset=study::datum("BlanketFaceInsetM")+depth/2.0;
    let position=[center[0]-normal[0]*inset,(top+bottom)/2.0,center[2]-normal[2]*inset];
    if top-bottom<=2.0*gap || width<=2.0*gap {throw("Source frame leaves no positive blanket bay");}
    #{position:position,scale:[width-2.0*gap,top-bottom-2.0*gap,depth],rotation:[0.0,yaw,0.0],normal:normal}
}
fn prepare_plan(doc) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:"/GriffinBus/TankSupportPlate"});
    if !q.prim.exists {throw("Open the canonical Griffin bus source");}
    let ops=[surface::add("/GriffinBus/TankSupportPlate","ExteriorBlankets","Xform")];
    ops.push(surface::attr(root(),"documentation","string","\"Hardware-photo-informed silver exterior blankets. Source frame defines bay dimensions. Seam/tape layout is an unqualified visual study. No collision, mass, thermal or pressure authority.\""));
    // Reuse the existing foil network; do not add lighting or shader source.
    let shader="/GriffinBus/Looks/ExteriorPanels/Surface";
    for op in wrapping::foil_ops(shader,wrapping::settings()) {ops.push(op);}
    #{doc_id:doc,generation:q.generation,ops:ops}
}
fn drape(doc,index,parameters) {
    let b=bay(doc,index);
    let frame=query("QueryUsdPrim",#{doc_id:doc,path:"/GriffinBus/PerimeterFrame",attrs:["points"]});
    let bottom=1.0e20;
    let top=-1.0e20;
    for point in frame.attrs.points {
        bottom=min(bottom,point[1]);
        top=max(top,point[1]);
    }
    bottom-=parameters.BusLowerOverhangM;
    b.position[1]=0.0;
    let outset=parameters.BusOutsetM+study::datum("BlanketThicknessM");
    b.position[0]+=b.normal[0]*outset;
    b.position[2]+=b.normal[2]*outset;
    let phase=index.to_float()*1.618;
    let mesh=wrapping::bus_surface(b.scale[0],bottom,top,phase,parameters);
    // Keep the top rail and side seams seated. Draw the lower foil into a
    // sloping pleat between the restraint points on the three aft bays.
    if index>=3 && index<=5 {
        let columns=parameters.BusColumns.to_int();
        let rows=parameters.BusRows.to_int();
        let skin=(columns+1)*(rows+1);
        for i in 0..skin {
            let u=(i%(columns+1)).to_float()/columns;
            let v=(i/(columns+1)).to_float()/rows;
            let hem=sin(acos(-1.0)*u)*(1.0-v);
            let crest=1.0-min(1.0,abs(u-(0.29+0.37*v+0.07*(index-4)))*3.4);
            let lift=parameters.AftPleatDepthM*hem*crest;
            let drop=parameters.AftHemDropM*hem*(0.30+0.70*crest);
            for vertex in [i,i+skin] {
                mesh.points[vertex][1]-=drop;
                mesh.points[vertex][2]+=lift;
            }
        }
    }
    #{bay:b,bottom:bottom,top:top,phase:phase,mesh:mesh}
}
fn patch_specs(d,index,parameters) {
    let b=d.bay;
    let result=[];
    let radians=b.rotation[1]*acos(-1.0)/180.0;
    let tangent=[cos(radians),0.0,-sin(radians)];
    for i in 0..parameters.TapeStations.len() {
        let station=parameters.TapeStations[i];
        let row=parameters.TapeRows[i];
        let columns=parameters.BusColumns.to_int();
        let grid_x=(station+0.5)*columns.to_float();
        let grid_y=row*parameters.BusRows.to_float();
        let column=floor(grid_x).to_int();
        let grid_row=floor(grid_y).to_int();
        let u=grid_x-column.to_float();
        let v=grid_y-grid_row.to_float();
        let a=grid_row*(columns+1)+column;
        let corners=if v<=u {[a,a+1,a+columns+2]} else {[a,a+columns+2,a+columns+1]};
        let weights=if v<=u {[1.0-u,u-v,v]} else {[1.0-v,u,v-u]};
        let local=[0.0,0.0,0.0];
        for vertex in 0..3 {for axis in 0..3 {
            local[axis]+=d.mesh.points[corners[vertex]][axis]*weights[vertex];
        }}
        let p0=d.mesh.points[corners[0]];
        let p1=d.mesh.points[corners[1]];
        let p2=d.mesh.points[corners[2]];
        let e=[p1[0]-p0[0],p1[1]-p0[1],p1[2]-p0[2]];
        let f=[p2[0]-p0[0],p2[1]-p0[1],p2[2]-p0[2]];
        let normal=[e[1]*f[2]-e[2]*f[1],e[2]*f[0]-e[0]*f[2],e[0]*f[1]-e[1]*f[0]];
        let length=sqrt(normal[0]*normal[0]+normal[1]*normal[1]+normal[2]*normal[2]);
        for axis in 0..3 {normal[axis]/=length;}
        let depth=study::datum("BlanketTapeDepthM");
        for axis in 0..3 {local[axis]+=normal[axis]*depth/2.0;}
        let p=[b.position[0]+tangent[0]*local[0]+b.normal[0]*local[2],local[1],
               b.position[2]+tangent[2]*local[0]+b.normal[2]*local[2]];
        let rotation=[-asin(normal[1])*180.0/acos(-1.0),
            b.rotation[1]+harness::angle(normal[0],normal[2])*180.0/acos(-1.0),0.0];
        result.push(geometry::shape("Tape"+index+"Patch"+i,p,
            [study::datum("BlanketTapeWidthM"),study::datum("BlanketTapeHeightM"),study::datum("BlanketTapeDepthM")],
            rotation,"/GriffinBus/Looks/ServiceConnectors"));
    }
    result
}
fn face_plan(doc,index) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:root()});
    if !q.prim.exists {throw("Prepare the exterior blanket collection first");}
    let parameters=wrapping::settings();
    let d=drape(doc,index,parameters);
    let name="Blanket"+index;
    let path=root()+"/"+name;
    let ops=[];
    let existing=query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:[]}).type_name;
    if existing!=() && existing!="Mesh" {
        ops.push(#{RemovePrim:#{edit_target:"@root@",path:path}});
    }
    for suffix in ["A","B"] {
        let old=root()+"/Tape"+index+suffix;
        if query("QueryUsdPrim",#{doc_id:doc,path:old,attrs:[]}).type_name!=() {
            ops.push(#{RemovePrim:#{edit_target:"@root@",path:old}});
        }
    }
    // Keep the existing mesh prim and its mounted fittings when refitting a bay.
    for op in wrapping::mesh_plan(root(),name,d.mesh.points,d.mesh.counts,d.mesh.indices,"/GriffinBus/Looks/ExteriorPanels") {
        if existing!="Mesh" || op.AddPrim==() {ops.push(op);}
    }
    ops=harness::append(ops,builder::place_plan("@root@",path,d.bay.position,d.bay.rotation,[1.0,1.0,1.0]));
    for spec in patch_specs(d,index,parameters) {
        let patch=root()+"/"+spec.name;
        if query("QueryUsdPrim",#{doc_id:doc,path:patch,attrs:[]}).type_name=="Cube" {
            ops=harness::append(ops,builder::place_plan("@root@",patch,spec.position,spec.rotation,spec.scale));
        } else {
            ops=geometry::cube(ops,root(),spec);
        }
    }
    for op in wrapping::foil_ops("/GriffinBus/Looks/ExteriorPanels/Surface",parameters) {ops.push(op);}
    #{doc_id:doc,generation:q.generation,ops:ops}
}
fn check_face(doc,index) {
    let parameters=wrapping::settings();
    let d=drape(doc,index,parameters);
    let q=query("QueryUsdPrim",#{doc_id:doc,path:root()+"/Blanket"+index,
        attrs:["points","faceVertexCounts","faceVertexIndices","purpose","physics:collisionEnabled"],relationships:true,schemas:true});
    if q.type_name!="Mesh" || q.attrs.purpose!="render" || q.attrs["physics:collisionEnabled"]!=false
        || q.api_schemas.contains("PhysicsCollisionAPI") || q.api_schemas.contains("PhysicsRigidBodyAPI") {
        throw("Blanket detail gained physical authority");
    }
    if q.attrs.points.len()!=d.mesh.points.len() || q.attrs.faceVertexIndices.len()!=d.mesh.indices.len() {
        throw("Folded blanket topology departed from its source plan");
    }
    if q.relationships["material:binding"]!=["/GriffinBus/Looks/ExteriorPanels"] {throw("Blanket lost its foil material");}
    for spec in patch_specs(d,index,parameters) {
        let patch=query("QueryUsdPrim",#{doc_id:doc,path:root()+"/"+spec.name,attrs:["purpose","physics:collisionEnabled"]});
        if patch.type_name!="Cube" || patch.attrs.purpose!="render" || patch.attrs["physics:collisionEnabled"]!=false {
            throw("Invalid localized tape patch");
        }
    }
    #{ok:true,bay:index,vertices:q.attrs.points.len(),triangles:q.attrs.faceVertexCounts.len(),patches:parameters.TapeStations.len()}
}

fn patch_plan(doc,index) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:root()});
    let parameters=wrapping::settings();
    let d=drape(doc,index,parameters);
    let ops=[];
    for spec in patch_specs(d,index,parameters) {
        ops=harness::append(ops,builder::place_plan("@root@",root()+"/"+spec.name,
            spec.position,spec.rotation,spec.scale));
    }
    #{doc_id:doc,generation:q.generation,ops:ops}
}
