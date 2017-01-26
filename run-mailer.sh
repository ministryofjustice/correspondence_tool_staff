#!/bin/bash

bundle exec sidekiq -C config/sidekiq-mailer.yml
