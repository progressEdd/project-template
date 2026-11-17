## What it does

`/skill:implement` turns approved plans into background work. It reads the phase's `NN-YY-PLAN.md` files, orders them by the `wave` frontmatter the planner precomputed, and dispatches one detached executor per plan — all plans of a wave in parallel, waves strictly one at a time. Each executor implements its plan's task blocks in a fresh context, runs every verify command, checks every acceptance criterion, and leaves two artifacts: an `NN-YY-SUMMARY.md` and a machine-readable commit spec (`runs/NN-YY.commits.tsv`). When a wave's markers have all flipped `.done`, the skill runs `replay-commits.sh`, which commits each plan's recorded specs sequentially in plan order and stamps the markers so nothing is ever committed twice. You can close the session between waves — markers and `committed` lines are the entire resume state.

## When to reach for it

- `/skill:define` just approved plans — `implement` is the command define ends by naming.
- You want work running while you do something else — waves are detached by design; walk away and re-run `/skill:implement` whenever you want to gate a wave, replay its commits, and dispatch the next.
- After a crash, reboot, or abandoned session — re-run it; markers say exactly what finished.
- One plan failed mid-wave — re-run; the gate offers inspect / redispatch / skip per failed plan.

## Prerequisites

- A shippEdd state dir (`/skill:bootstrap`) with a phase that has approved plans (`/skill:define`).
- git identity configured (`user.name` / `user.email`) — the sequencer commits with it.

## Common questions

**Why don't executors commit?**
Each wave runs several executors in parallel against the same working tree. Concurrent `git add`/`git commit` would race on git's index lock, so executors are forbidden from git entirely. Each records what *should* be committed — message plus paths, one line per task — and `replay-commits.sh` replays those specs sequentially after the wave lands. Deterministic commits, zero races.

**What if two plans touch the same file?**
They shouldn't: the planner guarantees plans in the same wave are file-disjoint and puts same-file work in different waves via `depends_on`. If a plan set slips through that guarantee anyway, the safe move is to let the wave finish (executors won't corrupt each other — they just may overwrite each other), then re-plan the affected slice or hand-fix the collision before the next wave dispatches.

**How do I check on a running wave?**
`bash .agents/skills/shippEdd/implement/scripts/dispatch.sh --status` lists every run (state, PID alive/dead, log size); `tail <state>/runs/NN-YY.log` streams one run. Finishers flip their own markers — nothing needs babysitting.

**A marker still says `.running` but the PID is dead.**
That run was aborted or crashed — aborted runs never flip their own markers. Re-running `/skill:implement` offers the cleanup: inspect the log, delete the stale marker, redispatch.

**When do the commits actually appear?**
Per wave, at the gate: all markers `.done` → `replay-commits.sh` → commits in git log, in plan order. Between waves the working tree carries uncommitted changes on purpose; that's the design, not an accident.

## It's working if

- Markers flip per plan: `.running` → `.done`, each stamped with `committed <sha>` after its wave's replay.
- Commits appear in `git log` in plan order, one per recorded task spec — and re-running `replay-commits.sh` commits nothing.
- Your session context stays empty of implementation detail — dispatch lines and marker states, never file contents.
- Every `NN-YY-SUMMARY.md` lands with frontmatter filled and task commit specs matching its TSV.
- Nothing runs git except the sequencer; nothing auto-runs `/skill:review`.

## Where it fits

Role: the execution step of the phase loop — the only skill that dispatches implementation work. Neighbours: `/skill:define` before it, which produces the approved plans (and precomputes the waves); `/skill:review` after it, which verifies coverage against requirements and decisions, then ships. `/skill:todo` takes stray ideas mid-execution so they don't derail a running wave.
