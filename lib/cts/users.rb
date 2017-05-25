module CTS
  class Users < Thor
    include Thor::Rails

    desc 'list', 'List users in the system.'
    option :all, aliases: :a
    def list
      if options[:all]
        columns = []
      else
        columns = [
          :id,
          :full_name,
          :email,
          teams: -> (u) { u.team_roles.map { |tr| "#{tr.team.name}:#{tr.role}" }.join ' ' }
        ]
      end
      tp.set :max_width, 80
      tp User.all, *columns
    end

    default_command :list
  end
end
