---
name: todo
description: Park stray work mid-flow without derailing — a one-line note becomes a numbered todo under todos/pending/, no questions asked. Later, promote a batch of parked todos into a real roadmap phase in one shot (folder, roadmap entry, seeded context, todos moved to done). Run /skill:todo <note> anytime, or /skill:todo --promote when the todos pile up.
disable-model-invocation: true
---

# shippEdd todo — bank it, keep moving

You are the intake valve of the phase loop. Work is flowing — a plan is being grilled, a wave is running — and something stray surfaces: a bug spotted, an idea worth keeping, a "we should really…". Your job is to make that thought durable in one line and get out of the way. You never dispatch subagents, never touch a live phase, and never ask a battery of questions: intake that interrupts is intake that stops happening.

`<state>` is the workflow state dir resolved in step 0; all other paths are relative to it or to the repo root. This skill is self-contained: its script (`scripts/state-dir.sh`) lives in this folder; its templates come from the state dir's own stash.

## Ground rules

1. **Intake never blocks** — mode A asks at most **one** clarifying question, and only when the note names nothing actionable. Slug, area, and severity are always inferred or defaulted silently — never questions. A parked idea is not worth an interrogation.
2. **Promote never edits an existing phase** — it appends exactly one new phase: new ROADMAP rows, one new folder, todos moved out of pending. Live phases, their artifacts, and ROADMAP history are not touched; STATE.md is updated only when it points at nothing.
3. **Plain files are the state** — a todo's presence in `todos/pending/` is the truth; its move to `todos/done/` is the record. No session memory anywhere: every mode re-reads the dir.
4. **Copy, don't generate** — todos come from the PENDING-TODO template, phase scaffolds from the `_templates/` stash, with placeholders filled. Capture never invents structure.
5. **Recommend and stop** — the skill ends by naming the next command. Never run it yourself.

## Step 0 — resolve the state dir

Run `scripts/state-dir.sh`. It prints exactly one line: the state dir path relative to the repo root (`$PLANNING_DIR` env → `.pi/planning.json` `state_dir` → `.planning`).

If that dir lacks both `STATE.md` and `ROADMAP.md`, no workflow state exists. Say:

> No workflow state found. Run `/skill:bootstrap` first — it creates the skeleton this skill reads.

Then stop.

## Step 0.5 — pick a mode

- **Arguments contain a note** (any free text, e.g. `/skill:todo fix the logout redirect loop`) → **Mode A — CAPTURE**.
- **Arguments say promote** (`--promote`, `promote`) → **Mode B — PROMOTE**.
- **No arguments** → check `<state>/todos/pending/`: files present → **Mode B**; empty → ask one plain line — "What should I capture?" — then run **Mode A** with the answer. (That question is the mode-A clarifying question; you get no second one.)

## Mode A — CAPTURE (the default)

Zero ceremony: infer everything you can from the note and the conversation around it, write one file, say one line.

**1. Understand the note.** The note may lean on the conversation that produced it ("capture: that redirect bug") — resolve references yourself from context; that resolution is a fact, not a question. Only if nothing actionable can be inferred at all, ask exactly one question, in the grilling format (identical to bootstrap's, define's, implement's, review's):

```
❓ I can't tell what "<the note>" should record — what's the work?
  ➡️ 1. <your best inference from the conversation, one line>
    2. free text — say it in your words
```

**2. Infer the fields** — silently, defaults over questions:

- **Slug** — kebab-case from the note's subject, ≤ 4 words (`logout-redirect-loop`). One slug per todo, derived fresh.
- **Area** — from named paths, modules, or vocabulary in the note (`auth`, `ui`, `build`, `docs`, …). Default `general`.
- **Severity** — `high` when the words say pain (broken, crash, fails, urgent, security, data loss); `medium` for should-haves; default `low`. A parked idea is low until it says otherwise.
- **NN** — next todo number: one more than the highest `NN-*` filename across `todos/pending/` **and** `todos/done/` (both — promoted todos move to done/ and keep their numbers forever, same law as archived phases), zero-padded to two digits. Start at 01 when both are empty.

**3. Write the todo.** Copy the template — source `<state>/todos/PENDING-TODO.md`, falling back to `.agents/skills/shippEdd/bootstrap/templates/todos/PENDING-TODO.md`; if both are missing, stop and recommend rerunning `/skill:bootstrap` (it repairs the skeleton without touching existing content). Write it as `<state>/todos/pending/<NN>-<slug>.md`, filling every field: slug in the title, today's date, the note as **What** (one line), the inferred area/path as **Where**, the severity, and a one-line **Context** a future session could act on without re-deriving anything. Drop the template's HTML comment.

**4. Reply in exactly one line:**

