module Stats
  class R103SarBusinessUnitPerformanceReport < BaseBusinessUnitPerformanceReport

    def self.title
      'Business unit report (SARs)'
    end

    def self.description
      'Shows all SAR open cases and cases closed this month, in-time or late, by responding team (excluding TMMs)'
    end

    def case_scope
      tmm = CaseClosure::RefusalReason.tmm
      Case::SAR.where('refusal_reason_id IS NULL OR refusal_reason_id != ?', tmm.id)
    end

  end
end
