#!/usr/bin/env python3
"""Audite les licences des datasets manifestés avant redistribution."""

from __future__ import annotations

import argparse
import concurrent.futures
import csv
import json
import re
import subprocess
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
DOWNLOAD_DIR = REPO / "downloads"
DATAGOUV = Path("/home/fgm/.local/bin/datagouv")
CATALOG_DIR = Path("/mnt/data/datasets/catalogs")
ENTRY_RE = re.compile(r'^download\s+(\S+)\s+"([^"]+)"')
ROOT_RE = re.compile(r'^ROOT="([^"]+)"')
OPEN_LICENSES = {"lov2", "fr-lo", "cc-by", "cc-by/4.0", "cc-by/3.0", "odc-by"}
PUBLIC_DOMAIN_LICENSES = {"cc-zero", "cc0", "pddl", "other-pd"}
SHARE_ALIKE_LICENSES = {"odbl", "odc-odbl", "cc-by-sa", "cc-by-sa/4.0"}
PERSONAL_TERMS = {
    "adresse", "association", "entreprise", "etablissement", "finess",
    "immigration", "individu", "menage", "patient", "personne", "sante",
    "sirene", "siret", "social",
}


def clean(value: object) -> str:
    return str(value if value is not None else "").replace("\t", " ").replace("\n", " ")


def destinations() -> dict[str, list[str]]:
    result: dict[str, list[str]] = {}
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
                result.setdefault(dataset_id, []).append(str(root / relative))
    return result


def fetch(dataset_id: str) -> tuple[str, dict | None, str]:
    try:
        process = subprocess.run(
            [str(DATAGOUV), "dataset", dataset_id, "--json"],
            check=True,
            capture_output=True,
            text=True,
            timeout=120,
        )
        return dataset_id, json.loads(process.stdout), ""
    except Exception as error:
        detail = getattr(error, "stderr", "") or str(error)
        return dataset_id, None, clean(detail)[:500]


def classify(metadata: dict) -> tuple[str, str]:
    license_id = str(metadata.get("license") or "").lower()
    if metadata.get("private") or metadata.get("access_type") not in {None, "open"}:
        return "EXCLUDE_ACCESS", "accès non ouvert"
    if metadata.get("deleted"):
        return "EXCLUDE_DELETED", "dataset supprimé"
    if license_id in OPEN_LICENSES:
        return "ELIGIBLE_ATTRIBUTION", "attribution et date requises"
    if license_id in PUBLIC_DOMAIN_LICENSES:
        return "ELIGIBLE_PUBLIC_DOMAIN", "vérifier les mentions recommandées"
    if license_id in SHARE_ALIKE_LICENSES:
        return "ELIGIBLE_SHARE_ALIKE", "conserver la licence et partager à l'identique"
    if not license_id:
        return "REVIEW_NO_LICENSE", "licence absente"
    return "REVIEW_LICENSE", f"licence non classée : {license_id}"


def record(dataset_id: str, metadata: dict | None, error: str, paths: list[str]) -> dict[str, object]:
    if metadata is None:
        return {
            "decision": "API_ERROR", "dataset_id": dataset_id, "title": "",
            "producer": "", "license": "", "access_type": "", "private": "",
            "archived": "", "deleted": "", "last_update": "", "page": "",
            "destinations": " | ".join(paths), "personal_data_signal": "",
            "signal_terms": "", "note": error,
        }
    decision, note = classify(metadata)
    organization = metadata.get("organization") or {}
    owner = metadata.get("owner") or {}
    producer = organization.get("name") or owner.get("full_name") or owner.get("name") or ""
    searchable = " ".join(
        [str(metadata.get("title") or ""), str(metadata.get("description") or ""), *paths]
    ).lower()
    terms = sorted(term for term in PERSONAL_TERMS if term in searchable)
    return {
        "decision": decision,
        "dataset_id": dataset_id,
        "title": metadata.get("title", ""),
        "producer": producer,
        "license": metadata.get("license", ""),
        "access_type": metadata.get("access_type", ""),
        "private": metadata.get("private", ""),
        "archived": metadata.get("archived", ""),
        "deleted": metadata.get("deleted", ""),
        "last_update": metadata.get("last_update", ""),
        "page": metadata.get("page", ""),
        "destinations": " | ".join(paths),
        "personal_data_signal": "REVIEW" if terms else "",
        "signal_terms": ",".join(terms),
        "note": note,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workers", type=int, default=12)
    args = parser.parse_args()
    if not 1 <= args.workers <= 32:
        parser.error("workers doit valoir 1..32")

    paths = destinations()
    dataset_ids = sorted(paths)
    records: list[dict[str, object]] = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = [pool.submit(fetch, dataset_id) for dataset_id in dataset_ids]
        for index, future in enumerate(futures, 1):
            dataset_id, metadata, error = future.result()
            records.append(record(dataset_id, metadata, error, paths[dataset_id]))
            if index % 25 == 0 or index == len(dataset_ids):
                print(f"Métadonnées : {index}/{len(dataset_ids)}", flush=True)

    records.sort(key=lambda item: (str(item["decision"]), str(item["dataset_id"])))
    CATALOG_DIR.mkdir(parents=True, exist_ok=True)
    tsv_path = CATALOG_DIR / "license-audit.tsv"
    jsonl_path = CATALOG_DIR / "license-audit.jsonl"
    summary_path = CATALOG_DIR / "license-audit-summary.json"
    fields = list(records[0]) if records else []
    with tsv_path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(records)
    with jsonl_path.open("w", encoding="utf-8") as stream:
        for item in records:
            stream.write(json.dumps(item, ensure_ascii=False, sort_keys=True) + "\n")
    counts = Counter(str(item["decision"]) for item in records)
    summary = {
        "schema_version": 1,
        "created_at": datetime.now().astimezone().isoformat(timespec="seconds"),
        "datasets": len(records),
        "decisions": dict(sorted(counts.items())),
        "personal_data_review": sum(item["personal_data_signal"] == "REVIEW" for item in records),
        "redistribution_automatically_approved": False,
    }
    summary_path.write_text(json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    for decision, count in sorted(counts.items()):
        print(f"{decision}: {count}")
    print(f"PERSONAL_DATA_REVIEW: {summary['personal_data_review']}")
    print(f"TSV : {tsv_path}")
    print(f"JSONL : {jsonl_path}")
    print(f"Résumé : {summary_path}")
    return 1 if counts.get("API_ERROR", 0) else 0


if __name__ == "__main__":
    sys.exit(main())
