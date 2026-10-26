"""An independent implementation of the circuits' physics in Python, to cross-check OpenModelica.

The same equations as the Modelica library (docs/PHYSICS.md), written as a network solver: nodes
are tube volumes, elements (valves, supply, cylinder) give the mass flows into the nodes and the
derivatives of their own states. Switching (button edges, pilot hysteresis, roller valves,
pressure sequence valve) and the end stops are integration events; between events SciPy's
implicit solver integrates the smooth equations.
"""
import math

import numpy as np
from scipy.integrate import solve_ivp

P_ATM = 101325.0
T0 = 293.15
R_AIR = 287.05
RHO0 = 1.185
G_N = 9.80665
RT = R_AIR * T0


# ------------------------------------------------------------------ flow laws (ISO 6358)
def phi(r, b):
    r_lam = 0.999
    if r <= b:
        return 1.0
    if r <= r_lam:
        return math.sqrt(1 - ((r - b) / (1 - b)) ** 2)
    return math.sqrt(1 - ((r_lam - b) / (1 - b)) ** 2) * (1 - r) / (1 - r_lam)


def mflow(C, b, pa, pb):
    """mass flow a -> b"""
    if pa >= pb:
        return C * RHO0 * pa * phi(pb / pa, b)
    return -C * RHO0 * pb * phi(pa / pb, b)


def conductance(qn, b):
    p1, p2 = 6e5 + P_ATM, 5e5 + P_ATM
    return qn / 60000 / (p1 * phi(p2 / p1, b))


def step(x, w):
    return 0.5 + 0.5 * math.tanh(x / w)


# ------------------------------------------------------------------ elements
class Element:
    """Base: no own states, no events."""
    nstates = 0
    names = ()

    def init(self):
        return []

    def flows(self, t, s, P, F):
        """add mass flows into nodes to F; return the derivatives of own states"""
        return []

    def events(self, t, s, P):
        """[(value, direction)] whose zero crossing is an event"""
        return []

    def on_event(self, k, t, s, P):
        """event k happened: update discrete states"""


class Supply(Element):
    def __init__(self, node, p_gauge=6e5, qn=750, b=0.3):
        self.node, self.ps, self.C, self.b = node, P_ATM + p_gauge, conductance(qn, b), b

    def flows(self, t, s, P, F):
        F[self.node] += mflow(self.C, self.b, self.ps, P[self.node])
        return []


class Schedule:
    """an operator's hand: pressed on [t_on, t_off)"""

    def __init__(self, t_on, t_off):
        self.t_on, self.t_off = list(t_on), list(t_off)

    def __call__(self, t):
        return any(a <= t < b for a, b in zip(self.t_on, self.t_off))

    def edges(self):
        return sorted(self.t_on + self.t_off)


class Valve32(Element):
    """3/2-way NC; actuated: a callable t -> bool (an operator's Schedule)"""
    nstates = 1
    names = ("xv",)

    def __init__(self, p1, p2, actuated, qn=80, b=0.3, tau=0.005):
        self.p1, self.p2, self.act = p1, p2, actuated
        self.C, self.b, self.tau = conductance(qn, b), b, tau

    def init(self):
        return [0.0]

    def flows(self, t, s, P, F):
        xv = s[0]
        m12 = xv * mflow(self.C, self.b, P[self.p1], P[self.p2])
        m23 = (1 - xv) * mflow(self.C, self.b, P[self.p2], P_ATM)
        F[self.p1] -= m12
        F[self.p2] += m12 - m23
        return [((1.0 if self.act(t) else 0.0) - xv) / self.tau]


class SequenceValve(Valve32):
    """pressure sequence valve: a 3/2 NC valve switched by the pressure at node p12"""
    nstates = 2
    names = ("xv", "p_c")

    def __init__(self, p1, p2, p12, p_set=4e5, dp_hyst=0.2e5, V_sense=0.3e-6, qn_sense=20, n=1.2, **kw):
        self.on = False
        super().__init__(p1, p2, lambda t: self.on, **kw)
        self.p12, self.p_set, self.dp_hyst, self.V, self.Cs, self.n = p12, p_set, dp_hyst, V_sense, conductance(qn_sense, self.b), n

    def init(self):
        return [0.0, P_ATM]

    def flows(self, t, s, P, F):
        d = super().flows(t, s[:1], P, F)
        m = mflow(self.Cs, self.b, P[self.p12], s[1])
        F[self.p12] -= m
        return d + [self.n * RT / self.V * m]

    def events(self, t, s, P):
        g = s[1] - P_ATM
        return [(g - self.p_set, 1)] if not self.on else [(g - (self.p_set - self.dp_hyst), -1)]

    def on_event(self, k, t, s, P):
        self.on = not self.on


