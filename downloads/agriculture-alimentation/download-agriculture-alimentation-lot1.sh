#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/agriculture-alimentation"
LOG="/mnt/data/datasets/logs/agriculture-alimentation-lot1-download.log"

mkdir -p "$(dirname "$LOG")"
mkdir -p \
  "$ROOT/parcellaire/rpg" \
  "$ROOT/agriculture-biologique" \
  "$ROOT/pesticides" \
  "$ROOT/securite-alimentaire" \
  "$ROOT/aides"

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

# LOT 1 — PARCELLAIRE / BIO / PESTICIDES / CONTRÔLES
download 53699edca3a729239d205faf "parcellaire/rpg/2010"
download 53fd262ea3a729390ba568a7 "parcellaire/rpg/2011"
download 53699edca3a729239d205fb3 "parcellaire/rpg/2012"
download 616d6531c2951bbe8bd97771 "agriculture-biologique/parcelles-pac"
download 67cad6ef9c8ad4fe75b8b7de "agriculture-biologique/part-surface-agricole"
download 68539efb85493296b78b2902 "pesticides/quantites-substances-actives"
download 594c298ec751df76726294d9 "pesticides/eaux-souterraines"
download 6a5821bbf9121211f67fa5bb "pesticides/achats-code-postal"
download 633456de3d2706f38b296285 "pesticides/usage-domestique-pestihome"
download 5593aab9c751df35d8a453ba "securite-alimentaire/alim-confiance"
download 6a745675d3e8618e4f9de0b0 "aides/aides-publiques"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
