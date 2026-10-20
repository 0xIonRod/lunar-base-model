"""Read the CAD study's explicit scalar/sample contract, not general SysML syntax."""
from pathlib import Path
import hashlib
import math
import re


def read_contract():
    path = Path(__file__).resolve().parents[2] / 'twins/astrobotic-griffin-1/requirements/flip_cad_requirements.sysml'
    source = path.read_text(encoding='utf-8')
    number = r'[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?'
    values = {name: float(value) for name, value in re.findall(
        r'attribute\s+(\w+)\s*:\s*(?:Real|Integer)\s*=\s*(' + number + r')\s*;', source)}
    samples = {}
    for name in ['panelSamplesDeg', 'wheelSamplesDeg']:
        match = re.search(r'attribute\s+' + name + r'\s*:\s*String\s*=\s*"([^"]+)"\s*;', source)
        if match is None:
            raise ValueError('CAD contract omits ' + name)
        samples[name] = [float(value.strip()) for value in match[1].split(';', 1)[0].split(',')]
        if not samples[name] or not all(math.isfinite(value) for value in samples[name]):
            raise ValueError('CAD contract has invalid samples: ' + name)
    if not values or not all(math.isfinite(value) for value in values.values()):
        raise ValueError('CAD contract has no finite scalar values')
    return path, hashlib.sha256(path.read_bytes()).hexdigest(), values, samples
