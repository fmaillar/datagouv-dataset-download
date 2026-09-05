#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/culture-patrimoine"
LOG="/mnt/data/datasets/logs/culture-patrimoine-lot4-download.log"

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
download 6a339e7910e4a8ab2d7d229e "complements/lot4/archives-annuelles-des-observations-navires"
download 68afd505667d22d2c6d6bb4e "complements/lot4/journees-du-patrimoine-2025-dans-les-sites-labellises-patrimoine-d-interet-regio"
download 54340f3688ee387369b698a1 "complements/lot4/frequentation-des-salles-de-cinema"
download 5437e96d88ee387cb28f5e7d "complements/lot4/meilleurs-succes-du-cinema-depuis-1945"
download 5429829c88ee380327a59168 "complements/lot4/distribution-des-films-dans-les-salles-de-cinema"
download 543408d888ee38736ab698a1 "complements/lot4/profil-du-public-des-salles-de-cinema"
download 53789930a3a7295dd332d9e7 "complements/lot4/photographies-serie-monuments-historiques-de-1851-a-1914"
download 5369995fa3a729239d20522b "complements/lot4/egalite-hommes-femmes-dans-la-culture-et-la-communication"
download 5550cfd9c751df388e190c78 "complements/lot4/nuit-des-musees-programme-national-de-la-11eme-edition-le-16-mai-2015"
download 5d12ee8206e3e762c0c89a4c "complements/lot4/repertoire-des-musees-de-france-base-museofile"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
