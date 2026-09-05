#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/transport"
LOG="/mnt/data/datasets/logs/transport-lot2-download.log"

mkdir -p "$(dirname "$LOG")"

mkdir -p \
  "$ROOT/transports-collectifs/enquete-nationale" \
  "$ROOT/transports-collectifs/gtfs" \
  "$ROOT/covoiturage/lieux" \
  "$ROOT/covoiturage/trajets"

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
# LOT 2 — TRANSPORTS COLLECTIFS / GTFS / COVOITURAGE
# ============================================================================

download 64d634d0a44bad3832e40886 "transports-collectifs/enquete-nationale"

download 60d2b1e50215101bf6f9ae1b "transports-collectifs/gtfs/ile-de-france"
download 65af92d12d38ceffacb04812 "transports-collectifs/gtfs/bretagne"
download 632b2a8a8bf5b436bed4f8df "transports-collectifs/gtfs/pays-loire"
download 5f2c9a79e4e713875a58be26 "transports-collectifs/gtfs/bourgogne-franche-comte"
download 6425dda513316bf1ecaf7e4a "transports-collectifs/gtfs/corse-routier"
download 6425def83ddb5f9cfd9652b2 "transports-collectifs/gtfs/corse-ferroviaire"

download 5d6eaffc8b4c417cdc452ac3 "covoiturage/lieux/base-nationale"
download 5e8ee97c16601da4ee24ffb7 "covoiturage/trajets/registre-preuve"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
