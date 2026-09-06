#!/usr/bin/env python3
"""Inspecte les candidats à la publication sans modifier les données brutes."""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
import zipfile
from collections import Counter
from datetime import datetime
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
DATASET_ROOT = Path("/mnt/data/datasets")
REVIEW = DATASET_ROOT / "catalogs" / "publication-review.tsv"
OUTPUT_TSV = DATASET_ROOT / "catalogs" / "publication-technical-scan.tsv"
OUTPUT_JSONL = DATASET_ROOT / "catalogs" / "publication-technical-scan.jsonl"
OUTPUT_SUMMARY = DATASET_ROOT / "catalogs" / "publication-technical-scan-summary.json"
ENTRY_RE = re.compile(r'^download\s+(\S+)\s+"([^"]+)"')
ROOT_RE = re.compile(r'^ROOT="([^"]+)"')
TEXT_SUFFIXES = {
    ".csv", ".json", ".jsonl", ".tsv", ".txt", ".xml", ".geojson",
    ".sql", ".yaml", ".yml", ".html", ".htm", ".rdf", ".nt",
}
ARCHIVE_MEMBER_SUFFIXES = TEXT_SUFFIXES | {".rels"}
HIGH_SIGNALS = {
    "address": re.compile(r"\b(adress\w*|domicile)\b", re.I),
    "birth": re.compile(r"\b(date de naissance|date_naissance|birth(?:day|date))\b", re.I),
    "contact": re.compile(r"\b(contact\w*|coordonn[ée]es)\b", re.I),
    "email": re.compile(r"\b(courriel\w*|e[-_ ]?mail\w*)\b", re.I),
    "first_name": re.compile(r"\b(pr[ée]nom\w*|first[_ ]?name)\b", re.I),
    "health_id": re.compile(r"\b(nir|num[ée]ro de s[ée]curit[ée] sociale|patient[_ ]?id)\b", re.I),
    "ip_address": re.compile(r"\b(ip[_ ]?address|adresse ip)\b", re.I),
    "individual_id": re.compile(r"\b(identifiant individuel|matricule|num[ée]ro allocataire)\b", re.I),
    "last_name": re.compile(r"\b(nom de famille|nom patronymique|last[_ ]?name|surname)\b", re.I),
    "phone": re.compile(r"\b(t[ée]l[ée]phon\w*|phone|mobile)\b", re.I),
}


def destinations() -> dict[str, Path]:
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


def signals(text: str) -> set[str]:
    return {name for name, pattern in HIGH_SIGNALS.items() if pattern.search(text)}


def inspect_file(path: Path, sample_bytes: int, max_archive_members: int) -> tuple[set[str], int]:
    found = signals(path.name)
    inspected_units = 0
    try:
        with path.open("rb") as stream:
            head = stream.read(sample_bytes)
        if path.suffix.lower() in TEXT_SUFFIXES or b"\x00" not in head[:4096]:
            found.update(signals(head.decode("utf-8", "replace")))
            inspected_units += 1
        if head.startswith(b"PK") and path.stat().st_size <= 512 * 1024 * 1024:
            with zipfile.ZipFile(path) as archive:
                sampled_members = 0
                for info in archive.infolist()[:max_archive_members]:
                    found.update(signals(info.filename))
                    if Path(info.filename).suffix.lower() not in ARCHIVE_MEMBER_SUFFIXES:
                        continue
                    if info.file_size > 32 * 1024 * 1024:
                        continue
                    if info.compress_size > 8 * 1024 * 1024 or sampled_members >= 10:
                        continue
                    with archive.open(info) as stream:
                        found.update(signals(stream.read(sample_bytes).decode("utf-8", "replace")))
                    inspected_units += 1
                    sampled_members += 1
    except (OSError, RuntimeError, zipfile.BadZipFile):
        return found | {"inspection_error"}, inspected_units
    return found, inspected_units


def recommendation(status: str, found: set[str], files: int) -> tuple[str, str]:
    if status == "BLOCKED_LICENSE_OR_ACCESS":
        return "EXCLUDE", "licence ou accès bloqué par l'audit"
    if status == "REVIEW_MISSING_FILES" or files == 0:
        return "EXCLUDE", "aucun fichier local complet à diffuser"
    if status == "REVIEW_ATTRIBUTION":
        return "HOLD", "producteur absent; attribution à résoudre"
    if "inspection_error" in found:
        return "HOLD", "au moins un fichier n'a pas pu être inspecté"
    if found:
        return "HOLD", "signal direct à examiner : " + ",".join(sorted(found))
    return "APPROVE", "aucun signal direct dans les noms et échantillons inspectés"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sample-bytes", type=int, default=262144)
    parser.add_argument("--max-archive-members", type=int, default=20)
    parser.add_argument("--max-files-per-dataset", type=int, default=20)
    args = parser.parse_args()
    if (
        args.sample_bytes < 4096
        or args.max_archive_members < 1
        or args.max_files_per_dataset < 1
    ):
        parser.error("limites d'inspection invalides")
    if not REVIEW.is_file():
        parser.error(f"registre absent : {REVIEW}")

    with REVIEW.open(encoding="utf-8", newline="") as stream:
        review = list(csv.DictReader(stream, delimiter="\t"))
    paths = destinations()
    records: list[dict[str, object]] = []
    for index, row in enumerate(review, 1):
        dataset_id = row["dataset_id"]
        destination = paths.get(dataset_id)
        files = [] if destination is None else sorted([
            path for path in destination.rglob("*")
            if path.is_file() and not path.name.endswith(".part")
        ])
        found = signals(row["title"])
        inspected_units = 0
        for path in files:
            found.update(signals(path.name))
        sampled_files = files[:args.max_files_per_dataset]
        if len(sampled_files) < len(files):
            found.add("partial_file_sample")
        for path in sampled_files:
            file_signals, units = inspect_file(
                path, args.sample_bytes, args.max_archive_members
            )
            found.update(file_signals)
            inspected_units += units
        proposed, rationale = recommendation(row["final_status"], found, len(files))
        records.append({
            "dataset_id": dataset_id,
            "title": row["title"],
            "producer": row["producer"],
            "license": row["license"],
            "current_status": row["final_status"],
            "files": len(files),
            "sampled_files": len(sampled_files),
            "inspected_units": inspected_units,
            "signals": ",".join(sorted(found)),
            "recommendation": proposed,
            "rationale": rationale,
        })
        if index % 50 == 0 or index == len(review):
            print(f"Datasets : {index}/{len(review)}", flush=True)

    records.sort(key=lambda item: (str(item["recommendation"]), str(item["dataset_id"])))
    fields = list(records[0]) if records else []
    with OUTPUT_TSV.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(records)
    with OUTPUT_JSONL.open("w", encoding="utf-8") as stream:
        for record in records:
            stream.write(json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n")
    counts = Counter(str(record["recommendation"]) for record in records)
    summary = {
        "schema_version": 1,
        "created_at": datetime.now().astimezone().isoformat(timespec="seconds"),
        "datasets": len(records),
        "sample_bytes": args.sample_bytes,
        "max_archive_members": args.max_archive_members,
        "max_files_per_dataset": args.max_files_per_dataset,
        "recommendations": dict(sorted(counts.items())),
        "automatic_legal_approval": False,
    }
    OUTPUT_SUMMARY.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    for name, count in sorted(counts.items()):
        print(f"{name}: {count}")
    print(f"Rapport : {OUTPUT_TSV}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError) as error:
        print(f"ERREUR : {error}", file=sys.stderr)
        sys.exit(2)
