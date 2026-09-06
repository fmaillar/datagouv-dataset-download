# Archive data.gouv.fr — manuel de reproductibilité

Ce dépôt décrit une méthode reproductible pour rechercher, sélectionner, télécharger, vérifier et réparer une archive thématique de jeux de données publiés sur [data.gouv.fr](https://www.data.gouv.fr/). Il contient les manifestes de téléchargement et les outils d’audit, mais pas les données : celles-ci sont écrites sous `/mnt/data/datasets/`.

Le corpus actuel comprend **895 identifiants uniques**, répartis dans **70 scripts** et 16 domaines : administration, agriculture-alimentation, climat-environnement, culture-patrimoine, éducation, emploi-formation, énergie, entreprises-économie, finances publiques, justice-sécurité, santé, socio-économie, technologie-numérique, territoire-géospatial, tourisme et transport.

## Environnement de référence

La campagne décrite ici a été exécutée les 5 et 6 septembre 2026 sur :

- Debian 13 (`m710s`) ;
- Bash, Python 3 et ShellCheck ;
- un volume ext4 monté sur `/mnt/data` ;
- `datagouv-toolkit` 0.5.0, appelé explicitement par `/home/fgm/.local/bin/datagouv`.

Vérifier l’installation avant de commencer :

```bash
/home/fgm/.local/bin/datagouv --help
/home/fgm/.local/bin/datagouv download --help
df -h /mnt/data
```

Le CLI propose notamment `search`, `dataset`, `resources`, `metadata`, `stats`, `inspect`, `organization`, `download`, `workflow`, `inspect-csv` et `catalog-stats`.

## Organisation

```text
downloads/<domaine>/download-<domaine>-lotN.sh  manifestes de datasets
orchestration/download-all.sh    exécution séquentielle
orchestration/download-all-parallel.sh  exécution parallèle
tools/verify/verify-downloads.{sh,py}  contrôle d’intégrité
tools/repair/repair-downloads.{sh,py}  audit et réparation ciblée
tools/migrate/migrate-destinations.{sh,py}  migration après renommage
tools/licenses/audit-licenses.{sh,py}  audit avant redistribution
tools/torrents/                    préparation et création des torrents
tools/catalog/build-remote-catalog.{sh,py}  catalogue des services non archivables
tools/fouille-datagouv.sh         exemple de campagne de recherche
README.md                        politique et procédure reproductible
```

Les sorties sont séparées du dépôt :

```text
/mnt/data/datasets/
├── raw/          ressources reçues, non transformées
├── logs/         journaux, rapports et manifestes
└── quarantine/   fichiers écartés de façon récupérable
```

## 1. Fouille du catalogue

Utiliser exclusivement le CLI local. Une fouille commence par des requêtes simples et larges ; les requêtes trop composées ont produit peu ou pas de résultats.

```bash
/home/fgm/.local/bin/datagouv search "occupation du sol" --limit 1000
/home/fgm/.local/bin/datagouv search "santé" --limit 1000
/home/fgm/.local/bin/datagouv dataset <dataset_id>
/home/fgm/.local/bin/datagouv resources <dataset_id> --json
```

`tools/fouille-datagouv.sh` illustre une fouille géospatiale et redirige les résultats dans un journal. L’exécuter depuis la racine du dépôt :

```bash
bash tools/fouille-datagouv.sh
```

Conserver le journal brut de chaque campagne avec sa date, les requêtes exactes et la limite utilisée. Cela permet de distinguer la sélection humaine du résultat renvoyé par le moteur de recherche à un instant donné.

## 2. Critères de sélection

La sélection n’est pas un miroir exhaustif de data.gouv.fr. Elle suit les règles suivantes :

1. privilégier les référentiels nationaux, producteurs publics identifiables et séries structurantes ;
2. conserver les millésimes historiques utiles ;
3. ajouter des jeux régionaux ou locaux lorsqu’ils apportent une granularité absente au niveau national ;
4. préférer les ressources structurées et disponibles ;
5. éviter les milliers de déclinaisons municipales répétitives ;
6. ne pas confondre pertinence thématique et qualité technique ;
7. vérifier chaque ID avec `dataset` et `resources` avant ajout ;
8. interdire les doublons d’ID entre lots.

Chaque décision est matérialisée par une ligne explicite :

```bash
download 61dc7157488f8cdb4283e3c3 "cadastre/batiments/base-donnees-nationale"
```

Le premier argument est l’ID immuable du dataset ; le second est son classement local. Les lots complémentaires contiennent généralement au moins dix datasets afin de garder des unités de travail lisibles.

Contrôler les doublons :

```bash
rg --no-filename '^download ' downloads --glob 'download-*.sh' \
  | awk '{print $2}' | sort | uniq -d
```

Une sortie vide est attendue.

Lorsqu’une destination est renommée après une campagne, réutiliser les fichiers
attribués par le dernier rapport de vérification. La commande simule d’abord la
migration ; `--execute` crée des liens physiques et ne remplace aucun fichier :

```bash
./tools/migrate/migrate-destinations.sh
./tools/migrate/migrate-destinations.sh --execute
```

Conserver les anciens répertoires jusqu’à ce que la vérification des nouvelles
destinations soit terminée. Les déplacer ensuite dans `quarantine/` plutôt que
les supprimer.

## 3. Convention des manifestes

Chaque script définit une racine thématique et un journal. Il utilise `set -u`, mais pas `set -e`, afin qu’un dataset en échec n’empêche pas les suivants d’être tentés. Les répertoires sont créés explicitement et chaque appel est journalisé.

```bash
ROOT="/mnt/data/datasets/raw/energie"
LOG="/mnt/data/datasets/logs/energie-lot1-download.log"

download <dataset_id> "destination/relative"
```

Valider le dépôt sans télécharger :

```bash
find downloads orchestration tools -type f -name '*.sh' -print0 | \
  xargs -0 -n1 bash -n
find downloads orchestration tools -type f -name '*.sh' -print0 | \
  xargs -0 shellcheck
find tools -type f -name '*.py' -print0 | \
  xargs -0 -n1 python3 -m py_compile
```

## 4. Téléchargement initial et reprise

Le mode recommandé lance plusieurs scripts, pas plusieurs ressources d’un même dataset :

```bash
./orchestration/download-all-parallel.sh 6
tail -f /mnt/data/datasets/logs/download-all-parallel.log
```

Le nombre de workers accepté est compris entre 1 et 16. Sur la machine de référence, 6 à 8 workers offraient un compromis raisonnable. Mesurer plutôt que supposer :

```bash
iostat -dxm 1 sdb
sar -n DEV 1
watch -n 30 'du -sh /mnt/data/datasets/raw'
```

Sans `--overwrite`, `datagouv download` saute un fichier final portant déjà le même nom. Un téléchargement est d’abord écrit dans `<nom>.part`, puis renommé atomiquement. Une erreur gérée supprime le `.part`; une interruption brutale peut en laisser un.

Cette reprise a une limite essentielle : **l’existence du nom suffit**. Le CLI ne contrôle ni taille ni checksum avant `SKIP`. Par ailleurs, un script marqué `OK` signifie seulement qu’il est arrivé à sa fin ; rechercher aussi les échecs internes :

```bash
rg '^ECHEC:' /mnt/data/datasets/logs/*-download.log
```

## 5. Vérification d’intégrité

Attendre la fin de tous les téléchargements. Commencer par l’inventaire rapide :

```bash
./tools/verify/verify-downloads.sh --quick
```

Limiter un contrôle à un ou plusieurs datasets avec une option répétable. Les
résultats ciblés sont écrits dans des fichiers suffixés `-targeted` afin de ne
pas remplacer le dernier rapport global :

```bash
./tools/verify/verify-downloads.sh --quick \
  --dataset 6707515c84dfa4012c3ecd45 \
  --dataset 5889d042a3a72974c1f0d607
```

Il reconstruit les couples ID/destination depuis les scripts, interroge `datagouv resources --json`, puis compare existence et taille. Il produit :

```text
/mnt/data/datasets/logs/verification-downloads.tsv
/mnt/data/datasets/logs/checksums-manifest.tsv
```

Lancer ensuite la passe complète :

```bash
time ./tools/verify/verify-downloads.sh
```

Elle compare les checksums distants disponibles et calcule un SHA-256 local. Sur environ 772 Go, la première passe complète a duré 126 minutes. Les statuts sont :

- `OK_CHECKSUM` : checksum publié et concordant ;
- `OK_TAILLE` : taille concordante, sans validation cryptographique ;
- `PRESENT_SANS_REFERENCE` : fichier présent, mais aucune référence distante exploitable ;
- `ABSENT` : aucun fichier correspondant ;
- `TAILLE_INCORRECTE` : taille locale différente des métadonnées ;
- `CHECKSUM_INCORRECT` : checksum local différent du checksum publié ;
- `API_ERROR` : dataset ou liste de ressources inaccessible.

Une divergence ne prouve pas immédiatement une corruption. Lors de cette campagne, un fichier local et une nouvelle lecture de son URL avaient le même SHA-1, tandis que le SHA-1 stocké dans les métadonnées data.gouv était ancien. De même, plusieurs ressources peuvent partager exactement le même titre : le CLI les dirige alors vers le même chemin. Le vérificateur reconnaît les noms anti-collision `<nom>--<resource_id>.<ext>` créés pendant la réparation.

Les rapports sont réécrits à chaque passe. Pour une piste d’audit, les copier avant toute nouvelle exécution :

```bash
cp --preserve=timestamps \
  /mnt/data/datasets/logs/verification-downloads.tsv \
  /mnt/data/datasets/logs/verification-downloads-$(date +%Y%m%dT%H%M%S).tsv
```

## 6. Audit et réparation ciblée

Ne jamais supprimer l’archive entière après un rapport négatif. Le réparateur travaille ressource par ressource afin qu’une URL morte ne bloque plus les ressources suivantes du même dataset.

Audit sans écriture :

```bash
./tools/repair/repair-downloads.sh
```

Réparation des seules ressources absentes dont data.gouv publie une taille :

```bash
./tools/repair/repair-downloads.sh --execute
```

Pour réparer seulement le résultat d’un contrôle ciblé sans toucher au rapport
global :

```bash
./tools/repair/repair-downloads.sh \
  --report /mnt/data/datasets/logs/verification-downloads-targeted.tsv \
  --execute
```

Garanties de ce mode :

- aucun fichier final existant n’est écrasé ;
- écriture dans `.repair.part`, synchronisation, puis renommage atomique ;
- SHA-256 calculé pendant le transfert ;
- poursuite après une erreur individuelle ;
- ajout du `resource_id` au nom en cas de collision ;
- les ressources sans taille restent exclues.

Les différences de taille et checksum sont d’abord sondées par requête HTTP `HEAD`. `URL_TAILLE_LOCALE_OK` indique que le fichier local correspond à la taille actuellement servie, même si les anciennes métadonnées divergent. Le réparateur n’efface pas ces fichiers.

## 7. Ressources sans taille et services

Classifier les absences sans taille sans télécharger leur contenu :

```bash
./tools/repair/repair-downloads.sh --probe-unknown --api-workers 16
```

La sonde utilise les en-têtes HTTP et les formats déclarés pour séparer :

- `PROBE_FICHIER_BORNE` : fichier ordinaire avec taille HTTP ;
- `PROBE_SERVICE` : API, WMS, WFS, WMTS ou service OGC ;
- `PROBE_PAGE_HTML` : page web, pas une ressource brute ;
- `PROBE_SANS_TAILLE` : flux encore non borné ;
- `PROBE_URL_NON_HTTP` : par exemple FTP ;
- `PROBE_ERROR` : 404, timeout, DNS, 403, 429, 5xx, etc.

Télécharger uniquement la liste blanche `PROBE_FICHIER_BORNE` :

```bash
./tools/repair/repair-downloads.sh --execute --execute-probed --download-workers 6
```

Ne pas employer `--include-unknown-size` sans revue manuelle : une URL peut être une API ou un flux sans borne.

Enfin, cataloguer ce qui doit rester distant :

```bash
./tools/catalog/build-remote-catalog.sh
```

Les fichiers `remote-resources-catalog.tsv` et `.jsonl` enregistrent le dataset, la ressource, le titre, l’URL, le format, le MIME, le chemin prévu et le résultat de la sonde. Ils rendent les exclusions explicites plutôt que silencieuses.

## 8. Détecter les doublons binaires

Construire l’inventaire SHA-256 et les groupes de fichiers strictement identiques :

```bash
./tools/duplicates/find-duplicates.sh --workers 1
```

Un seul worker est recommandé sur un disque rotatif. Lors du premier passage, l’outil réutilise les empreintes du rapport cryptographique et des réparations, puis ne lit que les fichiers encore inconnus. Les passages suivants valident le triplet chemin, taille et date de modification du cache ; un fichier nouveau ou modifié est automatiquement recalculé.

Sorties :

```text
/mnt/data/datasets/checksums/file-hash-cache.tsv
/mnt/data/datasets/catalogs/exact-duplicate-groups.tsv
/mnt/data/datasets/catalogs/exact-duplicate-files.tsv
/mnt/data/datasets/catalogs/duplicate-summary.json
```

`exact-duplicate-groups.tsv` fournit le SHA-256, le nombre de fichiers et d’inodes, la portée `within-dataset` ou `cross-dataset`, le chemin canonique proposé et l’espace physiquement récupérable. `exact-duplicate-files.tsv` détaille chaque membre. Deux chemins pointant déjà vers le même inode ne sont pas comptés deux fois dans le gain potentiel.

Forcer exceptionnellement une relecture complète :

```bash
./tools/duplicates/find-duplicates.sh --rehash --workers 1
```

Cette commande relit toute l’archive et peut durer plusieurs heures. Elle n’est normalement pas nécessaire. Le scanner ne modifie jamais `raw/` ; `mutation_performed` reste à `false` dans le résumé. Ne pas supprimer automatiquement les variantes CSV, JSON, Parquet, GPKG ou SQL : elles peuvent représenter les mêmes objets sans être des doublons binaires.

La campagne finale a trouvé 326 groupes, 981 entrées et 73 groupes traversant plusieurs datasets. Le gain maximal estimé était de 7,36 Gio sur 773 Gio logiques, insuffisant pour justifier une déduplication physique.

## 9. Auditer les licences avant redistribution

Avant de publier une copie, inventorier la licence, le producteur, la page source
et la date de mise à jour de chaque dataset :

```bash
./tools/licenses/audit-licenses.sh --workers 12
```

Les sorties `license-audit.tsv`, `license-audit.jsonl` et
`license-audit-summary.json` sont écrites dans `catalogs/`. Le classement
automatique sépare attribution, domaine public, partage à l’identique, licence
inconnue et accès non ouvert. Le signal de données personnelles est une
heuristique imposant une revue humaine ; il ne constitue pas une conclusion
juridique. Aucun torrent ne doit être publié uniquement sur la foi de cet audit.

Générer ensuite le registre de revue formelle :

```bash
./tools/licenses/review-publication.sh
```

Le rapport `catalogs/publication-review.tsv` classe chaque dataset sans prendre
de décision juridique à la place du réviseur. Les décisions humaines sont
versionnées dans `reviews/publication-decisions.tsv` avec les valeurs `APPROVE`,
`EXCLUDE` ou `HOLD`. Chaque ligne doit préciser le réviseur, un horodatage ISO et
un motif. Relancer l'outil après chaque modification ; une licence ou un accès
automatiquement bloqué ne peut pas être forcé par une décision manuelle.
Les analyses préparatoires peuvent être conservées sous
`reviews/recommendations/batch-NNN.tsv`. Une recommandation technique ne devient
une décision qu'après validation explicite et ajout dans
`reviews/publication-decisions.tsv`.

Pour prioriser une revue volumineuse, inspecter en lecture seule les noms,
en-têtes et premiers 256 Kio des fichiers et des petits membres d'archives :

```bash
./tools/licenses/scan-publication.sh
```

Les rapports `catalogs/publication-technical-scan.{tsv,jsonl}` et leur résumé
proposent `APPROVE`, `HOLD` ou
`EXCLUDE`. L'absence de signal ne prouve pas l'absence de données personnelles :
ce résultat sert à constituer les lots et doit rester accompagné d'une
recommandation motivée.

Après validation explicite d'un mandat de revue, matérialiser les recommandations
restantes en lots bornés et en décisions versionnées :

```bash
./tools/licenses/finalize-technical-review.sh \
    --reviewer "Florian MAILLARD" --execute
./tools/licenses/review-publication.sh
```

La préparation d'une release consulte ce dernier registre et ne retient que les
datasets dont le statut final est `APPROVED`. Les entrées `HOLD`, `EXCLUDE` et
les blocages automatiques ne peuvent donc pas entrer dans un nouveau torrent.

Préparer ensuite une release conservatrice par liens physiques, sans recopier
les données, puis générer un torrent sans tracker par domaine :

```bash
./tools/torrents/prepare-release.sh datagouv-2026-09-06 --execute
./tools/torrents/create-torrents.sh datagouv-2026-09-06
```

La release exclut les licences à revoir, les accès non ouverts, les fiches sans
producteur attribuable et tout dataset signalé par l'heuristique de données
personnelles. Chaque domaine contient un
répertoire `_METADATA/` avec son attribution filtrée et une notice ; ces preuves
font donc partie du contenu signé par le torrent. Les torrents restent marqués
comme non approuvés et ne doivent pas être publiés avant revue humaine. Une
ancienne release dépourvue de `_METADATA/` doit être recréée sous un nouvel
identifiant, jamais modifiée sur place. La création est reprenable : un torrent
existant et lisible par `transmission-show` est conservé, tandis qu'un fichier
`.torrent.part` incomplet est recalculé.

## 10. Figer une campagne auditable

Après la dernière vérification rapide, créer un snapshot en donnant un identifiant qui ne sera jamais réutilisé :

```bash
./tools/snapshot/snapshot-run.sh 2026-09-05_2026-09-06
```

Le script refuse d’écraser un dossier existant et crée sous `/mnt/data/datasets/catalogs/runs/<run_id>/` :

- `run-metadata.json` : dates, hôte, système, versions, commits, stockage et compteurs ;
- `dataset-inventory.tsv` : scripts, destinations et statuts agrégés pour chaque ID ;
- `unresolved-resources.tsv` : anomalies encore ouvertes ;
- `repository/` : copie exacte des fichiers de méthode présents dans le dépôt ;
- `evidence/logs/` : journaux et rapports de la campagne ;
- `evidence/duplicates/` : résumé et inventaires détaillés des doublons exacts ;
- `evidence/licenses/` : audit des licences et signaux de revue humaine ;
- `evidence/publication/` : registre de revue et décisions humaines versionnées ;
- `SHA256SUMS` : empreintes de toutes les preuves du snapshot ;
- `SNAPSHOT_COMPLETE` : marqueur écrit uniquement à la fin.

Les données brutes ne sont pas recopiées. Le snapshot enregistre leur volume et leur nombre de fichiers ; les empreintes disponibles restent dans les rapports de vérification. Contrôler l’intégrité du paquet :

```bash
cd /mnt/data/datasets/catalogs/runs/2026-09-05_2026-09-06
sha256sum -c SHA256SUMS
```

Un dépôt Git marqué `dirty` n’invalide pas le snapshot : cet état est déclaré dans `run-metadata.json` et la copie exacte du working tree est conservée sous `repository/`. Pour une publication formelle, préférer néanmoins un commit propre avant la capture finale.

## 11. Résultats de la campagne de référence

La première vérification complète du 6 septembre 2026 a produit :

```text
ABSENT                  1005
API_ERROR                 15
CHECKSUM_INCORRECT         75
OK_CHECKSUM              5355
OK_TAILLE                 282
PRESENT_SANS_REFERENCE   3085
TAILLE_INCORRECTE         229
```

L’analyse a identifié 338 chemins en collision. La réparation s’est déroulée en trois passes contrôlées :

1. 118 ressources de taille publiée récupérées, soit 33,7 Gio ;
2. 193 fichiers bornés récupérés après une première sonde, soit 3,04 Gio ;
3. 117 fichiers supplémentaires récupérés après correction de la distinction entre fichier distant et service, soit 2,03 Gio.

Au total, environ **428 ressources** ont été réparées. L’archive atteignait **772 Go**. Les ressources restantes étaient des services, pages, flux non bornés ou URL défaillantes et ont été cataloguées. Un ancien `.part` de 33 Mio a été déplacé, sans suppression, vers :

```text
/mnt/data/datasets/quarantine/2026-09-06-stale-parts/
```

Ces nombres sont un instantané, pas une propriété permanente du catalogue : les producteurs peuvent ajouter, remplacer ou retirer des ressources.

## 12. Limites et règles d’interprétation

- Les métadonnées `filesize` et `checksum` peuvent être absentes ou périmées.
- Une URL externe peut changer de contenu sans changement d’ID.
- Deux ressources de même titre provoquent une collision avec le téléchargeur générique.
- Les variantes CSV, JSON, GPKG ou dump SQL d’un dataset ne sont pas des doublons binaires, même si elles décrivent les mêmes objets.
- Un HTTP 403/404 n’implique pas un défaut du CLI.
- Les API et services cartographiques exigent un collecteur spécialisé et une politique de périmètre ; ils ne doivent pas être aspirés comme des fichiers.
- Le SHA-256 local assure la stabilité future de l’archive, mais ne prouve l’identité avec la source que lorsqu’une empreinte distante fiable existe.
- `raw/` doit rester immuable ; toute normalisation appartient à un futur répertoire `processed/`.

## 13. Checklist d’une nouvelle campagne

```text
[ ] Archiver les anciens rapports avec un horodatage
[ ] Enregistrer les requêtes de recherche brutes
[ ] Vérifier producteur, couverture, millésime et ressources
[ ] Ajouter ID et destination dans un lot thématique
[ ] Contrôler les doublons d’ID
[ ] Exécuter bash -n, ShellCheck et py_compile
[ ] Lancer orchestration/download-all-parallel.sh avec une concurrence mesurée
[ ] Rechercher les ECHEC internes, même si les scripts sont OK
[ ] Lancer tools/verify/verify-downloads.sh --quick
[ ] Lancer tools/verify/verify-downloads.sh et conserver le rapport complet
[ ] Auditer puis réparer uniquement les absences bornées
[ ] Sonder et cataloguer les services/URL non archivés
[ ] Exécuter tools/duplicates/find-duplicates.sh et examiner les groupes inter-datasets
[ ] Exécuter tools/licenses/audit-licenses.sh et revoir les licences et données personnelles
[ ] Créer le snapshot de campagne et valider SHA256SUMS
[ ] Mettre en quarantaine plutôt que supprimer
[ ] Consigner date, version du CLI, volumes et résultats finaux
```

Cette procédure favorise la traçabilité : la sélection est visible dans Git, les données restent hors dépôt, chaque anomalie reçoit un statut, et toute action destructive est remplacée par une réparation ciblée ou une quarantaine récupérable.
