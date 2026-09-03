#!/usr/bin/env python3
"""Static authored-contract checks for the Griffin-1 Twin.

This is deliberately a small, dependency-free check. It does not replace the
headful Editor, composed-stage inspection, collision queries, or driving test;
it catches regressions in the authored source that should be impossible to
miss in review.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TWIN = ROOT / "twins" / "astrobotic-griffin-1"


def require(text: str, pattern: str, label: str, failures: list[str]) -> None:
    if not re.search(pattern, text, re.MULTILINE | re.DOTALL):
        failures.append(label)


def count(text: str, pattern: str) -> int:
    return len(re.findall(pattern, text, re.MULTILINE | re.DOTALL))


def main() -> int:
    wrapper_path = TWIN / "vehicles" / "griffin_1.usda"
    rover_path = TWIN / "vehicles" / "flip.usda"
    scene_path = TWIN / "scenes" / "griffin_1_surface_ops.usda"
    scenario_path = TWIN / "scenarios" / "griffin_1_surface_ops.rhai"
    behavior_path = TWIN / "behaviors" / "griffin_1_flip_patrol.btxml"
    controls_path = TWIN / "tools" / "griffin_controls.rhai"
    assets_path = TWIN / "Assets.toml"
    files = [
        wrapper_path,
        rover_path,
        scene_path,
        scenario_path,
        behavior_path,
        controls_path,
        assets_path,
    ]
    missing = [str(path.relative_to(ROOT)) for path in files if not path.is_file()]
    if missing:
        print("FAIL: missing authored inputs:")
        print("  " + "\n  ".join(missing))
        return 1

    wrapper = wrapper_path.read_text(encoding="utf-8")
    rover = rover_path.read_text(encoding="utf-8")
    scene = scene_path.read_text(encoding="utf-8")
    scenario = scenario_path.read_text(encoding="utf-8")
    behavior = behavior_path.read_text(encoding="utf-8")
    controls = controls_path.read_text(encoding="utf-8")
    assets = assets_path.read_text(encoding="utf-8")
    failures: list[str] = []

    # Reusable wrapper and public-fact/provenance markers.
    require(wrapper, r"prepend references\s*=\s*@lunco://vessels/landers/descent_lander\.usda@</DescentLander>", "Griffin wrapper keeps the reusable lander reference", failures)
    require(wrapper, r"lunco:configuration\s*=\s*\"[^\"]*four legs[^\"]*side-mounted solar arrays", "Griffin configuration records legs and polar arrays", failures)
    require(wrapper, r"lunco:payload_class_kg\s*=\s*625", "public payload class is recorded", failures)
    require(wrapper, r"HighGainDish[\s\S]{0,240}active\s*=\s*false", "lander high-gain antenna is disabled in Griffin wrapper", failures)
    require(wrapper, r'def "Nozzle"[\s\S]*?visibility\s*=\s*"invisible"', "lander propulsion nozzle is hidden from the clean Griffin top view", failures)
    require(wrapper, r'def Xform "GriffinPortRail"[\s\S]*?visibility\s*=\s*"invisible"', "superseded top-deck payload rail is hidden", failures)
    require(wrapper, r"lunco:collision:contract\s*=", "collision contract is authored", failures)
    require(
        wrapper,
        r'def Cube "BoxyAirframe"[\s\S]*?xformOp:scale\s*=\s*\(2\.7, 1\.6, 2\.7\)[\s\S]*?physics:collisionEnabled\s*=\s*true',
        "Griffin body is the authored 5.4 x 3.2 x 5.4 m solid airframe",
        failures,
    )

    # Visible solar/panel/ramp ownership and collision facts.
    for panel in ("SolarPanelPort", "SolarPanelStarboard"):
        require(wrapper, rf'def Xform "{panel}"', f"{panel} exists", failures)
        require(wrapper, rf'def Xform "{panel}"[\s\S]*?physics:collisionEnabled\s*=\s*true', f"{panel} has a solid authored panel", failures)
    for ramp in ("EgressRampPort", "EgressRampStarboard"):
        require(wrapper, rf'def Xform "{ramp}"', f"{ramp} exists", failures)
        section = re.search(rf'def Xform "{ramp}"[\s\S]*?(?=\n    def |\Z)', wrapper)
        ramp_text = section.group(0) if section else ""
        require(ramp_text, r'def Cube "Surface"', f"{ramp} has a surface", failures)
        require(ramp_text, r'def Cube "EdgeRail"', f"{ramp} has an outside rail", failures)
        require(ramp_text, r'def Cube "EdgeRailInner"', f"{ramp} has a second rail", failures)
        if count(ramp_text, r'physics:collisionEnabled\s*=\s*true') < 3:
            failures.append(f"{ramp} surface and both rails are colliders")
    require(
        wrapper,
        r'def Xform "EgressRampPort"[\s\S]*?xformOp:translate\s*=\s*\(2\.3, 1\.95, 0\.0\)[\s\S]*?xformOp:rotateXYZ\s*=\s*\(0\.0, 0\.0, -50\.0\)',
        "port ramp is seated on the positive-X deck datum and reaches the landing plane",
        failures,
    )
    require(
        wrapper,
        r'def Xform "EgressRampStarboard"[\s\S]*?xformOp:translate\s*=\s*\(-2\.3, 1\.95, 0\.0\)[\s\S]*?xformOp:rotateXYZ\s*=\s*\(0\.0, 0\.0, 50\.0\)',
        "starboard ramp is seated on the negative-X deck datum and reaches the landing plane",
        failures,
    )
    for hinge in ("RampHingePort", "RampHingeStarboard"):
        require(
            wrapper,
            rf'def Cube "{hinge}"[\s\S]*?PhysicsCollisionAPI[\s\S]*?physics:collisionEnabled\s*=\s*true',
            f"{hinge} provides a solid ramp-root support",
            failures,
        )
    for ramp in ("EgressRampPort", "EgressRampStarboard"):
        section = re.search(rf'def Xform "{ramp}"[\s\S]*?(?=\n    def |\Z)', wrapper)
        ramp_text = section.group(0) if section else ""
        if "PhysicsRigidBodyAPI" in ramp_text:
            failures.append(f"{ramp} stays integrated with the lander compound rather than becoming an independent rigid body")
    if re.search(r'def (?:PhysicsRevoluteJoint|Xform) "EgressRamp(?:Port|Starboard)Hinge"', wrapper):
        failures.append("accepted wrapper has no unstable loose ramp hinge prims")
    require(wrapper, r'custom string lunco:feature\s*=\s*"single-side payload containment rail', "one-side payload rail is explicit", failures)
    for leg in (
        "SolidLegFrontPort",
        "SolidLegRearPort",
        "SolidLegFrontStarboard",
        "SolidLegRearStarboard",
    ):
        require(
            wrapper,
            rf'def Cube "{leg}"[\s\S]*?PhysicsCollisionAPI[\s\S]*?physics:collisionEnabled\s*=\s*true',
            f"{leg} is a solid authored landing strut",
            failures,
        )
    for foot in (
        "SolidFootFrontPort",
        "SolidFootRearPort",
        "SolidFootFrontStarboard",
        "SolidFootRearStarboard",
    ):
        require(
            wrapper,
            rf'def Cylinder "{foot}"[\s\S]*?PhysicsCollisionAPI[\s\S]*?physics:collisionEnabled\s*=\s*true',
            f"{foot} is a solid authored landing pad",
            failures,
        )

    for leg in (
        "SolidLegFrontPort",
        "SolidLegRearPort",
        "SolidLegFrontStarboard",
        "SolidLegRearStarboard",
    ):
        require(wrapper, rf'def Cube "{leg}"[\s\S]*?xformOp:translate\s*=\s*\([^,]+, -3\.125, [^)]+\)[\s\S]*?xformOp:rotateXYZ\s*=\s*\([^,]+, 0\.0, [^)]+\)[\s\S]*?xformOp:scale\s*=\s*\(0\.18, 1\.725, 0\.18\)', f"{leg} strut is radially raked and seated between body and pad", failures)
    for foot in (
        "SolidFootFrontPort",
        "SolidFootRearPort",
        "SolidFootFrontStarboard",
        "SolidFootRearStarboard",
    ):
        require(wrapper, rf'def Cylinder "{foot}"[\s\S]*?xformOp:translate\s*=\s*\([^,]+, -4\.85, [^)]+\)', f"{foot} meets the lower strut tip", failures)

    # FLIP physical driving contract.
    require(rover, r'lunco:configuration\s*=\s*"four-wheel all-wheel-steer study proxy"', "FLIP records the four-wheel steering boundary", failures)
    require(rover, r'PhysxVehicleAckermannSteeringAPI', "FLIP exposes typed steering", failures)
    require(rover, r'lunco:steering:status\s*=', "FLIP steering status is authored", failures)
    require(rover, r'lunco:wheel:geometry\s*=\s*"four solid', "FLIP solid wheel geometry is authored", failures)
    require(rover, r'variants\s*=\s*\{\s*string "drivetrain"\s*=\s*"raycast"\s*\}', "FLIP selects the stable raycast drivetrain realization", failures)
    require(rover, r'def Scope "Thermal"[\s\S]*?active\s*=\s*false', "FLIP optional thermal graph is disabled until algebraic support is available", failures)
    require(rover, r'def Cube "RoverSolarBacksheet"[\s\S]*?physics:collisionEnabled\s*=\s*true', "FLIP has a solid visual solar backsheet", failures)
    require(rover, r'def Cube "RoverSolarCells"[\s\S]*?physics:collisionEnabled\s*=\s*true', "FLIP has a solid visual solar surface", failures)
    if count(rover, r'physxVehicleWheel:radius\s*=\s*0\.449999') != 4:
        failures.append("FLIP has four 0.45 m wheel radius values")
    if count(rover, r'physxVehicleWheel:width\s*=\s*0\.280000') != 4:
        failures.append("FLIP has four 0.28 m wheel width values")
    if sorted(re.findall(r'physxVehicleWheelAttachment:index\s*=\s*(\d+)', rover)) != ["0", "1", "2", "3"]:
        failures.append("FLIP wheel attachment indices are exactly 0, 1, 2, 3")
    if count(rover, r'inputs:steer\.connect\s*=\s*</FLIP\.outputs:steering>') != 4:
        failures.append("all four FLIP wheels share the authoritative steering port")

    # Scene identity, fixed mount, route/terrain/lighting contracts.
    require(scene, r'def "Lander"[\s\S]*?griffin_1\.usda@</Griffin1>', "scene mounts the Griffin assembly", failures)
    require(scene, r'def "FLIP"[\s\S]*?vehicles/flip\.usda@</FLIP>', "scene mounts FLIP as a separate assembly", failures)
    require(scene, r'def PhysicsFixedJoint "FLIPPayloadAdapterJoint"', "scene has an authored payload joint", failures)
    require(scene, r'lunco:lighting:contract\s*=\s*"[^"]*LunarSurface/Sun', "scene records the shared polar light", failures)
    require(scene, r'RoverRampApproach[\s\S]*?xformOp:translate\s*=\s*\(5\.3, 6\.2, 0\.8\)', "scene route starts outside the descent column", failures)
    require(assets, r'NAC_DTM_NOBILE03\.TIF', "terrain manifest names official NOBILE03 DTM", failures)
    require(assets, r'sha256\s*=\s*"[0-9a-f]{64}"', "terrain manifest pins a source hash", failures)

    # Mission animation and operator handoff contract. These checks require
    # the authored state machine to contain the real event boundaries: descent
    # and touchdown, ramp confirmation, adapter release, rover deployment, and
    # a route tree that continues after the release. A comment or a timer-only
    # PASS must not satisfy this part of the specification.
    require(scenario, r'wait_for_from\("lander_touchdown"', "scenario waits for physical touchdown", failures)
    require(scenario, r'fn deploy_ramps\(me\)[\s\S]*?griffin_ramps_deploy_commanded', "scenario owns the ramp deployment phase", failures)
    require(scenario, r'cmd\("DetachJoint"[\s\S]*?FLIPPayloadAdapterJoint', "scenario releases the top-deck payload joint", failures)
    require(scenario, r'emit\("griffin_flip_released"\)[\s\S]*?cmd\("EngageAutopilot"', "scenario hands route authority to FLIP after release", failures)
    require(scenario, r'emit\("griffin_flip_deployed"\)', "scenario emits the rover deployment milestone", failures)
    if count(behavior, r'<Action ID="drive_to"') < 3:
        failures.append("FLIP behavior tree contains a post-release route")
    require(behavior, r'target="/Griffin1SurfaceOps/RoverRampExit"', "FLIP route begins at the ramp exit", failures)
    require(behavior, r'target="/Griffin1SurfaceOps/BaseSite"', "FLIP route has a terminal base-site target", failures)
    require(controls, r'fn set_rover_steering_mode\(mode\)', "FLIP exposes an explicit steering-mode command", failures)
    require(controls, r'rover must be stopped', "FLIP steering change is guarded by a stop condition", failures)
    require(controls, r'SimulateIntent[\s\S]*held: true', "FLIP brake path is persistent while stopping", failures)

    if failures:
        print("FAIL: Griffin-1 authored specification")
        for failure in failures:
            print(f"  - {failure}")
        return 1

    print("PASS: Griffin-1 authored specification")
    print(f"  lander wrapper: {wrapper_path.relative_to(ROOT)}")
    print(f"  rover assembly: {rover_path.relative_to(ROOT)}")
    print(f"  mission scene:  {scene_path.relative_to(ROOT)}")
    print("  collision, wheel, steering, mount, light, terrain, animation, and handoff contracts present")
    return 0


if __name__ == "__main__":
    sys.exit(main())
