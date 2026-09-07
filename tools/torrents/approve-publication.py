#!/usr/bin/env python3
"""Consigne une approbation humaine et finalise les métadonnées de publication."""

from __future__ import annotations

import argparse
import csv
import json
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path


DATASET_ROOT = Path("/mnt/data/datasets")
REPO = Path(__file__).resolve().parents[2]
APPROVALS = REPO / "reviews" / "publication-approvals.tsv"


def replace_torrent_comment(path: Path, release_id: str) -> None:
    old = f"Archive data.gouv.fr {release_id} — publication non approuvée".encode()
    new = f"Archive data.gouv.fr {release_id} — publication approuvée".encode()
    payload = path.read_bytes()
    marker = str(len(old)).encode() + b":" + old
    if marker not in payload:
        if new in payload:
            return
        raise ValueError(f"commentaire attendu absent : {path}")
    path.write_bytes(payload.replace(marker, str(len(new)).encode() + b":" + new, 1))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("release_id")
    parser.add_argument("--approver", required=True)
    parser.add_argument("--execute", action="store_true")
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9._+-]+", args.release_id):
        parser.error("release_id contient des caractères non autorisés")

    release = DATASET_ROOT / "releases" / args.release_id
    torrents = DATASET_ROOT / "torrents" / args.release_id
    if not release.is_dir() or not torrents.is_dir():
        parser.error("release ou répertoire de torrents absent")
    torrent_files = sorted(torrents.glob("*.torrent"))
    if not torrent_files:
        parser.error("aucun torrent")

    before = {
        path.name: subprocess.check_output(
            ["transmission-show", "--magnet", str(path)], text=True
        ).strip()
        for path in torrent_files
    }
    if not args.execute:
        print(f"Simulation : approbation de {args.release_id} par {args.approver}")
        print("Ajouter --execute pour finaliser la publication.")
        return 0

    approved_at = datetime.now().astimezone().isoformat(timespec="seconds")
    metadata_path = release / "RELEASE.json"
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    metadata.update(
        publication_approved=True,
        publication_approved_at=approved_at,
        publication_approved_by=args.approver,
    )
    metadata_path.write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    (release / "README.md").write_text(
        "# Archive data.gouv.fr — diffusion approuvée\n\n"
        f"Publication approuvée par {args.approver} le {approved_at}. "
        "Consultez `ATTRIBUTION.tsv` et `RELEASE.json` avant utilisation.\n",
        encoding="utf-8",
    )
    for name in ("README.md", "RELEASE.json"):
        (torrents / name).write_bytes((release / name).read_bytes())
    for path in torrent_files:
        replace_torrent_comment(path, args.release_id)

    after = {
        path.name: subprocess.check_output(
            ["transmission-show", "--magnet", str(path)], text=True
        ).strip()
        for path in torrent_files
    }
    if before != after:
        raise RuntimeError("un infohash a changé pendant la finalisation")

    new_file = not APPROVALS.exists()
    with APPROVALS.open("a", encoding="utf-8", newline="") as stream:
        writer = csv.writer(stream, delimiter="\t", lineterminator="\n")
        if new_file:
            writer.writerow(["release_id", "approved_at", "approver", "decision"])
        writer.writerow([args.release_id, approved_at, args.approver, "APPROVE_PUBLICATION"])

    subprocess.run(
        [str(REPO / "tools/torrents/build-index.sh"), args.release_id], check=True
    )
    print(f"Publication approuvée : {args.release_id}")
    print(f"Approbateur : {args.approver}")
    print(f"Infohashes inchangés : {len(after)}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"ERREUR : {error}", file=sys.stderr)
        sys.exit(2)
