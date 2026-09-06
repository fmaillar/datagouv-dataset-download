#!/usr/bin/env python3
"""Audite et répare les ressources manquantes sans écraser l'archive existante."""

from __future__ import annotations

import argparse
import concurrent.futures
import csv
import hashlib
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request
from collections import Counter
from datetime import datetime
from pathlib import Path


DATAGOUV = Path("/home/fgm/.local/bin/datagouv")
LOG_DIR = Path("/mnt/data/datasets/logs")
DEFAULT_REPORT = LOG_DIR / "verification-downloads.tsv"
USER_AGENT = "datagouv-archive-repair/1.0"
CHUNK_SIZE = 8 * 1024 * 1024


def clean(value: object) -> str:
    return str(value if value is not None else "").replace("\t", " ").replace("\n", " ")


def fetch_resources(dataset_id: str) -> tuple[str, dict[str, dict] | None, str]:
    try:
        result = subprocess.run(
            [str(DATAGOUV), "resources", dataset_id, "--json"],
            check=True,
            capture_output=True,
            text=True,
            timeout=120,
        )
        resources = json.loads(result.stdout)
        return dataset_id, {str(item.get("id")): item for item in resources}, ""
    except Exception as error:
        detail = getattr(error, "stderr", "") or str(error)
        return dataset_id, None, clean(detail)[:500]


def collision_path(path: Path, resource_id: str) -> Path:
    suffix = "".join(path.suffixes)
    basename = path.name[: -len(suffix)] if suffix else path.name
    return path.with_name(f"{basename}--{resource_id}{suffix}")


