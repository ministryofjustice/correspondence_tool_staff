#!/bin/bash
export RAILS_ENV=production
cd /usr/src/app
case ${DOCKER_STATE} in
create)
    echo "running create"
    bundle exec rails db:setup
    ;;
migrate)
    echo "running migrate and seed"
    bundle exec rails db:migrate
    ;;
esac
bundle exec puma -d -C config/puma.rb
tail -f /var/log/dmesg
