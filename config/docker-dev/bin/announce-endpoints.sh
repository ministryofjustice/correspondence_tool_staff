#!/bin/bash

. ./config/docker-dev/bin/functions.sh

header "Application Endpoints"
header_additional "${GREEN}Website:     ${NC} http://localhost:3000"
header_additional "${GREEN}PGAdmin (DB):${NC} http://localhost:5050 \n"
header_additional "${GREEN}App terminal: ${YELLOW}make shell${NC}" "close"

