#!/usr/bin/env bash
# shippEdd state-dir resolver.
# Precedence: $PLANNING_DIR env -> .pi/planning.json "state_dir" -> .planning
# Prints exactly one line: the state dir path, relative to the repo root.
set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root"

if [ -n "${PLANNING_DIR:-}" ]; then
  printf '%s\n' "$PLANNING_DIR"
  exit 0
fi

if [ -f .pi/planning.json ]; then
  dir="$(grep -o '"state_dir"[[:space:]]*:[[:space:]]*"[^"]*"' .pi/planning.json \
    | head -n1 \
    | sed -e 's/^[^:]*://' -e 's/[[:space:]]*"//' -e 's/"$//' || true)"
  if [ -n "$dir" ]; then
    printf '%s\n' "$dir"
    exit 0
  fi
fi

printf '%s\n' '.planning'
