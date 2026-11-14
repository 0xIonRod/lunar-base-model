#!/usr/bin/env python3
"""Run the tether's OpenModelica contracts without generating files in the Twin."""

import json
from pathlib import Path
import subprocess
import sys
import tempfile


def main():
    twin = Path(__file__).resolve().parents[1]
    with tempfile.TemporaryDirectory(prefix="griffin-tether-contract-") as work:
        script = Path(work) / "contract.mos"
        files = [twin / "models/GriffinTetherPairStudy.mo",
                 twin / "tests/GriffinTetherPairContract.mo"]
        script.write_text(
            "\n".join(f"loadFile({json.dumps(str(path), ensure_ascii=False)});" for path in files)
            + "\ngetErrorString();\ncheckModel(GriffinTetherPairContract);\n"
            + "simulate(GriffinTetherPairContract, stopTime=3.0, numberOfIntervals=100);\n"
            + "getErrorString();\n",
            encoding="utf-8",
        )
        result = subprocess.run(["omc", str(script)], cwd=work, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        sys.stdout.write(result.stdout)
        return 0 if result.returncode == 0 and "The simulation finished successfully." in result.stdout else 1


if __name__ == "__main__":
    raise SystemExit(main())
