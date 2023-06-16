module CTS
  class << self
    def info(statement)
      $stdout.puts statement
    end

    def error(statement)
      warn statement
    end

    def check_environment
      environment = if ::Rails.env.production?
                      ENV.fetch("ENV", Rails.env)
                    else
                      Rails.env
                    end
      if %w[prod production].include?(environment)
        warn "Environment '#{environment}' detected. Run cts in non-prod environments only!"
        exit 1
      end
    end

    def find_team(id_or_name)
      teams = find_teams(id_or_name)
      if teams.empty? || teams.first.nil?
        raise "No team matching name #{id_or_name} found."
      elsif teams.count > 1
        error "Multiple teams found matching #{id_or_name}"
        teams.each { |t| error "  #{t.name}" }
        raise "Multiple teams found matching #{id_or_name}"
      end

      teams.first
    end

    def find_teams(id_or_name)
      case id_or_name
      when %r{^\d+$}
        [BusinessUnit.find(id_or_name)]
      when %r{^/(.*)/$}
        team_name_regex = Regexp.new(Regexp.last_match(1), Regexp::IGNORECASE)
        BusinessUnit.all.find_all { |t| t.name.match(team_name_regex) }
      else
        BusinessUnit.where("name = ? OR code = ?", id_or_name, id_or_name)
      end
    end

    def find_user(id_or_name)
      users = find_users(id_or_name)
      if users.empty? || users.first.nil?
        raise "No user matching name #{id_or_name} found."
      elsif users.count > 1
        error "Multiple users found matching #{id_or_name}."
        users.each { |u| error "  #{u.name}" }
        raise "Multiple users found matching #{id_or_name}."
      end

      users.first
    end

    def find_users(id_or_name)
      case id_or_name
      when %r{^\d+$}
        [User.find(id_or_name)]
      when %r{^/(.*)/$}
        user_name_regex = Regexp.new(Regexp.last_match(1), Regexp::IGNORECASE)
        User.all.find_all { |t| t.full_name.match(user_name_regex) }
      else
        [User.find_by!(full_name: id_or_name)]
      end
    end

    def find_case(id_or_number)
      Case::Base.where(["id = ? or number = ?", id_or_number, id_or_number]).first or
        raise "No case found matching id or number '#{id_or_number}'."
    end

    def validate_teams_populated
      dacu_team
      dacu_disclosure_team
      press_office_team
      private_office_team
      hmcts_team
      hr_team
      laa_team
    rescue StandardError => e
      error e.message
      error "Run 'cts teams seed' to populate teams"
      error e.backtrace.join("\n\t")
      exit 2
    end

    def validate_users_populated
      dacu_team.managers.first || raise("DACU BMT missing users")
      dacu_disclosure_team.approvers.first || raise("DACU Disclosure missing users")
      hmcts_team.responders.first || raise("HMCTS missing users")
      hr_team.responders.first || raise("HR missing users")
      press_office_team.approvers.first || raise("Press Office missing users")
      private_office_team.approvers.first || raise("Private Office missing users")
    rescue StandardError => e
      error "Error validating users:"
      error e.message
      error "Run 'cts users seed' to populate users"
      error e.backtrace.join("\n\t")

      exit 3
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def dacu_manager
      @dacu_manager ||= if dacu_team.managers.blank?
                          raise "DACU team has no managers assigned."
                        else
                          dacu_team.managers.first
                        end
    end

    def dacu_disclosure_approver
      @dacu_disclosure_approver ||=
        if dacu_disclosure_team.approvers.blank?
          raise "DACU Disclosure team has no approvers assigned."
        else
          dacu_disclosure_team.approvers.last
        end
    end

    def press_officer
      @press_officer ||=
        if press_office_team.approvers.blank?
          raise "Press Office team has no approvers assigned."
        else
          press_office_team.approvers.first
        end
    end

    def private_officer
      @private_officer ||=
        if private_office_team.approvers.blank?
          raise "Private Office team has no approvers assigned."
        else
          private_office_team.approvers.first
        end
    end

    def dacu_team
      @dacu_team ||= CTS.find_team Settings.foi_cases.default_managing_team
    end

    def dacu_disclosure_team
      @dacu_disclosure_team ||=
        CTS.find_team Settings.foi_cases.default_clearance_team
    end

    def press_office_team
      @press_office_team ||= CTS.find_team Settings.press_office_team_name
    end

    def private_office_team
      @private_office_team ||= CTS.find_team Settings.private_office_team_name
    end

    def hmcts_team
      @hmcts_team ||=
        CTS.find_team "North East Regional Support Unit (NE RSU)"
    end

    def laa_team
      @laa_team ||= CTS.find_team "Legal Aid Agency (LAA)"
    end

    def hr_team
      @hr_team ||= CTS.find_team "MoJ Human Resources (MoJ HR)"
    end
  end
end
