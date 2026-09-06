#!/usr/bin/env python3
"""Matérialise en lots les recommandations techniques encore en attente."""

from __future__ import annotations

import argparse
import csv
import os
import sys
from datetime import datetime
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
DATASET_ROOT = Path("/mnt/data/datasets")
SCAN = DATASET_ROOT / "catalogs" / "publication-technical-scan.tsv"
DECISIONS = REPO / "reviews" / "publication-decisions.tsv"
BATCH_DIR = REPO / "reviews" / "recommendations"
PENDING_PREFIX = "REVIEW_"
DECISION_FIELDS = ["dataset_id", "decision", "reviewer", "reviewed_at", "rationale"]
BATCH_FIELDS = [
    "dataset_id", "recommendation", "current_status", "title", "producer",
    "license", "files", "sampled_files", "inspected_units", "signals", "rationale",
]


def read_tsv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as stream:
        return list(csv.DictReader(stream, delimiter="\t"))


def write_tsv(path: Path, fields: list[str], rows: list[dict[str, str]]) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    with temporary.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(
            stream, fieldnames=fields, delimiter="\t", lineterminator="\n",
            extrasaction="ignore",
        )
        writer.writeheader()
        writer.writerows(rows)
    os.replace(temporary, path)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reviewer", required=True)
    parser.add_argument("--batch-size", type=int, default=100)
    parser.add_argument("--execute", action="store_true")
    args = parser.parse_args()
    if not args.reviewer.strip() or not 1 <= args.batch_size <= 500:
        parser.error("reviewer ou batch-size invalide")
    if not SCAN.is_file() or not DECISIONS.is_file():
        parser.error("scan technique ou registre de décisions absent")

    scan = read_tsv(SCAN)
    pending = sorted(
        (row for row in scan if row["current_status"].startswith(PENDING_PREFIX)),
        key=lambda row: row["dataset_id"],
    )
    existing_rows = read_tsv(DECISIONS)
    existing_ids = {row["dataset_id"] for row in existing_rows}
    pending = [row for row in pending if row["dataset_id"] not in existing_ids]
    counts = {name: sum(row["recommendation"] == name for row in pending) for name in ("APPROVE", "HOLD", "EXCLUDE")}
    print(f"Décisions à matérialiser : {len(pending)}")
    for name, count in counts.items():
        print(f"{name}: {count}")
    if not args.execute:
        print("Simulation : ajouter --execute")
        return 0

    occupied = {
        int(path.stem.split("-")[-1])
        for path in BATCH_DIR.glob("batch-[0-9][0-9][0-9].tsv")
    }
    next_number = max(occupied, default=0) + 1
    created: list[Path] = []
    for offset in range(0, len(pending), args.batch_size):
        number = next_number + offset // args.batch_size
        path = BATCH_DIR / f"batch-{number:03d}.tsv"
        write_tsv(path, BATCH_FIELDS, pending[offset:offset + args.batch_size])
        created.append(path)

    reviewed_at = datetime.now().astimezone().isoformat(timespec="seconds")
    new_decisions = [
        {
            "dataset_id": row["dataset_id"],
            "decision": row["recommendation"],
            "reviewer": args.reviewer.strip(),
            "reviewed_at": reviewed_at,
            "rationale": "Revue technique bornée : " + row["rationale"],
        }
        for row in pending
    ]
    write_tsv(DECISIONS, DECISION_FIELDS, existing_rows + new_decisions)
    print(f"Lots créés : {len(created)} ({created[0].name if created else 'aucun'} .. {created[-1].name if created else 'aucun'})")
    print(f"Décisions totales : {len(existing_rows) + len(new_decisions)}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError) as error:
        print(f"ERREUR : {error}", file=sys.stderr)
        sys.exit(2)
