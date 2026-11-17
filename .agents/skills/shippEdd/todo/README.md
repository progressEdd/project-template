## What it does

`/skill:todo` is the loop's intake valve. Mid-grill, mid-wave, mid-anything, a stray thought surfaces — a bug you just saw, an idea for later, a "we should really fix…". You give todo the note in your own words; it infers a slug, an area, and a severity from them (asking at most one clarifying question, only when the note names nothing actionable), writes `todos/pending/NN-slug.md` from the todo template, and answers in a single line: `captured → todos/pending/03-logout-loop.md (auth, high)`. That's the whole interaction. The second half is graduation: `--promote` lists the parked todos, you multi-select (high severity is the recommendation), and todo creates a real phase in one breath — appended to the roadmap, folder scaffolded from the template stash, CONTEXT.md seeded with the consumed todos as pre-settled decisions, todos moved to `todos/done/`, and STATE.md updated only if nothing live holds the focus. Then it points at `/skill:define` and stops.

## When to reach for it

- Anything worth keeping crosses your mind mid-skill and you don't want to derail — that's the entire reason todo exists.
- `todos/pending/` has accumulated and you want the batch to become real work — `--promote` turns the pile into a planned-next phase without touching the phase currently in flight.
- The roadmap just ran dry (`/skill:review`'s "that was the last one" handoff) — bank what's next instead of minting a phase cold.

## Common questions

**When should a todo become a phase?**
When there are 2+ related todos, or even one high-severity todo — that's what the promote recommendation encodes. A phase is a unit of ship: it gets grilled, planned, executed, verified, and archived as one story. A single low-severity note isn't that story yet; let it sit in pending/ until it has company or starts to hurt.

**What happens to promoted todos?**
Two things, both durable: the files move from `todos/pending/` to `todos/done/` (numbers kept forever — the next capture continues the sequence), and each todo becomes a pre-settled row in the new phase's CONTEXT.md decisions table, so `/skill:define` starts from the banked decisions instead of a blank page. The todo's journey ends as context, not as a loose end.

**Why doesn't it ask me to confirm the inferred slug or severity?**
Because intake that interrupts is intake that stops happening. The reply line shows the file, area, and severity it chose — wrong inference is a one-edit markdown file, and promote shows the phase slug in its receipt before anything downstream consumes it. Cheap to correct, expensive to have asked.

**Can promote disturb the phase I'm in the middle of?**
No. Promote appends exactly one new phase: new roadmap rows, one new folder, todos moved. Live phases, their artifacts, and roadmap history are untouched, and STATE.md is only rewritten when it points at nothing — a live phase keeps the focus, and the receipt says so in plain words.

## It's working if

- A capture costs you one line in, one line out — `captured → todos/pending/NN-slug.md (area, severity)` — and no questions.
- The first capture in a repo mentions `--promote` once; later captures never do.
- Promote asks exactly one question (the multi-select) and then does everything — roadmap, folder, seeded CONTEXT, moved todos — before you see another prompt.
- A promoted phase gets a number past every archived phase (ship 01, live 02 → new is 03), its CONTEXT.md opens with the todos as settled decision rows, and `todos/pending/` no longer contains them.
- STATE.md still names the live phase after a promote that queued behind it.
- Nothing ever runs by itself — todo's last line is a recommendation, not an action.

## Where it fits

Role: the off-ramp that isn't one — stray work banks beside the loop instead of interrupting it, then merges back in as a phase. Neighbours: every skill in the kit, since any of them can be mid-flight when an idea strikes; `/skill:define`, which picks up each promoted phase when its turn comes; `/skill:wayfind`, which mentions the parked todos when they're worth promoting.
