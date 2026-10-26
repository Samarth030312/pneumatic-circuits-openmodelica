#!/usr/bin/env python3
"""Figures from results/data and results/tables -> docs/img/*.png, and the circuit diagrams."""
import csv
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "python"))
from pneusim import diagram, model, scenarios  # noqa: E402

DATA, TAB, IMG = ROOT / "results" / "data", ROOT / "results" / "tables", ROOT / "docs" / "img"
P_ATM = 101325.0
A1 = np.pi * 0.02 ** 2 / 4
A2 = np.pi * (0.02 ** 2 - 0.008 ** 2) / 4
C_RHO = model.RHO0 * model.R_AIR * model.T0          # rho0 R T0 (Pa)
plt.rcParams.update({"font.size": 9, "axes.grid": True, "grid.alpha": 0.3, "figure.dpi": 130,
                     "axes.spines.top": False, "axes.spines.right": False})
BLUE, RED, GREEN, GREY, ORANGE = "#1f5fa8", "#c0392b", "#1e8449", "#7f8c8d", "#d68910"


def load(id):
    with open(DATA / f"{id}.csv") as f:
        r = list(csv.reader(f))
    a = np.array(r[1:], dtype=float)
    return {k: a[:, i] for i, k in enumerate(r[0])}


def table(name):
    with open(TAB / f"{name}.csv") as f:
        return list(csv.DictReader(f))


def num(r, k):
    try:
        return float(r[k])
    except (KeyError, ValueError, TypeError):
        return float("nan")


def save(fig, name):
    fig.savefig(IMG / f"{name}.png", bbox_inches="tight", facecolor="white")
    plt.close(fig)


def bar(p):
    return (np.asarray(p) - P_ATM) / 1e5


# ------------------------------------------------------------------ E1
def e1_nominal():
    R = load("E1-01")
    t = R["time"]
    fig, ax = plt.subplots(4, 1, figsize=(7.5, 7), sharex=True, gridspec_kw={"height_ratios": [1, 1.2, 1.6, 1.6]})
    ax[0].step(t, R["s1.xv"] + 1.2, color=BLUE, where="post", label="1S1")
    ax[0].step(t, R["s2.xv"], color=GREEN, where="post", label="1S2")
    ax[0].set_yticks([0, 1, 1.2, 2.2]); ax[0].set_yticklabels(["", "1S2", "", "1S1"]); ax[0].set_ylabel("buttons")
    ax[1].plot(t, bar(R["v2.p_pilot"]), color=ORANGE, label="1V2 pilot 14 (bar)")
    ax[1].step(t, R["v2.on"] * 6, color=GREY, ls="--", where="post", label="1V2 switched (x6)")
    ax[1].axhline(1.5, color=ORANGE, lw=0.6, ls=":"); ax[1].axhline(1.0, color=ORANGE, lw=0.6, ls=":")
    ax[1].set_ylabel("bar"); ax[1].legend(loc="center right", fontsize=7.5)
    ax[2].plot(t, R["cyl.x"] * 1000, color="k")
    ax[2].set_ylabel("1A position (mm)")
    ax[3].plot(t, R["g1.p_bar"], color=BLUE, label="1Z1 cap side")
    ax[3].plot(t, R["g2.p_bar"], color=RED, label="1Z2 rod side")
    ax[3].set_ylabel("gauge (bar)"); ax[3].set_xlabel("t (s)"); ax[3].legend(loc="center right", fontsize=7.5)
    ax[3].set_xlim(0.8, 4.2)
    fig.suptitle("Two-hand press: both buttons held 1 s to 3 s, 1V3 at 30 %", fontsize=10)
    save(fig, "E1_nominal")
    # zoom on the two strokes
    fig, ax = plt.subplots(2, 2, figsize=(8, 4.6), sharey="row")
    for j, (a, b) in enumerate(((0.98, 1.16), (2.98, 3.6))):
        k = (t >= a) & (t <= b)
        ax[0, j].plot((t[k] - a) * 1000, R["cyl.x"][k] * 1000, color="k")
        ax[1, j].plot((t[k] - a) * 1000, R["g1.p_bar"][k], color=BLUE, label="1Z1 cap")
        ax[1, j].plot((t[k] - a) * 1000, R["g2.p_bar"][k], color=RED, label="1Z2 rod")
        ax[1, j].plot((t[k] - a) * 1000, bar(R["cyl.pA"][k]), color=BLUE, ls=":", label="cap chamber")
        ax[1, j].plot((t[k] - a) * 1000, bar(R["cyl.pB"][k]), color=RED, ls=":", label="rod chamber")
        ax[1, j].set_xlabel("ms after " + ("both pressed" if j == 0 else "release"))
    ax[0, 0].set_ylabel("position (mm)"); ax[1, 0].set_ylabel("bar"); ax[1, 1].legend(fontsize=7)
    ax[0, 0].set_title("extension"); ax[0, 1].set_title("return (meter-out 30 %)")
    save(fig, "E1_strokes")


