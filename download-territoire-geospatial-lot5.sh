#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/territoire-geospatial"
LOG="/mnt/data/datasets/logs/territoire-geospatial-lot5-download.log"

mkdir -p "$(dirname "$LOG")"

mkdir -p \
  "$ROOT/developpement-urbain/foncier" \
  "$ROOT/developpement-urbain/politique-ville" \
  "$ROOT/developpement-urbain/friches" \
  "$ROOT/developpement-urbain/artificialisation" \
  "$ROOT/developpement-urbain/urbanisme"

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
# LOT 5 — DÉVELOPPEMENT URBAIN / FONCIER / ARTIFICIALISATION
# ============================================================================

download 5c4ae55a634f4117716d5656 "developpement-urbain/foncier/dvf"
download 5cc1b94a634f4165e96436c1 "developpement-urbain/foncier/dvf-geolocalisees"

download 5a561801c751df42d7fca9b6 "developpement-urbain/politique-ville/qpv"
download 61892a26c94e39bde1dbf7ac "developpement-urbain/friches/cartofriches"
download 6a01b9280dd2d45907e5fc61 "developpement-urbain/artificialisation/consommation-enaf-2011-2025"
download 673319c4104ba60b2030ed4d "developpement-urbain/urbanisme/loi-montagne"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
