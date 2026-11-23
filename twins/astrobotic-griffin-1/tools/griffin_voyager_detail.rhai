import "griffin_tank_finish" as finish;
import "griffin_insulation_detail" as insulation;
import "griffin_geometry" as geometry;
import "lunco://scripting/tools/assembly_builder" as builder;

fn setting(name) {
    let v=sysml_model("twin://astrobotic-griffin-1/requirements/griffin_voyager_revision.sysml")
        .value("GriffinVoyagerRevision::VisualStudy::"+name);
    if v==() {throw("Missing Voyager visual parameter "+name);} v
}
fn render(ops,path,material) {
    ops.push(finish::attr(path,"purpose","token","\"render\""));
    ops.push(finish::attr(path,"physics:collisionEnabled","bool","false"));
    ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:path,schemas:["MaterialBindingAPI"]}});
    ops.push(finish::binding(path,material));ops
}

fn skirt_root() { "/World/EngineSkirt" }

fn skirt_stock(doc) {
    let root = skirt_root();
    let q = query("InspectUsdDocument", #{doc_id:doc,path:root});
    if !q.prim.exists { throw("Open the engine skirt source"); }
    let shell = query("QueryUsdPrim", #{doc_id:doc,path:root+"/EngineSkirtShell",attrs:["points"]});
    let apron = query("QueryUsdPrim", #{doc_id:doc,path:root+"/ThermalApron",attrs:["points"]});
    let rail = query("QueryUsdPrim", #{doc_id:doc,path:root+"/PerimeterRail",attrs:["points"]});
    let corners = shell.attrs.points;
    let lip = apron.attrs.points;
    // Read the eight-vertex rings from the saved wall and apron. The wall
    // begins with upper and lower outer rings. The apron begins at its underside.
    if !array_is(corners) || !array_is(lip) || corners.len()!=32 || lip.len()!=32
        || corners[0][1]<=corners[8][1]
        || lip[16][1]<=lip[0][1] {
        throw("Expected the installed skirt wall and apron rings");
    }
    let rail_bottom = corners[0][1];
    for p in rail.attrs.points { rail_bottom=min(rail_bottom,p[1]); }
    if rail_bottom<=corners[8][1] { throw("Skirt rail seat lies below the lower lip"); }
    #{generation:q.generation,corners:corners,apron:lip,rail_bottom:rail_bottom}
}

fn interpolate(a,b,t) { a+(b-a)*t }

fn skirt_ring_edge(points, first, face, u) {
    let a = points[first+face];
    let b = points[first+(face+1)%8];
    [interpolate(a[0],b[0],u),interpolate(a[1],b[1],u),interpolate(a[2],b[2],u)]
}

fn skirt_reversed_indices(surface, reverse) {
    if !reverse { return surface.indices; }
    let indices = [];
    for i in 0..surface.counts.len() {
        indices.push(surface.indices[3*i]);
        indices.push(surface.indices[3*i+2]);
        indices.push(surface.indices[3*i+1]);
    }
    indices
}

fn skirt_style_plan(doc) {
    let root = skirt_root();
    let q = query("InspectUsdDocument", #{doc_id:doc,path:root});
    let ops = [];
    for style in [
        ["VoyagerOuterFoil","SkirtFoilColor","0.66","0.24"],
        ["VoyagerApronFoil","SkirtApronFoilColor","0.52","0.36"],
        ["VoyagerFoilTape","SkirtFoilTapeColor","0.42","0.35"]
    ] {
        let path = root+"/Looks/"+style[0];
        if query("QueryUsdPrim", #{doc_id:doc,path:path,attrs:[]}).type_name!=() {
            ops.push(#{RemovePrim:#{edit_target:"@root@",path:path}});
        }
        ops = finish::material(ops,root+"/Looks",style[0],finish::color_text(setting(style[1])),style[2],style[3]);
    }
    // The earlier straight ribbons pierce the folds. Their visibility opinion
    // also covers the smaller bands nested under their common parent.
    let seams = root+"/EngineSkirtShell/BlanketSeams";
    if query("QueryUsdPrim", #{doc_id:doc,path:seams,attrs:[]}).type_name!=() {
        ops.push(finish::attr(seams,"visibility","token","\"invisible\""));
    }
    for i in 0..8 {
        let seam = root+"/ThermalFinishDetail/ApronSeam"+i;
        if query("QueryUsdPrim", #{doc_id:doc,path:seam,attrs:[]}).type_name!=() {
            ops.push(finish::attr(seam,"visibility","token","\"invisible\""));
        }
    }
    #{ok:true,generation:q.generation,ops:ops}
}

fn skirt_plan(doc,index) { skirt_panel_plan(doc,index,false) }
fn skirt_apron_plan(doc,index) { skirt_panel_plan(doc,index,true) }

fn skirt_mesh_ops(doc, root, name, points, counts, indices, color, material) {
    let path = root+"/"+name;
    let existing = query("QueryUsdPrim", #{doc_id:doc,path:path,attrs:["faceVertexCounts","faceVertexIndices"]});
    if existing.type_name=="Mesh" {
        let plan = if existing.attrs.faceVertexCounts==counts && existing.attrs.faceVertexIndices==indices {
            builder::mesh_points_update_plan("@root@",path,points)
        } else {
            builder::mesh_shape_update_plan("@root@",path,points,counts,indices,color,false,())
        };
        if !plan.ok { throw(plan.error); }
        return plan.ops;
    }
    let plan = builder::mesh_shape_plan("@root@",root,name,points,counts,indices,color,false);
    if !plan.ok { throw(plan.error); }
    render(plan.ops,path,material)
}

fn skirt_tape_plan(doc, root, name, points, winding, triangle) {
    let a = vec3_from(points[winding[3*triangle]]);
    let b = vec3_from(points[winding[3*triangle+1]]);
    let c = vec3_from(points[winding[3*triangle+2]]);
    let u = b-a; let v = c-a;
    let normal = vec3(u.y*v.z-u.z*v.y,u.z*v.x-u.x*v.z,u.x*v.y-u.y*v.x);
    let length = sqrt(normal.x*normal.x+normal.y*normal.y+normal.z*normal.z);
    // The tape lies within one foil facet. The submillimetre separation keeps
    // the display layers from competing at the same depth.
    let corners = [];
    for uv in [[0.25,0.27],[0.49,0.27],[0.49,0.37],[0.25,0.37]] {
        let p = a+u*uv[0]+v*uv[1]+normal*(0.0005/length);
        corners.push([p.x,p.y,p.z]);
    }
    skirt_mesh_ops(doc,root,name,corners,[4],[0,1,2,3],
        setting("SkirtFoilTapeColor"),root+"/Looks/VoyagerFoilTape")
}

fn skirt_panel_plan(doc,index,underneath) {
    if index<0 || index>=8 { throw("Invalid skirt face"); }
    let stock = skirt_stock(doc);
    let root = skirt_root();
    let a = stock.corners[index];
    let b = stock.corners[(index+1)%8];
    let dx = b[0]-a[0]; let dz = b[2]-a[2];
    let span = sqrt(dx*dx+dz*dz);
    let nx = dz/span; let nz = -dx/span;
    if nx*(a[0]+b[0])+nz*(a[2]+b[2])<0.0 { nx=-nx; nz=-nz; }
    let flip = dx*nz-dz*nx<0.0;
    let columns = setting("SkirtColumns").to_int();
    let rows = if underneath {2} else {setting("SkirtRows").to_int()};
    let thickness = setting("SkirtCoverThicknessM");
    let depth = if underneath {setting("SkirtApronFoldDepthM")} else {setting("SkirtFoldDepthM")};
    let lip_margin = setting("SkirtLipMarginM");
    let trim = setting("SkirtApronTrimFraction");
    let finish_color = if underneath {"SkirtApronFoilColor"} else {"SkirtFoilColor"};
    let surface = insulation::bus_surface(1.0,0.0,1.0,0.0,
        #{BusColumns:columns,BusRows:rows,BusEdgeGatherM:0.0,BusFoldDepthM:0.0,ShellThicknessM:thickness});

    // The blanket spans touch the mitered corners. The interior nodes shift
    // sideways and form diagonal peaks with unequal spacing and height.
    let pi = acos(-1.0);
    let phase = [0.6,2.0,3.3,1.4,4.8,0.1,2.7,5.3][index];
    let points = [];
    for point in surface.points {
        let u = point[0]+0.5; let v = point[1];
        let edge = sin(pi*u);
        let hold = edge*sin(pi*v);
        let column = (u*columns).round().to_int();
        let paired = if column==0 || column==columns {0.0}
            else if column%2==0 {-0.29} else {0.29};
        let across = u+(paired+hold*0.17*sin(8.0*u+5.0*v+phase))/columns;
        let ridge = abs(sin(11.0*u-3.5*v+phase));
        let channel = abs(sin(5.5*u+7.0*v-phase));
        let peak = if column%2==0 {ridge*ridge} else {0.12+0.25*channel};
        let fold = depth*max(0.0,hold)*(0.13+0.73*peak+0.14*channel);
        let gauge = thickness+point[2];
        if underneath {
            let outer = skirt_ring_edge(stock.corners,8,index,across);
            let inner = skirt_ring_edge(stock.apron,8,index,across);
            let t = v*(1.0-trim);
            points.push([interpolate(outer[0],inner[0],t),outer[1]-gauge-fold,
                interpolate(outer[2],inner[2],t)]);
        } else {
            let lower = skirt_ring_edge(stock.corners,8,index,across);
            let upper = skirt_ring_edge(stock.corners,0,index,across);
            let top = stock.rail_bottom-lip_margin;
            let t = (v*(top-lower[1])+0.022*hold*sin(7.0*u+phase))/(upper[1]-lower[1]);
            // Both skins use the same taper and gathers. The lower edge
            // seats against the underside return at the shell lip.
            let relief = gauge+fold;
            points.push([interpolate(lower[0],upper[0],t)+nx*relief,
                interpolate(lower[1],upper[1],t),interpolate(lower[2],upper[2],t)+nz*relief]);
        }
    }
    let name = if underneath {"VoyagerApronCover"+index} else {"VoyagerFoldedCover"+index};
    let finish = if underneath {"VoyagerApronFoil"} else {"VoyagerOuterFoil"};
    let material = root+"/Looks/"+finish;
    let winding = skirt_reversed_indices(surface,if underneath {!flip} else {flip});
    let ops = skirt_mesh_ops(doc,root,name,points,surface.counts,winding,setting(finish_color),material);
    if !underneath {
        // Sparse, small seal patches like those visible along the lower
        // blankets in the JPL acoustic-test view.
        if index!=2 && index!=5 {
            let column = 1+index%max(1,columns-2);
            let row = index%(rows-1);
            let tape = skirt_tape_plan(doc,root,"VoyagerFoilTape"+index,points,winding,4*(row*columns+column));
            for op in tape { ops.push(op); }
        }
    }
    #{ok:true,generation:stock.generation,ops:ops}
}

fn skirt_cover_clears_aperture(doc,path,points) {
    let index=path[path.len()-1].to_string().parse_int();
    if index==() || index<0 || index>=8 { return false; }
    let stock=skirt_stock(doc);
    let a=stock.apron[8+index]; let b=stock.apron[8+(index+1)%8];
    let nx=b[2]-a[2]; let nz=a[0]-b[0];
    if nx*a[0]+nz*a[2]<0.0 { nx=-nx; nz=-nz; }
    // A cover lies beyond one edge plane of the convex opening. Requiring
    // that half-space for every vertex also keeps the full triangles clear.
    for p in points {
        if (p[0]-a[0])*nx+(p[2]-a[2])*nz<=0.0 { return false; }
    }
    true
}

fn check(doc,root,group) {
    let q=query("QueryUsdPrim",#{doc_id:doc,path:root,children:true,attrs:[]});
    let count=0;let pending=[];
    for path in q.children {
        if path.contains(group) {pending.push(path);}
    }
    while pending.len()>0 {
            let path=pending.pop();
            let r=query("QueryUsdPrim",#{doc_id:doc,path:path,children:true,attrs:["purpose","physics:collisionEnabled","points","faceVertexCounts","faceVertexIndices"],schemas:true});
            if r.type_name=="Material" {continue;}
            if r.type_name=="Xform" {
                for child in r.children {pending.push(child);} continue;
            }
            if r.document_generation!=q.document_generation || r.stage_generation!=q.stage_generation
                || r.attrs.purpose!="render" || r.attrs["physics:collisionEnabled"]!=false
                || r.api_schemas.contains("PhysicsRigidBodyAPI") || r.api_schemas.contains("PhysicsMassAPI") {
                throw("Visual hardware acquired physical ownership: "+path);
            }
            if r.type_name=="Mesh" && (path.contains("FoldedCover") || path.contains("ApronCover")) {
                let m=geometry::closed_mesh_metrics(r.attrs.points,r.attrs.faceVertexCounts,r.attrs.faceVertexIndices);
                if !m.available || m.boundary!=0 || m.nonmanifold!=0 || m.winding!=0 || m.volume<=0.0 {
                    throw("Invalid closed skirt cover: "+path);
                }
                if !skirt_cover_clears_aperture(doc,path,r.attrs.points) {
                    throw("Folded cover entered the engine aperture: "+path);
                }
            }
            count+=1;
    }
    if count==0 {throw("No Voyager visual details found");} #{ok:true,checked:count}
}