def e1_logic():
    cases = [("E1-01", "both held 1-3 s"), ("E1-02", "only 1S1"), ("E1-03", "only 1S2"),
             ("E1-04", "1S2 released mid-stroke"), ("E1-05", "1S2 pressed 1.5 s after 1S1")]
    fig, ax = plt.subplots(len(cases), 1, figsize=(7.5, 7.5), sharex=True)
    for a, (id, title) in zip(ax, cases):
        R = load(id)
        t = R["time"]
        a.plot(t, R["cyl.x"] * 1000, color="k", label="1A (mm)")
        a.fill_between(t, 0, R["s1.xv"] * 45 + 55, where=R["s1.xv"] > 0.5, step="post", color=BLUE, alpha=0.15, label="1S1 held")
        a.fill_between(t, 0, R["s2.xv"] * 45, where=R["s2.xv"] > 0.5, step="post", color=GREEN, alpha=0.2, label="1S2 held")
        a.set_ylim(-5, 105); a.set_ylabel("mm"); a.set_title(title, fontsize=9, loc="left")
    ax[0].legend(fontsize=7, loc="center right"); ax[-1].set_xlabel("t (s)"); ax[-1].set_xlim(0, 6.5)
    save(fig, "E1_two_hand_logic")


def e1_throttle():
    T = [r for r in table("E1") if r["id"].startswith("E1-T")]
    op = np.array([num(r, "opening") for r in T])
    tr = np.array([num(r, "return_time_s") for r in T])
    vr = np.array([num(r, "return_speed_m_s") for r in T])
    te = np.array([num(r, "extend_time_s") for r in T])
    o = np.argsort(op)
    oo = np.linspace(0.02, 1, 200)
    v_choked = np.array([model.conductance(s * 85, 0.3) for s in oo]) * C_RHO / A1
    fig, ax = plt.subplots(1, 3, figsize=(10.5, 3.4))
    for r in sorted(T, key=lambda r: -num(r, "opening")):
        R = load(r["id"])
        k = R["time"] >= 2.9
        ax[0].plot(R["time"][k] - 3, R["cyl.x"][k] * 1000, lw=1, label=f"{num(r, 'opening') * 100:g} %")
    ax[0].set_xlabel("s after release"); ax[0].set_ylabel("position (mm)"); ax[0].legend(fontsize=7, title="1V3", title_fontsize=7)
    ax[0].set_xlim(-0.1, 8)
    ax[1].loglog(op[o] * 100, vr[o], "o", color=BLUE, label="simulated")
    ax[1].loglog(oo * 100, v_choked, "-", color=GREY, label=r"choked: $v = C\,\rho_0 R T_0/A_1$")
    ax[1].set_xlabel("1V3 setting (% of 85 l/min)"); ax[1].set_ylabel("return speed (m/s)"); ax[1].legend(fontsize=7)
    ax[2].semilogx(op[o] * 100, tr[o], "o-", color=RED, label="return")
    ax[2].semilogx(op[o] * 100, te[o], "s-", color=GREEN, label="extension")
    ax[2].set_xlabel("1V3 setting (%)"); ax[2].set_ylabel("stroke time (s)"); ax[2].legend(fontsize=7)
    fig.tight_layout()
    save(fig, "E1_throttle")


def e1_quick_exhaust():
    fig, ax = plt.subplots(1, 2, figsize=(9, 3.3))
    for id, lab, c in (("E1-T0300", "with 1V4 (quick exhaust)", BLUE), ("E1-N0300", "rod side straight to 1V2", RED)):
        R = load(id)
        k = (R["time"] >= 0.98) & (R["time"] <= 1.3)
        ax[0].plot((R["time"][k] - 1) * 1000, R["cyl.x"][k] * 1000, color=c, label=lab)
        ax[1].plot((R["time"][k] - 1) * 1000, bar(R["cyl.pB"][k]), color=c, label=lab)
        ax[1].plot((R["time"][k] - 1) * 1000, bar(R["cyl.pA"][k]), color=c, ls=":")
    ax[0].set_xlabel("ms after both pressed"); ax[0].set_ylabel("position (mm)"); ax[0].legend(fontsize=7)
    ax[1].set_xlabel("ms after both pressed"); ax[1].set_ylabel("chamber pressure (bar)")
    ax[1].text(0.98, 0.95, "solid: rod side, dotted: cap side", transform=ax[1].transAxes, ha="right", va="top", fontsize=7)
    fig.tight_layout()
    save(fig, "E1_quick_exhaust")


