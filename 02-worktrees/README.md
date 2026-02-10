# Git Worktrees

This directory contains git worktrees for parallel development workflows.

## What are git worktrees?

Git worktrees allow you to work on multiple branches simultaneously without switching back and forth. Each worktree is a separate working directory linked to the same repository.

## Usage

### Create a new worktree
```bash
# For existing branch
git worktree add 02-worktrees/branch-name branch-name

# For new branch
git worktree add 02-worktrees/new-feature -b new-feature
```

### List all worktrees
```bash
git worktree list
```

### Remove a worktree
```bash
git worktree remove 02-worktrees/branch-name
```

## Available Worktrees

- **experiments**: Sandbox environment with `sandbox.ipynb` for LLM exploration and testing

## Notes

- Worktree directories are not tracked in git (only this README is)
- Each worktree has its own working directory but shares the same git history
- You can have multiple worktrees checked out at once for different branches
