#!/usr/bin/env python3
"""Inventorie les fichiers bruts et signale les doublons SHA-256 exacts."""

from __future__ import annotations

import argparse
import concurrent.futures
import csv
import hashlib
import json
import os
import re
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
DOWNLOAD_DIR = REPO / "downloads"
RAW_ROOT = Path("/mnt/data/datasets/raw")
CHECKSUM_DIR = Path("/mnt/data/datasets/checksums")
CATALOG_DIR = Path("/mnt/data/datasets/catalogs")
LOG_DIR = Path("/mnt/data/datasets/logs")
CACHE_PATH = CHECKSUM_DIR / "file-hash-cache.tsv"
GROUPS_PATH = CATALOG_DIR / "exact-duplicate-groups.tsv"
FILES_PATH = CATALOG_DIR / "exact-duplicate-files.tsv"
SUMMARY_PATH = CATALOG_DIR / "duplicate-summary.json"
ENTRY_RE = re.compile(r'^download\s+(\S+)\s+"([^"]+)"')
ROOT_RE = re.compile(r'^ROOT="([^"]+)"')
CHUNK_SIZE = 8 * 1024 * 1024


def parse_destinations() -> list[tuple[Path, str, str]]:
    destinations: list[tuple[Path, str, str]] = []
    for script in sorted(DOWNLOAD_DIR.rglob("download-*.sh")):
        root: Path | None = None
        text = script.read_text(encoding="utf-8").replace("\\\n", "")
        for line in text.splitlines():
            if match := ROOT_RE.match(line):
                root = Path(match.group(1))
            elif match := ENTRY_RE.match(line):
                if root is not None:
                    destinations.append((root / match.group(2), match.group(1), script.name))
    return sorted(destinations, key=lambda item: len(item[0].parts), reverse=True)


def dataset_for(path: Path, destinations: dict[Path, tuple[str, str]]) -> tuple[str, str]:
    for parent in path.parents:
        if parent in destinations:
            return destinations[parent]
    return "", ""


def load_tsv_hashes(path: Path, hash_column: str, size_column: str) -> dict[tuple[str, int], str]:
    result: dict[tuple[str, int], str] = {}
    if not path.is_file():
        return result
    with path.open(encoding="utf-8", newline="") as stream:
        for row in csv.DictReader(stream, delimiter="\t"):
            digest = row.get(hash_column, "").lower()
            size = row.get(size_column, "")
            filename = row.get("chemin", "")
            if re.fullmatch(r"[0-9a-f]{64}", digest) and size.isdigit() and filename:
                result[(filename, int(size))] = digest
    return result


def load_cache() -> dict[str, dict[str, str]]:
    if not CACHE_PATH.is_file():
        return {}
    with CACHE_PATH.open(encoding="utf-8", newline="") as stream:
        return {row["path"]: row for row in csv.DictReader(stream, delimiter="\t")}


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        while chunk := stream.read(CHUNK_SIZE):
            digest.update(chunk)
    return digest.hexdigest()


