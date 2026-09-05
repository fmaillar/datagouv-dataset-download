#!/usr/bin/env python3
"""Vérifie les archives locales à partir des métadonnées data.gouv.fr."""

from __future__ import annotations

import argparse
import concurrent.futures
import hashlib
import json
import re
import subprocess
import sys
from collections import Counter
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
DATAGOUV = Path("/home/fgm/.local/bin/datagouv")
LOG_DIR = Path("/mnt/data/datasets/logs")
ENTRY_RE = re.compile(r'^download\s+(\S+)\s+"([^"]+)"')
ROOT_RE = re.compile(r'^ROOT="([^"]+)"')


@dataclass(frozen=True)
class Entry:
    dataset_id: str
    directory: Path
    script: str


def clean(value: object) -> str:
    return str(value if value is not None else "").replace("\t", " ").replace("\n", " ")


def entries_from_scripts() -> list[Entry]:
    entries: list[Entry] = []
    excluded = {"download-all.sh", "download-all-parallel.sh"}
    for script in sorted(SCRIPT_DIR.glob("download-*.sh")):
        if script.name in excluded:
            continue
        text = script.read_text(encoding="utf-8").replace("\\\n", "")
        root: Path | None = None
        for line in text.splitlines():
            if match := ROOT_RE.match(line):
                root = Path(match.group(1))
            elif match := ENTRY_RE.match(line):
                if root is None:
                    raise ValueError(f"ROOT absent avant download dans {script.name}")
                entries.append(Entry(match.group(1), root / match.group(2), script.name))
    unique: dict[tuple[str, Path], Entry] = {}
    for entry in entries:
        unique[(entry.dataset_id, entry.directory)] = entry
    return list(unique.values())


def fetch(entry: Entry) -> tuple[Entry, list[dict] | None, str]:
    try:
        result = subprocess.run(
            [str(DATAGOUV), "resources", entry.dataset_id, "--json"],
            check=True,
            capture_output=True,
            text=True,
            timeout=120,
        )
        return entry, json.loads(result.stdout), ""
    except Exception as error:  # Le rapport doit continuer après une API défaillante.
        detail = getattr(error, "stderr", "") or str(error)
        return entry, None, clean(detail)[:500]


def safe_filename(resource: dict) -> str:
    title = str(resource.get("title") or "").strip()
    return Path(title).name if title else str(resource.get("id") or "resource")


def collision_path(path: Path, resource_id: str) -> Path:
    suffix = "".join(path.suffixes)
    basename = path.name[: -len(suffix)] if suffix else path.name
    return path.with_name(f"{basename}--{resource_id}{suffix}")


