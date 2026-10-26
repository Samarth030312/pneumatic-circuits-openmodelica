"""Tests: the flow law, closed-form results, the diagrams, and OpenModelica against the Python twin.

    python3 -m pytest tests            # the OpenModelica tests run when Docker is available
"""
import math
import re
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np
import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "python"))
from pneusim import circuits, diagram, model, scenarios  # noqa: E402

MODELS = ["TwoHandPress", "TwoHandPressNoQuickExhaust", "Reciprocating", "PressureStamp"]
LESSONS = ["L01_DirectSingleActing", "L02_DirectDoubleActing", "L03_IndirectControl", "L04_OrTwoPlaces",
           "L05_AndTwoHands", "L06_SpeedControl", "L07_QuickExhaust", "L08_MemoryValve"]


def docker_ok():
    if not shutil.which("docker"):
        return False
    return subprocess.run(["docker", "info"], capture_output=True).returncode == 0


needs_om = pytest.mark.skipif(not docker_ok(), reason="Docker (for the OpenModelica container) not available")


# ------------------------------------------------------------------ the flow law
def test_phi_choked_and_closed():
    assert model.phi(0.1, 0.3) == 1.0
    assert model.phi(0.3, 0.3) == 1.0
    assert model.phi(1.0, 0.3) == 0.0
    r = np.linspace(0.3, 0.999, 200)
    y = [model.phi(v, 0.3) for v in r]
    assert all(np.diff(y) < 0)                                       # falls monotonically
    assert abs(model.phi(0.9995, 0.3) - 0.5 * model.phi(0.999, 0.3)) < 1e-12   # linear laminar end


def test_conductance_from_nominal_flow():
    # qn = 100 l/min at 6 -> 5 bar (gauge), b = 0.3: C = 3.93e-9 m3/(s Pa)
    C = model.conductance(100, 0.3)
    assert C == pytest.approx(3.93e-9, rel=2e-3)
    # and it reproduces its own definition
    q = model.mflow(C, 0.3, 6e5 + model.P_ATM, 5e5 + model.P_ATM) / model.RHO0 * 60000
    assert q == pytest.approx(100, rel=1e-12)


def test_mass_flow_antisymmetric():
    C = model.conductance(80, 0.3)
    assert model.mflow(C, 0.3, 3e5, 7e5) == -model.mflow(C, 0.3, 7e5, 3e5)


# ------------------------------------------------------------------ closed form vs the model
def test_meter_out_speed_is_choked_flow_over_area():
    """v = C rho0 R T0 / A1 while the exhaust throttle is choked"""
    for opening in (0.1, 0.3):
        c = circuits.two_hand_press(opening=opening, t1=(1, 3), t2=(1, 3))
        R = c.simulate(6.0, dt_out=0.001)
        x, v = R["cyl.x"], np.gradient(R["cyl.x"], R["time"])
        mid = (R["time"] > 3) & (x > 0.03) & (x < 0.07)
        A1 = math.pi * 0.02 ** 2 / 4
        v_pred = model.conductance(opening * 85, 0.3) * model.RHO0 * model.R_AIR * model.T0 / A1
        assert -v[mid].mean() == pytest.approx(v_pred, rel=0.02)


def test_holding_forces_match_datasheet():
    A1 = math.pi * 0.02 ** 2 / 4
    A2 = math.pi * (0.02 ** 2 - 0.008 ** 2) / 4
    assert 6e5 * A1 == pytest.approx(189, abs=0.6)      # Festo Didactic 152888: 189 N
    assert 6e5 * A2 == pytest.approx(158, abs=0.6)      # 158 N


def test_one_button_does_not_move_the_press():
    c = circuits.two_hand_press(t1=(1, 3), t2=(100, 101))
    R = c.simulate(4.0)
    assert R["cyl.x"].max() < 1e-4


# ------------------------------------------------------------------ the diagrams
@pytest.mark.parametrize("mdl", MODELS + LESSONS)
def test_diagram_lines_end_on_ports(mdl):
    assert diagram.check(mdl) == []


