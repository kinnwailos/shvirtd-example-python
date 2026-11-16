#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${1:-${REPO_URL:-}}"
DEST_DIR="${DEST_DIR:-/opt/shvirtd-example-python}"

if [[ -z "${REPO_URL}" ]]; then
  echo "Usage: $0 <git-repo-url>" >&2
  echo "Example: $0 https://github.com/<user>/shvirtd-example-python.git" >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git is not installed" >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "docker compose v2 is not installed" >&2
  exit 1
fi

mkdir -p "$(dirname "${DEST_DIR}")"

if [[ -d "${DEST_DIR}/.git" ]]; then
  git -C "${DEST_DIR}" remote set-url origin "${REPO_URL}"
  git -C "${DEST_DIR}" fetch origin
  git -C "${DEST_DIR}" pull --ff-only
else
  git clone "${REPO_URL}" "${DEST_DIR}"
fi

cd "${DEST_DIR}"
docker compose up -d --build --remove-orphans
docker compose ps
