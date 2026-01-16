#!/bin/bash

. ./config/docker-dev/bin/functions.sh

header "Application Endpoints"
header_additional "${GREEN}Website:${NC} http://localhost:3000"
header_additional "${GREEN}PGAdmin:${NC} http://localhost:5050"
header_close
