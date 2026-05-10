Dossier d'exploitation

## Sommaire
1. Guide d'installation
1.1 Prérequis système
1.2 Installation de l'application front-end (Olympic Participation Tracker)
1.3 Installation de l'application back-end (Workshop Organizer API)
1.4 Vérification de l'installation
1.5 Troubleshooting
2. Plan de sauvegarde des données
2.1 Données à sauvegarder
2.2 Stratégie de sauvegarde
2.3 Procédure de backup
2.4 Procédure de restauration
2.5 Tests de restauration
3. Surveillance (monitoring)
3.1 Métriques à surveiller
3.2 Seuils d'alerte
3.3 Healthchecks
3.4 Gestion des logs
3.5 Alertes et escalation
4. Recommandations
Notes et références
Glossaire

## 1. Guide d'installation
Ce guide couvre l'installation opérationnelle des applications Angular et Spring Boot/PostgreSQL via Docker Compose.

### 1.1 Prérequis système
Systèmes compatibles :
- Linux (Ubuntu 22.04+ recommandé)
- macOS 13+
- Windows 11 + WSL2

Ressources minimales recommandées :
- CPU : 2 vCPU (4 recommandés)
- RAM : 4 Go (8 Go recommandés)
- Disque libre : 10 Go

Versions/outils :
- Git >= 2.30
- Docker Engine >= 24
- Docker Compose v2 (commande `docker compose`) ; validé sur ce projet avec `Docker Compose version v5.0.2`
- curl >= 7.68

Ports à libérer :
- `80` (frontend nginx)
- `8080` (API Java)
- `5432` (PostgreSQL si exposé localement)

Vérification prérequis :
```bash
git --version
docker --version
docker compose version
curl --version
```

### 1.2 Installation de l'application front-end (Olympic Participation Tracker)
Deux modes sont possibles.

#### Mode A - Stack complète (recommandé exploitation)
Depuis la racine du dépôt :
```bash
cd /home/laurent/projet8
docker compose config
docker compose pull
docker compose up -d
```

Vérifications :
```bash
docker compose ps
curl -I http://localhost
```
Résultat attendu : HTTP `200` ou `304`.

#### Mode B - Frontend seul
```bash
cd /home/laurent/projet8
docker compose -f docker-compose.angular.yml config
docker compose -f docker-compose.angular.yml pull
docker compose -f docker-compose.angular.yml up -d
```

Vérification :
```bash
docker compose -f docker-compose.angular.yml ps
curl -I http://localhost
```

### 1.3 Installation de l'application back-end (Workshop Organizer API)
#### Mode A - Stack complète (API + DB + Web)
```bash
cd /home/laurent/projet8
docker compose config
docker compose up -d db api
```

Attendre la base saine :
```bash
docker compose ps
docker compose exec db pg_isready -U workshops_user -d workshopsdb
```

Vérifier l'API :
```bash
curl -sS http://localhost:8080/api/workshops
curl -sS http://localhost:8080/api/notions
```

#### Mode B - Backend local par dossier (build local)
```bash
cd /home/laurent/projet8/java/G-rez-l-int-gration-et-la-livraison-continue-Application-Java
docker compose config
docker compose up --build -d
```

Vérifications :
```bash
docker compose ps
docker compose exec db pg_isready -U workshops_user -d workshopsdb
curl -sS http://localhost:8080/api/workshops
```

### 1.4 Vérification de l'installation
Vérifications minimales :
```bash
cd /home/laurent/projet8
docker compose ps
docker compose logs --tail=100 api
docker compose logs --tail=100 web
docker compose logs --tail=100 db
```

Test de connectivité DB + persistance :
```bash
docker compose exec db psql -U workshops_user -d workshopsdb -c "SELECT NOW();"
docker compose exec db psql -U workshops_user -d workshopsdb -c "\dt"
```

Test API fonctionnel :
```bash
curl -sS http://localhost:8080/api/notions
curl -sS http://localhost:8080/api/workshops
```

Test Front :
```bash
curl -I http://localhost
```

### 1.5 Troubleshooting
**Erreur : `bind: address already in use` (ports 80/8080/5432)**  
Diagnostic :
```bash
ss -lntp | rg ":80 |:8080 |:5432 "
```
Correction : arrêter le service qui occupe le port ou adapter les mappings de ports dans le compose.

**Erreur Docker permissions (`permission denied while trying to connect to the Docker daemon socket`)**  
Correction :
```bash
sudo usermod -aG docker $USER
newgrp docker
```

