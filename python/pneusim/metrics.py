"""Quantities measured on a run: stroke times, speeds, gauge readings, cycles, forces."""
import numpy as np

P_ATM = 101325.0
L = 0.100


def first(t, cond, after=-np.inf):
    k = np.where(cond & (t >= after))[0]
    return float(t[k[0]]) if len(k) else float("nan")


def mean(a):
    a = np.asarray(a)
    return float(a.mean()) if a.size else float("nan")


def bar(p):
    return (np.asarray(p) - P_ATM) / 1e5


def stroke(R, t_cmd, t_rel):
    """two-hand press: command (later press) at t_cmd, first release at t_rel"""
    t, x, v = R["time"], R["cyl.x"], R["cyl.v"]
    out = {}
    t_move = first(t, x > 0.0005, t_cmd)
    t_out = first(t, x >= 0.99 * L, t_cmd)
    out["delay_to_motion_s"] = t_move - t_cmd
    out["extend_time_s"] = t_out - t_cmd
    out["extend_motion_s"] = t_out - t_move
    ext = (t >= t_cmd) & (t <= (t_out if np.isfinite(t_out) else t_rel))
    out["extend_peak_speed_m_s"] = float(v[ext].max()) if ext.any() else float("nan")
    out["x_max_mm"] = float(x[(t >= t_cmd)].max() * 1000)
    if np.isfinite(t_rel):
        t_back = first(t, x <= 0.01 * L, t_rel)
        t_leave = first(t, x < 0.99 * L, t_rel)
        out["return_time_s"] = t_back - t_rel
        out["return_delay_s"] = t_leave - t_rel
        mid = (t >= t_rel) & (x > 0.2 * L) & (x < 0.8 * L) & (v < 0)
        out["return_speed_m_s"] = float(-v[mid].mean()) if mid.any() else float("nan")
        out["cap_bar_returning"] = float(bar(R["cyl.pA"][mid]).mean()) if mid.any() else float("nan")
        out["rod_bar_returning"] = float(bar(R["cyl.pB"][mid]).mean()) if mid.any() else float("nan")
    hold = (t > t_rel - 0.05) & (t < t_rel - 0.01)
    out["gauge1_bar_extended"] = mean(R["g1.p_bar"][hold])
    out["gauge2_bar_extended"] = mean(R["g2.p_bar"][hold])
    rest = (t > t_cmd - 0.1) & (t < t_cmd - 0.01)
    out["gauge1_bar_rest"] = mean(R["g1.p_bar"][rest])
    out["gauge2_bar_rest"] = mean(R["g2.p_bar"][rest])
    exm = (t >= t_cmd) & (x > 0.2 * L) & (x < 0.8 * L) & (v > 0)
    out["cap_bar_extending"] = float(bar(R["cyl.pA"][exm]).mean()) if exm.any() else float("nan")
    out["rod_bar_extending"] = float(bar(R["cyl.pB"][exm]).mean()) if exm.any() else float("nan")
    out["pilot_switch_delay_s"] = first(t, R["v2.on"] > 0.5, t_cmd) - t_cmd
    return out


def cycles(R):
    """reciprocating: one cycle = leaving the retracted end until returning to it"""
    t, x, v = R["time"], R["cyl.x"], R["cyl.v"]
    up = np.where((x[1:] > 0.005) & (x[:-1] <= 0.005))[0] + 1           # leaves the retracted end
    out_t = np.where((x[1:] >= 0.095) & (x[:-1] < 0.095))[0] + 1         # reaches the extended end
    starts = t[up]
    res = {"cycles": int(len(starts))}
    if len(starts) >= 2:
        res["period_s"] = float(np.mean(np.diff(starts)))
    ext_t, ret_t, ext_v, ret_v, ext_sd, ret_sd = [], [], [], [], [], []
    for s in starts:
        e = t[out_t[t[out_t] > s]][:1]
        if not len(e):
            continue
        e = e[0]
        back = first(t, x <= 0.005, e)
        ext_t.append(e - s)
        if np.isfinite(back):
            ret_t.append(back - e)
        m = (t >= s) & (t <= e) & (x > 0.2 * L) & (x < 0.8 * L)
        ext_v.append(v[m].mean())
        ext_sd.append(v[m].std())
        m = (t >= e) & (t <= back) & (x > 0.2 * L) & (x < 0.8 * L)
        if m.any():
            ret_v.append(-v[m].mean())
            ret_sd.append(v[m].std())
    f = lambda a: float(np.mean(a)) if len(a) else float("nan")
    res.update(extend_time_s=f(ext_t), return_time_s=f(ret_t), extend_speed_m_s=f(ext_v),
               return_speed_m_s=f(ret_v), extend_speed_sd_m_s=f(ext_sd), return_speed_sd_m_s=f(ret_sd),
               rests_retracted=bool(abs(x[-1]) < 0.001))
    return res


def stamp(R, k_work, x_work, A1):
    """pressure stamp: when 1V1 is commanded back (its spool passes half way), where, and with what force"""
    t, x = R["time"], R["cyl.x"]
    out = {}
    out["contact_at_s"] = first(t, x >= x_work, 0)
    sp = R["v1.xv"]
    i1 = np.argmax(sp > 0.5)
    t_back = first(t, sp < 0.5, t[i1]) if sp[i1] > 0.5 else float("nan")
    out["return_command_at_s"] = t_back
    Fw = np.maximum(0, k_work * (x - x_work))
    ok = np.isfinite(t_back)
    out["x_at_return_mm"] = float(np.interp(t_back, t, x) * 1000) if ok else float("nan")
    out["force_at_return_N"] = float(np.interp(t_back, t, Fw)) if ok else float("nan")
    out["cap_bar_at_return"] = float(bar(np.interp(t_back, t, R["cyl.pA"]))) if ok else float("nan")
    out["peak_force_N"] = float(Fw.max())
    out["press_time_s"] = float(np.sum(Fw[1:] > 1) * np.median(np.diff(t))) if (Fw > 1).any() else 0.0
    out["x_max_mm"] = float(x.max() * 1000)
    out["back_at_s"] = first(t, x <= 0.001, t_back) if ok else float("nan")
    return out
