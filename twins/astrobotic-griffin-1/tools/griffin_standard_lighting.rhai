// Remove the rejected presentation-lighting experiment through native USD ops.
// Reuse existing component materials; no shader coefficients or physics edits.
fn remove_fill_plan(doc,root) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:root});
    if !q.prim.exists {throw("Missing lighting owner");}
    let path=root+"/PresentationGroundBounce";
    if query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:[]}).type_name!="DomeLight" {throw("Missing experimental fill");}
    #{doc_id:doc,generation:q.generation,ops:[#{RemovePrim:#{edit_target:"@root@",path:path}}]}
}
fn hardware_plan(doc,root) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:root});
    if !q.prim.exists {throw("Missing component");}
    let original=if root=="/RootBearing" {"Structure"} else if root=="/SolarPanel" {"PanelFrame"} else {"RampStructure"};
    let material=root+"/Looks/"+original;
    if query("QueryUsdPrim",#{doc_id:doc,path:material,attrs:[]}).type_name!="Material" {throw("Missing existing material");}
    let ops=[];let surfaces=[];
    for path in q.prim.children {
        let p=query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:[],relationships:true});
        let binding=p.relationships["material:binding"];
        if binding==[root+"/Looks/PinMetal"] || binding==[root+"/Looks/BearingHousing"] {
            ops.push(#{SetRelationship:#{edit_target:"@root@",path:path,name:"material:binding",targets:[material]}});
            surfaces.push(path);
        }
    }
    if surfaces.len()==0 {throw("No experimental finishes to replace");}
    for role in ["PinMetal","BearingHousing"] {
        let path=root+"/Looks/"+role;
        if query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:[]}).type_name=="Material" {ops.push(#{RemovePrim:#{edit_target:"@root@",path:path}});}
    }
    #{doc_id:doc,generation:q.generation,ops:ops,surfaces:surfaces,material:material}
}
