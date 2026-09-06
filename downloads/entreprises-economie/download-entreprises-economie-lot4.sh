#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/socio-economie"
LOG="/mnt/data/datasets/logs/entreprises-economie-lot4-download.log"

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
download 697c9aa7d6bc970fff176361 "complements/lot4/donnees-brutes-sur-la-menace-concurrentielle-chinoise-pour-lindustrie-europeenne"
download 685e46377957c0d85f384bc1 "complements/lot4/base-sirene-v3-soissons"
download 69c5c9d75a6b1d1c005e46c7 "complements/lot4/reduction-de-l-impact-des-entreprises-sur-l-environnement"
download 68cbc45adf952493fcc0bd56 "complements/lot4/paot-2022-2027-actions-prevues-en-bretagne-industrie-reduction-des-rejets-substa"
download 68cbc431df952493fcc0bcf3 "complements/lot4/paot-2022-2027-actions-prevues-en-bretagne-industrie-reduction-des-rejets-substa"
download 68cbc450df952493fcc0bd3f "complements/lot4/paot-2022-2027-actions-prevues-en-bretagne-industrie-pollutions-portuaires-et-na"
download 68cbc40fdf952493fcc0bc95 "complements/lot4/paot-2022-2027-actions-prevues-en-bretagne-industrie-connaissance-des-pressions"
download 68cbc429df952493fcc0bcdc "complements/lot4/paot-2022-2027-actions-prevues-en-bretagne-industrie-autorisation-de-rejet"
download 68cbc448df952493fcc0bd2c "complements/lot4/paot-2022-2027-actions-prevues-en-bretagne-industrie-etude"
download 62bd63b70ff1edf452b83a6b "complements/lot4/liste-des-entreprises-rge"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
