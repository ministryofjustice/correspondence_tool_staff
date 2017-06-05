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
        columns = [:id, :name, :email]
      end
      tp Team.all, *columns
    end

    default_command :list

    desc 'seed', 'Seed teams for dev/demo.'
    def seed
      require "#{CTS_ROOT_DIR}/db/seeders/demo_user_seeder"
      seeder = DemoUserSeeder.new
      seeder.seed_teams
    end
  end
end