class RollerValve32(Valve32):
    """3/2-way roller lever valve, NC: actuated while the cylinder's piston is beyond x_trip"""

    def __init__(self, p1, p2, cylinder, x_trip, whenAbove=True, **kw):
        self.cyl, self.x_trip, self.above, self.on = cylinder, x_trip, whenAbove, None
        super().__init__(p1, p2, lambda t: self.on, **kw)

    def _x(self):
        c = self.circuit
        return c._y[c.slices[self.cyl].start]

    def _init_on(self):
        if self.on is None:
            self.on = (self._x() >= self.x_trip) if self.above else (self._x() <= self.x_trip)

    def flows(self, t, s, P, F):
        self._init_on()
        return super().flows(t, s, P, F)

    def events(self, t, s, P):
        self._init_on()
        # waiting to be actuated: the crossing towards the actuated side; actuated: the way back
        toward = 1 if self.above else -1
        return [(self._x() - self.x_trip, -toward if self.on else toward)]

    def on_event(self, k, t, s, P):
        self.on = not self.on


class Valve52(Element):
    """5/2-way; pilot chambers on nodes p14 (and p12 for a double-pilot memory valve)"""

    def __init__(self, p1, p2, p4, p14, p12=None, qn=110, b=0.3, tau=0.008, p_on=1.5e5, p_off=1.0e5,
                 V_pilot=0.5e-6, qn_pilot=30, n=1.2, start=False):
        self.p1, self.p2, self.p4, self.p14, self.p12 = p1, p2, p4, p14, p12
        self.C, self.Cp, self.b, self.tau = conductance(qn, b), conductance(qn_pilot, b), b, tau
        self.p_on, self.p_off, self.V, self.n = p_on, p_off, V_pilot, n
        self.on = start
        self.nstates = 2 if p12 is None else 3
        self.names = ("xv", "p_pilot14") + (() if p12 is None else ("p_pilot12",))

    def init(self):
        return [0.0, P_ATM] + ([] if self.p12 is None else [P_ATM])

    def flows(self, t, s, P, F):
        xv = s[0]
        C, b = self.C, self.b
        m14 = xv * mflow(C, b, P[self.p1], P[self.p4])
        m23 = xv * mflow(C, b, P[self.p2], P_ATM)
        m12 = (1 - xv) * mflow(C, b, P[self.p1], P[self.p2])
        m45 = (1 - xv) * mflow(C, b, P[self.p4], P_ATM)
        F[self.p1] -= m14 + m12
        F[self.p2] += m12 - m23
        F[self.p4] += m14 - m45
        mp = mflow(self.Cp, b, P[self.p14], s[1])
        F[self.p14] -= mp
        d = [((1.0 if self.on else 0.0) - xv) / self.tau, self.n * RT / self.V * mp]
        if self.p12 is not None:
            mq = mflow(self.Cp, b, P[self.p12], s[2])
            F[self.p12] -= mq
            d.append(self.n * RT / self.V * mq)
        return d

    def events(self, t, s, P):
        g14 = s[1] - P_ATM
        if self.p12 is None:
            return [(g14 - self.p_on, 1)] if not self.on else [(g14 - self.p_off, -1)]
        g12 = s[2] - P_ATM
        # a double-pilot valve switches when one pilot is above p_on while the other is below p_off
        if not self.on:
            return [(min(g14 - self.p_on, self.p_off - g12), 1)]
        return [(min(g12 - self.p_on, self.p_off - g14), 1)]

    def on_event(self, k, t, s, P):
        self.on = not self.on


class LogicValve(Element):
    """two-pressure (AND, lower input feeds) or shuttle (OR, higher input feeds) valve"""

    def __init__(self, x, y, a, kind, qn=100, b=0.3, dp_w=5e3):
        self.x, self.y, self.a, self.kind = x, y, a, kind
        self.C, self.b, self.w = conductance(qn, b), b, dp_w

    def flows(self, t, s, P, F):
        px, py = P[self.x], P[self.y]
        w = step(py - px, self.w) if self.kind == "AND" else step(px - py, self.w)
        mx = w * mflow(self.C, self.b, px, P[self.a])
        my = (1 - w) * mflow(self.C, self.b, py, P[self.a])
        F[self.x] -= mx
        F[self.y] -= my
        F[self.a] += mx + my
        return []


