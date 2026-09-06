#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/territoire-geospatial"
LOG="/mnt/data/datasets/logs/territoire-geospatial-lot3-download.log"

mkdir -p "$(dirname "$LOG")"

mkdir -p \
  "$ROOT/topographie/bd-topo" \
  "$ROOT/topographie/relief" \
  "$ROOT/hydrographie/bd-topage" \
  "$ROOT/topographie/ign"

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
# LOT 3 — BD TOPO / RELIEF / HYDROGRAPHIE
# ============================================================================

download 61489083dc4223219e50cc35 "topographie/bd-topo/nationale"
download 69698191770f993ed4817ed2 "topographie/bd-topo/historique"
download 601c8d57cdfa0f394ac1ff90 "topographie/bd-topo/occitanie-v3-3-2024"

download 675871c36e60265b46ab3579 "topographie/relief/france-relief-beta"
download 692f7e9ad587651515eb69b5 "topographie/relief/bd-alti-bretagne"

download 666326cd7683aed116fd0ff3 "hydrographie/bd-topage/bassins-metropole-2019"
download 6663267b7683aed116fd0f8d "hydrographie/bd-topage/bassins-metropole-2023"
download 6a39cee98ea7947128467384 "hydrographie/bd-topage/bassins-metropole-2026"
download 68f820543fa6f1fc1c261cc8 "hydrographie/bd-topage/cours-eau-police-ara"

download 61488c8c6c3e156d4c83f979 "topographie/ign/plan-ign"
download 6a4b7f861d7ecb5a4eb55b14 "topographie/ign/bd-carto-occitanie"
download 6a4b7f451d7ecb5a4eb55aba "topographie/ign/regions-france-bd-carto"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
