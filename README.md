# Project Template Repo
## Background
Welcome to the template repository! I created this template repo so that as I start new projects, it is much faster to share to others

## Getting Started
This repo uses git submodules to embed other repos. To get started, clone the repository and initialize the submodules:

If you would like a quick one line clone, you can use the following command:
```bash
git clone --recurse-submodules https://github.com/progressEdd/project-template.git
```

If you have already cloned the repository, you can initialize the submodules with the following commands:
```bash
git pull
git submodule update --init --recursive
```

If you only need specific submodules, you can initialize them individually:
```bash
# For just the dev-onboarding submodule
git submodule update --init 01-dev-onboarding
```

## Active Experiments

Projects branched from `00-experiments`, each with its own worktree in `02-worktrees/`.

| Branch | Description | Worktree Path | Created |
|--------|-------------|---------------|---------|
| `test-gsd-flow` | A test project to validate the end-to-end branch creation workflow. | `02-worktrees/test-gsd-flow` | 2026-02-13 |

To set up a worktree for an existing branch:
```bash
git worktree add 02-worktrees/<branch-name> <branch-name>
```