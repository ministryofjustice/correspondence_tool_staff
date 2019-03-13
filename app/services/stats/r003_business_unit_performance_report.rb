module Stats
  class R003BusinessUnitPerformanceReport < BaseBusinessUnitPerformanceReport

    def self.title
      'Business unit report (FOIs)'
    end

    def self.description
      'Shows all FOI open cases and cases closed this month, in-time or late, by responding team'
    end

    def case_scope
      Case::Base.includes(:assign_responder_transitions,
                          :responded_transitions,
                          # TODO - adding eager load of these 2 associations results in a crash...
                          # test in spec/models/scope_spec.rb
                          # :responder_assignment,
                          # :responding_team,
                          ).standard_foi
    end

    def report_type
      ReportType.r003
    end
  end
end
