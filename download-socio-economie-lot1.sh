#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/socio-economie"
LOG="/mnt/data/datasets/logs/socio-economie-download.log"

mkdir -p "$(dirname "$LOG")"

mkdir -p \
  "$ROOT/demographie/population" \
  "$ROOT/demographie/recensement-detail" \
  "$ROOT/demographie/etat-civil" \
  "$ROOT/revenus-pauvrete" \
  "$ROOT/emploi-salaires" \
  "$ROOT/menages" \
  "$ROOT/logement" \
  "$ROOT/entreprises/sirene" \
  "$ROOT/entreprises/creations" \
  "$ROOT/mobilite-domicile-travail"

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
# DÉMOGRAPHIE / POPULATION
# ============================================================================

download 53699d0ea3a729239d205b2e \
  "demographie/population/population-insee"

download 6960460d981fc53b04b2f068 \
  "demographie/population/structure-series-longues"

download 67e34386efc54deb6b388bac \
  "demographie/population/populations-reference"

download 695316a64f759c9dba5182e5 \
  "demographie/population/populations-municipales-1968-2023"

download 666cdab72f594c83c2c4be20 \
  "demographie/population/estimations-localisees-series-longues"

download 685d96290b33ade4e2634262 \
  "demographie/population/recensement-serie-historique"

# ============================================================================
# RECENSEMENT — FICHIERS DÉTAILLÉS INSEE
# ============================================================================

download 548ad919c751df3d674120e7 \
  "demographie/recensement-detail/catalogue"

download 653668616ffc5fc0becb52b4 \
  "demographie/recensement-detail/logements-ordinaires"

download 6a430a7e994f73a50d54d390 \
  "demographie/recensement-detail/pop1-sexe-age"

download 6a430a7e994f73a50d54d38f \
  "demographie/recensement-detail/pop2-sexe-age-categorie"

download 6a430a7b994f73a50d54d38a \
  "demographie/recensement-detail/nat1-nationalite"

download 6a430a71994f73a50d54d370 \
  "demographie/recensement-detail/act1-population-active"

download 6a430a72994f73a50d54d374 \
  "demographie/recensement-detail/for2-diplomes-formation"

# ============================================================================
# MÉNAGES
# ============================================================================

download 6a430a79994f73a50d54d383 \
  "menages/men4-taille"

download 6a430a79994f73a50d54d385 \
  "menages/men5-men6-age-type"

download 6a430a79994f73a50d54d384 \
  "menages/men1-men2-pcs"

download 6a430a78994f73a50d54d382 \
  "menages/men7-cohabitation"

# ============================================================================
# REVENUS / PAUVRETÉ / NIVEAU DE VIE
# ============================================================================

download 5b156279c751df40bb588de9 \
  "revenus-pauvrete/filosofi-revenus-localises"

download 5d8e16106f44410332a79994 \
  "revenus-pauvrete/carroyage"

download 66fd2924ca43b044d55a7b74 \
  "revenus-pauvrete/filosofi-carroyage-2019-2021"

download 68c2896fc7b6121d990246d3 \
  "revenus-pauvrete/indicateurs-national-infradepartemental"

download 68c27c8bc543c5ee3e524838 \
  "revenus-pauvrete/indicateurs-individus-menages"

download 6a6a945281973a7cbe4ebe17 \
  "revenus-pauvrete/series-1996-2024-retropolees"

download 6a6a945281973a7cbe4ebe16 \
  "revenus-pauvrete/series-1975-2024"

download 687ae011ddfd9c43eb553747 \
  "revenus-pauvrete/niveau-vie-2023"

# ============================================================================
# EMPLOI / CHÔMAGE / SALAIRES
# ============================================================================

download 685d96230b33ade4e2634257 \
  "emploi-salaires/population-active-chomage"

download 693766cdda0a99f141cb6a2e \
  "emploi-salaires/salaires-fonction-publique-series-longues"

download 67f85d14377ef83a019ac740 \
  "emploi-salaires/salaires-prive-series-longues"

download 68bab0ea28430ae0a818baf3 \
  "emploi-salaires/salaires-ensemble"

download 67f85d13377ef83a019ac73f \
  "emploi-salaires/salaires-prive-csp"

download 693766ccda0a99f141cb6a2d \
  "emploi-salaires/salaires-public-csp"

download 536992d0a3a729239d20400d \
  "emploi-salaires/emplois-public-prive-salaires"

download 68082f308080d9dd71622e35 \
  "emploi-salaires/salaires-prive-sexe-age-commune"

# ============================================================================
# LOGEMENT / RPLS
# ============================================================================

download 6a46fd6b019ce7ee86398eaa \
  "logement/parc-logements-series-longues"

download 689c42dc21932fa1640d99c3 \
  "logement/rpls-detail-logement"

download 61dc6f4a673f9b5ffe0c29c1 \
  "logement/rpls-iris-qpv"

# ============================================================================
# ENTREPRISES / SIRENE
# ============================================================================

download 5b7ffc618b4c4169d30727e0 \
  "entreprises/sirene/base-nationale"

download 61d5e2d372a52d9f9411ff88 \
  "entreprises/sirene/geolocalisation-etablissements"

download 698e69bcebf3fdf6036e38f1 \
  "entreprises/creations/series-longues"

download 683f8e749bf2fdce342f1777 \
  "entreprises/creations/formes-legales"

download 683f8e739bf2fdce342f1774 \
  "entreprises/creations/secteurs-a21"

download 6a73d0613000b965ffaa3470 \
  "entreprises/creations/communes-a10"

# ============================================================================
# MOBILITÉS DOMICILE-TRAVAIL
# ============================================================================

download 6a430a7c994f73a50d54d38c \
  "mobilite-domicile-travail/nav1-sexe-age"

download 6a430a7d994f73a50d54d38d \
  "mobilite-domicile-travail/nav2-lieu-mode"

download 685d96280b33ade4e2634260 \
  "mobilite-domicile-travail/principaux-indicateurs"

# ============================================================================
# ÉTAT CIVIL
# ============================================================================

download 695ef57166181f79930a16bf \
  "demographie/etat-civil/naissances-fecondite-series-longues"

download 67e34385efc54deb6b388baa \
  "demographie/etat-civil/naissances-annuelles-commune"

download 695ef56c66181f79930a16be \
  "demographie/etat-civil/deces-mortalite-series-longues"

download 67e34386efc54deb6b388bab \
  "demographie/etat-civil/deces-annuels-commune"

download 67e34383efc54deb6b388ba6 \
  "demographie/etat-civil/deces-quotidiens-mensuels"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
