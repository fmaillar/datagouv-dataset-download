#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/agriculture-alimentation"
LOG="/mnt/data/datasets/logs/agriculture-alimentation-lot2-download.log"

mkdir -p "$(dirname "$LOG")"
mkdir -p "$ROOT/complements/lot2"

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

# LOT 2 — COMPLÉMENTS THÉMATIQUES
download 68499185bdb47a49e2b67581 "complements/lot2/parcelles-certifiees-en-agriculture-biologique-sur-cartobio"
download 60d19ed9992173e4b9300362 "complements/lot2/codes-cultures-pac"
download 67cad6f2b6a4268a4beba33a "complements/lot2/surface-en-agriculture-biologique-certifiees-bio-ou-en-conversion"
download 67cad6ecc2056d7da376fa3d "complements/lot2/surface-de-cultures-en-legumineuses-total-proteagineux-et-legumes-secs-soja-prai"
download 611621f37e10d43b662b5c64 "complements/lot2/annuaire-alimentation-et-precarite-etudiante-dans-la-metropole-de-lyon"
download 667e99aac9dd523ba0500c47 "complements/lot2/qualite-des-cours-d-eau-vis-a-vis-des-pesticides-en-bretagne-synthese-interannue"
download 690ba547e068527bfd8ebca5 "complements/lot2/agriculture-peche-aquaculture-et-perliculture"
download 6756b821d6f163559eab2818 "complements/lot2/dce-bassin-artois-picardie-etat-chimique-contaminants-chimiques-pesticides"
download 67cad6ce691ec92263232aa0 "complements/lot2/nombre-dexploitations-agricoles"
download 66b603ff237271726d4acbfc "complements/lot2/registre-parcellaire-graphique-rpg-de-troyes-champagne-metropole-contours-des-pa"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
