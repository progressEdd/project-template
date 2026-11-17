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

## shippEdd Skills

This repo embeds the [shippEdd](https://github.com/progressEdd/shippEdd.git) AI coding agent skills as a git subtree at `.agents/skills/shippEdd/`, so they ship with every clone of the template.

To start using the skills, run the onboarding wizard:
```
/skill:bootstrap
```

To pull in the latest shippEdd updates later:
```bash
git subtree pull --prefix=.agents/skills/shippEdd https://github.com/progressEdd/shippEdd.git master --squash
```