class OneWayFlowControl(Element):
    """free flow pa -> pb (or pb -> pa if reversed), throttled the other way"""

    def __init__(self, pa, pb, opening=0.3, reversed=False, qn_thr_max=85, qn_free=(100, 110),
                 p_crack=0.1e5, dp_w=5e3, b=0.3):
        self.pa, self.pb, self.rev = pa, pb, reversed
        self.Ct = conductance(opening * qn_thr_max, b)
        self.Cf = conductance(qn_free[0] + opening * (qn_free[1] - qn_free[0]), b)
        self.crack, self.w, self.b = p_crack, dp_w, b

    def flows(self, t, s, P, F):
        pa, pb = P[self.pa], P[self.pb]
        w = step(((pb - pa) if self.rev else (pa - pb)) - self.crack, self.w)
        m = w * mflow(self.Cf, self.b, pa, pb) + (1 - w) * mflow(self.Ct, self.b, pa, pb)
        F[self.pa] -= m
        F[self.pb] += m
        return []


class QuickExhaust(Element):
    def __init__(self, p1, p2, qn12=300, qn23=390, b=0.3, dp_open=0.1e5, dp_w=2e3):
        self.p1, self.p2 = p1, p2
        self.C12, self.C23, self.b, self.dp_open, self.w = conductance(qn12, b), conductance(qn23, b), b, dp_open, dp_w

    def flows(self, t, s, P, F):
        p1, p2 = P[self.p1], P[self.p2]
        m12 = step(p1 - p2, self.w) * mflow(self.C12, self.b, p1, p2)                  # lip seal: 1 -> 2 only
        m23 = step(p2 - p1 - self.dp_open, self.w) * mflow(self.C23, self.b, p2, P_ATM)   # disc lifts off the exhaust
        F[self.p1] -= m12
        F[self.p2] += m12 - m23
        return []


class Cylinder(Element):
    nstates = 4
    names = ("x", "v", "pA", "pB")

    def __init__(self, A, B, D=0.020, d=0.008, L=0.100, m=0.15, V0A=1.5e-6, V0B=1.5e-6, qn_port=150, b=0.3,
                 n=1.2, F_c=8, F_s=12, v_s=0.01, v_eps=1e-3, b_v=20, alpha=0, F_load=0, x_work=1,
                 k_work=2e5, d_work=200, k_stop=1e7, d_stop=2500, x_start=0):
        self.A, self.B = A, B
        self.A1, self.A2 = math.pi * D ** 2 / 4, math.pi * (D ** 2 - d ** 2) / 4
        self.L, self.m, self.V0A, self.V0B, self.Cp, self.b, self.n = L, m, V0A, V0B, conductance(qn_port, b), b, n
        self.fr = (F_c, F_s, v_s, v_eps, b_v)
        self.F_g = m * G_N * math.sin(math.radians(alpha))
        self.F_load, self.x_work, self.k_work, self.d_work = F_load, x_work, k_work, d_work
        self.k_stop, self.d_stop, self.x_start = k_stop, d_stop, x_start

    def init(self):
        return [self.x_start, 0.0, P_ATM, P_ATM]

    def flows(self, t, s, P, F):
        x, v, pA, pB = s
        mA = mflow(self.Cp, self.b, P[self.A], pA)
        mB = mflow(self.Cp, self.b, P[self.B], pB)
        F[self.A] -= mA
        F[self.B] -= mB
        VA = self.V0A + self.A1 * x
        VB = self.V0B + self.A2 * (self.L - x)
        Fp = pA * self.A1 - pB * self.A2 - P_ATM * (self.A1 - self.A2)
        Fc, Fs, vs, ve, bv = self.fr
        Ff = (Fc + (Fs - Fc) * math.exp(-(v / vs) ** 2)) * math.tanh(v / ve) + bv * v
        Fe = 0.0
        if x < 0:
            Fe += max(0.0, -self.k_stop * x - self.d_stop * v)
        if x > self.L:
            Fe -= max(0.0, self.k_stop * (x - self.L) + self.d_stop * v)
        if x > self.x_work:
            Fe -= max(0.0, self.k_work * (x - self.x_work) + self.d_work * v)
        a = (Fp - Ff - self.F_load + Fe + self.F_g) / self.m
        return [v, a, self.n / VA * (RT * mA - pA * self.A1 * v), self.n / VB * (RT * mB + pB * self.A2 * v)]


