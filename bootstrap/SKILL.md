---
name: bootstrap
description: One-time setup wizard for shippEdd, the phase-loop workflow (plan → execute → verify → ship) — detects the repo, chooses the workflow state dir, writes the planning skeleton, wires the subagent personas into .pi/agents/, configures toggles and model tiers, and wires AGENTS.md. Run /skill:bootstrap once per repository.
disable-model-invocation: true
---

# shippEdd bootstrap — once per repo, idempotent

You are running an interactive wizard. You read the repo, ask the user only what cannot be detected, then — after one explicit confirmation — write the workflow skeleton. You are the only skill that creates the state dir; every other skill reads it.

All paths below are relative to this skill's folder (`scripts/`, `templates/`, `personas/`).

## Ground rules

1. **Detect, never ask** — anything readable from the repo is a fact. Only genuinely undetectable preferences become questions.
2. **One question at a time**, grilling-style but short. Every question uses exactly this format:

   ```
   ❓ <question>
     ➡️ 1. <recommended answer>
       2. <option>
       3. <option>
   ```

   The ➡️ line is your recommendation; the user may answer by number or free text.
3. **Zero side effects before the confirmation gate** — everything above the gate is reading and asking. No file is created, modified, or committed until the user approves the complete write list (see *Confirmation gate*).
4. **Repair, never overwrite** — existing files are read and left alone. Templates fill gaps only; `<placeholders>` inside an existing file belong to its author.
5. **Absent = default** — write config only for non-default choices (see *Persistence rules*).
6. **Recommend and stop** — the wizard ends by naming the next command (`/skill:define`). Never run it yourself.

## Step 0 — resolve the state dir

Run `scripts/state-dir.sh`. It prints exactly one line: the state dir path relative to the repo root (`$PLANNING_DIR` env → `.pi/planning.json` `state_dir` → `.planning`). That is the *current* resolution; step 2 below may decide to change what gets persisted.

## Step 1 — DETECT (facts, not questions)

Gather all of this quietly before asking anything:

- **Repo root**: `git rev-parse --show-toplevel` (if this fails, treat as non-git and skip git/github steps later)
- **Tracked files**: `git ls-files | wc -l` and a sample — enough to judge greenfield (empty/skeleton repo) vs brownfield (real code tracked)
- **Existing workflow state**: dirs containing both `STATE.md` and `ROADMAP.md` — probe `.planning/` and `.gsd/` directly, plus `git ls-files | grep -E '(STATE|ROADMAP)\.md$'` for any git-tracked candidates
- **`.pi/planning.json`**: exists? what `state_dir` / `models` keys does it carry?
- **`.pi/agents/`**: which of `planner` / `researcher` / `executor` / `verifier` exist; diff any that exist against `personas/<name>.md` in this skill folder (no `personas/` folder = dev install — see step 3b)
- **`$PLANNING_DIR`**: set in the environment?
- **GitHub**: `command -v gh` and `gh auth status`; `git remote` (only if git detected)
- **`AGENTS.md`**: exists? already contains a `## Workflow` heading?

Report a two-line summary of what you found (repo type, existing state, gh availability), then move to step 2. If this is a **rerun** (state markers already exist), jump to *Rerun behavior* instead of the fresh wizard.

## Step 2 — STATE DIR

Discovery order — stop at the first case that applies:

**a. `.pi/planning.json` exists (with a `state_dir`):**
```
❓ Keep the existing state dir `<dir>` (from .pi/planning.json)?
  ➡️ 1. keep it
    2. change it → treat as case d
```

**b. `$PLANNING_DIR` is set (and a says nothing):** the env var wins for this session but is ephemeral —
```
❓ `$PLANNING_DIR=<dir>` is session-only. Persist it to .pi/planning.json so it sticks?
  ➡️ 1. yes — write it to .pi/planning.json
    2. no — keep it env-only (you must export it every session)
```

