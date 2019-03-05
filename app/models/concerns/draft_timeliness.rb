module DraftTimeliness
  module ResponseAdded
    extend ActiveSupport::Concern

    def log_compliance_date
      return unless date_draft_compliant.nil?
      update! date_draft_compliant: transitions
                                      .where(event: 'add_responses')
                                      .last
                                      .created_at
    end
  end

  module ProgressedForClearance
    extend ActiveSupport::Concern

    def log_compliance_date
      return unless date_draft_compliant.nil?
      update! date_draft_compliant: transitions
                                      .where(event: 'progress_for_clearance')
                                      .last
                                      .created_at
    end
  end
end
