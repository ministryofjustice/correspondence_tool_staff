module CTS
  class Teams < Thor
    include Thor::Rails unless SKIP_RAILS

    desc 'list', 'List teams in the system.'
    option :all, aliases: :a
    def list
      say ::Rails.env
      if options[:all]
        columns = []
      else
        columns = [
          :id,
          :type,
          :name,
          :email,
          {role: {
             display_method: ->(t) {
               t.class == BusinessUnit ? t.role.value : '-'
             }
           } }
        ]
      end
      tp Team.all, *columns
    end

    default_command :list

    desc 'seed', 'Seed teams for dev/demo.'
    def seed
      require "#{CTS_ROOT_DIR}/db/seeders/dev_user_seeder"
      CTS::check_enviroment
      seeder = DevUserSeeder.new
      seeder.seed_teams
    end

    desc 'seed_roles', 'Seed business unit roles.'
    option :force, aliases: :f, type: :boolean,
           desc: 'Force running in prod environment'
    option :dry_run, aliases: :n, type: :boolean,
           desc: 'Print what would be done, don\'t change anything.'
    def seed_roles
      unless options[:force]
        CTS::check_environment
      end
      rs = RolesSeeder.new(options)
      rs.run
    end

    desc 'show', 'Show team details.'
    def show(*args)
      args.each do |team_identifier|
        team = CTS::find_team(team_identifier)
        ap team
        puts "\nUsers:"
        tp team.user_roles,
           {user_id: { display_name: :id}},
           {'user.full_name' => { display_name: :full_name}},
           :role
      end
    end
  end
end
