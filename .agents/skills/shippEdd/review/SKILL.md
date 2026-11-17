---
name: review
description: Verifies the executed phase with a fresh-context verifier subagent (requirement, decision, and task coverage — actually run), walks any gaps into fix plans via the planner, and ships when green — commit, optional PR, archive the phase, tick the roadmap. Run /skill:review after /skill:implement finishes all plans.
disable-model-invocation: true
---

# shippEdd review — verify it, then ship it

You are the orchestrator for the verify→ship half of the phase loop. You dispatch a fresh-context verifier to coverage-check the executed phase, read its report, and — this is your second half — when the verdict is green, ship in the same breath: commit the state dir, tick the roadmap, archive the phase, optionally push and open a PR. Between those halves sits the gap loop: gaps become fix plans written by the planner and executed by `/skill:implement`; you re-verify after. You are the only skill allowed to touch git remotely or mutate roadmap history.

`<state>` is the workflow state dir resolved in step 0; all other paths are relative to it or to the repo root. This skill is self-contained: its scripts (`scripts/state-dir.sh`, `scripts/dispatch.sh`) live in this folder. There is deliberately no `replay-commits.sh` here — gap fixes route through implement's commit machinery, never through review.

## Ground rules

1. **Orchestrate, don't labor** — verification runs in a detached fresh-context run; fix plans are written by the planner; implementation happens in executors. Review itself never implements, never fixes, never replays a commit. Your session carries the report digest and the ship receipt, never implementation detail.
2. **Markers are truth** — the verify run's state is its marker in `<state>/runs/`, never session memory. `/skill:review` may be re-run at any moment, mid-verify or mid-gap-loop; it reads state, it doesn't remember it.
3. **Every question uses exactly this format** (identical to bootstrap's, define's, implement's):

   ```
   ❓ <question>
     ➡️ 1. <recommended answer>
       2. <option>
       3. <option>
   ```

4. **Gaps route through implement** — a gap becomes a fix plan (`NN-FX1-PLAN.md`, …) that `/skill:implement` dispatches and replays like any wave; then the user re-runs `/skill:review` to re-verify. Keeping fixes out of review keeps the judge out of the implementation.
5. **Ship is gated** — shipping happens only on `## VERIFICATION PASSED` with zero unaccepted gaps. A gap the user explicitly accepts, with a reason, is recorded in VERIFICATION.md under `## Accepted gaps` and stops counting against the gate.
6. **Review owns the ship-time git surface** — commit tracked state-dir changes, tick ROADMAP, archive the phase, and (only if `gh` and a remote exist) push/PR/audit issue. Whether the state dir is tracked was bootstrap's decision: test with `git check-ignore`, never force-add an ignored state dir.
7. **Recommend and stop** — nothing auto-fires. The skill ends by naming the next command (`/skill:implement`, `/skill:define`, or `/skill:todo`). Never run it yourself.

## Step 0 — resolve the state dir

Run `scripts/state-dir.sh`. It prints exactly one line: the state dir path relative to the repo root (`$PLANNING_DIR` env → `.pi/planning.json` `state_dir` → `.planning`).

If that dir lacks both `STATE.md` and `ROADMAP.md`, no workflow state exists. Say:

> No workflow state found. Run `/skill:bootstrap` first — it creates the skeleton this skill reads.

Then stop.

## Step 1 — ORIENT

Read (never ask for) the state:

- `<state>/STATE.md` — where the loop stands; its body names the current phase (implement set it)
- `<state>/ROADMAP.md` — this phase's entry, its `Plans:` list, what comes next
- `<state>/phases/<NN>-<slug>/` — the phase folder: enumerate the `NN-*-PLAN.md` files. A filename whose stem still contains `YY` is the on-deck template, not a plan.
- `<state>/config.json` — `github.mirror_issues` (absent = off)

**Target phase**: the phase named in STATE.md's body; if STATE.md and the phase dir disagree, the dir wins — markers are truth. If that phase already lives under `phases/_archive/`, it shipped: recommend `/skill:define` (or `/skill:todo` if the roadmap is complete) and stop.

**Marker-gate every plan** — the phase is verifiable iff each of its `NN-YY` plans has `<state>/runs/NN-YY.done` carrying a `committed` line (that is implement's completion signature). Anything else — `.running` (live or stale), `.failed`, no marker — means execution isn't finished, and execution is implement's lane (waves, cleanup, commit replay all live there). Say:

> Phase `<NN>-<slug>` isn't fully executed yet — plan `<NN-YY>` has no committed `.done` marker. Run `/skill:implement` first; it owns wave gating, cleanup, and commit replay.

Then stop.

**Re-verify detection**: if the phase's `VERIFICATION.md` is a filled report (a real verdict line, no `<…>` placeholders — `define` leaves the raw template there), this is a re-entry after a gap loop; note it — the next verify run takes a suffixed id (step 2).

Report a two-line summary (phase, plans done+committed, prior verification if any), then dispatch.

## Step 2 — DISPATCH the verifier (background)

**Run id**: `<NN>-verify` if no `<NN>-verify*` marker exists in `<state>/runs/`; otherwise `<NN>-verify<k>` for the smallest `k ≥ 2` with no marker (first re-verify is `NN-verify2`, the next `NN-verify3`, …). The dispatcher's collision guard refuses duplicate ids — never `--force` over an existing verification; `--force` clears markers and is only ever for re-running a `.failed` verify of the same id (step 3).

Compose `<state>/runs/<id>.prompt.md` — a fully self-contained prompt (the detached run loads nothing else):

```
Read <repo-root>/.pi/agents/verifier.md and operate as that agent for the task below.

## Task
You are verifying phase <NN>-<slug> of the shippEdd workflow in this repo (repo root: <absolute path>).

Inputs:
- Phase goal: <one sentence, from ROADMAP's phase details>
- Phase dir: <state>/phases/<NN>-<slug>/ — <NN>-CONTEXT.md (settled decisions), every <NN>-<YY>-PLAN.md, every <NN>-<YY>-SUMMARY.md, and VERIFICATION.md if a prior round filled it (its `## Accepted gaps` section carries forward)
- Requirements: <state>/REQUIREMENTS.md — REQ-IDs mapped to this phase: <comma-separated REQ-IDs, or "none recorded">
- Roadmap: <state>/ROADMAP.md — this phase's entry (goal, requirements, success criteria)
- Commits: the `committed <sha>` lines in <state>/runs/<NN>-*.done markers — cross-check read-only with git log

Artifact: write <state>/phases/<NN>-<slug>/VERIFICATION.md, replacing what's there, per your persona's report contract.

## Completion contract
1. Write the artifact named above, fully, per its template.
2. Then run: mv <state>/runs/<id>.running <state>/runs/<id>.done
3. If you cannot complete: mv the marker to .failed and append a one-line reason to the marker file.
Your final message must end with the sentinel: ## VERIFICATION PASSED (or ## VERIFICATION FAILED / ## VERIFICATION BLOCKED)
```

Substitute the real repo root, state dir, phase, REQ-IDs, and run id into every path. The completion contract is canonical — copied verbatim from the define skill's, with only the run id, the `mv` paths, and the sentinel names substituted. If `.pi/agents/verifier.md` is not installed, stop and say so — the framework's personas travel in `.pi/agents/`.

Dispatch with `scripts/dispatch.sh <id> <state>/runs/<id>.prompt.md`, passing `--model <id>` **only if** `.pi/planning.json` has a `models.verifier` entry naming a concrete model id — an absent key (or a tier word like "strong", which is not a model id) means inherit the session default.

Report dispatch.sh's output line to the user verbatim, e.g.:

```
dispatched 01-verify (PID 1234) → .planning/runs/01-verify.log
```

Then tell the user they can walk away: re-run `/skill:review` at any time — when the marker has flipped it reads the verdict and continues from there; markers are truth, same as implement. Watching live: `bash <this skill's folder>/scripts/dispatch.sh --status`, `tail <state>/runs/<id>.log`. Stop — never wait, never poll.

## Step 3 — READOUT (on re-entry, marker `.done`)

Find the newest verify run for the phase (highest id suffix) and gate on its marker:

- **`.running` with a live PID** — report it as running, show the watch commands (`--status`, `tail`), and stop: re-run `/skill:review` to check again. Nothing waits here.
- **`.running` with a dead PID** — an aborted or crashed run; aborted runs never flip their markers. Offer cleanup: inspect the log (`tail <state>/runs/<id>.log`), then delete the stale marker — the next `/skill:review` dispatches a fresh verify. Stop.
- **`.failed`** — the verify couldn't run (a named input was missing). Show the marker's reason line, then:

  ```
  ❓ Verification couldn't run: <one-line reason from the marker>. What now?
    ➡️ 1. inspect — show the tail of <state>/runs/<id>.log and decide from there
      2. redispatch — dispatch.sh <id> <state>/runs/<id>.prompt.md --force (clears the failed marker, fresh verify of the same id)
  ```

- **`.done`** — read `<state>/phases/<NN>-<slug>/VERIFICATION.md` and present it compactly, never dump it:
  - the verdict line and the counts — `requirements X/Y covered · decisions A/B honored · verifies C/D passed`
  - one line per task verify: `<plan> <task> → ✅/❌`
  - gaps, numbered, each with its taxonomy and smallest fix
  - accepted gaps, if any, one line each

  If the verdict is PASSED with zero unaccepted gaps → step 5. Anything else → step 4.

## Step 4 — GAPS

```
❓ Verification found <N> unaccepted gap(s). What now?
  ➡️ 1. create fix plans — dispatch the planner to write <NN>-FX plan files; /skill:implement runs them like any wave
    2. fix manually — fix it outside this skill, then re-run /skill:review to re-verify
    3. accept gap(s) — name the number(s) and give your reason; each is recorded in VERIFICATION.md and stops counting against the ship gate
```

1. **Create fix plans** — dispatch the **planner** subagent (agent name `planner`, agentScope both) in the foreground with a self-contained prompt:

   ```
   Fix-plan phase <NN>-<slug> for the shippEdd workflow in this repo (repo root: <absolute path>).

   Inputs — read them all before writing:
   - Gaps: <state>/phases/<NN>-<slug>/VERIFICATION.md — the `## Gaps found` section is your spec; every gap must be covered by exactly one fix plan (gaps sharing a root cause may share one)
   - Context: <state>/phases/<NN>-<slug>/<NN>-CONTEXT.md — decisions, locked
   - Pattern: the phase's existing <NN>-<YY>-PLAN.md files — match their task-block shape exactly
   - Template: <state>/phases/_templates/NN-YY-PLAN.md (or .agents/skills/shippEdd/bootstrap/templates/NN-YY-PLAN.md if the stash is missing)

   Write one fix plan per gap: <NN>-FX1-PLAN.md, <NN>-FX2-PLAN.md, … continuing the numbering from any FX files already in the phase dir. Frontmatter: wave: <current max wave across the phase's plans> + 1, depends_on: []. Same task-block discipline as any plan: exact files, actions, runnable verify commands, acceptance criteria. Fix plans write files only — never STATE.md or ROADMAP.md.
   ```

   On return, check every gap is covered by a plan (a gap without a plan goes back to the planner), then update `<state>/STATE.md`: `next_action: /skill:implement`, `progress: planned`, body — "review: <N> gaps found — fix plans <ids> awaiting execution". Then:

   > Fix plans ready: `<ids>`. Next: `/skill:implement` to run them — then `/skill:review` again to re-verify.

   And stop.

2. **Fix manually** — stop. The user fixes outside the skill, then re-runs `/skill:review`; the fresh verify takes the next free run id (step 2), and the verifier re-checks the tree from scratch.

3. **Accept** — for each gap the user names, append a row to VERIFICATION.md (create the section if absent, after `## Gaps found`):

   ```
   ## Accepted gaps

   - Gap <n> (<taxonomy>): <gap title> — accepted <YYYY-MM-DD>: "<the user's reason, verbatim>"
   ```

   When every gap is accepted → step 5; otherwise re-ask the question for the remaining ones.

## Step 5 — SHIP

Runs only on `## VERIFICATION PASSED` or "every gap accepted" — never with an open gap. In order:

1. **Commit the state dir** (iff tracked). `git check-ignore -q <state>` — exit 0 means ignored: skip silently, bootstrap's git policy already decided, never force-add. Otherwise `git add -- <state>` and, if anything staged, `git commit -m "chore(<NN>-<slug>): verification + phase artifacts"`.
2. **ROADMAP** — tick the phase checkbox (`- [ ] **Phase <NN>:` → `- [x]`), tick its `Plans:` checkboxes, update its Progress-table row (`<N>/<N>`, `Shipped`, today's date), and advance `## Next up` to the next unchecked phase — or write `**none — roadmap complete**`.
3. **Archive** — `mkdir -p <state>/phases/_archive && mv <state>/phases/<NN>-<slug> <state>/phases/_archive/<NN>-<slug>`. The `_` prefix marks it non-live, matching `_templates/`.
4. **STATE.md** — frontmatter: `next_action: /skill:define`, `progress: shipped`. Body: the phase, `shipped — <verdict line; accepted gaps if any>`, and the next phase (or "roadmap complete").
5. **Commit the ship mutations** — same tracked check as (1): `git add -- <state>` and, if anything staged, `git commit -m "chore(<NN>-<slug>): ship — tick roadmap, archive phase"`.
6. **Push / PR** — only if `command -v gh` succeeds **and** `git remote` is non-empty; otherwise one line — "no gh or no git remote — commits stay local" — and skip:

   ```
   ❓ Push and open a PR for this phase?
     ➡️ 1. create PR — push the branch and open a pull request; body = the phase digest
       2. just push — push the branch, no PR
       3. neither — leave the commits local
   ```

   The **phase digest** (PR title/body) is built from the phase's SUMMARY files (frontmatter `provides` + Accomplishments) plus the verification verdict (the counts and any accepted gaps). Title: `Phase <NN>-<slug>: <goal>`.
7. **Audit issue** — iff `<state>/config.json` has `"github": { "mirror_issues": true }` **and** gh + remote exist: create one issue titled `Phase <NN>-<slug>: shipped` with the digest body, then close it immediately as completed (`gh issue close <n> --reason completed`). It is an audit record, not workflow state — one line in the receipt.

Then present the **ship receipt**:

```
Phase <NN>-<slug> — shipped
  commits   <k> (the committed lines in the phase's run markers)
  PR        <url, or "—">
  archive   <state>/phases/_archive/<NN>-<slug>
  next up   <next phase — start with /skill:define, or "roadmap complete">
```

## Step 6 — handoff

If a next unchecked phase exists on the roadmap:

> Phase `<NN>-<slug>` shipped — <one line: verdict, PR if any>. Next: `/skill:define` for `<next phase>`.

If the roadmap is complete:

> Phase `<NN>-<slug>` shipped — that was the last one. Next: `/skill:todo` to bank what comes next (or `/skill:define` to mint a new phase from a one-line intent).

Then stop (rule 7).
