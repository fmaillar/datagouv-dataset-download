#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/administration"
LOG="/mnt/data/datasets/logs/administration-lot1-download.log"

mkdir -p "$(dirname "$LOG")"
mkdir -p \
  "$ROOT/annuaires" \
  "$ROOT/associations" \
  "$ROOT/fonction-publique/effectifs" \
  "$ROOT/fonction-publique/metiers"

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

# LOT 1 — ANNUAIRES / ASSOCIATIONS / FONCTION PUBLIQUE
download 53699fe4a3a729239d206227 "annuaires/service-public"
download 688201cd45ea9d6bf4921b95 "annuaires/service-public-vectorise"
download 67a5cd40941cbe4c206efcd1 "annuaires/administrations-espace-agent"
download 58e53811c751df03df38f42d "associations/repertoire-national"
download 5c4b0be98b4c412d41f1fdba "fonction-publique/effectifs/ensemble-depuis-2004"
download 5c4b0d2d8b4c413b7e935b3b "fonction-publique/effectifs/territoriale-depuis-2004"
download 5c4b0e3b8b4c41376792089 "fonction-publique/effectifs/etat-depuis-1998"
download 6519b123191e8d7297069700 "fonction-publique/metiers/referentiel"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
