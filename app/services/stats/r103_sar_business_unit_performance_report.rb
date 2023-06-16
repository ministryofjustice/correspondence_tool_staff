module Stats
  class R103SarBusinessUnitPerformanceReport < BaseBusinessUnitPerformanceReport
    def self.title
      "Business unit report (SARs)"
    end

    def self.description
      "Shows all SAR open cases and cases closed this month, in-time or late, by responding team (excluding TMMs)"
    end

    def case_scope
      sar_tmm = CaseClosure::RefusalReason.sar_tmm
      Case::SAR::Standard
        .includes(:assign_responder_transitions,
                  :responded_transitions,
                  :responder_assignment,
                  :responding_team,
                  :approver_assignments)
        .where("refusal_reason_id IS NULL OR refusal_reason_id != ?", sar_tmm.id)
        .where.not(type: "Case::SAR::InternalReview")
    end

    def report_type
      ReportType.r103
    end
  end
end
