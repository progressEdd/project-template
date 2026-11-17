#!/usr/bin/env bash
# shippEdd commit sequencer. Executors never run git — parallel siblings in a
# wave share the working tree, and concurrent git would race on the index lock.
# Each executor records a per-task commit spec instead; this script replays the
# specs sequentially (one commit per task line, plans in glob order) and stamps
# each plan's .done marker so re-entry never double-commits.
#
# Usage: replay-commits.sh     (no args — scans <state>/runs/*.done)
# TSV line: <commit message><TAB><path1,path2,...>  — message single-line, no
# tabs; paths repo-relative, comma-separated; blank/pathless lines are skipped.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
runs="$root/$("$here/state-dir.sh")/runs"
cd "$root"

for marker in "$runs"/*.done; do
  [ -f "$marker" ] || continue
  grep -q '^committed ' "$marker" && continue                 # already replayed
  id="$(basename "${marker%.done}")"
  tsv="${marker%.done}.commits.tsv"
  msgs=(); specs=()
  if [ -f "$tsv" ]; then
    while IFS=$'\t' read -r msg paths || [ -n "${msg:-}" ]; do
      [ -n "${msg:-}" ] && [ -n "${paths:-}" ] || continue   # blank / no files
      IFS=',' read -r -a files <<< "$paths"
      for f in "${files[@]}"; do
        if [ ! -e "$f" ] && ! git ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then
          echo "refused: $id commit spec lists a path that does not exist: $f" >&2
          echo "  fix or remove that line in $tsv, then rerun" >&2
          exit 1
        fi
      done
      msgs+=("$msg"); specs+=("$paths")
    done < "$tsv"
  fi
  for i in "${!msgs[@]}"; do                                  # validate all, then commit
    IFS=',' read -r -a files <<< "${specs[$i]}"
    git add -- "${files[@]}"
    if git diff --cached --quiet; then
      echo "skip: $id nothing new to commit: ${msgs[$i]}" >&2 # partial-replay recovery
    else
      git commit -q -m "${msgs[$i]}"
      echo "committed $id: $(git rev-parse --short HEAD) ${msgs[$i]}"
    fi
  done
  if [ "${#msgs[@]}" -gt 0 ]; then
    echo "committed $(git rev-parse --short HEAD)" >> "$marker"
  else
    echo "committed none" >> "$marker"                        # done, no spec to replay
  fi
done
