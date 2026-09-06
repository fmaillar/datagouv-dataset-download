#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/socio-economie"
LOG="/mnt/data/datasets/logs/socio-economie-lot6-download.log"

mkdir -p "$(dirname "$LOG")"

mkdir -p \
  "$ROOT/immigration/publications" \
  "$ROOT/immigration/titres-sejour-publications" \
  "$ROOT/immigration/asile-publications" \
  "$ROOT/immigration/visas" \
  "$ROOT/immigration/nationalite"

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
# LOT 6 — IMMIGRATION / SÉJOUR / ASILE — PUBLICATIONS HISTORIQUES
# ============================================================================

download 634962e4948c40913cf42383 "immigration/publications/principales-donnees-2021-01"
download 64abf15ad2ce05cea3ae0cab "immigration/publications/principales-donnees-2023-01"
download 64aff23b39cbec21a95aead8 "immigration/publications/principales-donnees-2023-06"

download 634e6170251dc233df33519f "immigration/titres-sejour-publications/2022-01"
download 634e7ca88a0cb8f79ca52501 "immigration/titres-sejour-publications/2022-06"
download 64ae589cd875cd094783bf75 "immigration/titres-sejour-publications/2023-01"
download 64ba96bde5b7ba2977b8d87a "immigration/titres-sejour-publications/2023-06"
download 66a0c275b4f7df2474efdb0a "immigration/titres-sejour-publications/2024-01"
download 66a8cc809b4750710f18920c "immigration/titres-sejour-publications/2024-06"

download 634d585bf4bfe3b787a8a6d1 "immigration/asile-publications/2022-01"
download 634e77da273b450a86b0fced "immigration/asile-publications/2022-06"
download 582d6c2bc751df3077c0bb7e "immigration/visas/2006-2016"
download 53698e13a3a729239d203389 "immigration/nationalite/acquisitions-2013"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