def e1_supply():
    T = [r for r in table("E1") if r["id"].startswith("E1-P")]
    ps = np.array([float(r["id"][-1]) for r in T])
    fig, ax = plt.subplots(1, 2, figsize=(8.5, 3.2))
    ax[0].plot(ps, [num(r, "extend_time_s") for r in T], "s-", color=GREEN, label="extension")
    ax[0].plot(ps, [num(r, "return_time_s") for r in T], "o-", color=RED, label="return (1V3 30 %)")
    ax[0].set_xlabel("supply (bar)"); ax[0].set_ylabel("stroke time (s)"); ax[0].legend(fontsize=7)
    ax[1].plot(ps, [num(r, "gauge1_bar_extended") for r in T], "o-", color=BLUE, label="1Z1 extended, holding")
    ax[1].plot(ps, [num(r, "cap_bar_returning") for r in T], "o--", color=BLUE, label="cap side returning")
    ax[1].plot(ps, [num(r, "rod_bar_returning") for r in T], "s--", color=RED, label="rod side returning")
    ax[1].plot(ps, [num(r, "gauge2_bar_rest") for r in T], "s-", color=RED, label="1Z2 at rest")
    ax[1].set_xlabel("supply (bar)"); ax[1].set_ylabel("gauge (bar)"); ax[1].legend(fontsize=7)
    fig.tight_layout()
    save(fig, "E1_supply")


def e1_step_diagram():
    R = load("E1-01")
    t, x = R["time"], R["cyl.x"]
    fig, ax = plt.subplots(figsize=(6, 2.2))
    k = (t >= 0.9) & (t <= 3.8)
    ax.plot(t[k], x[k] / 0.1, color="k", lw=1.5)
    for tt, lab in ((1.0, "1"), (1.0 + float(table("E1")[0]["extend_time_s"]), "2"), (3.0 + float(table("E1")[0]["return_time_s"]), "3=1")):
        ax.axvline(tt, color=GREY, lw=0.6); ax.text(tt, 1.12, lab, ha="center", fontsize=8)
    ax.set_yticks([0, 1]); ax.set_ylabel("1A"); ax.set_xlabel("t (s)"); ax.set_ylim(-0.1, 1.25)
    ax.set_title("displacement-time diagram, simulated (steps 1, 2, 3 = 1)", fontsize=9)
    save(fig, "E1_displacement_step")


