#!/usr/bin/env python3
"""Prépare une arborescence torrent conservatrice depuis l'audit des licences."""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
DOWNLOAD_DIR = REPO / "downloads"
DATASET_ROOT = Path("/mnt/data/datasets")
AUDIT = DATASET_ROOT / "catalogs" / "license-audit.tsv"
ENTRY_RE = re.compile(r'^download\s+(\S+)\s+"([^"]+)"')
ROOT_RE = re.compile(r'^ROOT="([^"]+)"')
ELIGIBLE = {"ELIGIBLE_ATTRIBUTION", "ELIGIBLE_PUBLIC_DOMAIN", "ELIGIBLE_SHARE_ALIKE"}


def destinations() -> dict[str, Path]:
    result: dict[str, Path] = {}
    for script in sorted(DOWNLOAD_DIR.rglob("download-*.sh")):
        root: Path | None = None
        for line in script.read_text(encoding="utf-8").replace("\\\n", "").splitlines():
            if match := ROOT_RE.match(line):
                root = Path(match.group(1))
            elif match := ENTRY_RE.match(line):
                dataset_id, relative = match.groups()
                if root is None or dataset_id in result:
                    raise ValueError(f"manifeste ambigu : {script}")
                result[dataset_id] = root / relative
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("release_id")
    parser.add_argument("--execute", action="store_true")
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9._+-]+", args.release_id):
        parser.error("release_id contient des caractères non autorisés")
    if not AUDIT.is_file():
        parser.error(f"audit absent : {AUDIT}")

    with AUDIT.open(encoding="utf-8", newline="") as stream:
        audit = list(csv.DictReader(stream, delimiter="\t"))
    selected = {
        row["dataset_id"]: row
        for row in audit
        if (
            row["decision"] in ELIGIBLE
            and not row["personal_data_signal"]
            and row["producer"].strip()
        )
    }
    manifest = destinations()
    release = DATASET_ROOT / "releases" / args.release_id
    if release.exists():
        parser.error(f"release déjà existante : {release}")

    files: list[tuple[Path, Path, str]] = []
    datasets_by_domain: dict[str, set[str]] = {}
    empty: list[str] = []
    for dataset_id in sorted(selected):
        source_dir = manifest[dataset_id]
        present = [path for path in source_dir.rglob("*") if path.is_file() and not path.name.endswith(".part")]
        if not present:
            empty.append(dataset_id)
            continue
        relative_dir = source_dir.relative_to(DATASET_ROOT / "raw")
        domain = relative_dir.parts[0]
        datasets_by_domain.setdefault(domain, set()).add(dataset_id)
        for source in present:
            target = release / "data" / relative_dir / source.relative_to(source_dir)
            files.append((source, target, dataset_id))

    logical_bytes = sum(source.stat().st_size for source, _, _ in files)
    print(f"Datasets sélectionnés : {len(selected)}")
    print(f"Datasets sans fichier : {len(empty)}")
    print(f"Fichiers : {len(files)}")
    print(f"Volume logique : {logical_bytes / 1024**3:.2f} Gio")
    if not args.execute:
        print("Simulation : ajouter --execute pour créer la release")
        return 0

    release.mkdir(parents=True)
    linked = 0
    try:
        for source, target, _ in files:
            target.parent.mkdir(parents=True, exist_ok=True)
            os.link(source, target)
            linked += 1

        fields = ["dataset_id", "title", "producer", "license", "last_update", "page", "decision"]
        with (release / "ATTRIBUTION.tsv").open("w", encoding="utf-8", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=fields, delimiter="\t", lineterminator="\n")
            writer.writeheader()
            for dataset_id in sorted(selected):
                writer.writerow({name: selected[dataset_id][name] for name in fields})

        for domain, dataset_ids in sorted(datasets_by_domain.items()):
            metadata_dir = release / "data" / domain / "_METADATA"
            metadata_dir.mkdir(parents=True, exist_ok=True)
            with (metadata_dir / "ATTRIBUTION.tsv").open(
                "w", encoding="utf-8", newline=""
            ) as stream:
                writer = csv.DictWriter(
                    stream, fieldnames=fields, delimiter="\t", lineterminator="\n"
                )
                writer.writeheader()
                for dataset_id in sorted(dataset_ids):
                    writer.writerow(
                        {name: selected[dataset_id][name] for name in fields}
                    )
            (metadata_dir / "README.md").write_text(
                f"# Archive data.gouv.fr — {domain}\n\n"
                "Ce torrent est un artefact candidat. Les sources, producteurs, licences "
                "et dates de mise à jour figurent dans `ATTRIBUTION.tsv`. La présence dans "
                "cette arborescence ne vaut pas approbation de publication.\n",
                encoding="utf-8",
            )

        summary = {
            "schema_version": 1,
            "release_id": args.release_id,
            "created_at": datetime.now().astimezone().isoformat(timespec="seconds"),
            "selection_policy": (
                "eligible license, identified producer, and no automatic "
                "personal-data signal"
            ),
            "datasets_selected": len(selected),
            "datasets_without_local_files": empty,
            "files": len(files),
            "logical_bytes": logical_bytes,
            "decisions": dict(sorted(Counter(row["decision"] for row in selected.values()).items())),
            "embedded_attribution_by_domain": True,
            "legal_review_complete": False,
            "publication_approved": False,
        }
        (release / "RELEASE.json").write_text(
            json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
        (release / "README.md").write_text(
            "# Archive data.gouv.fr — diffusion candidate\n\n"
            "Sélection conservatrice préparée automatiquement. Publication interdite tant que "
            "les revues juridique et données personnelles ne sont pas terminées. Consultez "
            "`ATTRIBUTION.tsv` et `RELEASE.json`.\n",
            encoding="utf-8",
        )
    except Exception:
        print(f"Release incomplète conservée : {release}", file=sys.stderr)
        raise
    print(f"Liens créés : {linked}")
    print(f"Release : {release}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