# ------------------------------------------------------------------ OpenModelica
@needs_om
def test_models_check_in_openmodelica():
    mos = ROOT / "build" / "check_all.mos"
    mos.parent.mkdir(exist_ok=True)
    names = [f"Experiments.{m}" for m in MODELS] + [f"Learn.Lessons.{m}" for m in LESSONS] + ["Learn.Sandbox"]
    mos.write_text('loadFile("modelica/PneumaticCircuits/package.mo"); getErrorString();\n' +
                   "".join(f"checkModel(PneumaticCircuits.{m}); getErrorString();\n" for m in names))
    out = subprocess.run([str(ROOT / "scripts" / "om.sh"), "build/check_all.mos"], capture_output=True, text=True).stdout
    assert out.count("completed successfully") == len(names), out
    assert "Error" not in out, out


@needs_om
def test_python_parameters_match_modelica():
    """the twin's parameters are the Modelica model's (read from the compiled model's init file)"""
    from pneusim import om
    om.build("PressureStamp")
    xml = next((ROOT / "build" / "PressureStamp").glob("*_init.xml")).read_text()

    def par(name):
        m = re.search(r'name = "' + re.escape(name) + r'"(?:(?!</ScalarVariable>).)*?start="([^"]+)"', xml, re.S)
        assert m, name
        return float(m.group(1))

    c = circuits.pressure_stamp()
    cyl = c.el["cyl"]
    D, d = par("cyl.D"), par("cyl.d")
    assert math.pi * D ** 2 / 4 == pytest.approx(cyl.A1)
    assert math.pi * (D ** 2 - d ** 2) / 4 == pytest.approx(cyl.A2)
    assert par("cyl.L") == pytest.approx(cyl.L)
    assert par("cyl.m") == pytest.approx(cyl.m)
    assert (par("cyl.F_c"), par("cyl.F_s"), par("cyl.v_s"), par("cyl.v_eps"), par("cyl.b_v")) == pytest.approx(cyl.fr)
    assert (par("cyl.V0A"), par("cyl.V0B")) == pytest.approx((cyl.V0A, cyl.V0B))
    assert par("cyl.k_stop") == pytest.approx(cyl.k_stop)
    assert model.conductance(par("cyl.qn_port"), par("cyl.b")) == pytest.approx(cyl.Cp, rel=1e-12)
    assert model.conductance(par("v1.qn"), par("v1.b")) == pytest.approx(c.el["v1"].C, rel=1e-12)
    assert (par("v1.p_on"), par("v1.p_off"), par("v1.tau")) == pytest.approx((c.el["v1"].p_on, c.el["v1"].p_off, c.el["v1"].tau))
    s_ = par("openingA")
    assert model.conductance(s_ * par("fcA.qn_throttle_max"), par("fcA.b")) == pytest.approx(c.el["fcA"].Ct, rel=1e-12)
    assert par("p_set") == pytest.approx(c.el["seq"].p_set)
    assert par("x_gate") == pytest.approx(c.el["r1"].x_trip)
    for net in ("tS", "tCap", "tRod", "tE", "tG"):
        V = math.pi * par(f"{net}.D") ** 2 / 4 * par(f"{net}.L") + par(f"{net}.V_extra")
        assert V == pytest.approx(c.V[c.idx[net]], rel=1e-12)
    assert par("tCap.n") == pytest.approx(c.n)


@needs_om
@pytest.mark.parametrize("sid", ["E1-T0100", "E2-01", "E3-01"])
def test_openmodelica_matches_python_twin(sid):
    from pneusim import om
    sc = [s for s in scenarios.all_scenarios() if s.id == sid][0]
    om.build(sc.model)
    R = om.run(sc.model, sc.overrides(), f"test_{sid}", stop_time=sc.stop)
    tw = sc.twin().simulate(sc.stop, times=R["time"])
    assert np.abs(R["cyl.x"] - tw["cyl.x"]).max() < 5e-5          # 0.05 mm
    assert np.abs(R["cyl.pA"] - tw["cyl.pA"]).max() < 0.02e5      # 0.02 bar
    assert np.abs(R["cyl.pB"] - tw["cyl.pB"]).max() < 0.02e5
