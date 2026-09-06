#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/sante"
LOG="/mnt/data/datasets/logs/sante-lot2-download.log"

mkdir -p "$(dirname "$LOG")"

mkdir -p \
  "$ROOT/depenses/assurance-maladie" \
  "$ROOT/depenses/medicaments" \
  "$ROOT/depenses/biologie" \
  "$ROOT/depenses/dispositifs-medicaux" \
  "$ROOT/pathologies" \
  "$ROOT/hospitalisation/smr"

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
# LOT 2 — DÉPENSES / MÉDICAMENTS / PATHOLOGIES
# ============================================================================

download 54de1e8fc751df388646738b "depenses/assurance-maladie/open-damir"
download 566e964188ee3875beaf0bf5 "depenses/medicaments/open-medic"
download 594a63cec751df347daad517 "depenses/medicaments/open-phmev"
download 58d3c14bc751df6883298f1c "depenses/biologie/open-bio"
download 5b45f757c751df102525972a "depenses/dispositifs-medicaux/open-lpp"

download 62b31f7b128643f46ea1f848 "pathologies/effectifs"
download 62b31f7b56938a09d9538362 "pathologies/depenses-remboursees"
download 62b31f7b2056861cb4a1f848 "pathologies/comorbidites"

download 6a6a2726d3f549ac534ebe27 "hospitalisation/smr/activite-pathologies"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
