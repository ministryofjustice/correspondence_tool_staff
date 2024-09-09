#!/bin/sh
set +ex

bundle exec sidekiq -C config/sidekiq-warehouse-jobs.yml
