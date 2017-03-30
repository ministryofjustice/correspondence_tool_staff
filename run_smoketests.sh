#!/bin/bash

# this script runs the smoke test, and it expects to have three environment variables set:

#  - TEST_SITE_URL        The base url of the site to connect to (e.g. http://localhost:3000, https://track-a-query-staging.dsd.io)
#  - TEST_USER_EMAIL      The email address of a user to login as
#  - TEST_USER_PASSWORD   The password to use when logging in

# on localhost in a development environment, the command will look like this:
#
# TEST_SITE_URL=http://localhost:3000 TEST_USER_EMAIL=correspondence-staff-dev+ass.igner@digital.justice.gov.uk TEST_USER_PASSWORD=12345678 ./run_smoketests.sh
#

# Even though we are running in a production environment, the smoke
# test has gem dependencies we prefer to keep in the test environment
# (e.g. mechanize and mail gems).
export RAILS_ENV=test

# By default we only install production gems in our Docker containers,
# and Bundler conspires to help & frustrate us by remembering that.
bundle install --with=test

# For some reason the she-bang line in smoketest.rb runs:
#   /usr/bin/env "rails runner"
# instead of:
#   /usr/bin/env "rails" "runner"
# bizarro. Version of env? bash?
rails runner ./smoketest.rb $TEST_SITE_URL $TEST_USER_EMAIL $TEST_USER_PASSWORD

exit $?
