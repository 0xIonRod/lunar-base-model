"""Reduced planar drive response; supplementary evidence, NOT native physics acceptance.

Read the exact open FLIP document through the production API. Integrate its
torque-limited hinge, lunar gravity and a +/-3 m/s^2 base-acceleration pulse.
This excludes contact, 3D chassis rotation and solver compliance. The authored
flip_motion.rhai gate remains the native driving/braking acceptance test.
"""
import argparse
import json
import math
import re
from pathlib import Path
from urllib.request import Request, urlopen


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, required=True)
    parser.add_argument('--baseline-stiffness', type=float, required=True)
    parser.add_argument('--baseline-damping', type=float, required=True)
    args = parser.parse_args()

    def command(name, **params):
        request = Request(f'http://127.0.0.1:{args.port}/api/commands',
                          data=json.dumps({'type': 'ExecuteCommand', 'command': name,
                                           'params': params}).encode(),
                          headers={'Content-Type': 'application/json'})
        result = json.load(urlopen(request, timeout=10))
        if 'error' in result:
            raise RuntimeError(result)
        return result['data']

    docs = command('ListOpenDocuments')['open_documents']
    matches = [d for d in docs if d['title'] == 'flip_v5' and d['kind'] == 'usd']
    if len(matches) != 1:
        raise RuntimeError('Open exactly one canonical flip_v5 document')
    doc = matches[0]['doc_id']

    def read(path, names):
        result = command('QueryUsdPrim', doc_id=doc, path=path, attrs=names)
        if any(result['attrs'].get(n) is None for n in names):
            raise RuntimeError(f'Missing authored facts: {result}')
        return result

    joint = read('/FLIP/PanelHinge', ['drive:angular:physics:stiffness',
                 'drive:angular:physics:damping', 'drive:angular:physics:maxForce'])
    body = read('/FLIP/SolarMechanism', ['physics:mass', 'physics:centerOfMass',
                'physics:diagonalInertia'])
    controller = read('/FLIP/SolarMechanism/Controller', ['inputs:initial_deg'])
    if len({r['generation'] for r in (joint, body, controller)}) != 1:
        raise RuntimeError('Document generation changed during response-model read')
    m = body['attrs']['physics:mass']
    x, y, _ = body['attrs']['physics:centerOfMass']
    inertia = body['attrs']['physics:diagonalInertia'][2] + m * (x*x + y*y)
    target = -math.radians(controller['attrs']['inputs:initial_deg'])
    cap = joint['attrs']['drive:angular:physics:maxForce']
    assert m > 0 and inertia > 0 and cap > 0

    def response(k_deg, c_deg):
        # Standard USD angular gains are per degree; native motor uses radians.
        k, c = k_deg * 180/math.pi, c_deg * 180/math.pi

        def derivative(t, state):
            theta, rate = state
            accel = 3.0 if 2 <= t < 4 else (-3.0 if 6 <= t < 8 else 0.0)
            world_x = x*math.cos(theta) - y*math.sin(theta)
            world_y = x*math.sin(theta) + y*math.cos(theta)
            drive = max(-cap, min(cap, k*(target-theta)-c*rate))
            torque = -m*1.62*world_x + m*accel*world_y + drive
            return rate, torque/inertia

        state = (target, 0.0)
        max_error = max_rate = 0.0
        step = 0.001
        for tick in range(12000):
            t = tick*step
            a = derivative(t, state)
            b = derivative(t+step/2, tuple(v+step*d/2 for v, d in zip(state, a)))
            c1 = derivative(t+step/2, tuple(v+step*d/2 for v, d in zip(state, b)))
            d = derivative(t+step, tuple(v+step*dv for v, dv in zip(state, c1)))
            state = tuple(v+step*(aa+2*bb+2*cc+dd)/6
                          for v, aa, bb, cc, dd in zip(state, a, b, c1, d))
            assert all(math.isfinite(v) for v in state)
            max_error = max(max_error, abs(math.degrees(state[0]-target)))
            max_rate = max(max_rate, abs(math.degrees(state[1])))
        return {'maximum_error_deg': max_error, 'maximum_rate_deg_s': max_rate,
                'native_stiffness_nm_per_rad': k, 'native_damping_nms_per_rad': c,
                'damping_ratio': c/(2*math.sqrt(k*inertia))}

    baseline = response(args.baseline_stiffness, args.baseline_damping)
    revised = response(joint['attrs']['drive:angular:physics:stiffness'],
                       joint['attrs']['drive:angular:physics:damping'])
    # Only these two scalar acceptance facts are read from the owning contract;
    # this external analysis driver is not a general SysML interpreter.
    contract = (Path(__file__).resolve().parents[1] /
                'requirements/flip_motion_requirements.sysml').read_text()
    limits = {}
    for name in ('maximumPanelAngleErrorDeg', 'maximumPanelRateDegPerS'):
        matches = re.findall(r'attribute\s+'+name+r'\s*:\s*Real\s*=\s*([0-9.]+)\s*;', contract)
        if len(matches) != 1:
            raise RuntimeError(f'Expected one scalar acceptance value: {name}')
        limits[name] = float(matches[0])
    # This comparison establishes reduced-model improvement, not native limits.
    assert revised['maximum_error_deg'] < baseline['maximum_error_deg']
    assert revised['maximum_rate_deg_s'] < baseline['maximum_rate_deg_s']
    assert baseline['maximum_error_deg'] > limits['maximumPanelAngleErrorDeg']
    assert revised['maximum_error_deg'] <= limits['maximumPanelAngleErrorDeg']
    assert revised['maximum_rate_deg_s'] <= limits['maximumPanelRateDegPerS']
    report = {'scope': 'reduced planar response only; native acceptance pending',
              'document': doc, 'generation': joint['generation'],
              'inertia_about_hinge_kg_m2': inertia, 'torque_cap_nm': cap,
              'limits': limits, 'baseline': baseline, 'revised': revised}
    output = Path(__file__).resolve().parents[1] / '.cache/flip-panel-hold'
    output.mkdir(parents=True, exist_ok=True)
    (output/'response.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
