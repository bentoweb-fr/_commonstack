NETWORK=proxy
MODE ?= prod
MKCERT ?= $(HOME)/.local/bin/mkcert
LOCAL_CERT_DOMAIN ?= 36o-local.fr

ifeq ($(MODE),prod)
TRAEFIK_MODE := prod
TRAEFIK_API_INSECURE ?= false
TRAEFIK_LOG_LEVEL ?= INFO
TRAEFIK_INSECURE_SKIP_VERIFY ?= false
TRAEFIK_DASHBOARD_HOST ?= 127.0.0.1
TRAEFIK_DASHBOARD_PORT ?= 8080
else
TRAEFIK_MODE := dev
TRAEFIK_API_INSECURE ?= true
TRAEFIK_LOG_LEVEL ?= DEBUG
TRAEFIK_INSECURE_SKIP_VERIFY ?= true
TRAEFIK_DASHBOARD_HOST ?= 0.0.0.0
TRAEFIK_DASHBOARD_PORT ?= 8080
endif

export TRAEFIK_MODE TRAEFIK_API_INSECURE TRAEFIK_LOG_LEVEL TRAEFIK_INSECURE_SKIP_VERIFY TRAEFIK_DASHBOARD_HOST TRAEFIK_DASHBOARD_PORT

cert-local:
	@command -v $(MKCERT) >/dev/null || { echo "mkcert est requis"; exit 1; }
	@mkdir -p certs tls
	@TRUST_STORES=nss $(MKCERT) -install
	@$(MKCERT) -cert-file certs/local.crt -key-file certs/local.key "$(LOCAL_CERT_DOMAIN)" "*.$(LOCAL_CERT_DOMAIN)"
	@chmod 644 certs/local.crt
	@chmod 600 certs/local.key
	@printf '%s\n' \
		'tls:' \
		'  certificates:' \
		'    - certFile: /certs/local.crt' \
		'      keyFile: /certs/local.key' > tls/local.yaml

run:
	@mkdir -p certs letsencrypt tls
	@touch letsencrypt/acme.json
	@chmod 600 letsencrypt/acme.json
	@docker network inspect $(NETWORK) >/dev/null 2>&1 || docker network create $(NETWORK)
	@docker compose --env-file .env up -d

stop:
	@docker compose down