# ------------------------------------------------------------------ E2
def e2():
    R = load("E2-01")
    t = R["time"]
    fig, ax = plt.subplots(3, 1, figsize=(8, 5.5), sharex=True, gridspec_kw={"height_ratios": [1.6, 1, 1.3]})
    ax[0].plot(t, R["cyl.x"] * 1000, color="k"); ax[0].set_ylabel("1A (mm)")
    ax[0].axvspan(1, 6, color=BLUE, alpha=0.06); ax[0].text(1.05, 92, "1S1 set", fontsize=7, color=BLUE)
    ax[1].step(t, R["r0.xv"] + 1.2, color=GREEN, where="post"); ax[1].step(t, R["r1.xv"], color=RED, where="post")
    ax[1].set_yticks([0.5, 1.7]); ax[1].set_yticklabels(["1S3 (out)", "1S2 (in)"])
    ax[2].plot(t, R["gA.p_bar"], color=BLUE, label="1Z1 cap"); ax[2].plot(t, R["gB.p_bar"], color=RED, label="1Z2 rod")
    ax[2].set_ylabel("gauge (bar)"); ax[2].set_xlabel("t (s)"); ax[2].legend(fontsize=7, loc="lower right")
    ax[0].set_xlim(0.5, 8)
    save(fig, "E2_cycles")
    T = [r for r in table("E2") if r["id"].startswith("E2-T")]
    op = np.array([num(r, "openingA") for r in T])
    o = np.argsort(op)
    fig, ax = plt.subplots(1, 2, figsize=(8.5, 3.2))
    ax[0].loglog(op[o] * 100, np.array([num(r, "period_s") for r in T])[o], "o-", color="k", label="cycle period")
    ax[0].loglog(op[o] * 100, np.array([num(r, "extend_time_s") for r in T])[o], "s--", color=GREEN, label="extension")
    ax[0].loglog(op[o] * 100, np.array([num(r, "return_time_s") for r in T])[o], "^--", color=RED, label="return")
    ax[0].set_xlabel("both flow controls (%)"); ax[0].set_ylabel("s"); ax[0].legend(fontsize=7)
    oo = np.linspace(0.08, 1, 100)
    ax[1].loglog(op[o] * 100, np.array([num(r, "extend_speed_m_s") for r in T])[o], "s", color=GREEN, label="extension (rod air out)")
    ax[1].loglog(op[o] * 100, np.array([num(r, "return_speed_m_s") for r in T])[o], "^", color=RED, label="return (cap air out)")
    C = np.array([model.conductance(s * 85, 0.3) for s in oo])
    ax[1].loglog(oo * 100, C * C_RHO / A2, color=GREEN, lw=0.8, label=r"$C\rho_0RT_0/A_2$")
    ax[1].loglog(oo * 100, C * C_RHO / A1, color=RED, lw=0.8, label=r"$C\rho_0RT_0/A_1$")
    ax[1].set_xlabel("both flow controls (%)"); ax[1].set_ylabel("speed, mid-stroke (m/s)"); ax[1].legend(fontsize=6.5)
    fig.tight_layout()
    save(fig, "E2_throttle")
    fig, ax = plt.subplots(3, 2, figsize=(9, 6.5), sharex=True)
    for i, (a, b, title) in enumerate((("E2-MI", "E2-MO", "horizontal, no load"), ("E2-MI-V", "E2-MO-V", "3 kg, extending downward"),
                                       ("E2-MI-F", "E2-MO-F", "60 N against extension"))):
        for id, c, lab in ((a, ORANGE, "meter-in"), (b, BLUE, "meter-out")):
            R = load(id)
            ax[i, 0].plot(R["time"], R["cyl.x"] * 1000, color=c, label=lab)
            ax[i, 1].plot(R["time"], R["cyl.v"], color=c, label=lab)
        ax[i, 0].set_ylabel("mm"); ax[i, 1].set_ylabel("m/s"); ax[i, 0].set_title(title, fontsize=9, loc="left")
    ax[0, 0].legend(fontsize=7); ax[-1, 0].set_xlabel("t (s)"); ax[-1, 1].set_xlabel("t (s)")
    ax[0, 0].set_xlim(0.8, 6)
    fig.tight_layout()
    save(fig, "E2_meter_in_out")