# ------------------------------------------------------------------ the network
class Circuit:
    def __init__(self, tubes, elements, schedules=(), n=1.2):
        """tubes: {node: (length m, extra volume m3)}; elements: {name: Element}"""
        self.nodes = list(tubes)
        self.idx = {k: i for i, k in enumerate(self.nodes)}
        D = 2.5e-3
        self.V = np.array([math.pi * D ** 2 / 4 * L + Vx for L, Vx in tubes.values()])
        self.n = n
        self.el = elements
        for e in elements.values():
            e.circuit = self
        self.sched = schedules
        off = len(self.nodes)
        self.slices = {}
        for k, e in elements.items():
            self.slices[k] = slice(off, off + e.nstates)
            off += e.nstates
        self.N = off

    def x0(self):
        s = [P_ATM] * len(self.nodes)
        for e in self.el.values():
            s += e.init()
        self._y = np.array(s)
        return self._y

    def _P(self, y):
        return {k: y[i] for k, i in self.idx.items()}

    def rhs(self, t, y):
        self._y = y
        P = self._P(y)
        F = {k: 0.0 for k in self.nodes}
        dy = np.zeros(self.N)
        for k, e in self.el.items():
            sl = self.slices[k]
            d = e.flows(t, y[sl], P, F)
            dy[sl] = d
        for k, i in self.idx.items():
            dy[i] = self.n * RT / self.V[i] * F[k]
        return dy

    def simulate(self, t_end, dt_out=0.002, rtol=1e-7, times=None):
        """integrate from 0 to t_end; returns {name: array} on a uniform grid (or at the given times)"""
        y = self.x0()
        t = 0.0
        breaks = sorted({b for s in self.sched for b in s.edges() if 0 < b < t_end} | {t_end})
        segs = []
        atol = np.full(self.N, 1e-9)
        atol[:len(self.nodes)] = 1.0                      # pressures, Pa
        for k, e in self.el.items():
            sl = self.slices[k]
            for j, nm in enumerate(e.names):
                atol[sl.start + j] = 1.0 if nm.startswith("p") else 1e-9
        for tb in breaks:
            while t < tb - 1e-12:
                self._y = y
                evs = self._event_funcs()
                sol = solve_ivp(self.rhs, (t, tb), y, method="LSODA", rtol=rtol, atol=atol,
                                events=[f for f, _ in evs], dense_output=True, max_step=0.01)
                segs.append((sol.t[0], sol.t[-1], sol.sol))
                t, y = sol.t[-1], sol.y[:, -1].copy()
                if sol.status == 1:                       # an event: flip that element's state
                    self._y = y
                    for j, (_, (k, i)) in enumerate(evs):
                        if len(sol.t_events[j]):
                            self.el[k].on_event(i, t, y[self.slices[k]], self._P(y))
                            break
                if sol.status == -1:
                    raise RuntimeError(sol.message)
        grid = np.arange(0, t_end + dt_out / 2, dt_out) if times is None else np.asarray(times)
        Yg = np.empty((self.N, len(grid)))
        for a, b, f in segs:                       # the solver's continuous solution, segment by segment
            k = (grid >= a) & (grid <= b)
            if k.any() and f is not None:
                Yg[:, k] = f(grid[k])
        out = {"time": grid}
        for k, i in self.idx.items():
            out[k] = Yg[i]
        for k, e in self.el.items():
            sl = self.slices[k]
            for j, nm in enumerate(e.names):
                out[f"{k}.{nm}"] = Yg[sl.start + j]
        return out

    def _event_funcs(self):
        """one terminal event function per element event; positional element events (x crossing a
        stop) only restart the integration"""
        fs = []
        for k, e in self.el.items():
            sl = self.slices[k]
            evs = e.events(0.0, self._y[sl], self._P(self._y))
            for i, (_, direction) in enumerate(evs):
                def f(t, y, k=k, sl=sl, i=i):
                    self._y = y
                    return self.el[k].events(t, y[sl], self._P(y))[i][0]
                f.terminal = True
                f.direction = direction
                fs.append((f, (k, i)))
        return fs
