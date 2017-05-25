#!/usr/bin/env ruby

require 'thor'
require 'thor/rails'

$: << 'lib'
require 'cts/teams'
require 'cts/users'
require File.join(File.dirname(__FILE__), 'db', 'seeders', 'case_seeder')


module CTS
  class Commands < Thor
    include Thor::Rails

    desc 'cases', 'Case commands'
    subcommand 'cases', CaseSeeder

    desc 'teams', 'Team commands'
    subcommand 'teams', Teams

    desc 'users', 'User commands'
    subcommand 'users', Users
  end

end

CTS::Commands.start(ARGV)
