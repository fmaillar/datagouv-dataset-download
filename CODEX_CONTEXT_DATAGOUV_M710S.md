# Codex Context — Archive data.gouv.fr sur m710s

## Objectif

Construire et maintenir sur le serveur Debian 13 `m710s` une archive locale structurée de jeux de données publics français, principalement issus de data.gouv.fr.

L’archive doit rester large mais organisée :

- conserver les jeux nationaux structurants ;
- conserver les séries historiques utiles ;
- conserver certains jeux régionaux ou territoriaux lorsqu’ils apportent une vraie valeur ;
- éviter les milliers de doublons municipaux ou couches locales peu utiles ;
- préserver les données brutes ;
- journaliser les téléchargements ;
- continuer les lots même si certaines ressources échouent.

---

## Machine et environnement

Hôte :

```text
m710s
```

Système :

```text
Debian 13 (Trixie)
```

Utilisateur :

```text
fgm
```

Stockage principal :

```text
/mnt/data
```

Stockage secondaire :

```text
/mnt/dd3to
```

CLI principale :

```text
/home/fgm/.local/bin/datagouv
```

Dépôt du toolkit :

```text
~/datagouv-toolkit
```

Commandes usuelles :

```bash
datagouv search "requête" --limit 1000
datagouv download <dataset_id> -o <destination>
```

Le moteur de recherche peut être très bruité. Les IDs de datasets doivent être triés et sélectionnés avant téléchargement.

Les échecs de téléchargement peuvent venir de :

- liens morts ;
- HTTP 403 / 404 ;
- ressources WMS / WFS ;
- serveurs QGIS ;
- pages externes ;
- types de ressources non directement téléchargeables.

Un échec `datagouv download` ne signifie donc pas automatiquement que le toolkit est en faute.

---

## Arborescence générale

```text
/mnt/data/datasets/
├── raw/
├── processed/
├── metadata/
├── checksums/
├── catalogs/
├── logs/
└── tmp/
```

Principes :

- `raw/` : données sources, à considérer comme immuables ;
- `processed/` : données transformées, nettoyées, normalisées, Parquet, etc. ;
- `metadata/` : métadonnées des datasets ;
- `checksums/` : informations d’intégrité ;
- `catalogs/` : inventaires et manifestes ;
- `logs/` : journaux d’exécution ;
- `tmp/` : données temporaires.

Domaines bruts :

```text
/mnt/data/datasets/raw/
├── administration
├── climat-environnement
├── education
├── energie
├── sante
├── socio-economie
├── territoire-geospatial
└── transport
```

---

## Modèle standard des scripts de téléchargement

Les scripts doivent suivre ce modèle :

```bash
#!/usr/bin/env bash

set -u

ROOT="/mnt/data/datasets/raw/<domaine>"
LOG="/mnt/data/datasets/logs/<nom>-download.log"

mkdir -p "$(dirname "$LOG")"

mkdir -p \
  "$ROOT/chemin1" \
  "$ROOT/chemin2"

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

# download <dataset_id> "<chemin/relatif>"

echo
echo "Fin : $(date --iso-8601=seconds)" | tee -a "$LOG"
```

Règles :

1. utiliser `set -u` ;
2. ne pas utiliser `set -e` ;
3. garder `mkdir -p "$ROOT/$dest"` dans `download()` ;
4. précréer aussi l’arborescence attendue en début de script ;
5. continuer après un échec individuel ;
6. journaliser dans `/mnt/data/datasets/logs/` ;
7. vérifier la syntaxe avec :

```bash
bash -n script.sh
```

8. éviter les doublons d’IDs entre lots ;
9. garder des noms de destination cohérents et explicites.

---

# Domaine 1 — Transport

Structure :

```text
transport/
├── baac
├── bornes-recharge
├── gtfs
├── infrastructures-ferroviaires
├── ponctualite
└── trafic-routier
```

## BAAC

Dataset national :

```text
53698f4ca3a729239d2036df
```

Nom :

```text
Bases de données annuelles des accidents corporels de la circulation routière - Années de 2005 à 2024
```

Destination :

```text
/mnt/data/datasets/raw/transport/baac
```

Ancien ID à ne pas utiliser :

```text
53a8bd3fa3a72905b7ce5961
```

## Ponctualité

```text
5dbd4a3a634f4140741cb9ad
```

Destination :

```text
transport/ponctualite
```

## IRVE

```text
685965d0ab901919e14a4a1b
```

Destination :

```text
transport/bornes-recharge
```

## Comptages routiers

```text
53699134a3a729239d203bd2
```

## Réseau ferré national

