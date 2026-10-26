#!/usr/bin/env python3
"""Try a circuit with your own settings and see it: one OpenModelica run, plotted in a window.

    python3 scripts/play.py TwoHandPress opening=0.1
    python3 scripts/play.py TwoHandPress p_supply=3e5 "t_on2={2.0}" "t_off2={4.0}"
    python3 scripts/play.py Reciprocating openingA=0.1 openingB=0.5 meterIn=true stop=10
    python3 scripts/play.py PressureStamp p_set=2.5e5 x_work=0.06
    python3 scripts/play.py TwoHandPress cyl.m=5 cyl.F_c=30          # any parameter, by its Modelica name
    python3 scripts/play.py --list TwoHandPress                       # the settings a circuit offers

Arrays are written {a,b}: two presses of 1S1, {1,4} and {2,5}, need t_on1={1,4} t_off1={2,5} and the
same number of entries in t_on2/t_off2. stop=<s> sets the run length. --save writes a PNG instead
of opening a window.
"""
import re
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "python"))
from pneusim import om  # noqa: E402

MODELS = ("TwoHandPress", "TwoHandPressNoQuickExhaust", "Reciprocating", "PressureStamp")
P_ATM = 101325.0


def top_parameters(model):
    """the experiment's own parameters with their defaults and descriptions, from the source"""
    src = (ROOT / "modelica" / "PneumaticCircuits" / "Experiments.mo").read_text()
    body = src[re.search(rf"model {model}\b", src).start():]
    body = body[:body.index(f"end {model};")]
    out = re.findall(r'parameter (?:Real|Boolean) (\w+)(?:\[[^\]]*\])?(?:\([^)]*\))? = ([^"]+?)\s*"([^"]*)"', body)
    if "extends TwoHandPressBase" in body:
        out = top_parameters("TwoHandPressBase") + out
    return out


def main(argv):
    save = "--save" in argv
    argv = [a for a in argv if a != "--save"]
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return
    if argv[0] == "--list":
        for k, v, d in top_parameters(argv[1]):
            print(f"  {k:12s} = {v:10s} {d}")
        return
    model = argv[0]
    if model not in MODELS:
        sys.exit(f"model must be one of {', '.join(MODELS)}")
    ov, stop = {}, None
    for a in argv[1:]:
        k, v = a.split("=", 1)
        if k == "stop":
            stop = float(v)
        elif v.startswith("{"):
            for i, e in enumerate(v.strip("{}").split(",")):
                ov[f"{k}[{i + 1}]"] = e.strip()
        else:
            ov[k] = v
    if not (ROOT / "build" / model / f"PneumaticCircuits.Experiments.{model}").exists():
        print(f"building {model} ...")
        om.build(model)
    print("running", model, ov or "(defaults)")
    R = om.run(model, ov, f"play_{model}", stop_time=stop)
    plot(model, R, ov, save)


def plot(model, R, ov, save):
    import matplotlib
    if save:
        matplotlib.use("Agg")
    else:
        try:
            matplotlib.use("TkAgg")          # an interactive window (zoom, pan) even where the default is not
        except Exception:
            pass
    import matplotlib.pyplot as plt
    t = R["time"]
    gauges = [(k, k.split(".")[0]) for k in R if k.endswith(".p_bar")]
    valves = [k for k in R if re.fullmatch(r"\w+\.xv", k)]
    fig, ax = plt.subplots(3, 1, figsize=(10, 7.5), sharex=True, gridspec_kw={"height_ratios": [1.5, 1.3, 1]})
    ax[0].plot(t, R["cyl.x"] * 1000, "k")
    ax[0].set_ylabel("piston (mm)")
    ax0b = ax[0].twinx()
    ax0b.plot(t, R["cyl.v"], color="#d68910", lw=0.8)
    ax0b.set_ylabel("speed (m/s)", color="#d68910")
    names = {"g1": "1Z1 cap", "g2": "1Z2 rod", "gA": "1Z1 cap", "gB": "1Z2 rod"}
    for k, g in gauges:
        ax[1].plot(t, R[k], label=names.get(g, g))
    ax[1].set_ylabel("gauge (bar)")
    ax[1].legend(loc="upper right", fontsize=8)
    for i, k in enumerate(sorted(valves)):
        ax[2].plot(t, R[k] + 1.2 * i, lw=1)
        ax[2].text(t[-1], 1.2 * i + 0.5, " " + k.split(".")[0], va="center", fontsize=8)
    ax[2].set_yticks([])
    ax[2].set_ylabel("valves (0 rest, 1 switched)")
    ax[2].set_xlabel("t (s)")
    for a in ax:
        a.grid(alpha=0.3)
    x = R["cyl.x"]
    F = (R["cyl.pA"] - P_ATM) * np.pi * 0.01 ** 2
    fig.suptitle(f"{model}  {' '.join(f'{k}={v}' for k, v in ov.items())}\n"
                 f"max stroke {x.max() * 1000:.1f} mm,  max speed {np.abs(R['cyl.v']).max():.2f} m/s,  "
                 f"max cap-side force {F.max():.0f} N", fontsize=10)
    fig.tight_layout()
    if save:
        out = ROOT / "build" / f"play_{model}.png"
        fig.savefig(out, dpi=120)
        print("->", out)
    else:
        plt.show()


if __name__ == "__main__":
    main(sys.argv[1:])
