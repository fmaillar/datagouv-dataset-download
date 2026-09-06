#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/socio-economie"
LOG="/mnt/data/datasets/logs/entreprises-economie-lot2-download.log"

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
download 53698e6aa3a729239d203466 "complements/lot2/activite-productrice-des-entreprises"
download 5d9215888b4c415092182f79 "complements/lot2/enquete-sur-les-entreprises-et-le-developpement-durable"
download 53699260a3a729239d203ee9 "complements/lot2/demographie-des-entreprises"
download 6587efa36e80ab61d5792fdd "complements/lot2/donnees-financieres-detaillees-des-entreprises-format-parquet"
download 6111ca4eceb85a1af39e9f47 "complements/lot2/repertoire-des-entreprises"
download 61aa0bd2c564b431e34ed799 "complements/lot2/sla-base-sirene-etablissements-actifs"
download 5c6f5987634f41317c8a0f14 "complements/lot2/commerce-exterieur-en-polynesie-francaise"
download 61a10eb9d79d475a65afd578 "complements/lot2/liste-des-entreprises-agreees-pour-le-materiel-des-casinos"
download 53699506a3a729239d2045bd "complements/lot2/etude-2010-evenement-de-vie-entreprises"
download 53d386c5a3a72904270136b2 "complements/lot2/les-entreprises-et-federations-partenaires-2013"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
