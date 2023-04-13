#!/bin/sh

# this block forces one-time setup on entry and a reinstall if environment changes
if [ ! -f .local-dev/.setup-complete ] || [ "$RAILS_ENV" != "$(cat .local-dev/.setup-complete)" ]; then
  printf '\e[33mINFO: Beginning a fresh install\e[0m\n'
  /usr/bin/entrypoint.sh

  # create a control file
  # at minimum, this file is referenced in .gitignore and Makefile
  echo "$RAILS_ENV" > .local-dev/.setup-complete
fi

