 whenever you need to check for or apply official Bloomee updates without wiping out your custom design and features, simply open this file and follow the steps.
# Bloomee Hard-Fork Sync Guide
This document tracks how to safely pull core backend, audio engine, or streaming fixes from the upstream official Bloomee repository without overwriting our custom features, custom layout, and custom UI design.
## Phase 1: The Initial Configuration (One-Time Setup)
Open your terminal inside your custom project directory and verify/add the connection to the original Bloomee source.
```bash
# Step 1: Tell Git where the original Bloomee project lives
git remote add upstream https://github.com/HemantKArya/BloomeeTunes.git

# Step 2: Verify that both 'origin' (your repo) and 'upstream' (theirs) exist
git remote -v

```
*(Your terminal should print four lines: two tracking your GitHub repository as origin, and two tracking Hemant's repository as upstream.)*
## Phase 2: The Maintenance & Update Workflow
Run this loop whenever you want to check for new backend fixes or whenever your stream resolvers break due to external API modifications.
**Fetch the Remote Commits**
*Safe background download*
Connect to the official Bloomee repository and pull down their latest data into the hidden Git repository space without changing your layout:

bash
git checkout main
git checkout -b sandbox-update-merge

bash
git add .
git commit -m "chore: successfully synced upstream core fixes while preserving custom layout""
git checkout main
git merge sandbox-update-merge
git push origin main
## Technical Safety Precautions
 * **Clean State Rule:** Never execute git merge upstream/main if you have uncommitted changes sitting in your working directory. Always use git status to verify your workspace is completely green before attempting a sync loop.
 * **Emergency Revert Strategy:** If a merge conflict goes terribly wrong and breaks your local files during Phase 2, you can completely abort the merge and wipe the sandbox clear safely by running:
```bash
  git merge --abort
  git checkout main
  git branch -D sandbox-update-merge

```
```</Step></Sequence>

```