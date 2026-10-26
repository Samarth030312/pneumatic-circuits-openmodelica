"""Build and run the Modelica experiments with OpenModelica, in its official container.

build(model)                   compiles PneumaticCircuits.Experiments.<model> once
run(model, overrides, name)    runs the executable with parameter overrides, returns the result
                               as {variable: numpy array}, and keeps the CSV in build/runs/
"""
import csv
import os
import subprocess
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
IMAGE = os.environ.get("OM_IMAGE", "openmodelica/openmodelica:v1.27.1-minimal")
BUILD = ROOT / "build"
PKG = "PneumaticCircuits.Experiments."


def _docker(cmd, cwd="/work"):
    """Run a shell command in the OpenModelica container with the repository mounted at /work."""
    full = ["docker", "run", "--rm", "-u", f"{os.getuid()}:{os.getgid()}", "-e", "HOME=/tmp",
            "-v", f"{ROOT}:/work", "-w", cwd, IMAGE, "bash", "-c", cmd]
    r = subprocess.run(full, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"container command failed ({r.returncode}): {cmd}\n{r.stdout}\n{r.stderr}")
    return r.stdout


def omc_version():
    return _docker("omc --version").strip()


def build(model, stop_time=None, interval=None):
    """Compile one experiment model (its experiment annotation sets the defaults)."""
    d = BUILD / model
    d.mkdir(parents=True, exist_ok=True)
    opts = 'outputFormat="csv"'
    if stop_time is not None:
        opts += f", stopTime={stop_time}"
    if interval is not None:
        opts += f", stepSize={interval}"
    mos = d / "build.mos"
    mos.write_text(
        'loadFile("/work/modelica/PneumaticCircuits/package.mo"); getErrorString();\n'
        f'buildModel({PKG}{model}, {opts}); getErrorString();\n')
    out = _docker(f"omc /work/build/{model}/build.mos", cwd=f"/work/build/{model}")
    exe = d / (PKG + model)
    if not exe.exists():
        raise RuntimeError(f"build of {model} failed:\n{out}")
    return out


def run(model, overrides=None, name="run", stop_time=None):
    """Run a built model with parameter overrides {name: value}; return {variable: array}."""
    runs = BUILD / "runs"
    runs.mkdir(parents=True, exist_ok=True)
    ov = dict(overrides or {})
    flag = ("-override=" + ",".join(f"{k}={v}" for k, v in ov.items())) if ov else ""
    if stop_time is not None:
        flag += f" -stopTime={stop_time}"
    res = f"/work/build/runs/{name}.csv"
    log = _docker(f"./{PKG}{model} {flag} -r={res} -lv=-LOG_SUCCESS 2>&1", cwd=f"/work/build/{model}")
    if "override variable name not found" in log or "error" in log.lower():
        raise RuntimeError(f"{name}: the simulation reported a problem:\n{log}")
    R = read_csv(runs / f"{name}.csv")
    if stop_time is not None and abs(R["time"][-1] - stop_time) > 1e-9:
        raise RuntimeError(f"{name}: result ends at {R['time'][-1]} s, not {stop_time} s")
    return R


def read_csv(path):
    with open(path) as f:
        rows = list(csv.reader(f))
    head = [h.strip('"') for h in rows[0]]
    data = np.array([[float(v) for v in r] for r in rows[1:]])
    # OpenModelica writes the values at an event twice (left and right limits): keep both, in order
    return {h: data[:, i] for i, h in enumerate(head)}
