# Git Branch Workflow

Updated on: 2026-03-15

This guide explains the recommended Git branch workflow for this repository.

It is written for the practical day-to-day case:

- you want to make changes safely
- you want to open clean pull requests
- you do not want to accidentally mix unrelated work into the same PR

## The short version

Use this rule:

- `master` is your sync branch
- every new task gets a new branch
- open pull requests from task branches, not from `master`

## What `master` should be used for

Treat your local `master` as your personal baseline.

That means:

- keep it close to `origin/master`
- use it to start new branches
- avoid doing large new work directly on it when you plan to open a PR

In practice, `master` is where you:

1. sync the latest code
2. create a fresh branch for the next task

## What a task branch is

A task branch is a branch created for one specific purpose.

Examples:

- `docs/local-server-handbook-and-id-reference`
- `fix/login-runtime-alignment`
- `feat/gm-command-export`

Good prefixes:

- `docs/` for documentation work
- `fix/` for bug fixes
- `feat/` for new features
- `refactor/` for structural code cleanup

## Recommended workflow for a new task

### 1. Go back to `master`

```powershell
git checkout master
```

### 2. Pull the latest changes from your fork

```powershell
git pull origin master
```

If you also track the upstream repository, you can update from upstream first and then push or merge into your fork, but for day-to-day work this is enough if your fork is already current.

### 3. Create a new branch

Example:

```powershell
git checkout -b docs/next-topic
```

Or:

```powershell
git switch -c docs/next-topic
```

### 4. Do the work

Edit files, run tests, and review your changes.

### 5. Commit your work

```powershell
git add .
git commit -m "docs: add next topic"
```

### 6. Push the branch

```powershell
git push -u origin docs/next-topic
```

### 7. Open the pull request

With GitHub CLI:

```powershell
gh pr create --repo dwSize-PE/PristonTale-EU-main --base master --head andrenogrib:docs/next-topic
```

## When to keep using the same branch

Keep using the same branch only when the new changes belong to the same pull request.

Examples:

- review fixes requested in the PR
- typo fixes in the same documentation batch
- small follow-up changes that clearly belong to the same topic

## When to create a new branch

Create a new branch when the work is a different topic.

Examples:

- you finished a docs PR and now want to fix gameplay code
- you finished runtime setup docs and now want to build a new script
- you want to investigate a different subsystem

If the answer to "would this deserve a separate PR?" is yes, make a new branch.

## Recommended branch rule for this repository

For this project, the safest practical rule is:

- use the current PR branch only for changes that belong to that PR
- use `master` only as a clean starting point
- create a new branch for each new batch of work

## Example: the branch we just created

Current PR branch:

```text
docs/local-server-handbook-and-id-reference
```

This branch was created after the documentation and helper-script work had already been committed to your fork.

That means this branch includes:

- the local setup guides
- the GM/Admin documentation
- the troubleshooting notes
- the helper scripts we added
- the generated ID reference files

It was then used to open the PR cleanly against the upstream repository.

## Important note about this current situation

Right now, your local `master` and this PR branch point to the same commit history in your fork.

So technically, either branch would work locally.

But the recommended workflow is still:

- keep this branch for PR-related updates only
- go back to `master` before starting a different task
- create a new branch from `master` for the next change

## Useful commands

### See your current branch

```powershell
git branch --show-current
```

### List all local branches

```powershell
git branch
```

### Switch branches

```powershell
git checkout master
git checkout docs/next-topic
```

Or:

```powershell
git switch master
git switch docs/next-topic
```

### Delete a local branch after it is no longer needed

```powershell
git branch -d docs/next-topic
```

If Git says it is not fully merged and you still want to remove it locally:

```powershell
git branch -D docs/next-topic
```

### Delete the remote branch

```powershell
git push origin --delete docs/next-topic
```

## Practical recommendation for you right now

For the branch that is already tied to the open PR:

- use it only if you want to improve that PR

For the next unrelated task:

1. `git checkout master`
2. `git pull origin master`
3. `git checkout -b <new-branch-name>`

## Safe mental model

Think of it like this:

- `master` = your clean desk
- task branch = the one folder for the job you are doing right now
- PR = you handing that folder to reviewers

That mental model helps avoid mixing unrelated work together.
