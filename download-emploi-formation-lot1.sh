#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/socio-economie"
LOG="/mnt/data/datasets/logs/emploi-formation-lot1-download.log"

mkdir -p "$(dirname "$LOG")"
mkdir -p \
  "$ROOT/emploi/chomage" \
  "$ROOT/emploi/recensement" \
  "$ROOT/emploi/metiers" \
  "$ROOT/emploi/recrutements" \
  "$ROOT/formation/apprentissage"

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

# LOT 1 — EMPLOI / MÉTIERS / APPRENTISSAGE
download 561fbf0d88ee3836b1628efb "emploi/chomage/demandeurs-france-travail"
download 53699434a3a729239d2043b3 "emploi/chomage/enquete-emploi-continu"
download 6a430a74994f73a50d54d378 "emploi/recensement/formes-temps-travail"
download 65f4e1142b6f0e75cc7cd1aa "emploi/metiers/fiches-onisep"
download 5fa5e38978ad06b169de1e1d "emploi/metiers/referentiel-onisep"
download 59593615a3a7291dcf9c8272 "emploi/recrutements/sncf-metiers"
download 60b5b0ed2571d1002e2fcb3e "formation/apprentissage/inserjeunes-cfa"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
