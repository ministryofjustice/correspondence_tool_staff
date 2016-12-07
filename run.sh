#!/bin/bash
export RAILS_ENV=production
# Make these available via Settings in the app
export SETTINGS__GIT_COMMIT="$APP_GIT_COMMIT"
export SETTINGS__BUILD_DATE="$APP_BUILD_DATE"
export SETTINGS__GIT_SOURCE="$APP_BUILD_TAG"
cd /usr/src/app
case ${DOCKER_STATE} in
create)
    echo "running create"
    bundle exec rails db:setup
    ;;
migrate)
    echo "running migrate"
    bundle exec rails db:migrate
    ;;
esac
bundle exec puma -C config/puma.rb
