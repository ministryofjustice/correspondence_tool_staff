module CTS
  class Users < Thor
    include Thor::Rails unless SKIP_RAILS

    desc "list", "List users in the system."
    option :all, aliases: :a
    def list
      columns = if options[:all]
                  []
                else
                  [
                    :id,
                    :full_name,
                    :email,
                    { teams: lambda do |u|
                      u.team_roles.map { |tr| "#{tr.team&.name}:#{tr.role}" }.join " "
                    end },
                  ]
                end
      tp.set :max_width, 80
      tp User.all, *columns
    end

    default_command :list

    desc "seed", "Seed users for dev/demo."
    def seed
      CTS.validate_teams_populated

      require "#{CTS_ROOT_DIR}/db/seeders/dev_user_seeder"
      seeder = DevUserSeeder.new
      seeder.seed!
    end
  end
end
