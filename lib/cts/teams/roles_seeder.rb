module CTS
  class Teams
    class RolesSeeder
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def run
        max_name_length = BusinessUnit.pluck('max(length(name))').first
        BusinessUnit.all.each do |bu|
          if bu.role.present?
            puts "%#{max_name_length}s: skipping, role exists: #{bu.role}" % [bu.name]
            next
          end

          role = case bu.name
                 when 'DACU BMT'
                   'manager'
                 when 'DACU Disclosure', 'Press Office', 'Private Office'
                   'approver'
                 else
                   'responder'
                 end
          puts "%#{max_name_length}s: setting role to #{role}" % [bu.name]
          unless options[:dry_run]
            bu.role = role
          end
        end
      end
    end
  end
end
