# Architecture Research

**Domain:** Git worktree-based project template workflow automation
**Researched:** 2026-02-13
**Confidence:** HIGH (based on existing codebase analysis + official git docs)

## Component Overview

The system has **5 distinct components** that operate across two git branch families (template branches on `master`, project branches off `00-experiments`).

### Component 1: Template Skeleton (master branch)

**Responsibility:** Provides the organizational structure — numbered directories, dev logs, supporting files, worktree container, submodule references.

**What it owns:**
- `00-dev-log/` — log templates
- `00-supporting-files/` — shared data/env templates
- `01-dev-onboarding/` — submodule pointer
- `02-worktrees/` — worktree container directory + README
- `.foam/` — note templates
- Root `README.md` — repo overview, active branches index
- `.gitignore` — Python-focused, includes `02-worktrees/*` exclusion

**Key constraint:** This branch never contains application code. It's pure scaffolding.

### Component 2: Base Environment (00-experiments branch)

**Responsibility:** Provides the inheritable Python development environment that all new project branches start from.

**What it owns:**
- `pyproject.toml` — project metadata + dependencies (currently: `name = "template-repo"`, Python >=3.13, ipykernel, openai, python-dotenv)
- `uv.lock` — locked dependency resolution
- `.python-version` — pins Python 3.13
- `sandbox.ipynb` — starter notebook
- `.gitignore` — same comprehensive Python gitignore (includes worktree rules)

**Key constraint:** This branch has a completely different file tree from `master` — no numbered directories, no template structure. It's a standalone Python project root.

**Missing (per PROJECT.md):** No `README.md` exists yet. The `pyproject.toml` references one (`readme = "README.md"`) but the file hasn't been created.

### Component 3: Branch Lifecycle Manager (GSD workflow automation)

**Responsibility:** Orchestrates the creation and setup of new project branches. This is the automation layer that doesn't exist yet — it's the core of what needs to be built.

**What it must do (per PROJECT.md requirements):**
1. Create a new branch from `00-experiments`
2. Create a worktree in `02-worktrees/<branch-name>`
3. Populate the branch's `README.md` with project context
4. Update `pyproject.toml` project name to match the experiment/feature
5. Update root repo `README.md` to reference active branches

**Where it lives:** GSD workflow instructions (AI-executed), not standalone scripts. The GSD system reads `PROJECT.md` and `.planning/` context to know what to do. No shell scripts are needed because the AI orchestrator IS the automation.

### Component 4: Project Branch Instance (per-branch)

**Responsibility:** A self-contained, self-documenting project that inherits from `00-experiments` and adds its own code, deps, and docs.

**What each instance owns:**
- `README.md` — project-specific description (populated by GSD at creation)
- `pyproject.toml` — renamed project, possibly with added deps
- Application code (Python files, notebooks, etc.)
- `uv.lock` — updated after any dependency changes
- `.venv/` — local virtual environment (gitignored)

**Key constraint:** Each branch must be self-contained. Its README fully describes the project without referencing the template repo.

### Component 5: Root README Index (master branch, cross-cutting)

**Responsibility:** Maintains a human-readable directory of active experiments/features so the template repo serves as a project dashboard.

**What it tracks:**
- List of active branches with descriptions
- Worktree setup commands for each
- Status (active, archived, etc.)

**Key constraint:** This is on `master` — updating it requires either: (a) switching to master to commit, or (b) a cross-branch update mechanism. This is architecturally the trickiest component.

## Data Flow

### Flow 1: New Project Creation (primary flow)

```
User triggers "new project" via GSD
         │
         ▼
┌─────────────────────────┐
│ GSD reads PROJECT.md    │  ← Understands the template system
│ and .planning/ context  │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────────────────────┐
│ 1. git branch <name> 00-experiments     │  ← New branch inherits Python env
│ 2. git worktree add                     │
│    02-worktrees/<name> <name>           │  ← Worktree appears in container
└───────────┬─────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────┐
│ 3. Create README.md on branch           │  ← GSD populates with project name,
│    (in 02-worktrees/<name>/)            │     description, goals, constraints
│ 4. Update pyproject.toml name field     │  ← "template-repo" → "<project-name>"
│ 5. Commit on the new branch             │
└───────────┬─────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────┐
│ 6. Update root README.md (on master)    │  ← Add entry to active projects list
│    with branch name + description       │     (REQUIRES branch switch or
│ 7. Commit on master                     │     separate worktree for master)
└─────────────────────────────────────────┘
```

