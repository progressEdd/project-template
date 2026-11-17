# shippEdd — the flow map

A hand-written map, not generated: six skills, one main flow, a few on-ramps. Find your situation, type the command on that line. `/skill:wayfind` reads this file and renders the line that matches your position — editing this file is the whole cost of changing the router.

## Main flow

One loop, travelled once per phase: **define → implement → review → define** (next phase). bootstrap runs once at the start.

- **/skill:bootstrap** — creates the state dir, skeleton, toggles, model tiers. *Go there when* no state dir exists yet — or to repair the skeleton / change a setting (idempotent: fills gaps, never overwrites).
- **/skill:define** — grills the phase into decisions (CONTEXT.md), dispatches background research, returns approved plan files. *Go there when* the roadmap's next phase isn't planned yet: no decisions on file, no plan files, or a replan is wanted.
- **/skill:implement** — runs approved plans as background waves, one detached executor per plan, then replays their recorded commits in plan order. *Go there when* plans are approved and not every plan marker reads `.done` + `committed`.
- **/skill:review** — verifies coverage with a fresh-context verifier, walks gaps into fix plans, and ships when green: commits, archives the phase, ticks the roadmap, optional PR. *Go there when* every plan of the phase is `done`+`committed` — and again after any gap-fix loop.

## On-ramps

Situations that drop you onto the flow mid-stream:

- **An idea strikes mid-phase** → `/skill:todo` — parks it as a numbered todo in one line, no derail. Promote a batch into a new roadmap phase when they pile up.
- **You're lost, or a new session just started** → `/skill:wayfind` — reads the state dir, renders position + runs + the one command to type. Never advances anything.
- **The skeleton is damaged or a toggle needs changing** → rerun `/skill:bootstrap` — same entry point as fresh setup, repair semantics.

## Loop notes

- **Gap fixes never leave the loop**: review finds a gap → the planner writes a fix plan (`NN-FX1-PLAN.md`) → `/skill:implement` runs it like any wave → `/skill:review` re-verifies. The judge never implements.
- **Accepted gaps ship**: a gap you accept with a reason is recorded in VERIFICATION.md under `## Accepted gaps` and stops counting against the ship gate.
- **Phases advance only via explicit skill invocation.** Nothing auto-fires; every skill ends by naming the next command and stopping. Even a finished roadmap waits to be typed at.

## Session hygiene

- The filesystem is the state: markers in `<state>/runs/`, files in `phases/<NN>-<slug>/`, checkboxes in ROADMAP.md. That is the entire loop position.
- A fresh session loses nothing — every skill re-reads state from disk before acting; none of them remember.
- Heavy work (research, execution, verification) runs detached and flips its own markers, so session age barely matters. To stop a run, kill the PID recorded in its `.running` marker; a stale `.running` means aborted, and the next skill visit offers cleanup.

## Adding a skill

Add a line to the section above that fits it — that's the whole router maintenance burden.
