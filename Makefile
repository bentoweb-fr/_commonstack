NETWORK=proxy

run:
	@docker network inspect $(NETWORK) >/dev/null 2>&1 || docker network create $(NETWORK)
	@docker compose up -d

stop:
	@docker compose down
