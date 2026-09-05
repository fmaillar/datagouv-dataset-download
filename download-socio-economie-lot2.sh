#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/socio-economie"
LOG="/mnt/data/datasets/logs/socio-economie-lot2-download.log"

mkdir -p "$(dirname "$LOG")"

mkdir -p \
  "$ROOT/geographie-fine/iris" \
  "$ROOT/geographie-fine/carroyage" \
  "$ROOT/geographie-fine/filosofi" \
  "$ROOT/geographie-fine/rpls" \
  "$ROOT/geographie-fine/sirene"

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
# LOT 2 — GÉOGRAPHIE FINE / IRIS / CARROYAGES / DONNÉES GÉOLOCALISÉES
# ============================================================================

# IRIS / contours
download 55424b64c751df766fa7b26f "geographie-fine/iris/contours-iris-ign"
download 61489e33b77d1697d00d2fec "geographie-fine/iris/iris-ge-ign"
download 595915ada3a7291dd09c804f "geographie-fine/iris/contours-iris-idf"

# Population carroyée / fine
download 54abdee9c751df2fcd04805b "geographie-fine/carroyage/population-200m"
download 5369931ca3a729239d2040d1 "geographie-fine/carroyage/population-200m-ancienne-insee"
download 656fbdcf39613b5c17780a36 "geographie-fine/carroyage/occitanie-2020"
download 6279abeb7f2bbd82a89ddd2d "geographie-fine/carroyage/occitanie-2018"
download 656fbdcf9dee33c6e0780a36 "geographie-fine/carroyage/departements-2020"
download 624643145ba053f1cbeb4ce4 "geographie-fine/carroyage/departements-2018"

# Filosofi fin
download 684c4c9045e1b1cfad52b742 "geographie-fine/filosofi/ara-2015-200m"
download 67289477639527408ae687da "geographie-fine/filosofi/rp-filosofi-france-metropolitaine"
download 67f5bb0403325228295b7e85 "geographie-fine/filosofi/bordeaux-2021"

# RPLS géolocalisé / mailles fines
download 673eb2de4c91caa2357733c9 "geographie-fine/rpls/geolocalisation-hlm"
download 66c2ff224ea0a9d2ba6a62bf "geographie-fine/rpls/detail-2022"
download 63ce580d323b6878eca82ae4 "geographie-fine/rpls/detail-2021"

# SIRENE géocodé / régional
download 6597e4bbbecab41da48717c7 "geographie-fine/sirene/geoparquet-2024"
download 684c4c4145e1b1cfad52b665 "geographie-fine/sirene/ara-geocode"
download 5e3221ee9ce2e7433df7fb95 "geographie-fine/sirene/pays-loire-v3"
download 6349fab2bd7ea72afeeacfa4 "geographie-fine/sirene/bretagne"
download 6a0eba064780a16c39e21ba1 "geographie-fine/sirene/seine-saint-denis"
download 623bb50e9e3590664a927462 "geographie-fine/sirene/mulhouse-v3"
download 5f031c0284d60df5d5d06000 "geographie-fine/sirene/isere"
download 5d85a39106e3e776600e40e2 "geographie-fine/sirene/toulouse"
download 5e3221ed06e3e70507320baf "geographie-fine/sirene/maine-et-loire"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
