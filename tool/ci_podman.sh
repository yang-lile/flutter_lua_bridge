#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW="${ACT_WORKFLOW:-$ROOT_DIR/.github/workflows/typed-bridge.yml}"
IMAGE="${ACT_IMAGE:-catthehacker/ubuntu:act-latest}"
ARCHITECTURE="${ACT_ARCHITECTURE:-linux/amd64}"
NETWORK="${ACT_NETWORK:-bridge}"
MODE="${1:-dry-run}"
TEMP_WORKFLOW=""

usage() {
  cat <<'EOF'
Usage: ./tool/ci_podman.sh [dry-run|list|teal|local-gate|all]

Run the GitHub Actions workflow locally with act and a Podman machine.

  dry-run     Parse the workflow and print all jobs without running them (default).
  list        List workflow jobs.
  teal        Run the Teal/Cyan job.
  local-gate  Run the Linux local gate. Flutter is selected as x64 for Apple Silicon.
  all         Run teal, then local-gate.

Environment overrides:
  ACT_WORKFLOW       Workflow file path.
  ACT_IMAGE          act runner image.
  ACT_ARCHITECTURE   Container architecture (default: linux/amd64).
  ACT_NETWORK        Container network (default: bridge).
EOF
}

cleanup() {
  if [[ -n "$TEMP_WORKFLOW" ]]; then
    rm -f -- "$TEMP_WORKFLOW"
  fi
}
trap cleanup EXIT

case "$MODE" in
  -h|--help|help)
    usage
    exit 0
    ;;
  dry-run|list|teal|local-gate|all)
    ;;
  *)
    echo "Unknown mode: $MODE" >&2
    usage >&2
    exit 2
    ;;
esac

command -v podman >/dev/null 2>&1 || {
  echo "podman is required; install it and start a Podman machine first" >&2
  exit 1
}
command -v act >/dev/null 2>&1 || {
  echo "act is required; install it with: brew install act" >&2
  exit 1
}
[[ -f "$WORKFLOW" ]] || {
  echo "workflow not found: $WORKFLOW" >&2
  exit 1
}

if [[ -n "${DOCKER_HOST:-}" ]]; then
  PODMAN_HOST="$DOCKER_HOST"
else
  machine_state="$(podman machine inspect --format '{{.State}}' 2>/dev/null | head -n 1 || true)"
  if [[ -n "$machine_state" && "$machine_state" != "running" ]]; then
    echo "Podman machine is $machine_state; start it with: podman machine start" >&2
    exit 1
  fi

  socket_path="$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null | head -n 1 || true)"
  if [[ -z "$socket_path" ]]; then
    echo "could not find a Podman API socket; set DOCKER_HOST explicitly" >&2
    exit 1
  fi
  if [[ "$socket_path" == unix://* ]]; then
    PODMAN_HOST="$socket_path"
  else
    PODMAN_HOST="unix://$socket_path"
  fi
fi

export DOCKER_HOST="$PODMAN_HOST"
echo "Using Podman API: $DOCKER_HOST"
echo "Using runner: $IMAGE ($ARCHITECTURE)"

act_args=(
  pull_request
  --container-daemon-socket -
  --network "$NETWORK"
  -P "ubuntu-latest=$IMAGE"
  --container-architecture "$ARCHITECTURE"
)

run_act() {
  act "$@" -W "$WORKFLOW" "${act_args[@]}"
}

run_local_gate() {
  # Flutter 3.38.10 has no Linux arm64 archive. act reports the Podman VM's
  # host architecture, so use a temporary x64 workflow for this local check.
  TEMP_WORKFLOW="$(mktemp "${TMPDIR:-/tmp}/flutter-lua-bridge-act.XXXXXX.yml")"
  python3 - "$WORKFLOW" "$TEMP_WORKFLOW" <<'PY'
from pathlib import Path
import sys

source, destination = map(Path, sys.argv[1:])
lines = []
for line in source.read_text().splitlines(keepends=True):
    lines.append(line)
    if line.strip().startswith("flutter-version:"):
        indent = line[: len(line) - len(line.lstrip())]
        lines.append(f"{indent}architecture: x64\n")
destination.write_text("".join(lines))
PY
  act -j local-gate -W "$TEMP_WORKFLOW" "${act_args[@]}"
}

case "$MODE" in
  dry-run)
    run_act --dryrun
    ;;
  list)
    act -l -W "$WORKFLOW" --container-daemon-socket - \
      -P "ubuntu-latest=$IMAGE" --container-architecture "$ARCHITECTURE"
    ;;
  teal)
    run_act -j teal
    ;;
  local-gate)
    run_local_gate
    ;;
  all)
    run_act -j teal
    run_local_gate
    ;;
esac
