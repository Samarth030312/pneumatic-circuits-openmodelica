#!/usr/bin/env python3
"""Run every lesson and every "Try this" variant from the lessons' documentation; record the data
and check each documented claim.

    python3 scripts/run_lessons.py

Writes results/data/lessons/<run>.csv (5 ms), results/tables/lessons.csv (one row per run, with
the motion events) and results/tables/lesson_claims.csv (each claim, the measured values, PASS/FAIL),
and docs/img/lessons_overview.png.
"""
import csv
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "python"))
sys.path.insert(0, str(ROOT / "scripts"))
from pneusim import om  # noqa: E402
from run_experiments import thin, write_csv  # noqa: E402

DATA = ROOT / "results" / "data" / "lessons"
TAB = ROOT / "results" / "tables"

RUNS = [  # id, lesson, overrides
    ("L01", "L01_DirectSingleActing", {}),
    ("L01-1bar", "L01_DirectSingleActing", {"sup.p_gauge": 1e5}),
    ("L01-stiff", "L01_DirectSingleActing", {"cyl.k_spring": 3000}),
    ("L01-short", "L01_DirectSingleActing", {"hand.t_off[1]": 1.015}),
    ("L02", "L02_DirectDoubleActing", {}),
    ("L02-heavy", "L02_DirectDoubleActing", {"cyl.m": 5}),
    ("L02-small", "L02_DirectDoubleActing", {"v1.qn": 30}),
    ("L03", "L03_IndirectControl", {}),
    ("L03-10m", "L03_IndirectControl", {"tP.L": 10}),
    ("L03-stiff", "L03_IndirectControl", {"v1.p_on": 4e5, "sup.p_gauge": 3e5}),
    ("L04", "L04_OrTwoPlaces", {}),
    ("L04-overlap", "L04_OrTwoPlaces", {"hand2.t_on[1]": 1.5}),
    ("L05", "L05_AndTwoHands", {}),
    ("L05-apart", "L05_AndTwoHands", {"hand2.t_on[1]": 3.5}),
    ("L06", "L06_SpeedControl", {}),
    ("L06-5pc", "L06_SpeedControl", {"openingA": 0.05}),
    ("L06-in", "L06_SpeedControl", {"meterIn": "true"}),
    ("L06-in-60N", "L06_SpeedControl", {"meterIn": "true", "cyl.F_load": 60}),
    ("L06-out-60N", "L06_SpeedControl", {"cyl.F_load": 60}),
    ("L07", "L07_QuickExhaust", {}),
    ("L08", "L08_MemoryValve", {}),
    ("L08-longer", "L08_MemoryValve", {"handReturn.t_off[2]": 7.5}),
]


def events(R):
    """out_start, out_end, back_start, home for each stroke; times in s"""
    t, x = R["time"], R["cyl.x"]
    L = max(x.max(), 1e-9)
    ev, state = [], "home"
    cur = {}
    for i in range(1, len(t)):
        if state == "home" and x[i] > 0.0005 and x[i] > x[i - 1]:
            cur = {"out_start": t[i]}; state = "out"
        elif state == "out" and x[i] >= 0.99 * L:
            cur["out_end"] = t[i]; state = "held"
        elif state == "held" and x[i] < 0.98 * L:
            cur["back_start"] = t[i]; state = "in"
        elif state == "in" and x[i] < 0.0005:
            cur["home"] = t[i]; ev.append(cur); cur = {}; state = "home"
    if cur:
        ev.append(cur)
    return ev


def mid_speed(R, a, b):
    t, x = R["time"], R["cyl.x"]
    k = (t >= a) & (t <= b) & (x > 0.02 * 5) & (x < 0.08 * 1.0)
    if k.sum() < 3:
        return float("nan")
    return float(abs(np.polyfit(t[k], x[k], 1)[0]))