```text
6067e89b0aa12cfb479a7ce8  # opérateurs RFN
5f603c9607bc385c2b8f0771  # voies RFN
5b220199a3a7297ffee6cc23  # lignes RFN
```

Certains jeux Hauts-de-France utilisent des endpoints QGIS qui ont déjà renvoyé HTTP 403.

---

# Domaine 2 — Énergie

## Production

```text
603f0a0c413de52eda7ce5a3
5b90b8779ce2e75385bc02c2
5b90b88c9ce2e7539fbc02c2
5b90b87c06e3e7417c2ffd32
5ba1fd6006e3e775722ffd31
55f0463d88ee3849f5a46ec1
```

## Consommation

```text
65f118613e0e630d9f924b52
65f1185f3e0e630d9f924b51
65f1185fd7321d8e647ba548
65f1185fbb16ea436d7ba548
65e2979e41fa6389c8eb5b57
689c42addc3c56b809984b57
689c42aa186c86587b4443dd
689c42b9f918f4c8e71c9327
689c4297be0dc572c6294d1c
689c42a121932fa1640d99c1
```

## Industrie

```text
5a142ae9a3a7297774073454
```

## Registre production / stockage — millésimes

```text
5bfcc5a006e3e744e304ccf0  # 2026
69c4af4e5c9f9567df414fc6  # 2025
67d8f02e4d7033a78a52ce3d  # 2024
65f125f4f1d232d84e924b51  # 2023
64377e959b978c3f19538672  # 2022
62355567868a58b8316723e3  # 2021
6042fecac08756b00d7a57de  # 2020
5ed5ced55454365371179ef4  # 2019
5d43b88306e3e7328c40147c  # 2018
5bfa279006e3e703191a69b5  # 2017
```

---

# Domaine 3 — Climat / environnement

Script principal :

```text
download-climat-environnement.sh
```

État actuel :

```text
118 datasets uniques
```

Le script regroupe 4 lots logiques.

Thèmes couverts :

- qualité de l’air ;
- émissions GES ;
- CO2 ;
- déchets ;
- sols ;
- occupation des sols ;
- biodiversité ;
- climat ;
- sécheresse ;
- risques naturels ;
- eau / hydrologie.

Le script précrée explicitement les répertoires de destination en début de fichier.

Le volet eau/hydrologie inclut notamment :

- SISPEA ;
- ADES ;
- masses d’eau DCE ;
- rapportages 2010 / 2016 / 2019 / 2022 lorsqu’ils existent.

Ce domaine est considéré comme suffisamment rempli pour l’instant.

---

# Domaine 4 — Socio-économie / démographie

Log principal utilisé :

```text
~/socio-economie-demographie-search-v2.log
```

Le premier balayage avec des requêtes trop complexes (`INSEE France`, etc.) renvoyait souvent zéro résultat.

Les recherches simples ont donné de bien meilleurs résultats.

Scripts actuels :

```text
download-socio-economie-lot1.sh
download-socio-economie-lot2.sh
download-socio-economie-lot3.sh
download-socio-economie-lot4.sh
```

Comptage :

```text
Lot 1 : 50 datasets
Lot 2 : 24 datasets
Lot 3 : 28 datasets
Lot 4 : 19 datasets
Total : 121 datasets
```

Aucun doublon d’ID entre les 4 lots.

## Lot 1 — national structurant

Contient notamment :

- population ;
- recensement détaillé ;
- ménages ;
- revenus / pauvreté ;
- Filosofi ;
- emploi ;
- chômage ;
- salaires ;
- logement ;
- RPLS ;
- SIRENE ;
- créations d’entreprises ;
- mobilités domicile-travail ;
- état civil.

## Lot 2 — géographie fine

Contient notamment :

- IRIS ;
- contours IRIS ;
- carroyages 200 m ;
- Filosofi fin ;
- RPLS géolocalisé ;
- SIRENE géocodé ou régional.

## Lot 3 — historique / régional

Contient notamment :

- Bretagne ;
- Pays de la Loire ;
- PACA ;
- Grand Poitiers ;
- Dijon ;
- Lyon ;
- Somme ;
- Doubs ;
- séries historiques de mortalité.

## Lot 4 — équipements / accessibilité

Contient notamment :

- Base Permanente des Équipements ;
- BPE géolocalisée ;
- commerces ;
- services ;
- santé ;
- accessibilité de la population ;
- compléments de démographie d’entreprises.

---

# Domaine 5 — Territoire / géospatial

Log principal :

```text
~/territoire-geospatial-search.log
```

Taille :

```text
10618 lignes
```

Scripts :

