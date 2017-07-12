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
require 'cts/policies'

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

    def error(statement)
      $stderr.puts statement
    end

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
        teams = Team.all.detect { |t| t.name.match(team_name_regex) }
        if teams.empty?
          raise "No team matching name #{id_or_name} found."
        elsif teams.count > 1
          error "Multiple teams found matching #{id_or_name}"
          teams.each { |t| error "  #{t.name}" }
          raise "Multiple teams found matching #{id_or_name}"
        end
        teams.first
      else
        Team.find_by! name: id_or_name
      end
    end

    def find_user(id_or_name)
      if id_or_name.match %r{^\d+$}
        User.find id_or_name
      elsif id_or_name.match %r{^/(.*)/$}
        user_name_regex = Reger.new(Regex.last_match, Regex::IGNORECASE)
        users = User.all.detect { |t| t.full_name.match(user_name_regex) }
        if users.empty?
          raise "No user matching name #{id_or_name} found."
        elsif users.count > 1
          error "Multiple users found matching #{id_or_name}."
          users.each { |u| error "  #{u.name}" }
          raise "Multiple users found matching #{id_or_name}."
        end
        users.first
      else
        User.find_by! full_name: id_or_name
      end
    end

    def find_case(id_or_number)
      Case.where(['id = ? or number = ?', id_or_number, id_or_number]).first or
        raise "No case found matching id or number '#{id_or_number}'."
    end

    def validate_teams_populated
      dacu_team
      dacu_disclosure_team
      press_office_team
      private_office_team
      hmcts_team
      hr_team
      laa_team
    rescue => err
      error err.message
      error "Run 'cts teams seed' to populate teams, or use 'rake db:seed:dev:users' for the whole shebang"
      error err.backtrace.join("\n\t")
      exit 2
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def validate_users_populated
      begin
        dacu_team.managers.first || raise("DACU BMT missing users")
        dacu_disclosure_team.approvers.first || raise("DACU Disclosure missing users")
        hmcts_team.responders.first || raise("HMCTS missing users")
        hr_team.responders.first || raise("HR missing users")
        press_office_team.approvers.first || raise("Press Office missing users")
        private_office_team.approvers.first || raise("Private Office missing users")
      rescue => ex
        error "Error validating users:"
        error ex.message
        error "Run 'cts users seed' to populate users, or use 'rake db:seed:dev:users' for the whole shebang"
        error ex.backtrace.join("\n\t")

        exit 3
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def dacu_manager
      @dacu_manager ||= if dacu_team.managers.blank?
                          raise 'DACU team has no managers assigned.'
                        else
                          dacu_team.managers.first
                        end
    end

    def dacu_disclosure_approver
      @dacu_disclosure_approver ||=
        if dacu_disclosure_team.approvers.blank?
          raise 'DACU Disclosure team has no approvers assigned.'
        else
          dacu_disclosure_team.approvers.first
        end
    end

    def press_office_approver
      @press_office_approver ||=
        if press_office_team.approvers.blank?
          raise 'Press Office team has no approvers assigned.'
        else
          press_office_team.approvers.first
        end
    end

    def private_office_approver
      @private_office_approver ||=
          if private_office_team.approvers.blank?
            raise 'Private Office team has no approvers assigned.'
          else
            private_office_team.approvers.first
          end
    end

    def dacu_team
      @dacu_team ||= CTS::find_team 'DACU'
    end

    def dacu_disclosure_team
      @dacu_disclosure_team ||=
        CTS::find_team Settings.foi_cases.default_clearance_team
    end

    def press_office_team
      @press_office_team ||= CTS::find_team Settings.press_office_team_name
    end

    def private_office_team
      @private_office_team ||= CTS::find_team Settings.private_office_team_name
    end

    def hmcts_team
      @hmcts_team ||=
        CTS::find_team 'HMCTS North East Response Unit(RSU)'
    end

    def laa_team
      @laa_team ||= CTS::find_team 'Legal Aid Agency'
    end

    def hr_team
      @hr_team ||= CTS::find_team 'HR'
    end
  end

  class Commands < Thor
    include Thor::Rails unless SKIP_RAILS

    desc 'cases', 'Case commands'
    subcommand 'cases', Cases

    desc 'policies', 'Policy related commands'
    subcommand 'policies', Policies

    desc 'teams', 'Team commands'
    subcommand 'teams', Teams

    desc 'users', 'User commands'
    subcommand 'users', Users

    desc 'validate_data', 'Validate team and user data in DB.'
    def validate_data
      CTS::validate_teams_populated
      CTS::validate_users_populated
      puts "Looks good."
    end
  end
end

CTS::Commands.start(ARGV)
