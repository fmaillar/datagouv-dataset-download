#!/usr/bin/env python3
"""Construit le catalogue des ressources distantes non archivées comme fichiers."""

from __future__ import annotations

import concurrent.futures
import csv
import json
import subprocess
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path


DATAGOUV = Path("/home/fgm/.local/bin/datagouv")
LOG_DIR = Path("/mnt/data/datasets/logs")
PROBE_REPORT = LOG_DIR / "repair-downloads-probe-unknown.tsv"
CATALOG_TSV = LOG_DIR / "remote-resources-catalog.tsv"
CATALOG_JSONL = LOG_DIR / "remote-resources-catalog.jsonl"
KEEP = {
    "PROBE_ERROR",
    "PROBE_PAGE_HTML",
    "PROBE_SANS_TAILLE",
    "PROBE_SERVICE",
    "PROBE_URL_NON_HTTP",
    "WOULD_DOWNLOAD",
}


def fetch(dataset_id: str) -> tuple[str, dict[str, dict] | None, str]:
    try:
        result = subprocess.run(
            [str(DATAGOUV), "resources", dataset_id, "--json"],
            check=True,
            capture_output=True,
            text=True,
            timeout=120,
        )
        return dataset_id, {str(item.get("id")): item for item in json.loads(result.stdout)}, ""
    except Exception as error:
        detail = getattr(error, "stderr", "") or str(error)
        return dataset_id, None, str(detail).replace("\n", " ")[:500]


def main() -> int:
    if not PROBE_REPORT.is_file():
        print(f"Rapport absent : {PROBE_REPORT}", file=sys.stderr)
        return 2
    with PROBE_REPORT.open(encoding="utf-8", newline="") as stream:
        probe_rows = [row for row in csv.DictReader(stream, delimiter="\t") if row["statut"] in KEEP]
    dataset_ids = sorted({row["dataset_id"] for row in probe_rows})
    metadata: dict[str, dict[str, dict] | None] = {}
    errors: dict[str, str] = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=16) as pool:
        for dataset_id, resources, error in pool.map(fetch, dataset_ids):
            metadata[dataset_id] = resources
            if error:
                errors[dataset_id] = error

    records: list[dict] = []
    for row in probe_rows:
        dataset_id = row["dataset_id"]
        resource_id = row["resource_id"]
        resource = (metadata.get(dataset_id) or {}).get(resource_id, {})
        checksum = resource.get("checksum") or {}
        records.append(
            {
                "probe_status": row["statut"],
                "dataset_id": dataset_id,
                "resource_id": resource_id,
                "title": resource.get("title", ""),
                "url": resource.get("url", ""),
                "format": resource.get("format", ""),
                "filetype": resource.get("filetype", ""),
                "mime": resource.get("mime", ""),
                "filesize": resource.get("filesize", ""),
                "checksum_type": checksum.get("type", ""),
                "checksum_value": checksum.get("value", ""),
                "last_modified": resource.get("last_modified", ""),
                "expected_path": row["chemin"],
                "probe_detail": row["detail"],
                "metadata_error": errors.get(dataset_id, ""),
            }
        )
    records.sort(key=lambda item: (item["probe_status"], item["dataset_id"], item["resource_id"]))
    fields = list(records[0]) if records else []
    with CATALOG_TSV.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(records)
    with CATALOG_JSONL.open("w", encoding="utf-8") as stream:
        for record in records:
            stream.write(json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n")

    print(f"Fin : {datetime.now().astimezone().isoformat(timespec='seconds')}")
    for status, count in sorted(Counter(record["probe_status"] for record in records).items()):
        print(f"{status}: {count}")
    print(f"TSV : {CATALOG_TSV}")
    print(f"JSONL : {CATALOG_JSONL}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
