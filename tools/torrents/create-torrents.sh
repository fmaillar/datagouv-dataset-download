#!/usr/bin/env bash

set -u
RELEASE_ID="${1:-}"
DATASET_ROOT="/mnt/data/datasets"
RELEASE="$DATASET_ROOT/releases/$RELEASE_ID"
OUTPUT="$DATASET_ROOT/torrents/$RELEASE_ID"

if [[ ! "$RELEASE_ID" =~ ^[A-Za-z0-9._+-]+$ ]] || [[ ! -d "$RELEASE/data" ]]; then
    echo "Usage : $0 <release_id>" >&2
    exit 2
fi
command -v transmission-create >/dev/null || { echo "transmission-create est requis" >&2; exit 2; }
command -v transmission-show >/dev/null || { echo "transmission-show est requis" >&2; exit 2; }

mkdir -p "$OUTPUT"
failed=0
for domain in "$RELEASE"/data/*; do
    [[ -d "$domain" ]] || continue
    name="$(basename "$domain")"
    if [[ ! -f "$domain/_METADATA/ATTRIBUTION.tsv" ]] || [[ ! -f "$domain/_METADATA/README.md" ]]; then
        echo "ERREUR : métadonnées embarquées absentes pour $name" >&2
        failed=$((failed + 1))
        continue
    fi
    torrent="$OUTPUT/$name.torrent"
    if [[ -s "$torrent" ]] && transmission-show "$torrent" >/dev/null 2>&1; then
        echo "Déjà valide : $name"
        continue
    fi
    echo "Torrent : $name"
    transmission-create --outfile "$torrent.part" \
        --comment "Archive data.gouv.fr $RELEASE_ID — publication non approuvée" \
        "$domain"
    status=$?
    if ((status == 0)) && transmission-show "$torrent.part" >/dev/null 2>&1; then
        mv "$torrent.part" "$torrent"
    else
        echo "ECHEC : $name" >&2
        failed=$((failed + 1))
    fi
done
cp "$RELEASE/ATTRIBUTION.tsv" "$RELEASE/README.md" "$RELEASE/RELEASE.json" "$OUTPUT/"
(cd "$OUTPUT" && sha256sum -- *.torrent ATTRIBUTION.tsv README.md RELEASE.json >SHA256SUMS)
echo "Torrents : $OUTPUT"
exit "$failed"
