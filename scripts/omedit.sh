#!/usr/bin/env bash
# Open OMEdit (OpenModelica's graphical editor) on this library from the official container.
#   Linux:  scripts/omedit.sh                       (X11 or XWayland desktop)
#   macOS:  install Docker Desktop and XQuartz; in XQuartz > Settings > Security tick
#           "Allow connections from network clients", log out and in, then: scripts/omedit.sh
#   Windows: install OpenModelica natively instead (docs/INSTALL.md).
# OMEdit's settings are kept in build/omedit-home. The message that the Modelica library cannot
# be loaded, and "failed to create drawable", are harmless here.
set -euo pipefail
IMAGE="${OM_GUI_IMAGE:-openmodelica/openmodelica:v1.27.1-gui}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/build/omedit-home"
common=(--rm -e QT_X11_NO_MITSHM=1 -e LIBGL_ALWAYS_SOFTWARE=1 -e QTWEBENGINE_CHROMIUM_FLAGS="--disable-gpu --no-sandbox"
        -e HOME=/home/om -v "$ROOT/build/omedit-home":/home/om -v "$ROOT":/work -w /work)
if [ "$(uname)" = "Darwin" ]; then
  command -v xhost >/dev/null || { echo "XQuartz is needed: https://www.xquartz.org"; exit 1; }
  open -a XQuartz; sleep 2; xhost +localhost >/dev/null
  exec docker run "${common[@]}" -e DISPLAY=host.docker.internal:0 "$IMAGE" OMEdit /work/modelica/PneumaticCircuits/package.mo
fi
XAUTH="${XAUTHORITY:-$HOME/.Xauthority}"
args=("${common[@]}" --net=host -u "$(id -u):$(id -g)" -e DISPLAY="${DISPLAY:?no DISPLAY: run this from a desktop session}"
      -v /tmp/.X11-unix:/tmp/.X11-unix:ro)
if [ -f "$XAUTH" ]; then args+=(-v "$XAUTH":/tmp/.Xauthority:ro -e XAUTHORITY=/tmp/.Xauthority); fi
exec docker run "${args[@]}" "$IMAGE" OMEdit /work/modelica/PneumaticCircuits/package.mo
