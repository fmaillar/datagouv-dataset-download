#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/socio-economie"
LOG="/mnt/data/datasets/logs/socio-economie-lot5-download.log"

mkdir -p "$(dirname "$LOG")"

mkdir -p \
  "$ROOT/immigration/titres-sejour" \
  "$ROOT/immigration/asile" \
  "$ROOT/immigration/population"

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

# ============================================================================
# LOT 5 — POPULATION / IMMIGRATION / ASILE
# ============================================================================

# Stock et flux des titres de séjour — série nationale 2015-2024
download 6a8584948422257ba81b4150 "immigration/titres-sejour/2015"
download 6a857f5fca89c11d9f1d6c89 "immigration/titres-sejour/2016"
download 6a85b681b416ba2a1615fd5a "immigration/titres-sejour/2017"
download 6a85c3f776c914c4cac7055d "immigration/titres-sejour/2018"
download 6a86bc2bf7cfb89cc729c0d6 "immigration/titres-sejour/2019"
download 6a8825a04b4e0490e3ca09f3 "immigration/titres-sejour/2020"
download 6a883c8722d4b6a99be7e3da "immigration/titres-sejour/2021"
download 6a884177ba2735a3ffdfd811 "immigration/titres-sejour/2022"
download 6a8847a57f75b57601210300 "immigration/titres-sejour/2023"
download 6a884f10fa89847e4bd683cf "immigration/titres-sejour/2024"

# Demandes d'asile et transferts Dublin
download 67c028ea079dafeb2b5ea8ca "immigration/asile/2023"
download 6867a571c3b49b0c33f2fa73 "immigration/asile/2024"

# Publication nationale de référence de l'Insee
download 53699643a3a729239d20494b "immigration/population/immigres-descendants"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
