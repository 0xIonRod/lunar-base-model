import "griffin_upper_visuals" as study;
import "griffin_tank_finish" as finish;
import "social_surface_finish" as surface;
import "social_geometry_detail" as geometry;
import "griffin_bus_detail" as harness;

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
    for row in [["crinkle","SkirtFoilCrinkle"],["facet_depth","SkirtFoilFacet"],["sheen","SkirtFoilSheen"],["v_scale","SkirtFoilAxialScale"]] {
        ops.push(surface::attr(shader,"inputs:"+row[0],"float",study::datum(row[1]).to_string()));
    }
    #{doc_id:doc,generation:q.generation,ops:ops}
}
fn specs(doc,index) {
    let b=bay(doc,index);let result=[geometry::shape("Blanket"+index,b.position,b.scale,b.rotation,"/GriffinBus/Looks/ExteriorPanels")];
    let radians=b.rotation[1]*acos(-1.0)/180.0;
    let tangent=[cos(radians),0.0,-sin(radians)];
    let patch_depth=study::datum("BlanketTapeDepthM");
    let lift=(b.scale[2]+patch_depth)/2.0;
    for side in [-1.0,1.0] {
        let offset=side*b.scale[0]*study::datum("BlanketTapeStationFraction");
        let p=[b.position[0]+tangent[0]*offset+b.normal[0]*lift,
          b.position[1]+b.scale[1]/2.0-study::datum("BlanketTapeTopInsetM"),
          b.position[2]+tangent[2]*offset+b.normal[2]*lift];
        result.push(geometry::shape("Tape"+index+if side<0.0 {"A"}else{"B"},p,
          [study::datum("BlanketTapeWidthM"),study::datum("BlanketTapeHeightM"),patch_depth],b.rotation,
          "/GriffinBus/Looks/ServiceConnectors"));
    }
    result
}
fn face_plan(doc,index) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:root()});
    if !q.prim.exists {throw("Prepare the exterior blanket collection first");}
    let ops=[];for s in specs(doc,index) {ops=geometry::cube(ops,root(),s);}
    #{doc_id:doc,generation:q.generation,ops:ops}
}
fn check_face(doc,index) {
    let observed=[];
    for s in specs(doc,index) {
        let q=query("QueryUsdPrim",#{doc_id:doc,path:root()+"/"+s.name,
          attrs:["xformOp:translate","xformOp:scale","xformOp:rotateXYZ","purpose","physics:collisionEnabled"],relationships:true,schemas:true});
        if q.type_name!="Cube" || q.attrs.purpose!="render" || q.attrs["physics:collisionEnabled"]!=false || q.api_schemas.contains("PhysicsCollisionAPI") || q.api_schemas.contains("PhysicsRigidBodyAPI") {throw("Blanket detail gained physical authority");}
        if q.relationships["material:binding"]!=[s.material] {throw("Blanket material does not match the existing network");}
        for a in 0..3 {
            if abs(q.attrs["xformOp:translate"][a]-s.position[a])>0.000001 || abs(q.attrs["xformOp:scale"][a]-s.scale[a])>0.000001 || abs(q.attrs["xformOp:rotateXYZ"][a]-s.rotation[a])>0.000001 {throw("Blanket detail departed from its source frame bay");}
        }
        observed.push(s.name);
    }
    #{ok:true,bay:index,parts:observed,scope:"Frame-fitted render blankets only; no tether, collider or thermal physics"}
}
