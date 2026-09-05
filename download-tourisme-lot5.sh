#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/tourisme"
LOG="/mnt/data/datasets/logs/tourisme-lot5-download.log"

mkdir -p "$(dirname "$LOG")"
mkdir -p "$ROOT/complements/lot5"

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

# LOT 5 — COMPLÉMENTS THÉMATIQUES
download 5fdaa17540b22ccf1e1f7cbe "complements/lot5/to-delete-liste-des-etablissements-labellises-tourisme-et-handicap"
download 5dddbf399ce2e72e15b62c0a "complements/lot5/hebergements-touristiques-en-region-centre-val-de-loire"
download 5dddbf379ce2e72e15b62c09 "complements/lot5/hebergements-locatifs-touristiques-meubles-et-chambres-d-hotes-en-region-centre-"
download 5dddbf389ce2e72e0fb62c0a "complements/lot5/hebergements-touristiques-collectifs-en-region-centre-val-de-loire"
download 5950cc9888ee384bd5eabd8e "complements/lot5/tourisme"
download 5ed7c76398c0da12698f167d "complements/lot5/tourisme-communaute-de-communes-des-coevrons"
download 68c362a46e58a6c28e724405 "complements/lot5/hebergements-touristiques-en-region-centre-val-de-loire"
download 6970bad8a4a1ec1721209cd9 "complements/lot5/evenements-publics-recenses-par-l-office-de-tourisme-intercommunal-ventoux-prove"
download 59591c01a3a7291dcf9c8140 "complements/lot5/carte-des-campings-classes"
download 5761babc88ee382661640391 "complements/lot5/le-secteur-du-tourisme"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
