#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/finances-publiques"
LOG="/mnt/data/datasets/logs/finances-publiques-lot4-download.log"

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
download 53699546a3a729239d204693 "complements/lot4/execution-2012-du-budget-de-l-etat-en-ae-suivant-la-nomenclature-mission-program"
download 64ac9d02e0951b41b712a193 "complements/lot4/fiscalite-locale-des-professionnels"
download 66512b67b8c9abb821e5a98b "complements/lot4/fiscalite-locale-des-particuliers"
download 5e7b688ad0216647b33b1250 "complements/lot4/fiscalite-locale-a-antibes"
download 5ad0afe588ee3861b20f7c0d "complements/lot4/declarations-nationales-de-resultats-des-impots-professionnels-bic-is-bnc-et-ba"
download 64ac9d008a3ef9d72912a193 "complements/lot4/fiscalite-locale-des-professionnels-geo"
download 66512be37d2d55cbd2e5a98b "complements/lot4/fiscalite-locale-des-particuliers-geo"
download 678090e0f574dd6af0133b6d "complements/lot4/etablissement-public-de-cooperation-intercommunale-a-fiscalite-propre-dans-l-orn"
download 664337d4629c4313dc94b104 "complements/lot4/comptes-de-gestion-des-communes-de-la-metropole-de-lyon"
download 69795263711985c99898673e "complements/lot4/dotations-de-fonctionnement-versees-aux-lycees-de-la-region-centre-val-de-loire-"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
