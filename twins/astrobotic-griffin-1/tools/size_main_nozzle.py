#!/usr/bin/env python3
"""Reproduce the provisional Griffin nozzle envelope; never writes USD.

Historical thrust: Astrobotic PUG, January 2022, p.26 (five-engine variant).
Equations: https://www.grc.nasa.gov/WWW/BGH/isentrop.html
Current pressure, expansion ratio, gamma and length fraction are study inputs,
not released Frontier dimensions. The runtime BellNozzle is the acceptance owner.
"""
import argparse
import json
import math


def size(thrust_n, pressure_pa, expansion, gamma, length_fraction, wall_m):
    if not (thrust_n > 0 and pressure_pa > 0 and expansion > 1 and gamma > 1
            and 0 < length_fraction <= 1 and wall_m > 0):
        raise ValueError("invalid nozzle study inputs")

    def area_ratio(mach):
        return ((2 / (gamma + 1)) * (1 + (gamma - 1) * mach**2 / 2)) ** (
            (gamma + 1) / (2 * (gamma - 1))) / mach

    lower, upper = 1.0, 2.0
    while area_ratio(upper) < expansion:
        upper *= 2
    for _ in range(100):
        mach = (lower + upper) / 2
        if area_ratio(mach) < expansion:
            lower = mach
        else:
            upper = mach
    exit_pressure_ratio = (1 + (gamma - 1) * mach**2 / 2) ** (-gamma / (gamma - 1))
    coefficient = math.sqrt(2 * gamma**2 / (gamma - 1)
        * (2 / (gamma + 1)) ** ((gamma + 1) / (gamma - 1))
        * (1 - exit_pressure_ratio ** ((gamma - 1) / gamma))) + exit_pressure_ratio * expansion
    throat_area = thrust_n / (coefficient * pressure_pa)
    throat = math.sqrt(throat_area / math.pi)
    exit_radius = throat * math.sqrt(expansion)
    return dict(throat_bore_radius_m=throat, exit_bore_radius_m=exit_radius,
        outside_diameter_m=2 * (exit_radius + wall_m),
        bell_length_m=length_fraction * (exit_radius - throat) / math.tan(math.radians(15)),
        throat_area_m2=throat_area, vacuum_thrust_coefficient=coefficient,
        exit_mach=mach, exit_pressure_ratio=exit_pressure_ratio)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--thrust-n", type=float, default=700 * 4.4482216152605)
    parser.add_argument("--pressure-pa", type=float, default=1_500_000)
    parser.add_argument("--expansion", type=float, default=100)
    parser.add_argument("--gamma", type=float, default=1.2)
    parser.add_argument("--length-fraction", type=float, default=.8)
    parser.add_argument("--wall-m", type=float, default=.006)
    args = parser.parse_args()
    print(json.dumps(dict(inputs=vars(args), status="provisional study, not flight dimensions",
        outputs=size(args.thrust_n, args.pressure_pa, args.expansion, args.gamma,
                     args.length_fraction, args.wall_m)), indent=2))
