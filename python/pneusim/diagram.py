"""Draw an experiment's circuit diagram from the Modelica source: the icons, placements and
connection lines the models carry (what OMEdit shows), as SVG/PNG via matplotlib.

Only the annotation subset this library uses is read: Icon(coordinateSystem(extent), graphics
= {Line, Rectangle, Ellipse, Polygon, Text}), Placement(transformation(extent)), and
connect(...) annotation(Line(points, color)). check(model) verifies that every connection line
ends on the ports it joins.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "modelica" / "PneumaticCircuits"


# ------------------------------------------------------------------ a small Modelica expression parser
TOKEN = re.compile(r'\s*(?:(?P<num>-?\d+\.?\d*(?:[eE][-+]?\d+)?)|(?P<str>"(?:[^"\\]|\\.)*")|(?P<id>[A-Za-z_][\w.]*)|(?P<op>[{}(),=]))')


def tokens(s):
    pos = 0
    out = []
    while pos < len(s):
        m = TOKEN.match(s, pos)
        if not m or m.end() == pos:
            if s[pos:].strip() == "":
                break
            raise ValueError(f"cannot parse near: {s[pos:pos + 40]!r}")
        pos = m.end()
        for k in ("num", "str", "id", "op"):
            if m.group(k) is not None:
                out.append((k, m.group(k)))
                break
    return out


class Parser:
    def __init__(self, s):
        self.t = tokens(s)
        self.i = 0

    def peek(self):
        return self.t[self.i] if self.i < len(self.t) else (None, None)

    def take(self, v=None):
        k, x = self.peek()
        if v is not None and x != v:
            raise ValueError(f"expected {v}, got {x}")
        self.i += 1
        return k, x

    def value(self):
        k, x = self.peek()
        if x == "{":
            self.take("{")
            items = []
            while self.peek()[1] != "}":
                items.append(self.value())
                if self.peek()[1] == ",":
                    self.take(",")
            self.take("}")
            return items
        if k == "num":
            self.take()
            return float(x)
        if k == "str":
            self.take()
            return x[1:-1]
        if k == "id":
            self.take()
            if self.peek()[1] == "(":
                return (x, self.args())
            return {"true": True, "false": False}.get(x, x)
        raise ValueError(f"unexpected {x}")

    def args(self):
        self.take("(")
        pos, named = [], {}
        while self.peek()[1] != ")":
            k, x = self.peek()
            if k == "id" and self.i + 1 < len(self.t) and self.t[self.i + 1][1] == "=":
                self.take()
                self.take("=")
                named[x] = self.value()
            else:
                pos.append(self.value())
            if self.peek()[1] == ",":
                self.take(",")
        self.take(")")
        return pos, named


def arg(callargs, key):
    """an argument of a call, given by name or as a positional call with that head"""
    pos, named = callargs
    if key in named:
        return named[key]
    for p in pos:
        if isinstance(p, tuple) and p[0] == key:
            return p
    return None


def balanced(s, start):
    """s[start] == '(' ; return the index after its matching ')' (strings respected)"""
    depth, i, instr = 0, start, False
    while i < len(s):
        c = s[i]
        if instr:
            if c == "\\":
                i += 1
            elif c == '"':
                instr = False
        elif c == '"':
            instr = True
        elif c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    raise ValueError("unbalanced")


# ------------------------------------------------------------------ the library's classes
class Cls:
    def __init__(self, name, body, full):
        self.name, self.body, self.full = name, body, full
        self.extends = re.findall(r"^\s*extends\s+([\w.]+)\s*[(;]", body, re.M)
        self.redeclares = dict((n, t) for t, n in re.findall(r"redeclare\s+([\w.]+)\s+(\w+)", body))
        self.icon, self.extent = [], None
        self.components = []          # (type, name, comment, placement extent)
        self.connects = []            # (a, b, points, color)
        self._parse()

    def _parse(self):
        b = self.body
        # the class annotation: the last top-level "annotation(" after the equations
        # the class annotation is the last top-level annotation(...) of the body; Icon(...) is one of its arguments
        starts = [m.start() for m in re.finditer(r"\n\s*annotation\s*\(", b)]
        for st in reversed(starts):
            p0 = b.index("(", st)
            end = balanced(b, p0)
            ann = b[p0:end]
            mi = re.search(r"[(,]\s*Icon\s*\(", ann)
            if not mi:
                continue
            q0 = ann.index("(", mi.start() + 1)
            q1 = balanced(ann, q0)
            ca = Parser("Icon" + ann[q0:q1]).value()[1]
            cs = arg(ca, "coordinateSystem")
            if cs:
                self.extent = arg(cs[1], "extent")
            self.icon = arg(ca, "graphics") or []
            break
        # components with placements
        for m in re.finditer(r"^\s*(?:discrete\s+|parameter\s+|replaceable\s+)?([\w.]+)\s+(\w+)\s*(\([^;]*?\))?\s*(?:constrainedby\s+[\w.]+\s*)?(\"[^\"]*\")?\s*annotation\s*\(\s*Placement", b, re.M):
            typ, name = m.group(1), m.group(2)
            if typ in ("connect",):
                continue
            p0 = b.index("(", b.index("Placement", m.start()))
            end = balanced(b, p0)
            ca = Parser("P" + b[p0:end]).value()[1]
            ext = arg(arg(ca, "transformation")[1], "extent")
            tag = re.search(r'tag\s*=\s*"([^"]*)"', m.group(3) or "")
            self.components.append((typ, name, tag.group(1) if tag else "", ext))
        for m in re.finditer(r"connect\s*\(\s*([\w.]+)\s*,\s*([\w.]+)\s*\)\s*annotation\s*\(\s*Line\s*", b):
            p0 = b.index("(", b.index("Line", m.start()))
            end = balanced(b, p0)
            _, named = Parser("L" + b[p0:end]).value()[1]
            self.connects.append((m.group(1), m.group(2), named["points"], named.get("color", [0, 0, 0])))


def strip_dynamic(s):
    """DynamicSelect(static, dynamic) -> static: the drawing without animation"""
    while True:
        i = s.find("DynamicSelect(")
        if i < 0:
            return s
        p0 = i + len("DynamicSelect")
        end = balanced(s, p0)
        inner, depth, cut = s[p0 + 1:end - 1], 0, None
        for k, c in enumerate(inner):                 # the first top-level comma ends the static part
            if c in "({":
                depth += 1
            elif c in ")}":
                depth -= 1
            elif c == "," and depth == 0:
                cut = k
                break
        s = s[:i] + inner[:cut].strip() + s[end:]


def load_library():
    classes = {}
    for f in SRC.glob("*.mo"):
        s = strip_dynamic(f.read_text())
        pkg = f.stem if f.stem != "package" else ""
        for m in re.finditer(r"^\s*(?:partial\s+)?(model|block|connector)\s+(\w+)\b(?!\s*=)", s, re.M):
            name = m.group(2)
            e = re.search(rf"^\s*end\s+{name}\s*;", s[m.end():], re.M)
            body = s[m.end(): m.end() + e.start()]
            classes[name] = Cls(name, body, f"{pkg}.{name}")
        for m in re.finditer(r"^\s*connector\s+(\w+)\s*=.*?annotation\s*\(", s, re.M | re.S):
            p0 = s.index("(", m.end() - 1)
            end = balanced(s, p0)
            ca = Parser("A" + s[p0:end]).value()[1]
            c = Cls.__new__(Cls)
            c.name, c.extends, c.components, c.connects, c.extent = m.group(1), [], [], [], None
            c.icon = arg(arg(ca, "Icon")[1], "graphics") or []
            classes[m.group(1)] = c
    return classes


def resolve(classes, name):
    return classes[name.split(".")[-1]]


def chain(classes, c):
    """the class and its bases, base first"""
    out = []
    for e in c.extends:
        out += chain(classes, resolve(classes, e))
    return out + [c]


def icon_of(classes, c):
    ext, gr, comps = [[-100, -100], [100, 100]], [], []
    for k in chain(classes, c):
        if k.extent:
            ext = k.extent
        gr += k.icon
        comps += k.components
    return ext, gr, comps


# ------------------------------------------------------------------ geometry
def mapper(src, dst):
    (x1, y1), (x2, y2) = src
    (X1, Y1), (X2, Y2) = dst
    sx, sy = (X2 - X1) / (x2 - x1), (Y2 - Y1) / (y2 - y1)
    return lambda x, y: (X1 + (x - x1) * sx, Y1 + (y - y1) * sy)


def model_layout(model):
    classes = load_library()
    top = classes[model]
    comps, connects, redecl = [], [], {}
    for k in chain(classes, top):
        comps += k.components
        connects += k.connects
        redecl.update(getattr(k, "redeclares", {}))
    comps = [(redecl.get(name, typ), name, comment, ext) for typ, name, comment, ext in comps]
    placed = {}
    for typ, name, comment, ext in comps:
        c = resolve(classes, typ)
        iext, gr, sub = icon_of(classes, c)
        f = mapper(iext, ext)
        ports = {}
        for styp, sname, _, sext in sub:
            (a, b), (cx, cy) = sext, (0, 0)
            cx, cy = (sext[0][0] + sext[1][0]) / 2, (sext[0][1] + sext[1][1]) / 2
            ports[sname] = (f(cx, cy), styp, [f(*sext[0]), f(*sext[1])])
        placed[name] = dict(type=typ, comment=comment, extent=ext, icon_ext=iext, graphics=gr, map=f, ports=ports)
    return placed, connects, classes


def check(model, tol=0.6):
    """every connection line must start and end on the ports it connects"""
    placed, connects, _ = model_layout(model)
    bad = []
    for a, b, pts, _ in connects:
        for end, ref in ((pts[0], a), (pts[-1], b)):
            comp, port = ref.split(".", 1)
            p = placed[comp]["ports"][port][0]
            if abs(p[0] - end[0]) > tol or abs(p[1] - end[1]) > tol:
                bad.append(f"{a} -> {b}: line end {end} is not on {ref} at ({p[0]:.1f}, {p[1]:.1f})")
    return bad


# ------------------------------------------------------------------ drawing
def label(name, tag):
    """the designation (tag) when the circuit sets one; parts without it (tubes, operators) stay unlabelled"""
    return tag


def draw(model, path_noext, title=None, hide=("Tube",)):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.patches import Ellipse, Polygon, Rectangle

    placed, connects, classes = model_layout(model)
    top = classes[model]
    dext = None
    for k in chain(classes, top):
        m = re.search(r"Diagram\s*\(\s*coordinateSystem\s*\(\s*extent\s*=\s*(\{[^;]*?\}\s*\})", k.body)
        if m:
            dext = Parser(m.group(1)).value()
    (x1, y1), (x2, y2) = dext
    fig, ax = plt.subplots(figsize=((x2 - x1) / 55, (y2 - y1) / 55))
    ax.set_xlim(x1, x2)
    ax.set_ylim(y1, y2)
    ax.set_aspect("equal")
    ax.axis("off")

    def col(c, default=(0, 0, 0)):
        c = c if c is not None else default
        return tuple(v / 255 for v in c)

    def prim(g, f, scale, comp_name=None, comment=None):
        kind, (pos, nm) = g
        lc = col(nm.get("lineColor", nm.get("color")))
        fc = col(nm.get("fillColor"), (255, 255, 255)) if nm.get("fillPattern") == "FillPattern.Solid" else "none"
        lw = 0.9 * max(nm.get("thickness", 0.25) / 0.25, 1)
        if nm.get("pattern") == "LinePattern.None":
            lw = 0
        if kind == "Line":
            pts = [f(*p) for p in nm["points"]]
            xs, ys = zip(*pts)
            ls = "--" if nm.get("pattern") == "LinePattern.Dash" else "-"
            ax.plot(xs, ys, color=lc, lw=lw, ls=ls, solid_capstyle="round")
            arr = nm.get("arrow")
            if arr and arr[1] in ("Arrow.Filled", "Arrow.Open") and len(pts) >= 2:
                (ax0, ay0), (ax1, ay1) = pts[-2], pts[-1]
                ax.annotate("", xy=(ax1, ay1), xytext=(ax0 + (ax1 - ax0) * 0.7, ay0 + (ay1 - ay0) * 0.7),
                            arrowprops=dict(arrowstyle="-|>" if arr[1] == "Arrow.Filled" else "->", color=lc,
                                            lw=lw, mutation_scale=7))
        elif kind == "Rectangle":
            (a, b), (c, d) = f(*nm["extent"][0]), f(*nm["extent"][1])
            ax.add_patch(Rectangle((min(a, c), min(b, d)), abs(c - a), abs(d - b), ec=lc, fc=fc, lw=lw))
        elif kind == "Ellipse":
            (a, b), (c, d) = f(*nm["extent"][0]), f(*nm["extent"][1])
            ax.add_patch(Ellipse(((a + c) / 2, (b + d) / 2), abs(c - a), abs(d - b), ec=lc, fc=fc, lw=lw))
        elif kind == "Polygon":
            ax.add_patch(Polygon([f(*p) for p in nm["points"]], closed=True, ec=lc, fc=fc, lw=lw))
        elif kind == "Text":
            s = nm.get("textString", "")
            if "%name" in s or "%tag" in s:
                s = label(comp_name, comment) if "%tag" in s else s.replace("%name", comp_name or "")
            if not s:
                return
            (a, b), (c, d) = f(*nm["extent"][0]), f(*nm["extent"][1])
            ha = {"TextAlignment.Left": "left", "TextAlignment.Right": "right"}.get(nm.get("horizontalAlignment"), "center")
            x = min(a, c) if ha == "left" else max(a, c) if ha == "right" else (a + c) / 2
            ax.text(x, (b + d) / 2, s, ha=ha, va="center", fontsize=7.5, family="DejaVu Sans")

    for a, b, pts, color in connects:
        xs, ys = zip(*pts)
        sig = tuple(color) != (0, 0, 0)
        ax.plot(xs, ys, color=col(color), lw=0.8 if sig else 1.1, ls=(0, (4, 2)) if sig else "-")
    for name, p in placed.items():
        typ = p["type"].split(".")[-1]
        for g in p["graphics"]:
            prim(g, p["map"], 1, name, p["comment"])
        if typ in hide:
            continue
        for pname, ((px, py), ptyp, _) in p["ports"].items():
            if ptyp.endswith("Port"):
                ax.add_patch(Ellipse((px, py), 3.2, 3.2, ec="k", fc="w", lw=0.7, zorder=5))
    if title:
        ax.set_title(title, fontsize=10)
    fig.tight_layout()
    for ext in (".svg", ".png"):
        fig.savefig(str(path_noext) + ext, dpi=160, bbox_inches="tight", facecolor="white")
    plt.close(fig)
