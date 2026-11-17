## What it does

`/skill:bootstrap` is the once-per-repo onboarding wizard for shippEdd. It detects what it can from the repo (git state, existing planning dirs, `gh` availability, greenfield vs brownfield), walks you through the few decisions it can't make for you — where workflow state lives, which toggles and model tiers, git policy, optional GitHub mirroring — then, after showing you the complete write list and getting a yes, creates the planning skeleton (`ROADMAP.md`, `STATE.md`, `REQUIREMENTS.md`, `config.json`, phase templates, todo/probe/run folders), appends a `## Workflow` block to `AGENTS.md`, and points you at `/skill:define`.

## When to reach for it

- Starting shippEdd in any repo, greenfield or brownfield.
- Adopting an existing planning state dir (`.planning/` or a GSD-style `.gsd/`) — the wizard detects markers and offers to adopt or rename.
- Something feels off after cloning a repo that uses shippEdd — rerun it: it verifies the skeleton and repairs gaps without touching your content.

## Prerequisites

- A git repo. Without one the wizard still runs, but the git/GitHub steps are skipped.
- The `gh` CLI, authenticated — only if you want phases mirrored to GitHub issues. Otherwise this question never appears.

Nothing else: no packages, no build step. Markdown plus one bash script.

## Common questions

**Can I move the state dir later?**
Yes — edit `state_dir` in `.pi/planning.json` (or export `PLANNING_DIR` for a session) and move the folder. Everything resolves through `scripts/state-dir.sh`; the toggles in `config.json` travel with the state dir.

**Why is there no `.pi/planning.json` after setup?**
Absent = default. The file only exists when you chose something non-default (a custom state dir or model tiers). No choices made, no file written.

**Will rerunning break my planning files?**
No. A rerun detects existing state, reports what's missing, and offers to create only the gaps. Existing files are never overwritten.

## It's working if

- Running `scripts/state-dir.sh` prints exactly one line — the state dir (`$PLANNING_DIR` → `.pi/planning.json` → `.planning`).
- The state dir contains `ROADMAP.md`, `STATE.md`, `REQUIREMENTS.md`, `config.json`, `README.md`, `todos/`, `codebase/` (4 stubs), `runs/`, and `phases/_templates/` (5 phase templates).
- `AGENTS.md` gained a `## Workflow` block naming the state dir and the "phases advance only via explicit skills" rule — with all prior content intact.
- `.pi/planning.json` exists only if a non-default choice was made.
- Rerunning `/skill:bootstrap` offers verify/repair and writes nothing you already wrote.

## Where it fits

Role: run-once setup — the front door of shippEdd. It creates the state every other skill reads; nothing else creates it. Neighbours: `/skill:define` is the immediate next step (bootstrap ends by naming it), and `/skill:wayfind` is the compass if you come back to a repo later and feel lost.
