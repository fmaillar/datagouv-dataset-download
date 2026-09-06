# Repository Guidelines

## Project Structure & Module Organization

This repository is a collection of Bash download manifests for archiving selected data.gouv.fr datasets. Top-level `download-<domain>.sh` scripts group downloads by domain; larger domains are split into `-lot1`, `-lot2`, and later batches. `CODEX_CONTEXT_DATAGOUV_M710S.md` documents the archive policy, target host, directory layout, and known dataset IDs.

Downloaded data is not stored in the repository. Scripts write immutable source files below `/mnt/data/datasets/raw/<domain>/` and logs below `/mnt/data/datasets/logs/`. Keep generated data, logs, and temporary files out of Git.

## Build, Test, and Development Commands

There is no build step or package manager. Validate all scripts without downloading data:

```bash
bash -n download-*.sh
```

Run a batch explicitly when the host has the `datagouv` CLI and `/mnt/data` storage configured:

```bash
bash downloads/socio-economie/download-socio-economie-lot2.sh
tail -f /mnt/data/datasets/logs/socio-economie-lot2-download.log
```

Use `shellcheck download-*.sh` when ShellCheck is available; no repository-specific configuration currently exists.

## Coding Style & Naming Conventions

Use Bash with the `#!/usr/bin/env bash` shebang, four-space indentation inside functions and conditionals, and quoted variable expansions. Preserve `set -u`, but do not add `set -e`: one failed remote resource must not stop the rest of a batch. Name scripts `download-<domain>-lotN.sh`, destinations with lowercase descriptive kebab-case paths, and variables/functions consistently with the existing `ROOT`, `LOG`, and `download()` pattern.

Each download entry must contain a verified dataset ID and a destination relative to `ROOT`. Pre-create the expected directory tree, retain per-download logging, and avoid duplicate IDs across batches.

## Testing Guidelines

Syntax validation is the required baseline. For behavior changes, run the smallest affected batch and inspect its log for `OK` and `ECHEC` entries. Remote 403/404 responses, WMS/WFS endpoints, and dead publisher links may be data-source failures rather than script defects. Do not commit downloaded fixtures.

## Commit & Pull Request Guidelines

History currently contains only the `Init` commit, so no established convention exists. Use short, imperative subjects such as `Add cadastral dataset batch`. Pull requests should identify affected domains/lots, explain dataset additions or removals, report `bash -n` results, and call out storage impact or known remote failures. Link relevant data.gouv.fr dataset pages or issues when IDs change.
