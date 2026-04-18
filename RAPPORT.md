# Rapport de Travaux Pratiques
## Déploiement d'une Plateforme de Business Intelligence avec Docker

---

**Institut Saint Jean**
Département Informatique — Master Ingénierie

| | |
|---|---|
| **Module** | Cloud et Virtualisation |
| **Année académique** | 2025 - 2026 |
| **Niveau** | Master |
| **Étudiants** | DJIDAWO FOMANO Tyrrel Keylian |
| | DONGMO MEAFFO Leslie |

---

## Table des Matières

1. [Introduction](#1-introduction)
2. [Présentation du Projet](#2-présentation-du-projet)
3. [Architecture Technique](#3-architecture-technique)
4. [Phase 1 — Préparation de l'Environnement](#4-phase-1--préparation-de-lenvironnement)
5. [Phase 2 — Configuration Docker Compose](#5-phase-2--configuration-docker-compose)
6. [Phase 3 — HTTPS avec Traefik et Let's Encrypt](#6-phase-3--https-avec-traefik-et-lets-encrypt)
7. [Phase 4 — Image Docker Personnalisée](#7-phase-4--image-docker-personnalisée)
8. [Phase 5 — Connexion Base de Données et Fonctionnalités BI](#8-phase-5--connexion-base-de-données-et-fonctionnalités-bi)
9. [Phase 6 — Aspect DevOps](#9-phase-6--aspect-devops)
10. [Difficultés Rencontrées et Solutions](#10-difficultés-rencontrées-et-solutions)
11. [Conclusion](#11-conclusion)
12. [Annexes](#12-annexes)

---

## 1. Introduction

Dans le cadre du module Cloud et Virtualisation, ce travail pratique a pour objectif le déploiement complet d'une plateforme de Business Intelligence (BI) en environnement conteneurisé. Ce type de déploiement est représentatif des pratiques actuelles en ingénierie logicielle et DevOps, où la conteneurisation est devenue un standard industriel incontournable.

L'outil déployé est **Metabase**, une solution open-source de BI permettant à des utilisateurs non techniques de visualiser et analyser des données sans écrire de requêtes SQL. Il s'agit d'une alternative open-source aux solutions propriétaires telles que Power BI ou Tableau.

Ce rapport présente l'ensemble des étapes de réalisation, les choix techniques effectués, les difficultés rencontrées ainsi que les solutions apportées.

---

## 2. Présentation du Projet

### 2.1 Objectifs

Le projet vise à déployer une stack complète comprenant :

- Une instance **Metabase** accessible via une interface web sécurisée
- Une base de données **PostgreSQL** servant de source de données externe
- Un reverse proxy **Traefik** assurant la terminaison TLS et le routage HTTPS
- Une image Docker **personnalisée** pour Metabase
- Un pipeline **CI/CD** automatisant le build et la validation

### 2.2 Outils et Technologies

| Technologie | Version | Rôle |
|-------------|---------|------|
| Docker Desktop | Latest | Moteur de conteneurisation |
| Docker Compose | v2 | Orchestration multi-conteneurs |
| Metabase | v0.49.0 | Plateforme BI |
| PostgreSQL | 16 | Base de données relationnelle |
| Traefik | v2.11 | Reverse proxy et gestion TLS |
| GitHub Actions | — | Pipeline CI/CD |
| DuckDNS | — | DNS dynamique gratuit |

---

## 3. Architecture Technique

### 3.1 Schéma d'Architecture

```
Utilisateur (navigateur)
         │
         │ HTTPS (port 443)
         ▼
┌─────────────────────┐
│       Traefik        │  ← Reverse Proxy
│  (Let's Encrypt TLS) │  ← Certificat SSL automatique
└─────────┬───────────┘
          │ HTTP interne (port 3000)
          ▼
┌─────────────────────┐
│      Metabase        │  ← Application BI
│   metabase-tp:1.0    │  ← Image personnalisée
└─────────┬───────────┘
          │ PostgreSQL (port 5432)
          ▼
┌─────────────────────┐
│     PostgreSQL 16    │  ← Base de données externe
│    (postgres-db)     │  ← Données persistées sur volume
└─────────────────────┘
```

### 3.2 Réseau Docker

Tous les conteneurs partagent le réseau Docker par défaut `tp-metabase_default`, ce qui leur permet de communiquer entre eux par nom de service (DNS interne Docker). Traefik accède au daemon Docker via TCP sur `host.docker.internal:2375`, spécificité de l'environnement Windows avec Docker Desktop.

### 3.3 Volumes Persistants

| Volume | Contenu |
|--------|---------|
| `pgdata` | Données PostgreSQL |
| `metabase-data` | Données internes Metabase |
| `traefik-certs` | Certificats Let's Encrypt |

---

## 4. Phase 1 — Préparation de l'Environnement

### 4.1 Installation de Docker Desktop

L'environnement de travail est Windows 11 avec Docker Desktop configuré en mode WSL 2 (Windows Subsystem for Linux). WSL 2 a été préféré à Hyper-V pour ses meilleures performances I/O et sa compatibilité native avec les outils Linux.

La configuration Docker Desktop retenue :
- Backend : WSL 2
- Ressources allouées : 4 Go RAM, 2 CPU
- Option activée : "Expose daemon on tcp://localhost:2375 without TLS"

### 4.2 Validation

```bash
docker run hello-world
docker --version
docker compose version
```

---

## 5. Phase 2 — Configuration Docker Compose

### 5.1 Structure du Fichier .env

Le fichier `.env` centralise toutes les variables de configuration sensibles. Cette approche respecte le principe **12-Factor App** qui préconise de séparer la configuration du code.

```
# PostgreSQL
POSTGRES_DB=metabase_tp
POSTGRES_USER=metabase_user
POSTGRES_PASSWORD=*****

# Metabase
MB_SITE_URL=https://keylianleslie-tp-bi.duckdns.org
MB_ADMIN_EMAIL=[email]
MB_ADMIN_PASSWORD=*****

# Connexion Metabase → PostgreSQL
MB_DB_TYPE=postgres
MB_DB_HOST=postgres-db
MB_DB_PORT=5432
```

Le fichier `.env` est exclu du dépôt Git via `.gitignore` pour ne jamais exposer les secrets.

### 5.2 Services Docker Compose

Le fichier `docker-compose.yml` définit trois services interdépendants avec une gestion des dépendances via `depends_on` et `condition: service_healthy`.

#### Service PostgreSQL

```yaml
postgres-db:
  image: postgres:16
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
    interval: 10s
    timeout: 5s
    retries: 5
    start_period: 20s
```

#### Service Metabase

```yaml
metabase:
  build: .
  image: metabase-tp:1.0
  depends_on:
    postgres-db:
      condition: service_healthy
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
    interval: 30s
    timeout: 10s
    retries: 5
    start_period: 120s
```

### 5.3 Healthchecks

Les healthchecks permettent à Docker de connaître l'état réel d'un service au-delà du simple statut "running". Le mécanisme `depends_on` avec `condition: service_healthy` garantit que Metabase ne démarre qu'une fois PostgreSQL pleinement opérationnel, évitant ainsi les erreurs de connexion au démarrage.

---

## 6. Phase 3 — HTTPS avec Traefik et Let's Encrypt

### 6.1 Rôle de Traefik

Traefik est un reverse proxy moderne conçu nativement pour les environnements conteneurisés. Il détecte automatiquement les conteneurs Docker via leurs labels et configure le routage dynamiquement, sans redémarrage.

### 6.2 Configuration ACME / Let's Encrypt

Le challenge HTTP-01 a été configuré pour l'obtention automatique du certificat SSL :

```yaml
- "--certificatesresolvers.letsencrypt.acme.httpChallenge=true"
- "--certificatesresolvers.letsencrypt.acme.httpChallenge.entryPoint=web"
- "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
```

Let's Encrypt valide la propriété du domaine en effectuant une requête HTTP sur `http://domaine/.well-known/acme-challenge/`. Le certificat obtenu est stocké dans le volume persistant `traefik-certs`.

### 6.3 Redirection HTTP vers HTTPS

```yaml
- "--entrypoints.web.http.redirections.entryPoint.to=websecure"
- "--entrypoints.web.http.redirections.entryPoint.scheme=https"
- "--entrypoints.web.http.redirections.entryPoint.permanent=true"
```

Tout trafic HTTP (port 80) est automatiquement redirigé en HTTPS (port 443) avec un code 301.

### 6.4 Labels Traefik sur Metabase

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.metabase.rule=Host(`keylianleslie-tp-bi.duckdns.org`)"
  - "traefik.http.routers.metabase.entrypoints=websecure"
  - "traefik.http.routers.metabase.tls=true"
  - "traefik.http.routers.metabase.tls.certresolver=letsencrypt"
  - "traefik.http.services.metabase.loadbalancer.server.port=3000"
```

---

## 7. Phase 4 — Image Docker Personnalisée

### 7.1 Dockerfile

Une image personnalisée `metabase-tp:1.0` a été créée à partir de l'image officielle Metabase. L'utilisation d'une version fixe (`v0.49.0`) plutôt que `latest` garantit la reproductibilité du build.

```dockerfile
FROM metabase/metabase:v0.49.0

LABEL maintainer="[email]"
LABEL version="1.0"
LABEL description="Image Metabase personnalisée - TP BI Institut Jean"
LABEL org.opencontainers.image.title="Metabase TP"
LABEL org.opencontainers.image.version="1.0"

ENV MB_SITE_NAME="Institut Jean - TP BI Metabase"

EXPOSE 3000
```

### 7.2 Build et Versioning

```bash
docker build -t metabase-tp:1.0 .
docker images metabase-tp
docker inspect metabase-tp:1.0 --format "{{json .Config.Labels}}"
```

Le versioning sémantique (`1.0`) permet de tracer les évolutions de l'image dans le temps.

---

## 8. Phase 5 — Connexion Base de Données et Fonctionnalités BI

### 8.1 Initialisation des Données

Un script SQL `init-db/01_init_data.sql` a été créé pour peupler automatiquement la base de données avec des données de démonstration représentatives d'un institut de formation.

Deux tables ont été créées :

**Table `ventes`** : 30 enregistrements couvrant 6 mois de données de ventes de formations par région.

```sql
CREATE TABLE IF NOT EXISTS ventes (
    id         SERIAL PRIMARY KEY,
    produit    VARCHAR(100) NOT NULL,
    region     VARCHAR(50)  NOT NULL,
    montant    NUMERIC(10,2) NOT NULL,
    quantite   INTEGER NOT NULL,
    date_vente DATE NOT NULL
);
```

**Table `etudiants`** : 10 enregistrements d'inscriptions avec statuts.

### 8.2 Connexion de la Source de Données dans Metabase

La connexion à PostgreSQL a été configurée dans l'interface d'administration de Metabase :

| Paramètre | Valeur |
|-----------|--------|
| Type | PostgreSQL |
| Host | postgres-db |
| Port | 5432 |
| Database | metabase_tp |
| Username | metabase_user |

### 8.3 Création du Dashboard

Deux questions ont été créées et assemblées dans un dashboard :

- **"Ventes par région"** : agrégation `SUM(montant)` groupée par `region`, visualisée en bar chart
- **"Évolution des ventes mensuelles"** : agrégation `SUM(montant)` groupée par mois, visualisée en line chart

Le dashboard **"Dashboard BI - Institut Jean"** regroupe ces deux visualisations et constitue la validation fonctionnelle de la plateforme BI.

---

## 9. Phase 6 — Aspect DevOps

### 9.1 Pipeline CI/CD avec GitHub Actions

Un pipeline d'intégration continue a été mis en place via GitHub Actions. Il se déclenche automatiquement à chaque push sur la branche `main`.

```
Push sur main
     │
     ▼
Job 1 : Build Image Docker
  → Checkout du code
  → Configuration Docker Buildx
  → Build metabase-tp:1.0
  → Vérification de l'image
     │
     ▼
Job 2 : Validation docker-compose.yml
  → Création d'un .env de test
  → docker compose config
```

### 9.2 Bonnes Pratiques DevOps Appliquées

| Pratique | Implémentation |
|----------|----------------|
| Secrets hors du code | Variables dans `.env`, exclu via `.gitignore` |
| Image versionnée | `metabase-tp:1.0` avec tag sémantique |
| Healthchecks | Sur PostgreSQL et Metabase avec `start_period` |
| Volumes persistants | `pgdata`, `metabase-data`, `traefik-certs` |
| Infrastructure as Code | Tout le déploiement décrit dans `docker-compose.yml` |
| Documentation | `README.md` avec architecture, prérequis et commandes |

---

## 10. Difficultés Rencontrées et Solutions

### 10.1 Blocage Réseau Institutionnel

**Problème** : Le réseau de l'Institut Saint Jean bloque les ports 80 et 443 entrants, rendant impossible la validation du challenge HTTP-01 de Let's Encrypt depuis internet.

**Solution** : Les tests ont été réalisés en local via `http://localhost:3000`. La configuration Traefik et Let's Encrypt reste fonctionnelle et opérationnelle sur un réseau sans restriction. Pour contourner ce blocage en environnement institutionnel, l'outil ngrok a été identifié comme solution alternative permettant de créer un tunnel HTTPS sans nécessiter l'ouverture de ports.

### 10.2 Conflit de Timing sur l'Initialisation PostgreSQL

**Problème** : Le script `init-db/01_init_data.sql` n'était pas exécuté car Metabase initialisait la base `metabase_tp` avant que PostgreSQL puisse lancer les scripts d'initialisation, rendant le volume non vierge.

**Solution** : Les données ont été insérées manuellement via `psql` directement dans le conteneur PostgreSQL. Le mécanisme `depends_on` avec `condition: service_healthy` a été renforcé pour garantir l'ordre de démarrage.

### 10.3 Blocage Pipeline GitHub Actions

**Problème** : Le pipeline CI/CD a été bloqué par une restriction de facturation sur le compte GitHub ("account is locked due to a billing issue").

**Solution** : Le fichier de pipeline `.github/workflows/deploy.yml` est correctement configuré et validé syntaxiquement. L'exécution sera possible dès la résolution du problème de compte GitHub.

---

## 11. Conclusion

Ce travail pratique a permis de mettre en œuvre une stack complète de déploiement d'une application BI en environnement conteneurisé. Les compétences suivantes ont été acquises et démontrées :

- Maîtrise de Docker et Docker Compose pour l'orchestration multi-conteneurs
- Configuration d'un reverse proxy Traefik avec gestion automatique des certificats SSL
- Création d'une image Docker personnalisée et versionnée
- Utilisation des variables d'environnement comme bonne pratique de sécurité
- Mise en place de healthchecks pour garantir la robustesse du déploiement
- Initialisation automatique d'une base de données avec des données de démonstration
- Création de visualisations et dashboards dans Metabase
- Mise en place d'un pipeline CI/CD avec GitHub Actions

Les difficultés rencontrées, notamment le blocage réseau institutionnel, ont permis d'explorer des solutions alternatives (ngrok, certificats auto-signés) et de mieux comprendre les contraintes réelles d'un déploiement en environnement d'entreprise.

---

## 12. Annexes

### Annexe A — Structure du Projet

```
tp-metabase/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── init-db/
│   └── 01_init_data.sql
├── .env                  (non versionné)
├── .gitignore
├── Dockerfile
├── docker-compose.yml
└── README.md
```

### Annexe B — Commandes Principales

```bash
# Lancer la stack complète
docker compose up -d --build

# Vérifier l'état des services
docker compose ps

# Consulter les logs Traefik
docker logs traefik --tail 50

# Consulter les logs Metabase
docker compose logs metabase -f

# Vérifier les tables PostgreSQL
docker exec -it postgres-externe psql -U metabase_user -d metabase_tp -c "\dt"

# Inspecter les labels de l'image custom
docker inspect metabase-tp:1.0 --format "{{json .Config.Labels}}"

# Arrêter et supprimer les volumes
docker compose down -v
```

### Annexe C — Variables d'Environnement

| Variable | Description |
|----------|-------------|
| `POSTGRES_DB` | Nom de la base PostgreSQL |
| `POSTGRES_USER` | Utilisateur PostgreSQL |
| `POSTGRES_PASSWORD` | Mot de passe PostgreSQL |
| `MB_SITE_URL` | URL publique de Metabase |
| `MB_SITE_NAME` | Nom affiché dans l'interface |
| `MB_ADMIN_EMAIL` | Email du compte administrateur |
| `MB_ADMIN_PASSWORD` | Mot de passe administrateur |
| `MB_DB_TYPE` | Type de base (postgres) |
| `MB_DB_HOST` | Hôte PostgreSQL |
| `MB_DB_PORT` | Port PostgreSQL (5432) |
| `MB_DB_DBNAME` | Nom de la base Metabase |
| `MB_DB_USER` | Utilisateur de connexion |
| `MB_DB_PASS` | Mot de passe de connexion |
| `MB_APPLICATION_DB_AUTO_MIGRATE` | Migration automatique au démarrage |
| `JAVA_TIMEZONE` | Fuseau horaire JVM |

---

*Rapport rédigé par DJIDAWO FOMANO Tyrrel Keylian et DONGMO MEAFFO Leslie*
*Institut Saint Jean — Master Cloud et Virtualisation — 2025-2026*
