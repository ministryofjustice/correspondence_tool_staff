.PHONY: docker-shell

# run docker in the background and open an interactive shell on an app container.
# use `make shell` to open a prompt on the main app container
docker-shell: env dc

# build the application
build: env docker-sync dc-build servers

# start docker and the app server
launch: docker-check docker-sync up-daemon servers

# destroy everything and start again
rebuild: docker-sync dc-reset-bg servers

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
	rm -rf ./log* ./tmp* ./.local-dev/.setup-complete
	docker compose down -v
	docker-sync clean
	docker system prune -f
	clear

dc-reset: dc-clean
	docker compose up --build

dc-reset-bg: dc-clean
	docker compose up -d --build

dc-build: # no cleaning
	docker compose up -d --build

down:
	docker-sync stop
	docker-sync clean
	docker compose down

up: env
	docker compose up

up-daemon: env
	docker compose up -d

setup:
	docker compose exec app /usr/bin/install.sh

spec-setup:
	@/usr/bin/spec-install.sh

sidekiq-anon:
	bundle exec sidekiq -C config/sidekiq-anonymizer-jobs.yml

sidekiq-jobs:
	bundle exec sidekiq -C config/sidekiq-background-jobs.yml

sidekiq-quick:
	bundle exec sidekiq -C config/sidekiq-quick-jobs.yml

sidekiq-uploads:
	bundle exec sidekiq -C config/sidekiq-uploads.yml

browser-sync:
	docker compose exec -d app /usr/bin/browserSync.sh

server:
	docker compose exec app /usr/bin/app-server-start.sh

restart:
	docker-sync clean
	docker-compose down
	make dc

# Remove ignored git files
clean:
	@if [ -d ".git" ]; then git clean -xdf --exclude ".env" --exclude ".idea"; fi

shell:
	docker compose exec --workdir /usr/src/app app /bin/sh

specs: docker-check
	clear
	@chmod +x .local-dev/bin/spec-intro.sh && .local-dev/bin/spec-intro.sh
	@docker compose exec --workdir /usr/src/app spec bash

docker-check:
	@chmod +x ./.local-dev/bin/check-docker-running.sh
	@./.local-dev/bin/check-docker-running.sh

#####
## Production CI mock
#####

ks-apply:
	kubectl apply -f config/kubernetes/development
