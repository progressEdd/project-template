# Roadmap: Project Template Workflow

## Overview

Automate the creation of self-documenting experiment/feature branches from `00-experiments`, using git worktrees for parallel development. Phase 1 creates the README template that all future branches inherit. Phase 2 delivers the complete new-project workflow: branch creation, worktree setup, file population, and environment initialization. Phase 3 adds a root README index so the master branch reflects which experiments are active.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Template Preparation** - README template with placeholder variables on `00-experiments`
- [ ] **Phase 2: Branch Creation Flow** - Complete new-project workflow from branch creation through ready-to-code state
- [ ] **Phase 3: Root README Index** - Master branch README updated to list active experiments

## Phase Details

### Phase 1: Template Preparation
**Goal**: A proper README template exists on `00-experiments` so every new branch inherits a structured, populatable starting point
**Depends on**: Nothing (first phase)
**Requirements**: TMPL-01, TMPL-02
**Success Criteria** (what must be TRUE):
  1. `README.md` exists on the `00-experiments` branch with `$placeholder` variables (e.g., `$project_name`, `$description`)
  2. Template includes all required sections: project name, description, what it does, how to run, status
  3. Template contains a sentinel comment (e.g., `<!-- TEMPLATE: REPLACE ME -->`) that downstream tooling can detect to distinguish template vs populated README
**Plans**: TBD

Plans:
- [ ] 01-01: TBD

### Phase 2: Branch Creation Flow
**Goal**: A user can create a new experiment/feature project in one invocation and get a fully configured, ready-to-code worktree
**Depends on**: Phase 1 (template must exist on `00-experiments` before branches inherit it)
**Requirements**: WKTR-01, WKTR-02, WKTR-03, FILE-01, FILE-02, FILE-03, FILE-04
**Success Criteria** (what must be TRUE):
  1. Running the creation workflow produces a new branch forked from `00-experiments` with a worktree at `02-worktrees/<branch-name>`
  2. The branch's README is populated with actual project context (name, description, purpose) — no leftover `$placeholder` variables
  3. The branch's `pyproject.toml` has the correct project `name` and `description` fields (not the template defaults)
  4. `uv sync` has run and a working `.venv` exists in the worktree — imports work immediately
  5. Pre-flight checks prevent duplicate branch or worktree creation with a clear error message
**Plans**: TBD

Plans:
- [ ] 02-01: TBD
- [ ] 02-02: TBD
- [ ] 02-03: TBD

### Phase 3: Root README Index
**Goal**: The master branch README reflects which experiments/features are actively in development
**Depends on**: Phase 2 (must have at least one created branch to index)
**Requirements**: ROOT-01
**Success Criteria** (what must be TRUE):
  1. After creating a new project, the root `README.md` on the main branch includes an entry for the new branch (name, description, worktree path)
  2. The root README update does not corrupt or lose existing entries
**Plans**: TBD

Plans:
- [ ] 03-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Template Preparation | 0/TBD | Not started | - |
| 2. Branch Creation Flow | 0/TBD | Not started | - |
| 3. Root README Index | 0/TBD | Not started | - |
