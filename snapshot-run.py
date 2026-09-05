#!/usr/bin/env python3
"""Fige une campagne data.gouv dans un dossier de preuves autoportant."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import platform
import re
import shutil
import socket
import subprocess
import sys
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path


REPO = Path(__file__).resolve().parent
DATASET_ROOT = Path("/mnt/data/datasets")
LOG_ROOT = DATASET_ROOT / "logs"
RUN_ROOT = DATASET_ROOT / "catalogs" / "runs"
VERIFY_REPORT = LOG_ROOT / "verification-downloads.tsv"
ENTRY_RE = re.compile(r'^download\s+(\S+)\s+"([^"]+)"')
ROOT_RE = re.compile(r'^ROOT="([^"]+)"')


def command(*args: str, cwd: Path | None = None) -> str:
    try:
        return subprocess.run(
            args,
            cwd=cwd,
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
    except Exception:
        return ""


def parse_entries() -> list[dict[str, str]]:
    entries: list[dict[str, str]] = []
    excluded = {"download-all.sh", "download-all-parallel.sh"}
    for script in sorted(REPO.glob("download-*.sh")):
        if script.name in excluded:
            continue
        root = ""
        text = script.read_text(encoding="utf-8").replace("\\\n", "")
        for line in text.splitlines():
            if match := ROOT_RE.match(line):
                root = match.group(1)
            elif match := ENTRY_RE.match(line):
                entries.append(
                    {
                        "dataset_id": match.group(1),
                        "script": script.name,
                        "destination": str(Path(root) / match.group(2)),
                    }
                )
    return entries


def directory_summary(root: Path) -> list[dict[str, int | str]]:
    result: list[dict[str, int | str]] = []
    if not root.is_dir():
        return result
    for directory in sorted(path for path in root.iterdir() if path.is_dir()):
        size = 0
        files = 0
        for current, _, names in os.walk(directory):
            for name in names:
                try:
                    size += (Path(current) / name).stat().st_size
                    files += 1
                except FileNotFoundError:
                    pass
        result.append({"domain": directory.name, "files": files, "bytes": size})
    return result


def copy_repository(destination: Path) -> None:
    destination.mkdir(parents=True)
    for source in sorted(REPO.iterdir()):
        if not source.is_file():
            continue
        if source.name.endswith((".pyc", ".log")):
            continue
        shutil.copy2(source, destination / source.name)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        while chunk := stream.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "run_id",
        nargs="?",
        default=datetime.now().astimezone().strftime("%Y%m%dT%H%M%S%z"),
        help="identifiant du snapshot, créé sous catalogs/runs/",
    )
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9._+-]+", args.run_id):
        parser.error("run_id contient des caractères non autorisés")
    if not VERIFY_REPORT.is_file():
        parser.error(f"rapport de vérification absent : {VERIFY_REPORT}")

    run_dir = RUN_ROOT / args.run_id
    if run_dir.exists():
        parser.error(f"snapshot déjà existant : {run_dir}")
    evidence_dir = run_dir / "evidence"
    repository_dir = run_dir / "repository"
    run_dir.mkdir(parents=True)
    try:
        shutil.copytree(LOG_ROOT, evidence_dir / "logs", copy_function=shutil.copy2)
        copy_repository(repository_dir)

        entries = parse_entries()
        by_dataset: dict[str, list[dict[str, str]]] = defaultdict(list)
        for entry in entries:
            by_dataset[entry["dataset_id"]].append(entry)

        with VERIFY_REPORT.open(encoding="utf-8", newline="") as stream:
            verification = list(csv.DictReader(stream, delimiter="\t"))
        statuses: dict[str, Counter[str]] = defaultdict(Counter)
        for row in verification:
            statuses[row["dataset_id"]][row["statut"]] += 1

        status_names = sorted({status for counts in statuses.values() for status in counts})
        inventory_fields = ["dataset_id", "scripts", "destinations", "resources_total", *status_names]
        with (run_dir / "dataset-inventory.tsv").open("w", encoding="utf-8", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=inventory_fields, delimiter="\t", lineterminator="\n")
            writer.writeheader()
            for dataset_id in sorted(by_dataset):
                dataset_entries = by_dataset[dataset_id]
                counts = statuses.get(dataset_id, Counter())
                writer.writerow(
                    {
                        "dataset_id": dataset_id,
                        "scripts": ",".join(sorted({item["script"] for item in dataset_entries})),
                        "destinations": ",".join(sorted({item["destination"] for item in dataset_entries})),
                        "resources_total": sum(counts.values()),
                        **{status: counts[status] for status in status_names},
                    }
                )

        unresolved_statuses = {"ABSENT", "API_ERROR", "CHECKSUM_INCORRECT", "TAILLE_INCORRECTE"}
        with (run_dir / "unresolved-resources.tsv").open("w", encoding="utf-8", newline="") as stream:
            fields = list(verification[0]) if verification else []
            writer = csv.DictWriter(stream, fieldnames=fields, delimiter="\t", lineterminator="\n")
            writer.writeheader()
            writer.writerows(row for row in verification if row["statut"] in unresolved_statuses)

        disk = os.statvfs(DATASET_ROOT)
        raw_summary = directory_summary(DATASET_ROOT / "raw")
        run_metadata = {
            "schema_version": 1,
            "run_id": args.run_id,
            "snapshot_created_at": datetime.now().astimezone().isoformat(timespec="seconds"),
            "campaign_dates": ["2026-09-05", "2026-09-06"],
            "host": socket.gethostname(),
            "platform": platform.platform(),
            "kernel": platform.release(),
            "python": platform.python_version(),
            "repository": {
                "path": str(REPO),
                "commit": command("git", "rev-parse", "HEAD", cwd=REPO),
                "branch": command("git", "branch", "--show-current", cwd=REPO),
                "dirty": bool(command("git", "status", "--porcelain", cwd=REPO)),
            },
            "datagouv": {
                "executable": "/home/fgm/.local/bin/datagouv",
                "version": command(
                    "/home/fgm/.local/share/uv/tools/datagouv-toolkit/bin/python",
                    "-c",
                    "import importlib.metadata; print(importlib.metadata.version('datagouv-toolkit'))",
                ),
                "source_path": "/home/fgm/datagouv-toolkit",
                "source_commit": command("git", "rev-parse", "HEAD", cwd=Path("/home/fgm/datagouv-toolkit")),
            },
            "selection": {
                "manifest_scripts": len({entry["script"] for entry in entries}),
                "entries": len(entries),
                "unique_dataset_ids": len(by_dataset),
            },
            "verification_statuses": dict(sorted(Counter(row["statut"] for row in verification).items())),
            "storage": {
                "path": str(DATASET_ROOT),
                "filesystem_bytes": disk.f_blocks * disk.f_frsize,
                "available_bytes": disk.f_bavail * disk.f_frsize,
                "raw_domains": raw_summary,
                "raw_total_bytes": sum(int(item["bytes"]) for item in raw_summary),
                "raw_total_files": sum(int(item["files"]) for item in raw_summary),
            },
            "notes": [
                "Checksums in SHA256SUMS cover snapshot evidence, not raw datasets.",
                "Verification metadata may change after this snapshot.",
                "Repository working-tree files are copied under repository/.",
            ],
        }
        (run_dir / "run-metadata.json").write_text(
            json.dumps(run_metadata, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )

        checksum_path = run_dir / "SHA256SUMS"
        files = sorted(path for path in run_dir.rglob("*") if path.is_file() and path != checksum_path)
        with checksum_path.open("w", encoding="utf-8") as stream:
            for path in files:
                stream.write(f"{sha256_file(path)}  {path.relative_to(run_dir)}\n")

        (run_dir / "SNAPSHOT_COMPLETE").write_text(
            datetime.now().astimezone().isoformat(timespec="seconds") + "\n",
            encoding="utf-8",
        )
        print(f"Snapshot : {run_dir}")
        print(f"Datasets : {len(by_dataset)}")
        print(f"Fichiers bruts inventoriés : {run_metadata['storage']['raw_total_files']}")
        print(f"Preuves indexées dans SHA256SUMS : {len(files)}")
        return 0
    except Exception:
        print(f"Snapshot incomplet conservé pour diagnostic : {run_dir}", file=sys.stderr)
        raise


if __name__ == "__main__":
    sys.exit(main())