**DB unhealthy / API ne démarre pas**  
Diagnostic :
```bash
docker compose logs db --tail=200
docker compose exec db pg_isready -U workshops_user -d workshopsdb
```
Correction : vérifier identifiants DB et variables `SPRING_DATASOURCE_*`.

**Erreur image introuvable (`manifest unknown`)**  
Correction :
- vérifier le tag (`java-latest`, `angular-latest`) ;
- tirer explicitement l'image ;
- ou utiliser les compose locaux avec `--build`.

**Timeout de démarrage API**  
Diagnostic :
```bash
docker compose logs api --tail=300
```
Correction : attendre le `healthcheck` DB, augmenter ressources CPU/RAM, redémarrer service :
```bash
docker compose restart api
```

## 2. Plan de sauvegarde des données

### 2.1 Données à sauvegarder
1. Base PostgreSQL `workshopsdb` (schéma + données métiers).
2. Volume Docker PostgreSQL (si volume nommé utilisé en prod).
3. Fichiers de configuration :
   - `docker-compose.yml`
   - `docker-compose.java.yml`
   - `docker-compose.angular.yml`
   - `java/.../docker-compose.yml`
   - fichiers `.env` et secrets hors Git.
4. Logs d'exploitation (API/DB/proxy) si conservation centralisée activée.

### 2.2 Stratégie de sauvegarde
| Type de donnée | Type de backup | Fréquence | Rétention | Stockage |
|---|---|---|---|---|
| PostgreSQL `workshopsdb` | Full logique (`pg_dump -Fc`) | Quotidien (02:00) | 30 jours | `backup/YYYY-MM-DD/HHMMSS/db` + stockage distant hebdo |
| PostgreSQL (snapshot volume) | Snapshot volume | Hebdomadaire | 4 semaines | stockage bloc/snapshot |
| Config compose + scripts | Archive `tar.gz` | À chaque changement + hebdo | 90 jours | `backup/YYYY-MM-DD/HHMMSS/config` + Git privé |
| Logs critiques exportés | Archive compressée | Quotidien | 14 jours | `backup/YYYY-MM-DD/HHMMSS/logs` |

### 2.3 Procédure de backup
Exemple backup DB (stack racine) avec dossier date/heure :
```bash
cd /home/laurent/projet8
BACKUP_ROOT=/home/laurent/projet8/backup
BACKUP_DAY=$(date +%F)
TS=$(date +%F_%H%M%S)
BACKUP_RUN=$(date +%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$BACKUP_DAY/$BACKUP_RUN/db"
mkdir -p "$BACKUP_DIR"
docker compose exec -T db pg_dump -U workshops_user -d workshopsdb -Fc > "$BACKUP_DIR/workshopsdb_$TS.dump"
sha256sum "$BACKUP_DIR/workshopsdb_$TS.dump" > "$BACKUP_DIR/workshopsdb_$TS.dump.sha256"
ls -lh "$BACKUP_DIR/workshopsdb_$TS.dump" "$BACKUP_DIR/workshopsdb_$TS.dump.sha256"
```

Backup config (meme run date/heure) :
```bash
BACKUP_ROOT=/home/laurent/projet8/backup
BACKUP_DAY=$(date +%F)
BACKUP_RUN=$(date +%H%M%S)
BACKUP_CFG="$BACKUP_ROOT/$BACKUP_DAY/$BACKUP_RUN/config"
TS=$(date +%F_%H%M%S)
mkdir -p "$BACKUP_CFG"
tar -czf "$BACKUP_CFG/p8_config_$TS.tar.gz" \
  /home/laurent/projet8/docker-compose.yml \
  /home/laurent/projet8/docker-compose.java.yml \
  /home/laurent/projet8/docker-compose.angular.yml \
  /home/laurent/projet8/java/G-rez-l-int-gration-et-la-livraison-continue-Application-Java/docker-compose.yml
ls -lh "$BACKUP_CFG/p8_config_$TS.tar.gz"
```

Automatisation cron (exemple) :
```cron
0 2 * * * /usr/local/bin/p8_backup_db.sh >> /home/laurent/projet8/backup/backup.log 2>&1
30 2 * * 0 /usr/local/bin/p8_backup_config.sh >> /home/laurent/projet8/backup/backup.log 2>&1
```

