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

mkdir -p "$OUTPUT"
failed=0
for domain in "$RELEASE"/data/*; do
    [[ -d "$domain" ]] || continue
    name="$(basename "$domain")"
    echo "Torrent : $name"
    transmission-create --outfile "$OUTPUT/$name.torrent" \
        --comment "Archive data.gouv.fr $RELEASE_ID — publication non approuvée" \
        "$domain" || failed=$((failed + 1))
done
cp "$RELEASE/ATTRIBUTION.tsv" "$RELEASE/README.md" "$RELEASE/RELEASE.json" "$OUTPUT/"
(cd "$OUTPUT" && sha256sum -- *.torrent ATTRIBUTION.tsv README.md RELEASE.json >SHA256SUMS)
echo "Torrents : $OUTPUT"
exit "$failed"
