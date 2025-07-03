#!/bin/sh

if ! bundle show puma 2>/dev/null; then
  printf '\e[33mPuma server could not be started.\e[0m\n'
  printf '\e[33mThis is likely an issue with our bundle install script; /usr/bin/install.sh\e[0m\n'
  exit 0
fi

mkdir -p tmp/pids

# sync asset and view changes to the browser...
# bundle exec rails generate browser_sync_rails:install
# bundle exec rails browser_sync:start

printf '\e[33mINFO: Launching Puma\e[0m\n'
bundle exec puma -C config/puma.rb
