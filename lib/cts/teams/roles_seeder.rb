module CTS
  class Teams
    class RolesSeeder
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def run
        BusinessUnit.all.each do |bu|
          if bu.role.present?
            puts "#{bu.name}: skipping, role exists: #{bu.role}"
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
          puts "#{bu.name}: setting role to #{role}"
          unless options[:dry_run]
            bu.properties << TeamProperty.create!(key: 'role', value: role)
          end
        end
      end
    end
  end
end
