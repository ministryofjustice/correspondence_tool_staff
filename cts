#!/usr/bin/env ruby

CTS_ROOT_DIR = File.dirname($0)

if defined?(Rails) || ARGV.include?('-h') || ARGV.include?('--help')
  SKIP_RAILS=true
else
  exec(File.join(CTS_ROOT_DIR, 'bin', 'rails'), 'runner', $0, *ARGV)
end

require 'thor'

$: << 'lib'
require 'cts/cases'
require 'cts/teams'
require 'cts/users'

class Thor
  module Shell
    class Basic
      def print_wrapped(message, _options = {})
        stdout.puts message
      end
    end
  end
end

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

    def find_team(id_or_name)
      if id_or_name.match %r{^\d+$}
        Team.find id_or_name
      elsif id_or_name.match %r{^/(.*)/$}
        team_name_regex = Reger.new(Regex.last_match)
        Team.all.detect { |t| t.name.match(team_name_regex) } or
          raise "No team matching name #{id_or_name} found."
      else
        Team.find_by! name: id_or_name
      end
    end


    def find_user(id_or_name)
      if id_or_name.match %r{^\d+$}
        User.find id_or_name
      elsif id_or_name.match %r{^/(.*)/$}
        user_name_regex = Reger.new(Regex.last_match)
        User.all.detect { |t| t.full_name.match(user_name_regex) } 
          raise "No user matching name #{id_or_name} found."
      else
        User.find_by! full_name: id_or_name
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

    desc 'validate_data', 'Validate team and user data in DB.'
    def validate_data
      validate_teams_populated
      validate_users_populated
      puts "Looks good."
    end

    private

    def validate_teams_populated
      @dacu_team, @disclosure_team, @hmcts_team, @hr_team, @laa_team = ['DACU', 'DACU Disclosure', 'Legal Aid Agency', 'HR', 'HMCTS North East Response Unit(RSU)'].map do |team_name|
        teams = Team.where(name: team_name)
        if teams.count > 1
          error "ERROR: multiple entries found for team: #{team_name}"
          exit 2
        elsif teams.count == 0
          error "ERROR: team missing: #{team_name}"
          error "Run 'cts teams seed' to populate teams, or use 'rake db:seed:dev:users' for the whole shebang"
          exit 2
        else
          teams.first
        end
      end
    end

    def validate_users_populated
      begin
        @dacu_manager = @dacu_team.managers.first ||
                        raise("DACU BMT missing users")
        @disclosure_approver = @disclosure_team.approvers.first ||
                               raise("DACU Disclosure missing users")
        @hmcts_responder = @hmcts_team.responders.first ||
                           raise("HMCTS missing users")
      rescue => ex
        error "Error validating users:"
        error ex.message
        error "Run 'cts users seed' to populate users, or use 'rake db:seed:dev:users' for the whole shebang"
        exit 3
      end
    end

  end
end

CTS::Commands.start(ARGV)
