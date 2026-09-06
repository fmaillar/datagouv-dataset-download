#!/usr/bin/env python3
"""Construit le registre auditable de revue avant redistribution."""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
DATASET_ROOT = Path("/mnt/data/datasets")
AUDIT = DATASET_ROOT / "catalogs" / "license-audit.tsv"
DEFAULT_DECISIONS = REPO / "reviews" / "publication-decisions.tsv"
OUTPUT_TSV = DATASET_ROOT / "catalogs" / "publication-review.tsv"
OUTPUT_JSONL = DATASET_ROOT / "catalogs" / "publication-review.jsonl"
OUTPUT_SUMMARY = DATASET_ROOT / "catalogs" / "publication-review-summary.json"
ELIGIBLE = {
    "ELIGIBLE_ATTRIBUTION",
    "ELIGIBLE_PUBLIC_DOMAIN",
    "ELIGIBLE_SHARE_ALIKE",
}
MANUAL_DECISIONS = {"APPROVE", "EXCLUDE", "HOLD"}
ENTRY_RE = re.compile(r'^download\s+(\S+)\s+"([^"]+)"')
ROOT_RE = re.compile(r'^ROOT="([^"]+)"')


def load_destinations() -> dict[str, Path]:
    result: dict[str, Path] = {}
    for script in sorted((REPO / "downloads").rglob("download-*.sh")):
        root: Path | None = None
        text = script.read_text(encoding="utf-8").replace("\\\n", "")
        for line in text.splitlines():
            if match := ROOT_RE.match(line):
                root = Path(match.group(1))
            elif match := ENTRY_RE.match(line):
                dataset_id, relative = match.groups()
                if root is None or dataset_id in result:
                    raise ValueError(f"manifeste ambigu : {script}")
                result[dataset_id] = root / relative
    return result


def load_decisions(path: Path) -> dict[str, dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as stream:
        reader = csv.DictReader(stream, delimiter="\t")
        required = ["dataset_id", "decision", "reviewer", "reviewed_at", "rationale"]
        if reader.fieldnames != required:
            raise ValueError(f"colonnes de décisions invalides : {path}")
        rows = list(reader)
    result: dict[str, dict[str, str]] = {}
    for line, row in enumerate(rows, 2):
        dataset_id = row.get("dataset_id", "").strip()
        decision = row.get("decision", "").strip().upper()
        if not dataset_id or dataset_id in result:
            raise ValueError(f"dataset_id absent ou dupliqué ligne {line}")
        if decision not in MANUAL_DECISIONS:
            raise ValueError(f"décision invalide ligne {line} : {decision}")
        for field in ("reviewer", "reviewed_at", "rationale"):
            if not row.get(field, "").strip():
                raise ValueError(f"{field} requis ligne {line}")
        result[dataset_id] = {**row, "decision": decision}
    return result


def automatic_status(row: dict[str, str], files: int) -> tuple[str, str]:
    if row["decision"] not in ELIGIBLE:
        return "BLOCKED_LICENSE_OR_ACCESS", row["note"]
    if row["personal_data_signal"]:
        return "REVIEW_PERSONAL_DATA", f"signal : {row['signal_terms']}"
    if not row["producer"].strip():
        return "REVIEW_ATTRIBUTION", "producteur absent des métadonnées"
    if files == 0:
        return "REVIEW_MISSING_FILES", "aucun fichier local complet"
    return "REVIEW_REQUIRED", "licence admissible; validation humaine requise"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--decisions", type=Path, default=DEFAULT_DECISIONS)
    args = parser.parse_args()
    if not AUDIT.is_file():
        parser.error(f"audit absent : {AUDIT}")
    if not args.decisions.is_file():
        parser.error(f"décisions absentes : {args.decisions}")

    with AUDIT.open(encoding="utf-8", newline="") as stream:
        audit = list(csv.DictReader(stream, delimiter="\t"))
    destinations = load_destinations()
    decisions = load_decisions(args.decisions)
    known_ids = {row["dataset_id"] for row in audit}
    unknown = sorted(set(decisions) - known_ids)
    if unknown:
        raise ValueError(f"décisions pour dataset inconnu : {', '.join(unknown)}")

    records: list[dict[str, object]] = []
    for row in audit:
        dataset_id = row["dataset_id"]
        destination = destinations.get(dataset_id)
        local = [] if destination is None else [
            path for path in destination.rglob("*")
            if path.is_file() and not path.name.endswith(".part")
        ]
        status, reason = automatic_status(row, len(local))
        manual = decisions.get(dataset_id, {})
        manual_decision = manual.get("decision", "")
        if status == "BLOCKED_LICENSE_OR_ACCESS":
            final_status = status
        elif manual_decision == "APPROVE":
            final_status = "APPROVED"
        elif manual_decision == "EXCLUDE":
            final_status = "EXCLUDED_BY_REVIEW"
        elif manual_decision == "HOLD":
            final_status = "HELD_BY_REVIEW"
        else:
            final_status = status
        records.append({
            "dataset_id": dataset_id,
            "title": row["title"],
            "producer": row["producer"],
            "license": row["license"],
            "page": row["page"],
            "automatic_status": status,
            "automatic_reason": reason,
            "local_files": len(local),
            "local_bytes": sum(path.stat().st_size for path in local),
            "manual_decision": manual_decision,
            "reviewer": manual.get("reviewer", ""),
            "reviewed_at": manual.get("reviewed_at", ""),
            "rationale": manual.get("rationale", ""),
            "final_status": final_status,
        })

    records.sort(key=lambda item: (str(item["final_status"]), str(item["dataset_id"])))
    OUTPUT_TSV.parent.mkdir(parents=True, exist_ok=True)
    fields = list(records[0]) if records else []
    with OUTPUT_TSV.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(records)
    with OUTPUT_JSONL.open("w", encoding="utf-8") as stream:
        for record in records:
            stream.write(json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n")

    counts = Counter(str(record["final_status"]) for record in records)
    pending = sum(count for status, count in counts.items() if status.startswith("REVIEW_"))
    summary = {
        "schema_version": 1,
        "created_at": datetime.now().astimezone().isoformat(timespec="seconds"),
        "datasets": len(records),
        "manual_decisions": len(decisions),
        "pending_reviews": pending,
        "statuses": dict(sorted(counts.items())),
        "review_complete": pending == 0,
        "publication_approved": False,
    }
    OUTPUT_SUMMARY.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    for status, count in sorted(counts.items()):
        print(f"{status}: {count}")
    print(f"Décisions humaines : {len(decisions)}")
    print(f"Revues restantes : {pending}")
    print(f"Rapport : {OUTPUT_TSV}")
    print(f"Résumé : {OUTPUT_SUMMARY}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError) as error:
        print(f"ERREUR : {error}", file=sys.stderr)
        sys.exit(2)