def remote_size(url: str) -> tuple[int | None, str]:
    try:
        request = urllib.request.Request(url, method="HEAD", headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(request, timeout=60) as response:
            value = response.headers.get("Content-Length")
            return (int(value) if value and value.isdigit() else None), ""
    except Exception as error:
        return None, clean(error)[:300]


def probe_unknown(job: tuple[str, str, Path, dict]) -> list[object]:
    dataset_id, resource_id, path, resource = job
    url = str(resource.get("url") or "")
    filetype = str(resource.get("filetype") or "").lower()
    resource_format = str(resource.get("format") or "").lower()
    service_formats = {"api", "wfs", "wms", "wmts", "csw", "sparql"}
    if not url.startswith(("http://", "https://")):
        return ["PROBE_URL_NON_HTTP", dataset_id, resource_id, path, f"format={resource_format}; url={url}", "", ""]
    try:
        request = urllib.request.Request(url, method="HEAD", headers={"User-Agent": USER_AGENT})
        try:
            response = urllib.request.urlopen(request, timeout=60)
        except urllib.error.HTTPError as error:
            if error.code not in {405, 501}:
                raise
            request = urllib.request.Request(
                url,
                headers={"User-Agent": USER_AGENT, "Range": "bytes=0-0"},
            )
            response = urllib.request.urlopen(request, timeout=60)
        with response:
            content_type = str(response.headers.get("Content-Type") or "").split(";", 1)[0].lower()
            length = response.headers.get("Content-Length")
            size = int(length) if length and length.isdigit() else None
            content_range = str(response.headers.get("Content-Range") or "")
            if "/" in content_range and content_range.rsplit("/", 1)[1].isdigit():
                size = int(content_range.rsplit("/", 1)[1])
            final_url = response.geturl()
        detail = clean(
            f"filetype={filetype}; format={resource_format}; content_type={content_type}; final_url={final_url}"
        )
        lower_url = final_url.lower()
        service_url = any(
            marker in lower_url
            for marker in ("service=wms", "service=wfs", "request=getcapabilities", "/ogc/features", "/wms", "/wfs")
        )
        if resource_format in service_formats or filetype == "api" or service_url:
            status = "PROBE_SERVICE"
        elif content_type == "text/html":
            status = "PROBE_PAGE_HTML"
        elif size is not None:
            status = "PROBE_FICHIER_BORNE"
        else:
            status = "PROBE_SANS_TAILLE"
        return [status, dataset_id, resource_id, path, detail, size or "", ""]
    except Exception as error:
        return ["PROBE_ERROR", dataset_id, resource_id, path, clean(error)[:500], "", ""]


def download(job: dict) -> list[object]:
    resource = job["resource"]
    target: Path = job["target"]
    dataset_id = job["dataset_id"]
    resource_id = str(resource.get("id") or "")
    url = str(resource.get("url") or "")
    if not url:
        return ["DOWNLOAD_ERROR", dataset_id, resource_id, target, "ressource sans URL", "", ""]
    if target.exists():
        return ["SKIP_EXISTANT", dataset_id, resource_id, target, "", target.stat().st_size, ""]

    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.with_name(target.name + ".repair.part")
    temporary.unlink(missing_ok=True)
    checksum = resource.get("checksum") or {}
    algorithm = str(checksum.get("type") or "").lower().replace("-", "")
    expected_hash = str(checksum.get("value") or "").lower()
    digests = {"sha256": hashlib.sha256()}
    if expected_hash and algorithm in hashlib.algorithms_available:
        digests[algorithm] = hashlib.new(algorithm)

    try:
        request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(request, timeout=120) as response, temporary.open("wb") as stream:
            while chunk := response.read(CHUNK_SIZE):
                stream.write(chunk)
                for digest in digests.values():
                    digest.update(chunk)
            stream.flush()
            os.fsync(stream.fileno())
        actual_size = temporary.stat().st_size
        expected_size = resource.get("filesize")
        notes: list[str] = []
        if expected_size is not None and actual_size != int(expected_size):
            notes.append(f"taille metadata={expected_size}, URL={actual_size}")
        if expected_hash and algorithm in digests and digests[algorithm].hexdigest().lower() != expected_hash:
            notes.append(f"checksum metadata {algorithm} divergent du contenu URL actuel")
        temporary.replace(target)
        status = "DOWNLOADED" if not notes else "DOWNLOADED_METADATA_DIVERGENTE"
        return [status, dataset_id, resource_id, target, "; ".join(notes), actual_size, digests["sha256"].hexdigest()]
    except Exception as error:
        temporary.unlink(missing_ok=True)
        return ["DOWNLOAD_ERROR", dataset_id, resource_id, target, clean(error)[:500], "", ""]


def audit_existing(job: tuple[str, str, Path, dict, str]) -> list[object]:
    dataset_id, resource_id, path, resource, old_status = job
    size, error = remote_size(str(resource.get("url") or ""))
    local_size = path.stat().st_size if path.is_file() else None
    if error:
        status = "HEAD_ERROR"
        detail = error
    elif size is None:
        status = "HEAD_SANS_TAILLE"
        detail = ""
    elif local_size == size:
        status = "URL_TAILLE_LOCALE_OK"
        detail = f"ancienne anomalie={old_status}"
    else:
        status = "URL_TAILLE_LOCALE_DIFFERENTE"
        detail = f"URL={size}, local={local_size}, ancienne anomalie={old_status}"
    return [status, dataset_id, resource_id, path, detail, local_size or "", ""]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    parser.add_argument("--execute", action="store_true", help="télécharger réellement les ressources ABSENT")
    parser.add_argument(
        "--include-unknown-size",
        action="store_true",
        help="inclure les ressources sans taille publiée (potentiellement volumineuses)",
    )
    parser.add_argument(
        "--probe-unknown",
        action="store_true",
        help="classifier les ressources ABSENT sans taille, sans les télécharger",
    )
    parser.add_argument(
        "--execute-probed",
        action="store_true",
        help="avec --execute, limiter les ressources sans taille aux PROBE_FICHIER_BORNE",
    )
    parser.add_argument("--api-workers", type=int, default=8)
    parser.add_argument("--download-workers", type=int, default=4)
    args = parser.parse_args()
    if not 1 <= args.api_workers <= 32 or not 1 <= args.download_workers <= 8:
        parser.error("api-workers doit valoir 1..32 et download-workers 1..8")
    if args.execute and args.probe_unknown:
        parser.error("--probe-unknown est un audit et ne se combine pas avec --execute")
    if args.execute_probed and not args.execute:
        parser.error("--execute-probed exige --execute")
    if not args.report.is_file():
        parser.error(f"rapport absent : {args.report}")

    with args.report.open(encoding="utf-8", newline="") as stream:
        rows = list(csv.DictReader(stream, delimiter="\t"))
    probed_allowed: set[tuple[str, str]] = set()
    if args.execute_probed:
        suffix = "-targeted" if "targeted" in args.report.stem else ""
        probe_report = LOG_DIR / f"repair-downloads-probe-unknown{suffix}.tsv"
        if not probe_report.is_file():
            parser.error(f"rapport de sonde absent : {probe_report}")
        with probe_report.open(encoding="utf-8", newline="") as stream:
            probed_allowed = {
                (row["dataset_id"], row["resource_id"])
                for row in csv.DictReader(stream, delimiter="\t")
                if row["statut"] == "PROBE_FICHIER_BORNE"
            }
    wanted = [row for row in rows if row["statut"] in {"ABSENT", "TAILLE_INCORRECTE", "CHECKSUM_INCORRECT", "API_ERROR"}]
    path_counts = Counter(row["chemin"] for row in rows if row["chemin"])
    dataset_ids = sorted({row["dataset_id"] for row in wanted})
    print(f"Datasets anormaux à interroger : {len(dataset_ids)}", flush=True)

    metadata: dict[str, dict[str, dict] | None] = {}
    api_errors: dict[str, str] = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.api_workers) as pool:
        for index, (dataset_id, resources, error) in enumerate(pool.map(fetch_resources, dataset_ids), 1):
            metadata[dataset_id] = resources
            if error:
                api_errors[dataset_id] = error
            if index % 25 == 0 or index == len(dataset_ids):
                print(f"Métadonnées : {index}/{len(dataset_ids)}", flush=True)

    results: list[list[object]] = []
    jobs: list[dict] = []
    audit_jobs: list[tuple[str, str, Path, dict, str]] = []
    probe_jobs: list[tuple[str, str, Path, dict]] = []
    for row in wanted:
        status = row["statut"]
        dataset_id = row["dataset_id"]
        resource_id = row["resource_id"]
        path = Path(row["chemin"]) if row["chemin"] else Path(".")
        resources = metadata.get(dataset_id)
        if resources is None:
            results.append(["API_ERROR", dataset_id, resource_id, path, api_errors.get(dataset_id, row.get("detail", "")), "", ""])
            continue
        resource = resources.get(resource_id)
        if resource is None:
            results.append(["RESSOURCE_DISPARUE", dataset_id, resource_id, path, "absente des métadonnées actuelles", "", ""])
            continue

        if status == "ABSENT":
            target = collision_path(path, resource_id) if path_counts[str(path)] > 1 else path
            if target.exists():
                results.append(["SKIP_EXISTANT", dataset_id, resource_id, target, "", target.stat().st_size, ""])
            elif resource.get("filesize") is None and args.probe_unknown:
                probe_jobs.append((dataset_id, resource_id, target, resource))
            elif resource.get("filesize") is None and args.execute_probed and (dataset_id, resource_id) in probed_allowed:
                jobs.append({"dataset_id": dataset_id, "resource": resource, "target": target})
            elif resource.get("filesize") is None and not args.include_unknown_size:
                action = "SKIP_TAILLE_INCONNUE" if args.execute else "WOULD_SKIP_TAILLE_INCONNUE"
                results.append([action, dataset_id, resource_id, target, "utiliser --include-unknown-size pour autoriser", "", ""])
            elif args.execute:
                jobs.append({"dataset_id": dataset_id, "resource": resource, "target": target})
            else:
                results.append(["WOULD_DOWNLOAD", dataset_id, resource_id, target, "", resource.get("filesize", ""), ""])
            continue

        audit_jobs.append((dataset_id, resource_id, path, resource, status))

    if audit_jobs:
        print(f"Contrôles HTTP : {len(audit_jobs)}", flush=True)
        with concurrent.futures.ThreadPoolExecutor(max_workers=args.api_workers) as pool:
            for index, result in enumerate(pool.map(audit_existing, audit_jobs), 1):
                results.append(result)
                if index % 25 == 0 or index == len(audit_jobs):
                    print(f"Contrôles HTTP : {index}/{len(audit_jobs)}", flush=True)

    if probe_jobs:
        print(f"Sondes sans taille : {len(probe_jobs)}", flush=True)
        with concurrent.futures.ThreadPoolExecutor(max_workers=args.api_workers) as pool:
            for index, result in enumerate(pool.map(probe_unknown, probe_jobs), 1):
                results.append(result)
                if index % 25 == 0 or index == len(probe_jobs):
                    print(f"Sondes : {index}/{len(probe_jobs)}", flush=True)

    if jobs:
        print(f"Téléchargements indépendants : {len(jobs)}", flush=True)
        with concurrent.futures.ThreadPoolExecutor(max_workers=args.download_workers) as pool:
            for index, result in enumerate(pool.map(download, jobs), 1):
                results.append(result)
                if index % 25 == 0 or index == len(jobs):
                    print(f"Réparation : {index}/{len(jobs)}", flush=True)

    suffix = "-targeted" if "targeted" in args.report.stem else ""
    if args.execute:
        output = LOG_DIR / f"repair-downloads-execution{suffix}.tsv"
    elif args.probe_unknown:
        output = LOG_DIR / f"repair-downloads-probe-unknown{suffix}.tsv"
    else:
        output = LOG_DIR / f"repair-downloads-audit{suffix}.tsv"
    with output.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.writer(stream, delimiter="\t", lineterminator="\n")
        writer.writerow(["statut", "dataset_id", "resource_id", "chemin", "detail", "taille", "sha256"])
        writer.writerows(sorted(results, key=lambda item: (str(item[0]), str(item[3]))))

    counts = Counter(str(result[0]) for result in results)
    print(f"Fin : {datetime.now().astimezone().isoformat(timespec='seconds')}")
    for status in sorted(counts):
        print(f"{status}: {counts[status]}")
    print(f"Rapport : {output}")
    return 1 if counts.get("DOWNLOAD_ERROR", 0) or counts.get("API_ERROR", 0) else 0


if __name__ == "__main__":
    sys.exit(main())
