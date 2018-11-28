class SetDraftTimelinessService
attr_reader :result

  def initialize(kase:)
    @kase = kase
    @result = :error
  end

  def call
    ActiveRecord::Base.transaction do
      if @kase.sar?
        compliance_date = @kase.transitions.where(event: 'progress_for_clearance').last.created_at
      else
        compliance_date = @kase.transitions.where(event: 'add_responses').last.created_at
      end
      @kase.update!(date_draft_compliant: compliance_date)
      @result = :ok
    end
  end
end
