#!/bin/sh
set +ex

# Make these available via Settings in the app
export SETTINGS__GIT_COMMIT="$APP_GIT_COMMIT"
export SETTINGS__BUILD_DATE="$APP_BUILD_DATE"
export SETTINGS__GIT_SOURCE="$APP_BUILD_TAG"

# printf '\e[33mINFO: Running asset pipeline build\e[0m\n'
# RAILS_ENV=production bundle exec rake assets:clean assets:precompile assets:non_digested SECRET_KEY_BASE=required_but_does_not_matter_for_assets

case ${DOCKER_STATE} in
create)
    printf '\e[33mINFO: executing Setup\e[0m\n'
    bundle exec rails db:setup
    bundle exec rails data:migrate
    ;;
migrate)
    printf '\e[33mINFO: executing rake db:migrate\e[0m\n'
    bundle exec rails db:migrate
    bundle exec rails data:migrate
    ;;
seed)
    printf '\e[33mINFO: executing rake db:seed\e[0m\n'
    bundle exec rake db:seed
    ;;
reload)
    printf '\e[33mINFO: executing rake db:create + db:reload\e[0m\n'
    bundle exec rake db:create
    bundle exec rake db:reload
    ;;
reseed)
    printf '\e[33mINFO: executing rake db:reseed\e[0m\n'
    bundle exec rake db:reseed
    ;;
development-setup)
    printf '\e[33mINFO: executing development setup and seed\e[0m\n'
    rails db:setup
    echo "migrating database..."
    rails db:migrate
    rails data:migrate
    echo "seeding database for dev environment"
    rails db:seed
    rails db:seed:dev
    ;;
reset)
    if [[ "$ENV" = staging || "$ENV" = prod ]]
    then
        printf '\e[33mINFO: Cannot reset database in staging or production environments\e[0m\n'
        echo "https://dsdmoj.atlassian.net/wiki/display/CD/Resetting+the+DB+in+Deployed+Environments"
        echo "For instructions on how to do this manually."
    else
        printf '\e[33mINFO: executing development database reset\e[0m\n'
        bundle exec rails db:reset
    fi
    ;;
esac

set -ex

# if REDIS_URL is not set then we start redis-server locally (in local environment)
if [ -z ${REDIS_URL+x} ]; then
  printf '\e[33mINFO: Starting redis-server daemon\e[0m\n'
  redis-server --daemonize yes
else
  printf '\e[33mINFO: Using remote redis-server specified in REDIS_URL\e[0m\n'
fi


printf '\e[33mINFO: Launching Puma\e[0m\n'
bundle exec puma -C config/puma.rb -e production
