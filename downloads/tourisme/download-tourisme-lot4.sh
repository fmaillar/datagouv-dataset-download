#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/tourisme"
LOG="/mnt/data/datasets/logs/tourisme-lot4-download.log"

mkdir -p "$(dirname "$LOG")"
mkdir -p "$ROOT/complements/lot4"

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

# LOT 4 — COMPLÉMENTS THÉMATIQUES
download 5cf4d3908b4c415043d31f79 "complements/lot4/bp2019-office-de-tourisme-communautaire"
download 6152d0adef276056de55cbfe "complements/lot4/pepinieres-et-hotels-d-entreprises-sur-le-territoire-de-la-cu-caen-la-mer"
download 660bf8c3b504b24a6b00c533 "complements/lot4/stations-classees-de-tourisme-en-haute-savoie"
download 683f8d4555cba033dc2f1785 "complements/lot4/openstreetmap-tourisme-lignes"
download 66a438f63c1d7adf3a8e70bb "complements/lot4/tarifs-appliques-en-2025-pour-l-office-de-tourisme"
download 682edf34db1c1f1909848cd9 "complements/lot4/ecolabel-europeen-hebergements-touristiques-francais"
download 683f8d1955cba033dc2f176f "complements/lot4/openstreetmap-tourisme-points"
download 683f8d5f55cba033dc2f1795 "complements/lot4/openstreetmap-tourisme-polygones"
download 6941f348018e3a466784ac8d "complements/lot4/tarifs-appliques-en-2026-pour-l-office-du-tourisme"
download 69a6530d52b6d68bf32f5498 "complements/lot4/donnees-de-frequentation-des-lieux-de-tourisme-dans-le-departement-de-l-orne-ent"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