### 2.4 Procédure de restauration
Exemple restauration DB :
```bash
cd /home/laurent/projet8
RESTORE_FILE=/home/laurent/projet8/backup/YYYY-MM-DD/HHMMSS/db/workshopsdb_YYYY-MM-DD_HHMMSS.dump
docker compose stop api
docker compose exec -T db dropdb --if-exists -U workshops_user workshopsdb
docker compose exec -T db createdb -U workshops_user workshopsdb
cat "$RESTORE_FILE" | docker compose exec -T db pg_restore -U workshops_user -d workshopsdb --clean --if-exists
docker compose start api
# attendre 5 a 10 secondes que l'API termine son redemarrage
```

Vérification post-restauration :
```bash
docker compose exec db psql -U workshops_user -d workshopsdb -c "SELECT NOW();"
docker compose exec db psql -U workshops_user -d workshopsdb -c "\dt"
curl -sS http://localhost:8080/api/workshops
curl -sS http://localhost:8080/api/notions
```

### 2.5 Tests de restauration
Fréquence recommandée : mensuelle.

Procédure :
1. Restaurer la dernière sauvegarde dans un environnement de test isolé.
2. Prendre un run daté (exemple : `backup/2026-05-10/021500/`) et tracer l'identifiant de run dans le compte-rendu.
3. Vérifier intégrité SQL (`\dt`, comptages de tables critiques).
4. Vérifier disponibilité API et scénarios de base.
5. Documenter résultat dans un journal (date, dump utilisé, durée, succès/échec, actions).

Critères de succès :
- restauration terminée sans erreur ;
- API fonctionnelle ;
- données cohérentes (tables présentes, lignes non nulles sur entités principales).

## 3. Surveillance (monitoring)

### 3.1 Métriques à surveiller
- Hôte/containers : CPU, mémoire, disque, redémarrages.
- PostgreSQL : disponibilité, connexions actives, latence requêtes.
- API : temps de réponse `/api/workshops`, `/api/notions`, taux d'erreur HTTP.
- Frontend : disponibilité HTTP et latence de réponse.

### 3.2 Seuils d'alerte
| Métrique | Warning | Critical | Action recommandée |
|---|---:|---:|---|
| CPU hôte/container | > 70% sur 5 min | > 90% sur 5 min | analyser charge, scaler ou optimiser |
| Mémoire hôte/container | > 75% | > 90% | vérifier fuite mémoire, augmenter limites |
| Disque libre | < 20% | < 10% | purge logs/backups, extension stockage |
| API p95 latence | > 300 ms | > 800 ms | analyser DB et appels lents |
| Taux erreurs API 5xx | > 1% | > 5% | incident applicatif immédiat |
| Disponibilité PostgreSQL | 1 échec healthcheck | > 3 échecs successifs | bascule incident DB |
| Disponibilité frontend (HTTP) | > 1 min indispo | > 5 min indispo | intervention astreinte |

### 3.3 Healthchecks
Healthchecks existants :
- PostgreSQL via `pg_isready` (dans compose).

Commandes d'exploitation :
```bash
cd /home/laurent/projet8
docker compose ps
docker compose exec db pg_isready -U workshops_user -d workshopsdb
docker stats --no-stream
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/api/workshops
curl -s -o /dev/null -w "%{http_code}\n" http://localhost
```

Recommandation backend :
- ajouter `/actuator/health` (Spring Boot Actuator) pour un healthcheck API explicite.

### 3.4 Gestion des logs
Emplacements et consultation :
- Logs conteneurs :
```bash
docker compose logs -f api
docker compose logs -f db
docker compose logs -f web
```
- Journal docker host : `journalctl -u docker` (Linux).

Rotation recommandée (driver json-file) :
- `max-size=10m`
- `max-file=5`

Niveaux :
- Prod : INFO par défaut
- DEBUG uniquement temporaire et ciblé
- ERROR suivi et corrélé aux alertes

### 3.5 Alertes et escalation
Canaux :
- Warning : email + canal Slack technique.
- Critical : PagerDuty/SMS + Slack incident.

Escalade :
1. N1 (Dev on-call) : prise en charge < 15 min.
2. N2 (Ops/DevOps) : escalade si non résolu < 30 min.
3. N3 (Lead/Manager) : escalade si impact > 60 min ou service indisponible.

Procédure :
- ouvrir ticket incident (horodatage, impact, métriques, actions) ;
- communiquer toutes les 30 min jusqu'à résolution ;
- faire un post-mortem pour incidents critiques.

