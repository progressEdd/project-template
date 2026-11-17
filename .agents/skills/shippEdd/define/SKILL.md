---
name: define
description: Plan the next roadmap phase — grills you in short rounds (max 3 questions each) until decisions settle into CONTEXT.md, runs research for open factual questions, then a planner subagent drafts executable plan files for your approval. Run /skill:define after setup, or whenever a phase needs planning or replanning.
disable-model-invocation: true
---

# shippEdd define — grill it, then plan it

You are the orchestrator for the discuss→plan half of the phase loop. You interview the user, dispatch research and planning to fresh-context subagents, and keep this session lean: decisions enter your context, research and implementation detail do not. You never advance past approval on your own — the user approves the plans, then you name the next command and stop.

`<state>` is the workflow state dir resolved in step 0; all other paths are relative to it or to the repo root. This skill is self-contained: its scripts (`scripts/state-dir.sh`, `scripts/dispatch.sh`) live in this folder, and phase templates come from the state dir's own stash (step 2).

## Ground rules

1. **Orchestrate, don't labor** — research and planning run in subagents with fresh context. Your context carries decisions and digests only.
2. **Every question uses exactly this format** (identical to bootstrap's):

   ```
   ❓ <question>
     ➡️ 1. <recommended answer>
       2. <option>
       3. <option>
   ```

   The ➡️ line is your recommendation; the user may answer by number or free text. If your recommendation argues against the premise of your own question, reword the question first — agreeing must mean yes.
3. **Facts are yours, decisions are the user's** — anything readable from the repo, the state dir, or resolvable by a subagent is a fact you resolve without asking. Only genuine preferences become questions.
4. **Decisions land in CONTEXT.md as they settle** — never batched at the end. The decisions table is the durable record; a lost session loses nothing.
5. **Absent = default** — a missing config key means the feature is enabled; a missing file means the default path.
6. **Recommend and stop** — the skill ends by naming the next command (`/skill:implement`). Never run it yourself.

## Step 0 — resolve the state dir

Run `scripts/state-dir.sh`. It prints exactly one line: the state dir path relative to the repo root (`$PLANNING_DIR` env → `.pi/planning.json` `state_dir` → `.planning`).

If that dir lacks both `STATE.md` and `ROADMAP.md`, no workflow state exists. Say:

> No workflow state found. Run `/skill:bootstrap` first — it creates the skeleton this skill reads.

Then stop.

## Step 1 — ORIENT

Read (never ask for) the state:

- `<state>/STATE.md` — where the loop stands
- `<state>/ROADMAP.md` — the source of truth for what's next
- `<state>/config.json` — workflow toggles (absent file = all defaults)
- `<state>/codebase/*.md` — the codebase map, if bootstrap ran the probes (skim it now; step 4 points research at it)

**Determine the target phase**: the phase named under ROADMAP's `## Next up` if it is unchecked under `## Phases`; otherwise the first unchecked phase there.

- **No unchecked phase remains:**
  ```
  ❓ The roadmap has no open phases. Create a new one from what you want to work on next?
    ➡️ 1. yes — tell me in a sentence what it should deliver; I'll add it as Phase <NN>
      2. no — stop here
  ```
  On yes: derive a short slug and one-line goal from the answer, append the phase to `## Phases` and a matching `### Phase <NN>` details block (goal, requirements "from grilling", empty `Plans:` list) to ROADMAP, and point `## Next up` at it. `<NN>` is the next integer, zero-padded to two digits. Then continue.
- **Resume**: if the target phase's folder already exists, read its `NN-CONTEXT.md` decisions table and any `NN-*-PLAN.md` files. Settled decisions are locked — never re-ask them. A phase that already has plans gets one question: replan (your edits go to the planner, step 6) or stop and head for `/skill:implement`.

Report a two-line summary (phase target, toggles in effect), then scaffold.

## Step 2 — SCAFFOLD

Create the phase folder and seed it by copying the templates — copy, don't generate:

```bash
mkdir -p <state>/phases/<NN>-<slug>/
cp <templates>/NN-CONTEXT.md     <state>/phases/<NN>-<slug>/<NN>-CONTEXT.md
cp <templates>/NN-RESEARCH.md    <state>/phases/<NN>-<slug>/<NN>-RESEARCH.md
cp <templates>/NN-YY-PLAN.md     <state>/phases/<NN>-<slug>/<NN>-YY-PLAN.md
cp <templates>/NN-YY-SUMMARY.md  <state>/phases/<NN>-<slug>/<NN>-YY-SUMMARY.md
cp <templates>/VERIFICATION.md   <state>/phases/<NN>-<slug>/VERIFICATION.md
```

Template source, in order: `<state>/phases/_templates/` (the stash bootstrap wrote); if missing, `.agents/skills/shippEdd/bootstrap/templates/` (repo-relative); if both are missing, stop and recommend rerunning `/skill:bootstrap` (it repairs the skeleton without touching existing content).

Replace every `NN` / `<NN-slug>` placeholder in the copied names and contents with the phase's number and slug. `YY` placeholders are kept: `NN-YY-PLAN.md` and `NN-YY-SUMMARY.md` are the on-deck templates the planner and the executors instantiate — a filename still containing `YY` is a template, never an artifact. Files that already exist in the phase folder are left untouched (repair, never overwrite).

Fill the CONTEXT header now: phase goal in one sentence (from ROADMAP's phase details, or leave for grilling to settle if blank) and today's date.

## Step 3 — GRILLING (inlined — never delegate this)

Interview the user until you share a complete understanding of the phase. The grilling primitive is inlined here on purpose: delegating an interview to a wrapper skill is the single most documented failure of the pattern this comes from. There is no wrapper.

**The law: at most 3 questions per round.** Each round asks up to 3 questions, chosen highest-leverage first — a question whose answer unblocks the most downstream decisions goes earliest. Frontier questions that don't make the cut carry over to the next round: carry them, never drop them.

### The frontier

Map the phase as a **design tree**: every decision branches into the decisions hanging off it. The **frontier** is every open question whose prerequisites are already settled — the questions you can ask now without guessing at answers you haven't heard. A question whose answer depends on another question still open belongs to a later round, not this one.

Each round of answers reshapes the tree: settled decisions push the frontier outward and unblock what hung off them. Recompute the frontier after every round.

**Facts vs decisions:**

- **Facts are your job.** Anything readable from the repo, the state dir, or a quick lookup never becomes a question — read it yourself or dispatch a subagent to find it. Don't block the round on a running lookup: an unresolved fact is just an unsettled prerequisite, so only the questions downstream of it wait; ask the rest of the frontier now. A fact too big for a quick lookup isn't a question either — park it in the ledger; step 4 researches it.
- **Decisions are the user's.** Put each to them in the question format and wait. An agent running grilling that answers its own decisions has broken the skill.

### A round

Show the **question ledger** first — the visible running list that makes carried-over questions impossible to lose:

```
Ledger — ✓ 2 settled · ⏳ 3 open · ⏸ 1 parked
  ✓ what "done" means for this phase  → demoable login flow
  ✓ error-handling policy             → surface, never swallow
  ⏳ session storage choice
  ⏳ rate limiting: yes/no, and where
  ⏳ token expiry semantics
  ⏸ exact refresh-rotation rules — parked on: library research (step 4)
```

Then up to 3 questions, numbered so the user can answer "Q1: 2, Q3: free text":

```
❓ Q1 — <question>
  ➡️ 1. <recommended answer>
    2. <option>
    3. <option>

❓ Q2 — <question>
  ➡️ 1. <recommended answer>
    2. <option>
```

### Recording decisions — as they settle

After each round, update `<state>/phases/<NN>-<slug>/<NN>-CONTEXT.md` immediately (never batched at the end):

- **Decisions table** — one row per settled question: `# | Question | Decision | Why`
- **Constraints** — hard constraints surfaced by answers ("no breaking changes to the existing API")
- **Open questions** — facts parked on research (these feed step 4), or "none — frontier is clear"

### Termination

The frontier is empty when every branch of the tree is visited and nothing is silently assumed. Then exactly one confirmation round:

```
❓ That's everything I have — anything I missed or got wrong?
  ➡️ 1. no — lock CONTEXT.md and move on
    2. yes — raise it (free text)
```

Free-text answers may reopen the frontier; recompute and keep going until a clean confirmation. Never start research or planning before that confirmation lands.

## Step 4 — RESEARCH (conditional, background-first)

Run this step iff `config.json` → `workflow.research` is enabled (absent key = enabled; absent file = enabled) **and** grilling left factual questions open in CONTEXT.md. If research is off, or the frontier resolved every fact, delete the scaffolded `<NN>-RESEARCH.md` — an unfilled template would falsely mark research as done — and skip to step 5.

Research always runs in an isolated context; your session never carries the research detail. One question picks the mode:

```
❓ Run the research in the background or the foreground?
  ➡️ 1. background — dispatch it and keep going; it flips its own marker when done, and you can walk away
    2. foreground — watch it stream here before continuing
```

### Background (the recommended path)

Compose a self-contained prompt file at `<state>/runs/<id>.prompt.md`, where the run id is `<NN>-research` (e.g. `01-research`). Background runs load no personas from `.pi/agents/` — a detached `pi --print` run carries its persona in its prompt file. The prompt points at the persona file as the single source of truth (never a copy of it), states the task, and ends with the completion contract:

```
Read <repo-root>/.pi/agents/researcher.md and operate as that agent for the task below.

## Task
You are researching phase <NN>-<slug> for the shippEdd workflow in this repo (repo root: <absolute path>).

Answer these questions, gathered during grilling:
<each open factual question from CONTEXT.md, numbered>

Inputs:
- Phase context: <state>/phases/<NN>-<slug>/<NN>-CONTEXT.md — decisions already made; don't revisit them
- Codebase map, if present: <state>/codebase/*.md — read it before grepping the repo
- Roadmap: <state>/ROADMAP.md — this phase's goal and requirements

Artifact: write your findings to <state>/phases/<NN>-<slug>/<NN>-RESEARCH.md, replacing the template already in place, per your persona's MODE A contract.

## Completion contract
1. Write the artifact named above, fully, per its template.
2. Then run: mv <state>/runs/<id>.running <state>/runs/<id>.done
3. If you cannot complete: mv the marker to .failed and append a one-line reason to the marker file.
Your final message must end with the sentinel: ## RESEARCH COMPLETE (or ## RESEARCH BLOCKED)
```

The **completion contract is canonical** — future skills (implement's executor waves) copy it verbatim, substituting only the real state dir and run id into the `mv` paths. The run flips its own marker; nothing waits on it or post-processes it.

Dispatch with `scripts/dispatch.sh <id> <state>/runs/<id>.prompt.md`, passing `--model <id>` **only if** `.pi/planning.json` has a `models.researcher` entry naming a concrete model id — an absent key (or a tier word like "cheap", which is not a model id) means inherit the session default. Report dispatch.sh's output line to the user verbatim, then **continue the skill without waiting**: step 5 grilling and plan prep proceed while research runs; its findings enter your context only when you read the finished artifact.

**The marker gate** — RESEARCH.md is an input to the planner (step 6) and to plan approval (step 7), so before dispatching the planner, check the run's marker:

- `<state>/runs/<id>.done` — read `NN-RESEARCH.md` and digest three bullets (strongest findings, biggest risk, unanswered questions) into your context; put any decision the findings force to the user in the question format — research recommends, the user decides. Proceed.
- `.running` with a **live** PID — pause: say research is still running, how to watch it (`bash <this skill's folder>/scripts/dispatch.sh --status`, or `tail <state>/runs/<id>.log`), and that planning resumes the moment the marker flips. Do not dispatch the planner without it.
- `.failed` — read the one-line reason appended to the marker; put recovery to the user (clear the blocker and redispatch, or rerun in the foreground).
- `.running` with a **dead** PID — an aborted or crashed run: aborted runs never flip their markers. Offer cleanup: inspect the log, then delete the stale marker and, if wanted, redispatch.

### Foreground

Spawn the **researcher** subagent (agent name `researcher`, agentScope both) with the same task as the prompt file above, minus the completion contract — a foreground run streams its reply back and needs no markers. On return: same digest discipline (three bullets, forced decisions to the user), then continue.

## Step 5 — UI SPEC (conditional)

Run this step iff `config.json` → `workflow.ui_phase` is enabled (`true`; absent key = enabled by the absent-means-default law — though bootstrap always writes this key explicitly, so an absent key usually means a hand-rolled state dir worth flagging). If disabled, skip to step 6.

One short grilling round — the 3-question law still applies — over the UI surfaces this phase touches. For each surface the phase will present to a user, settle: which surfaces exist (CLI output? screen? dialog? none?), the one-line shape of each, and the polish bar for this phase. Terminate with the same confirmation question.

Append the settled results to `<NN>-CONTEXT.md` as a section (no separate template yet):

```markdown
## UI Spec

| Surface | Shape | Polish bar |
|---|---|---|
| <e.g. `/login` screen> | <one line: layout + primary action> | <e.g. "functional, unstyled" / "matches existing design system"> |
```

## Step 6 — PLAN (dispatch the planner)

If background research ran for this phase, pass the marker gate in step 4 first — the planner consumes `NN-RESEARCH.md`, so a `.running` marker means wait (or pause with the status commands), `.failed` or a stale marker means resolve before planning.

Dispatch the **planner** subagent (agent name `planner`, agentScope both) in the foreground with a self-contained prompt:

```
Plan phase <NN>-<slug> for the shippEdd workflow in this repo.

Inputs — read them all before writing:
- Phase goal: <one sentence, from CONTEXT.md / ROADMAP>
- Phase dir: <state>/phases/<NN>-<slug>/ — <NN>-CONTEXT.md (locked decisions, constraints, UI spec) and <NN>-RESEARCH.md if present
- Plan template: <state>/phases/<NN>-<slug>/<NN>-YY-PLAN.md — instantiate it as <NN>-01-PLAN.md, <NN>-02-PLAN.md, … one file per plan
- Roadmap: <state>/ROADMAP.md — this phase's requirements and success criteria
- Repo context: <state>/codebase/*.md if present; AGENTS.md if present
- Requirements: <REQ-IDs from ROADMAP's phase details, or "none recorded">

Rules: write plan files only — never STATE.md or ROADMAP.md. Follow your persona's output contract exactly.
```

What comes back, and what to check:

- One `<NN>-YY-PLAN.md` per coherent unit of work — vertical slices preferred (one feature cut through all its layers beats a horizontal layer-plan); 2–3 tasks per plan; multiple plans (`01-01`, `01-02`, …) with `wave` + `depends_on` computed across them.
- Task blocks with concrete identifiers — exact files, actions, runnable verify commands. Vagueness goes back for a rewrite, not a patch from you.

If the planner reports `## PLAN BLOCKED` (missing decisions, contradictory inputs), put each gap to the user in the question format, record answers in CONTEXT.md, and redispatch. Never edit plan substance yourself — edits go back to the planner.

On success, remove the phase's leftover `<NN>-YY-PLAN.md` on-deck template (the real plans replace it; `<NN>-YY-SUMMARY.md` stays — executors instantiate it per plan).

## Step 7 — APPROVE

Present the plan(s) compactly — never dump full plan text. For each plan:

```
Plan 01-01 — <title>  (wave 1, no deps)
  Objective: <one line>
  Tasks: <task name>; <task name>; <task name>
  Verify: <the runnable verify commands>
```

Plus one line of wave structure: `wave 1: 01-01, 01-02 · wave 2: 01-03 (needs 01-01)`.

Approval requires the research digest if research ran: the marker gate (step 4) should already have put it in front of the user. If the run is somehow still `.running` here, pause — show how to check (`scripts/dispatch.sh --status`, `tail <state>/runs/<id>.log`) and resume when the marker flips; never approve plans whose research input hasn't landed.

```
❓ Approve these plans?
  ➡️ 1. approve — lock them in and update the state
    2. edit — name the change; it goes back to the planner (step 6) and returns here
```

On approval:

- `<state>/STATE.md` — frontmatter: `next_action: /skill:implement`, `progress: planned`. Body: the phase name and a one-line status ("planned — N plans in M waves, awaiting execution").
- `<state>/ROADMAP.md` — fill this phase's `Plans:` list with the approved plan IDs and one-liners. Never tick phase checkboxes — completing phases is `/skill:review`'s job, not yours.

## Step 8 — handoff

> Phase `<NN>-<slug>` planned — <N> plans in <M> waves. Next: `/skill:implement` to run wave 1.

Then stop (rule 6). Do not run it yourself.
