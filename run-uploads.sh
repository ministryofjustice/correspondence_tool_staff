#!/bin/bash

service clamav-daemon start
service clamav-freshclam start

bundle exec sidekiq -C config/sidekiq-uploads.yml
