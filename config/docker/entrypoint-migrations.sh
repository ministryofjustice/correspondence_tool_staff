#!/bin/sh
set +ex

bundle exec rails db:migrate
bundle exec rails data:migrate
