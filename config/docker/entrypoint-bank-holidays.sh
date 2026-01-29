#!/bin/sh
set +ex

bundle exec rake bank_holidays:run
