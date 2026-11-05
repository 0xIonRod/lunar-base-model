#!/usr/bin/env python3
"""Check the saved Moon view, reject a clipped target, and restore its view layer."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import sys
import time
from PIL import Image


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--engine', type=Path, required=True)
    parser.add_argument('--port', type=int, required=True)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--render-quality', choices=['low', 'balanced', 'high'], default='high')
    args = parser.parse_args()
    engine = args.engine.resolve()
    twin = Path(__file__).resolve().parents[1]
    source = twin / 'media/griffin_flip_v13/scenes/moon-day.usda'
    output = (args.output or engine / '.cache/moon-presentation-qualification').resolve()
    if not output.is_relative_to(engine):
        parser.error('--output must stay under the engine workspace for screenshot access')
    output.mkdir(parents=True, exist_ok=True)
    source_hash = hashlib.sha256(source.read_bytes()).hexdigest()
    binary = Path(os.environ.get('LUNCOSIM_BIN', engine / 'target/debug/luncosim')).resolve()
    os.environ.update(LUNCOSIM_BIN=str(binary), LUNCOSIM_CONFIG=str(output / 'config'),
                      LUNCOSIM_EPHEMERAL_SETTINGS='1', LUNCOSIM_ISOLATED_RUN='1')
    sys.path.insert(0, str(engine / 'scripts/api'))
    from runtime import ProductionSession, run_authored_scenario, assert_render_log_clean
    log = output / 'app.log'
    observer = 'twin://astrobotic-griffin-1/scenarios/tests/moon_presentation.rhai'
    with ProductionSession(args.port, windowed=True,
                           extra_args=['--scene', str(source), '--render-quality', args.render_quality],
                           log_path=log) as session:
        pid = session.process.pid
        if Path('/proc').exists():
            assert Path(f'/proc/{pid}/cwd').resolve() == engine
            assert Path(f'/proc/{pid}/exe').resolve() == binary

        def command(name, **params):
            response = session.post({'type': 'ExecuteCommand', 'command': name, 'params': params})
            if response.get('error'):
                raise RuntimeError(response)
            return response['data']

        path = '/Griffin1SurfaceOps/MoonView'
        deadline = time.monotonic() + 120
        while time.monotonic() < deadline:
            ready = command('GetReadiness')
            if ready.get('faulted'):
                raise RuntimeError(ready)
            cameras = command('ReadExposures', surface='camera-status')
            props = cameras.get('surfaces', {}).get('camera-status', {}).get('properties', {})
            elapsed = command('RunRhai', code='get_setting("WorldTime.sim_secs")')['stdout']
            if ready.get('ready') and not ready.get('pending_count') and not ready.get('world_hold') \
                    and props.get('active_name') == path and float(elapsed) > 0:
                break
            time.sleep(.2)
        else:
            raise RuntimeError('the saved Moon view did not settle on its authored camera')
        run_authored_scenario(session, observer, title='MOON PRESENTATION', check_count=10)
        camera = command('QueryUsdPrim', path=path, attrs=['clippingRange'])
        doc = camera['doc_id']
        original_range = camera['attrs']['clippingRange']

        def clip(value):
            receipt = command('ApplyUsdTransientOps', doc_id=doc, parent_gen=None,
                label='Qualify Moon camera clipping', ops=[{'SetAttribute': {
                    'edit_target': '@view@', 'path': path, 'name': 'clippingRange',
                    'type_name': 'float2', 'value': '(' + ', '.join(map(str, value)) + ')'}}])
            assert receipt['status'] == 'applied', receipt
            deadline = time.monotonic() + 30
            while time.monotonic() < deadline:
                live = command('QueryUsdPrim', path=path, attrs=['clippingRange'])
                if live['attrs']['clippingRange'] == value and live['stage_generation'] == receipt['generation']:
                    return
                time.sleep(.1)
            raise RuntimeError('camera clipping projection did not commit')

        try:
            clip([original_range[0], 1000000.0])
            offset = log.stat().st_size
            command('RunScenarioAsset', source_asset=observer, reload_policy='retain', params={})
            deadline = time.monotonic() + 30
            while time.monotonic() < deadline:
                with log.open('rb') as stream:
                    stream.seek(offset)
                    text = stream.read().decode(errors='replace')
                if '[rhai] MOON PRESENTATION: FAIL' in text:
                    assert 'Moon camera far plane excludes its authored target' in text
                    assert '[rhai] TESTS_FAIL 1/10' in text, text
                    break
                if command('GetReadiness').get('faulted'):
                    raise RuntimeError('runtime fault does not qualify clipping rejection')
                time.sleep(.1)
            else:
                raise RuntimeError('clipped target did not produce its authored failure')
        finally:
            clip(original_range)
        run_authored_scenario(session, observer, title='MOON PRESENTATION', check_count=10)
        # Source readiness precedes asynchronous GPU pipeline preparation.
        # Observe the rendered globe itself; UI chrome cannot satisfy this crop.
        deadline = time.monotonic() + 60
        rendered_samples = []
        visible_streak = 0
        previous_bright = None
        while time.monotonic() < deadline:
            assert_render_log_clean(log)
            session.capture_screenshot(output / 'moon.png')
            with Image.open(output / 'moon.png') as image:
                width, height = image.size
                center = image.crop((width // 4, height // 4, width * 3 // 4, height * 3 // 4)).convert('L')
                bright = sum(center.histogram()[13:])
                area = center.width * center.height
            rendered_samples.append({'bright_pixels': bright, 'crop_pixels': area})
            if bright > area / 100 and previous_bright is not None and abs(bright - previous_bright) < area / 100:
                visible_streak += 1
            else:
                visible_streak = 0
            previous_bright = bright
            if visible_streak >= 2:
                break
            diagnostics = command('RuntimeDiagnostics')
            if diagnostics['errors']:
                raise RuntimeError(diagnostics)
            time.sleep(2)
        else:
            raise RuntimeError('Moon remains blank after bounded render preparation')
        diagnostics = command('RuntimeDiagnostics')
        assert diagnostics['errors'] == 0, diagnostics
        (output / 'runtime.json').write_text(json.dumps({'readiness': command('GetReadiness'),
            'rendered_samples': rendered_samples, 'render_quality': args.render_quality,
            'diagnostics': diagnostics, 'cameras': command('SceneCameraAudit')}, indent=2) + '\n')
        assert_render_log_clean(log)
    assert hashlib.sha256(source.read_bytes()).hexdigest() == source_hash
    assert_render_log_clean(log)
    print('PASS: saved Moon view, exact clipped-target rejection, restored render and source preservation')


if __name__ == '__main__':
    main()
