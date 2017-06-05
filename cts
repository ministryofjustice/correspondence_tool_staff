#!/usr/bin/env ruby

if defined?(Rails) || ARGV.include?('-h') || ARGV.include?('--help')
  SKIP_RAILS=true
else
  root_dir = File.dirname($0)
  exec(File.join(root_dir, 'bin', 'rails'), 'runner', $0, *ARGV)
end

require 'thor'

$: << 'lib'
require 'cts/cases'
require 'cts/teams'
require 'cts/users'

module CTS
  class << self
    def check_environment
      environment = if ::Rails.env.production?
                      ENV.fetch('ENV', Rails.env)
                    else
                      Rails.env
                    end
      if environment == 'prod' || environment == 'production'
        STDERR.puts "Environment '#{environment}' detected. Run cts in non-prod environments only!"
        exit 1
      end
    end
  end

  class Commands < Thor
    include Thor::Rails unless SKIP_RAILS

    desc 'cases', 'Case commands'
    subcommand 'cases', Cases

    desc 'teams', 'Team commands'
    subcommand 'teams', Teams

    desc 'users', 'User commands'
    subcommand 'users', Users
  end

end

CTS::Commands.start(ARGV)
