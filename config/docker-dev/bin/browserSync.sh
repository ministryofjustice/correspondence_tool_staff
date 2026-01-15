#!/bin/sh

# Optional BrowserSync integration for Rails.
# This script will only run if explicitly enabled and if the supporting gem is present.
# To enable, set BROWSER_SYNC_ENABLED=true in your environment.

if [ "${BROWSER_SYNC_ENABLED}" != "true" ]; then
  printf '\e[33mBrowserSync disabled (set BROWSER_SYNC_ENABLED=true to enable). Skipping.\e[0m\n'
  exit 0
fi

# Ensure the browser_sync_rails gem is installed in the bundle
if ! bundle show browser_sync_rails >/dev/null 2>&1; then
  printf '\e[33mBrowserSync gem (browser_sync_rails) not found in bundle. Skipping.\e[0m\n'
  exit 0
fi

# Try to run the installer (idempotent or ignore errors if already installed)
bundle exec rails generate browser_sync_rails:install || true

# Start BrowserSync (if the command is available)
if bundle exec rails help 2>/dev/null | grep -q "browser_sync:start"; then
  bundle exec rails browser_sync:start
else
  printf '\e[33mRails task browser_sync:start not found. Skipping.\e[0m\n'
fi
