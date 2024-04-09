require "cts/cli"
require "cts/cases/cli"
require "cts/policies"
require "cts/teams/cli"
require "cts/users"

class CTS::Cli < Thor
  include Thor::Rails unless SKIP_RAILS

  desc "cases", "Case commands"
  subcommand "cases", CTS::Cases::Cli

  desc "policies", "Policy related commands"
  subcommand "policies", CTS::Policies

  desc "teams", "Team commands"
  subcommand "teams", CTS::Teams::Cli

  desc "users", "User commands"
  subcommand "users", CTS::Users

  desc "validate_data", "Validate team and user data in DB."
  def validate_data
    CTS.validate_teams_populated
    CTS.validate_users_populated
    puts "Looks good."
  end
end
