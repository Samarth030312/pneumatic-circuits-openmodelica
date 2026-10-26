#!/usr/bin/env python3
"""How much the key results depend on the ESTIMATED parameters (Python twin).

Each estimated quantity is set to a low and a high value, the rest at nominal, and the two-hand
press (throttle 30 %) and the stamp (4 bar, slow approach) are run again.
Writes results/tables/sensitivity.csv.
"""
import csv
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "python"))
from pneusim import circuits, metrics, model  # noqa: E402


def scale_C(names, k):
    def f(c):
        for n in names:
            e = c.el.get(n)
            if e is None:
                continue
            for a in ("C", "Cp", "C12", "C23", "Cf"):
                if hasattr(e, a):
                    setattr(e, a, getattr(e, a) * k)
    return f


def attr(name, a, value=None, k=None):
    def f(c):
        e = c.el[name]
        setattr(e, a, value if value is not None else getattr(e, a) * k)
    return f


def friction(k):
    def f(c):
        Fc, Fs, vs, ve, bv = c.el["cyl"].fr
        c.el["cyl"].fr = (Fc * k, Fs * k, vs, ve, bv * k)
    return f


def poly(n):
    def f(c):
        c.n = n
        c.el["cyl"].n = n
        for e in c.el.values():
            if hasattr(e, "n") and e is not c.el["cyl"]:
                e.n = n
    return f


def volumes(k):
    def f(c):
        c.V = c.V * k
    return f


def b_all(b):
    def f(c):
        for e in c.el.values():
            if hasattr(e, "b"):
                for a in ("C", "Cp", "C12", "C23", "Cf", "Ct", "Cs"):
                    if hasattr(e, a):
                        # keep each part's nominal flow rate: re-derive C for the new b
                        q = getattr(e, a) * 60000 * (6e5 + model.P_ATM) * model.phi((5e5 + model.P_ATM) / (6e5 + model.P_ATM), e.b)
                        setattr(e, a, model.conductance(q, b))
                e.b = b
    return f


def pilots(on, off):
    def f(c):
        for e in c.el.values():
            if hasattr(e, "p_on"):
                e.p_on, e.p_off = on, off
    return f


CASES = [
    ("nominal", None),
    ("5/2 valve flow x0.5", scale_C(["v2", "v1"], 0.5)), ("5/2 valve flow x2", scale_C(["v2", "v1"], 2)),
    ("cylinder port flow x0.5", attr("cyl", "Cp", k=0.5)), ("cylinder port flow x2", attr("cyl", "Cp", k=2)),
    ("signal valves flow x0.5", scale_C(["s1", "s2", "and1", "r1", "seq"], 0.5)),
    ("signal valves flow x2", scale_C(["s1", "s2", "and1", "r1", "seq"], 2)),
    ("quick exhaust flow x0.5", scale_C(["v4"], 0.5)), ("quick exhaust flow x2", scale_C(["v4"], 2)),
    ("friction x0.5", friction(0.5)), ("friction x2", friction(2)),
    ("moving mass x0.5", attr("cyl", "m", k=0.5)), ("moving mass x2", attr("cyl", "m", k=2)),
    ("polytropic n = 1.0", poly(1.0)), ("polytropic n = 1.4", poly(1.4)),
    ("tube volumes x0.5", volumes(0.5)), ("tube volumes x2", volumes(2)),
    ("critical ratio b = 0.2", b_all(0.2)), ("critical ratio b = 0.5", b_all(0.5)),
    ("pilot switching 1.0 / 0.5 bar", pilots(1.0e5, 0.5e5)), ("pilot switching 2.5 / 1.5 bar", pilots(2.5e5, 1.5e5)),
]


def run(case_fn):
    c = circuits.two_hand_press(opening=0.3, t1=(1, 3), t2=(1, 3))
    if case_fn:
        case_fn(c)
    R = c.simulate(6.0, dt_out=0.0005)
    R["g1.p_bar"] = metrics.bar(R["t5"]); R["g2.p_bar"] = metrics.bar(R["t7"])
    R["cyl.v"] = np.gradient(R["cyl.x"], R["time"])
    R["v2.on"] = (R["v2.xv"] > 0.5).astype(float)
    m1 = metrics.stroke(R, 1.0, 3.0)
    s = circuits.pressure_stamp(p_set=4e5)
    if case_fn:
        try:
            case_fn(s)
        except KeyError:
            pass
    S = s.simulate(4.0, dt_out=0.0005)
    m3 = metrics.stamp(S, 2e5, 0.08, np.pi * 0.02 ** 2 / 4)
    return {"extend_time_s": m1["extend_time_s"], "return_time_s": m1["return_time_s"],
            "return_speed_m_s": m1["return_speed_m_s"], "stamp_force_at_return_N": m3["force_at_return_N"]}


def main():
    rows = []
    for name, fn in CASES:
        r = run(fn)
        rows.append({"case": name, **r})
        print(f"{name:32s} " + "  ".join(f"{k} {v:.4g}" for k, v in r.items()), flush=True)
    nom = rows[0]
    for r in rows:
        for k in ("extend_time_s", "return_time_s", "return_speed_m_s", "stamp_force_at_return_N"):
            r[f"{k}_change_pct"] = 100 * (r[k] / nom[k] - 1)
    out = ROOT / "results" / "tables" / "sensitivity.csv"
    out.parent.mkdir(parents=True, exist_ok=True)
    with open(out, "w", newline="") as f:
        w = csv.DictWriter(f, list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    print("->", out)


if __name__ == "__main__":
    main()