```
captured → todos/pending/<NN>-<slug>.md (<area>, <severity>)
```

**5. First-capture hint — once per repo.** If `todos/pending/` was empty *before* this write, append one gentle line:

```
(banked todos become a phase later: /skill:todo --promote)
```

Never again after that. No promote offer on later captures, no follow-up questions, nothing else — the user was mid-flow; give them their flow back.

## Mode B — PROMOTE (the batch graduation)

**1. List the pending todos** — read every file in `<state>/todos/pending/`, one line each:

```
Todos pending (3):
  01  fix logout redirect loop        auth    medium
  02  search results drop filters     search  high
  03  typo in README install steps    docs    low
```

(id, title from the `# Todo:` heading, area, severity — plus the Context line when it adds anything.)

**If none exist:** say `nothing to promote — todos/pending/ is empty`, then recommend: `/skill:define` if the roadmap has any phase (it continues or mints the next one), or `/skill:bootstrap` if the roadmap itself is still a blank skeleton. Stop.

**2. One multi-select question** (the only question promote asks):

```
❓ Promote which todos into a new phase? (multi-select — answer with ids)
  ➡️ 1. 02 — the high-severity one(s): <ids of every high todo>
    2. all of them: 01, 02, 03
    3. other — name the ids
```

The recommendation is the high-severity subset; if no todo is high, recommend all of them (they parked together for a reason).

**3. Derive the phase** from the selected todos: one **slug** (kebab, ≤ 3 words — the shared area or the dominant subject; when the todos share no thread, the first selected todo's slug carries), a one-line **goal** ("deliver the N promoted todos: <titles>"), and — per selected todo — one success criterion (its What line). You show the slug in the receipt, not in a question: promote asked its one question already.

**4. Execute the promote — one breath, in order:**

1. **NN** — one more than the highest `NN-*` phase number across `phases/` (ignoring `_templates/`) **and** `phases/_archive/`. Archived phases reserve their numbers forever, so a repo that shipped 01 and is mid-02 gets 03.
2. **ROADMAP** — append, never edit history:
   - `## Phases`: `- [ ] **Phase <NN>: <slug>** — <goal>`
   - `## Phase details`: a `### Phase <NN>: <slug>` block — Goal (from step 3), Depends on: `nothing` (unless the todos say otherwise), Requirements: `none recorded — promoted from todos`, success criteria = one per selected todo, and `Plans:` left as `- [ ] (filled by /skill:define)`
   - `## Progress`: a row `| <NN> `<slug>` | 0/0 | Not started | — |`
   - `## Next up`: point it at the new phase **only if no other unchecked phase precedes it** — a live phase keeps the focus (rule 2). If the roadmap was complete, the new phase is next up by right.
3. **Scaffold** `<state>/phases/<NN>-<slug>/` from the stash — same rules `define` uses: copy from `<state>/phases/_templates/`, falling back to `.agents/skills/shippEdd/bootstrap/templates/`; both missing → stop, recommend `/skill:bootstrap`. Copy all five files, renaming `NN` → the real number in name and contents (`YY` placeholders stay — they are the on-deck templates `define`/`implement` instantiate).
4. **Seed `<NN>-CONTEXT.md`** — header: goal from step 3, today's date, `via /skill:todo promote` (the todos were banked mid-work, not grilled — say so). **Decisions table**: one row per selected todo, pre-settled — `| <n> | <todo title> | <todo What> | promoted todo <id> (<severity>), captured <date> |`. Constraints: `none — promoted todos`. Open questions: `none — frontier starts clear`. The phase enters planning with its history already decided.
5. **Move the consumed todos** — `mkdir -p <state>/todos/done/` and `mv` each selected `todos/pending/<id>-<slug>.md` there, filename unchanged. Presence in pending/ was the truth; done/ is the record.
6. **STATE.md — only if it points at nothing** (rule 2): i.e. its body names no live phase (`<none yet…>`, or a phase that is archived or absent). Then set frontmatter `next_action: /skill:define`, `progress: 0%`, body: the new phase and `promoted from <k> todos — awaiting planning`. If STATE.md names a live phase, leave it byte-for-byte untouched.

**5. Promote receipt:**

```
Phase <NN>-<slug> promoted
  todos     <ids> → todos/done/
  roadmap   Phase <NN> appended (unchecked) · Next up <unchanged: <live phase> | now <NN>-<slug>>
  folder    phases/<NN>-<slug>/ scaffolded · CONTEXT seeded with <k> todo row(s)
  state     <untouched — <live phase> still holds focus | → /skill:define>
Next: `/skill:define` — for <the first unchecked phase> (that's <NN>-<slug> itself, or the live phase it queued behind).
```

Then stop (rule 5). todo's whole contribution to flow control is that last line.
