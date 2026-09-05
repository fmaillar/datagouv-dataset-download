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
download-<domaine>-lotN.sh       manifestes de datasets
download-all.sh                  exécution séquentielle
download-all-parallel.sh         exécution parallèle
verify-downloads.{sh,py}         contrôle d’intégrité
repair-downloads.{sh,py}         audit et réparation ciblée
build-remote-catalog.{sh,py}     catalogue des services non archivables
fouille-datagouv.sh              exemple de campagne de recherche
CODEX_CONTEXT_DATAGOUV_M710S.md  décisions et IDs structurants initiaux
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

`fouille-datagouv.sh` illustre une fouille géospatiale et redirige les résultats dans un journal. C’est un fragment Bash sans shebang ; l’exécuter ainsi :

```bash
bash fouille-datagouv.sh
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
rg --no-filename '^download ' download-*.sh \
  | awk '{print $2}' | sort | uniq -d
```

Une sortie vide est attendue.

## 3. Convention des manifestes

Chaque script définit une racine thématique et un journal. Il utilise `set -u`, mais pas `set -e`, afin qu’un dataset en échec n’empêche pas les suivants d’être tentés. Les répertoires sont créés explicitement et chaque appel est journalisé.

```bash
ROOT="/mnt/data/datasets/raw/energie"
LOG="/mnt/data/datasets/logs/energie-lot1-download.log"

download <dataset_id> "destination/relative"
```

Valider le dépôt sans télécharger :

```bash
bash -n download-*.sh verify-downloads.sh repair-downloads.sh \
  build-remote-catalog.sh
shellcheck download-*.sh verify-downloads.sh repair-downloads.sh \
  build-remote-catalog.sh
python3 -m py_compile verify-downloads.py repair-downloads.py \
  build-remote-catalog.py
```

## 4. Téléchargement initial et reprise

Le mode recommandé lance plusieurs scripts, pas plusieurs ressources d’un même dataset :

```bash
./download-all-parallel.sh 6
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
./verify-downloads.sh --quick
```

Il reconstruit les couples ID/destination depuis les scripts, interroge `datagouv resources --json`, puis compare existence et taille. Il produit :

```text
/mnt/data/datasets/logs/verification-downloads.tsv
/mnt/data/datasets/logs/checksums-manifest.tsv
```

Lancer ensuite la passe complète :

```bash
time ./verify-downloads.sh
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
./repair-downloads.sh
```

Réparation des seules ressources absentes dont data.gouv publie une taille :

```bash
./repair-downloads.sh --execute
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
./repair-downloads.sh --probe-unknown --api-workers 16
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
./repair-downloads.sh --execute --execute-probed --download-workers 6
```

Ne pas employer `--include-unknown-size` sans revue manuelle : une URL peut être une API ou un flux sans borne.

Enfin, cataloguer ce qui doit rester distant :

```bash
./build-remote-catalog.sh
```

Les fichiers `remote-resources-catalog.tsv` et `.jsonl` enregistrent le dataset, la ressource, le titre, l’URL, le format, le MIME, le chemin prévu et le résultat de la sonde. Ils rendent les exclusions explicites plutôt que silencieuses.

## 8. Résultats de la campagne de référence

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

## 9. Limites et règles d’interprétation

- Les métadonnées `filesize` et `checksum` peuvent être absentes ou périmées.
- Une URL externe peut changer de contenu sans changement d’ID.
- Deux ressources de même titre provoquent une collision avec le téléchargeur générique.
- Les variantes CSV, JSON, GPKG ou dump SQL d’un dataset ne sont pas des doublons binaires, même si elles décrivent les mêmes objets.
- Un HTTP 403/404 n’implique pas un défaut du CLI.
- Les API et services cartographiques exigent un collecteur spécialisé et une politique de périmètre ; ils ne doivent pas être aspirés comme des fichiers.
- Le SHA-256 local assure la stabilité future de l’archive, mais ne prouve l’identité avec la source que lorsqu’une empreinte distante fiable existe.
- `raw/` doit rester immuable ; toute normalisation appartient à un futur répertoire `processed/`.

## 10. Checklist d’une nouvelle campagne

```text
[ ] Archiver les anciens rapports avec un horodatage
[ ] Enregistrer les requêtes de recherche brutes
[ ] Vérifier producteur, couverture, millésime et ressources
[ ] Ajouter ID et destination dans un lot thématique
[ ] Contrôler les doublons d’ID
[ ] Exécuter bash -n, ShellCheck et py_compile
[ ] Lancer download-all-parallel.sh avec une concurrence mesurée
[ ] Rechercher les ECHEC internes, même si les scripts sont OK
[ ] Lancer verify-downloads.sh --quick
[ ] Lancer verify-downloads.sh et conserver le rapport complet
[ ] Auditer puis réparer uniquement les absences bornées
[ ] Sonder et cataloguer les services/URL non archivés
[ ] Mettre en quarantaine plutôt que supprimer
[ ] Consigner date, version du CLI, volumes et résultats finaux
```

Cette procédure favorise la traçabilité : la sélection est visible dans Git, les données restent hors dépôt, chaque anomalie reçoit un statut, et toute action destructive est remplacée par une réparation ciblée ou une quarantaine récupérable.
