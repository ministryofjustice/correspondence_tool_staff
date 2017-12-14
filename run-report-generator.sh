#!/bin/bash

bundle exec sidekiq -C config/sidekiq-report-generator.yml
