#!/bin/bash

. ./config/docker-dev/bin/functions.sh

header "Checking Docker Engine..."
sleep 3

## Check if our script is compatible on MacOS
if [[ "$CAN_RUN" != "true" ]]; then
  header_additional "${GREEN}Wait!${NC} This installation of Docker Compose requires MacOS."
  header_additional "Please consider contributing to the project to add support for your platform. Bye." "close"
  exit 1
fi

## Check if Docker is installed
if ! docker --version >/dev/null 2>&1; then
  header_additional "${GREEN}Hang on!${NC} Docker Compose requires the Docker engine. Please install Docker Desktop."
  header_additional "Find installation guidance at: https://docs.docker.com/desktop/install/" "close"
  exit 1
fi

## Check if Docker is running
if ! docker info >/dev/null 2>&1; then
  header_additional "${GREEN}Oops!${NC} Docker isn't running. We will need this."
  header_additional "${YELLOW}Starting...${NC}"

  if ! open -a Docker >/dev/null 2>&1; then
    header_additional "${YELLOW}Sorry!${NC} We couldn't start Docker Desktop. Please start it manually and try again."
    exit 1
  else
    header_additional "${YELLOW}Docker Desktop started!${NC} Please wait a few moments for it to initialize..."
    sleep 10 # wait for Docker to start
  fi
fi

header_additional "${GREEN}Done.${NC} We are good to go!" "close"

