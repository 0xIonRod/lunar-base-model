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
    // Use the same folded-silver shader as the bus, including its shade and
    // crinkle inputs. Each skirt finish retains its own foil base colour.
    for style in [["VoyagerOuterFoil","SkirtFoilColor"],["VoyagerApronFoil","SkirtApronFoilColor"]] {
        let shader = root+"/Looks/"+style[0]+"/Surface";
        ops.push(finish::attr(shader,"info:implementationSource","token","\"sourceAsset\""));
        ops.push(finish::attr(shader,"info:wesl:sourceAsset","asset","@twin://astrobotic-griffin-1/shaders/thermal_blanket.wesl@"));
        ops += finish::insulation_ops(shader);
        ops.push(finish::attr(shader,"inputs:foil_color","color3f",finish::color_text(setting(style[1]))));
    }
    let plate = root+"/EngineAdapterPlate";
    ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:plate,schemas:["PhysicsCollisionAPI","MaterialBindingAPI"]}});
    ops.push(finish::binding(plate,root+"/Looks/BayApronSatin"));
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

fn visual_mesh_ops(doc, root, name, points, counts, indices, color, material) {
    let path = root+"/"+name;
    let existing = query("QueryUsdPrim", #{doc_id:doc,path:path,attrs:["faceVertexCounts","faceVertexIndices"]});
    if existing.type_name=="Mesh" {
        let plan = if existing.attrs.faceVertexCounts==counts && existing.attrs.faceVertexIndices==indices {
            builder::mesh_points_update_plan("@root@",path,points)
        } else {
            builder::mesh_shape_update_plan("@root@",path,points,counts,indices,color,false,())
        };
        if !plan.ok { throw(plan.error); }
        return render(plan.ops,path,material);
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
    visual_mesh_ops(doc,root,name,corners,[4],[0,1,2,3],
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
    let hem_depth = setting("SkirtFoldDepthM");
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
        // The lip hangs between corner seams. Use the same edge displacement
        // on the return so the two panels meet along the entire hem.
        let hem = hem_depth * edge * (0.35+0.65*abs(sin(4.0*across+phase)));

        if underneath {
            let outer = skirt_ring_edge(stock.corners,8,index,across);
            let inner = skirt_ring_edge(stock.apron,8,index,across);
            let t = v*(1.0-trim);
            let miter=gauge*(1.0-v);
            points.push([interpolate(outer[0],inner[0],t)+nx*miter,outer[1]-gauge-fold-hem*(1.0-v),
                interpolate(outer[2],inner[2],t)+nz*miter]);
        } else {
            let lower = skirt_ring_edge(stock.corners,8,index,across);
            let upper = skirt_ring_edge(stock.corners,0,index,across);
            let top = stock.rail_bottom-lip_margin;
            let t = (v*(top-lower[1])+0.022*hold*sin(7.0*u+phase))/(upper[1]-lower[1]);
            // Both skins use the same taper and gathers. The lower edge
            // seats against the underside return at the shell lip.
            let relief = gauge+fold;
            points.push([interpolate(lower[0],upper[0],t)+nx*relief,
                interpolate(lower[1],upper[1],t)-(gauge+hem)*(1.0-v),interpolate(lower[2],upper[2],t)+nz*relief]);
        }
    }
    let name = if underneath {"VoyagerApronCover"+index} else {"VoyagerFoldedCover"+index};
    let finish = if underneath {"VoyagerApronFoil"} else {"VoyagerOuterFoil"};
    let material = root+"/Looks/"+finish;
    let winding = skirt_reversed_indices(surface,if underneath {!flip} else {flip});
    let ops = visual_mesh_ops(doc,root,name,points,surface.counts,winding,setting(finish_color),material);
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

// Eight embossed sectors sit against the underside of the existing adapter.
// The inner edge stays outside the complete seven-bell cluster.
fn adapter_panel_plan(doc,index) {
    if index<0 || index>=8 {throw("Invalid adapter sector");}
    let root=skirt_root();
    let plate=query("QueryUsdPrim",#{doc_id:doc,path:root+"/EngineAdapterPlate",attrs:["points","xformOp:translate"]});
    let ring=plate.attrs.points;
    if ring.len()!=16 {throw("Expected two octagonal adapter rings");}
    let y=ring[0][1]+plate.attrs["xformOp:translate"][1];
    let inset=setting("SkirtAdapterInsetFraction");
    let relief=setting("SkirtApronFoldDepthM");
    let points=[]; let counts=[]; let indices=[];
    // The narrow edge setback exposes the adapter as a seam between sectors.
    for v in [0.0,0.15,0.55,0.87,1.0] {
        for u in [0.008,0.10,0.47,0.90,0.992] {
            let a=skirt_ring_edge(ring,0,index,u);
            let radius=interpolate(inset,0.996,v);
            let rib=sin(acos(-1.0)*v)*sin(acos(-1.0)*u);
            let offset=relief*(0.08+rib*(0.35+0.65*abs(sin(5.0*u-3.0*v+index))));
            points.push([a[0]*radius,y-offset,a[2]*radius]);
        }
    }
    for j in 0..4 {
        for k in 0..4 {
            let a=j*5+k;
            indices+=[a,a+1,a+6,a,a+6,a+5]; counts+=[3,3];
        }
    }
    let ops=visual_mesh_ops(doc,root,"AdapterFacing"+index,points,counts,indices,
        setting("SkirtAdapterColor"),root+"/Looks/BayEdgeMetal");
    #{ok:true,ops:ops}
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

// The blanket carries the mount transform. Its folded outer surface lies
// above local Z=0. Seat the ferrules through it and recess the dark inserts.
fn aft_openings_plan(doc) {
    let root = "/GriffinBus/TankSupportPlate/ExteriorBlankets/Blanket4";
    let owner = query("InspectUsdDocument", #{doc_id:doc,path:root});
    if !owner.prim.exists { throw("Expected the aft bus blanket"); }
    let centers = setting("AftOpeningCentersM");
    let radii = setting("AftOpeningRadiiM");
    let height = setting("AftOpeningHeightM");
    let ops = [];
    for i in 0..centers.len() {
        let r = radii[i];
        let name = "Opening"+i;
        let points = []; let winding = []; let counts = [];
        // Counterclockwise rings from the buried outer seat to the recessed bore.
        for ring in [[0.90,0.0],[1.0,0.83],[0.92,1.05],[0.75,1.05],[0.72,0.79]] {
            for j in 0..24 {
                let phi = 2.0*acos(-1.0)*j/24.0;
                points.push([centers[i]+r*ring[0]*cos(phi),height+r*ring[0]*sin(phi),r*ring[1]]);
            }
        }
        for k in 0..4 { for j in 0..24 {
            let a = k*24+j; let b = k*24+(j+1)%24;
            winding += [a,b,b+24,a+24]; counts.push(4);
        }}
        ops += visual_mesh_ops(doc,root,name+"Rim",points,counts,winding,[0.63,0.67,0.72],"/GriffinBus/Looks/FrameMetal");
        let disk = []; let face = [];
        for j in 0..24 {
            disk.push(points[4*24+j]);
            face.push(j);
        }
        ops += visual_mesh_ops(doc,root,name+"Insert",disk,[24],face,[0.075,0.085,0.10],"/GriffinBus/Looks/HarnessJacket");
    }
    #{ok:true,generation:owner.generation,ops:ops}
}

// Form the clipped plate on the adjacent chamfer with the raised strip and
// two small contrasting identification pads visible in the Voyager side view.
fn aft_plate_plan(doc) {
    let root = "/GriffinBus/TankSupportPlate/ExteriorBlankets/Blanket3";
    let owner = query("InspectUsdDocument", #{doc_id:doc,path:root});
    if !owner.prim.exists { throw("Expected the aft quarter blanket"); }
    let size = setting("AftPlateSizeM");
    let w=size[0]; let h=size[1]; let z=size[2];
    let profile = [[-0.50,-0.20],[-0.23,-0.50],[0.5,-0.50],[0.5,0.44],[0.44,0.50],[-0.5,0.50]];
    let points=[]; let counts=[6,6]; let indices=[5,4,3,2,1,0,6,7,8,9,10,11];
    for depth in [0.0,z] { for uv in profile {points.push([w*uv[0],h*uv[1],depth]);} }
    for j in 0..6 { let n=(j+1)%6; counts.push(4); indices += [j,n,n+6,j+6]; }
    let ops=visual_mesh_ops(doc,root,"EquipmentPlate",points,counts,indices,[0.20,0.24,0.29],"/GriffinBus/Looks/TankFrame");
    for detail in [["Spine",0.04,0.0,0.065,0.94],["UpperPad",0.27,0.25,0.18,0.08],
                   ["LowerPad",-0.26,-0.02,0.12,0.06]] {
        let x=w*detail[1]; let y=h*detail[2]; let dx=w*detail[3]/2.0; let dy=h*detail[4]/2.0;
        let part=geometry::rectangular_prism_geometry(vec3(x,y,z+0.001),vec3(2.0*dx,2.0*dy,0.002));
        ops += visual_mesh_ops(doc,root,"EquipmentPlate"+detail[0],part.points,part.face_counts,part.face_indices,[0.63,0.67,0.72],
            "/GriffinBus/Looks/FrameMetal");
    }
    #{ok:true,generation:owner.generation,ops:ops}
}

// Batch a few rows per mesh to stay within the native authoring plan budget. Take each station from its real
// cell row so the recesses remain empty. Local +Y is the collecting face.
fn solar_contacts_plan(doc,first_row,end_row) {
    let root="/SolarPanel";
    let owner=query("InspectUsdDocument",#{doc_id:doc,path:root});
    if !owner.prim.exists { throw("Expected a solar panel source"); }
    let points=[]; let indices=[]; let counts=[];
    let width=setting("SolarContactWidthM");
    let length=setting("SolarContactLengthM");
    for i in first_row..end_row {
        let row=query("QueryUsdPrim",#{doc_id:doc,path:root+"/CellRow"+i,attrs:["points"]});
        let cells=row.attrs.points;
        if !array_is(cells) || cells.is_empty() || cells.len()%16!=0 { throw("Missing installed cell row "+i); }
        for j in 0..cells.len()/16 {
            let a=cells[j*16+8];
            let x=(cells[j*16+10][0]+cells[j*16+14][0])/2.0;
            let y=a[1]+0.0002; let z=a[2];
            let n=points.len();
            points += [[x-width/2.0,y,z-length/2.0],[x-width/2.0,y,z+length/2.0],
                       [x+width/2.0,y,z+length/2.0],[x+width/2.0,y,z-length/2.0]];
            indices += [n,n+1,n+2,n+3]; counts.push(4);
        }
    }
    let ops=visual_mesh_ops(doc,root,"CellEdgeContacts"+first_row,points,counts,indices,[0.62,0.66,0.71],"/SolarPanel/Looks/PanelFrame");
    #{ok:true,generation:owner.generation,ops:ops}
}

// In Astrobotic photo 1348 the forward leg cutout has silver tapered cheeks.
// The notch rails supply their attachment stations and minimum open throat.
fn forward_notch_plan(doc) {
    let root="/SolarPanel/Frame/EdgeCaps";
    let owner=query("InspectUsdDocument",#{doc_id:doc,path:root});
    if !owner.prim.exists {throw("Expected the fitted forward panel frame");}
    let ops=[];
    let seat="/SolarPanel/Looks/FastenerSeat";
    if query("QueryUsdPrim",#{doc_id:doc,path:seat,attrs:[]}).type_name==() {
        ops=finish::material(ops,"/SolarPanel/Looks","FastenerSeat","(0.09, 0.10, 0.12)","0.55","0.38");
    }
    for side in [["Right",7,8],["Left",13,12]] {
        let lower=query("QueryUsdPrim",#{doc_id:doc,path:root+"/Lip"+side[1],attrs:["xformOp:translate","xformOp:scale"]}).attrs;
        let shoulder=query("QueryUsdPrim",#{doc_id:doc,path:root+"/Lip"+side[2],attrs:["xformOp:translate","xformOp:scale"]}).attrs;
        if lower==() || shoulder==() {throw("Missing forward notch edging");}
        let a=lower["xformOp:translate"]; let b=shoulder["xformOp:translate"];
        let leg=lower["xformOp:scale"]; let ledge=shoulder["xformOp:scale"];
        let sign=if side[0]=="Right" {1.0} else {-1.0};
        if sign*a[0]<=sign*b[0] || ledge[0]<=ledge[2] || leg[2]<=leg[0] {
            throw("Unexpected forward leg opening");
        }
        let inner=b[0]-sign*ledge[0]/2.0+sign*leg[0]/2.0;
        let out=a[0]; let bottom=a[2]+leg[2]/2.0;
        // The native XZ plane maps its second profile axis to local -Z.
        let profile=[vec2(inner,-b[2]),vec2(out,-b[2]),vec2(out,-bottom)];
        if sign>0.0 {profile.reverse();}
        let blank=extrude_profile(profile,leg[1],profile_plane_xz());
        let points=[];
        for v in blank.points {points.push([v.x,v.y+a[1]-leg[1]/3.0,v.z]);}
        let name="LegCutout"+side[0];
        ops+=visual_mesh_ops(doc,root,name,points,blank.face_vertex_counts,blank.face_vertex_indices,
            [0.62,0.66,0.71],"/SolarPanel/Looks/PanelFrame");

        // A flush circular seat, picked out against the silver triangular sheet.
        let disk=[]; let face=[];
        let x=out+(inner-out)*0.34; let z=b[2]+(bottom-b[2])*0.22;
        for j in 0..16 {
            let phi=2.0*acos(-1.0)*j/16.0;
            disk.push([x+leg[0]*0.38*cos(phi),a[1]+leg[1]*0.24,z-leg[0]*0.38*sin(phi)]);
            face.push(j);
        }
        ops+=visual_mesh_ops(doc,root,name+"Seat",disk,[16],face,[0.09,0.10,0.12],seat);
    }
    #{ok:true,generation:owner.generation,ops:ops}
}

fn rcs_optics_ops(edit_target,nozzle) {
    let shader=nozzle+"/Exhaust/Looks/Flame_Mat/Surface";
    let ops=[];
    for pair in [["core_fraction","RcsCoreFraction"],["core_width","RcsCoreWidth"],["flicker","RcsFlicker"],
        ["inner_hot_color","RcsCoreTint"],["inner_edge_color","RcsEdgeTint"]] {
        let v=setting(pair[1]);
        let color=array_is(v);
        ops.push(#{SetAttribute:#{edit_target:edit_target,path:shader,name:"inputs:"+pair[0],
            type_name:if color {"color3f"} else {"float"},value:if color {finish::color_text(v)} else {v.to_string()}}});
    }
    ops
}

// The A110 product photos show a bright injector flange and two metal feed
// unions. Fit both to the existing valve bodies and keep their passages open.
fn rcs_head_plan(doc) {
    let root="/World";
    let neck=query("QueryUsdPrim",#{doc_id:doc,path:root+"/Throat",attrs:["points"]});
    if neck.type_name!="Mesh" {throw("Open the reusable RCS nozzle");}
    let radius=0.0; let head=-1.0;
    for p in neck.attrs.points {
        radius=max(radius,sqrt(p[0]*p[0]+p[2]*p[2])); head=max(head,p[1]);
    }
    let parts=[#{name:"InjectorFlange",r:radius,outer:radius*1.75,h:radius*0.52,
        center:[0.0,head,0.0],rot:[0.0,0.0,0.0],sides:32}];
    for name in ["Fuel","Oxidizer"] {
        let q=query("QueryUsdPrim",#{doc_id:doc,path:root+"/"+name+"Inlet",
            attrs:["height","radius","xformOp:translate","xformOp:rotateXYZ"]});
        let rot=vec3_from(q.attrs["xformOp:rotateXYZ"]);
        let axis=qrot(quat_from_euler_xyz_deg(rot),vec3(0.0,1.0,0.0));
        let c=vec3_from(q.attrs["xformOp:translate"])-axis*(q.attrs.height*0.32);
        parts.push(#{name:name+"Union",r:q.attrs.radius,outer:q.attrs.radius*2.4,h:q.attrs.radius*2.1,
            center:vec3_array(c),rot:vec3_array(rot),sides:8});
    }
    let ops=[]; let color=[0.65,0.69,0.72];
    for part in parts {
        let path=root+"/"+part.name;
        if query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:[]}).type_name==() {
            ops.push(finish::add(root,part.name,"Mesh"));
        }
        let a=part.r;let b=part.outer;let h=part.h;
        ops.push(#{RevolveProfileMesh:#{edit_target:"@root@",path:path,axis:[0.0,1.0,0.0],
            angular_segments:part.sides,normal_crease_angle_deg:25.0,display_color:color,collision_enabled:false,
            profile:[[a,-h],[b*0.93,-h],[b,-h*0.6],[b,h*0.6],[b*0.93,h],[a,h]]}});
        let pose=builder::place_plan("@root@",path,part.center,part.rot,[1.0,1.0,1.0]);
        if !pose.ok {throw(pose.error);} ops+=pose.ops;
        ops.push(finish::attr(path,"purpose","token","\"render\""));
    }
    ops+=rcs_optics_ops("@root@",root);
    ops.push(finish::attr(root+"/Exhaust/Looks/Flame_Mat/Surface","inputs:core_color","color3f","(3.2, 3.0, 2.8)"));
    ops.push(finish::attr(root+"/Exhaust/Looks/Flame_Mat/Surface","inputs:edge_color","color3f","(1.5, 0.98, 0.87)"));
    // Base metal on the long chamber and bell remains thermally driven.
    let shader=root+"/Looks/Nozzle_Mat/Surface";
    for label in ["inputs:base_color","inputs:diffuseColor"] {
        ops.push(finish::attr(shader,label,"color3f","(0.18, 0.19, 0.21)"));
    }
    #{ok:true,ops:ops}
}
