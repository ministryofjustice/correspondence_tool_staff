require "cts"

module CTS::Teams
  class RolesSeeder
    attr_reader :options

    def initialize(options = {})
      @options = options
    end

    def run
      max_name_length = BusinessUnit.pick("max(length(name))")
      BusinessUnit.all.each do |bu|
        if bu.role.present?
          puts sprintf("%#{max_name_length}s: skipping, role exists: #{bu.role}", bu.name)
          next
        end

        role = case bu.name
               when Settings.foi_cases.default_managing_team
                 "manager"
               when Settings.foi_cases.default_clearance_team,
                    Settings.press_office_team_name,
                    Settings.private_office_team_name
                 "approver"
               else
                 "responder"
               end
        puts sprintf("%#{max_name_length}s: setting role to #{role}", bu.name)
        unless options[:dry_run]
          bu.role = role
        end
      end
    end
  end
end
