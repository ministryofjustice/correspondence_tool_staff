#!/bin/sh
set +ex

bundle exec sidekiq -C config/sidekiq-anonymizer-jobs.yml