# ------------------------------------------------------------------ E3
def e3():
    R = load("E3-01")
    t = R["time"]
    k = (t >= 0.95) & (t <= 2.2)
    fig, ax = plt.subplots(4, 1, figsize=(7.5, 6.5), sharex=True, gridspec_kw={"height_ratios": [1.4, 1.4, 1, 1.2]})
    ax[0].plot(t[k], R["cyl.x"][k] * 1000, color="k"); ax[0].axhline(80, color=GREY, ls=":", lw=0.8)
    ax[0].axhline(75, color=ORANGE, ls=":", lw=0.8)
    ax[0].text(0.97, 82, "workpiece 80 mm", fontsize=7, color=GREY); ax[0].text(0.97, 68, "gate 75 mm", fontsize=7, color=ORANGE)
    ax[0].set_ylabel("1A (mm)")
    ax[1].plot(t[k], R["gA.p_bar"][k], color=BLUE, label="1Z1 cap line (sensed)")
    ax[1].plot(t[k], R["gB.p_bar"][k], color=RED, label="1Z2 rod")
    ax[1].axhline(4, color=BLUE, ls=":", lw=0.8); ax[1].set_ylabel("bar"); ax[1].legend(fontsize=7, loc="center right")
    ax[2].step(t[k], R["s1.xv"][k] + 2.4, color=GREEN, where="post"); ax[2].step(t[k], R["seq.on"][k] + 1.2, color=BLUE, where="post")
    ax[2].step(t[k], R["v1.xv"][k], color="k", where="post")
    ax[2].set_yticks([0.5, 1.7, 2.9]); ax[2].set_yticklabels(["1V1 switched", "1V2 on", "1S1"])
    Fw = np.maximum(0, 2e5 * (R["cyl.x"] - 0.08))
    ax[3].plot(t[k], Fw[k], color=GREEN); ax[3].set_ylabel("force on\nworkpiece (N)"); ax[3].set_xlabel("t (s)")
    fig.suptitle("Pressure stamp: sequence valve at 4 bar, meter-in 10 %, start tapped for 50 ms", fontsize=10)
    save(fig, "E3_stamp")
    T = {r["id"]: r for r in table("E3")}
    ps = np.arange(1, 6)
    fig, ax = plt.subplots(1, 2, figsize=(9, 3.4))
    pp = np.linspace(0, 5.5, 50)
    ax[0].plot(pp, pp * 1e5 * A1, color=GREY, lw=0.8, label=r"$p_{set} A_1$")
    ax[0].plot(pp, pp * 1e5 * A1 - 8, color=GREY, ls="--", lw=0.8, label=r"$p_{set} A_1 - F_c$")
    ax[0].plot(ps, [num(T[f"E3-P{i}"], "force_at_return_N") for i in ps], "o", color=GREEN, label="slow approach (10 %)")
    ax[0].plot(ps, [num(T[f"E3-F{i}"], "force_at_return_N") for i in ps], "s", color=RED, mfc="none", label="fast approach (30 %)")
    ax[0].set_xlabel("sequence valve setting (bar)"); ax[0].set_ylabel("force when 1V1 reverses (N)"); ax[0].legend(fontsize=7)
    for i in ps:
        R = load(f"E3-P{i}")
        k = (R["time"] >= 1.2) & (R["time"] <= 2.2)
        ax[1].plot(R["time"][k], np.maximum(0, 2e5 * (R["cyl.x"][k] - 0.08)), label=f"{i} bar")
    ax[1].set_xlabel("t (s)"); ax[1].set_ylabel("force on workpiece (N)"); ax[1].legend(fontsize=7); ax[1].set_title("slow approach", fontsize=9)
    fig.tight_layout()
    save(fig, "E3_setting")
    fig, ax = plt.subplots(1, 4, figsize=(13, 3))
    for a, id, title in zip(ax, ("E3-NOGATE2", "E3-MO", "E3-HOLD", "E3-NOWP"),
                            ("no position gate, 2 bar", "meter-out instead, 4 bar", "button held 1 s to 2.5 s", "no workpiece")):
        R = load(id)
        k = (R["time"] >= 0.95) & (R["time"] <= 3.2)
        a.plot(R["time"][k], R["cyl.x"][k] * 1000, color="k")
        a.axhline(80, color=GREY, ls=":", lw=0.8)
        a2 = a.twinx()
        a2.plot(R["time"][k], R["gA.p_bar"][k], color=BLUE, lw=0.8)
        a2.set_ylim(-0.3, 7); a2.set_ylabel("1Z1 (bar)", color=BLUE)
        a.set_title(title, fontsize=9, loc="left"); a.set_xlabel("t (s)"); a.set_ylim(-5, 105)
    ax[0].set_ylabel("1A (mm)")
    fig.tight_layout()
    save(fig, "E3_variants")


def crosscheck():
    sc = [s for s in scenarios.all_scenarios() if s.id == "E1-T0100"][0]
    R = load("E1-T0100")
    tw = sc.twin().simulate(sc.stop, times=R["time"])
    fig, ax = plt.subplots(2, 1, figsize=(7.5, 4.2), sharex=True)
    ax[0].plot(R["time"], R["cyl.x"] * 1000, color=BLUE, lw=2.5, alpha=0.5, label="OpenModelica")
    ax[0].plot(tw["time"], tw["cyl.x"] * 1000, color="k", lw=0.8, ls="--", label="Python twin")
    ax[0].set_ylabel("1A (mm)"); ax[0].legend(fontsize=7)
    ax[1].plot(R["time"], (R["cyl.x"] - tw["cyl.x"]) * 1e6, color=RED, lw=0.8)
    ax[1].set_ylabel("difference (um)"); ax[1].set_xlabel("t (s)")
    ax[0].set_title("E1-T0100 (1V3 at 10 %), the same run in both implementations", fontsize=9)
    save(fig, "crosscheck")


def diagrams():
    for mdl, name in (("TwoHandPress", "circuit_two_hand_press"), ("TwoHandPressNoQuickExhaust", "circuit_two_hand_press_no_qe"),
                      ("Reciprocating", "circuit_reciprocating"), ("PressureStamp", "circuit_pressure_stamp")):
        bad = diagram.check(mdl)
        assert not bad, bad
        diagram.draw(mdl, IMG / name)


if __name__ == "__main__":
    IMG.mkdir(parents=True, exist_ok=True)
    diagrams()
    e1_nominal(); e1_logic(); e1_throttle(); e1_quick_exhaust(); e1_supply(); e1_step_diagram()
    e2(); e3(); crosscheck()
    print("figures ->", IMG)
