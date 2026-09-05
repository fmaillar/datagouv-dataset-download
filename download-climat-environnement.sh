#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/climat-environnement"
LOG="/mnt/data/datasets/logs/climat-environnement-download.log"

mkdir -p "$(dirname "$LOG")"

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
# LOT 1
# ============================================================================

# Qualité de l'air
download 6729ed3a87591d8ff72ab95c "qualite-air/atmo-data"
download 6149925a2ff0ab6cebdd6fe8 "qualite-air/indice-atmo"
download 67f79b112ceb5b1df4c25a8b "qualite-air/prevair-previsions"
download 67f8c966c92603a7a776f4f1 "qualite-air/prevair-analyses"
download 689c42bb521ccf80ce954f81 "qualite-air/sdes-national"
download 689c42c0bf3f3901d8aa171f "qualite-air/sdes-territorial"

# Gaz à effet de serre
download 6729ea0c4fc557c93d0c8cec "ges/atmo-france"
download 684fe469b7b33d836a115539 "ges/projections-nationales"
download 60b0a8760400f4c54e5ca05e "ges/quotas-ue"
download 65c0e835c48bd8b0e5db9076 "ges/domicile-travail"

# Déchets
download 678696dfc84aa624432ce778 "dechets/sdes"
download 577225c888ee383112ab6512 "dechets/inventaire-radioactif"
download 649af611eaa8b9950ea5b3e8 "dechets/trackdechets"
download 5d7f639e8b4c412cf8b8500c "dechets/insee-industrie"
download 5d7f4da08b4c415e9fd832f1 "dechets/insee-commerce"
download 5f637e78444bc28c04a6e1c3 "dechets/sinoe-decheteries"
download 5f6463ee271bb37526f5907c "dechets/sinoe-destination"

# Sols
download 5863714388ee3863df3f4e5d "sols/corine-land-cover"
download 69380f267975cac439339b63 "sols/humidite-sols"
download 67cad6eaf4bd7e3f3d82ff9e "sols/sequestration-carbone"

# Biodiversité
download 60f83b6ee3f89c4005e598c4 "biodiversite/atlas-communaux"
download 66d1ac0abfa15762753d8355 "biodiversite/mesures-compensatoires-france"

# Climat
download 5b7a8d52634f41121f319b4c "climat/archives-quotidiennes"
download 5b87f1568b4c417e46a85e4a "climat/archives-mensuelles"
download 6881dde3c144ee824f457f53 "climat/france-2c"
download 6881ddbfcb27381d10700f71 "climat/france-2-7c"
download 6881dda16713843e52a08c07 "climat/france-4c"
download 6641c562e5acdb35c0e6051d "climat/lcz"

# Sécheresse
download 6470b39cfbad66b8c265ada3 "secheresse/propluvia"
download 662a5e2cd71b24df5e9a0827 "secheresse/vigieau"

# ============================================================================
# LOT 2
# ============================================================================

# Biodiversité / OFB
download 66601a4032498dd005f23baa "biodiversite/pressref"
download 6a58229277c58f2d2ec27a21 "biodiversite/abc-projets"
download 6a581fd077c58f2d2ec276f9 "biodiversite/marine-estuaires"
download 6a58230577c58f2d2ec27a96 "biodiversite/marine-occupation-sols"
download 6a58232277c58f2d2ec27ab3 "biodiversite/retex-eolien"

# Occupation des sols
download 6a581f5e77c58f2d2ec2765c "occupation-sols/clc-ofb-region"
download 6a58222377c58f2d2ec279b9 "occupation-sols/clc-ofb-departement"
download 6a5822c477c58f2d2ec27a54 "occupation-sols/clc-ofb-commune"
download 6a58246c77c58f2d2ec27bd5 "occupation-sols/clc-ofb-parent"
download 6a581f1077c58f2d2ec275f0 "occupation-sols/mayotte"
download 624527b28abc53a3f158ffdc "occupation-sols/loire-atlantique"

