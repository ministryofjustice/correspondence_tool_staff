#!/bin/bash
export RAILS_ENV=production
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
