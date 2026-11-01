// @timing presentation
fn on_start(me,ctx) {for r in ["FlipRoute","AmberRoute"] {let e=find_path("/Griffin1SurfaceOps/"+r+"/RouteRibbon/Geometry");let l=get(e,"PbrLook");print("CURVE_LOOK|"+r+"|"+e+"|"+l.base_color.red+"|"+l.base_color.green+"|"+l.base_color.blue+"|"+l.emissive.red+"|"+l.emissive.green+"|"+l.emissive.blue);}}
