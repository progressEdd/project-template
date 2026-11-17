## What it does

`/skill:review` closes a phase. It dispatches a fresh-context verifier as a detached background run — a session that never watched the implementation and trusts nothing but the tree. The verifier traces every REQ-ID mapped to the phase and every decision in its CONTEXT.md to real evidence, actually runs every plan task's verify command (a SUMMARY that says "done" proves nothing), and writes `VERIFICATION.md` with a coverage table per check, a per-task verify table, and a classified gap list (missing / partial / deviated — each with evidence and a smallest-fix pointer). Back in your session, review reads the report and shows you the digest. Gaps become fix plans: the planner writes `NN-FX1-PLAN.md` files, `/skill:implement` runs them like any wave, and you re-run `/skill:review` to re-verify — or you accept a gap with a reason and it's recorded, not argued. When the verdict is green (`PASSED`, or every gap accepted), review ships in the same breath: commits the state dir (iff tracked), ticks the roadmap, archives the phase to `phases/_archive/`, updates STATE.md, and — only if `gh` and a remote exist — asks one push/PR question and files an optional closed audit issue. You get a ship receipt: commits, PR, archive path, next up.

## When to reach for it

- `/skill:implement` finished every plan — its handoff names review. That's the normal entry.
- A fix loop just ran (fix plans executed) — re-run review; the fresh verify takes the next run id (`01-verify2`, `01-verify3`, …).
- A verify run is in flight and you want to check in — re-run review anytime; markers are truth, and a still-`.running` run just gets a status line.
- You know about a gap and want to ship anyway — accept it at readout with your reason; it's recorded under `## Accepted gaps` in VERIFICATION.md.

## Prerequisites

- A shippEdd state dir (`/skill:bootstrap`) with a phase whose every plan run is `.done` **and** `committed` — anything less and review points you back at `/skill:implement`.
- git identity configured — review commits the ship. `gh` plus a git remote are needed only for the optional push/PR and audit-issue steps; without them review says so in one line and stays local.

## Common questions

**Why is verification a separate agent?**
Fresh context. Your orchestrator session dispatched the executors and read their summaries — it is the worst possible judge of whether the summaries are true, and it never even saw the implementation. The verifier is spawned with zero history and no stake in the answer: REQ-IDs must trace to evidence, decisions must trace to evidence, every verify command gets actually run, and every claim in the report carries a citation (file:line, or command + output). An unevidenced claim is rewritten or dropped — that's the verifier's law.

**What if I disagree with a gap?**
Accept it — with a reason. Review records your words under `## Accepted gaps` in VERIFICATION.md and the gap stops counting against the ship gate. You're never arguing with the verifier; you're overruling it on the record, and the record ships with the phase. If you'd rather fix it, that's option 1: a fix plan through the planner, run by implement, then a re-verify.

**When does the phase actually ship?**
Only on `## VERIFICATION PASSED` with zero unaccepted gaps — never with an open gap, never on a summary's say-so. Shipping is one gated sequence: state-dir commit, roadmap tick, archive move, STATE.md update, then the optional push/PR question. Each step is filesystem-truth; the ship receipt at the end matches git log.

**Why doesn't review just fix the gaps itself?**
Lane discipline. All implementation flows through implement's wave/commit machinery — a gap becomes a fix plan, implement runs it, review re-verifies. The skill that judges the work can't also be the skill that does it, or the verification stops meaning anything.

**How do I check on the verify run?**
`bash .agents/skills/shippEdd/review/scripts/dispatch.sh --status` lists every run (state, PID alive/dead, log size); `tail <state>/runs/NN-verify.log` streams it. A still-`.running` marker on re-entry gets you a status line and nothing blocks; a dead PID means an abort — review offers cleanup; a `.failed` marker means the verify was blocked (missing input) and review offers inspect or redispatch.

**What does review do to git?**
At ship time only, and it's the only skill allowed there: it commits uncommitted state-dir changes iff the state dir is tracked (`git check-ignore` decides — an ignored state dir is bootstrap's decision and is never force-added), optionally pushes/opens a PR (only if `gh` and a remote exist), and optionally files one immediately-closed audit issue (only if `config.json` sets `github.mirror_issues`). Everything else stays local.

## It's working if

- VERIFICATION.md cites evidence for every claim — file:line or command + output; no bare assertions anywhere.
- Your session never sees implementation detail — only the report digest, the gap list, and the ship receipt.
- The verify log's final line is exactly one sentinel: `## VERIFICATION PASSED`, `## VERIFICATION FAILED`, or `## VERIFICATION BLOCKED`.
- Gaps produce `NN-FX1-PLAN.md` files and a recommendation to run `/skill:implement` — never a direct edit from review.
- Accepted gaps appear in VERIFICATION.md with your reason and ship without re-appearing as blockers on the next verify round.
- After shipping: the ship receipt's commit count matches the run markers, `phases/` holds only `_archive/` and `_templates/`, the roadmap checkbox is `[x]`, and STATE.md says `/skill:define`.

## Where it fits

Role: the verification-and-shipping step of the phase loop — the gate nothing skips. Neighbours: `/skill:implement` before it, which produced the plans, summaries, and commits review verifies; `/skill:define` after it, which grills the next roadmap phase (or `/skill:todo` to bank one when the roadmap runs dry). `/skill:wayfind` will point here whenever every plan marker reads `.done` + `committed`.