### Flow 2: Context Inheritance

```
00-experiments branch (base)
├── pyproject.toml  ──── name: "template-repo"
├── .python-version ──── 3.13
├── uv.lock         ──── locked deps
├── sandbox.ipynb   ──── starter notebook
└── .gitignore      ──── Python patterns

        │ git branch <name> 00-experiments
        ▼

<name> branch (inherits everything, then customizes)
├── pyproject.toml  ──── name: "<project-name>" (UPDATED)
├── README.md       ──── project docs (CREATED)
├── .python-version ──── 3.13 (inherited)
├── uv.lock         ──── locked deps (inherited, then updated)
├── sandbox.ipynb   ──── starter notebook (inherited, may be renamed/extended)
└── .gitignore      ──── Python patterns (inherited)
```

### Flow 3: Cross-Branch Root README Update

This is the architecturally sensitive flow. The root README lives on `master`, but project creation happens on feature branches worked on from `02-worktrees/`. Options:

**Option A: GSD switches to master worktree (recommended)**
```
GSD working in 02-worktrees/<name>/
    │
    ├── Commits new project files on <name> branch
    │
    ├── Switches context to root worktree (master)
    │   └── Edits README.md to add project entry
    │   └── Commits on master
    │
    └── Returns context to 02-worktrees/<name>/
```

**Option B: Separate master worktree**
```
02-worktrees/master/  ← dedicated worktree for master branch
    └── Edit README.md here
```

**Option C: Defer root README updates**
```
Root README is updated manually or in a separate GSD step later.
```

**Recommendation:** Option A. The root worktree IS master (confirmed by `git worktree list` output showing the repo root is on `vibe-coding-gsd` currently, but normally would be `master`). The GSD orchestrator can make commits on both the new branch (in its worktree) and on master (in the root directory) within the same workflow. No extra worktree needed.

**Caveat:** The root worktree may be on a different branch during development (like `vibe-coding-gsd` right now). The root README update should be a best-effort step that gracefully handles the root not being on `master`.

## Build Order

Dependency-driven sequence for implementing the automation:


## Where Automation Lives

### GSD Instructions (primary — not scripts)

The GSD AI workflow system is the automation engine. It reads `.planning/PROJECT.md` and the codebase context files to understand what to do. The "automation" is encoded as:

1. **PROJECT.md requirements** — the checklist of what GSD must do for a new project
2. **Codebase docs** (`.planning/codebase/`) — how the repo is structured
3. **Research docs** (`.planning/research/`) — architectural decisions and patterns
4. **GSD's own orchestration** — branching, file editing, committing

**Why not shell scripts:** This is a personal template repo, not a team tool. The user interacts through GSD (AI orchestrator), not CLI scripts. Shell scripts add maintenance burden for a single-person workflow. GSD can execute the git commands directly.

### When Scripts WOULD Make Sense (future consideration)

If the template were shared with a team or the workflow became complex enough that GSD needed a "run this script" step, then a thin shell script would be appropriate. Candidates:

- **Worktree cleanup:** `git worktree prune` + removal of stale entries from root README
- **Dependency sync:** `uv sync` in a worktree after branch creation
- **Validation:** Check that a branch's README is populated and `pyproject.toml` name is updated

These would live in a `scripts/` directory on `master` if ever needed. For now, GSD handles all of this inline.

## Integration Points

### Integration 1: Git Worktree ↔ Gitignore

**How they connect:** `02-worktrees/*` is gitignored on both `master` and `00-experiments` branches. Only `02-worktrees/README.md` and `.gitkeep` are tracked.

**Why this matters:** Worktree contents are separate git checkouts — they MUST be gitignored from the master branch's perspective or you'd get nested git tracking conflicts. This is correctly configured.

### Integration 2: Git Worktree ↔ Submodules

**Critical warning from official git docs (2026-02-02, git 2.53.0):**
> "Multiple checkout in general is still experimental, and the support for submodules is incomplete. It is NOT recommended to make multiple checkouts of a superproject."

