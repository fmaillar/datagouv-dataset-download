#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/culture-patrimoine"
LOG="/mnt/data/datasets/logs/culture-patrimoine-lot1-download.log"

mkdir -p "$(dirname "$LOG")"
mkdir -p \
  "$ROOT/patrimoine/monuments-historiques" \
  "$ROOT/musees" \
  "$ROOT/bibliotheques" \
  "$ROOT/evenements"

download() {
    local id="$1"
    local dest="$2"
    echo
    echo "===== $id -> $dest =====" | tee -a "$LOG"
    mkdir -p "$ROOT/$dest"
    if datagouv download "$id" -o "$ROOT/$dest" >>"$LOG" 2>&1; then
        echo "OK: $id -> $dest" | tee -a "$LOG"
    else
        echo "ECHEC: $id -> $dest" | tee -a "$LOG" >&2
    fi
}

echo "Début : $(date --iso-8601=seconds)" >"$LOG"

# LOT 1 — MONUMENTS / MUSÉES / BIBLIOTHÈQUES
download 5af120e5b595087cfabcde81 "patrimoine/monuments-historiques/immeubles-proteges"
download 68e8bbfa16a41347e37c821c "patrimoine/monuments-historiques/merimee-palissy"
download 5af1210fb595080488bcde6e "patrimoine/monuments-historiques/photographies-1851-1914"
download 5b448216a3a729752eb11d6f "musees/collections-joconde"
download 5af120e7b595087cfabcde82 "musees/frequentation"
download 6a58a5085069867fa2991908 "bibliotheques/base-publique"
download 66063d22592637d8f57263d5 "evenements/nuit-musees-2024"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
