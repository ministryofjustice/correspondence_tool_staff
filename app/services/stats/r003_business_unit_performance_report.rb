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
                          :responded_transitions).standard_foi
    end

    def report_type
      ReportType.r003
    end
  end
end
