# Install and run

Two parts, both free:

- **OpenModelica** (the simulator and its graphical editor, OMEdit): to open the circuits, run them
  and watch them animate. This is what you need for the lessons.
- **Python** (optional): to plot runs from the command line and to reproduce the recorded results.

First, get this repository: on its GitHub page press **Code → Download ZIP** and unzip it (or
`git clone https://github.com/Samarth030312/pneumatic-circuits-openmodelica`).

## Windows (10 or 11, 64-bit)

1. Download and run the OpenModelica installer, version **1.27.1** or later:
   <https://openmodelica.org/download/download-windows/>. Accept the defaults.
2. Start **OMEdit** (Start menu → OpenModelica → OMEdit).
3. **File → Open Model/Library File(s)** → choose `modelica/PneumaticCircuits/package.mo` in the
   unzipped folder. `PneumaticCircuits` appears under *Libraries*.
4. Go to [Learn](LEARN.md): open `Learn → Lessons → L01_DirectSingleActing`, Simulate, Diagram Window, Play.

Python, optional: install Python 3.10+ from <https://www.python.org/downloads/> (tick *Add python.exe
to PATH*), then in the repository folder:

```bat
pip install -r requirements.txt
python scripts\play.py TwoHandPress opening=0.1
```

The scripts find the installed OpenModelica by themselves. Tested: CI runs every test on Windows
with OpenModelica 1.27.1 installed this way.

## macOS

OpenModelica no longer ships Mac installers (the last one was 1.16), so it runs from its official
Linux container, which supports both Intel and Apple-silicon Macs.

1. Install **Docker Desktop** (<https://www.docker.com/products/docker-desktop/>) and start it.
2. Install **XQuartz** (<https://www.xquartz.org>). Open it, *Settings → Security*, tick *Allow
   connections from network clients*, then log out and in again.
3. In Terminal, in the repository folder:
   ```bash
   docker pull openmodelica/openmodelica:v1.27.1-gui
   scripts/omedit.sh
   ```
   OMEdit opens with the library loaded. Continue with [Learn](LEARN.md).

Without Docker, the three experiments still run in Python on any Mac (no OpenModelica needed;
no animation, plots only):

```bash
pip3 install -r requirements.txt
python3 scripts/play.py TwoHandPress opening=0.1 --engine python
```

Tested: CI runs the Python parts on macOS. The OMEdit route follows OpenModelica's own instructions
for macOS (Docker and XQuartz); we have not run it on a Mac ourselves.

## Linux

Either install OpenModelica from its packages (<https://openmodelica.org/download/download-linux/>)
and open `package.mo` in OMEdit, or use Docker without installing anything else:

```bash
docker pull openmodelica/openmodelica:v1.27.1-gui
scripts/omedit.sh
```

Tested: developed and run on Ubuntu 22.04 with Docker; CI runs every test there.

## Python commands

| Command | Does |
|---|---|
| `python3 scripts/play.py --list TwoHandPress` | the settings a circuit offers |
| `python3 scripts/play.py L06_SpeedControl openingA=0.05` | one run of a lesson or experiment, plotted |
| `python3 scripts/play.py TwoHandPress opening=0.1 --engine python` | the same without OpenModelica (experiments only) |
| `python3 scripts/run_lessons.py` | every lesson and its documented variants, recorded and checked |
| `python3 scripts/run_experiments.py` | the 48 experiment runs, OpenModelica and the Python twin |
| `python3 scripts/make_figures.py` | all figures and circuit drawings |
| `python3 -m pytest tests` | the tests |

## If something goes wrong

| Symptom | Cause, fix |
|---|---|
| OMEdit: "Failed to load package Modelica" | harmless: this library does not use the Modelica Standard Library |
| OMEdit in Docker: "failed to create drawable" | harmless: software graphics inside the container |
| OMEdit in Docker opens a black window | the X11 shared-memory problem: use `scripts/omedit.sh`, which sets `QT_X11_NO_MITSHM=1` |
| a script: "neither OpenModelica (omc) nor Docker was found" | install one of them; or use `--engine python` for the experiments |
| a lesson does not animate | simulate it first, then press *Diagram Window* in the Plotting perspective, then Play |
| Simulate fails in an Exercise | expected until all parts are connected: each net needs one Tube, each button an operator |
