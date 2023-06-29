require "cts"

module CTS::Cases
  class Show
    def call(kase)
      ap kase

      puts "\nAssignments:"
      show_case_assignments(kase)

      puts "\nTransitions:"
      show_case_transitions(kase)

      puts "\nAttachments:"
      tp kase.attachments, %i[id type key preview_key]
    end

  private

    def show_case_assignments(kase)
      team_display = team_display_method :team
      team_width = kase.assignments.map(&team_display).map(&:length).max
      user_display = user_display_method :user
      user_width = kase.assignments.map(&user_display).map(&:length).max
      tp kase.assignments, :id, :state, :role,
         { user: { display_method: user_display, width: user_width } },
         { team: { display_method: team_display, width: team_width } }
    end

    def show_case_transitions(kase)
      transition_display_fields =
        [
          [:acting_team, team_display_method(:acting_team)],
          [:acting_user, user_display_method(:acting_user)],
          # [:target_team, team_display_method(:target_team)],
          # [:target_user, user_display_method(:target_user)],
        ].map do |field, display_method|
          max_width = longest_field(kase.transitions, &display_method)
          {
            field => {
              display_method:,
              width: max_width,
            },
          }
        end
      tp kase.transitions.order(:id),
         :id,
         :event,
         :to_state,
         transition_display_fields
    end

    def longest_field(objects, &display_method)
      objects.map(&display_method).map(&:length).max
    end

    def user_display_method(attr)
      lambda do |o|
        user = o.send attr
        if user
          "#{user&.full_name}:#{user&.id}"
        else
          ""
        end
      end
    end

    def team_display_method(attr)
      lambda do |object|
        team = object.send attr
        if team
          "#{team&.name}:#{team&.id}"
        else
          ""
        end
      end
    end
  end
end