def atomic_tsv(path: Path, fields: list[str], rows: list[dict[str, object]]) -> None:
    temporary = path.with_name(path.name + ".tmp")
    with temporary.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
        stream.flush()
        os.fsync(stream.fileno())
    temporary.replace(path)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workers", type=int, default=1, help="workers de hash (1 recommandé sur disque rotatif)")
    parser.add_argument("--rehash", action="store_true", help="ignorer tous les hashes réutilisables")
    args = parser.parse_args()
    if not 1 <= args.workers <= 4:
        parser.error("workers doit valoir entre 1 et 4")
    if not RAW_ROOT.is_dir():
        parser.error(f"racine absente : {RAW_ROOT}")

    CHECKSUM_DIR.mkdir(parents=True, exist_ok=True)
    CATALOG_DIR.mkdir(parents=True, exist_ok=True)
    destinations = {
        path: (dataset_id, script)
        for path, dataset_id, script in parse_destinations()
    }
    cache = {} if args.rehash else load_cache()
    legacy = {} if args.rehash else load_tsv_hashes(
        LOG_DIR / "verification-downloads-full-20260906T001309.tsv",
        "sha256_local",
        "taille_locale",
    )
    repaired = {} if args.rehash else load_tsv_hashes(
        LOG_DIR / "repair-downloads-execution.tsv",
        "sha256",
        "taille",
    )

    records: list[dict[str, object]] = []
    to_hash: list[tuple[int, Path]] = []
    reused = defaultdict(int)
    for path in sorted(RAW_ROOT.rglob("*")):
        if not path.is_file() or path.is_symlink():
            continue
        stat = path.stat()
        path_text = str(path)
        digest = ""
        source = ""
        cached = cache.get(path_text)
        if cached and cached.get("size") == str(stat.st_size) and cached.get("mtime_ns") == str(stat.st_mtime_ns):
            digest = cached.get("sha256", "")
            source = "cache"
        elif (path_text, stat.st_size) in repaired:
            digest = repaired[(path_text, stat.st_size)]
            source = "repair"
        elif (path_text, stat.st_size) in legacy:
            digest = legacy[(path_text, stat.st_size)]
            source = "verification-20260906"
        if not re.fullmatch(r"[0-9a-f]{64}", digest):
            to_hash.append((len(records), path))
            source = "calculated"
        else:
            reused[source] += 1
        dataset_id, script = dataset_for(path, destinations)
        relative = path.relative_to(RAW_ROOT)
        records.append(
            {
                "path": path_text,
                "relative_path": str(relative),
                "domain": relative.parts[0] if relative.parts else "",
                "dataset_id": dataset_id,
                "script": script,
                "size": stat.st_size,
                "allocated_bytes": stat.st_blocks * 512,
                "mtime_ns": stat.st_mtime_ns,
                "device": stat.st_dev,
                "inode": stat.st_ino,
                "sha256": digest,
                "hash_source": source,
            }
        )

    bytes_to_hash = sum(int(records[index]["size"]) for index, _ in to_hash)
    print(f"Fichiers : {len(records)}")
    print(f"Hashes réutilisés : {sum(reused.values())} ({dict(sorted(reused.items()))})")
    print(f"Hashes à calculer : {len(to_hash)} ({bytes_to_hash / 1024**3:.2f} Gio)", flush=True)
    completed_bytes = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = [(index, path, pool.submit(sha256_file, path)) for index, path in to_hash]
        for done, (index, path, future) in enumerate(futures, 1):
            records[index]["sha256"] = future.result()
            completed_bytes += int(records[index]["size"])
            if done % 25 == 0 or done == len(futures):
                print(
                    f"Hash : {done}/{len(futures)} — {completed_bytes / 1024**3:.2f}/{bytes_to_hash / 1024**3:.2f} Gio",
                    flush=True,
                )

    cache_fields = [
        "path", "relative_path", "domain", "dataset_id", "script", "size",
        "allocated_bytes", "mtime_ns", "device", "inode", "sha256", "hash_source",
    ]
    atomic_tsv(CACHE_PATH, cache_fields, records)

    by_hash: dict[str, list[dict[str, object]]] = defaultdict(list)
    for record in records:
        by_hash[str(record["sha256"])].append(record)
    duplicate_sets = [items for items in by_hash.values() if len(items) > 1]
    duplicate_sets.sort(key=lambda items: (-(len({(r['device'], r['inode']) for r in items}) - 1) * int(items[0]["allocated_bytes"]), str(items[0]["sha256"])))

    group_rows: list[dict[str, object]] = []
    file_rows: list[dict[str, object]] = []
    total_reclaimable = 0
    for number, items in enumerate(duplicate_sets, 1):
        group_id = f"dup-{number:06d}"
        items = sorted(items, key=lambda item: (len(str(item["path"])), str(item["path"])))
        canonical = items[0]
        inodes: dict[tuple[object, object], dict[str, object]] = {}
        for item in items:
            inodes[(item["device"], item["inode"])] = item
        physical_bytes = sum(int(item["allocated_bytes"]) for item in inodes.values())
        canonical_allocated = int(canonical["allocated_bytes"])
        reclaimable = max(0, physical_bytes - canonical_allocated)
        total_reclaimable += reclaimable
        datasets = sorted({str(item["dataset_id"]) for item in items if item["dataset_id"]})
        scope = "cross-dataset" if len(datasets) > 1 else "within-dataset"
        if not datasets:
            scope = "unassigned"
        group_rows.append(
            {
                "group_id": group_id,
                "sha256": canonical["sha256"],
                "logical_size": canonical["size"],
                "file_count": len(items),
                "inode_count": len(inodes),
                "dataset_count": len(datasets),
                "scope": scope,
                "physical_bytes": physical_bytes,
                "reclaimable_bytes": reclaimable,
                "canonical_path": canonical["path"],
            }
        )
        for item in items:
            file_rows.append(
                {
                    "group_id": group_id,
                    "canonical": "yes" if item is canonical else "no",
                    **{field: item[field] for field in cache_fields},
                }
            )

    group_fields = [
        "group_id", "sha256", "logical_size", "file_count", "inode_count",
        "dataset_count", "scope", "physical_bytes", "reclaimable_bytes", "canonical_path",
    ]
    atomic_tsv(GROUPS_PATH, group_fields, group_rows)
    atomic_tsv(FILES_PATH, ["group_id", "canonical", *cache_fields], file_rows)
    summary = {
        "schema_version": 1,
        "created_at": datetime.now().astimezone().isoformat(timespec="seconds"),
        "raw_root": str(RAW_ROOT),
        "files_scanned": len(records),
        "logical_bytes_scanned": sum(int(record["size"]) for record in records),
        "hashes_reused": dict(sorted(reused.items())),
        "files_hashed": len(to_hash),
        "bytes_hashed": bytes_to_hash,
        "duplicate_groups": len(group_rows),
        "duplicate_file_entries": len(file_rows),
        "cross_dataset_groups": sum(row["scope"] == "cross-dataset" for row in group_rows),
        "reclaimable_bytes": total_reclaimable,
        "mutation_performed": False,
    }
    temporary = SUMMARY_PATH.with_name(SUMMARY_PATH.name + ".tmp")
    temporary.write_text(json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(SUMMARY_PATH)

    print(f"Groupes de doublons : {len(group_rows)}")
    print(f"Fichiers dans ces groupes : {len(file_rows)}")
    print(f"Espace récupérable estimé : {total_reclaimable / 1024**3:.2f} Gio")
    print(f"Résumé : {SUMMARY_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
