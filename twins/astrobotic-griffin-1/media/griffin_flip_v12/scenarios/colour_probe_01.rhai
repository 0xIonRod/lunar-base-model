// @timing presentation
import "lunco://scripting/tools/waypoint_editor" as waypoint_editor;
fn on_start(me, ctx) {
    for r in ["FlipRoute", "AmberRoute"] {
        let path = "/Griffin1SurfaceOps/" + r;
        let owner = query("QueryUsdPrim", #{path:path});
        if owner == () || owner.doc_id == () { throw "Route owner is unavailable: " + path; }
        let e = waypoint_editor::ribbon_entity(owner.doc_id, path);
        if e < 0 { throw "Route ribbon has no live presentation: " + path; }
        let l = get(e, "PbrLook");
        print("CURVE_LOOK|" + r + "|" + e + "|" + l.base_color.red + "|" + l.base_color.green
            + "|" + l.base_color.blue + "|" + l.emissive.red + "|" + l.emissive.green + "|" + l.emissive.blue);
    }
}
