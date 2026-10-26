#!/usr/bin/env bash
# Run OpenModelica's compiler (omc) from the official container, on this repository.
# Usage: scripts/om.sh script.mos      (paths relative to the repository root)
set -euo pipefail
IMAGE="${OM_IMAGE:-openmodelica/openmodelica:v1.27.1-minimal}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec docker run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp -v "$ROOT":/work -w /work "$IMAGE" omc "$@"
