# TP BI Metabase - Institut Jean

Plateforme de Business Intelligence déployée avec Docker, Traefik et PostgreSQL.

## Architecture

```
Internet (HTTPS)
       ↓
Traefik (Reverse Proxy + Let's Encrypt)
       ↓
Metabase (conteneur) ←→ PostgreSQL (conteneur)
```

| Service    | Rôle                                      | Image                    |
|------------|-------------------------------------------|--------------------------|
| Traefik    | Reverse proxy + certificat HTTPS          | traefik:v2.11            |
| Metabase   | Plateforme BI (dashboards, questions)     | metabase-tp:1.0 (custom) |
| PostgreSQL | Base de données externe                   | postgres:16              |

## Prérequis

- Docker Desktop avec WSL 2 activé
- Ports 80 et 443 ouverts sur le réseau
- Domaine DNS pointant vers l'IP publique

## Lancement

1. Copier le fichier d'environnement :
```bash
cp .env.example .env
```

2. Renseigner les variables dans `.env`

3. Builder et lancer :
```bash
docker compose up -d --build
```

4. Vérifier que les services tournent :
```bash
docker compose ps
```

5. Accéder à Metabase : `https://ton-domaine` ou `http://localhost:3000`

## Commandes utiles

```bash
# Voir les logs en temps réel
docker compose logs -f

# Voir les logs d'un service spécifique
docker compose logs traefik --tail 50
docker compose logs metabase --tail 50

# Redémarrer un service
docker compose restart metabase

# Arrêter sans supprimer les volumes
docker compose down

# Arrêter ET supprimer les volumes (repart de zéro)
docker compose down -v
```

## Variables d'environnement

| Variable | Description |
|----------|-------------|
| `POSTGRES_DB` | Nom de la base PostgreSQL |
| `POSTGRES_USER` | Utilisateur PostgreSQL |
| `POSTGRES_PASSWORD` | Mot de passe PostgreSQL |
| `MB_SITE_URL` | URL publique de Metabase |
| `MB_ADMIN_EMAIL` | Email du compte admin Metabase |
| `MB_ADMIN_PASSWORD` | Mot de passe admin Metabase |
| `MB_DB_HOST` | Hôte PostgreSQL vu par Metabase |

## Pipeline CI/CD

Le pipeline GitHub Actions (`.github/workflows/deploy.yml`) se déclenche à chaque push sur `main` et effectue :
- Build de l'image Docker `metabase-tp:1.0`
- Validation de la syntaxe du `docker-compose.yml`

## Auteur

- **Nom** : Institut Jean
- **Email** : kdjidawo@gmail.com
- **TP** : Virtualisation / Cloud - Déploiement plateforme BI