## 4. Recommandations
1. Automatiser backups + purge de rétention (scripts versionnés + cron/CI).
2. Mettre en place monitoring centralisé (Prometheus/Grafana + Alertmanager).
3. Ajouter Spring Boot Actuator pour health et métriques backend.
4. Centraliser les logs (ELK/OpenSearch/Loki) avec corrélation API/DB.
5. Tester la restauration mensuellement et conserver un compte rendu signé.
6. Revue trimestrielle des seuils d'alerte selon charge réelle.

## Notes et références
- Docker Engine : https://docs.docker.com/engine/
- Docker Compose : https://docs.docker.com/compose/
- PostgreSQL backup/restore (`pg_dump`, `pg_restore`) : https://www.postgresql.org/docs/current/backup-dump.html
- PostgreSQL `pg_isready` : https://www.postgresql.org/docs/current/app-pg-isready.html
- Spring Boot Actuator : https://docs.spring.io/spring-boot/reference/actuator/index.html
- Observabilité Prometheus : https://prometheus.io/docs/introduction/overview/
- Grafana Alerting : https://grafana.com/docs/grafana/latest/alerting/

## Glossaire
- **Actuator** : module Spring Boot exposant des endpoints de santé et de métriques (ex. `/actuator/health`).
- **API** : interface HTTP exposée par le backend (ex. `/api/workshops`, `/api/notions`).
- **Backup / sauvegarde** : copie des données ou de la configuration à un instant T pour restauration ultérieure.
- **Checksum (SHA-256)** : empreinte cryptographique d’un fichier pour vérifier son intégrité après copie ou transfert.
- **CI** : intégration continue, exécution automatisée de builds et tests sur chaque changement.
- **Conteneur** : unité d’exécution isolée (image + runtime), gérée ici par Docker.
- **Cron** : planificateur de tâches sur Linux pour automatiser les sauvegardes.
- **Docker Compose** : outil décrivant et orchestrant plusieurs services (`db`, `api`, `web`) via un fichier YAML.
- **Driver json-file** : mode de stockage des logs Docker sur disque, avec options de rotation (`max-size`, `max-file`).
- **Dump** : fichier produit par `pg_dump` contenant une sauvegarde logique de la base PostgreSQL.
- **Endpoint** : URL ou chemin HTTP appelé pour une fonction (API, page, santé).
- **Escalade** : passage d’un niveau de support à un autre (N1 → N2 → N3) si l’incident n’est pas résolu dans les délais.
- **Healthcheck** : contrôle automatique de l’état d’un service (ex. `pg_isready` pour PostgreSQL).
- **Image Docker** : modèle immuable utilisé pour lancer un conteneur (`postgres:13`, image applicative).
- **Journalctl** : outil Linux pour consulter les journaux système (dont le service Docker).
- **LCP / INP** : métriques Web Vitals (chargement perçu et réactivité de l’interface).
- **N1 / N2 / N3** : niveaux d’intervention (première ligne, exploitation/DevOps, pilotage).
- **Nginx** : serveur web utilisé pour servir le frontend Angular dans les images de production.
- **On-call** : astreinte pour répondre aux incidents hors horaires habituels.
- **pg_dump** : utilitaire PostgreSQL pour exporter une base (format personnalisé avec `-Fc`).
- **pg_isready** : utilitaire PostgreSQL vérifiant qu’une instance accepte les connexions.
- **pg_restore** : utilitaire PostgreSQL pour importer un dump produit par `pg_dump`.
- **Post-mortem** : analyse après incident pour en tirer des actions correctives.
- **PostgreSQL** : SGBD relationnel utilisé pour persister les données métier (`workshopsdb`).
- **Rétention** : durée pendant laquelle on conserve les sauvegardes avant purge.
- **Restauration** : réinjection d’une sauvegarde dans un environnement cible pour retrouver un état antérieur.
- **Rotation des logs** : limitation de la taille et du nombre de fichiers de logs pour éviter de saturer le disque.
- **Run (sauvegarde)** : répertoire daté `backup/AAAA-MM-JJ/HHMMSS/` regroupant les artefacts d’une exécution.
- **SLA** : engagement de délai ou de niveau de service (ex. délai de correction d’une vulnérabilité).
- **Spring Boot** : framework Java pour l’API backend.
- **Stack** : ensemble des services déployés ensemble (base, API, frontend).
- **Volume Docker** : stockage persistant attaché à un conteneur (données PostgreSQL en production typique).