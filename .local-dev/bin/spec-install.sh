#!/bin/bash

. functions.sh

# this block checks for the rspec-rails gem and forces one-time setup if not present
if ! bundle show rspec-core 2>/dev/null; then
  sub_header "${YELLOW}Onetime setup initiated${NC}"
  # shellcheck source=/dev/null
  source ~/.bashrc

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

  sub_header_divider "${YELLOW}Attempting to update webdriver version for chrome${NC}"
  bin/rails webdrivers:chromedriver:update | indent

  sub_header "${GREEN}Installation complete! Use ${DARK_GRAY}rspec ${GREEN}like ${NC} bundle exec rspec [spec/path/to/_spec.rb][:line-number]\n\n${DARK_GRAY}******     ${GREEN}Or, use ${DARK_GRAY} parallel testing${GREEN} like${NC} bundle exec rails parallel:spec"

  exit;
fi

sub_header "${GREEN}Ready to play? Use ${DARK_GRAY}rspec ${GREEN}like ${NC} bundle exec rspec [spec/path/to/_spec.rb][:line-number]"
