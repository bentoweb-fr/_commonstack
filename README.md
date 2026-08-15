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
ACME_EMAIL=admin@example.com
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

## HTTPS OVH avec HTTP-01

HTTP-01 est la solution la plus simple lorsqu'un seul VPS reçoit directement le trafic Internet. Elle ne demande aucune clé API OVH. Elle ne permet en revanche pas de créer un certificat wildcard (`*.example.com`).

Pour chaque domaine ou sous-domaine dans la zone DNS OVH :

1. Créer un enregistrement `A` vers l'IPv4 publique du VPS.
2. Créer un enregistrement `AAAA` uniquement si le VPS est réellement joignable en IPv6. Supprimer tout `AAAA` obsolète.
3. Autoriser les ports TCP `80` et `443` dans le pare-feu OVH et dans celui du VPS.
4. Vérifier qu'aucun autre serveur, comme Nginx ou Apache, n'occupe ces ports.
5. Démarrer Traefik avec `make run`.

Le port `80` doit rester accessible publiquement : Let's Encrypt appelle temporairement `http://domaine/.well-known/acme-challenge/...`. La redirection HTTP vers HTTPS configurée par Traefik est compatible avec ce challenge.

Contrôles utiles depuis une autre machine :

```bash
dig +short A app.example.com
dig +short AAAA app.example.com
curl -I http://app.example.com
curl -I https://app.example.com
```

Sur le VPS :

```bash
sudo ss -lntp | grep -E ':(80|443) '
docker compose logs traefik | grep -Ei 'acme|certificate|challenge|error'
```

En cas d'échecs répétés pendant les essais, utiliser temporairement le serveur de staging Let's Encrypt pour éviter ses limites de requêtes :

```yaml
- "--certificatesresolvers.le.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory"
```

Retirer cette option avant de demander le certificat de production.

## Routage par domaine

Chaque service doit être exposé via Traefik par labels Docker, selon son host.

### Exemple backend

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.api.rule=Host(`api.example.com`)"
  - "traefik.http.routers.api.entrypoints=websecure"
  - "traefik.http.services.api.loadbalancer.server.port=3000"
```

### Exemple frontend

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.frontend.rule=Host(`app.example.com`)"
  - "traefik.http.routers.frontend.entrypoints=websecure"
  - "traefik.http.services.frontend.loadbalancer.server.port=5173"
```

Le TLS et le resolver `le` sont hérités de l'entrypoint `websecure`. Le service doit aussi rejoindre le réseau Docker externe `proxy`. Il n'est pas nécessaire de publier son port applicatif sur le VPS.

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