**c. State markers found (STATE.md + ROADMAP.md together) in `.planning/`, `.gsd/`, or a git-tracked dir:**
```
❓ Adopt `<dir>` as the shippEdd state dir?
  ➡️ 1. adopt, keep the name `<dir>` (persist to .pi/planning.json)
    2. adopt, but rename to `.planning` (git mv — keeps history)
    3. ignore it, choose a fresh location → case d
```
Adopting GSD-style state is safe — shippEdd templates are near-verbatim descendants; only fill gaps.

**d. Fresh (nothing found):**
```
❓ Where should workflow state live?
  ➡️ 1. `.planning` (default)
    2. custom path
```

Persist `state_dir` to `.pi/planning.json` **only** if the resolved dir ≠ `.planning`.

## Step 3 — SKELETON (planned now, written after confirmation)

The skeleton copies from `templates/` into the state dir:

| From `templates/` | To state dir | Notes |
|---|---|---|
| `ROADMAP.md` | `<state>/ROADMAP.md` | fill `<project-name>` if detectable |
| `STATE.md` | `<state>/STATE.md` | — |
| `REQUIREMENTS.md` | `<state>/REQUIREMENTS.md` | — |
| `config.json` | `<state>/config.json` | toggle values exactly as chosen in step 4 |
| `README.md` | `<state>/README.md` | documents every file + the absent=enabled convention |
| `todos/PENDING-TODO.md` | `<state>/todos/PENDING-TODO.md` | also create empty `<state>/todos/pending/` |
| `codebase/stack.md` … `testing.md` | `<state>/codebase/` | four stub probes |
| `runs/.gitkeep` | `<state>/runs/.gitkeep` | — |
| `NN-CONTEXT.md`, `NN-RESEARCH.md`, `NN-YY-PLAN.md`, `NN-YY-SUMMARY.md`, `VERIFICATION.md` | `<state>/phases/_templates/` | copied + renamed per phase by `define`/`implement` |

Repair semantics: a destination file that already exists is **left untouched**; only missing files are created. `todos/PENDING-TODO.md` is the note template `/skill:todo` copies to `todos/pending/<NN-slug>.md`.

## Step 3b — PERSONAS (repo wiring, written after confirmation)

The four subagent personas — planner, researcher, executor, verifier — power every skill that dispatches subagents. Pi discovers skills from `.agents/skills/` but not `.pi/agents/` content, so the personas travel inside this skill (`personas/*.md`) and bootstrap wires them into the repo — one folder-copy is then enough to adopt the whole harness. Using the diffs already gathered in step 1:

- **Missing from `.pi/agents/`** → copy `personas/<name>.md` in.
- **Identical** → nothing to do.
- **Different** → repair semantics: show the diff, offer replace-or-keep. Never silently overwrite.

No question is asked — this is detection plus action, and every write appears in the confirmation gate. If this skill folder has no `personas/` (a hand-rolled install), report "personas already wired" and skip.

## Step 4 — TOGGLES

One question, recommended combo first:
```
❓ Workflow toggles — go with the recommended set?
  ➡️ 1. recommended: research ON · UI phase OFF · UI safety gate ON
    2. customize (I'll then ask one toggle at a time)
```
Chosen values are written explicitly to `<state>/config.json` → `workflow`. (Convention: any key *absent* from config means **enabled** — but `ui_phase` defaults to off at setup, so it is always written explicitly.)

## Step 5 — TIERS

```
❓ Model tiers for subagents — use defaults?
  ➡️ 1. defaults: researcher = cheap/fast model · planner + verifier = strongest · executor = default model
    2. customize (name a model id per role, one at a time)
```
Defaults write nothing (absent = default). Custom tiers persist to `.pi/planning.json` → `models: { researcher, planner, verifier, executor }` — write **only the roles the user actually changed**.

## Step 6 — GIT

```
❓ Commit the state dir to git?
  ➡️ 1. commit (the paper trail is the point — plans, summaries, verification age with the code)
    2. ignore it (append the state dir to .gitignore)
```

