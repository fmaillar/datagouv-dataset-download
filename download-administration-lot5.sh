#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/administration"
LOG="/mnt/data/datasets/logs/administration-lot5-download.log"

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
download 68309fcb36ea9a6ee45f9cf4 "complements/lot5/fiches-pratiques-service-public-fr-vectorisees"
download 6322e99e12175f7eb26ff465 "complements/lot5/les-offres-diffusees-sur-choisir-le-service-public"
download 69f34e3b265117ee2f3d627f "complements/lot5/accord-cadre-interministeriel-realisation-de-services-publics-numeriques-en-mode"
download 62225f6a523b5729143b138c "complements/lot5/referentiel-structure-de-la-plateforme-services-publics-plus-de-la-ditp"
download 65f96d3d30c8e128529264a2 "complements/lot5/programmation-annuelle-des-achats-des-collectivites-bretonnes-volontaires"
download 61c26ac39bd57502b58b8e9e "complements/lot5/sla-annuaire-des-professionnels-de-sante"
download 5bcdc37a634f41327d733c29 "complements/lot5/annuaire-des-profils-acheteurs-des-adherents-de-megalis-bretagne"
download 67a3a1f4bb51187206427bdd "complements/lot5/annuaire-de-l-accessibilite-des-cabinets-sante-fr"
download 5458f03bc751df46e6225d2e "complements/lot5/recensement-indicatif-des-donnees-publiques-issues-des-services-publics-de-l-eta"
download 61b149402e4e55ff50993393 "complements/lot5/sla-annuaire-des-metiers-de-la-collectivite"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
