---
name: wayfind
description: Where am I, what's running, what do I type next — reads the workflow state dir (roadmap, phase artifacts, run markers) and recommends exactly one command. Never advances anything. Run /skill:wayfind when lost, at a session start, or to check on background runs.
disable-model-invocation: true
---

# shippEdd wayfind — read the state, name the command

You are the state reader and flow router of the phase loop. You look at the filesystem — markers, artifacts, roadmap — render where the work stands in a handful of lines, and name the single command to type next. That is all. You never dispatch, never edit STATE.md or ROADMAP, never advance a phase: the loop moves only when the user types the command. A router that drives is a router nobody can trust.

`<state>` is the workflow state dir resolved in step 0; all other paths are relative to it or to the repo root. This skill is self-contained: its scripts (`scripts/state-dir.sh`, `scripts/dispatch.sh`) and its route table (`MAP.md`, same folder) live in this folder.

## Ground rules

1. **Read-only by default** — inspect, never advance. The one sanctioned mutation is stale-marker cleanup (a `.running` marker whose PID is dead), and only on the user's explicit choice; even then, inspect-the-log is the recommended first move.
2. **Markers are truth** — run state comes from `<state>/runs/` markers, loop position from files and ROADMAP. STATE.md is advisory: when it disagrees with the markers, trust the markers and say the drift out loud.
3. **Render, don't dump** — the readout is a digest: checkmarks, one-line run states, one diagnosis. Artifacts get named, never pasted. MAP.md rows are selected for the situation, never listed wholesale.
4. **Recommend and stop** — end by naming exactly one command. Never run it (outside the confirmed cleanup), never chain, never "while I'm here".

## Step 0 — resolve the state dir

Run `scripts/state-dir.sh`. It prints exactly one line: the state dir path relative to the repo root (`$PLANNING_DIR` env → `.pi/planning.json` `state_dir` → `.planning`).

If that dir lacks both `STATE.md` and `ROADMAP.md`, no workflow state exists. Say:

> No workflow state found. Run `/skill:bootstrap` first — it creates the skeleton this skill reads.

Then stop.

## Step 1 — STATE READOUT

Gather, in order — everything is a fact off the disk:

1. **Runs**: `bash <this skill's folder>/scripts/dispatch.sh --status` — one line per marker: id, state, PID, alive/dead, log size.
2. **STATE.md** — `next_action`, `progress`, the phase named in the body (advisory only, rule 2).
3. **ROADMAP.md** — `## Next up`, the phase checkboxes under `## Phases`, the target phase's `Plans:` list.
4. **Live phases** — directories under `<state>/phases/`, excluding `_`-prefixed entries (`_templates/`, `_archive/`).

**Current phase** (same rule `define` uses): the `## Next up` phase if it is unchecked and its folder is live; else the first unchecked phase with a live folder; else none.

**Artifact checklist** for the current phase — each entry is `✓` iff the file exists *and* is not still the raw template (no `<…>` placeholders left in it; `NN-YY-PLAN`/`NN-YY-SUMMARY` count only once instantiated — a filename still containing `YY` is a template, never an artifact):

- `CONTEXT` → `<NN>-CONTEXT.md`
- `RESEARCH` → `<NN>-RESEARCH.md` (absent is legitimate when research is off or ran clean — still `✗`, the diagnosis says why not to worry)
- one `<NN>-<YY>-PLAN` / `<NN>-<YY>-SUMMARY` pair per plan id in ROADMAP's `Plans:` list for the phase (or per instantiated file when the list is unfilled)
- `VERIFICATION` → `VERIFICATION.md` filled (a real verdict line, not the template)

**Runs line** — translate each marker (current phase's ids first, then any others):

- `.done` with a `committed` line → `<id> done+committed`
- `.done` without one → `<id> done (awaiting commit replay)`
- `.running`, live PID → `<id> running (PID <n>, alive)`
- `.running`, dead PID → `<id> running (PID <n>, DEAD — stale marker)`
- `.failed` → `<id> failed — <the one-line reason appended to the marker>`

**Render** (this shape, one line each):

```
Phase 02-auth: CONTEXT ✓ · RESEARCH ✓ · 02-01-PLAN ✓ · 02-01-SUMMARY ✓ · VERIFICATION ✗
Runs: 02-01 running (PID 999999, DEAD — stale marker) · 02-verify failed — verifier missing input · 01-01 done+committed
Roadmap: next up 02-auth · 1 live phase · 1 shipped
```

(Roadmap line: next up from `## Next up`; live = non-`_` phase dirs; shipped = checked boxes under `## Phases`. No current phase → drop the first line and let the diagnosis carry it.)

**Then the diagnosis — what's waiting on what**, first match wins:

1. **Stale `.running` (dead PID)** — an aborted or crashed run; aborted runs never flip their own markers. Put the cleanup to the user before anything else (this is the one mutation, rule 1, confirmation required):

   ```
   ❓ Run <id> is marked .running but its PID is dead — aborted or crashed. Clean it up how?
     ➡️ 1. inspect — show the tail of <state>/runs/<id>.log first
       2. delete the stale marker <state>/runs/<id>.running
       3. redispatch — relaunch it from its saved prompt: dispatch.sh <id> <state>/runs/<id>.prompt.md --force
   ```

   Do exactly what was chosen, then continue the diagnosis treating that run as not-running. No second question.
2. **`.failed` run** — name the owning skill by id shape: `<NN>-research` → `/skill:define`; `<NN>-<YY>` → `/skill:implement`; `<NN>-verify*` → `/skill:review`. Say: `<id> failed — <reason>; /skill:<owner> owns the retry (inspect the log, redispatch --force)`. Failed runs are the owner's lane, not yours.
3. **STATE.md drift** — if STATE.md's `next_action`/phase disagrees with what the markers and files say, say it in one line: `STATE.md says <x>, but the markers say <y> — trusting the markers.` Then proceed on marker truth.
4. **Otherwise, the ladder** (first true line names the recommendation):
   - no live phase and no unchecked roadmap phase → the roadmap is complete — `/skill:todo` to bank what's next (or `/skill:define` to mint a phase from a one-line intent)
   - no live phase, unchecked phase exists → `/skill:define` — the phase exists only on the roadmap
   - current phase has `CONTEXT ✗` → `/skill:define` — no decisions on file yet (or the folder isn't even scaffolded)
   - plans instantiated for none of the `Plans:` ids → `/skill:define` — planning never finished
   - any plan's run is not `done+committed` (no marker, `.running`, `.done` without `committed`) → `/skill:implement` — waves, cleanup, and commit replay live there
   - all plans `done+committed`, `VERIFICATION ✗` → `/skill:review` — verify and ship
   - `VERIFICATION ✓` but the phase is still live → `/skill:review` — a re-entry: finish the readout/ship sequence

Write the ladder's line as the diagnosis, e.g. `01-02 is still running — walk away or check back; when it's done+committed, /skill:review`.

## Step 2 — ROUTES (from MAP.md)

Read `MAP.md` from this skill's folder — the hand-written flow map, and the only file that changes when a skill is added. Render for this situation, not verbatim (rule 3):

- the **one main-flow line** whose "go there when" matches the diagnosis above;
- any **on-ramp line** whose trigger is observably true right now — e.g. `todos/pending/` non-empty makes the todo line relevant;
- nothing else. The loop notes and session-hygiene sections are for humans reading the file; they are not routes.

Then the single recommendation, as the last line:

```
Type this next: /skill:<name>
```

It repeats the diagnosis's skill — one position, one command, no menu. Then stop (rule 4).
