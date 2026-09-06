#!/usr/bin/env python3
"""Réconcilie les fichiers existants après un changement de destination manifeste."""

from __future__ import annotations

import argparse
import csv
import os
import re
import shutil
import sys
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
DOWNLOAD_DIR = REPO / "downloads"
DEFAULT_REPORT = Path("/mnt/data/datasets/logs/verification-downloads.tsv")
ENTRY_RE = re.compile(r'^download\s+(\S+)\s+"([^"]+)"')
ROOT_RE = re.compile(r'^ROOT="([^"]+)"')


def manifest_destinations() -> dict[str, Path]:
    destinations: dict[str, Path] = {}
    for script in sorted(DOWNLOAD_DIR.rglob("download-*.sh")):
        root: Path | None = None
        text = script.read_text(encoding="utf-8").replace("\\\n", "")
        for line in text.splitlines():
            if match := ROOT_RE.match(line):
                root = Path(match.group(1))
            elif match := ENTRY_RE.match(line):
                if root is None:
                    raise ValueError(f"ROOT absent avant download dans {script}")
                dataset_id, relative = match.groups()
                if dataset_id in destinations:
                    raise ValueError(f"dataset dupliqué dans les manifestes : {dataset_id}")
                destinations[dataset_id] = root / relative
    return destinations


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    parser.add_argument("--execute", action="store_true", help="créer les liens physiques")
    args = parser.parse_args()
    if not args.report.is_file():
        parser.error(f"rapport absent : {args.report}")

    destinations = manifest_destinations()
    planned: dict[tuple[Path, Path], str] = {}
    with args.report.open(encoding="utf-8", newline="") as stream:
        for row in csv.DictReader(stream, delimiter="\t"):
            source = Path(row.get("chemin", ""))
            target_dir = destinations.get(row.get("dataset_id", ""))
            if not target_dir or not source.is_file() or source.parent == target_dir:
                continue
            planned[(source, target_dir / source.name)] = row["dataset_id"]

    created = skipped = conflicts = errors = 0
    for (source, target), dataset_id in sorted(planned.items(), key=lambda item: str(item[0][1])):
        if target.exists():
            if target.is_file() and os.path.samefile(source, target):
                skipped += 1
                status = "DÉJÀ_LIÉ"
            else:
                conflicts += 1
                status = "CONFLIT"
        elif not args.execute:
            status = "À_LIER"
        else:
            try:
                target.parent.mkdir(parents=True, exist_ok=True)
                try:
                    os.link(source, target)
                    status = "LIÉ"
                except OSError:
                    shutil.copy2(source, target)
                    status = "COPIÉ"
                created += 1
            except OSError as error:
                errors += 1
                status = f"ERREUR:{error}"
        print(f"{status}\t{dataset_id}\t{source}\t{target}")

    print(
        f"Candidats={len(planned)} créés={created} déjà_liés={skipped} "
        f"conflits={conflicts} erreurs={errors}",
        file=sys.stderr,
    )
    return 1 if conflicts or errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