# Climat complémentaire
download 5b7ec60c8b4c410775324e55 "climat/archives-aerologiques"
download 5b7eaa3d8b4c415a11a8ca82 "climat/archives-infraquotidiennes"
download 6881ddcf5007d087eddf4401 "climat/vague-chaleur-2c"
download 6881ddb0f0744368d0818da6 "climat/vague-chaleur-2-7c"
download 6881dd8f1b98d332a72cbfb1 "climat/vague-chaleur-4c"
download 628e0500943ff94edb9275f9 "climat/stations-synop"

# Déchets complémentaires
download 614adde800eeb2f8ac95be12 "dechets/ademe-produits"
download 6763da0a8e03c6a65efb4a70 "dechets/economie-circulaire"
download 5d3824836f444107bf9d9707 "dechets/sinoe-isdnd"
download 67cad6f0f4bd7e3f3d82ffa0 "dechets/taux-valorisation"
download 6a714ab7f831ef3b43cfdcd2 "dechets/stockage-dma"

# Sécheresse complémentaire
download 680197a093473505d4622e1b "secheresse/mayotte"
download 685d7e7fec5a7481ab63428e "secheresse/pdl-superficielles"
download 685d7e7cec5a7481ab63428c "secheresse/pdl-souterraines"
download 685d7e7dec5a7481ab63428d "secheresse/pdl-eau-potable"

# Risques naturels
download 68f6cd9967faa5fcc0261ca8 "risques-naturels/pprn-isere-aleas"
download 6863a8863492920481cfefaa "risques-naturels/pprn-isere-perimetres"
download 686251b7b6576ee57df6129f "risques-naturels/pprn-na-inondation"
download 673773cd1881e8d970c2538a "risques-naturels/oleron-feux-littoral"
download 674661f98731a4f47077341f "risques-naturels/submersion-hdf"

# ============================================================================
# LOT 3
# ============================================================================

# CO2 / transports / grands opérateurs
download 618bbfa6adc9cbcdf94a1318 "co2/edf-par-pays"
download 66fcc59a93564dca19679c31 "co2/sncf-usage"
download 66fcc59d93564dca19679c32 "co2/sncf-complet"
download 53ba4c07a3a729219b7bead3 "co2/vehicules-ademe"
download 691dcc1b4a50a5b0a65889c8 "co2/trafic-aerien-dgac"
download 69b98829c2fa6a1b56676adc "co2/mobilite-hebdomadaire"
download 6895bfb71930a5b1cff0e980 "co2/domicile-travail"

# Eau / qualité
download 6a5824c377c58f2d2ec27c1f "eau/qualite/parc-marin-estuaires-picards"
download 68cbc449df952493fcc0bd2e "eau/qualite/seine-aval-temps-reel"
download 6970c63a13006c1235209ce5 "eau/qualite/stations-val-oise"
download 67fde2999ab3bd79d09ac72f "eau/qualite/etat-ecologique-val-oise"

# Sols / pollution / propriétés
download 5d4dd16c6f444161e140abc9 "sols/base-sols-pollues"
download 623847761c49d72dda5a4359 "sols/argiles-catastrophes-naturelles"
download 646491d18b36cfe7da2c4232 "sols/terra-occitania"
download 68b7ca8ae9efbdc6298dc187 "sols/pollution-sup-normandie"
download 6a633dd9c2298f03e19a9bfc "occupation-sols/guyane-2015"

# Biodiversité régionale structurante
download 67373dca8cf405ef3cc253fc "biodiversite/srce-normandie"
download 6835e1edb63a9d35e7858984 "biodiversite/reservoirs-idf"
download 6859f1512aaba1762552b8ca "biodiversite/reservoirs-auvergne"
download 67373edeec00afe5cdc40c12 "biodiversite/srce-lorraine"
download 68cbc40edf952493fcc0bc91 "biodiversite/reservoirs-bretagne"
download 684af8184cf6f9dd2aadff1f "biodiversite/tvb-pays-loire"
download 6a03345fc762c94feac14ac8 "biodiversite/tvb-grand-est-2025"
download 5ebd3ee87d7c3b66d08cf4fd "biodiversite/observations-ecrins"

