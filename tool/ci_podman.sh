#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW="${ACT_WORKFLOW:-$ROOT_DIR/.github/workflows/typed-bridge.yml}"
RELEASE_WORKFLOW="${ACT_RELEASE_WORKFLOW:-$ROOT_DIR/.github/workflows/typed-bridge-release.yml}"
IMAGE="${ACT_IMAGE:-catthehacker/ubuntu:act-latest}"
ARCHITECTURE="${ACT_ARCHITECTURE:-linux/amd64}"
NETWORK="${ACT_NETWORK:-bridge}"
MODE="${1:-dry-run}"
TEMP_WORKFLOW=""

usage() {
  cat <<'EOF'
Usage: ./tool/ci_podman.sh [dry-run|list|light|release-dry-run|release|all]

Run the GitHub Actions workflow locally with act and a Podman machine.

  dry-run     Parse the workflow and print all jobs without running them (default).
  list        List workflow jobs.
  light       Run the lightweight workflow.
  release-dry-run Parse the release workflow without running it.
  release     Run the release integration workflow. Flutter is selected as x64 for Apple Silicon.
  all         Run light, then release integration.

Environment overrides:
  ACT_WORKFLOW       Workflow file path.
  ACT_RELEASE_WORKFLOW Release workflow file path.
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
  dry-run|list|light|release-dry-run|release|all)
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
[[ -f "$RELEASE_WORKFLOW" ]] || {
  echo "release workflow not found: $RELEASE_WORKFLOW" >&2
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
  --container-daemon-socket -
  --network "$NETWORK"
  -P "ubuntu-latest=$IMAGE"
  --container-architecture "$ARCHITECTURE"
)

run_workflow() {
  local event="$1"
  local workflow="$2"
  shift 2
  act "$event" "$@" -W "$workflow" "${act_args[@]}"
}

run_release() {
  # Flutter 3.38.10 has no Linux arm64 archive. act reports the Podman VM's
  # host architecture, so use a temporary x64 workflow for this local check.
  TEMP_WORKFLOW="$(mktemp "${TMPDIR:-/tmp}/flutter-lua-bridge-act.XXXXXX.yml")"
  python3 - "$RELEASE_WORKFLOW" "$TEMP_WORKFLOW" <<'PY'
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
  local extra_args=()
  if [[ "${RELEASE_DRY_RUN:-}" == 1 ]]; then
    extra_args+=(--dryrun)
  fi
  run_workflow release "$TEMP_WORKFLOW" -j ubuntu-integration "${extra_args[@]}"
}

case "$MODE" in
  dry-run)
    run_workflow pull_request "$WORKFLOW" --dryrun
    ;;
  list)
    act -l -W "$WORKFLOW" --container-daemon-socket - \
      -P "ubuntu-latest=$IMAGE" --container-architecture "$ARCHITECTURE"
    ;;
  light)
    run_workflow pull_request "$WORKFLOW"
    ;;
  release)
    run_release
    ;;
  release-dry-run)
    RELEASE_DRY_RUN=1
    run_release
    ;;
  all)
    run_workflow pull_request "$WORKFLOW"
    run_release
    ;;
esac
