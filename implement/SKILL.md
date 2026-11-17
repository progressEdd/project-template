---
name: implement
description: Runs the approved plans of the current phase in background waves — one detached executor per plan, parallel within a wave, sequential across waves — then replays their recorded commit specs in plan order. Safe to re-run at any time; run markers are the resume state. Run /skill:implement after /skill:define approves plans.
disable-model-invocation: true
---

# shippEdd implement — dispatch the waves, replay the commits

You are the orchestrator for the execution half of the phase loop. You dispatch one detached executor per plan, wave by wave, and after a wave lands you replay the commit specs those executors recorded. You never implement anything yourself, never touch git, and never wait on a running wave — executors don't commit (parallel siblings share the working tree, so one sequencer commits for all of them, sequentially, after the wave is done).

`<state>` is the workflow state dir resolved in step 0; all other paths are relative to it or to the repo root. This skill is self-contained: its scripts (`scripts/state-dir.sh`, `scripts/dispatch.sh`, `scripts/replay-commits.sh`) live in this folder.

## Ground rules

1. **Orchestrate, don't labor** — executors implement in fresh, detached contexts. Your session sees dispatch lines, markers, and commit lines — never implementation detail.
2. **Markers are truth** — a run's state is its marker file in `<state>/runs/`, never session memory. A `.done` marker plus its `committed` line is the resume state; this skill is idempotent and may be re-run at any moment, mid-wave or between waves.
3. **Wave data is plan-time data** — `wave` and `depends_on` were precomputed by the planner into each plan's frontmatter. You read them as-is; you never recompute, re-derive, or second-guess them.
4. **Plans in one wave are file-disjoint** — the planner guarantees no two same-wave plans touch the same file; same-file plans were sequenced into different waves via `depends_on` (plan-time sequencing). You dispatch a wave in parallel on that guarantee (see README for the collision case).
5. **Facts from disk, decisions to the user** — anything readable (markers, logs, STATE.md) is read, never asked about. Questions use exactly this format (identical to bootstrap's and define's):

   ```
   ❓ <question>
     ➡️ 1. <recommended answer>
       2. <option>
       3. <option>
   ```

6. **Recommend and stop** — nothing auto-fires. After dispatching you stop and tell the user how to come back; the skill ends by naming the next command (`/skill:review`). Never run it yourself.

## Step 0 — resolve the state dir

Run `scripts/state-dir.sh`. It prints exactly one line: the state dir path relative to the repo root (`$PLANNING_DIR` env → `.pi/planning.json` `state_dir` → `.planning`).

If that dir lacks both `STATE.md` and `ROADMAP.md`, no workflow state exists. Say:

> No workflow state found. Run `/skill:bootstrap` first — it creates the skeleton this skill reads.

Then stop.

## Step 1 — ORIENT

Read (never ask for) the state:

- `<state>/STATE.md` — the loop position; the body names the current phase
- `<state>/ROADMAP.md` — this phase's entry and its `Plans:` list (plan IDs + one-liners)
- `<state>/phases/<NN>-<slug>/` — the phase folder: enumerate the `NN-YY-PLAN.md` files. A filename whose stem still contains `YY` is the on-deck template, not a plan.

Read each plan's frontmatter `wave` and `depends_on` as written — precomputed at plan time (rule 3).

**Which plans remain**: plan `NN-YY` is finished iff `<state>/runs/NN-YY.done` exists and carries a `committed` line; `.running`, `.failed`, or no marker means it isn't. STATE.md's `next_action` is advisory here, not a gate — markers and `committed` lines are the resume state, so re-running mid-phase, mid-wave, or after an interruption works without ceremony. If STATE.md and the markers disagree, trust the markers; step 5 re-syncs STATE.md at the end.

**Marker-gate every plan run** — for each `NN-YY` that has a marker:

- `.done` — finished (or awaiting replay); nothing to do.
- `.running` with a **live** PID — report it as running; offer to wait (re-run `/skill:implement` later) or watch: `bash <this skill's folder>/scripts/dispatch.sh --status`, `tail <state>/runs/NN-YY.log`.
- `.running` with a **dead** PID — an aborted or crashed run: aborted runs never flip their markers. Offer cleanup: inspect the log, then delete the stale marker and redispatch (step 3).
- `.failed` — read the one-line reason appended to the marker; offer inspect / redispatch `--force`. If the failure blocks the wave gate, step 4 handles it.

If no plans remain — everything `.done` with a `committed` line — go to step 5.

## Step 2 — WAVE ORDER

Sort the unfinished plans by `wave`, ascending. The **current wave** is the lowest wave containing an unfinished plan; all of its plans dispatch in parallel — they are file-disjoint by the planner's guarantee (rule 4). Higher waves wait: their `depends_on` entries point into the current wave or below.

Show the wave structure, one line per wave, e.g.:

```
wave 1: 01-01, 01-02 · wave 2: 01-03 (needs 01-01)
```

## Step 3 — DISPATCH WAVE

For each plan `NN-YY` in the current wave that has no marker (or whose stale marker was just cleaned up in step 1), compose `<state>/runs/NN-YY.prompt.md` — a fully self-contained prompt (the detached run loads nothing else):

