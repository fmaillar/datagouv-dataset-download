# Repository Guidelines

## Project Structure & Module Organization

This repository is a collection of Bash download manifests for archiving selected data.gouv.fr datasets. Manifests live in `downloads/<domain>/`; larger domains are split into `-lot1`, `-lot2`, and later batches. Global launchers are in `orchestration/`, while verification, repair, catalog, snapshot, and duplicate-analysis utilities are grouped below `tools/`. `README.md` documents the archive policy and reproducible workflow.

Downloaded data is not stored in the repository. Scripts write immutable source files below `/mnt/data/datasets/raw/<domain>/` and logs below `/mnt/data/datasets/logs/`. Keep generated data, logs, and temporary files out of Git.

## Build, Test, and Development Commands

There is no build step or package manager. Validate all scripts without downloading data:

```bash
find downloads orchestration tools -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
```

Run a batch explicitly when the host has the `datagouv` CLI and `/mnt/data` storage configured:

```bash
bash downloads/socio-economie/download-socio-economie-lot2.sh
tail -f /mnt/data/datasets/logs/socio-economie-lot2-download.log
```

Use `find downloads orchestration tools -type f -name '*.sh' -print0 | xargs -0 shellcheck` when ShellCheck is available; no repository-specific configuration currently exists.

## Coding Style & Naming Conventions

Use Bash with the `#!/usr/bin/env bash` shebang, four-space indentation inside functions and conditionals, and quoted variable expansions. Preserve `set -u`, but do not add `set -e`: one failed remote resource must not stop the rest of a batch. Name scripts `download-<domain>-lotN.sh`, destinations with lowercase descriptive kebab-case paths, and variables/functions consistently with the existing `ROOT`, `LOG`, and `download()` pattern.

Each download entry must contain a verified dataset ID and a destination relative to `ROOT`. Pre-create the expected directory tree, retain per-download logging, and avoid duplicate IDs across batches.

## Testing Guidelines

Syntax validation is the required baseline. For behavior changes, run the smallest affected batch and inspect its log for `OK` and `ECHEC` entries. Remote 403/404 responses, WMS/WFS endpoints, and dead publisher links may be data-source failures rather than script defects. Do not commit downloaded fixtures.

## Commit & Pull Request Guidelines

Use short, imperative subjects consistent with recent history, such as `Add cadastral dataset batch` or `Reorganize download scripts`. Pull requests should identify affected domains/lots, explain dataset additions or removals, report syntax and ShellCheck results, and call out storage impact or known remote failures. Link relevant data.gouv.fr dataset pages or issues when IDs change.
