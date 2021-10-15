#!/bin/sh
set +ex

bundle exec sidekiq -C config/sidekiq-quick-jobs.yml
