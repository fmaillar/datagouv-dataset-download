#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/energie"
LOG="/mnt/data/datasets/logs/energie-lot1-download.log"

mkdir -p "$(dirname "$LOG")"
mkdir -p \
  "$ROOT/electricite" \
  "$ROOT/consommation" \
  "$ROOT/installations/registre"

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

# LOT 1 — CONSOMMATION / PRODUCTION / INSTALLATIONS
download 55f0463d88ee3849f5a46ec1 "electricite/consommation-production-co2-echanges"
download 65e2979e41fa6389c8eb5b57 "consommation/iris"
download 65f1185fd7321d8e647ba548 "consommation/commune"
download 65f1185fbb16ea436d7ba548 "consommation/departement"
download 65f118613e0e630d9f924b52 "consommation/epci"

download 5ed5ced55454365371179ef4 "installations/registre/2019"
download 6042fecac08756b00d7a57de "installations/registre/2020"
download 62355567868a58b8316723e3 "installations/registre/2021"
download 64377e959b978c3f19538672 "installations/registre/2022"
download 65f125f4f1d232d84e924b51 "installations/registre/2023"
download 67d8f02e4d7033a78a52ce3d "installations/registre/2024"
download 69c4af4e5c9f9567df414fc6 "installations/registre/2025"
download 5bfcc5a006e3e744e304ccf0 "installations/registre/2026"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
