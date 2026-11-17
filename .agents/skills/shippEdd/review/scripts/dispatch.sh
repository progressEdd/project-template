#!/usr/bin/env bash
# shippEdd background dispatcher. Generic by design: the ROLE lives in the
# prompt file, not here. The detached `pi --print` run gets its persona inline
# in its prompt, flips its own marker (.running -> .done / .failed), and is
# never waited on or post-processed by this script.
#
# Usage:
#   dispatch.sh <id> <prompt-file> [--model <model-id>] [--force]
#   dispatch.sh --status
#
# Abort semantics: to stop a run, kill the PID recorded in its .running marker.
# An aborted run never flips — a stale .running marker whose PID is dead means
# aborted/failed; the next orchestrator command should offer cleanup (inspect
# the log, then delete the stale marker before redispatching).
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
runs="$root/$("$here/state-dir.sh")/runs"
mkdir -p "$runs"

if [ "${1:-}" = "--status" ]; then
  for marker in "$runs"/*.running "$runs"/*.done "$runs"/*.failed; do
    [ -f "$marker" ] || continue
    id="$(basename "${marker%.*}")"
    pid="$(head -n1 "$marker" 2>/dev/null | grep -oE '[0-9]+' || true)"
    alive=dead
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then alive=alive; fi
    size="$(wc -c < "$runs/$id.log" 2>/dev/null | tr -d '[:space:]')" || size=0
    printf '%s  %s  pid %s %s  log %s bytes\n' "$id" "${marker##*.}" "${pid:-?}" "$alive" "${size:-0}"
  done
  exit 0
fi

usage='usage: dispatch.sh <id> <prompt-file> [--model <model-id>] [--force] | dispatch.sh --status'
id="${1:?$usage}"
prompt="${2:?$usage}"
shift 2
model=(); force=0
while [ $# -gt 0 ]; do
  case "$1" in
    --model) model=(--model "${2:?$usage}"); shift 2 ;;
    --force) force=1; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

case "$prompt" in /*) ;; *) prompt="$PWD/$prompt" ;; esac
if [ "$force" -eq 0 ] && { [ -e "$runs/$id.running" ] || [ -e "$runs/$id.done" ] || [ -e "$runs/$id.failed" ]; }; then
  echo "refused: run '$id' already has a marker (use --force to redispatch)" >&2; exit 1
fi
[ -f "$prompt" ] || { echo "no such prompt file: $prompt" >&2; exit 1; }
if [ "$force" -eq 1 ]; then rm -f "$runs/$id.running" "$runs/$id.done" "$runs/$id.failed"; fi

cd "$root"
nohup pi --print ${model[@]+"${model[@]}"} < "$prompt" > "$runs/$id.log" 2>&1 &
pid=$!
printf '%s\n' "$pid" > "$runs/$id.running"
printf 'dispatched %s (PID %s) → %s\n' "$id" "$pid" "$runs/$id.log"
