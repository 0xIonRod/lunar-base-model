// Dry Editor plan. SysML owns the internal pack allocation; the shared battery
// retains electrical behavior, mass, and the visible/collision case identity.
fn plan(doc, edit, path) {
    let prefix = "FlipSensorPowerRequirements::FlipSensorPowerAssembly::";
    let names = ["batteryLengthM", "batteryHeightM", "batteryWidthM",
        "batteryCenterXM", "batteryCenterYM", "batteryCenterZM"];
    let source = sysml_requirements::model();
    let values = [];
    for name in names {
        let value = f64_from(source.value(prefix+name));
        if value == () || !value.is_finite() { throw("Battery packaging datum unavailable: "+name); }
        values.push(value);
    }
    for index in 0..3 { if values[index] <= 0.0 { throw("Battery dimensions must be positive"); } }
    let prim = query("QueryUsdPrim", #{doc_id:doc, path:path});
    if prim.type_name != "Xform" { throw("Select the battery assembly instance"); }
    #{source_revision:source.source_revision, doc_id:doc, generation:prim.generation, ops:[
        #{SetAttribute:#{edit_target:edit,path:path,name:"xformOp:scale",type_name:"double3",value:"("+values[0]+","+values[1]+","+values[2]+")"}},
        #{SetAttribute:#{edit_target:edit,path:path,name:"xformOp:translate",type_name:"double3",value:"("+values[3]+","+values[4]+","+values[5]+")"}},
        #{SetAttribute:#{edit_target:edit,path:path,name:"xformOpOrder",type_name:"token[]",value:"[\"xformOp:translate\",\"xformOp:scale\"]"}}
    ]}
}
