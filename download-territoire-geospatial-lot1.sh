#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/territoire-geospatial"
LOG="/mnt/data/datasets/logs/territoire-geospatial-lot1-download.log"

mkdir -p "$(dirname "$LOG")"

mkdir -p \
  "$ROOT/administratif/referentiels" \
  "$ROOT/administratif/communes" \
  "$ROOT/administratif/departements" \
  "$ROOT/administratif/epci" \
  "$ROOT/adresses/ban"

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
# LOT 1 — RÉFÉRENTIELS ADMINISTRATIFS / BAN
# ============================================================================

download 56ebf05fc751df7756cc7140 "administratif/referentiels/referentiel-geographique-francais"
download 685ab87ea35cf447867fd96a "administratif/referentiels/admin-express-cog-plus-2025"
download 5e313aa66f44413bf8c5ba4d "administratif/referentiels/evenements-communes-depuis-1943"

download 6663274a7683aed116fd1068 "administratif/communes/2023"
download 6663272b7683aed116fd104b "administratif/communes/2020"
download 666327577683aed116fd1074 "administratif/communes/2021"
download 666326827683aed116fd0f99 "administratif/communes/2022"
download 680197ff93473505d4622e41 "administratif/communes/2024"
download 6995047774be076493f1e1a7 "administratif/communes/2025"

download 666327357683aed116fd1055 "administratif/departements/2022"
download 5d79f02a634f4132bd8ee1c5 "administratif/departements/2019"
download 5d79f026634f4132ac9ea4c0 "administratif/departements/2018"

download 673a5e40a8c1a16ff52d9958 "administratif/epci/contours-2019"
download 68de28448d824fcc51b5e4fd "administratif/epci/loiret-decoupage"

download 5530fbacc751df5ff937dddb "adresses/ban/nationale"
download 60191f8eb95272904c26b615 "adresses/ban/etat-par-commune"
download 5fda75d3084b5fa14f89cd2f "adresses/ban/locaux-adressables-communes"
download 538071a9a3a7297e4d35d6ce "adresses/ban/bano"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
