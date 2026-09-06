#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/socio-economie"
LOG="/mnt/data/datasets/logs/entreprises-economie-lot5-download.log"

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
download 53698f4ea3a729239d2036ee "complements/lot5/base-de-donnees-des-obligations-d-information-pesant-sur-les-entreprises"
download 53699c14a3a729239d2058b5 "complements/lot5/perimetre-des-interventions-economiques-analysees-dans-le-cadre-de-la-mission-ma"
download 53699836a3a729239d204eca "complements/lot5/les-entreprises-et-federation-partenaires-2012"
download 67daa1e510033ddb00612abd "complements/lot5/subventions-organisation-gip-les-entreprises-s-engagent"
download 66fde00a0d497789e7436d9f "complements/lot5/entreprises-du-patrimoine-vivant-epv"
download 624fdbbbf68a3666d6fe7af1 "complements/lot5/historique-des-entreprises-rge-depuis-2014"
download 62dfe1518bcb48c2eb805b6d "complements/lot5/base-sirene-de-la-metropole-de-lyon"
download 6132b8007c4562a7d32bd965 "complements/lot5/plan-de-relance-industrie-du-futur-nombre-de-beneficiaires-et-montants-par-depar"
download 53699794a3a729239d204d1e "complements/lot5/la-base-economique-des-entreprises-regionales"
download 635a0251dc41dc073190f690 "complements/lot5/entreprises-salaries-des-secteurs-culturels-par-region"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
