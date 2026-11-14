// Presentation of the reduced balanced bridle study. Modelica selects the
// active routing contact; these curves do not calculate forces or edit USD.
const ROOT="/Griffin1SurfaceOps";

fn setup() {
    // Discover the presentation adapter once. Offscreen renderers can have it;
    // physics-only hosts do not. Audience or Mesh3d existence is not that fact.
    let catalog=query("ScriptingCatalog",#{sections:["queries"]});
    if catalog.ok==false {throw("Cannot discover tether presentation: "+catalog.error);}
    let available=false;
    for entry in catalog.queries {if entry.name=="InspectUsdCurveView" {available=true;}}
    if !available {return [];}
    let rows=[];
    let index=0;
    for side in ["Left","Right"] {
        let path=ROOT+"/Lander/LiveTethers/"+side;
        let root=find_path(path);let span=find_path(path+"/Span");let wheel=find_path(ROOT+"/FLIP/Suspension_"+["RL","RR"][index]+"/Wheel_"+["RL","RR"][index]);
        if wheel<0 {throw("Missing native rear wheel for "+side+" tether view");}
        let bridle=find_path(usd_path(wheel)+"/CADVisuals/LiveBridle");
        if root<0 || span<0 || bridle<0 {throw("Missing authored "+side+" tether presentation");}
        let source=query("QueryUsdPrim",#{path:path+"/Span",attrs:["widths"]});
        let width=source.attrs.widths[0];
        if width==() || !width.is_finite() || width<=0.0 {throw("Tether visual width is invalid");}
        rows.push(#{root:root,span:span,bridle:bridle,wheel:wheel,doc:source.doc_id,width:width});index+=1;
    }
    rows
}

fn vector_value(geometry,prefix) {
    let v=[(),(),()];
    for row in geometry {for i in 0..3 {if row[0]==prefix+"_"+["x","y","z"][i] {v[i]=row[1];}}}
    for value in v {if value==() || !value.is_finite() {throw("Missing or invalid tether geometry: "+prefix);}}
    vec3_from(v)
}

fn submit(row,curve,points,normals) {
    cmd("UpdateUsdCurveView",#{doc_id:row.doc,root_entity_id:if curve==row.bridle {row.wheel}else{row.root},
        curve_entity_id:curve,points:points,normals:normals,width_m:row.width,projection:"Spatial"})
}

fn clear(rows) {
    if rows.len()!=2 || get(rows[0].span,"Mesh3d.0")==() {return;}
    for row in rows {for curve in [row.span,row.bridle] {submit(row,curve,[],[]);}}
}

fn ready(rows) {
    for row in rows {for curve in [row.span] {
        let status=query("InspectUsdCurveView",#{doc_id:row.doc,entity_id:curve});
        if status.state=="pending" {return false;}
        if status.error!="" {throw("Tether mesh preparation failed: "+status.error);}
    }}
    true
}

fn update(rows,geometry,state,lander) {
    if rows.len()!=2 {return #{ok:true,rendered:false};}
    // Headless hosts do not project render meshes and must not prepare them.
    if get(rows[0].span,"Mesh3d.0")==() {return #{ok:true,rendered:false};}
    let origin=world_pos3(lander);let inverse=quat_inverse(world_rotation_quat(lander));
    let index=0;
    for station in ["RL","RR"] {
        let row=rows[index];
        let wheel=find_path(ROOT+"/FLIP/Suspension_"+station+"/Wheel_"+station);
        let hub=world_pos3(wheel);
        let anchor=vector_value(geometry,"span"+index);
        let selected=vec3(state["routing"+index+"_x"],state["routing"+index+"_y"],state["routing"+index+"_z"]);
        let active=-1;let best=vlen(selected-anchor);
        let guides=[];
        for j in 0..7 {
            let guide=vector_value(geometry,"guide"+index+"_"+j);guides.push(guide);
            let distance=vlen(guide-selected);
            if distance<best {best=distance;active=j;}
        }
        let path=[qrot(inverse,hub+anchor-origin)];
        let inboard=vector_value(geometry,"inboard");
        for j in 0..7 {
            if j<=active && vdot(guides[j]-anchor,inboard)<=0.0 {
                path.push(qrot(inverse,hub+guides[j]-origin));
            }
        }
        path.push(qrot(inverse,hub-origin));
        let axis=qrot(inverse,vector_value(geometry,"axis"+index));
        let points=[];let normals=[];
        for j in 0..path.len() {
            let before=path[max(0,j-1)];let after=path[min(path.len()-1,j+1)];
            let n=vcross(after-before,axis);
            if vlen(n)<=0.000001 {return #{ok:false,error:"Tether ribbon has a degenerate orientation"};}
            points.push(vec3_array(path[j]));normals.push(vec3_array(n*(1.0/vlen(n))));
        }
        let span=submit(row,row.span,points,normals);
        if span==() || span.ok!=true {return #{ok:false,error:"Live tether curve update was rejected",command:span};}
        // The authored sling is wheel-local. Native wheel transforms move it
        // every frame without a delayed world-space pose snapshot.
        index+=1;
    }
    #{ok:true,rendered:true}
}
