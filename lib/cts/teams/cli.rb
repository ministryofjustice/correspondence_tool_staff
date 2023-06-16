require "cts"

module CTS::Teams
  class CLI < Thor
    include Thor::Rails unless SKIP_RAILS

    desc "list", "List teams in the system."
    option :all, aliases: :a
    def list
      say ::Rails.env
      columns = if options[:all]
                  []
                else
                  [
                    :id,
                    :type,
                    :name,
                    :email,
                    { role: {
                      display_method: lambda { |t|
                        t.instance_of?(BusinessUnit) ? t.role : "-"
                      },
                    } },
                  ]
                end
      tp Team.all, *columns
    end

    default_command :list

    desc "seed", "Seed teams for dev/demo."
    def seed
      require "#{CTS_ROOT_DIR}/db/seeders/dev_team_seeder"
      CTS.check_environment
      seeder = DevTeamSeeder.new
      seeder.seed!
    end

    desc "seed_roles", "Seed business unit roles."
    option :force, aliases: :f, type: :boolean,
                   desc: "Force running in prod environment"
    option :dry_run, aliases: :n, type: :boolean,
                     desc: "Print what would be done, don't change anything."
    def seed_roles
      unless options[:force]
        CTS.check_environment
      end
      rs = RolesSeeder.new(options)
      rs.run
    end

    desc "show", "Show team details."
    def show(*args)
      args.each do |team_identifier|
        team = CTS.find_team(team_identifier)
        ap team
        puts "\nUsers:"
        tp team.user_roles,
           { user_id: { display_name: :id } },
           { "user.full_name" => { display_name: :full_name } },
           :role
      end
    end

    desc "role TEAM [TEAM ...]", "View or set team role."
    option :role, aliases: :r, type: :string,
                  enum: %w[manager responder approver],
                  desc: "Set the team(s) role(s) to this value."
    option :delete, aliases: :d, type: :boolean,
                    desc: "Delete the team(s) role(s)."
    option :force, aliases: :f, type: :boolean,
                   desc: "Force running, even if in prod env."
    def role(*args)
      teams = args.map { |a| CTS.find_team(a) }
      max_name_length = teams.pick("max(length(name))")
      if options[:role]
        CTS.check_environment unless options[:force]
        teams.each do |bu|
          puts sprintf("%#{max_name_length}s: setting role to: #{options[:role]}", bu.name)
          bu.role = options[:role]
        end
      elsif options[:delete]
        CTS.check_environment unless options[:force]
        teams.each do |bu|
          puts sprintf("%#{max_name_length}s: deleting role: #{bu.role}", bu.name)
          bu.properties.role.first.delete
        end
      else
        teams.each do |bu|
          puts sprintf("%#{max_name_length}s: role is: #{bu.role}", bu.name)
        end
      end
    end
  end
end
