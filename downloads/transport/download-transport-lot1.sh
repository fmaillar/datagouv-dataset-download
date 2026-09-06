#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/transport"
LOG="/mnt/data/datasets/logs/transport-lot1-download.log"

mkdir -p "$(dirname "$LOG")"

mkdir -p \
  "$ROOT/accidents/baac" \
  "$ROOT/ponctualite" \
  "$ROOT/bornes-recharge" \
  "$ROOT/trafic-routier" \
  "$ROOT/infrastructures-ferroviaires" \
  "$ROOT/enquetes-mobilite"

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
# LOT 1 — MOBILITÉ / SÉCURITÉ / INFRASTRUCTURES
# ============================================================================

download 53698f4ca3a729239d2036df "accidents/baac"
download 5dbd4a3a634f4140741cb9ad "ponctualite/statistiques-transports"
download 685965d0ab901919e14a4a1b "bornes-recharge/irve-national"
download 53699134a3a729239d203bd2 "trafic-routier/comptages-france"

download 6067e89b0aa12cfb479a7ce8 "infrastructures-ferroviaires/operateurs-rfn"
download 5f603c9607bc385c2b8f0771 "infrastructures-ferroviaires/voies-rfn"
download 5b220199a3a7297ffee6cc23 "infrastructures-ferroviaires/lignes-rfn"

download 6285e9adf8a6866bbd8bddb9 "enquetes-mobilite/personnes-2018-2019"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
