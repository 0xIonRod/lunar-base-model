#!/usr/bin/env python3
"""Check the native shadow lattice from FLIP's moving camera under a live celestial clock."""
import argparse
import math
import os
from pathlib import Path
import struct
import sys
import time


def wait_for(read, timeout):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        value = read()
        if value:
            return value
        time.sleep(0.25)
    raise RuntimeError(f"Timed out waiting for {read.__name__}")


def floats(bits):
    return struct.unpack("<16f", struct.pack("<16I", *bits))


def shadow_coordinates(audit, scene, camera_path):
    cameras = audit["candidates"]
    camera = next(c for c in cameras if c["camera_active"] and c["render_target"] == "window")
    if camera["usd_path"] != camera_path:
        raise RuntimeError(f"Unexpected active camera {camera['usd_path']}")
    fixed = next(c for c in cameras if c["usd_path"] == scene + "/Avatar")
    sun = next(light for light in audit["shadow_inputs"]["lights"] if light["usd_path"] == scene + "/Sun")
    cascade = next(c for c in sun["maps"] if c["camera"] == camera["entity"] and c["cascade"] == 0)
    pitch, = struct.unpack("<f", struct.pack("<I", cascade["texel_size_bits"]))
    size = round(2 / (floats(cascade["clip_from_cascade_bits"])[0] * pitch))
    matrix = floats(cascade["clip_from_world_bits"])
    position = fixed["world_translation"]
    point = [*position, 1.0]
    uv = [sum(matrix[4 * i + axis] * point[i] for i in range(4)) * size / 2 for axis in (0, 1)]
    return position, uv


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sim-root", required=True, type=Path)
    parser.add_argument("--port", required=True, type=int)
    args = parser.parse_args()
    sim = args.sim_root.resolve()
    sys.path.insert(0, str(sim / "scripts/api"))
    from runtime import BINARY, ProductionSession, port_is_open, request_json

    scene_file = Path(__file__).resolve().parents[1] / "scenes/flip_cad_drive.usda"
    scene = "/Griffin1SurfaceOps"
    camera = scene + "/FLIP/ForwardDriveCamera"
    os.environ.update(BEVY_ASSET_ROOT=str(sim), LUNCOSIM_ISOLATED_RUN="1", LUNCOSIM_EPHEMERAL_SETTINGS="1")
    with ProductionSession(args.port, windowed=True, require_readiness=False, extra_args=[
        "--scene", str(scene_file), "--render-quality", "high", "--no-vsync", "--no-throttle",
        "--window-pos", "1600x1000+0+0",
    ]) as session:
        pid = session.process.pid
        if Path(f"/proc/{pid}/cwd").resolve() != sim or Path(f"/proc/{pid}/exe").resolve() != BINARY.resolve():
            raise RuntimeError("Production session does not match the requested checkout and binary")

        wait_for(lambda: port_is_open(args.port), 120)

        def command(command_name, **params):
            result = request_json(args.port, {"type": "ExecuteCommand", "command": command_name, "params": params}, timeout_s=60)
            if result.get("error"):
                raise RuntimeError(result["error"])
            return result["data"]

        def find(path):
            value = int(command("RunRhai", code=f'print(find_path("{path}"));')["stdout"])
            return value if value > 0 else None

        def scene_ready():
            state = command("GetReadiness")
            if state["faulted"]:
                raise RuntimeError(state["fault"])
            return state["ready"] and not state["world_hold"]

        rover = wait_for(lambda: find(scene + "/FLIP"), 180)
        avatar = wait_for(lambda: find(scene + "/Avatar"), 30)
        wait_for(scene_ready, 180)
        command("SetTimeTransport", playing=True)

        def rover_position():
            return command("QueryEntity", id=rover)["position"]

        def settled():
            state = command("QueryPhysicsState", id=rover)
            return state["sleeping"] or (math.hypot(*state["linear_velocity_mps"]) < 0.001
                                         and math.hypot(*state["angular_velocity_radps"]) < 0.001)

        wait_for(settled, 180)
        start = rover_position()
        command("SetUserCamera", name=camera)
        command("SetCelestialClock", epoch_jd=2461395.5, scale=1)
        command("SetPorts", target=rover, producer_id=63500, writes=[
            ["program_active", 1.0], ["autopilot_enable", 1.0],
            ["autopilot_target_x", start[0]], ["autopilot_target_z", start[2] - 90.0],
            ["autopilot_speed", 1.0], ["autopilot_radius", 0.3],
            ["autopilot_turn_only", 0.0], ["throttle", 0.0], ["brake", 0.0],
        ])
        wait_for(lambda: math.dist(start, rover_position()) > 0.1, 120)
        fixed_start = command("QueryEntity", id=avatar)["position"]
        start = rover_position()
        samples = []
        end = time.monotonic() + 12
        while time.monotonic() < end:
            audit = command("SceneCameraAudit", shadow_inputs=True, shadow_caster_limit=0)
            samples.append(shadow_coordinates(audit, scene, camera))
            time.sleep(0.35)
        distance = math.dist(start, rover_position())
        fixed_motion = math.dist(fixed_start, command("QueryEntity", id=avatar)["position"])
        displacement = max(math.dist(samples[0][0], pos) for pos, _ in samples)
        phase = max(abs(math.remainder(uv[i] - samples[0][1][i], 1.0))
                    for _, uv in samples for i in (0, 1))
        print(f"{len(samples)} observations, drive {distance:.2f} m, observer motion {fixed_motion:.5f} m, "
              f"render displacement {displacement:.2f} m, maximum phase change {phase:.4f} texel")
        if len(samples) < 4 or distance < 1 or displacement < 10 or fixed_motion > 0.001:
            raise RuntimeError("Capture did not exercise a moving rover and a stationary physical observer")
        if phase > 0.1:
            raise RuntimeError("Shadow grid slipped by more than 0.1 texel at the stationary site point")


if __name__ == "__main__":
    main()