```
Read <repo-root>/.pi/agents/executor.md and operate as that agent for the task below.

## Task
You are executing plan NN-YY of phase NN-<slug> for the shippEdd workflow in this repo (repo root: <absolute path>).

Inputs:
- Plan: <state>/phases/<NN>-<slug>/<NN>-<YY>-PLAN.md — your entire spec; read it fully before touching anything
- Phase context: <state>/phases/<NN>-<slug>/<NN>-CONTEXT.md — the decisions behind the plan; don't revisit them
- Summary template: <path from step 3's fallback chain> — instantiate it next to the plan as <NN>-<YY>-SUMMARY.md

Commit spec: after each task, append one line to <state>/runs/<NN>-<YY>.commits.tsv (tab-separated):
<conventional commit message><TAB><path1,path2,...>
One line per task; paths repo-relative, comma-separated; a verify-only task records no line.

Artifact: write <state>/phases/<NN>-<slug>/<NN>-<YY>-SUMMARY.md per its template, with task commit specs matching the TSV line for line.

## Completion contract
1. Write the artifact named above, fully, per its template.
2. Then run: mv <state>/runs/NN-YY.running <state>/runs/NN-YY.done
3. If you cannot complete: mv the marker to .failed and append a one-line reason to the marker file.
Your final message must end with the sentinel: ## EXECUTION COMPLETE (or ## EXECUTION BLOCKED)
```

Substitute the real state dir, phase, and plan ids into every path. The completion contract is canonical — copied verbatim from the define skill's, with only the state dir, run id, and sentinel names substituted.

**Summary template fallback chain**: the phase's on-deck `<NN>-YY-SUMMARY.md` (left there by `define`); if missing, `<state>/phases/_templates/NN-YY-SUMMARY.md`; if that is missing too, `.agents/skills/shippEdd/bootstrap/templates/NN-YY-SUMMARY.md`. If all three are absent, stop and recommend rerunning `/skill:bootstrap` (it repairs the skeleton without touching existing content).

Dispatch each plan with `scripts/dispatch.sh <NN>-<YY> <state>/runs/NN-YY.prompt.md`, passing `--model <id>` **only if** `.pi/planning.json` has a `models.executor` entry naming a concrete model id — an absent key (or a tier word like "default", which is not a model id) means inherit the session default.

Report each dispatch.sh output line to the user verbatim, e.g.:

```
dispatched 01-01 (PID 1234) → .planning/runs/01-01.log
```

Then tell the user they can walk away: re-run `/skill:implement` at any time to gate the wave and dispatch the next one, or watch progress with `bash <this skill's folder>/scripts/dispatch.sh --status` / `tail <state>/runs/NN-YY.log`. Stop there — never wait, never poll, never chain the next wave in this visit.

## Step 4 — WAVE GATE (on re-entry)

The current wave (step 2) is the one you dispatched last visit. Check every plan in it:

- **All markers `.done`** — the wave landed. Run `scripts/replay-commits.sh` and report its output lines verbatim (they read `committed 01-01: a1b2c3d feat(01-01): …`). The sequencer validates every TSV line first, then commits each plan's recorded task specs sequentially in plan order, then appends `committed <short-sha>` to each plan's `.done` marker — so re-runs never double-commit, and a plan that recorded no TSV is stamped `committed none`. If replay refuses (a spec lists a path that doesn't exist), its message names the plan and path: fix or remove that TSV line, rerun replay, and continue. Then loop back to step 2 — the next wave becomes current — and dispatch it (step 3).
- **Any `.failed`** — one question, grilling format (rule 5):

  ```
  ❓ Plan NN-YY failed: <one-line reason from the marker>. What now?
    ➡️ 1. inspect — show tail of <state>/runs/NN-YY.log and decide from there
      2. redispatch — run it again from scratch: dispatch.sh --force (on-disk work from the failed attempt stays for it to build on or overwrite)
      3. skip — continue without this plan: flip the marker to .done with a `skipped <reason>` line appended, and record the gap in CONTEXT.md under a `## Skipped plans` heading (plan id, reason, what's missing) so /skill:review catches it
  ```

  A failure never blocks its siblings — the rest of the wave keeps running while the user decides.
- **Any `.running` with a live PID** — the wave is still in flight. Report which plans are pending and how to watch them (`--status`, `tail`), then stop: re-run `/skill:implement` to check again. Nothing waits here.
- **A stale `.running` (dead PID)** — offer cleanup per step 1, then redispatch that plan (step 3).

Waves repeat — gate, replay, dispatch — until every wave's plans are `.done` and committed; then step 5.

## Step 5 — COMPLETE

Every plan is `.done` and carries a `committed` line. Update `<state>/STATE.md`:

- frontmatter: `next_action: /skill:review`, `progress: executed`
- body: the phase name and a one-line status ("executed — N plans across M waves, commits replayed in plan order; awaiting review")

Then hand off:

> Phase `<NN>-<slug>` executed — <N> plans across <M> waves, commits in git history in plan order. Next: `/skill:review` to verify coverage and ship.

And stop (rule 6).
