# =============================================================
# IMAGE DE BASE
# =============================================================
# On part de l'image officielle Metabase (version stable v0.49)
# On évite "latest" ici pour garantir la reproductibilité du build :
# "latest" peut changer du jour au lendemain et casser le déploiement
# =============================================================
FROM metabase/metabase:v0.49.0

# =============================================================
# LABELS (MÉTADONNÉES DE L'IMAGE)
# =============================================================
# Les labels sont des informations attachées à l'image.
# Ils n'affectent pas le fonctionnement de l'app mais permettent
# de documenter, identifier et tracer l'image (bonne pratique DevOps)
# Visibles avec : docker inspect metabase-tp:1.0
# =============================================================
LABEL maintainer="kdjidawo@gmail.com"
LABEL version="1.0"
LABEL description="Image Metabase personnalisée - TP BI Institut Jean"
LABEL org.opencontainers.image.title="Metabase TP"
LABEL org.opencontainers.image.version="1.0"
LABEL org.opencontainers.image.authors="kdjidawo@gmail.com"

# =============================================================
# VARIABLE D'ENVIRONNEMENT PAR DÉFAUT
# =============================================================
# Cette valeur est intégrée dans l'image comme valeur par défaut.
# Elle peut toujours être écrasée par le docker-compose.yml ou
# par un -e lors d'un docker run.
# =============================================================
ENV MB_SITE_NAME="Institut Jean - TP BI Metabase"

# =============================================================
# PORT EXPOSÉ
# =============================================================
# Documente que ce conteneur écoute sur le port 3000.
# C'est informatif (ne publie pas le port automatiquement),
# mais c'est une bonne pratique pour la lisibilité du Dockerfile.
# =============================================================
EXPOSE 3000

# =============================================================
# NOTE : On n'a pas besoin de redéfinir CMD ni ENTRYPOINT
# car l'image officielle Metabase les définit déjà correctement.
# Toute la configuration se fait via les variables d'environnement
# passées dans le docker-compose.yml
# =============================================================
