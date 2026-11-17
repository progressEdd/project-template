## What it does

`/skill:wayfind` reads the workflow state off the disk and hands you back three things: a position (the current phase with its artifact checklist — CONTEXT, RESEARCH, each plan and summary, VERIFICATION — as ✓/✗), the run board (every background run as `done+committed`, `running (PID, alive)`, `DEAD — stale marker`, or `failed — reason`), and the roadmap line (what's next up, how many phases live, how many shipped). Then one diagnosis sentence — what's waiting on what — and one command to type, chosen from `MAP.md`, the hand-written flow map that lives beside the skill. It never dispatches anything, never edits STATE.md or ROADMAP, never advances a phase. Its single sanctioned mutation is cleaning up a stale `.running` marker (a dead PID — an aborted run that never flipped its own marker), and only after you pick inspect-log, delete-marker, or redispatch from an explicit question.

## When to reach for it

- A new session just opened and you want to know where the work stands before typing anything.
- You're lost mid-loop — which phase, which wave, which skill owns the next move.
- You walked away from background runs and want the board: what finished, what's still alive, what died.
- STATE.md and reality seem to disagree — wayfind tells you which one wins (the markers).

## Common questions

**Is this required to resume work?**
No — that's the point of the design. Every skill re-reads the state dir itself; `/skill:implement` resumed mid-wave and `/skill:review` re-entered mid-verify both work with no warm-up. wayfind is for *you*, when you're the one who's lost. The filesystem is the state; wayfind is just the clearest window onto it.

**Why does it sometimes disagree with STATE.md?**
Because STATE.md is advisory and the markers are truth. STATE.md is written by skills at handoff moments; markers are flipped by the runs themselves the instant they finish. When a run failed, or a session died between a write and a flip, STATE.md stales. wayfind always reads both, reports the drift in one line, and proceeds on marker truth — the same law implement and review run on.

**What does a dead-PID `.running` marker mean?**
An abort or a crash — aborted runs never flip their own markers. wayfind asks exactly once what to do: inspect the log tail (recommended), delete the stale marker, or redispatch the run from its saved prompt file with `--force`. Your choice executes; no cleanup happens unconfirmed.

**Why one command and not a menu?**
Because a router that hedges is a router you have to re-derive. The situation picks one most-likely command; the on-ramp lines (like a pile of parked todos pointing at `/skill:todo`) render only when they're observably true. If you want the full map instead of your line of it, read `MAP.md` itself — it's five sections and about a screen.

## It's working if

- The readout is a handful of lines — checklist, runs, roadmap, one diagnosis, one `Type this next:` — and no pasted file contents.
- Every run's line matches its marker on disk: done markers with a `committed` line read `done+committed`, dead PIDs read `DEAD — stale marker`, failed runs carry their one-line reason.
- A stale marker produces exactly one cleanup question; a `.failed` run produces a pointer at the owning skill (`/skill:implement` for plans, `/skill:review` for verifies, `/skill:define` for research) — never a direct retry.
- STATE.md drift is called out in one line, and the recommendation follows the markers, not the file.
- Nothing in the state dir changes unless you confirmed a cleanup.
- The session ends right after the recommendation — nothing chained, nothing auto-run.

## Where it fits

Role: the loop's dashboard and router — the only skill with no lane of its own, reading everyone else's. Neighbours: `/skill:bootstrap`, whose skeleton wayfind verifies exists; every loop skill, which wayfind routes between by reading their markers and artifacts; `/skill:todo`, whose parked todos surface here as an on-ramp when they're worth promoting.
