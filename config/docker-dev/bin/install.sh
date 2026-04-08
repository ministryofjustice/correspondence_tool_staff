#!/bin/sh

DIRECTORY="./config/docker-dev"
FILENAME="$DIRECTORY/.setup-complete"

# this block forces one-time setup on entry and a reinstall if environment changes
if [ ! -f "$FILENAME" ] || [ "$RAILS_ENV" != "$(cat $FILENAME)" ]; then
  printf '\e[33mINFO: Beginning a fresh install\e[0m\n'
  /usr/bin/entrypoint.sh

  # create a control file
  # at minimum, this file is referenced in .gitignore and Makefile
  echo "$RAILS_ENV" > "$FILENAME"
fi

