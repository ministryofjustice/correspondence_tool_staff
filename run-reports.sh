#!/bin/bash

bundle exec sidekiq -C config/sidekiq-reports.yml
