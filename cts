#!/usr/bin/env ruby

require 'thor'
require 'thor/rails'

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
    include Thor::Rails

    desc 'cases', 'Case commands'
    subcommand 'cases', Cases

    desc 'teams', 'Team commands'
    subcommand 'teams', Teams

    desc 'users', 'User commands'
    subcommand 'users', Users
  end

end

CTS::Commands.start(ARGV)