**Impact on this project:** The `master` branch has a submodule (`01-dev-onboarding`), but `00-experiments` and its child branches do NOT. Since new project branches fork from `00-experiments` (which has no submodule references), this warning doesn't apply to project branch worktrees. The submodule only exists on template branches.

**Safe pattern:** Never branch from `master` for project work. Always branch from `00-experiments`. This avoids the worktree + submodule incompatibility.

### Integration 3: Branch ↔ pyproject.toml

**How they connect:** Each branch has its own copy of `pyproject.toml` (inherited from `00-experiments`, then modified). The `name` field is the primary customization point.

**Consideration:** If `00-experiments` gets new dependencies added later, existing project branches won't automatically inherit them. This is by design — each branch is independent after creation. If a project needs the base deps updated, it can `git merge 00-experiments` or cherry-pick.

### Integration 4: Root Worktree ↔ Master Branch

**How they connect:** The repo root (`/Users/progressedd/personal-projects/project-template`) is the main worktree. It's typically on `master` but can be on any branch (currently `vibe-coding-gsd`).

**Implication for root README updates:** The GSD workflow that updates the root README must check which branch the root worktree is on. If it's not `master`, the update should either be deferred or done via a temporary branch switch.

### Integration 5: 02-worktrees/ README ↔ Active Projects

**How they connect:** The `02-worktrees/README.md` currently documents manual worktree commands. It could be auto-updated alongside the root README to list all active worktrees.

**Recommendation:** Keep `02-worktrees/README.md` as a static usage guide. Use the root `README.md` as the dynamic project index. Two auto-updating files doubles the maintenance surface for no user benefit.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Branching from master for project work

**What:** Creating project branches from `master` instead of `00-experiments`.

**Why bad:** `master` has numbered directories, submodule refs, and a completely different file tree. The project would inherit template scaffolding instead of a clean Python environment. Also triggers the git worktree + submodule incompatibility warning.

**Instead:** Always branch from `00-experiments`. Enforce this in GSD workflow instructions.

### Anti-Pattern 2: Nesting worktrees

**What:** Creating a worktree inside another worktree's directory.

**Why bad:** Git worktrees are separate working directories linked to the same repo. Nesting them creates confusing `.git` file resolution and potential data corruption.

**Instead:** All worktrees go in `02-worktrees/` at the same level: `02-worktrees/<branch-a>/`, `02-worktrees/<branch-b>/`.

### Anti-Pattern 3: Shared mutable state between branches

**What:** Having project branches depend on files from `master` (like `00-supporting-files/`) at runtime.

**Why bad:** Project branches checked out as worktrees have their own file tree — they can't see `master`'s `00-supporting-files/` directory. Branches are isolated.

**Instead:** Any shared data needed by project branches should be on `00-experiments` so it gets inherited, or copied into the branch at creation time.

### Anti-Pattern 4: Manual worktree management

**What:** Users running `git worktree add` manually without the GSD workflow.

**Why bad:** Skips README population, pyproject.toml renaming, and root README indexing. Creates inconsistent project state.

**Instead:** All project creation goes through GSD. Document the GSD-driven workflow, not the manual commands.

## Scalability Considerations

| Concern | At 5 projects | At 20 projects | At 50+ projects |
|---------|---------------|----------------|-----------------|
| Worktree count | No issue | Git handles fine; disk space is the only limit since worktrees share object store | Consider archiving old worktrees with `git worktree remove` |
| Root README index | Simple list | Needs sections (active/archived) | Needs auto-generation or a separate index file |
| Branch proliferation | No issue | `git branch` output gets noisy | Use naming conventions (`exp-*`, `feat-*`) and prune merged branches |
| Disk space | ~50MB per worktree (Python + venv) | ~1GB total | Significant; document `git worktree remove` + `uv` cache cleanup |

## Sources

- Official git-worktree docs: https://git-scm.com/docs/git-worktree (git 2.53.0, 2026-02-02) — HIGH confidence
- Existing codebase analysis: `.planning/codebase/ARCHITECTURE.md`, `STRUCTURE.md`, `CONVENTIONS.md` — HIGH confidence
- `PROJECT.md` requirements — HIGH confidence (first-party)
- Git version on this machine: 2.51.2 — verified

---

*Architecture research: 2026-02-13*
