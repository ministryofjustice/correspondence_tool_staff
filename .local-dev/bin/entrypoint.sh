#!/bin/sh

bundler install

# Make these available via Settings in the app
export SETTINGS__GIT_COMMIT="$APP_GIT_COMMIT"
export SETTINGS__BUILD_DATE="$APP_BUILD_DATE"
export SETTINGS__GIT_SOURCE="$APP_BUILD_TAG"

mkdir -p log

set -ex

rails db:setup
rails db:migrate
rails db:seed

# load pseudo users
rake db:reseed