## Step 7 — GITHUB (only if `gh` + remote detected; otherwise skip silently)

```
❓ Mirror phases as GitHub issues when a phase ships?
  ➡️ 1. skip (local-first; can enable later)
    2. mirror — `/skill:review` will open/close issues per phase
```
If mirror: add `"github": { "mirror_issues": true }` to `<state>/config.json`. Absent key = skip.

## Step 8 — HANDOFF

- **Brownfield**: offer the 4 codebase probes now:
  ```
  ❓ Run the 4 codebase probes (stack / architecture / conventions / testing) now?
    ➡️ 1. yes — dispatch 4 parallel researcher subagents to fill <state>/codebase/
      2. later — stubs stay; fill them via /skill:wayfind anytime
  ```
  If the researcher persona is still not usable after step 3b (the user kept a differing existing file), say so and offer to fill the stubs inline instead.
- **Either way**, end with (and do not run it yourself):

  > Setup complete. Next: `/skill:define` to grill out your first phase.

## Confirmation gate

Before any write, show the complete list:

```
I will create/modify:
  STATE DIR  <dir>
    create   <each new file path>
    repair   <each missing template in an existing skeleton — existing files untouched>
  PERSONAS
    create   .pi/agents/<name>.md   (each missing persona) — or: none, all wired
    replace  .pi/agents/<name>.md   (only a differing persona the user chose to replace)
  CONFIG
    write    .pi/planning.json   (only the non-default keys chosen) — or: none, all defaults
    write    <state>/config.json (toggles [+ github])
    append   AGENTS.md — "## Workflow" block   (or: merge — block already exists)
  GIT
    commit   "chore: shippEdd setup"   |   append .gitignore entry

❓ Proceed?
  ➡️ 1. yes — write it all
    2. adjust something first
```

Then execute in that order, and finally show the handoff line from step 8.

## The AGENTS.md Workflow block

Append this block to the repo's `AGENTS.md` (create the file if absent). If a `## Workflow` section already exists, merge: update only the shippEdd bullets, keep all unrelated content.

```markdown
## Workflow

This repo runs **shippEdd** — a phase loop (discuss → research → plan → execute → verify → ship) driven by explicit skills.

- Workflow state lives in `<state-dir>/`. `ROADMAP.md` is the source of truth for what's next; `STATE.md` frontmatter (`next_action`, `progress`) is the machine-read surface.
- Phases advance **only** via explicit skills: `/skill:define`, `/skill:implement`, `/skill:review`. Nothing auto-fires.
- Stray work → `/skill:todo`. Lost → `/skill:wayfind`.
```

(Resolve `<state-dir>` to the chosen dir before writing.)

## Persistence rules

| Choice | Written to | When |
|---|---|---|
| state dir ≠ `.planning` | `.pi/planning.json` → `state_dir` | only non-default |
| model tier overrides | `.pi/planning.json` → `models.<role>` | only changed roles |
| workflow toggles | `<state>/config.json` → `workflow` | always (explicit values) |
| github mirror | `<state>/config.json` → `github.mirror_issues` | only if chosen |
| everything default | **no `.pi/planning.json` at all** | absent = default |

If `.pi/planning.json` already exists, merge: update only the keys decided in this wizard, never remove or rewrite unknown keys.

## Rerun behavior (idempotent)

If state markers already exist when you reach step 1, skip the fresh wizard:

1. Report what was found: state dir, a persona check (missing or differing personas, per step 3b), and a skeleton check listing any missing template files.
2. ```
   ❓ Repair the skeleton and wire missing personas?
     ➡️ 1. yes — create only the missing files (a differing persona gets a diff and a replace-or-keep choice first)
       2. no — leave everything as is
   ```
3. Show the current config (state dir, tiers, toggles) and offer to change any single setting.
4. Never overwrite user content. Only re-run the full wizard if the user explicitly asks to "start over".
