import "lunco://scripting/tools/assembly_builder" as assembly_builder;

// Shared composed-document reads and typed authoring-plan diagnostics.
// Domain builders own their engineering decisions and operation plans.

fn query_ok(record) {
    record != () && record.ok != false
}

fn component_query(doc, path) {
    let record = assembly_builder::composed_query(doc, #{path: path, children: false});
    if !query_ok(record) {
        return #{ok: false, error: path + ": component prim is missing"};
    }
    #{ok: true, type_name: record.type_name, path: path}
}

fn plan_error(kind, message) {
    #{ ok: false, kind: kind, error: message, ops: [] }
}

fn absolute_root(root) {
    root != () && string_is(root) && root != ""
        && root.starts_with("/") && !(root.ends_with("/") && root != "/")
}

fn component_asset(relative) {
    "twin://" + twin_source_identity() + "/components/" + relative
}

fn color3_literal(color) {
    "("+color[0].to_string()+", "+color[1].to_string()+", "+color[2].to_string()+")"
}

fn source_number(model, name) { f64_from(model.value(name)) }

fn exists(doc, path) { query_ok(assembly_builder::composed_query(doc, #{path:path, children:false})) }

// Typed document operations shared by the domain plans.
fn add(edit, parent, name, kind) {
    #{AddPrim:#{edit_target:edit,parent_path:parent,name:name,type_name:kind,reference:(),reference_prim_path:()}}
}
fn attribute(edit, path, name, kind, value) {
    #{SetAttribute:#{edit_target:edit,path:path,name:name,type_name:kind,value:value}}
}
fn scalar(edit, path, name, value) {attribute(edit,path,name,"double",value.to_string())}
fn connection(edit, path, name, kind, sources) {
    #{SetConnection:#{edit_target:edit,path:path,name:name,type_name:kind,sources:sources}}
}
fn outputs(edit, path, names) {
    let ops=[];for name in names {ops.push(scalar(edit,path,"outputs:"+name,0.0));}ops
}
