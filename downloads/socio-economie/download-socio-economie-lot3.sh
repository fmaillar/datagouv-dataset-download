#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/socio-economie"
LOG="/mnt/data/datasets/logs/socio-economie-lot3-download.log"

mkdir -p "$(dirname "$LOG")"

mkdir -p \
  "$ROOT/regional/bretagne" \
  "$ROOT/regional/pays-loire" \
  "$ROOT/regional/paca" \
  "$ROOT/historique/grand-poitiers" \
  "$ROOT/historique/dijon" \
  "$ROOT/historique/lyon" \
  "$ROOT/historique/somme" \
  "$ROOT/historique/doubs" \
  "$ROOT/historique/mortalite"

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

# ============================================================================
# LOT 3 — HISTORIQUE / RÉGIONAL
# ============================================================================

# Bretagne — recensement régional
download 684004232f9592aab088e170 "regional/bretagne/structure-population"
download 6840041b2f9592aab088e15a "regional/bretagne/emploi-population-active"
download 684004182f9592aab088e150 "regional/bretagne/evolution-population"
download 6840041a2f9592aab088e156 "regional/bretagne/formation"
download 6840041c2f9592aab088e15b "regional/bretagne/logement"
download 684004242f9592aab088e173 "regional/bretagne/menages"
download 684004282f9592aab088e17e "regional/bretagne/evolution-emploi"
download 68cbc41edf952493fcc0bcc0 "regional/bretagne/rpls-2014-2018"

# Pays de la Loire
download 63a24de564fe8067559dde9a "regional/pays-loire/population"
download 63a24df412fe2a442a9dde9b "regional/pays-loire/csp-2019"
download 63a24df4f3bf7ca5df9dde9c "regional/pays-loire/diplomes-2019"

# Provence-Alpes-Côte d'Azur
download 668d0a20a847603d391cbef6 "regional/paca/population-commune-2006-2014"
download 668d0a12a847603d391cbee4 "regional/paca/population-epci-2006-2014"
download 668d09f9a847603d391cbec1 "regional/paca/population-departement-2006-2014"
download 668d09f8a847603d391cbec0 "regional/paca/population-age-commune-2015"

# Historiques locaux structurés
download 58ef2d65a3a7293d49c4e183 "historique/grand-poitiers/recensement-series"
download 58ef2cd2a3a7293d49c4e177 "historique/grand-poitiers/recensement-communes"
download 662156e6b5a7116d9e79100e "historique/dijon/population-1968-2019"
download 611621ef015cc1e65f3c91cc "historique/lyon/population-annuelle-communes"

# Somme — série démographique communale
download 673818ebc1f7a9921ac40aaa "historique/somme/demographie-2006"
download 6738195ac1f7a9921ac40adc "historique/somme/demographie-2007"
download 6816fb7bdcf30d7430622e26 "historique/somme/demographie-2008"
download 68c24ccbc4dfb749b6724458 "historique/somme/demographie-2009"
download 6850eeedaf1ad5618052b664 "historique/somme/demographie-2011"
download 67381993c1f7a9921ac40aed "historique/somme/demographie-2012"
download 67381958c1f7a9921ac40ad7 "historique/somme/demographie-2013"

# Longue durée démographique
download 60d3cbea97e7cbc080f9ae1b "historique/doubs/recensements-1801-1936"
download 5369904fa3a729239d20398b "historique/mortalite/causes-deces-1925-1999"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