```text
download-territoire-geospatial-lot1.sh
download-territoire-geospatial-lot2.sh
download-territoire-geospatial-lot3.sh
download-territoire-geospatial-lot4.sh
```

Comptage :

```text
Lot 1 : 18 datasets
Lot 2 : 14 datasets
Lot 3 : 12 datasets
Lot 4 : 20 datasets
Total : 64 datasets
```

Aucun doublon d’ID entre les 4 lots.

## Lot 1 — référentiels administratifs / BAN

Contient notamment :

- référentiel géographique français ;
- communes ;
- départements ;
- EPCI ;
- historique des communes ;
- Base Adresse Nationale ;
- état de la BAN par commune ;
- BANO.

ID BAN national :

```text
5530fbacc751df5ff937dddb
```

## Lot 2 — cadastre / parcelles / bâtiments

IDs structurants :

```text
66c2ff1a4ea0a9d2ba6a62a9  # Cadastre - PCI vecteur
61dc7157488f8cdb4283e3c3  # Base de données nationale des bâtiments
64f8681944e2fc006a93e65b  # IMOPE
```

Autres thèmes :

- parcelles ;
- filiation parcellaire ;
- adresses cadastrales ;
- bâtiments ;
- cadastre historique.

## Lot 3 — BD TOPO / relief / hydrographie

IDs structurants :

```text
61489083dc4223219e50cc35  # BD TOPO
69698191770f993ed4817ed2  # BD TOPO Historique
675871c36e60265b46ab3579  # France RELIEF beta
666326cd7683aed116fd0ff3  # BD Topage bassins 2019
6663267b7683aed116fd0f8d  # BD Topage bassins 2023
6a39cee98ea7947128467384  # BD Topage bassins 2026
61488c8c6c3e156d4c83f979  # Plan IGN
```

## Lot 4 — occupation du sol / OCS GE

IDs structurants :

```text
61489ec3e64c7f138f1b2e13  # OCS GE
693373c62a73b75078265d9d  # OCS GE Artificialisation
68348c9afa867945df5968e5  # Couverture OCS GE France
```

Le lot contient aussi des séries historiques et régionales, notamment Nantes et Région Sud.

---

# État global du data lake

Domaines déjà largement couverts :

```text
transport
energie
climat-environnement
socio-economie
territoire-geospatial
```

Domaines encore à couvrir en profondeur :

```text
sante
education
administration
```

Ordre recommandé :

```text
1. sante
2. education
3. administration
```

---

# Style de travail attendu de Codex

Pour ce projet :

1. privilégier les commandes shell exactes ;
2. ne pas sur-réduire la sélection ;
3. préférer les datasets nationaux structurants ;
4. conserver certaines séries historiques et régionales utiles ;
5. éviter les milliers de duplications municipales ;
6. ne pas conclure trop vite qu’un 403/404 vient du toolkit ;
7. préserver `raw/` ;
8. vérifier tous les scripts avec `bash -n` ;
9. vérifier les doublons d’IDs entre lots ;
10. conserver une arborescence cohérente ;
11. garder les `mkdir -p` explicites en début de script ;
12. utiliser `set -u` ;
13. ne pas utiliser `set -e` ;
14. continuer après les erreurs individuelles ;
15. journaliser sous `/mnt/data/datasets/logs/`.

---

# Commandes utiles

## Taille totale du data lake

```bash
du -sh /mnt/data/datasets
```

## Taille par domaine

```bash
du -sh /mnt/data/datasets/raw/*
```

## Scripts de téléchargement

```bash
ls -lh ~/download-*.sh
```

## Vérification de syntaxe

```bash
for f in ~/download-*.sh; do
    printf '%-60s ' "$f"
    bash -n "$f" && echo OK || echo FAIL
done
```

## Lancer plusieurs scripts en parallèle

```bash
for f in ~/download-*.sh; do
    bash "$f" &
done
wait
```

## Chercher les erreurs

```bash
grep -R "^ECHEC:" /mnt/data/datasets/logs
```

## Chercher les succès

```bash
grep -R "^OK:" /mnt/data/datasets/logs
```

---

# Prochaine étape recommandée

Continuer avec :

```text
sante
```

Méthode recommandée :

1. créer un log de recherche large dans `$HOME` ;
2. utiliser des requêtes simples ;
3. trier les IDs ;
4. privilégier les sources nationales ;
5. créer 3 à 4 lots ;
6. générer un script par lot ;
7. vérifier chaque script avec `bash -n` ;
8. vérifier l’absence de doublons inter-lots ;
9. télécharger dans :

```text
/mnt/data/datasets/raw/sante
```
