# _commonstack

Proxy Traefik centralise pour plusieurs projets, avec un mode de fonctionnement dev et un profil stricte pour le VPS de production.

## Démarrage rapide

```bash
cp .env.example .env
make run
```

La cible `run` prépare automatiquement `letsencrypt/acme.json` avec les permissions `600`, nécessaires à Traefik pour Let's Encrypt.

## Profil recommandé pour un VPS

Le projet est désormais pensé avec un profil de production par défaut :

```env
TRAEFIK_MODE=prod
TRAEFIK_HTTP_PORT=80
TRAEFIK_HTTPS_PORT=443
TRAEFIK_DASHBOARD_HOST=127.0.0.1
TRAEFIK_DASHBOARD_PORT=8080
TRAEFIK_API_INSECURE=false
TRAEFIK_LOG_LEVEL=INFO
TRAEFIK_INSECURE_SKIP_VERIFY=false
```

Cela donne un comportement plus sécurisé :
- dashboard masqué en localhost uniquement
- accès public uniquement sur 80 / 443
- logs en mode info
- vérification TLS activée
- API Traefik non publique

## Bascule dev / prod

Tu peux forcer le mode explicitement :

```bash
# dev local
make run MODE=dev

# production vps
make run MODE=prod
```

ou en gardant un `.env` avec le bon profil, puis :

```bash
docker compose --env-file .env up -d
```

### Exemple dev

```env
TRAEFIK_MODE=dev
TRAEFIK_API_INSECURE=true
TRAEFIK_LOG_LEVEL=DEBUG
TRAEFIK_INSECURE_SKIP_VERIFY=true
TRAEFIK_DASHBOARD_HOST=0.0.0.0
TRAEFIK_DASHBOARD_PORT=8080
```

### Exemple prod VPS stricte

```env
TRAEFIK_MODE=prod
TRAEFIK_HTTP_PORT=80
TRAEFIK_HTTPS_PORT=443
TRAEFIK_DASHBOARD_HOST=127.0.0.1
TRAEFIK_DASHBOARD_PORT=8080
TRAEFIK_API_INSECURE=false
TRAEFIK_LOG_LEVEL=INFO
TRAEFIK_INSECURE_SKIP_VERIFY=false
```

Le port bind du dashboard est un port seul. La valeur `TRAEFIK_DASHBOARD_HOST` reste un IP/host, tandis que `TRAEFIK_DASHBOARD_PORT` reste un numéro de port uniquement.

## Routage par domaine

Chaque service doit être exposé via Traefik par labels Docker, selon son host.

### Exemple backend

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.api.rule=Host(`api.example.com`)"
  - "traefik.http.routers.api.entrypoints=websecure"
  - "traefik.http.routers.api.tls=true"
  - "traefik.http.routers.api.tls.certresolver=le"
  - "traefik.http.services.api.loadbalancer.server.port=3000"
```

### Exemple frontend

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.frontend.rule=Host(`app.example.com`)"
  - "traefik.http.routers.frontend.entrypoints=websecure"
  - "traefik.http.routers.frontend.tls=true"
  - "traefik.http.routers.frontend.tls.certresolver=le"
  - "traefik.http.services.frontend.loadbalancer.server.port=5173"
```

## Bonnes pratiques sur VPS

- garder le réseau Docker `proxy` externe et partagé
- exposer uniquement `80` et `443` sur le VPS
- ne jamais publier le dashboard Traefik sur l’Internet public
- utiliser les domaines réels et `Host(...)` pour le routage
- laisser le chargeur Let’s Encrypt gérer les certificats HTTPS
- utiliser un `.env` dédié à chaque environnement

## Fichiers de référence

- [.env.example](.env.example)
- [docker-compose.yml](docker-compose.yml)
- [tls.yaml](tls.yaml)
