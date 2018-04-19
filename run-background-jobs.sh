#!/bin/bash

bundle exec sidekiq -C config/sidekiq-background-jobs.yml
