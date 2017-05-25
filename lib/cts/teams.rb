module CTS
  class Teams < Thor
    include Thor::Rails

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
  end
end
