#!/usr/bin/env bash
# Open OMEdit (OpenModelica's graphical editor) on this library, from the official container.
# Linux desktop with X11 or XWayland. Nothing is installed on the computer; OMEdit's settings
# are kept in build/omedit-home. In OMEdit: Libraries > PneumaticCircuits > Experiments, double-click
# a model, then Simulation > Simulate. (The message that the Modelica library cannot be loaded is
# harmless: this library does not use it.)
#   scripts/omedit.sh
set -euo pipefail
IMAGE="${OM_GUI_IMAGE:-openmodelica/openmodelica:v1.27.1-gui}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
XAUTH="${XAUTHORITY:-$HOME/.Xauthority}"
mkdir -p "$ROOT/build/omedit-home"
args=(--rm --net=host -u "$(id -u):$(id -g)"
      -e DISPLAY="${DISPLAY:?no DISPLAY: run this from a desktop session}"
      -e QT_X11_NO_MITSHM=1 -e LIBGL_ALWAYS_SOFTWARE=1 -e QTWEBENGINE_CHROMIUM_FLAGS="--disable-gpu --no-sandbox"
      -e HOME=/home/om -v "$ROOT/build/omedit-home":/home/om
      -v /tmp/.X11-unix:/tmp/.X11-unix:ro -v "$ROOT":/work -w /work)
if [ -f "$XAUTH" ]; then args+=(-v "$XAUTH":/tmp/.Xauthority:ro -e XAUTHORITY=/tmp/.Xauthority); fi
exec docker run "${args[@]}" "$IMAGE" OMEdit /work/modelica/PneumaticCircuits/package.mo
