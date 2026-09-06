#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/administration"
LOG="/mnt/data/datasets/logs/administration-lot2-download.log"

mkdir -p "$(dirname "$LOG")"
mkdir -p "$ROOT/complements/lot2"

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

# LOT 2 — COMPLÉMENTS THÉMATIQUES
download 53699fe5a3a729239d206232 "complements/lot2/fiches-pratiques-et-ressources-de-service-public-gouv-fr-particuliers"
download 5889d03fa3a72974cbf0d5b1 "complements/lot2/annuaire-de-l-education"
download 6564969d3579e21795ebd378 "complements/lot2/communes-et-inventaire-sru"
download 53ca2be2a3a7294a1ddd7847 "complements/lot2/associations-joafe"
download 53ca2e62a3a7294a1ddd784b "complements/lot2/comptes-associations"
download 61a92b5148113b5780a01cfb "complements/lot2/annuaire-des-exploitations-certifiees-haute-valeur-environnementale"
download 53699fe5a3a729239d206233 "complements/lot2/fiches-pratiques-et-ressources-entreprendre-service-public-gouv-fr"
download 53699fe3a3a729239d206225 "complements/lot2/service-public-gouv-fr-actualites-particuliers"
download 6176785207139a929a2776fe "complements/lot2/projets-finances-par-les-dotations-de-soutien-a-l-investissement-des-collectivit"
download 5e174be4634f414cd8a244f1 "complements/lot2/criteres-de-repartition-des-dotations-versees-par-letat-aux-collectivites-territ"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
