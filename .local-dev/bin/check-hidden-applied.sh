#!/bin/bash

grep -Fxq ".local-dev" .gitignore
if [[ $? == "1" ]]; then
  echo 'Dockerized files NOT hidden from Git. Writing rules...'
  {
    echo ''
    echo "# TEMP - docker environment files"
    echo '.local-dev'
    echo 'cts-dev*'
    echo 'docker-*'
    echo 'Makefile'
    echo 'README.docker.md'
  } >>.gitignore
  echo 'Done.'
else
  echo 'Dockerized files are hidden from Git'
fi
