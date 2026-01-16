#!/bin/bash

# colours
GREEN='\033[0;32m'
GREEN_BOLD='\033[1;32m'
YELLOW='\033[0;93m'
DARK_GRAY='\033[3;90m'
LIGHT_BLUE='\033[1;34m'
NC='\033[0m' # No Color

CAN_RUN="false"
if [[ "$OSTYPE" == "darwin"* ]]; then
  CAN_RUN="true" # MacOS
fi

UTILITY_TITLE="${YELLOW}C T   S T A F F  ${DARK_GRAY}/  ${GREEN}D E V E L O P M E N T   E N V I R O N M E N T"

## a full width line of stars
FULL_WIDTH_STARS="*"
for ((i = 1; i < $(tput cols); i++)); do FULL_WIDTH_STARS="$FULL_WIDTH_STARS*"; done
####

header() {
  echo -e "\n${DARK_GRAY}$FULL_WIDTH_STARS${NC}\n"
  echo -e "${DARK_GRAY}******     ${GREEN}$UTILITY_TITLE${NC}\n"
  echo -e "${DARK_GRAY}******     ${NC}$1\n"
}

header_additional() {
  echo -e "$1" | indent

  if [[ -n "$2" ]]; then
    header_close
  fi
}

header_close() {
  echo -e "\n${DARK_GRAY}$FULL_WIDTH_STARS${NC}\n"
}

sub_header() {
  echo -e "${DARK_GRAY}******    ${NC} $1\n"
  echo -e "${DARK_GRAY}$FULL_WIDTH_STARS${NC}\n"
}

sub_header_divider() {
  echo -e "\n---\n${GREEN}***${NC}   $1\n"
}

indent() {
  sed 's/^/           /'
}
