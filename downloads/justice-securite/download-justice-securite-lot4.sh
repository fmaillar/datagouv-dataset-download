#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/justice-securite"
LOG="/mnt/data/datasets/logs/justice-securite-lot4-download.log"

mkdir -p "$(dirname "$LOG")"
mkdir -p "$ROOT/complements/lot4"

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

# LOT 4 — COMPLÉMENTS THÉMATIQUES
download 6721f27db121da225bd2badf "complements/lot4/centres-d-incendie-et-de-secours-du-tarn"
download 6686a1b8ebcb8e50ac8f03cd "complements/lot4/acquisition-dun-vehicule-neuf-pour-la-police-municipale"
download 637c8ce96878725b7414e0c2 "complements/lot4/les-etablissements-des-services-de-police-municipale-et-de-police-nationale-sur-"
download 56ec0852c751df1d76cc7141 "complements/lot4/etablissements-de-police-ou-de-gendarmerie-de-la-metropole-de-lyon"
download 6662c31a3bb8a2560ed1aeac "complements/lot4/verification-et-maintenance-des-systemes-de-securite-incendie-et-des-installatio"
download 6662bd3ca034945a7320e7e4 "complements/lot4/verification-et-maintenance-des-systemes-de-securite-incendie-et-des-installatio"
download 56ec088b88ee385297e1a629 "complements/lot4/etablissements-de-police-ou-de-gendarmerie-de-la-metropole-de-lyon-point-d-inter"
download 6662c9cc7ebf700080a9135a "complements/lot4/verification-et-maintenance-des-systemes-de-securite-incendie-et-des-installatio"
download 69e17aa4ad77817e62a21d7a "complements/lot4/cours-d-eau-relevant-de-la-police-de-l-eau-en-auvergne-rhone-alpes"
download 67fe86976c4bb3f943910f45 "complements/lot4/fourniture-dequipements-pour-la-police-municipale-en-2-lots-mapa-5-1-2025"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
