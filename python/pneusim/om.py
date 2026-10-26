"""Build and run the Modelica models with OpenModelica: a native installation if there is one,
otherwise the official container.

build(model)                   compiles PneumaticCircuits.<PKG><model> once
run(model, overrides, name)    runs the executable with parameter overrides and returns the result
                               as {variable: numpy array}; the CSV stays in build/runs/

Engine: OM_ENGINE=native or docker forces one; by default a native omc (on PATH, or under
OPENMODELICAHOME as on Windows) is used, else Docker.
"""
import csv
import os
import platform
import shutil
import subprocess
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
IMAGE = os.environ.get("OM_IMAGE", "openmodelica/openmodelica:v1.27.1-minimal")
BUILD = ROOT / "build"
PKG = "PneumaticCircuits.Experiments."
WINDOWS = platform.system() == "Windows"


def _native_omc():
    home = os.environ.get("OPENMODELICAHOME")
    if home:
        exe = Path(home) / "bin" / ("omc.exe" if WINDOWS else "omc")
        if exe.exists():
            return str(exe)
    return shutil.which("omc")


def engine():
    forced = os.environ.get("OM_ENGINE")
    if forced in ("native", "docker"):
        return forced
    return "native" if _native_omc() else "docker"


def _env():
    env = dict(os.environ)
    omc = _native_omc()
    if omc:                       # the simulation executables need OpenModelica's libraries (DLLs on Windows)
        home = Path(omc).parent.parent
        dirs = [Path(omc).parent] + [home / d for d in ("tools/msys/ucrt64/bin", "tools/msys/mingw64/bin", "lib/omc", "lib/omc/omsicpp")]
        env["PATH"] = os.pathsep.join(str(d) for d in dirs if d.exists()) + os.pathsep + env.get("PATH", "")
    return env


def _run(args, cwd, docker_cmd):
    """run a command natively (args, in cwd) or in the container (docker_cmd, with the repository at /work)"""
    if engine() == "native":
        r = subprocess.run(args, cwd=cwd, capture_output=True, text=True, env=_env())
    else:
        if not shutil.which("docker"):
            raise RuntimeError("neither OpenModelica (omc) nor Docker was found: install one (see docs/INSTALL.md)")
        rel = Path(cwd).resolve().relative_to(ROOT).as_posix()
        user = [] if WINDOWS else ["-u", f"{os.getuid()}:{os.getgid()}"]
        r = subprocess.run(["docker", "run", "--rm", *user, "-e", "HOME=/tmp", "-v", f"{ROOT}:/work",
                            "-w", f"/work/{rel}", IMAGE, "bash", "-c", docker_cmd], capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"command failed ({r.returncode}): {args}\n{r.stdout}\n{r.stderr}")
    return r.stdout + r.stderr


def omc_version():
    if engine() == "native":
        return _run([_native_omc(), "--version"], ROOT, "").strip()
    return _run([], ROOT, "omc --version").strip()


def available():
    return engine() == "native" or bool(shutil.which("docker")) and \
        subprocess.run(["docker", "info"], capture_output=True).returncode == 0


def script(text):
    """run an OpenModelica script (.mos text, paths relative to the repository) and return its output"""
    d = BUILD / "scripts"
    d.mkdir(parents=True, exist_ok=True)
    pkg = "/work/modelica/PneumaticCircuits/package.mo" if engine() == "docker" else \
        (ROOT / "modelica" / "PneumaticCircuits" / "package.mo").as_posix()
    (d / "s.mos").write_text(text.replace("modelica/PneumaticCircuits/package.mo", pkg))
    return _run([_native_omc() or "omc", "s.mos"], d, "omc s.mos")


def _exe(model, d):
    name = PKG + model + (".exe" if WINDOWS and engine() == "native" else "")
    return d / name


def build(model, stop_time=None, interval=None):
    """Compile one model (its experiment annotation sets the defaults)."""
    d = BUILD / model
    d.mkdir(parents=True, exist_ok=True)
    opts = 'outputFormat="csv"'
    if stop_time is not None:
        opts += f", stopTime={stop_time}"
    if interval is not None:
        opts += f", stepSize={interval}"
    pkg = "/work/modelica/PneumaticCircuits/package.mo" if engine() == "docker" else \
        (ROOT / "modelica" / "PneumaticCircuits" / "package.mo").as_posix()
    (d / "build.mos").write_text(f'loadFile("{pkg}"); getErrorString();\n'
                                 f'buildModel({PKG}{model}, {opts}); getErrorString();\n')
    out = _run([_native_omc() or "omc", "build.mos"], d, "omc build.mos")
    if not _exe(model, d).exists():
        raise RuntimeError(f"build of {model} failed:\n{out}")
    return out


def run(model, overrides=None, name="run", stop_time=None):
    """Run a built model with parameter overrides {name: value}; return {variable: array}."""
    runs = BUILD / "runs"
    runs.mkdir(parents=True, exist_ok=True)
    flags = []
    if overrides:
        flags.append("-override=" + ",".join(f"{k}={v}" for k, v in overrides.items()))
    if stop_time is not None:
        flags.append(f"-stopTime={stop_time}")
    d = BUILD / model
    if engine() == "native":
        res = (runs / f"{name}.csv").resolve()
        log = _run([str(_exe(model, d).resolve()), *flags, f"-r={res}", "-lv=-LOG_SUCCESS"], d, "")
    else:
        log = _run([], d, f"./{PKG}{model} {' '.join(flags)} -r=/work/build/runs/{name}.csv -lv=-LOG_SUCCESS 2>&1")
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
    # OpenModelica writes the values at an event twice (left and right limits): both are kept, in order
    return {h: data[:, i] for i, h in enumerate(head)}
