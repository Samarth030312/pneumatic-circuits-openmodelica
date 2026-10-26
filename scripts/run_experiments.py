#!/usr/bin/env python3
"""Run every scenario in OpenModelica and in the Python twin; write data, tables and run info.

    python3 scripts/run_experiments.py            # all scenarios
    python3 scripts/run_experiments.py E1-01 E3   # scenarios whose id starts with these

Writes results/data/<id>.csv (OpenModelica, 5 ms, selected signals), results/tables/*.csv,
results/RUN_INFO.json. Figures: scripts/make_figures.py.
"""
import csv
import json
import platform
import subprocess
import sys
import time
from pathlib import Path

import numpy as np
import scipy

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "python"))
from pneusim import metrics, om, scenarios  # noqa: E402

DATA = ROOT / "results" / "data"
TABLES = ROOT / "results" / "tables"
KEEP = ["time", "cyl.x", "cyl.v", "cyl.pA", "cyl.pB", "cyl.F_p", "cyl.F_f",
        "g1.p_bar", "g2.p_bar", "gA.p_bar", "gB.p_bar", "v1.on", "v2.on", "v1.xv", "v2.xv",
        "v1.p_pilot14", "v1.p_pilot12", "v2.p_pilot", "s1.xv", "s2.xv", "r0.xv", "r1.xv",
        "seq.on", "seq.p_c", "op1.y", "op2.y"]
A1 = np.pi * 0.020 ** 2 / 4


def thin(R, dt=0.005):
    """resample on a uniform grid; event duplicates collapse to the value after the event"""
    t = R["time"]
    grid = np.arange(0, t[-1] + dt / 2, dt)
    _, last = np.unique(t[::-1], return_index=True)
    idx = len(t) - 1 - last
    out = {"time": grid}
    for k in KEEP[1:]:
        if k in R:
            out[k] = np.interp(grid, t[idx], R[k][idx])
    return out


def write_csv(path, R):
    keys = list(R)
    with open(path, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(keys)
        for i in range(len(R["time"])):
            w.writerow([f"{R[k][i]:.6g}" for k in keys])


def measure(sc, R):
    p = sc.p
    if sc.model.startswith("TwoHandPress"):
        t_cmd = max(p["t_on1"][0], p["t_on2"][0])
        t_rel = min(p["t_off1"][0], p["t_off2"][0])
        if t_cmd > sc.stop:                    # one hand never presses: report what the circuit did
            t_cmd, t_rel = min(p["t_on1"][0], p["t_on2"][0]), float("nan")
        return metrics.stroke(R, t_cmd, t_rel)
    if sc.model == "Reciprocating":
        return metrics.cycles(R)
    return metrics.stamp(R, p.get("k_work", 2e5), p.get("x_work", 0.08), A1)


def main(prefixes):
    DATA.mkdir(parents=True, exist_ok=True)
    TABLES.mkdir(parents=True, exist_ok=True)
    t0 = time.time()
    for mdl in ("TwoHandPress", "TwoHandPressNoQuickExhaust", "Reciprocating", "PressureStamp"):
        om.build(mdl)
    # the release time for "mid-stroke": half way through the nominal extension
    nominal = om.run("TwoHandPress", scenarios.all_scenarios()[0].overrides(), "E1-01", stop_time=6)
    t_half = metrics.first(nominal["time"], nominal["cyl.x"] >= 0.05, 1.0)
    S = [s for s in scenarios.all_scenarios(mid_stroke_release=round(t_half, 3))
         if not prefixes or any(s.id.startswith(p) for p in prefixes)]
    rows, checks = [], []
    for sc in S:
        R = om.run(sc.model, sc.overrides(), sc.id, stop_time=sc.stop)
        Rt = thin(R)
        write_csv(DATA / f"{sc.id}.csv", Rt)
        m = measure(sc, R)
        rows.append({"id": sc.id, "model": sc.model, "title": sc.title, **{k: (str(v) if isinstance(v, list) else v) for k, v in sc.p.items()}, **m})
        # the Python twin
        tw = sc.twin().simulate(sc.stop, times=R["time"])       # at OpenModelica's own output times
        dx = np.abs(R["cyl.x"] - tw["cyl.x"]).max() * 1000
        dpa = np.abs(R["cyl.pA"] - tw["cyl.pA"]).max() / 1e5
        dpb = np.abs(R["cyl.pB"] - tw["cyl.pB"]).max() / 1e5
        tw_m = measure(sc, {**tw, **_twin_aliases(sc, tw)})
        key = {"TwoHandPress": "extend_time_s", "TwoHandPressNoQuickExhaust": "extend_time_s",
               "Reciprocating": "period_s", "PressureStamp": "force_at_return_N"}[sc.model]
        key2 = {"TwoHandPress": "return_time_s", "TwoHandPressNoQuickExhaust": "return_time_s",
                "Reciprocating": "extend_speed_m_s", "PressureStamp": "back_at_s"}[sc.model]
        checks.append({"id": sc.id, "max_dx_mm": dx, "max_dpA_bar": dpa, "max_dpB_bar": dpb,
                       "metric": key, "openmodelica": m.get(key), "python": tw_m.get(key),
                       "metric2": key2, "openmodelica2": m.get(key2), "python2": tw_m.get(key2)})
        print(f"{sc.id:9s} {sc.title:45s} dx {dx:.2e} mm  dp {max(dpa, dpb):.1e} bar  "
              f"{key} {m.get(key, float('nan')):.4g} / {tw_m.get(key, float('nan')):.4g}", flush=True)
    for exp in ("E1", "E2", "E3"):
        rs = [r for r in rows if r["id"].startswith(exp)]
        if rs:
            keys = []
            for r in rs:
                keys += [k for k in r if k not in keys]
            with open(TABLES / f"{exp}.csv", "w", newline="") as f:
                w = csv.DictWriter(f, keys)
                w.writeheader()
                w.writerows(rs)
    if checks:
        with open(TABLES / "crosscheck.csv", "w", newline="") as f:
            w = csv.DictWriter(f, list(checks[0]))
            w.writeheader()
            w.writerows(checks)
    git = subprocess.run(["git", "-C", str(ROOT), "rev-parse", "--short", "HEAD"], capture_output=True, text=True).stdout.strip()
    info = {"date_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "openmodelica": om.omc_version(),
            "image": om.IMAGE, "python": platform.python_version(), "numpy": np.__version__, "scipy": scipy.__version__,
            "git": git or None, "scenarios": len(S), "seconds": round(time.time() - t0)}
    (ROOT / "results" / "RUN_INFO.json").write_text(json.dumps(info, indent=2) + "\n")
    print(json.dumps(info))


def _twin_aliases(sc, tw):
    """name the twin's signals as the Modelica result does"""
    a = {}
    el = {"TwoHandPress": ("g1", "t5", "g2", "t7", "v2"), "TwoHandPressNoQuickExhaust": ("g1", "t5", "g2", "t6", "v2")}
    if sc.model in el:
        g1, n1, g2, n2, v = el[sc.model]
        a["g1.p_bar"] = metrics.bar(tw[n1])
        a["g2.p_bar"] = metrics.bar(tw[n2])
        a["v2.on"] = (tw["v2.xv"] > 0.5).astype(float)
    if sc.model == "PressureStamp":
        a["gA.p_bar"] = metrics.bar(tw["tCap"])
        a["seq.on"] = (tw["seq.xv"] > 0.5).astype(float)
    return a


if __name__ == "__main__":
    main(sys.argv[1:])