def main():
    DATA.mkdir(parents=True, exist_ok=True)
    om.PKG = "PneumaticCircuits.Learn.Lessons."
    built, R, rows = set(), {}, []
    for rid, lesson, ov in RUNS:
        if lesson not in built:
            om.build(lesson)
            built.add(lesson)
        r = om.run(lesson, ov, f"lesson_{rid}")
        R[rid] = r
        write_csv(DATA / f"{rid}.csv", thin(r))
        ev = events(r)
        e = ev[0] if ev else {}
        row = {"run": rid, "lesson": lesson, "settings": " ".join(f"{k}={v}" for k, v in ov.items()) or "defaults",
               "x_max_mm": round(float(r["cyl.x"].max()) * 1000, 2), "strokes": len(ev),
               "x_end_mm": round(float(r["cyl.x"][-1]) * 1000, 2)}
        for k in ("out_start", "out_end", "back_start", "home"):
            row[k + "_s"] = round(e[k], 4) if k in e else ""
        row["extend_s"] = round(e["out_end"] - e["out_start"], 4) if "out_end" in e else ""
        row["return_s"] = round(e["home"] - e["back_start"], 4) if "home" in e else ""
        rows.append(row)
        print(rid, row, flush=True)
    with open(TAB / "lessons.csv", "w", newline="") as f:
        w = csv.DictWriter(f, list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    claims(R, {r["run"]: r for r in rows})
    overview(R)


def claims(R, T):
    f = lambda k, c: T[k][c]
    C = []

    def claim(lesson, text, ok, measured):
        C.append({"lesson": lesson, "claim": text, "measured": measured, "result": "PASS" if ok else "FAIL"})

    claim("L01", "the spring return is slower than the extension", f("L01", "return_s") > f("L01", "extend_s"),
          f"extend {f('L01','extend_s')} s, return {f('L01','return_s')} s")
    claim("L01", "at 1 bar it still reaches the end, much more slowly: 1 bar x A = 31.4 N, just above spring 25 N + friction 6 N",
          f("L01-1bar", "x_max_mm") > 49.5 and f("L01-1bar", "extend_s") > 3 * f("L01", "extend_s"),
          f"x max {f('L01-1bar','x_max_mm')} mm, extend {f('L01-1bar','extend_s')} s vs {f('L01','extend_s')} s")
    claim("L01", "a stiffer spring returns faster", f("L01-stiff", "return_s") < f("L01", "return_s"),
          f"return {f('L01-stiff','return_s')} s vs {f('L01','return_s')} s")
    claim("L01", "released after 15 ms the piston stops part-way and comes back", f("L01-short", "x_max_mm") < 49,
          f"x max {f('L01-short','x_max_mm')} mm")
    claim("L02", "a 5 kg tool overshoots into the end stop (rebounds)",
          float(np.max(R["L02-heavy"]["cyl.x"])) > 0.1 + 1e-5, f"x max {f('L02-heavy','x_max_mm')} mm")
    claim("L02", "a small valve (30 l/min) slows both strokes",
          f("L02-small", "extend_s") > f("L02", "extend_s") and f("L02-small", "return_s") > f("L02", "return_s"),
          f"extend {f('L02-small','extend_s')} vs {f('L02','extend_s')} s, return {f('L02-small','return_s')} vs {f('L02','return_s')} s")
    claim("L03", "indirect control starts later than direct control (pilot filling)",
          f("L03", "out_start_s") > f("L02", "out_start_s"), f"{f('L03','out_start_s')} s vs {f('L02','out_start_s')} s")
    claim("L03", "a 10 m pilot line starts the cylinder later", f("L03-10m", "out_start_s") > f("L03", "out_start_s"),
          f"{f('L03-10m','out_start_s')} s vs {f('L03','out_start_s')} s")
    claim("L03", "pilot needing 4 bar on a 3 bar supply: nothing moves", f("L03-stiff", "x_max_mm") < 0.5,
          f"x max {f('L03-stiff','x_max_mm')} mm")
    claim("L04", "either station extends the cylinder (two strokes)", f("L04", "strokes") == 2, f"{f('L04','strokes')} strokes")
    claim("L04", "overlapping presses give one longer stroke, nothing new", f("L04-overlap", "strokes") <= 2,
          f"{f('L04-overlap','strokes')} strokes")
    claim("L05", "the cylinder starts only when the second hand arrives (1.5 s)",
          1.5 < f("L05", "out_start_s") < 1.6, f"starts {f('L05','out_start_s')} s")
    claim("L05", "hands that never overlap: no motion", f("L05-apart", "x_max_mm") < 0.5, f"x max {f('L05-apart','x_max_mm')} mm")
    r6, r5 = f("L06", "return_s"), f("L06-5pc", "return_s")
    claim("L06", "a quarter of the opening (20 % to 5 %): the return takes about four times longer", 3.2 < r5 / r6 < 4.4,
          f"return {r5} s vs {r6} s, ratio {r5 / r6:.2f}")
    claim("L06", "meter-in is faster at the same settings", f("L06-in", "extend_s") < f("L06", "extend_s"),
          f"extend {f('L06-in','extend_s')} s vs {f('L06','extend_s')} s")
    din = f("L06-in-60N", "extend_s") / f("L06-in", "extend_s")
    dout = f("L06-out-60N", "extend_s") / f("L06", "extend_s")
    claim("L06", "a 60 N load slows meter-in far more than meter-out", din > dout,
          f"extend time x{din:.2f} (meter-in) vs x{dout:.2f} (meter-out)")
    claim("L07", "the quick-exhaust valve shortens the extension (vs L03)", f("L07", "extend_s") < f("L03", "extend_s"),
          f"{f('L07','extend_s')} s vs {f('L03','extend_s')} s")
    claim("L08", "a tap on start keeps it extended after the release; a tap on return brings it back",
          f("L08", "out_end_s") != "" and 3.0 < f("L08", "back_start_s") < 3.3, f"back at {f('L08','back_start_s')} s")
    claim("L08", "overlapping signals: still extended at the end", f("L08", "x_end_mm") > 99, f"x end {f('L08','x_end_mm')} mm")
    claim("L08", "return held until 7.5 s: it returns when start is released at 7 s",
          float(np.interp(7.4, R["L08-longer"]["time"], R["L08-longer"]["cyl.x"])) < 0.099,
          f"x at 7.4 s {np.interp(7.4, R['L08-longer']['time'], R['L08-longer']['cyl.x']) * 1000:.1f} mm")
    with open(TAB / "lesson_claims.csv", "w", newline="") as fh:
        w = csv.DictWriter(fh, list(C[0]))
        w.writeheader()
        w.writerows(C)
    for c in C:
        print(f"{c['result']}  {c['lesson']}  {c['claim']}  [{c['measured']}]")


def overview(R):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    ids = ["L01", "L02", "L03", "L04", "L05", "L06", "L07", "L08"]
    fig, ax = plt.subplots(4, 2, figsize=(11, 10), sharex=False)
    for a, rid in zip(ax.flat, ids):
        r = R[rid]
        a.plot(r["time"], r["cyl.x"] * 1000, "k", lw=1.2)
        a.set_ylabel("piston (mm)")
        b = a.twinx()
        for k, c in (("g1.p_bar", "#1f5fa8"), ("g2.p_bar", "#c0392b")):
            if k in r:
                b.plot(r["time"], r[k], color=c, lw=0.8)
        b.set_ylabel("gauges (bar)", fontsize=8)
        a.set_title(rid + "  " + [l for i, l, _ in RUNS if i == rid][0].split("_", 1)[1], fontsize=9, loc="left")
        a.grid(alpha=0.3)
    for a in ax[-1]:
        a.set_xlabel("t (s)")
    fig.tight_layout()
    fig.savefig(ROOT / "docs" / "img" / "lessons_overview.png", dpi=120, facecolor="white")


if __name__ == "__main__":
    main()
