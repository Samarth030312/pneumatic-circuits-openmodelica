"""The experiment circuits in the Python cross-check model; nets carry the Modelica tube names."""
from . import model as m

VX = 0.3e-6          # fittings per net, as Sources.Tube.V_extra


def two_hand_press(opening=0.3, p_supply=6e5, t1=(1, 4), t2=(1, 4), quick_exhaust=True):
    """TwoHandPress (quick_exhaust=True) or TwoHandPressNoQuickExhaust; t1, t2: (press, release)"""
    op1, op2 = m.Schedule([t1[0]], [t1[1]]), m.Schedule([t2[0]], [t2[1]])
    tubes = {"tS": (1.0, VX), "t1": (0.5, VX), "t2": (0.5, VX), "t3": (0.3, VX), "t4": (0.5, VX),
             "t5": (0.3, VX), "t6": (0.5 if quick_exhaust else 0.8, VX)}
    if quick_exhaust:
        tubes["t7"] = (0.3, VX)
    rod = "t7" if quick_exhaust else "t6"
    el = {
        "sup": m.Supply("tS", p_gauge=p_supply),
        "s1": m.Valve32("tS", "t1", op1),
        "s2": m.Valve32("tS", "t2", op2),
        "and1": m.LogicValve("t1", "t2", "t3", "AND"),
        "v2": m.Valve52(p1="tS", p2="t6", p4="t4", p14="t3"),
        "v3": m.OneWayFlowControl("t4", "t5", opening=opening),
        "cyl": m.Cylinder("t5", rod),
    }
    if quick_exhaust:
        el["v4"] = m.QuickExhaust("t6", "t7")
    return m.Circuit(tubes, el, schedules=(op1, op2))


def reciprocating(openingA=0.3, openingB=0.3, meter_in=False, t_start=1, t_stop=6, m_load=0.15, alpha=0,
                  F_load=0, p_supply=6e5):
    """Reciprocating: start switch, roller valves at both ends, double-pilot 5/2, two flow controls"""
    op = m.Schedule([t_start], [t_stop])
    tubes = {"tS": (1.5, VX), "t1": (0.5, VX), "t2": (0.5, VX), "tP14": (0.3, VX), "tC": (0.8, VX),
             "tE": (0.5, VX), "tR": (0.5, VX), "tCap": (0.3, VX), "tRod": (0.3, VX)}
    el = {
        "sup": m.Supply("tS", p_gauge=p_supply),
        "s1": m.Valve32("tS", "t1", op),
        "r0": m.RollerValve32("tS", "t2", "cyl", 0.003, whenAbove=False),
        "r1": m.RollerValve32("tS", "tC", "cyl", 0.100 - 0.003, whenAbove=True),
        "and1": m.LogicValve("t1", "t2", "tP14", "AND"),
        "v1": m.Valve52(p1="tS", p2="tR", p4="tE", p14="tP14", p12="tC"),
        "fcA": m.OneWayFlowControl("tE", "tCap", opening=openingA, reversed=meter_in),
        "fcB": m.OneWayFlowControl("tR", "tRod", opening=openingB, reversed=meter_in),
        "cyl": m.Cylinder("tCap", "tRod", m=m_load, alpha=alpha, F_load=F_load),
    }
    return m.Circuit(tubes, el, schedules=(op,))


def pressure_stamp(p_set=4e5, openingA=0.1, meter_in=True, t_press=1, t_release=1.05, x_work=0.08, k_work=2e5,
                   p_supply=6e5, x_gate=0.075):
    """PressureStamp: start button, double-pilot 5/2, meter-in flow control, sequence valve, workpiece"""
    op = m.Schedule([t_press], [t_release])
    tubes = {"tS": (1.0, VX), "tSt": (0.5, VX), "tQ": (0.5, VX), "tE": (0.5, VX), "tCap": (0.3, VX),
             "tRod": (0.8, VX), "tG": (0.3, VX)}
    el = {
        "sup": m.Supply("tS", p_gauge=p_supply),
        "s1": m.Valve32("tS", "tSt", op),
        "r1": m.RollerValve32("tS", "tG", "cyl", x_gate, whenAbove=True),
        "seq": m.SequenceValve("tG", "tQ", "tCap", p_set=p_set),
        "v1": m.Valve52(p1="tS", p2="tRod", p4="tE", p14="tSt", p12="tQ"),
        "fcA": m.OneWayFlowControl("tE", "tCap", opening=openingA, reversed=meter_in),
        "cyl": m.Cylinder("tCap", "tRod", x_work=x_work, k_work=k_work),
    }
    return m.Circuit(tubes, el, schedules=(op,))
