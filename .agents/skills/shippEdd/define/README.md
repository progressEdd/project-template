## What it does

`/skill:define` runs the front half of a phase. It grills you about the roadmap's next phase — at most 3 questions per round, each with a recommendation, carried-over questions tracked in a visible ledger — and writes every decision into the phase's `CONTEXT.md` the moment it settles. Facts it can look up itself, it does, without blocking the interview; the questions that reach you are only ever real decisions. Factual questions too big for a lookup go to a research run that fills `RESEARCH.md` (when research is enabled) — dispatched by default as a detached background run that flips its own completion marker while the interview continues, an optional short round shapes UI surfaces when the `ui_phase` toggle is on, and then a planner subagent turns the settled context into executable plan files — task blocks with exact files, actions, and runnable verify commands, plus wave/dependency frontmatter computed up front. You approve from a compact summary, the state updates, and the skill points at `/skill:implement`.

## When to reach for it

- Setup just finished — `/skill:define` is the command bootstrap ends by naming.
- The roadmap's next unchecked phase needs to become real work.
- The roadmap is empty and you have a phase in mind — define offers to append one from a one-sentence intent, then grills it into shape.
- A phase needs replanning (e.g. after review feedback) — rerun it; decisions already in `CONTEXT.md` are never re-asked.

## Prerequisites

- A shippEdd state dir — `/skill:bootstrap` creates it. `define` reads state; it never creates the skeleton. No state found means bootstrap hasn't run, and define will say so and stop.
- A phase to plan: the roadmap's next unchecked phase, or thirty seconds of your intent.

## Common questions

**Why only 3 questions per round?**
Small rounds are easier to answer well and cheaper to recompute: with ≤3 answers landing at once, one answer is far less likely to invalidate a sibling question. The cost is more round-trips — that trade is deliberate.

**It asked me something it could have looked up.**
That's a bug in the run, not the design — facts are the agent's job. Say so and it should resolve the fact itself and re-ask only what's genuinely yours to decide.

**Where did my decisions go?**
Into `phases/<NN>-<slug>/<NN>-CONTEXT.md`, row by row as they settled — not in one dump at the end. Interrupt the grill at any point; the table is the state, and rerunning picks up from it.

**The planner came back "blocked".**
It hit a gap — a missing decision, a conflict between inputs — and reported it instead of inventing requirements. Answer the gap question, and the planner is redispatched with the settled answer.

**Research ran in the background — how do I check on it?**
`bash .agents/skills/shippEdd/define/scripts/dispatch.sh --status` lists every run (state, PID alive/dead, log size); `tail <state>/runs/<id>.log` streams its output. When it finishes, the run itself flips its marker `.running` → `.done`.

**A run's marker still says `.running` but its PID is dead.**
That run was aborted or crashed — aborted runs never flip their own markers. Inspect the log, then delete the stale marker; the next `define`/`implement` command offers exactly that cleanup before redispatching.

## It's working if

- Every question you're asked has a ➡️ recommendation and numbered options — answerable by number.
- Each round is preceded by the ledger, and no question you deferred ever silently disappears.
- Decisions appear in `NN-CONTEXT.md` as they settle.
- Nothing you could have answered with `ls` ever reaches you as a question.
- The phase folder ends with `NN-CONTEXT.md` filled, `NN-RESEARCH.md` filled or deliberately absent, and `NN-01-PLAN.md`+ whose tasks name exact files, actions, and runnable verify commands.
- Background research leaves no trace in your session context — one dispatched line, then findings only when the finished artifact is read.
- Background runs flip their own markers `.running` → `.done` (or `.failed` with a reason); a stale `.running` with a dead PID surfaces as an abort with offered cleanup.
- After approval, `STATE.md` reads `next_action: /skill:implement` — and nothing auto-ran.

## Where it fits

Role: the discussion-and-planning step of the phase loop — the longest conversation in the kit, and the only skill that interviews you at length. Neighbours: `/skill:bootstrap` before it, because bootstrap creates everything define reads; `/skill:implement` after it, which runs the approved plans wave by wave. `/skill:todo` is where stray ideas go mid-grill so they don't derail the frontier.
