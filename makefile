.PHONY: launch
.DEFAULT_GOAL := launch

# run docker in the background and open an interactive shell on an app container.
# use `make shell` to open a prompt on the main app container
docker-shell: env dc

# build the application
build: env docker-sync dc-build servers

# start docker and the app server
launch: docker-check docker-sync up-daemon servers

# destroy everything and start again
rebuild: dc-reset-bg servers

# a collection of server starters
servers: docker-check setup browser-sync server

env:
	@[ -f "./.env" ] || cp .env.example .env

docker-sync:
	docker-sync start

dc:
	docker compose up -d app
	docker compose run --rm --entrypoint=/bin/sh app

dc-clean:
	rm -rf ./log* ./config/docker-dev/.setup-complete
	docker compose down -v
	docker-sync stop || true
	docker-sync clean
	docker system prune -f
	clear

dc-reset: dc-clean docker-sync
	docker compose up --build

dc-reset-bg: dc-clean docker-sync
	docker compose up -d --build

dc-build: # no cleaning
	docker compose up -d --build

down:
	docker-sync clean
	docker compose down

up: launch

up-daemon: env
	docker compose up -d

setup:
	docker compose exec app /usr/bin/install.sh

sidekiq-anon:
	bundle exec sidekiq -C config/sidekiq-anonymizer-jobs.yml

sidekiq-jobs:
	bundle exec sidekiq -C config/sidekiq-background-jobs.yml

sidekiq-quick:
	bundle exec sidekiq -C config/sidekiq-quick-jobs.yml

sidekiq-uploads:
	bundle exec sidekiq -C config/sidekiq-uploads.yml

browser-sync:
	@docker compose exec -d app /usr/bin/browserSync.sh

server: endpoints
	@docker compose exec app /usr/bin/app-server-start.sh

restart:
	docker-sync clean
	docker-compose down
	make dc

# Remove ignored git files
clean:
	@if [ -d ".git" ]; then git clean -xdf --exclude ".env" --exclude ".idea"; fi

shell:
	docker compose exec --workdir /usr/src/app app /bin/sh

docker-check:
	@chmod +x ./config/docker-dev/bin/check-docker.sh
	@./config/docker-dev/bin/check-docker.sh

endpoints:
	@chmod +x ./config/docker-dev/bin/announce-endpoints.sh
	@./config/docker-dev/bin/announce-endpoints.sh
