#!/usr/bin/env python3
"""Génère l'index, les liens magnet et les empreintes d'une release torrent."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path


DATASET_ROOT = Path("/mnt/data/datasets")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        while chunk := stream.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def magnet(path: Path) -> str:
    process = subprocess.run(
        ["transmission-show", "--magnet", str(path)],
        check=True,
        capture_output=True,
        text=True,
    )
    value = process.stdout.strip()
    if not value.startswith("magnet:?xt=urn:btih:"):
        raise ValueError(f"lien magnet invalide : {path}")
    return value


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("release_id")
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9._+-]+", args.release_id):
        parser.error("release_id contient des caractères non autorisés")
    output = DATASET_ROOT / "torrents" / args.release_id
    release = DATASET_ROOT / "releases" / args.release_id
    if not output.is_dir() or not release.is_dir():
        parser.error("release ou répertoire de torrents absent")
    metadata = json.loads((release / "RELEASE.json").read_text(encoding="utf-8"))
    torrents = sorted(output.glob("*.torrent"))
    if not torrents:
        parser.error("aucun torrent")

    rows = [
        {
            "domain": path.stem,
            "torrent": path.name,
            "sha256": sha256(path),
            "magnet": magnet(path),
        }
        for path in torrents
    ]
    with (output / "INDEX.tsv").open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]), delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    (output / "MAGNETS.txt").write_text(
        "".join(f"{row['domain']}\t{row['magnet']}\n" for row in rows),
        encoding="utf-8",
    )
    publication_notice = (
        "Publication externe approuvée. Vérifier `SHA256SUMS`, `RELEASE.json` "
        "et `ATTRIBUTION.tsv` avant utilisation.\n\n"
        if metadata.get("publication_approved") is True
        else "Publication externe non approuvée. Vérifier `SHA256SUMS`, `RELEASE.json` "
        "et `ATTRIBUTION.tsv` avant diffusion.\n\n"
    )
    lines = [
        f"# {args.release_id}\n\n",
        f"{metadata['datasets_selected']} datasets, {metadata['files']} fichiers, ",
        f"{metadata['logical_bytes'] / 1024**3:.2f} Gio.\n\n",
        publication_notice,
        "| Domaine | Torrent | SHA-256 | Magnet |\n",
        "|---|---|---|---|\n",
    ]
    for row in rows:
        lines.append(
            f"| {row['domain']} | `{row['torrent']}` | `{row['sha256']}` | "
            f"[magnet]({row['magnet']}) |\n"
        )
    (output / "INDEX.md").write_text("".join(lines), encoding="utf-8")

    checksum_files = [
        *torrents,
        *(output / name for name in (
            "ATTRIBUTION.tsv", "README.md", "RELEASE.json",
            "INDEX.tsv", "INDEX.md", "MAGNETS.txt",
        )),
    ]
    with (output / "SHA256SUMS").open("w", encoding="utf-8") as stream:
        for path in checksum_files:
            stream.write(f"{sha256(path)}  {path.name}\n")
    print(f"Torrents indexés : {len(rows)}")
    print(f"Index : {output / 'INDEX.md'}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"ERREUR : {error}", file=sys.stderr)
        sys.exit(2)
