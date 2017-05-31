#!/usr/bin/env ruby

require 'thor'
require 'thor/rails'

$: << 'lib'
require 'cts/cases'
require 'cts/teams'
require 'cts/users'


module CTS
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
