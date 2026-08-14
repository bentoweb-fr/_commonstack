NETWORK=proxy
MODE ?= dev

ifeq ($(MODE),prod)
TRAEFIK_MODE := prod
TRAEFIK_API_INSECURE ?= false
TRAEFIK_LOG_LEVEL ?= INFO
TRAEFIK_INSECURE_SKIP_VERIFY ?= false
TRAEFIK_DASHBOARD_PORT ?= 127.0.0.1:8080
else
TRAEFIK_MODE := dev
TRAEFIK_API_INSECURE ?= true
TRAEFIK_LOG_LEVEL ?= DEBUG
TRAEFIK_INSECURE_SKIP_VERIFY ?= true
TRAEFIK_DASHBOARD_PORT ?= 8080
endif

export TRAEFIK_MODE TRAEFIK_API_INSECURE TRAEFIK_LOG_LEVEL TRAEFIK_INSECURE_SKIP_VERIFY TRAEFIK_DASHBOARD_PORT

run:
	@mkdir -p letsencrypt
	@touch letsencrypt/acme.json
	@chmod 600 letsencrypt/acme.json
	@docker network inspect $(NETWORK) >/dev/null 2>&1 || docker network create $(NETWORK)
	@docker compose --env-file .env up -d

stop:
	@docker compose down
