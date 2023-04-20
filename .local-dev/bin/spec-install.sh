#!/bin/bash

. functions.sh

# this block checks for the rspec-rails gem and forces one-time setup if not present
if ! bundle show rspec-core 2>/dev/null; then
  sub_header "${YELLOW}Onetime setup initiated${NC}"
  # shellcheck source=/dev/null
  source ~/.bashrc

  GECKO_DRIVER_FILENAME="geckodriver-$GECKO_DRIVER_VERSION-linux64.tar"

  if [ "$(arch | sed s/aarch64/arm64/)" == 'arm64' ]; then
      # fix for Nokogiri on arm64; helps to install platform agnostic/non-specific gems
      bundle config set force_ruby_platform true
      GECKO_DRIVER_FILENAME="geckodriver-$GECKO_DRIVER_VERSION-linux-aarch64.tar"
  fi

  sub_header_divider "${YELLOW}Installing Gems${NC}"
  # install gems under current user
  bundler install | indent

  sub_header_divider "${YELLOW}Preparing database for testing${NC}"
  bundle exec rake db:setup | indent

  sub_header_divider "${YELLOW}Storing environment value in DB${NC}"
  bin/rails db:environment:set RAILS_ENV=test
  echo "Done." | indent

  sub_header_divider "${YELLOW}Setting up parallel testing${NC}"
  bundle exec rails parallel:create | indent

  sub_header_divider "${YELLOW}Loading DB schema across multiple test databases${NC}"
  bundle exec rails parallel:load_schema | indent

  sub_header_divider "${YELLOW}Attempting to update webdriver version${NC}"
  # geckodriver download URL
  URL="https://github.com/mozilla/geckodriver/releases/download/$GECKO_DRIVER_VERSION/$GECKO_DRIVER_FILENAME.gz"
  (cd /usr/local/bin && curl -O -L "$URL" && gunzip "$GECKO_DRIVER_FILENAME.gz" && mv "$GECKO_DRIVER_FILENAME" geckodriver && chmod +x geckodriver)

  sub_header "${GREEN}Installation complete! Use ${YELLOW}rspec ${GREEN}like ${NC} bundle exec rspec [spec/path/to/_spec.rb][:line-number]\n\n${DARK_GRAY}******     ${GREEN}Or, use ${YELLOW}parallel testing${GREEN} like${NC} bundle exec rails parallel:spec"

  exit;
fi

sub_header "${GREEN}Ready to play? Use ${YELLOW}rspec ${GREEN}like ${NC} bundle exec rspec [spec/path/to/_spec.rb][:line-number]"
