#!/usr/bin/env python3
"""Qualify the physical motion gate and its terminal missing-brake rejection.

The authoring port must belong to an owned windowed session with this Twin open.
The engine checkout supplies the common production-session/API boundary.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import sys
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--engine', type=Path, required=True)
    parser.add_argument('--author-port', type=int, required=True)
    parser.add_argument('--test-port', type=int, required=True)
    parser.add_argument('--case', action='append', choices=['positive', 'no-brake-command'])
    args = parser.parse_args()
    if args.author_port == args.test_port:
        parser.error('authoring and test ports must differ')
    engine = args.engine.resolve()
    twin = Path(__file__).resolve().parents[1]
    binary = Path(os.environ.get('LUNCOSIM_BIN', engine / 'target/debug/luncosim')).resolve()
    os.environ.update(LUNCOSIM_BIN=str(binary), LUNCOSIM_EPHEMERAL_SETTINGS='1',
                      LUNCOSIM_ISOLATED_RUN='1')
    sys.path.insert(0, str(engine / 'scripts/api'))
    from runtime import ProductionSession, request_json

    output = twin / '.cache/flip-motion-qualification'
    output.mkdir(parents=True, exist_ok=True)

    def command(command_name, **params):
        response = request_json(args.author_port,
            {'type': 'ExecuteCommand', 'command': command_name, 'params': params}, timeout_s=60)
        if response.get('error'):
            raise RuntimeError(response)
        return response['data']

    def documents():
        return command('ListOpenDocuments')['open_documents']

    source = twin / 'tests/flip_motion.usda'
    original_hash = hashlib.sha256(source.read_bytes()).hexdigest()
    command('OpenFile', path=str(source))
    deadline = time.monotonic() + 60
    while time.monotonic() < deadline:
        original = next((d for d in documents() if d.get('origin', {}).get('path') == str(source)), None)
        if original:
            break
        time.sleep(.1)
    else:
        raise RuntimeError('positive motion fixture did not open')
    if original['dirty']:
        raise RuntimeError('positive motion document has unsaved edits')

    def run(name, scene, expected_code, verification=False):
        os.environ['LUNCOSIM_CONFIG'] = str(output / (name + '-config'))
        log = output / (name + '.log')
        test_args = ['--scene', str(scene), '--verdict-channel', 'FLIP_MOTION_COMPLETE',
                     '--max-ticks', '2400', '--readiness-timeout', '60']
        if verification:
            test_args += ['--verification', 'FlipMotionRequirements::Verify_FLIPMotion']
        with ProductionSession(args.test_port, subcommand='test', require_readiness=False,
                               extra_args=test_args, log_path=log) as session:
            process = session.process
            if Path('/proc').exists():
                assert Path(f'/proc/{process.pid}/cwd').resolve() == engine
                assert Path(f'/proc/{process.pid}/exe').resolve() == binary
            code = process.wait(timeout=120)
        text = log.read_text()
        verdict = 'PASS' if expected_code == 0 else 'FAIL'
        if code != expected_code or f'luncosim test {verdict} ' not in text \
                or f'[rhai] FLIP MOTION COMPLETE: {verdict}' not in text \
                or 'NO-VERDICT' in text or '[rhai] on_tick() failed' in text:
            raise RuntimeError(f'{name} did not produce its required terminal verdict; {log}')
        if expected_code == 0:
            assert '[rhai] TESTS_OK 44' in text, log
        else:
            for detail in ['braking: stopped-speed requirement failed', 'initial=', 'elapsed=', 'distance=']:
                assert detail in text, (detail, log)
        return {'name': name, 'exit_code': code, 'verdict': verdict, 'log': str(log)}

    selected = args.case or ['positive', 'no-brake-command']
    results = [run('positive', source, 0, verification=True)] if 'positive' in selected else []
    if 'no-brake-command' not in selected:
        (output / 'results-positive.json').write_text(json.dumps(results, indent=2) + '\n')
        print('PASS: 44 authored physical motion and panel-hold checks')
        return
    target = twin / 'tests/_motion_failure_no_brake_command.usda'
    if target.exists():
        raise RuntimeError(f'disposable fixture already exists: {target}')
    fork = command('ForkDocument', source_doc_id=original['doc_id'], name='Motion without brake command')
    doc = fork['doc_id']
    try:
        command('InspectUsdEditSession', doc_id=doc)
        command('SaveAsDocument', doc_id=doc, path=str(target))
        command('OpenUsdPreview', preview=doc, doc_id=doc, edit_target='@root@')
        deadline = time.monotonic() + 60
        while time.monotonic() < deadline:
            previews = command('InspectUsdViewport')['previews']
            if any(p['doc_id'] == doc and p['projection_ready'] and p['text_ready'] for p in previews):
                break
            time.sleep(.15)
        else:
            raise RuntimeError('negative motion preview did not compose')
        receipt = command('ApplyUsdOps', doc_id=doc, label='Omit the physical braking command', ops=[
            {'SetAttribute': {'edit_target': '@root@', 'path': '/Griffin1SurfaceOps/Scenario/Test',
                              'name': 'inputs:apply_brake', 'type_name': 'bool', 'value': 'false'}}])
        assert receipt['status'] == 'applied', receipt
        command('SaveDocument', doc_id=doc)
        deadline = time.monotonic() + 30
        while next(d for d in documents() if d['doc_id'] == doc)['dirty']:
            if time.monotonic() >= deadline:
                raise RuntimeError('negative fixture save did not finish')
            time.sleep(.1)
        command('CloseDocument', doc_id=doc)
        results.append(run('no-brake-command', target, 1))
    finally:
        if any(d['doc_id'] == doc for d in documents()):
            command('CloseDocument', doc_id=doc)
        target.unlink(missing_ok=True)
    assert hashlib.sha256(source.read_bytes()).hexdigest() == original_hash
    report = {'binary_sha256': hashlib.sha256(binary.read_bytes()).hexdigest(),
              'positive_source_sha256': original_hash, 'results': results,
              'negative_fixture_removed': not target.exists()}
    (output / 'results.json').write_text(json.dumps(report, indent=2) + '\n')
    print('PASS: selected motion trials produced their required terminal verdicts and diagnostics')


if __name__ == '__main__':
    main()