# Sécheresse / hydrographie
download 684af7a44cf6f9dd2aadfdfa "secheresse/zones-alerte-pays-loire"
download 687b26975476a29aabff1389 "secheresse/eaux-souterraines-paca"
download 68cbc45fdf952493fcc0bd63 "secheresse/schapi-debits-seuils"
download 673779e6871a62e16cc40c12 "secheresse/gard-eaux-superficielles"
download 67377840871a62e16cc40aa5 "secheresse/gard-eaux-souterraines"
download 6a3f1b28e00747006c54d32a "secheresse/bouches-rhone-secteurs-hydro"

# ============================================================================
# LOT 4 — Eau / hydrologie nationale
# ============================================================================

# Prélèvements / services d'eau / qualité des eaux souterraines
download 5d79f0298b4c412a75293c7b "eau/prelevements/stations-qualite-eaux-superficielles"
download 6a582159f9121211f67fa59c "eau/sispea/services-publics-eau-potable"
download 53699e7ba3a729239d205eb0 "eau/qualite/ades-eaux-souterraines-france"

# Masses d'eau — cours d'eau
download 666326fa7683aed116fd101b "eau/masses-eau/cours-eau/rapportage-2010"
download 597b4504c751df0709bff25c "eau/masses-eau/cours-eau/rapportage-2016"
download 6663272d7683aed116fd104d "eau/masses-eau/cours-eau/etat-lieux-2019"
download 6801982793473505d4622e4b "eau/masses-eau/cours-eau/rapportage-2022"

# Masses d'eau — plans d'eau
download 666327267683aed116fd1044 "eau/masses-eau/plans-eau/rapportage-2010"
download 597b451188ee383b7e823d60 "eau/masses-eau/plans-eau/rapportage-2016"
download 666326c57683aed116fd0fe7 "eau/masses-eau/plans-eau/etat-lieux-2019"
download 680197ed93473505d4622e3a "eau/masses-eau/plans-eau/rapportage-2022"

# Masses d'eau — eaux côtières
download 6663274f7683aed116fd106d "eau/masses-eau/cotieres/rapportage-2010"
download 6801979693473505d4622e18 "eau/masses-eau/cotieres/rapportage-2016"
download 666327037683aed116fd1025 "eau/masses-eau/cotieres/etat-lieux-2013"
download 680197aa93473505d4622e1e "eau/masses-eau/cotieres/rapportage-2022"

# Masses d'eau — eaux de transition
download 6663267c7683aed116fd0f8e "eau/masses-eau/transition/rapportage-2010"
download 597b4513c751df06dd254d4a "eau/masses-eau/transition/rapportage-2016"
download 6801980593473505d4622e43 "eau/masses-eau/transition/rapportage-2022"

# Masses d'eau — eaux souterraines
download 666327457683aed116fd1065 "eau/masses-eau/souterraines/rapportage-2010"
download 666327637683aed116fd107c "eau/masses-eau/souterraines/etat-lieux-2019"
download 6801981193473505d4622e48 "eau/masses-eau/souterraines/rapportage-2022"

# Polygones élémentaires des masses d'eau souterraines
download 666326ac7683aed116fd0fcc "eau/masses-eau/souterraines-polygones/rapportage-2010"
download 597b452088ee383d3c10c6ae "eau/masses-eau/souterraines-polygones/rapportage-2016"
download 666327277683aed116fd1045 "eau/masses-eau/souterraines-polygones/etat-lieux-2019"
download 680197c493473505d4622e2a "eau/masses-eau/souterraines-polygones/rapportage-2022"

# Directive Cadre sur l'Eau — jeux OFB historiques
download 6a581ff277c58f2d2ec27727 "eau/dce/2010-sig-masses-eau-surface-wise"
download 6a5820e277c58f2d2ec27859 "eau/dce/2010-etats-objectifs-masses-eau"


echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
