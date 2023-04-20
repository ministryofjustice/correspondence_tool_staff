#!/bin/bash

# Search for the Dory Proxy container
DORY_RUNNING=$(docker ps | grep dory_dnsmasq)

# If an output is available in the DORY_RUNNING var, we're good. Otherwise, try and start the proxy server
if [[ -z "$DORY_RUNNING" ]]; then
  if command -v dory &>/dev/null; then
    dory up
  else
    printf "\nThe Dory Proxy is used in this project. You may install it using homebrew.\n\n"
    while true; do
      read -r -p "$(echo -e "${GREEN}Would you like to install Dory using homebrew now? ${NC}" | indent)" yn
      case $yn in
      [Yy]*)
        echo -e "\nRunning ${YELLOW}brew install dory${NC}. This may take a few minutes...\n" | indent
        brew install dory | indent
        echo -e "\n${YELLOW}Installation complete.${NC} Starting Dory...\n" | indent
        dory up | indent
        echo -e "\n\n"
        break
        ;;
      [Nn]*)
        echo -e "\n${YELLOW}Shame${NC}. Continuing without Dory...\n\n"
        break
        ;;
      *) echo "Please answer yes or no." | indent ;;
      esac
    done
  fi
else
  dory restart dnsmasq
fi
