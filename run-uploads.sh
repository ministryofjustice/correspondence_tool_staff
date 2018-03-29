#!/bin/bash

bundle exec sidekiq -C config/sidekiq-uploads.yml