def hashes(path: Path, algorithms: set[str], quick: bool) -> dict[str, str]:
    if quick:
        return {}
    digests = {name: hashlib.new(name) for name in algorithms}
    with path.open("rb") as stream:
        while chunk := stream.read(8 * 1024 * 1024):
            for digest in digests.values():
                digest.update(chunk)
    return {name: digest.hexdigest() for name, digest in digests.items()}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--api-workers", type=int, default=8)
    parser.add_argument("--hash-workers", type=int, default=1)
    parser.add_argument(
        "--dataset",
        action="append",
        help="limiter la vérification à cet identifiant (option répétable)",
    )
    parser.add_argument(
        "--quick",
        action="store_true",
        help="vérifier uniquement l'existence et la taille, sans lire le contenu",
    )
    args = parser.parse_args()
    if not 1 <= args.api_workers <= 32 or not 1 <= args.hash_workers <= 4:
        parser.error("api-workers doit valoir 1..32 et hash-workers 1..4")

    LOG_DIR.mkdir(parents=True, exist_ok=True)
    report = LOG_DIR / "verification-downloads.tsv"
    manifest = LOG_DIR / "checksums-manifest.tsv"
    entries = entries_from_scripts()
    if args.dataset:
        selected = set(args.dataset)
        entries = [entry for entry in entries if entry.dataset_id in selected]
        unknown = selected - {entry.dataset_id for entry in entries}
        if unknown:
            parser.error("dataset absent des scripts : " + ", ".join(sorted(unknown)))
    print(f"Datasets à interroger : {len(entries)}", flush=True)

    fetched: list[tuple[Entry, list[dict] | None, str]] = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.api_workers) as pool:
        for index, result in enumerate(pool.map(fetch, entries), 1):
            fetched.append(result)
            if index % 25 == 0 or index == len(entries):
                print(f"Métadonnées : {index}/{len(entries)}", flush=True)

    jobs: list[tuple[Entry, dict, Path]] = []
    rows: list[list[object]] = []
    for entry, resources, error in fetched:
        if resources is None:
            rows.append(["API_ERROR", entry.dataset_id, "", "", "", "", "", "", entry.directory, error])
            continue
        for resource in resources:
            path = entry.directory / safe_filename(resource)
            jobs.append((entry, resource, path))

    path_counts = Counter(str(path) for _, _, path in jobs)

    def verify(job: tuple[Entry, dict, Path]) -> tuple[list[object], list[object] | None]:
        entry, resource, path = job
        resource_id = resource.get("id", "")
        alternate = collision_path(path, str(resource_id))
        if path_counts[str(path)] > 1 and alternate.is_file():
            path = alternate
        expected_size = resource.get("filesize")
        checksum = resource.get("checksum") or {}
        algorithm = str(checksum.get("type") or "").lower().replace("-", "")
        expected_hash = str(checksum.get("value") or "").lower()
        if not path.is_file():
            return (["ABSENT", entry.dataset_id, resource_id, algorithm, expected_hash, expected_size, "", "", path, ""], None)

        actual_size = path.stat().st_size
        supported = algorithm in hashlib.algorithms_available
        algorithms = {"sha256"}
        if expected_hash and supported:
            algorithms.add(algorithm)
        actual_hashes = hashes(path, algorithms, args.quick)
        local_sha256 = actual_hashes.get("sha256", "")

        if expected_size is not None and actual_size != int(expected_size):
            status = "TAILLE_INCORRECTE"
        elif args.quick:
            status = "OK_TAILLE" if expected_size is not None else "PRESENT_NON_VERIFIE"
        elif expected_hash and supported:
            status = "OK_CHECKSUM" if actual_hashes[algorithm].lower() == expected_hash else "CHECKSUM_INCORRECT"
        elif expected_size is not None:
            status = "OK_TAILLE"
        else:
            status = "PRESENT_SANS_REFERENCE"

        row = [status, entry.dataset_id, resource_id, algorithm, expected_hash, expected_size, actual_size, local_sha256, path, ""]
        item = [entry.dataset_id, resource_id, algorithm, expected_hash, expected_size, actual_size, local_sha256, path, resource.get("url", "")]
        return row, item

    manifest_rows: list[list[object]] = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.hash_workers) as pool:
        for index, (row, item) in enumerate(pool.map(verify, jobs), 1):
            rows.append(row)
            if item is not None:
                manifest_rows.append(item)
            if index % 100 == 0 or index == len(jobs):
                print(f"Fichiers : {index}/{len(jobs)}", flush=True)

    rows.sort(key=lambda row: (str(row[0]), str(row[8])))
    with report.open("w", encoding="utf-8") as stream:
        stream.write("statut\tdataset_id\tresource_id\tchecksum_type\tchecksum_attendu\ttaille_attendue\ttaille_locale\tsha256_local\tchemin\tdetail\n")
        for row in rows:
            stream.write("\t".join(clean(value) for value in row) + "\n")

    with manifest.open("w", encoding="utf-8") as stream:
        stream.write("dataset_id\tresource_id\tchecksum_type\tchecksum_attendu\ttaille_attendue\ttaille_locale\tsha256_local\tchemin\turl\n")
        for row in sorted(manifest_rows, key=lambda item: str(item[7])):
            stream.write("\t".join(clean(value) for value in row) + "\n")

    counts: dict[str, int] = {}
    for row in rows:
        counts[str(row[0])] = counts.get(str(row[0]), 0) + 1
    print(f"Fin : {datetime.now().astimezone().isoformat(timespec='seconds')}")
    for status in sorted(counts):
        print(f"{status}: {counts[status]}")
    print(f"Rapport : {report}")
    print(f"Manifeste : {manifest}")
    bad = {"API_ERROR", "ABSENT", "TAILLE_INCORRECTE", "CHECKSUM_INCORRECT"}
    return 1 if any(status in bad for status in counts) else 0


if __name__ == "__main__":
    sys.exit(main())
