#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/socio-economie"
LOG="/mnt/data/datasets/logs/entreprises-economie-lot3-download.log"

mkdir -p "$(dirname "$LOG")"
mkdir -p "$ROOT/complements/lot3"

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

# LOT 3 — COMPLÉMENTS THÉMATIQUES
download 667ebdd4547ab9bd6e4682d3 "complements/lot3/donnees-des-entreprises-utilisees-dans-l-annuaire-des-entreprises"
download 53699504a3a729239d2045bb "complements/lot3/etude-2008-evenement-de-vie-entreprises"
download 6149a5b090f7deb2468619cd "complements/lot3/sirenes-du-systeme-d-alerte-et-d-informations-aux-populations-saip-a-antibes-jua"
download 648096d1c0887c22a8495888 "complements/lot3/sirenes-d-alerte"
download 5ec3a046c9e9abed50d770a9 "complements/lot3/contenu-textuel-de-la-foire-aux-questions-info-entreprises-covid19"
download 631751d1cf8ce1b8ed7ac644 "complements/lot3/entreprises-installees-dans-les-locaux-de-la-pepiniere-delta"
download 598324dc88ee3848356dd30a "complements/lot3/entreprises-et-commerces-locaux-commune-de-mogneneins"
download 674a8e5d9d1a19af3a9636bb "complements/lot3/pamir-soutien-a-la-recherche-entites-du-reseau-du-dim-pamir-laboratoires-institu"
download 667e955551fb8c370827f640 "complements/lot3/gisement-de-dechets-non-dangereux-du-commerce-et-des-industries-dndae-en-bretagn"
download 648096d32697b64f06b9186c "complements/lot3/perimetre-de-portee-des-sirenes-d-alerte"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
