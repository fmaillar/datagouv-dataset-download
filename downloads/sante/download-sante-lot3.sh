#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/sante"
LOG="/mnt/data/datasets/logs/sante-lot3-download.log"

mkdir -p "$(dirname "$LOG")"

mkdir -p \
  "$ROOT/epidemiologie/covid-19" \
  "$ROOT/epidemiologie/grippe" \
  "$ROOT/prevention/vaccination" \
  "$ROOT/cancer/incidence" \
  "$ROOT/cancer/activite-etablissements"

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
# LOT 3 — ÉPIDÉMIOLOGIE / PRÉVENTION / CANCER
# ============================================================================

download 5f69ecb155c43420918410b8 "epidemiologie/covid-19/vue-ensemble"
download 5e74ecf52eb7514f2d3b8845 "epidemiologie/covid-19/urgences-sos-medecins"
download 619f5f9c38e27e934733e60b "epidemiologie/covid-19/esms"
download 53699327a3a729239d2040f6 "epidemiologie/grippe/surveillance"

download 63a0368afe0e9c47c3bbde9d "prevention/vaccination/professionnels-etablissements"
download 60cb52a2d6477a292b8cfbcd "prevention/vaccination/professionnels-liberaux"

download 6971f40c34e6cbb1788a508d "cancer/incidence/1990-2023"
download 68f238920753d399dd27c361 "cancer/activite-etablissements"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
