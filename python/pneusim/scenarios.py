"""Every simulated run: id, model, settings. One definition drives OpenModelica and the Python twin."""
from dataclasses import dataclass, field

from . import circuits


@dataclass
class Scenario:
    id: str
    model: str            # Modelica model in PneumaticCircuits.Experiments
    title: str
    stop: float
    p: dict = field(default_factory=dict)     # settings, in the Modelica parameter names

    def overrides(self):
        """-override list for the OpenModelica executable"""
        ov = {}
        for k, v in self.p.items():
            if isinstance(v, bool):
                ov[k] = "true" if v else "false"
            elif isinstance(v, (list, tuple)):
                for i, e in enumerate(v):
                    ov[f"{k}[{i + 1}]"] = e
            else:
                ov[k] = v
        return ov

    def twin(self):
        """the same circuit in the Python model"""
        p = self.p
        if self.model.startswith("TwoHandPress"):
            t1 = (p.get("t_on1", [1])[0], p.get("t_off1", [4])[0])
            t2 = (p.get("t_on2", [1])[0], p.get("t_off2", [4])[0])
            return circuits.two_hand_press(opening=p.get("opening", 0.3), p_supply=p.get("p_supply", 6e5),
                                           t1=t1, t2=t2, quick_exhaust=(self.model == "TwoHandPress"))
        if self.model == "Reciprocating":
            return circuits.reciprocating(openingA=p.get("openingA", 0.3), openingB=p.get("openingB", 0.3),
                                          meter_in=p.get("meterIn", False), t_start=p.get("t_start", 1),
                                          t_stop=p.get("t_stop", 6), m_load=p.get("m_load", 0.15),
                                          alpha=p.get("alpha", 0), F_load=p.get("F_load", 0),
                                          p_supply=p.get("p_supply", 6e5))
        if self.model == "PressureStamp":
            return circuits.pressure_stamp(p_set=p.get("p_set", 4e5), openingA=p.get("openingA", 0.1),
                                           meter_in=p.get("meterIn", True), t_press=p.get("t_press", 1),
                                           t_release=p.get("t_release", 1.05), x_work=p.get("x_work", 0.08),
                                           k_work=p.get("k_work", 2e5), p_supply=p.get("p_supply", 6e5),
                                           x_gate=p.get("x_gate", 0.075))
        raise KeyError(self.model)


NEVER = ([100.0], [101.0])        # a hand that never presses within the run


def press(id, title, stop=6, model="TwoHandPress", **p):
    p.setdefault("t_on1", [1.0]); p.setdefault("t_off1", [3.0])
    p.setdefault("t_on2", [1.0]); p.setdefault("t_off2", [3.0])
    return Scenario(id, model, title, stop, p)

def all_scenarios(mid_stroke_release=1.045):
    S = []
    # ---- E1: two-hand press
    S.append(press("E1-01", "both buttons, throttle 30 %", opening=0.3))
    S.append(press("E1-02", "only 1S1", opening=0.3, t_on2=NEVER[0], t_off2=NEVER[1]))
    S.append(press("E1-03", "only 1S2", opening=0.3, t_on1=NEVER[0], t_off1=NEVER[1]))
    S.append(press("E1-04", "1S2 released mid-stroke", opening=0.3, t_off2=[mid_stroke_release]))
    S.append(press("E1-05", "1S2 pressed 1.5 s after 1S1", opening=0.3, t_on2=[2.5], t_off2=[4.0], stop=7))
    for op in (1.0, 0.7, 0.5, 0.3, 0.2, 0.1, 0.05, 0.025):
        S.append(press(f"E1-T{int(round(op * 1000)):04d}", f"throttle {op * 100:g} %", opening=op,
                       stop=3 + (12 if op < 0.04 else 6 if op < 0.15 else 3)))
    for op in (1.0, 0.3, 0.1):
        S.append(press(f"E1-N{int(round(op * 1000)):04d}", f"no quick exhaust, throttle {op * 100:g} %",
                       model="TwoHandPressNoQuickExhaust", opening=op, stop=(9 if op < 0.15 else 6)))
    for ps in (3e5, 4e5, 5e5, 6e5):
        S.append(press(f"E1-P{int(ps / 1e5)}", f"supply {ps / 1e5:g} bar, throttle 30 %", opening=0.3, p_supply=ps))
    # ---- E2: reciprocating
    S.append(Scenario("E2-01", "Reciprocating", "meter-out 30 % / 30 %, start 1 s to 6 s", 9, {}))
    for op in (1.0, 0.5, 0.3, 0.2, 0.1):
        S.append(Scenario(f"E2-T{int(round(op * 1000)):04d}", "Reciprocating", f"meter-out, both {op * 100:g} %",
                          (14 if op <= 0.1 else 9), {"openingA": op, "openingB": op, "t_stop": (10.4 if op <= 0.1 else 6)}))
    S.append(Scenario("E2-MI", "Reciprocating", "meter-in 20 %, horizontal", 9, {"openingA": 0.2, "openingB": 0.2, "meterIn": True}))
    S.append(Scenario("E2-MO", "Reciprocating", "meter-out 20 %, horizontal", 9, {"openingA": 0.2, "openingB": 0.2}))
    S.append(Scenario("E2-MI-V", "Reciprocating", "meter-in 20 %, 3 kg, extends downward", 9,
                      {"openingA": 0.2, "openingB": 0.2, "meterIn": True, "m_load": 3.0, "alpha": 90.0}))
    S.append(Scenario("E2-MO-V", "Reciprocating", "meter-out 20 %, 3 kg, extends downward", 9,
                      {"openingA": 0.2, "openingB": 0.2, "m_load": 3.0, "alpha": 90.0}))
    S.append(Scenario("E2-MI-F", "Reciprocating", "meter-in 20 %, 60 N against extension", 9,
                      {"openingA": 0.2, "openingB": 0.2, "meterIn": True, "F_load": 60.0}))
    S.append(Scenario("E2-MO-F", "Reciprocating", "meter-out 20 %, 60 N against extension", 9,
                      {"openingA": 0.2, "openingB": 0.2, "F_load": 60.0}))
    # ---- E3: pressure-dependent stamping (default: meter-in 10 %, gate at 75 mm, start tapped for 50 ms)
    S.append(Scenario("E3-01", "PressureStamp", "sequence valve at 4 bar, meter-in 10 %, gated at 75 mm", 4, {}))
    for ps in (1, 2, 3, 4, 5):
        S.append(Scenario(f"E3-P{ps}", "PressureStamp", f"sequence valve at {ps} bar", 4, {"p_set": ps * 1e5}))
        S.append(Scenario(f"E3-F{ps}", "PressureStamp", f"sequence valve at {ps} bar, fast approach (meter-in 30 %)", 3,
                          {"p_set": ps * 1e5, "openingA": 0.3}))
    S.append(Scenario("E3-NOGATE2", "PressureStamp", "no position gate, 2 bar", 4, {"x_gate": -1.0, "p_set": 2e5}))
    S.append(Scenario("E3-NOGATE4", "PressureStamp", "no position gate, 4 bar", 4, {"x_gate": -1.0}))
    S.append(Scenario("E3-MO", "PressureStamp", "meter-out 10 % instead, 4 bar", 4, {"meterIn": False}))
    S.append(Scenario("E3-HOLD", "PressureStamp", "start button held 1 s to 2.5 s", 4, {"t_release": 2.5}))
    S.append(Scenario("E3-NOWP", "PressureStamp", "no workpiece, 4 bar", 4, {"x_work": 1.0}))
    return S
